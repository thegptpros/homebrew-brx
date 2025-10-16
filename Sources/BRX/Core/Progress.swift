import Foundation

enum ProgressPhase {
    case build
    case boot
    case install
    case launch
    case archive
    case upload
    case review
    case doctor
    
    var emoji: String {
        switch self {
        case .build: return "⚙️"
        case .boot: return "📱"
        case .install: return "📦"
        case .launch: return "🚀"
        case .archive: return "📦"
        case .upload: return "☁️"
        case .review: return "👀"
        case .doctor: return "🩺"
        }
    }
    
    var label: String {
        switch self {
        case .build: return "building"
        case .boot: return "booting"
        case .install: return "installing"
        case .launch: return "launching"
        case .archive: return "archiving"
        case .upload: return "uploading"
        case .review: return "submitting"
        case .doctor: return "checking"
        }
    }
}

class Progress {
    private var timer: Timer?
    private var current: Double = 0.0
    private let total: Double = 100.0
    private var phase: ProgressPhase
    private var message: String
    
    init(phase: ProgressPhase, message: String = "") {
        self.phase = phase
        self.message = message
    }
    
    func start() {
        Terminal.hideCursor()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    private func update() {
        current = min(current + 2, total)
        render()
    }
    
    func set(_ percentage: Double) {
        current = min(percentage, total)
        render()
    }
    
    private func render() {
        let width = Terminal.width - 20
        let filled = Int((current / total) * Double(width))
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: width - filled)
        
        let percent = String(format: "%3.0f", current)
        let text = "\(phase.emoji)  \(phase.label) \(message) [\(bar)] \(percent)%"
        
        Terminal.clearLine()
        Terminal.write(text)
        fflush(stdout)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        Terminal.showCursor()
        Terminal.writeLine("")
    }
    
    deinit {
        stop()
    }
}

