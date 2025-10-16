import SpriteKit

class GameScene: SKScene {
    private var ball: SKShapeNode?
    private var velocity = CGVector(dx: 5, dy: 5)
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Create ball
        ball = SKShapeNode(circleOfRadius: 20)
        ball?.fillColor = .systemBlue
        ball?.strokeColor = .white
        ball?.lineWidth = 2
        ball?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        if let ball = ball {
            addChild(ball)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let ball = ball else { return }
        
        // Update position
        ball.position.x += velocity.dx
        ball.position.y += velocity.dy
        
        // Bounce off walls
        let radius: CGFloat = 20
        
        if ball.position.x - radius < 0 || ball.position.x + radius > size.width {
            velocity.dx *= -1
        }
        
        if ball.position.y - radius < 0 || ball.position.y + radius > size.height {
            velocity.dy *= -1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Randomize velocity on tap
        velocity.dx = CGFloat.random(in: -10...10)
        velocity.dy = CGFloat.random(in: -10...10)
    }
}

