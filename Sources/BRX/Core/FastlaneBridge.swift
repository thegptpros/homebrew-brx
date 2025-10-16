import Foundation

enum FastlaneBridge {
    static func ensureInstalled() throws {
        guard Shell.which("fastlane") != nil else {
            throw FastlaneError.notInstalled
        }
    }
    
    static func bootstrap(in directory: String = ".") throws {
        let fastlaneDir = "\(directory)/fastlane"
        
        if !FS.exists(fastlaneDir) {
            try FS.createDirectory(fastlaneDir)
        }
        
        let fastfilePath = "\(fastlaneDir)/Fastfile"
        
        if !FS.exists(fastfilePath) {
            let fastfile = """
            # BRX Fastfile
            
            default_platform(:ios)
            
            platform :ios do
              desc "Prepare signing"
              lane :brx_prepare_signing do
                # Automatic signing setup
                update_code_signing_settings(
                  use_automatic_signing: true
                )
              end
              
              desc "Build for TestFlight"
              lane :brx_build_for_testflight do
                gym(
                  scheme: ENV["SCHEME"],
                  export_method: "app-store",
                  output_directory: "./build",
                  output_name: "app.ipa"
                )
              end
              
              desc "Upload to TestFlight"
              lane :brx_upload_testflight do |options|
                pilot(
                  skip_waiting_for_build_processing: true,
                  skip_submission: true,
                  ipa: "./build/app.ipa"
                )
              end
              
              desc "Submit for App Store Review"
              lane :brx_submit_for_review do
                deliver(
                  submit_for_review: true,
                  automatic_release: false,
                  force: true,
                  skip_metadata: true,
                  skip_screenshots: true
                )
              end
            end
            """
            
            try FS.writeFile(fastfilePath, contents: fastfile)
            Logger.success("Created Fastfile at \(fastfilePath)")
        }
    }
    
    static func run(
        lane: String,
        in directory: String = ".",
        env: [String: String] = [:]
    ) throws {
        var processEnv = ProcessInfo.processInfo.environment
        for (key, value) in env {
            processEnv[key] = value
        }
        
        let result = try Shell.run("/usr/bin/fastlane", args: [lane], env: processEnv)
        
        guard result.success else {
            throw FastlaneError.laneFailed(lane, result.stderr)
        }
    }
}

enum FastlaneError: Error, CustomStringConvertible {
    case notInstalled
    case laneFailed(String, String)
    
    var description: String {
        switch self {
        case .notInstalled:
            return "Fastlane not installed. Install with: gem install fastlane"
        case .laneFailed(let lane, let error):
            return "Fastlane lane '\(lane)' failed: \(error)"
        }
    }
}

