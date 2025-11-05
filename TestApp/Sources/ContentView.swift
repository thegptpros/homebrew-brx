import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Hello, World!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your app is ready to build!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
