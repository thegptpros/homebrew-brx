import Foundation
import ArgumentParser

struct DevicesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "List and manage simulators and devices",
        subcommands: [List.self, Create.self, SetDefault.self],
        defaultSubcommand: List.self
    )
}

extension DevicesCommand {
    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all simulators and devices"
        )
        
        func run() async throws {
            Signature.start()
            defer { Signature.stopBlink() }
            
            let config = BRXConfig.load()
            
            Terminal.writeLine("")
            Terminal.writeLine("\(Theme.current.primary)iOS Simulators:\(Ansi.reset)")
            Terminal.writeLine("")
            
            try listSimulators(platform: .iOS, defaultDevice: config.defaults.iosDevice)
            
            Terminal.writeLine("")
            Terminal.writeLine("\(Theme.current.primary)watchOS Simulators:\(Ansi.reset)")
            Terminal.writeLine("")
            
            try listSimulators(platform: .watchOS, defaultDevice: config.defaults.watchDevice)
            
            // Physical devices
            if DeviceCtl.isAvailable() {
                Terminal.writeLine("")
                Terminal.writeLine("\(Theme.current.primary)Connected devices:\(Ansi.reset)")
                Terminal.writeLine("")
                
                do {
                    let devices = try DeviceCtl.listPhysicalDevices()
                    if devices.isEmpty {
                        Terminal.writeLine("  \(Theme.current.muted)No physical devices connected\(Ansi.reset)")
                        Terminal.writeLine("  \(Theme.current.muted)→ Connect your iPhone via USB to see it here\(Ansi.reset)")
                    } else {
                        for device in devices {
                            let isTrusted = (try? DeviceCtl.checkDeviceTrust(udid: device.udid)) ?? false
                            let trustStatus = isTrusted ? Theme.current.success + "●" + Ansi.reset : Theme.current.muted + "○" + Ansi.reset
                            Terminal.writeLine("  \(trustStatus) \(device.name)")
                            if !isTrusted {
                                Terminal.writeLine("    \(Theme.current.muted)→ Unlock device and tap 'Trust' to enable deployment\(Ansi.reset)")
                            }
                        }
                    }
                } catch {
                    Terminal.writeLine("  \(Theme.current.error)Failed to list physical devices: \(error)\(Ansi.reset)")
                }
            } else {
                Terminal.writeLine("")
                Terminal.writeLine("\(Theme.current.primary)Connected devices:\(Ansi.reset)")
                Terminal.writeLine("")
                Terminal.writeLine("  \(Theme.current.muted)devicectl not available (requires Xcode 15+)\(Ansi.reset)")
            }
            
            Terminal.writeLine("")
        }
        
        private func listSimulators(platform: Platform, defaultDevice: String) throws {
            let result = try Shell.run("/usr/bin/xcrun", args: ["simctl", "list", "devices", "--json"])
            
            guard result.success else { return }
            
            let data = result.stdout.data(using: .utf8)!
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let devicesDict = json["devices"] as! [String: [[String: Any]]]
            
            for (runtimeKey, devices) in devicesDict.sorted(by: { $0.key > $1.key }) {
                guard runtimeKey.contains(platform.identifier) else { continue }
                
                for device in devices {
                    guard let name = device["name"] as? String,
                          let state = device["state"] as? String else { continue }
                    
                    let isDefault = name == defaultDevice
                    let marker = isDefault ? Theme.current.success + " [default]" + Ansi.reset : ""
                    let stateText = state == "Booted" ? Theme.current.success + "●" + Ansi.reset : Theme.current.muted + "○" + Ansi.reset
                    
                    Terminal.writeLine("  \(stateText) \(name)\(marker)")
                }
            }
        }
    }
    
    struct Create: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "create",
            abstract: "Create a new simulator"
        )
        
        @Option(name: .long, help: "Device name")
        var name: String
        
        @Option(name: .long, help: "Platform (ios or watchos)")
        var platform: String = "ios"
        
        func run() async throws {
            Signature.start()
            defer { Signature.stopBlink() }
            
            let platformType: Platform = platform.lowercased() == "watchos" ? .watchOS : .iOS
            let udid = try Simulator.ensureDevice(named: name, platform: platformType)
            
            Logger.success("Created simulator '\(name)' (\(udid))")
            Terminal.writeLine("")
        }
    }
    
    struct SetDefault: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set-default",
            abstract: "Set default device"
        )
        
        @Option(name: .long, help: "iOS device name")
        var ios: String?
        
        @Option(name: .long, help: "watchOS device name")
        var watch: String?
        
        func run() async throws {
            Signature.start()
            defer { Signature.stopBlink() }
            
            var config = BRXConfig.load()
            
            if let iosDevice = ios {
                config.defaults.iosDevice = iosDevice
                Logger.success("Set default iOS device to '\(iosDevice)'")
            }
            
            if let watchDevice = watch {
                config.defaults.watchDevice = watchDevice
                Logger.success("Set default watchOS device to '\(watchDevice)'")
            }
            
            try config.save()
            Terminal.writeLine("")
        }
    }
}

