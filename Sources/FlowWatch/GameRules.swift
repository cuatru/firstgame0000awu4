import Foundation

struct RunSummary {
    let score: Int
    let cleared: Bool
    let detail: String
}

enum GameRules {
    static let haloHitsToFinish = 12
    static let currentRunLength: TimeInterval = 35

    static func wrappedAngle(_ angle: Double) -> Double {
        let circle = 2 * Double.pi
        let value = angle.truncatingRemainder(dividingBy: circle)
        return value < 0 ? value + circle : value
    }

    static func angularDistance(_ first: Double, _ second: Double) -> Double {
        let difference = abs(wrappedAngle(first) - wrappedAngle(second))
        return min(difference, 2 * Double.pi - difference)
    }

    static func haloSpeed(hit: Int) -> Double {
        min(3.1, 1.65 + 0.12 * Double(max(0, hit)))
    }

    static func haloTolerance(hit: Int) -> Double {
        max(0.14, 0.28 - 0.009 * Double(max(0, hit)))
    }

    static func haloPoints(combo: Int) -> Int {
        100 + 15 * min(max(combo - 1, 0), 10)
    }

    static func currentSpeed(elapsed: Double) -> Double {
        min(160, 85 + max(0, elapsed) * 1.8)
    }

    static func currentSpawnInterval(elapsed: Double) -> Double {
        max(0.72, 1.2 - max(0, elapsed) * 0.011)
    }
}
