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
        XCTAssertEqual(GameRules.haloTolerance(hit: 10_000), 0.14, accuracy: 0.0001)
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
}
