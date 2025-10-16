import Foundation

enum Ansi {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    
    static var isColorDisabled: Bool {
        return ProcessInfo.processInfo.environment["NO_COLOR"] != nil
    }
    
    static func rgb(_ r: Int, _ g: Int, _ b: Int) -> String {
        if isColorDisabled || !Terminal.isTTY {
            return ""
        }
        return "\u{001B}[38;2;\(r);\(g);\(b)m"
    }
    
    static func bgRgb(_ r: Int, _ g: Int, _ b: Int) -> String {
        if isColorDisabled || !Terminal.isTTY {
            return ""
        }
        return "\u{001B}[48;2;\(r);\(g);\(b)m"
    }
}

