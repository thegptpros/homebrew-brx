import Foundation

struct BuildErrorParser {
    enum ErrorType {
        case simulatorRuntimeMismatch(requestedVersion: String, availableVersions: [String])
        case corruptedDerivedData
        case missingScheme(String)
        case codeSigningIssue
        case missingDependency(String)
        case projectCorrupted
        case unknown(String)
    }
    
    struct RecoveryAction {
        let description: String
        let action: () throws -> Void
    }
    
    static func parse(xcodebuildError: String) -> ErrorType {
        let error = xcodebuildError.lowercased()
        
        // Simulator runtime mismatch
        if error.contains("unable to find a destination") ||
           error.contains("is not installed") ||
           error.contains("runtime") && error.contains("not available") {
            // Try to extract version from error
            let versionPattern = #"iOS[-\s]?(\d+\.\d+)"#
            if let regex = try? NSRegularExpression(pattern: versionPattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: xcodebuildError, range: NSRange(xcodebuildError.startIndex..., in: xcodebuildError)),
               let versionRange = Range(match.range(at: 1), in: xcodebuildError) {
                let requestedVersion = String(xcodebuildError[versionRange])
                return .simulatorRuntimeMismatch(requestedVersion: requestedVersion, availableVersions: [])
            }
            return .simulatorRuntimeMismatch(requestedVersion: "unknown", availableVersions: [])
        }
        
        // Corrupted DerivedData
        if error.contains("deriveddata") && (error.contains("corrupt") || error.contains("invalid")) ||
           error.contains("could not find") && error.contains("build products") {
            return .corruptedDerivedData
        }
        
        // Missing scheme
        if error.contains("scheme") && (error.contains("not found") || error.contains("does not exist")) {
            let schemePattern = #"'([^']+)'"#
            if let regex = try? NSRegularExpression(pattern: schemePattern),
               let match = regex.firstMatch(in: xcodebuildError, range: NSRange(xcodebuildError.startIndex..., in: xcodebuildError)),
               let schemeRange = Range(match.range(at: 1), in: xcodebuildError) {
                let scheme = String(xcodebuildError[schemeRange])
                return .missingScheme(scheme)
            }
            return .missingScheme("unknown")
        }
        
        // Code signing
        if error.contains("code sign") || error.contains("provisioning profile") ||
           error.contains("no account for team") {
            return .codeSigningIssue
        }
        
        // Missing dependency
        if error.contains("no such module") || error.contains("cannot find") && error.contains("in scope") {
            let modulePattern = #"no such module '([^']+)'"#
            if let regex = try? NSRegularExpression(pattern: modulePattern),
               let match = regex.firstMatch(in: xcodebuildError, range: NSRange(xcodebuildError.startIndex..., in: xcodebuildError)),
               let moduleRange = Range(match.range(at: 1), in: xcodebuildError) {
                let module = String(xcodebuildError[moduleRange])
                return .missingDependency(module)
            }
        }
        
        // Project corrupted
        if error.contains("project.pbxproj") && (error.contains("parse") || error.contains("invalid") || error.contains("corrupt")) {
            return .projectCorrupted
        }
        
        return .unknown(xcodebuildError)
    }
    
    static func getRecoveryAction(for errorType: ErrorType, context: BuildContext) -> RecoveryAction? {
        switch errorType {
        case .simulatorRuntimeMismatch(let requestedVersion, _):
            return RecoveryAction(
                description: "Auto-fixing: Using closest available iOS runtime instead of \(requestedVersion)",
                action: {
                    // Recovery is handled by caller - they should call findClosestRuntime
                    // and retry with the new destination
                }
            )
            
        case .corruptedDerivedData:
            return RecoveryAction(
                description: "Auto-fixing: Cleaning corrupted build cache",
                action: {
                    let derivedDataPath = "\(FS.currentDirectory())/.brx/DerivedData"
                    if FS.exists(derivedDataPath) {
                        try FS.removeItem(derivedDataPath)
                        Logger.debug("Cleaned DerivedData at \(derivedDataPath)")
                    }
                }
            )
            
        case .missingScheme(let scheme):
            return RecoveryAction(
                description: "Auto-fixing: Regenerating project to create scheme '\(scheme)'",
                action: {
                    if FS.exists("project.yml") {
                        let spec = try ProjectSpec.load()
                        try ProjectGen.generate(spec: spec)
                        Logger.debug("Regenerated project for missing scheme")
                    }
                }
            )
            
        case .projectCorrupted:
            return RecoveryAction(
                description: "Auto-fixing: Regenerating corrupted project",
                action: {
                    if FS.exists("project.yml") {
                        let spec = try ProjectSpec.load()
                        try ProjectGen.generate(spec: spec)
                        Logger.debug("Regenerated corrupted project")
                    }
                }
            )
            
        case .codeSigningIssue, .missingDependency, .unknown:
            return nil
        }
    }
    
    static func getHumanReadableMessage(for errorType: ErrorType) -> String {
        switch errorType {
        case .simulatorRuntimeMismatch(let requestedVersion, _):
            return """
            ❌ Simulator runtime mismatch
            
            Requested iOS \(requestedVersion) is not available.
            → Auto-fixing: Using latest available runtime instead
            """
            
        case .corruptedDerivedData:
            return """
            ❌ Corrupted build cache detected
            
            → Auto-fixing: Cleaning DerivedData
            """
            
        case .missingScheme(let scheme):
            return """
            ❌ Scheme '\(scheme)' not found
            
            → Auto-fixing: Regenerating project
            """
            
        case .codeSigningIssue:
            return """
            ❌ Code signing issue detected
            
            → Opening Xcode for setup...
            """
            
        case .missingDependency(let module):
            return """
            ❌ Missing dependency: \(module)
            
            → Install with: swift package resolve
            → Or add to project.yml dependencies
            """
            
        case .projectCorrupted:
            return """
            ❌ Project file appears corrupted
            
            → Auto-fixing: Regenerating project
            """
            
        case .unknown(let error):
            return """
            ❌ Build failed
            
            \(error)
            """
        }
    }
}

struct BuildContext {
    let projectPath: String
    let scheme: String
    let destination: String
    let isPhysicalDevice: Bool
}

