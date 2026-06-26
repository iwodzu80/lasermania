import XCTest
@testable import LasermaniaCore

final class ScoringTests: XCTestCase {
    func testBaseScoreWithNoMovesOrCapsules() {
        XCTAssertEqual(Scoring.score(moves: 0, capsulesCollected: 0, parMoves: nil), 1000)
    }

    func testMoveCostReducesScore() {
        XCTAssertEqual(Scoring.score(moves: 10, capsulesCollected: 0, parMoves: nil), 900)
    }

    func testCapsuleBonusIncreasesScore() {
        XCTAssertEqual(Scoring.score(moves: 0, capsulesCollected: 2, parMoves: nil), 1500)
    }

    func testParBonusAwardedWhenMovesEqualsPar() {
        XCTAssertEqual(Scoring.score(moves: 10, capsulesCollected: 0, parMoves: 10), 1400)
    }

    func testParBonusAwardedWhenMovesUnderPar() {
        XCTAssertEqual(Scoring.score(moves: 5, capsulesCollected: 0, parMoves: 10), 1450)
    }

    func testNoParBonusWhenMovesExceedPar() {
        XCTAssertEqual(Scoring.score(moves: 11, capsulesCollected: 0, parMoves: 10), 890)
    }

    func testNoParBonusWhenParIsNil() {
        XCTAssertEqual(Scoring.score(moves: 5, capsulesCollected: 0, parMoves: nil), 950)
    }

    func testScoreNeverGoesNegative() {
        XCTAssertEqual(Scoring.score(moves: 1000, capsulesCollected: 0, parMoves: nil), 0)
        XCTAssertEqual(Scoring.score(moves: 1000, capsulesCollected: 1, parMoves: nil), 0)
    }

    func testRealisticScenarioMatchesExpectedScore() {
        // Mirrors a "First Light"-style clear: 9 moves, 1 capsule, par of 9.
        XCTAssertEqual(Scoring.score(moves: 9, capsulesCollected: 1, parMoves: 9), 1660)
    }
}
