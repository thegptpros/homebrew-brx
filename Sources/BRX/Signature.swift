import Foundation

enum Signature {
    static func start() {
        let width = Terminal.width
        let logo = "◻︎ brx — build. run. ship. ios. from terminal."
        let padding = max(0, (width - logo.count) / 2)
        
        Terminal.writeLine(String(repeating: "─", count: width))
        Terminal.write(String(repeating: " ", count: padding))
        Terminal.writeLine(logo)
        Terminal.writeLine(String(repeating: "─", count: width))
        Terminal.writeLine("")
    }
    
    static func stopBlink() {
        // No-op now, but kept for compatibility
    }
}

