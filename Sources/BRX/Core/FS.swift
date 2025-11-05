import Foundation

enum FS {
    static let fileManager = FileManager.default
    
    static func exists(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
    
    static func createDirectory(_ path: String) throws {
        try fileManager.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    static func writeFile(_ path: String, contents: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    static func readFile(_ path: String) throws -> String {
        return try String(contentsOfFile: path, encoding: .utf8)
    }
    
    static func copyItem(from: String, to: String) throws {
        try fileManager.copyItem(atPath: from, toPath: to)
    }
    
    static func removeItem(_ path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    static func removeDirectory(_ path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    static func listDirectory(_ path: String) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: path)
    }
    
    static func homeDirectory() -> String {
        return fileManager.homeDirectoryForCurrentUser.path
    }
    
    static func currentDirectory() -> String {
        return fileManager.currentDirectoryPath
    }
}

