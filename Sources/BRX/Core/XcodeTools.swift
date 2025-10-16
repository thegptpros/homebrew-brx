import Foundation

enum XcodeTools {
    static func build(
        project: String,
        scheme: String,
        configuration: String = "Debug",
        destination: String
    ) throws -> String {
        let derivedDataPath = "\(FS.currentDirectory())/.brx/DerivedData"
        
        try? FS.createDirectory(derivedDataPath)
        
        let args = [
            "-project", project,
            "-scheme", scheme,
            "-configuration", configuration,
            "-destination", destination,
            "-derivedDataPath", derivedDataPath,
            "build"
        ]
        
        let result = try Shell.run("/usr/bin/xcodebuild", args: args, timeout: 300)
        
        guard result.success else {
            throw XcodeError.buildFailed(result.stderr)
        }
        
        // Find .app in DerivedData
        return try findApp(in: derivedDataPath, configuration: configuration)
    }
    
    private static func findApp(in derivedDataPath: String, configuration: String) throws -> String {
        let buildProductsPath = "\(derivedDataPath)/Build/Products/\(configuration)-iphonesimulator"
        
        guard FS.exists(buildProductsPath) else {
            throw XcodeError.appNotFound
        }
        
        let contents = try FS.listDirectory(buildProductsPath)
        
        for item in contents where item.hasSuffix(".app") {
            return "\(buildProductsPath)/\(item)"
        }
        
        throw XcodeError.appNotFound
    }
    
    static func checkXcodeBuild() -> Bool {
        return Shell.which("xcodebuild") != nil
    }
    
    static func getXcodeVersion() -> String? {
        guard let result = try? Shell.run("/usr/bin/xcodebuild", args: ["-version"]),
              result.success else {
            return nil
        }
        
        let firstLine = result.stdout.components(separatedBy: .newlines).first ?? ""
        return firstLine.replacingOccurrences(of: "Xcode ", with: "")
    }
    
    static func listSchemes(project: String) throws -> [String] {
        let result = try Shell.run("/usr/bin/xcodebuild", args: [
            "-project", project,
            "-list"
        ])
        
        guard result.success else {
            throw XcodeError.listSchemesFailed
        }
        
        var schemes: [String] = []
        var inSchemes = false
        
        for line in result.stdout.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed == "Schemes:" {
                inSchemes = true
                continue
            }
            
            if inSchemes {
                if trimmed.isEmpty { break }
                schemes.append(trimmed)
            }
        }
        
        return schemes
    }
    
    // MARK: - Deployment Methods
    
    static func archive(project: String, scheme: String, configuration: String) async throws -> String {
        Logger.step("📦", "creating archive")
        
        let archivePath = "\(FileManager.default.currentDirectoryPath)/build/\(scheme).xcarchive"
        
        // Ensure build directory exists
        try FS.createDirectory("build")
        
        let args = [
            "-project", project,
            "-scheme", scheme,
            "-configuration", configuration,
            "-archivePath", archivePath,
            "archive",
            "-destination", "generic/platform=iOS"
        ]
        
        let result = try Shell.run("/usr/bin/xcodebuild", args: args)
        
        guard result.success else {
            throw XcodeError.buildFailed(result.stderr)
        }
        
        Logger.success("archive created at \(archivePath)")
        return archivePath
    }
    
    static func exportIPA(archivePath: String, exportMethod: String) async throws -> String {
        Logger.step("📱", "exporting IPA")
        
        let exportPath = "\(FileManager.default.currentDirectoryPath)/build/export"
        let ipaPath = "\(exportPath)/\(URL(fileURLWithPath: archivePath).deletingPathExtension().lastPathComponent).ipa"
        
        // Create export plist
        let exportPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>method</key>
            <string>\(exportMethod)</string>
            <key>uploadBitcode</key>
            <false/>
            <key>uploadSymbols</key>
            <true/>
            <key>compileBitcode</key>
            <false/>
        </dict>
        </plist>
        """
        
        let plistPath = "\(exportPath)/ExportOptions.plist"
        try FS.createDirectory(exportPath)
        try FS.writeFile(plistPath, contents: exportPlist)
        
        let args = [
            "-exportArchive",
            "-archivePath", archivePath,
            "-exportPath", exportPath,
            "-exportOptionsPlist", plistPath
        ]
        
        let result = try Shell.run("/usr/bin/xcodebuild", args: args)
        
        guard result.success else {
            throw XcodeError.buildFailed(result.stderr)
        }
        
        Logger.success("IPA exported to \(ipaPath)")
        return ipaPath
    }
    
    static func uploadToTestFlight(ipaPath: String, appleId: String, appPassword: String) async throws {
        Logger.step("☁️", "uploading to TestFlight")
        
        let args = [
            "--upload-app",
            "--file", ipaPath,
            "--username", appleId,
            "--password", appPassword,
            "--type", "ios"
        ]
        
        let result = try Shell.run("/usr/bin/xcrun", args: ["altool"] + args)
        
        guard result.success else {
            throw XcodeError.buildFailed(result.stderr)
        }
        
        Logger.success("uploaded to TestFlight")
    }
    
    static func submitForReview(appleId: String, appPassword: String) async throws {
        Logger.step("👀", "submitting for review")
        
        // This would use App Store Connect API in a real implementation
        // For now, we'll provide instructions
        Logger.step("ℹ️", "Please submit for review manually in App Store Connect")
        Logger.step("ℹ️", "Visit: https://appstoreconnect.apple.com")
        
        // TODO: Implement App Store Connect API integration
        // This would require API keys and more complex authentication
    }
}

enum XcodeError: Error, CustomStringConvertible {
    case buildFailed(String)
    case appNotFound
    case listSchemesFailed
    
    var description: String {
        switch self {
        case .buildFailed(let error):
            return "Build failed: \(error)"
        case .appNotFound:
            return "Could not find .app in build products"
        case .listSchemesFailed:
            return "Failed to list schemes"
        }
    }
}

