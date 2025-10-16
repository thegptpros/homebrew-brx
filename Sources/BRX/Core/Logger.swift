import Foundation

enum Logger {
    static func info(_ message: String) {
        Terminal.writeLine("\(Theme.current.primary)ℹ︎\(Ansi.reset)  \(message)")
    }
    
    static func success(_ message: String) {
        Terminal.writeLine("\(Theme.current.success)✅\(Ansi.reset)  \(message)")
    }
    
    static func warning(_ message: String) {
        Terminal.writeLine("\(Theme.current.warning)⚠️\(Ansi.reset)  \(message)")
    }
    
    static func error(_ message: String) {
        Terminal.writeLine("\(Theme.current.error)❌\(Ansi.reset)  \(message)")
    }
    
    static func step(_ emoji: String, _ message: String) {
        Terminal.writeLine("\(emoji)  \(message)")
    }
    
    static func debug(_ message: String) {
        if ProcessInfo.processInfo.environment["BRX_DEBUG"] != nil {
            Terminal.writeLine("\(Theme.current.muted)[DEBUG]\(Ansi.reset) \(message)")
        }
    }
}

