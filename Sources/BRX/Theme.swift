import Foundation

enum Theme {
    case proMono
    case aurora
    
    static var current: Theme = .proMono
    
    var primary: String {
        switch self {
        case .proMono: return Ansi.rgb(108, 158, 248) // blue
        case .aurora: return Ansi.rgb(134, 239, 172) // green
        }
    }
    
    var success: String {
        switch self {
        case .proMono: return Ansi.rgb(74, 222, 128) // green
        case .aurora: return Ansi.rgb(103, 232, 249) // cyan
        }
    }
    
    var warning: String {
        switch self {
        case .proMono: return Ansi.rgb(251, 191, 36) // yellow
        case .aurora: return Ansi.rgb(251, 146, 60) // orange
        }
    }
    
    var error: String {
        switch self {
        case .proMono: return Ansi.rgb(248, 113, 113) // red
        case .aurora: return Ansi.rgb(244, 63, 94) // rose
        }
    }
    
    var muted: String {
        return Ansi.rgb(160, 160, 160) // gray
    }
}

