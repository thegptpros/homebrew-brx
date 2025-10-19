import Foundation

enum CodeSigning {
    struct DevelopmentTeam {
        let id: String
        let name: String
        let email: String
    }
    
    /// Get available development teams from installed certificates
    static func getAvailableTeams() throws -> [DevelopmentTeam] {
        let result = try Shell.run("/usr/bin/security", args: [
            "find-identity", "-v", "-p", "codesigning"
        ])
        
        guard result.success else {
            return []
        }
        
        var teams: [DevelopmentTeam] = []
        let lines = result.stdout.components(separatedBy: .newlines)
        
        for line in lines {
            // Parse lines like: "Apple Development: email@example.com (TEAMID)"
            if line.contains("Apple Development:") {
                if let emailRange = line.range(of: "Apple Development: "),
                   let parenRange = line.range(of: "("),
                   let closeParenRange = line.range(of: ")") {
                    
                    let emailStart = emailRange.upperBound
                    let emailEnd = parenRange.lowerBound
                    let email = String(line[emailStart..<emailEnd]).trimmingCharacters(in: .whitespaces)
                    
                    let teamIdStart = parenRange.upperBound
                    let teamIdEnd = closeParenRange.lowerBound
                    let teamId = String(line[teamIdStart..<teamIdEnd])
                    
                    if !teamId.isEmpty && !email.isEmpty {
                        teams.append(DevelopmentTeam(
                            id: teamId,
                            name: "Apple Development",
                            email: email
                        ))
                    }
                }
            }
        }
        
        return teams
    }
    
    /// Select the best available development team
    static func selectDevelopmentTeam() throws -> DevelopmentTeam? {
        let teams = try getAvailableTeams()
        
        if teams.isEmpty {
            return nil
        }
        
        // For now, just use the first available team
        // In the future, we could add interactive selection or preferences
        return teams.first
    }
    
    /// Check if code signing is available
    static func isAvailable() -> Bool {
        do {
            let teams = try getAvailableTeams()
            return !teams.isEmpty
        } catch {
            return false
        }
    }
    
    /// Open Xcode and guide the user through signing setup
    static func setupSigningInteractive(projectPath: String) throws {
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)📱 Physical Device Setup Required\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  To deploy to your iPhone, we need to configure code signing.")
        Terminal.writeLine("  This is a \(Theme.current.primary)one-time setup\(Ansi.reset) per project.")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Opening Xcode...\(Ansi.reset)")
        Terminal.writeLine("")
        
        // Open the project in Xcode
        let result = try Shell.run("/usr/bin/open", args: [projectPath])
        guard result.success else {
            throw CodeSigningError.setupFailed("Failed to open Xcode")
        }
        
        // Give Xcode time to open
        Thread.sleep(forTimeInterval: 2.0)
        
        // Show instructions
        Terminal.writeLine("\(Theme.current.success)✓\(Ansi.reset) Xcode opened with your project")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.primary)Quick Setup:\(Ansi.reset)")
        Terminal.writeLine("")
        Terminal.writeLine("  1. \(Theme.current.primary)Select your project\(Ansi.reset) (top of left sidebar)")
        Terminal.writeLine("  2. \(Theme.current.primary)Select the target\(Ansi.reset) (under project name)")
        Terminal.writeLine("  3. Go to \(Theme.current.primary)\"Signing & Capabilities\"\(Ansi.reset) tab")
        Terminal.writeLine("  4. Check \(Theme.current.primary)\"Automatically manage signing\"\(Ansi.reset)")
        Terminal.writeLine("  5. \(Theme.current.primary)Select your Apple ID team\(Ansi.reset) from dropdown")
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.muted)No Apple ID?\(Ansi.reset) Go to Xcode → Settings → Accounts → Add (+)")
        Terminal.writeLine("")
        Terminal.writeLine("Press \(Theme.current.primary)Enter\(Ansi.reset) when signing is configured...")
        
        // Wait for user to press Enter
        _ = readLine()
        
        Terminal.writeLine("")
        Terminal.writeLine("\(Theme.current.success)✓\(Ansi.reset) Great! Continuing build...")
        Terminal.writeLine("")
    }
}

enum CodeSigningError: Error, CustomStringConvertible {
    case noTeamsAvailable
    case provisioningFailed(String)
    case setupFailed(String)
    
    var description: String {
        switch self {
        case .noTeamsAvailable:
            return """
            \(Theme.current.error)No development teams found\(Ansi.reset)
            
            To deploy to physical devices, you need:
              1. An Apple ID (free or paid)
              2. Xcode configured with your Apple ID
            
            \(Theme.current.primary)Setup Instructions:\(Ansi.reset)
              1. Open Xcode
              2. Go to Settings → Accounts
              3. Add your Apple ID
              4. Then try \(Theme.current.primary)brx run\(Ansi.reset) again
            
            \(Theme.current.muted)For simulator testing (no Apple ID needed):\(Ansi.reset)
              \(Theme.current.primary)brx run --device "iPhone 17 Pro Max"\(Ansi.reset)
            """
        case .provisioningFailed(let message):
            return """
            \(Theme.current.error)Code signing failed\(Ansi.reset)
            
            \(message)
            """
        case .setupFailed(let message):
            return """
            \(Theme.current.error)Setup failed\(Ansi.reset)
            
            \(message)
            """
        }
    }
}

