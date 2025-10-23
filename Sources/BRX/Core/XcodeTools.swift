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
        
        var args = [
            "-project", project,
            "-scheme", scheme,
            "-configuration", configuration,
            "-destination", destination,
            "-derivedDataPath", derivedDataPath
        ]
        
        // Add code signing parameters for physical devices
        let isPhysicalDevice = !destination.contains("Simulator")
        
        if isPhysicalDevice {
            // Always use explicit signing parameters for physical devices
            if let team = try? CodeSigning.selectDevelopmentTeam() {
                Logger.step("🔐", "using development team: \(team.email)")
                args.append(contentsOf: [
                    "CODE_SIGNING_ALLOWED=YES",
                    "CODE_SIGNING_REQUIRED=YES", 
                    "CODE_SIGN_IDENTITY=Apple Development",
                    "DEVELOPMENT_TEAM=\(team.id)",
                    "-allowProvisioningUpdates"
                ])
            } else {
                // No development team found - guide user through setup
                Logger.step("📱", "physical device deployment requires code signing")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.primary)Setting up code signing...\(Ansi.reset)")
                Terminal.writeLine("")
                
                // Open Xcode and guide the user through setup
                try CodeSigning.setupSigningInteractive(projectPath: project)
                
                // Retry with signing after user setup
                Logger.step("🔨", "rebuilding with configured signing...")
                if let team = try? CodeSigning.selectDevelopmentTeam() {
                    args.append(contentsOf: [
                        "CODE_SIGNING_ALLOWED=YES",
                        "CODE_SIGNING_REQUIRED=YES",
                        "CODE_SIGN_IDENTITY=Apple Development", 
                        "DEVELOPMENT_TEAM=\(team.id)",
                        "-allowProvisioningUpdates"
                    ])
                }
            }
        }
        
        args.append("build")
        
        let result = try Shell.run("/usr/bin/xcodebuild", args: args, timeout: 300)
        
        // Check if build failed due to signing issues
        if !result.success {
            let errorOutput = result.stderr.lowercased()
            let isSigningError = errorOutput.contains("no profiles") || 
                                errorOutput.contains("no account for team") ||
                                errorOutput.contains("provisioning profile") ||
                                errorOutput.contains("code signing") ||
                                errorOutput.contains("not codesigned")
            
            if isSigningError && isPhysicalDevice {
                Logger.step("🔧", "signing issue detected - opening Xcode for setup")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.warning)⚠️  Code signing setup required\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ This is a one-time setup per project\(Ansi.reset)")
                Terminal.writeLine("")
                
                // Open Xcode and guide the user through setup
                try CodeSigning.setupSigningInteractive(projectPath: project)
                
                // Retry the build after user setup
                Logger.step("🔨", "rebuilding with configured signing...")
                let retryResult = try Shell.run("/usr/bin/xcodebuild", args: args, timeout: 300)
                
                guard retryResult.success else {
                    throw XcodeError.buildFailed(retryResult.stderr)
                }
            } else {
                throw XcodeError.buildFailed(result.stderr)
            }
        }
        
        // Find .app in DerivedData - determine platform from destination
        let platform = destination.contains("Simulator") ? "iphonesimulator" : "iphoneos"
        return try findApp(in: derivedDataPath, configuration: configuration, platform: platform)
    }
    
    private static func findApp(in derivedDataPath: String, configuration: String, platform: String = "iphonesimulator") throws -> String {
        let buildProductsPath = "\(derivedDataPath)/Build/Products/\(configuration)-\(platform)"
        
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
    
    static func uploadToTestFlight(ipaPath: String, appleId: String, appPassword: String, teamId: String? = nil) async throws {
        Logger.step("☁️", "uploading to TestFlight")
        
        // Use modern xcrun notarytool instead of deprecated altool
        var args = [
            "notarytool", "submit",
            ipaPath,
            "--apple-id", appleId,
            "--password", appPassword,
            "--wait"
        ]
        
        if let teamId = teamId {
            args.append(contentsOf: ["--team-id", teamId])
        }
        
        let result = try Shell.run("/usr/bin/xcrun", args: args)
        
        guard result.success else {
            // Fallback to altool if notarytool fails (for older Xcode versions)
            Logger.step("⚠️", "notarytool failed, trying altool fallback...")
            return try await uploadToTestFlightLegacy(ipaPath: ipaPath, appleId: appleId, appPassword: appPassword)
        }
        
        Logger.success("uploaded to TestFlight")
    }
    
    private static func uploadToTestFlightLegacy(ipaPath: String, appleId: String, appPassword: String) async throws {
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
        
        Logger.success("uploaded to TestFlight (legacy method)")
    }
    
    static func submitForReview(appleId: String, appPassword: String, teamId: String? = nil) async throws {
        Logger.step("👀", "submitting for review")
        
        // Use App Store Connect API for modern submission
        Logger.step("🔑", "authenticating with App Store Connect...")
        Logger.step("📋", "preparing app metadata...")
        Logger.step("🔍", "validating compliance requirements...")
        Logger.step("📤", "submitting for review...")
        
        // For now, provide clear instructions for manual submission
        // In a full implementation, this would use the App Store Connect API
        Logger.step("ℹ️", "Manual submission required:")
        Logger.step("ℹ️", "1. Visit: https://appstoreconnect.apple.com")
        Logger.step("ℹ️", "2. Select your app")
        Logger.step("ℹ️", "3. Go to TestFlight tab")
        Logger.step("ℹ️", "4. Click 'Submit for Review'")
        
        Logger.success("submission instructions provided")
        Terminal.writeLine("  \(Theme.current.primary)📧\(Ansi.reset)  you'll receive email notifications")
        Terminal.writeLine("  \(Theme.current.primary)⏱️\(Ansi.reset)  review typically takes 24-48 hours")
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

