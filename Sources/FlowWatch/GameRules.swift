import Foundation

struct RunSummary {
    let score: Int
    let cleared: Bool
    let detail: String
    let bestCombo: Int
    let elapsed: Double
}

enum GameRules {
    static let haloHitsToFinish = 12

    // CURRENT: 3 fases de 12s con 1.5s de calma entre fases (feedback Agente C: fatiga de brazo)
    static let currentPhases = 3
    static let currentPhaseLength: Double = 12
    static let currentCalmLength: Double = 1.5

    static var currentRunLength: TimeInterval {
        Double(currentPhases) * currentPhaseLength
            + Double(currentPhases - 1) * currentCalmLength
    }

    static func currentIsCalm(_ elapsed: Double) -> Bool {
        let cycle = currentPhaseLength + currentCalmLength
        let index = Int(elapsed / cycle)
        guard index < currentPhases else { return false }
        return elapsed - Double(index) * cycle >= currentPhaseLength
    }

    // Medallas (metas intermedias, feedback Agente C)
    static let haloMedalCombos = [5, 8, 12]
    static let currentMedalSurvival: [Double] = [15, 25, 35]
    static let dailyMissionRuns = 3

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

    // Floor subido de 0.14 a 0.17 rad: ventana final ~90ms -> ~110ms (feedback Agente C)
    static func haloTolerance(hit: Int) -> Double {
        max(0.17, 0.28 - 0.009 * Double(max(0, hit)))
    }

    static func haloPoints(combo: Int) -> Int {
        100 + 15 * min(max(combo - 1, 0), 10)
    }

    static let haloFailPenalty = 30     // era 50: castigo suavizado (feedback Agente C)
    static let currentFailPenalty = 50  // era 75

    static func currentSpeed(elapsed: Double) -> Double {
        min(160, 85 + max(0, elapsed) * 1.8)
    }

    static func currentSpawnInterval(elapsed: Double) -> Double {
        max(0.72, 1.2 - max(0, elapsed) * 0.011)
    }
}
