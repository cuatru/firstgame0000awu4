import XCTest
@testable import FlowWatch

final class GameRulesTests: XCTestCase {
    func testAngularDistanceWrapsAroundCircle() {
        XCTAssertEqual(
            GameRules.angularDistance(0.01, 2 * Double.pi - 0.01),
            0.02,
            accuracy: 0.0001
        )
    }

    func testNegativeAnglesAreWrapped() {
        XCTAssertEqual(
            GameRules.wrappedAngle(-Double.pi / 2),
            3 * Double.pi / 2,
            accuracy: 0.0001
        )
    }

    func testHaloScoringIsDeterministic() {
        XCTAssertEqual(GameRules.haloPoints(combo: 1), 100)
        XCTAssertEqual(GameRules.haloPoints(combo: 2), 115)
        XCTAssertEqual(GameRules.haloPoints(combo: 50), 250)
    }

    func testHaloDifficultyHasSafeLimits() {
        XCTAssertEqual(GameRules.haloSpeed(hit: 10_000), 3.1, accuracy: 0.0001)
        // Floor 0.17 rad (feedback de diseño: ventana final humana)
        XCTAssertEqual(GameRules.haloTolerance(hit: 10_000), 0.17, accuracy: 0.0001)
    }

    func testCurrentDifficultyHasSafeLimits() {
        XCTAssertEqual(
            GameRules.currentSpeed(elapsed: 10_000),
            160,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            GameRules.currentSpawnInterval(elapsed: 10_000),
            0.72,
            accuracy: 0.0001
        )
    }

    func testCurrentPhasesSumToTotal() {
        // 3 fases de 12s + 2 calmas de 1.5s = 39s
        XCTAssertEqual(GameRules.currentRunLength, 39, accuracy: 0.0001)
    }

    func testCalmWindows() {
        XCTAssertFalse(GameRules.currentIsCalm(5))      // fase 1
        XCTAssertTrue(GameRules.currentIsCalm(12.5))    // primera calma
        XCTAssertFalse(GameRules.currentIsCalm(14))     // fase 2
        XCTAssertTrue(GameRules.currentIsCalm(26))      // segunda calma
        XCTAssertFalse(GameRules.currentIsCalm(30))     // fase 3
    }

    func testFailPenaltiesAreSoftened() {
        XCTAssertEqual(GameRules.haloFailPenalty, 30)
        XCTAssertEqual(GameRules.currentFailPenalty, 50)
    }
}
