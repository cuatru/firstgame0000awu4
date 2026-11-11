import SpriteKit
import WatchKit

final class HaloScene: SKScene {
    private enum Phase {
        case ready, playing, finished
    }

    var onFinish: ((RunSummary) -> Void)?

    private let ring = SKShapeNode()
    private let flashRing = SKShapeNode()
    private let target = SKShapeNode()
    private let playerAura = SKShapeNode(circleOfRadius: 13)
    private let player = SKShapeNode(circleOfRadius: 6.5)
    private let scoreLabel = SKLabelNode(text: "")
    private let hintLabel = SKLabelNode(text: "")

    private var built = false
    private var phase: Phase = .ready
    private var angle = -Double.pi / 2
    // Arco objetivo fijo a las 12 en punto (feedback Agente C: el dedo nunca lo tapa)
    private let targetAngle = Double.pi / 2
    private var lastTime: TimeInterval?
    private var lastHapticAt: TimeInterval = 0
    private var elapsed = 0.0
    private var hitCount = 0
    private var combo = 0
    private var bestCombo = 0
    private var score = 0
    private var lives = 3

    private var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2 - 4)
    }

    private var radius: CGFloat {
        min(size.width, size.height) * 0.27
    }

    override init() {
        super.init(size: CGSize(width: 205, height: 251))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sceneDidLoad() {
        backgroundColor = .clear
        guard !built else { return }
        built = true

        ring.fillColor = .clear
        ring.strokeColor = SKColor.white.withAlphaComponent(0.18)
        ring.lineWidth = 2

        flashRing.fillColor = .clear
        flashRing.lineWidth = 6
        flashRing.alpha = 0
        flashRing.zPosition = 1

        target.fillColor = .clear
        target.strokeColor = .cyan
        target.lineWidth = 8
        target.lineCap = .round
        target.glowWidth = 7   // único glow real de la escena (auditoría perf M2)

        playerAura.fillColor = SKColor.cyan.withAlphaComponent(0.22)
        playerAura.strokeColor = .clear

        player.fillColor = .white
        player.strokeColor = .white

        scoreLabel.fontName = "HelveticaNeue-Bold"
        scoreLabel.fontSize = 17
        scoreLabel.fontColor = .white

        hintLabel.fontName = "HelveticaNeue-Medium"
        hintLabel.fontSize = 11
        hintLabel.fontColor = SKColor.white.withAlphaComponent(0.8)

        addChild(ring)
        addChild(flashRing)
        addChild(target)
        addChild(playerAura)
        addChild(player)
        addChild(scoreLabel)
        addChild(hintLabel)

        playerAura.run(
            SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.scale(to: 1.25, duration: 0.7),
                    SKAction.scale(to: 0.9, duration: 0.7)
                ])
            )
        )

        restart()
    }

    override func didChangeSize(_ oldValue: CGSize) {
        if built {
            layout()
        }
    }

    func restart() {
        phase = .ready
        angle = -Double.pi / 2
        lastTime = nil
        elapsed = 0
        hitCount = 0
        combo = 0
        bestCombo = 0
        score = 0
        lives = 3

        target.removeAllActions()
        target.setScale(1)
        target.alpha = 1
        player.removeAllActions()
        player.alpha = 1
        flashRing.removeAllActions()
        flashRing.alpha = 0

        layout()
        updateHUD()
        hintLabel.text = "TAP TO START"

        // Fase ready auto-demostrativa: el arco pulsa hasta el primer tap (feedback Agente C)
        target.run(
            SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.scale(to: 1.08, duration: 0.5),
                    SKAction.scale(to: 0.96, duration: 0.5)
                ])
            ),
            withKey: "readyPulse"
        )
    }

    func tap() {
        switch phase {
        case .ready:
            phase = .playing
            lastTime = nil
            target.removeAction(forKey: "readyPulse")
            target.setScale(1)
            hintLabel.text = "TAP AT THE TOP"
        case .playing:
            judge()
        case .finished:
            break
        }
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
        let delta = min(max(currentTime - previous, 0), 0.05)
        elapsed += delta
        angle = GameRules.wrappedAngle(
            angle + GameRules.haloSpeed(hit: hitCount) * delta
        )
        positionPlayer()
    }

    private func judge() {
        let tolerance = GameRules.haloTolerance(hit: hitCount)
        let distance = GameRules.angularDistance(angle, targetAngle)

        guard distance <= tolerance else {
            lives -= 1
            combo = combo / 2   // combo a la mitad, no a 0 (feedback Agente C)
            score = max(0, score - GameRules.haloFailPenalty)
            playHaptic(.failure)
            flash(.red)

            player.run(
                SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.2, duration: 0.08),
                    SKAction.fadeAlpha(to: 1, duration: 0.15)
                ])
            )

            if lives <= 0 {
                lives = 0
                finish(cleared: false)
            } else {
                hintLabel.text = "MISS  •  \(lives) SHIELDS"
                updateHUD()
            }
            return
        }

        hitCount += 1
        combo += 1
        bestCombo = max(bestCombo, combo)
        score += GameRules.haloPoints(combo: combo)
        playHaptic(.click)
        flash(.green)
        flashTarget()

        if hitCount >= GameRules.haloHitsToFinish {
            score += lives * 100
            updateHUD()
            finish(cleared: true)
            return
        }

        hintLabel.text = combo > 1
            ? "COMBO ×\(combo)"
            : "NICE  •  KEEP FLOWING"
        updateHUD()
    }

    private func finish(cleared: Bool) {
        guard phase != .finished else { return }
        phase = .finished
        hintLabel.text = cleared ? "FLOW COMPLETE" : "RUN OVER"

        if cleared {
            playHaptic(.success)
        }

        let detail = cleared
            ? "Best combo ×\(bestCombo)  •  \(lives) shields left"
            : "\(hitCount)/\(GameRules.haloHitsToFinish) gates  •  Best combo ×\(bestCombo)"

        onFinish?(
            RunSummary(
                score: score,
                cleared: cleared,
                detail: detail,
                bestCombo: bestCombo,
                elapsed: elapsed
            )
        )
    }

    // Flash visual de 120ms sincronizado con el haptic (feedback Agente C)
    private func flash(_ color: SKColor) {
        flashRing.removeAllActions()
        flashRing.strokeColor = color
        flashRing.alpha = 0.9
        flashRing.run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.12),
                SKAction.run { [weak self] in self?.flashRing.alpha = 0 }
            ])
        )
    }

    // Throttle de haptics: mínimo 0.15s entre plays (auditoría perf m1)
    private func playHaptic(_ type: WKHapticType) {
        let now = Date().timeIntervalSince1970
        guard now - lastHapticAt > 0.15 else { return }
        lastHapticAt = now
        WKInterfaceDevice.current().play(type)
    }

    private func flashTarget() {
        target.removeAllActions()
        target.setScale(1)
        target.alpha = 1
        target.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.1, duration: 0.07),
                    SKAction.fadeAlpha(to: 0.45, duration: 0.07)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1, duration: 0.14),
                    SKAction.fadeAlpha(to: 1, duration: 0.14)
                ])
            ])
        )
    }

    private func layout() {
        ring.position = center
        let ringPath = CGPath(
            ellipseIn: CGRect(
                x: -radius,
                y: -radius,
                width: radius * 2,
                height: radius * 2
            ),
            transform: nil
        )
        ring.path = ringPath
        flashRing.position = center
        flashRing.path = ringPath

        target.position = center
        updateTargetPath()
        positionPlayer()

        scoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - 42
        )
        hintLabel.position = CGPoint(
            x: size.width / 2,
            y: 25
        )
    }

    private func updateTargetPath() {
        let tolerance = GameRules.haloTolerance(hit: hitCount)
        let path = CGMutablePath()
        path.addArc(
            center: .zero,
            radius: radius,
            startAngle: -CGFloat(tolerance),
            endAngle: CGFloat(tolerance),
            clockwise: false
        )
        target.path = path
        target.zRotation = CGFloat(targetAngle)
    }

    private func positionPlayer() {
        let point = CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
        player.position = point
        playerAura.position = point
    }

    private func updateHUD() {
        scoreLabel.text = "\(score)  •  \(hitCount)/\(GameRules.haloHitsToFinish)"
    }
}
