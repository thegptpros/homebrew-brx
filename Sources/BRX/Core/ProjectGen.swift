import Foundation

enum ProjectGen {
    static func generate(spec: ProjectSpec) throws {
        if let generator = spec.generator, generator.lowercased() == "xcodegen" {
            try generateWithXcodeGen()
        } else {
            try generateMinimalProject(spec: spec)
        }
    }
    
    private static func generateWithXcodeGen() throws {
        guard Shell.which("xcodegen") != nil else {
            throw ProjectGenError.xcodegenNotFound
        }
        
        let result = try Shell.run("/usr/bin/xcodegen", args: ["generate", "--spec", "brx.yml"])
        
        guard result.success else {
            throw ProjectGenError.generationFailed(result.stderr)
        }
        
        Logger.success("Generated project with XcodeGen")
    }
    
    private static func generateMinimalProject(spec: ProjectSpec) throws {
        let projectName = spec.name
        let projectPath = "\(projectName).xcodeproj"
        
        if FS.exists(projectPath) {
            Logger.debug("Project already exists at \(projectPath)")
            return
        }
        
        // Create minimal .xcodeproj structure
        try FS.createDirectory("\(projectPath)/project.xcworkspace/xcshareddata")
        try FS.createDirectory("\(projectPath)/xcshareddata/xcschemes")
        
        // Create pbxproj (minimal)
        let pbxproj = """
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 56;
            objects = {
                /* Begin PBXProject section */
                PROJ001 /* Project object */ = {
                    isa = PBXProject;
                    buildConfigurationList = CONF001;
                    compatibilityVersion = "Xcode 14.0";
                    mainGroup = GROUP001;
                    projectDirPath = "";
                    projectRoot = "";
                    targets = (
                    );
                };
                /* End PBXProject section */
            };
            rootObject = PROJ001;
        }
        """
        
        try FS.writeFile("\(projectPath)/project.pbxproj", contents: pbxproj)
        
        // Create shared scheme
        let schemeName = spec.scheme ?? projectName
        let scheme = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Scheme
           LastUpgradeVersion = "1500"
           version = "1.7">
           <BuildAction
              parallelizeBuildables = "YES"
              buildImplicitDependencies = "YES">
           </BuildAction>
           <TestAction
              buildConfiguration = "Debug">
           </TestAction>
           <LaunchAction
              buildConfiguration = "Debug">
           </LaunchAction>
        </Scheme>
        """
        
        try FS.writeFile("\(projectPath)/xcshareddata/xcschemes/\(schemeName).xcscheme", contents: scheme)
        
        Logger.warning("Created minimal project. Consider using XcodeGen for better project management.")
    }
}

enum ProjectGenError: Error, CustomStringConvertible {
    case xcodegenNotFound
    case generationFailed(String)
    
    var description: String {
        switch self {
        case .xcodegenNotFound:
            return "XcodeGen not found. Install with: brew install xcodegen"
        case .generationFailed(let error):
            return "Project generation failed: \(error)"
        }
    }
}

