import Foundation

struct ProjectSpec: Codable {
    let name: String
    let bundleId: String
    let scheme: String?
    let destination: String?
    let generator: String?
    let project: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case bundleId = "bundle_id"
        case scheme
        case destination
        case generator
        case project
    }
    
    static func load(from path: String = "brx.yml") throws -> ProjectSpec {
        guard FS.exists(path) else {
            throw ProjectError.specNotFound(path)
        }
        
        let contents = try FS.readFile(path)
        return try parseYAML(contents)
    }
    
    private static func parseYAML(_ yaml: String) throws -> ProjectSpec {
        var name: String?
        var bundleId: String?
        var scheme: String?
        var destination: String?
        var generator: String?
        var project: String?
        
        for line in yaml.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let parts = trimmed.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2 else { continue }
            
            let key = parts[0]
            let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .init(charactersIn: "\""))
            
            switch key {
            case "name": name = value
            case "bundle_id": bundleId = value
            case "scheme": scheme = value
            case "destination": destination = value
            case "generator": generator = value
            case "project": project = value
            default: break
            }
        }
        
        guard let name = name, let bundleId = bundleId else {
            throw ProjectError.invalidSpec
        }
        
        return ProjectSpec(
            name: name,
            bundleId: bundleId,
            scheme: scheme,
            destination: destination,
            generator: generator,
            project: project
        )
    }
}

enum ProjectError: Error, CustomStringConvertible {
    case specNotFound(String)
    case invalidSpec
    case projectNotFound(String)
    case schemeNotFound(String)
    
    var description: String {
        switch self {
        case .specNotFound(let path):
            return "Project spec not found at \(path)"
        case .invalidSpec:
            return "Invalid project spec (missing name or bundle_id)"
        case .projectNotFound(let path):
            return "Project not found at \(path)"
        case .schemeNotFound(let scheme):
            return "Scheme '\(scheme)' not found"
        }
    }
}

