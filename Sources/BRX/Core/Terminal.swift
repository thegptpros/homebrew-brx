import Foundation

enum Terminal {
    static var width: Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return Int(w.ws_col)
        }
        return 80
    }
    
    static var isTTY: Bool {
        return isatty(STDOUT_FILENO) != 0
    }
    
    static func write(_ text: String) {
        print(text, terminator: "")
        fflush(stdout)
    }
    
    static func writeLine(_ text: String) {
        print(text)
        fflush(stdout)
    }
    
    static func clearLine() {
        write("\r\u{001B}[2K")
    }
    
    static func cursorUp(_ lines: Int = 1) {
        write("\u{001B}[\(lines)A")
    }
    
    static func cursorDown(_ lines: Int = 1) {
        write("\u{001B}[\(lines)B")
    }
    
    static func hideCursor() {
        write("\u{001B}[?25l")
    }
    
    static func showCursor() {
        write("\u{001B}[?25h")
    }
}

