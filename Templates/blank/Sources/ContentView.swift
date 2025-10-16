import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "swift")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Hello, brx!")
                .font(.title)
                .padding()
            
            Spacer()
            
            Link("Built with brx.dev", destination: URL(string: "https://brx.dev")!)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
    }
}

