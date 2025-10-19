import Foundation
import ArgumentParser

struct BuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Create project from template & build"
    )
    
    @Option(name: .shortAndLong, help: "Template name")
    var template: String = "swiftui-blank"
    
    @Option(name: .shortAndLong, help: "Project name")
    var name: String?
    
    @Option(name: .long, help: "Bundle identifier")
    var bundleId: String?
    
    @Option(name: .long, help: "Configuration (Debug or Release)")
    var configuration: String = "Debug"
    
    @Flag(name: .long, help: "Show verbose xcodebuild output")
    var verbose: Bool = false
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        // Check build limit (allows 10 free builds or unlimited with license)
        let (canBuild, _) = License.canBuild()
        guard canBuild else {
            throw LicenseError.buildLimitReached
        }
        
        Telemetry.trackCommand("build")
        
        // Check if we're in an existing project
        if FS.exists("brx.yml") {
            // We're in an existing project, just build it
            try await buildExistingProject()
        } else {
            // Create new project from template
            try await createAndBuildProject()
        }
        
        // Increment build count and show remaining builds (only for free users)
        License.incrementBuildCount()
        License.showBuildLimitMessage()
    }
    
    private func buildExistingProject() async throws {
        // Load project spec
        let spec = try ProjectSpec.load()
        let config = BRXConfig.load()
        
        let projectPath = spec.project ?? "\(spec.name).xcodeproj"
        let scheme = spec.scheme ?? spec.name
        let targetDevice = config.defaults.iosDevice
        
        // Ensure device exists for destination
        let udid = try Simulator.ensureDevice(named: targetDevice, platform: .iOS)
        
        Logger.step("⚙️", "building \(spec.name) (\(configuration))")
        
        let destination = "platform=iOS Simulator,id=\(udid)"
        let appPath = try XcodeTools.build(
            project: projectPath,
            scheme: scheme,
            configuration: configuration,
            destination: destination
        )
        
        Logger.success("built \(appPath)")
        Terminal.writeLine("")
    }
    
    private func createAndBuildProject() async throws {
        guard let projectName = name else {
            throw BuildError.projectNameRequired
        }
        
        Logger.step("🚀", "creating \(projectName) from \(template) template")
        
        // Find template
        let templatePath = try findTemplate(template)
        let projectPath = projectName
        
        // Copy template
        Logger.step("📦", "copying template files...")
        try copyTemplate(from: templatePath, to: projectPath)
        
        // Update brx.yml with project name and bundle ID
        let bundleIdentifier = bundleId ?? "com.brx.\(projectName.lowercased())"
        try updateBRXYML(at: "\(projectPath)/brx.yml", name: projectName, bundleId: bundleIdentifier)
        try updateProjectYML(at: "\(projectPath)/project.yml", name: projectName, bundleId: bundleIdentifier)
        try replaceTemplateVariables(in: projectPath, name: projectName)
        
        // Generate project automatically
        let originalDir = FS.currentDirectory()
        FileManager.default.changeCurrentDirectoryPath(projectPath)
        
        Logger.step("⚙️", "generating Xcode project...")
        let spec = try ProjectSpec.load()
        try ProjectGen.generate(spec: spec)
        
        // Build the project automatically
        Logger.step("🔨", "building project...")
        let config = BRXConfig.load()
        let targetDevice = config.defaults.iosDevice
        let udid = try Simulator.ensureDevice(named: targetDevice, platform: .iOS)
        let destination = "platform=iOS Simulator,id=\(udid)"
        
        _ = try XcodeTools.build(
            project: spec.project ?? "\(spec.name).xcodeproj",
            scheme: spec.scheme ?? spec.name,
            configuration: configuration,
            destination: destination
        )
        
        FileManager.default.changeCurrentDirectoryPath(originalDir)
        
        Logger.success("created ./\(projectName)  • built successfully")
        Terminal.writeLine("\(Theme.current.primary)→\(Ansi.reset)  Next: \(Theme.current.muted)cd \(projectName) && brx run\(Ansi.reset)")
        Terminal.writeLine("")
    }
    
    private func findTemplate(_ name: String) throws -> String {
        // Try multiple paths to find templates
        let searchPaths = [
            // Templates bundled with executable (for releases)
            "\(ProcessInfo.processInfo.arguments[0])/Templates/\(name)",
            // Local Templates directory (for development)
            "./Templates/\(name)",
            // User directory (for local installs)
            "~/.local/share/brx/Templates/\(name)",
            // Relative to executable (for installed brx)
            "\(ProcessInfo.processInfo.arguments[0])/../Templates/\(name)",
            // Source directory (for development builds)
            "\(FS.currentDirectory())/Templates/\(name)",
            // Installed location
            "/usr/local/share/brx/Templates/\(name)",
            // Homebrew location
            "/opt/homebrew/share/brx/Templates/\(name)"
        ]
        
        for path in searchPaths {
            let expandedPath = (path as NSString).expandingTildeInPath
            if FS.exists(expandedPath) {
                return expandedPath
            }
        }
        
        throw BuildError.templateNotFound(name)
    }
    
    private func copyTemplate(from source: String, to destination: String) throws {
        if FS.exists(destination) {
            throw BuildError.directoryExists(destination)
        }
        
        try FS.createDirectory(destination)
        
        // Get all files including hidden ones
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(atPath: source)
        
        for file in files {
            // Skip hidden files except for Cursor/VS Code integration files
            if file.hasPrefix(".") && !shouldIncludeHiddenFile(file) { 
                continue 
            }
            
            let sourcePath = "\(source)/\(file)"
            let destPath = "\(destination)/\(file)"
            
            try FS.copyItem(from: sourcePath, to: destPath)
        }
    }
    
    private func shouldIncludeHiddenFile(_ file: String) -> Bool {
        // Include Cursor/VS Code integration files
        let allowedHiddenFiles = [
            ".cursorrules",
            ".cursorignore",
            ".vscode"
        ]
        
        return allowedHiddenFiles.contains(file)
    }
    
    private func updateBRXYML(at path: String, name: String, bundleId: String) throws {
        let content = """
        name: \(name)
        bundle_id: \(bundleId)
        project: \(name).xcodeproj
        scheme: \(name)
        """
        try FS.writeFile(path, contents: content)
    }
    
    private func updateProjectYML(at path: String, name: String, bundleId: String) throws {
        // Read the template file and replace placeholders
        guard let content = try? FS.readFile(path) else {
            throw BuildError.templateNotFound("project.yml")
        }
        
        let nameLower = name.lowercased()
        let bundlePrefix = bundleId.components(separatedBy: ".\(nameLower)").first ?? "com.brx"
        
        let updated = content
            .replacingOccurrences(of: "{{PROJECT_NAME}}", with: name)
            .replacingOccurrences(of: "{{PROJECT_NAME_LOWER}}", with: nameLower)
            .replacingOccurrences(of: "com.brx", with: bundlePrefix)
        
        try FS.writeFile(path, contents: updated)
    }
    
    private func replaceTemplateVariables(in projectPath: String, name: String) throws {
        // Replace {{PROJECT_NAME}} in all Swift files
        let sourcesPath = "\(projectPath)/Sources"
        if FS.exists(sourcesPath) {
            let files = try FS.listDirectory(sourcesPath)
            for file in files {
                if file.hasSuffix(".swift") {
                    let filePath = "\(sourcesPath)/\(file)"
                    if let content = try? FS.readFile(filePath) {
                        let updated = content.replacingOccurrences(of: "{{PROJECT_NAME}}", with: name)
                        try FS.writeFile(filePath, contents: updated)
                    }
                }
            }
        }
        
        // Replace template variables in Cursor/VS Code files
        try replaceTemplateVariablesInCursorFiles(projectPath: projectPath, name: name)
    }
    
    private func replaceTemplateVariablesInCursorFiles(projectPath: String, name: String) throws {
        // Update .vscode/launch.json files
        let launchJsonPath = "\(projectPath)/.vscode/launch.json"
        if FS.exists(launchJsonPath) {
            if let content = try? FS.readFile(launchJsonPath) {
                let updated = content
                    .replacingOccurrences(of: "{{NAME}}", with: name)
                    .replacingOccurrences(of: "{{PROJECT_NAME}}", with: name)
                try FS.writeFile(launchJsonPath, contents: updated)
            }
        }
        
        // Update README.md files
        let readmePath = "\(projectPath)/README.md"
        if FS.exists(readmePath) {
            if let content = try? FS.readFile(readmePath) {
                let updated = content
                    .replacingOccurrences(of: "{{NAME}}", with: name)
                    .replacingOccurrences(of: "{{PROJECT_NAME}}", with: name)
                try FS.writeFile(readmePath, contents: updated)
            }
        }
    }
}

enum BuildError: Error, CustomStringConvertible {
    case projectNameRequired
    case templateNotFound(String)
    case directoryExists(String)
    
    var description: String {
        switch self {
        case .projectNameRequired:
            return "Project name is required. Use --name <name>"
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .directoryExists(let name):
            return "Directory '\(name)' already exists"
        }
    }
}

