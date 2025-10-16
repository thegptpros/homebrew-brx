import SwiftUI

@main
struct TodoApp: App {
    @StateObject private var store = TodoStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

