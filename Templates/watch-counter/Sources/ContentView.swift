import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
            
            HStack(spacing: 20) {
                Button(action: decrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                }
                
                Button(action: increment) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
            
            Button(action: reset) {
                Text("Reset")
                    .font(.caption)
            }
            
            Spacer()
            
            Link("brx.dev", destination: URL(string: "https://brx.dev")!)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private func increment() {
        count += 1
        WKInterfaceDevice.current().play(.click)
    }
    
    private func decrement() {
        count -= 1
        WKInterfaceDevice.current().play(.click)
    }
    
    private func reset() {
        count = 0
        WKInterfaceDevice.current().play(.success)
    }
}

