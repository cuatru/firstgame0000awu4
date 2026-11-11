import SpriteKit
import WatchKit

final class CurrentScene: SKScene {
    private enum Phase {
        case ready, playing, finished
    }

    private struct Gate {
        let top: SKShapeNode
        let bottom: SKShapeNode
        var x: CGFloat
        let gapY: CGFloat
        let gap: CGFloat
        var passed = false
    }

    var onFinish: ((RunSummary) -> Void)?

    private let playerAura = SKShapeNode(circleOfRadius: 14)
    private let player = SKShapeNode(circleOfRadius: 7)
    private let scoreLabel = SKLabelNode(text: "")
    private let hintLabel = SKLabelNode(text: "")

    private var built = false
    private var phase: Phase = .ready
    private var gates: [Gate] = []
    private var holding = false
    private var playerY: CGFloat = 125
    private var velocityY: CGFloat = 0
    private var elapsed: Double = 0
    private var spawnIn: Double = 0.8
    private var lastTime: TimeInterval?
    private var score = 0
    private var lives = 3
    private var combo = 0
    private var passedGates = 0

    private var playerX: CGFloat {
        size.width * 0.25
    }

    init() {
        super.init(size: CGSize(width: 205, height: 251))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        guard !built else { return }
        built = true

        playerAura.fillColor = SKColor.cyan.withAlphaComponent(0.20)
        playerAura.strokeColor = .clear

        player.fillColor = .white
        player.strokeColor = .cyan
        player.lineWidth = 1.5
        player.glowWidth = 5

        scoreLabel.fontName = "HelveticaNeue-Bold"
        scoreLabel.fontSize = 17
        scoreLabel.fontColor = .white

        hintLabel.fontName = "HelveticaNeue-Medium"
        hintLabel.fontSize = 11
        hintLabel.fontColor = SKColor.white.withAlphaComponent(0.8)

        addChild(playerAura)
        addChild(player)
        addChild(scoreLabel)
        addChild(hintLabel)

        playerAura.run(
            SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.3, duration: 0.8),
                        SKAction.fadeAlpha(to: 0.45, duration: 0.8)
                    ]),
                    SKAction.group([
                        SKAction.scale(to: 0.9, duration: 0.8),
                        SKAction.fadeAlpha(to: 1, duration: 0.8)
                    ])
                ])
            )
        )

        restart()
    }

    func restart() {
        for gate in gates {
            gate.top.removeFromParent()
            gate.bottom.removeFromParent()
        }
        gates.removeAll()

        phase = .ready
        holding = false
        playerY = size.height / 2
        velocityY = 0
        elapsed = 0
        spawnIn = 0.8
        lastTime = nil
        score = 0
        lives = 3
        combo = 0
        passedGates = 0

        player.removeAllActions()
        player.alpha = 1
        player.position = CGPoint(x: playerX, y: playerY)
        playerAura.position = player.position

        scoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - 42
        )
        hintLabel.position = CGPoint(
            x: size.width / 2,
            y: 25
        )

        scoreLabel.text = "35 SECOND RUN"
        hintLabel.text = "HOLD TO RISE"
    }

    func holdingChanged(_ value: Bool) {
        if value && phase == .ready {
            phase = .playing
            lastTime = nil
            hintLabel.text = "RELEASE TO SINK"
        }

        holding = value && phase == .playing
    }

    override func update(_ currentTime: TimeInterval) {
        guard phase == .playing else {
            lastTime = nil
            return
        }

        guard let previous = lastTime else {
            lastTime = currentTime
            return
        }

        lastTime = currentTime
        let seconds = min(max(currentTime - previous, 0), 0.04)
        let delta = CGFloat(seconds)
        elapsed += seconds

        if elapsed >= GameRules.currentRunLength {
            elapsed = GameRules.currentRunLength
            updateHUD()
            finish(cleared: true)
            return
        }

        let targetVelocity: CGFloat = holding ? 100 : -100
        let blend = min(1, delta * 8)
        velocityY += (targetVelocity - velocityY) * blend
        playerY += velocityY * delta

        let minimumY: CGFloat = 38
        let maximumY = size.height - 42

        if playerY < minimumY {
            playerY = minimumY
            velocityY = 0
        } else if playerY > maximumY {
            playerY = maximumY
            velocityY = 0
        }

        player.position = CGPoint(x: playerX, y: playerY)
        playerAura.position = player.position

        spawnIn -= seconds
        if spawnIn <= 0 {
            spawnGate()
            spawnIn = GameRules.currentSpawnInterval(elapsed: elapsed)
        }

        updateGates(
            delta: delta,
            speed: CGFloat(GameRules.currentSpeed(elapsed: elapsed))
        )
        updateHUD()
    }

    private func spawnGate() {
        let progress = elapsed / GameRules.currentRunLength
        let gap = max(66, 92 - CGFloat(progress) * 26)
        let margin: CGFloat = 48
        let lower = margin + gap / 2
        let upper = size.height - margin - gap / 2
        let gapY = lower < upper
            ? CGFloat.random(in: lower...upper)
            : size.height / 2

        let width: CGFloat = 16
        let x = size.width + 24

        let top = SKShapeNode(
            rect: CGRect(
                x: -width / 2,
                y: 0,
                width: width,
                height: size.height
            ),
            cornerRadius: 7
        )
        let bottom = SKShapeNode(
            rect: CGRect(
                x: -width / 2,
                y: -size.height,
                width: width,
                height: size.height
            ),
            cornerRadius: 7
        )

        for node in [top, bottom] {
            node.fillColor = SKColor.white.withAlphaComponent(0.16)
            node.strokeColor = SKColor.cyan.withAlphaComponent(0.72)
            node.lineWidth = 1
            node.glowWidth = 3
            addChild(node)
        }

        top.position = CGPoint(x: x, y: gapY + gap / 2)
        bottom.position = CGPoint(x: x, y: gapY - gap / 2)

        gates.append(
            Gate(top: top, bottom: bottom, x: x, gapY: gapY, gap: gap)
        )
    }

    private func updateGates(delta: CGFloat, speed: CGFloat) {
        let playerRadius: CGFloat = 7
        let gateWidth: CGFloat = 16
        var index = gates.count - 1

        while index >= 0 {
            gates[index].x -= speed * delta
            let x = gates[index].x
            gates[index].top.position.x = x
            gates[index].bottom.position.x = x

            let gate = gates[index]
            let overlapsX = abs(x - playerX) < gateWidth / 2 + playerRadius
            let safelyInsideGap =
                abs(playerY - gate.gapY) + playerRadius < gate.gap / 2

            if overlapsX && !safelyInsideGap {
                removeGate(at: index)
                registerHit()

                if phase == .finished {
                    return
                }
            } else {
                if !gates[index].passed && x < playerX - gateWidth {
                    gates[index].passed = true
                    passedGates += 1
                    combo += 1
                    score += 100 + min(combo - 1, 10) * 10

                    if combo % 3 == 0 {
                        WKInterfaceDevice.current().play(.click)
                    }
                    hintLabel.text = "COMBO ×\(combo)  •  \(lives) SHIELDS"
                }

                if x < -30 {
                    removeGate(at: index)
                }
            }

            index -= 1
        }
    }

    private func removeGate(at index: Int) {
        gates[index].top.removeFromParent()
        gates[index].bottom.removeFromParent()
        gates.remove(at: index)
    }

    private func registerHit() {
        lives -= 1
        combo = 0
        score = max(0, score - 75)
        WKInterfaceDevice.current().play(.failure)

        player.run(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.08),
                SKAction.fadeAlpha(to: 1, duration: 0.16)
            ])
        )

        if lives == 0 {
            finish(cleared: false)
        } else {
            hintLabel.text = "HIT  •  \(lives) SHIELDS LEFT"
        }
    }

    private func finish(cleared: Bool) {
        guard phase != .finished else { return }
        phase = .finished
        holding = false

        score += Int(elapsed * 5)
        if cleared {
            score += 500 + lives * 100
            WKInterfaceDevice.current().play(.success)
        }

        updateHUD()
        hintLabel.text = cleared ? "FLOW COMPLETE" : "RUN OVER"

        let detail = cleared
            ? "\(passedGates) gates cleared  •  \(lives) shields left"
            : "\(passedGates) gates  •  \(Int(elapsed)) seconds survived"

        onFinish?(
            RunSummary(score: score, cleared: cleared, detail: detail)
        )
    }

    private func updateHUD() {
        let remaining = max(
            0,
            Int(ceil(GameRules.currentRunLength - elapsed))
        )
        scoreLabel.text = "\(score)  •  \(remaining)s"
    }
}
