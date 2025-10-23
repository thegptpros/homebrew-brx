import Foundation
import ArgumentParser

struct WelcomeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "welcome",
        abstract: "Interactive tutorial and onboarding experience"
    )
    
    func run() async throws {
        Signature.start()
        defer { Signature.stopBlink() }
        
        // Step 1: Welcome & Value Proposition
        await showWelcome()
        
        // Step 2: Environment Check
        await checkEnvironment()
        
        // Step 3: Create First Project
        await createFirstProject()
        
        // Step 4: Show Success Metrics
        await showSuccessMetrics()
        
        // Step 5: Guide to Purchase
        await guideToPurchase()
    }
    
    private func showWelcome() async {
        Terminal.writeLine("")
        Terminal.writeLine("🎉 Welcome to BRX!")
        Terminal.writeLine("")
        Terminal.writeLine("You're about to experience the fastest way to build iOS apps.")
        Terminal.writeLine("")
        Terminal.writeLine("✨ What you'll get:")
        Terminal.writeLine("  • 2× faster builds than Xcode")
        Terminal.writeLine("  • No more crashes or signing errors")
        Terminal.writeLine("  • Stay in your editor (Cursor, VS Code)")
        Terminal.writeLine("  • Ship to TestFlight in one command")
        Terminal.writeLine("")
        Terminal.writeLine("Let's build your first app in 60 seconds...")
        Terminal.writeLine("")
        
        // Pause for dramatic effect
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func checkEnvironment() async {
        Terminal.writeLine("🔍 Checking your development environment...")
        
        // Run doctor command
        do {
            try await DoctorCommand().run()
            Terminal.writeLine("")
            Terminal.writeLine("✅ Your environment is ready!")
        } catch {
            Terminal.writeLine("")
            Terminal.writeLine("⚠️  Some issues detected. Let's fix them:")
            Terminal.writeLine("")
            Terminal.writeLine("Run: brx doctor --fix")
            Terminal.writeLine("")
            Terminal.writeLine("Then come back and run: brx welcome")
            return
        }
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
    }
    
    private func createFirstProject() async {
        Terminal.writeLine("🚀 Creating your first app...")
        Terminal.writeLine("")
        
        let projectName = "MyFirstApp"
        
        // Check if project already exists
        if FS.exists(projectName) {
            Terminal.writeLine("📁 Project already exists. Let's use it!")
        } else {
            // Create the project using shell command
            do {
                let result = try Shell.run("brx", args: ["build", "--name", projectName])
                if result.success {
                    Terminal.writeLine("")
                    Terminal.writeLine("✅ Project created successfully!")
                } else {
                    throw ShellError.executionFailed(result.status, result.stderr)
                }
            } catch {
                Terminal.writeLine("")
                Terminal.writeLine("❌ Failed to create project: \(error)")
                Terminal.writeLine("")
                Terminal.writeLine("Let's try manually:")
                Terminal.writeLine("  brx build --name \(projectName)")
                return
            }
        }
        
        Terminal.writeLine("")
        Terminal.writeLine("🎯 Now let's run your app...")
        
        // Change to project directory and run
        let originalPath = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(projectName)
        
        do {
            let result = try Shell.run("brx", args: ["run"])
            if result.success {
                Terminal.writeLine("")
                Terminal.writeLine("🎉 SUCCESS! Your app is running!")
            } else {
                throw ShellError.executionFailed(result.status, result.stderr)
            }
        } catch {
            Terminal.writeLine("")
            Terminal.writeLine("❌ Failed to run app: \(error)")
            Terminal.writeLine("")
            Terminal.writeLine("Let's try manually:")
            Terminal.writeLine("  cd \(projectName)")
            Terminal.writeLine("  brx run")
        }
        
        // Restore original path
        FileManager.default.changeCurrentDirectoryPath(originalPath)
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func showSuccessMetrics() async {
        Terminal.writeLine("")
        Terminal.writeLine("📊 What just happened:")
        Terminal.writeLine("")
        Terminal.writeLine("⏱️  Time saved: ~15 minutes")
        Terminal.writeLine("  (vs manual Xcode setup)")
        Terminal.writeLine("")
        Terminal.writeLine("🛠️  Steps automated: 8")
        Terminal.writeLine("  (project creation, build, simulator, launch)")
        Terminal.writeLine("")
        Terminal.writeLine("💡 Productivity gain: 2× faster")
        Terminal.writeLine("  (no Xcode crashes, no context switching)")
        Terminal.writeLine("")
        Terminal.writeLine("🎯 This is just the beginning...")
        Terminal.writeLine("")
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func guideToPurchase() async {
        Terminal.writeLine("🚀 Ready to unlock unlimited builds?")
        Terminal.writeLine("")
        Terminal.writeLine("✨ With a BRX license, you get:")
        Terminal.writeLine("  • Unlimited builds (no more 3-build limit)")
        Terminal.writeLine("  • TestFlight deployment (brx ship)")
        Terminal.writeLine("  • App Store submission (brx publish)")
        Terminal.writeLine("  • Live reload (brx watch)")
        Terminal.writeLine("  • Works offline after activation")
        Terminal.writeLine("")
        Terminal.writeLine("💰 Fair pricing:")
        Terminal.writeLine("  • $39/year (less than a coffee per month)")
        Terminal.writeLine("  • $79 lifetime (one-time payment)")
        Terminal.writeLine("")
        Terminal.writeLine("🎯 Get your license:")
        Terminal.writeLine("  • Visit: https://brx.dev")
        Terminal.writeLine("  • Or run: brx activate --license-key <your-key>")
        Terminal.writeLine("")
        Terminal.writeLine("💡 Pro tip: Most developers save 1.5 hours daily")
        Terminal.writeLine("   That's $150+ in time savings per month!")
        Terminal.writeLine("")
        Terminal.writeLine("Ready to ship faster? 🚀")
    }
}
