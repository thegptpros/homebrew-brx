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
            
            // Try online activation with retry logic
            Logger.step("☁️", "activating with brx.dev")
            
            var activationSuccess = false
            var lastError: Error?
            
            // Retry up to 3 times with exponential backoff
            for attempt in 1...3 {
                do {
                    let response = try await LicenseAPI.activateOnline(key: key)
                    
                    if response.success {
                        // Save locally with full license info
                        if License.activateWithDetails(
                            key: key,
                            tier: response.tier,
                            expiresAt: response.expiresAt,
                            seatsUsed: response.seatsUsed,
                            seatsTotal: response.seatsTotal
                        ) {
                            Logger.success("license activated successfully")
                            Terminal.writeLine("")
                            Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) Your license is now active")
                            
                            if let tier = response.tier {
                                Terminal.writeLine("  \(Theme.current.muted)→ Plan: \(tier)\(Ansi.reset)")
                            }
                            
                            if let seatsUsed = response.seatsUsed, let seatsTotal = response.seatsTotal {
                                Terminal.writeLine("  \(Theme.current.muted)→ Seats used: \(seatsUsed)/\(seatsTotal)\(Ansi.reset)")
                            }
                            
                            if let expiresAt = response.expiresAt {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .medium
                                Terminal.writeLine("  \(Theme.current.muted)→ Expires: \(expiresAt)\(Ansi.reset)")
                            }
                            
                            Terminal.writeLine("")
                            Terminal.writeLine("  Run \(Theme.current.primary)brx build --name MyApp\(Ansi.reset) to get started!")
                            activationSuccess = true
                            break
                        }
                    } else {
                        Logger.error(response.message ?? "Activation failed")
                        Terminal.writeLine("")
                        Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) \(response.message ?? "Unable to activate license")")
                        Terminal.writeLine("  \(Theme.current.muted)→ Contact support: support@brx.dev\(Ansi.reset)")
                        throw LicenseError.custom(response.message ?? "Activation failed")
                    }
                } catch {
                    lastError = error
                    if attempt < 3 {
                        let delay = pow(2.0, Double(attempt)) // Exponential backoff: 2s, 4s, 8s
                        Logger.warning("Attempt \(attempt) failed, retrying in \(Int(delay))s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
            }
            
            if !activationSuccess {
                Logger.warning("Could not reach brx.dev after 3 attempts, using offline validation")
                
                // Check if license is expired before allowing offline activation
                if License.isExpired() {
                    Logger.error("License has expired")
                    Terminal.writeLine("")
                    Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) Your license has expired")
                    Terminal.writeLine("  \(Theme.current.muted)→ Renew at: https://brx.dev\(Ansi.reset)")
                    throw LicenseError.custom("License expired")
                }
                
                // Check machine binding for offline activation
                let currentMachineId = License.getMachineID()
                let config = BRXConfig.load()
                
                if let boundMachineId = config.license.machineId, boundMachineId != currentMachineId {
                    Logger.error("License is bound to a different machine")
                    Terminal.writeLine("")
                    Terminal.writeLine("  \(Theme.current.error)✗\(Ansi.reset) This license is bound to another machine")
                    Terminal.writeLine("  \(Theme.current.muted)→ Contact support: support@brx.dev\(Ansi.reset)")
                    throw LicenseError.custom("License bound to different machine")
                }
                
                if License.activateOffline(key: key) {
                    Logger.success("license activated (offline mode)")
                    Terminal.writeLine("")
                    Terminal.writeLine("  \(Theme.current.success)✓\(Ansi.reset) Your license is active (offline validation)")
                    Terminal.writeLine("  \(Theme.current.muted)→ Online features may be limited\(Ansi.reset)")
                    Terminal.writeLine("")
                    Terminal.writeLine("  Run \(Theme.current.primary)brx build --name MyApp\(Ansi.reset) to get started!")
                } else {
                    throw lastError ?? LicenseError.custom("Activation failed")
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
