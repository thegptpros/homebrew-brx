import Foundation
import ArgumentParser

struct ActivateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activate",
        abstract: "Activate license"
    )
    
    @Option(name: .shortAndLong, help: "License key")
    var licenseKey: String?
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        Telemetry.trackCommand("activate")
        
        if let key = licenseKey {
            Logger.step("🔑", "validating license key")
            
            // First validate format locally
            if !License.validate(key: key) {
                Logger.error("invalid license key format")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) The license key format is invalid")
                Terminal.writeLine("  \(Theme.current.muted)→ Expected format: BRX-XXXX-XXXX-XXXX-XXXX\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Purchase at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)")
                throw LicenseError.invalidKey
            }
            
            // Try online activation first
            Logger.step("☁️", "activating with brx.dev")
            
            do {
                let response = try await LicenseAPI.activateOnline(key: key)
                
                if response.success {
                    // Save locally
                    if License.activate(key: key) {
                        Logger.success("license activated successfully")
                        Terminal.writeLine("")
                        Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) Your license is now active")
                        
                        if let tier = response.tier {
                            Terminal.writeLine("  \(Theme.current.muted)→ Plan: \(tier)\(Ansi.reset)")
                        }
                        
                        if let seatsUsed = response.seatsUsed, let seatsTotal = response.seatsTotal {
                            Terminal.writeLine("  \(Theme.current.muted)→ Seats used: \(seatsUsed)/\(seatsTotal)\(Ansi.reset)")
                        }
                        
                        Terminal.writeLine("")
                        Terminal.writeLine("  Run \(Theme.current.primary)brx build --name MyApp\(Ansi.reset) to get started!")
                    }
                } else {
                    Logger.error(response.message ?? "Activation failed")
                    Terminal.writeLine("")
                    Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) \(response.message ?? "Unable to activate license")")
                    Terminal.writeLine("  \(Theme.current.muted)→ Contact support: support@brx.dev\(Ansi.reset)")
                    throw LicenseError.custom(response.message ?? "Activation failed")
                }
            } catch {
                // Online activation failed, try offline validation
                Logger.warning("Could not reach brx.dev, using offline validation")
                
                if License.activate(key: key) {
                    Logger.success("license activated (offline mode)")
                    Terminal.writeLine("")
                    Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) Your license is active (offline validation)")
                    Terminal.writeLine("  \(Theme.current.muted)→ Online features may be limited\(Ansi.reset)")
                    Terminal.writeLine("")
                    Terminal.writeLine("  Run \(Theme.current.primary)brx build --name MyApp\(Ansi.reset) to get started!")
                } else {
                    throw error
                }
            }
        } else {
            // Check if already activated
            if License.isActivated {
                Logger.success("license already activated")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) Your license is active")
                Terminal.writeLine("  \(Theme.current.muted)→ Check status: \(Theme.current.primary)brx status\(Ansi.reset)")
            } else {
                Logger.step("ℹ️", "please provide a license key")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.muted)→ Usage: brx activate --license-key <your-key>\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Purchase at: \(Theme.current.primary)https://brx.dev\(Ansi.reset)")
                Terminal.writeLine("  \(Theme.current.muted)→ Check status: \(Theme.current.primary)brx status\(Ansi.reset)")
            }
        }
        
        Terminal.writeLine("")
    }
}
