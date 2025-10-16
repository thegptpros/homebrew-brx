import Foundation

enum ShellError: Error {
    case commandNotFound(String)
    case executionFailed(Int32, String)
    case timeout
}

struct ShellResult {
    let status: Int32
    let stdout: String
    let stderr: String
    
    var success: Bool { status == 0 }
}

enum Shell {
    @discardableResult
    static func run(
        _ command: String,
        args: [String] = [],
        timeout: TimeInterval? = nil,
        env: [String: String]? = nil
    ) throws -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = args
        
        if let env = env {
            var processEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                processEnv[key] = value
            }
            process.environment = processEnv
        }
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        
        if let timeout = timeout {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning {
                    process.terminate()
                }
            }
        }
        
        process.waitUntilExit()
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        return ShellResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
    
    static func which(_ command: String) -> String? {
        let result = try? run("/usr/bin/which", args: [command])
        return result?.success == true ? result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    }
    
    static func runCapturingOutput(
        _ command: String,
        args: [String] = []
    ) -> String? {
        let result = try? run(command, args: args)
        return result?.success == true ? result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    }
}

