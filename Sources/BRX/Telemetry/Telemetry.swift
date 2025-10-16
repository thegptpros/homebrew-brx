import Foundation

enum Telemetry {
    static var isEnabled: Bool {
        return BRXConfig.load().telemetry
    }
    
    static func track(_ event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        // Stub implementation
        Logger.debug("[Telemetry] \(event) \(properties)")
    }
    
    static func trackCommand(_ command: String) {
        track("command_executed", properties: ["command": command])
    }
    
    static func trackError(_ error: Error) {
        track("error_occurred", properties: ["error": String(describing: error)])
    }
}

