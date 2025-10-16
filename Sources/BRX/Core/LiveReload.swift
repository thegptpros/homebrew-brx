import Foundation

class LiveReload {
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var lastTrigger: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.5
    private let watchPaths: [String]
    private let onChange: (ChangeType) -> Void
    
    enum ChangeType {
        case assets
        case code
    }
    
    init(watchPaths: [String], onChange: @escaping (ChangeType) -> Void) {
        self.watchPaths = watchPaths
        self.onChange = onChange
    }
    
    func start() {
        for path in watchPaths {
            watchDirectory(path)
        }
    }
    
    func stop() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }
    
    private func watchDirectory(_ path: String) {
        guard FS.exists(path) else { return }
        
        let url = URL(fileURLWithPath: path)
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        
        let queue = DispatchQueue(label: "com.brx.livereload")
        
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: queue
        )
        
        fileMonitor?.setEventHandler { [weak self] in
            self?.handleFileChange(in: path)
        }
        
        fileMonitor?.setCancelHandler {
            close(descriptor)
        }
        
        fileMonitor?.resume()
    }
    
    private func handleFileChange(in path: String) {
        let now = Date()
        
        // Throttle
        guard now.timeIntervalSince(lastTrigger) > throttleInterval else {
            return
        }
        
        lastTrigger = now
        
        // Determine change type
        let changeType = detectChangeType(in: path)
        
        DispatchQueue.main.async {
            self.onChange(changeType)
        }
    }
    
    private func detectChangeType(in path: String) -> ChangeType {
        let codeExtensions = ["swift", "m", "mm", "h"]
        
        do {
            let files = try FS.listDirectory(path)
            
            for file in files {
                let ext = (file as NSString).pathExtension.lowercased()
                
                if codeExtensions.contains(ext) {
                    return .code
                }
            }
        } catch {
            Logger.debug("Failed to list directory \(path): \(error)")
        }
        
        return .assets
    }
    
    deinit {
        stop()
    }
}

