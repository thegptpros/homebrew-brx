import SwiftUI
import SpriteKit

struct GameView: View {
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 430, height: 932) // iPhone 17 Pro Max
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Text("Ball Game")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Text("Tap to spawn balls")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    GameView()
}

