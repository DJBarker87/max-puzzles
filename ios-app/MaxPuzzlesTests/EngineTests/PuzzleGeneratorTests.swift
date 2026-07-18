import XCTest
@testable import MaxPuzzles

final class PuzzleGeneratorTests: XCTestCase {

    func testGeneratePuzzleLevel1() {
        let difficulty = DifficultyPresets.byLevel(1)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 3)
            XCTAssertEqual(puzzle.grid[0].count, 4)
            XCTAssertTrue(puzzle.grid[0][0].isStart)
            XCTAssertTrue(puzzle.grid[2][3].isFinish)
        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testGeneratePuzzleLevel5() {
        let difficulty = DifficultyPresets.byLevel(5)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 4)
            XCTAssertEqual(puzzle.grid[0].count, 5)
            let validation = PuzzleValidator.validatePuzzle(puzzle)
            XCTAssertTrue(validation.valid, "Puzzle should be valid. Errors: \(validation.errors)")
        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testGeneratePuzzleLevel10() {
        let difficulty = DifficultyPresets.byLevel(10)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 6)
            XCTAssertEqual(puzzle.grid[0].count, 8)
            let validation = PuzzleValidator.validatePuzzle(puzzle)
            XCTAssertTrue(validation.valid, "Puzzle should be valid. Errors: \(validation.errors)")
        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testGeneratePuzzleAllLevels() {
        for level in 1...10 {
            let difficulty = DifficultyPresets.byLevel(level)
            let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

            switch result {
            case .success(let puzzle):
                let validation = PuzzleValidator.validatePuzzle(puzzle)
                XCTAssertTrue(validation.valid, "Level \(level) puzzle should be valid. Errors: \(validation.errors)")
            case .failure(let error):
                XCTFail("Level \(level) generation failed: \(error)")
            }
        }
    }

    func testGeneratePuzzlePerformance() {
        let difficulty = DifficultyPresets.byLevel(5)

        measure {
            _ = PuzzleGenerator.generatePuzzle(difficulty: difficulty)
        }
    }

    func testMassGeneration() {
        // Generate 50 puzzles at Level 5 and verify all are valid
        let difficulty = DifficultyPresets.byLevel(5)
        var failures = 0

        for i in 0..<50 {
            let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

            switch result {
            case .success(let puzzle):
                let validation = PuzzleValidator.validatePuzzle(puzzle)
                if !validation.valid {
                    print("Puzzle \(i) failed validation: \(validation.errors)")
                    failures += 1
                }
            case .failure(let error):
                print("Puzzle \(i) generation failed: \(error)")
                failures += 1
            }
        }

        XCTAssertEqual(failures, 0, "\(failures) puzzles failed out of 50")
    }

    func testMassLevelOneGeneration() {
        let difficulty = DifficultyPresets.byLevel(1)
        var failures = 0

        for _ in 0..<50 {
            if case .failure = PuzzleGenerator.generatePuzzle(difficulty: difficulty) {
                failures += 1
            }
        }

        XCTAssertEqual(failures, 0, "Level 1 generation must not fail intermittently")
    }

    func testPuzzleSolutionPathIsValid() {
        let difficulty = DifficultyPresets.byLevel(5)

        for _ in 0..<10 {
            guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
                XCTFail("Generation failed")
                continue
            }

            // Walk the solution path and verify each step
            for i in 0..<(puzzle.solution.path.count - 1) {
                let current = puzzle.solution.path[i]
                let next = puzzle.solution.path[i + 1]
                let cell = puzzle.cell(at: current)!

                // Cell answer should lead to next cell
                guard let connector = puzzle.connector(between: current, and: next) else {
                    XCTFail("No connector between \(current.key) and \(next.key)")
                    continue
                }

                XCTAssertEqual(cell.answer, connector.value, "Cell \(current.key) answer should match connector to \(next.key)")
            }
        }
    }

    func testPuzzleHasValidExpressions() {
        let difficulty = DifficultyPresets.byLevel(5)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        for row in puzzle.grid {
            for cell in row {
                if cell.isStart || cell.isFinish {
                    continue
                }

                let evaluated = ExpressionGenerator.evaluateExpression(cell.expression)
                XCTAssertNotNil(evaluated, "Expression '\(cell.expression)' should be evaluable")
                XCTAssertEqual(evaluated, cell.answer, "Expression '\(cell.expression)' should equal answer \(cell.answer ?? -1)")
            }
        }
    }

    func testPuzzleConnectorUniqueness() {
        let difficulty = DifficultyPresets.byLevel(5)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        // Check each cell has unique connector values
        for row in 0..<puzzle.rows {
            for col in 0..<puzzle.cols {
                let cellConnectors = puzzle.connectors(for: Coordinate(row: row, col: col))
                let values = cellConnectors.map { $0.value }
                XCTAssertEqual(values.count, Set(values).count, "Cell (\(row),\(col)) should have unique connector values")
            }
        }
    }

    func testStartCellHasExpression() {
        let difficulty = DifficultyPresets.byLevel(3)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        let startCell = puzzle.grid[0][0]
        XCTAssertTrue(startCell.isStart)
        // START cell should have an expression (it's on the solution path)
        XCTAssertFalse(startCell.expression.isEmpty || startCell.expression == "START", "START cell should have an arithmetic expression")
    }

    func testFinishCellHasNoExpression() {
        let difficulty = DifficultyPresets.byLevel(3)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        let finishRow = puzzle.rows - 1
        let finishCol = puzzle.cols - 1
        let finishCell = puzzle.grid[finishRow][finishCol]
        XCTAssertTrue(finishCell.isFinish)
        XCTAssertTrue(finishCell.expression.isEmpty, "FINISH cell should have empty expression")
        XCTAssertNil(finishCell.answer, "FINISH cell should have nil answer")
    }

    func testStoryCompletionUnlocksNextLevelEvenWithOneStar() {
        let suiteName = "PuzzleGeneratorTests.storyUnlock.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = StoryProgress(defaults: defaults)
        XCTAssertFalse(progress.isLevelUnlocked(chapter: 1, level: 2))

        progress.recordAttempt(
            chapter: 1,
            level: 1,
            won: true,
            livesLost: 4,
            timeSeconds: 180,
            tileCount: 8
        )

        XCTAssertEqual(progress.starsForLevel(chapter: 1, level: 1), 1)
        XCTAssertTrue(progress.isLevelUnlocked(chapter: 1, level: 2))

        let reloadedProgress = StoryProgress(defaults: defaults)
        XCTAssertTrue(
            reloadedProgress.isLevelUnlocked(chapter: 1, level: 2),
            "Leaving and returning must preserve the same next-level access offered in-session"
        )
    }

    func testFailedStoryAttemptDoesNotUnlockNextLevel() {
        let suiteName = "PuzzleGeneratorTests.storyFailed.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = StoryProgress(defaults: defaults)
        progress.recordAttempt(
            chapter: 1,
            level: 1,
            won: false,
            livesLost: 5,
            timeSeconds: 90,
            tileCount: 3
        )

        XCTAssertFalse(progress.isLevelUnlocked(chapter: 1, level: 2))
    }

    func testBossRequiresEveryEarlierLevelEvenWithSparsePersistedProgress() {
        let suiteName = "PuzzleGeneratorTests.storyBossUnlock.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = StoryProgress(defaults: defaults)
        progress.recordAttempt(
            chapter: 1,
            level: 6,
            won: true,
            livesLost: 0,
            timeSeconds: 60,
            tileCount: 8
        )

        XCTAssertFalse(
            progress.isLevelUnlocked(chapter: 1, level: 7),
            "A sparse legacy or cloud record for level 6 must not expose the boss"
        )

        for level in 1...5 {
            progress.recordAttempt(
                chapter: 1,
                level: level,
                won: true,
                livesLost: 0,
                timeSeconds: 60,
                tileCount: 8
            )
        }

        XCTAssertTrue(progress.isLevelUnlocked(chapter: 1, level: 7))
    }

    func testStoryStarsRewardAccuracyWithoutSpeedPressure() {
        XCTAssertEqual(StoryDifficulty.calculateStars(livesLost: 0), 3)
        XCTAssertEqual(StoryDifficulty.calculateStars(livesLost: 1), 2)
        XCTAssertEqual(StoryDifficulty.calculateStars(livesLost: 2), 2)
        XCTAssertEqual(StoryDifficulty.calculateStars(livesLost: 3), 1)
    }

    func testWrongMoveNeverErasesEarnedPoints() {
        let earned = CircuitReward.points(afterMoveIsCorrect: true, current: 20)
        let afterMistake = CircuitReward.points(afterMoveIsCorrect: false, current: earned)

        XCTAssertEqual(earned, 30)
        XCTAssertEqual(afterMistake, earned)
        XCTAssertEqual(CircuitReward.points(correctMoves: 4), 40)
    }

    func testStoryNewPuzzleRequiresConfirmation() {
        XCTAssertTrue(CircuitNewPuzzleSafeguard.requiresConfirmation(isStoryMode: true))
        XCTAssertFalse(CircuitNewPuzzleSafeguard.requiresConfirmation(isStoryMode: false))
    }

    func testHiddenRevealOwnsTheOnlyPendingSummarySchedule() {
        XCTAssertEqual(
            CircuitSummarySchedulingPolicy.decision(
                for: .revealing,
                isHiddenMode: true,
                isShowingSolution: false,
                hasPendingSummary: false
            ),
            .revealHiddenAndSchedule(
                delayNanoseconds: CircuitSummarySchedulingPolicy.hiddenRevealDelayNanoseconds
            )
        )

        XCTAssertEqual(
            CircuitSummarySchedulingPolicy.decision(
                for: .won,
                isHiddenMode: true,
                isShowingSolution: false,
                hasPendingSummary: true
            ),
            .keepPending,
            "Publishing a pass after hidden reveal must not install a second delayed callback"
        )

        XCTAssertEqual(
            CircuitSummarySchedulingPolicy.decision(
                for: .lost,
                isHiddenMode: true,
                isShowingSolution: false,
                hasPendingSummary: true
            ),
            .keepPending,
            "A failed hidden attempt must keep the reveal's existing summary callback"
        )
    }

    func testHiddenModeOnlyPassesACompletePerfectRoute() {
        let start = Coordinate(row: 0, col: 0)
        let middle = Coordinate(row: 0, col: 1)
        let finish = Coordinate(row: 0, col: 2)
        let correctMove = GameMoveResult(
            correct: true,
            fromCell: start,
            toCell: middle,
            connectorValue: 4,
            cellAnswer: 4
        )
        let wrongMove = GameMoveResult(
            correct: false,
            fromCell: middle,
            toCell: finish,
            connectorValue: 9,
            cellAnswer: 5
        )

        XCTAssertEqual(HiddenModeOutcome.status(for: HiddenModeResults()), .lost)
        XCTAssertEqual(
            HiddenModeOutcome.status(
                for: HiddenModeResults(
                    moves: [correctMove],
                    correctCount: 1,
                    mistakeCount: 0
                )
            ),
            .won
        )
        XCTAssertEqual(
            HiddenModeOutcome.status(
                for: HiddenModeResults(
                    moves: [correctMove, wrongMove],
                    correctCount: 1,
                    mistakeCount: 1
                )
            ),
            .lost,
            "Reaching FINISH after any wrong move must not complete a hidden story level"
        )
    }

    func testCircuitSummaryScheduleRejectsCancelledOrReplacedPuzzleGeneration() {
        let originalPuzzleID = UUID().uuidString

        XCTAssertTrue(
            CircuitSummarySchedulingPolicy.isCurrent(
                scheduledGeneration: 4,
                scheduledPuzzleID: originalPuzzleID,
                currentGeneration: 4,
                currentPuzzleID: originalPuzzleID
            )
        )
        XCTAssertFalse(
            CircuitSummarySchedulingPolicy.isCurrent(
                scheduledGeneration: 4,
                scheduledPuzzleID: originalPuzzleID,
                currentGeneration: 5,
                currentPuzzleID: originalPuzzleID
            ),
            "Cancellation must invalidate a callback even while the same puzzle is visible"
        )
        XCTAssertFalse(
            CircuitSummarySchedulingPolicy.isCurrent(
                scheduledGeneration: 4,
                scheduledPuzzleID: originalPuzzleID,
                currentGeneration: 4,
                currentPuzzleID: UUID().uuidString
            ),
            "A callback from the previous puzzle must never summarize the replacement puzzle"
        )
    }

    func testCircuitSummaryDoesNotScheduleWhileShowingSolution() {
        XCTAssertEqual(
            CircuitSummarySchedulingPolicy.decision(
                for: .lost,
                isHiddenMode: false,
                isShowingSolution: true,
                hasPendingSummary: false
            ),
            .cancel
        )
    }

    func testCircuitActiveCellUsesTheOriginalSharedAnimationFormulas() {
        let initial = CircuitCellAnimationFrame.values(
            at: 0,
            size: 42,
            compact: false,
            reduceMotion: false
        )
        XCTAssertEqual(initial.fastFlowPhase, 0, accuracy: 0.0001)
        XCTAssertEqual(initial.slowFlowPhase, 0, accuracy: 0.0001)
        XCTAssertEqual(initial.electricGlowOpacity, 0.65, accuracy: 0.0001)
        XCTAssertEqual(initial.shadowGlowAmount, 0.70, accuracy: 0.0001)

        let halfFastCycle = CircuitCellAnimationFrame.values(
            at: 0.4,
            size: 42,
            compact: false,
            reduceMotion: false
        )
        XCTAssertEqual(halfFastCycle.fastFlowPhase, -18, accuracy: 0.0001)
        XCTAssertEqual(halfFastCycle.slowFlowPhase, -12, accuracy: 0.0001)

        let compactElectricPeak = CircuitCellAnimationFrame.values(
            at: 0.375,
            size: 42,
            compact: true,
            reduceMotion: false
        )
        XCTAssertEqual(compactElectricPeak.electricGlowOpacity, 0.60, accuracy: 0.0001)
    }

    func testCircuitActiveCellReduceMotionUsesAStaticFrame() {
        let frame = CircuitCellAnimationFrame.values(
            at: 123.456,
            size: 63,
            compact: false,
            reduceMotion: true
        )

        XCTAssertEqual(frame.fastFlowPhase, 0)
        XCTAssertEqual(frame.slowFlowPhase, 0)
        XCTAssertEqual(frame.electricGlowOpacity, 0.55)
        XCTAssertEqual(frame.shadowGlowAmount, 0.45)
    }

    func testConfettiGenerationIsStableForASeedAndPreservesIntensityCounts() {
        let size = CGSize(width: 768, height: 1_024)
        var firstGenerator = TestSeededRandomNumberGenerator(seed: 0xC0FFEE)
        var secondGenerator = TestSeededRandomNumberGenerator(seed: 0xC0FFEE)

        let firstParticles = ConfettiParticleFactory.makeParticles(
            count: 150,
            in: size,
            burstFromCenter: true,
            colorCount: 7,
            using: &firstGenerator
        )
        let repeatedParticles = ConfettiParticleFactory.makeParticles(
            count: 150,
            in: size,
            burstFromCenter: true,
            colorCount: 7,
            using: &secondGenerator
        )
        let firstSparkles = ConfettiParticleFactory.makeSparkles(
            count: 80,
            in: size,
            using: &firstGenerator
        )
        let repeatedSparkles = ConfettiParticleFactory.makeSparkles(
            count: 80,
            in: size,
            using: &secondGenerator
        )

        XCTAssertEqual(firstParticles, repeatedParticles)
        XCTAssertEqual(firstSparkles, repeatedSparkles)
        XCTAssertEqual(firstParticles.count, 150)
        XCTAssertEqual(firstSparkles.count, 80)
        XCTAssertEqual(Set(firstParticles.map(\.shape)), Set(ConfettiShape.allCases))
        XCTAssertTrue(firstParticles.allSatisfy { $0.x == size.width / 2 })
        XCTAssertTrue(firstParticles.allSatisfy { $0.y == size.height * 0.4 })
        XCTAssertTrue(firstParticles.allSatisfy { (0..<7).contains($0.colorIndex) })
    }

    func testConfettiSimulationKeepsTheBurstAndFadeTrajectory() {
        let particle = ConfettiParticle(
            id: 0,
            x: 100,
            y: 200,
            targetY: 900,
            colorIndex: 0,
            size: 12,
            rotation: 90,
            delay: 0,
            duration: 3,
            horizontalDrift: 300,
            verticalVelocity: -100,
            shape: .rectangle
        )

        let start = ConfettiSimulation.frame(
            for: particle,
            elapsed: 0,
            burstFromCenter: true
        )
        XCTAssertEqual(start.position, CGPoint(x: 100, y: 200))
        XCTAssertEqual(start.opacity, 0, accuracy: 0.0001)
        XCTAssertEqual(start.scale, 0, accuracy: 0.0001)

        let endOfBurst = ConfettiSimulation.frame(
            for: particle,
            elapsed: 0.3,
            burstFromCenter: true
        )
        XCTAssertEqual(endOfBurst.position.x, 190, accuracy: 0.01)
        XCTAssertEqual(endOfBurst.position.y, 100, accuracy: 0.01)
        XCTAssertEqual(endOfBurst.opacity, 1, accuracy: 0.001)
        XCTAssertEqual(endOfBurst.scale, 1, accuracy: 0.001)
        XCTAssertEqual(endOfBurst.rotation, 81, accuracy: 0.001)

        let faded = ConfettiSimulation.frame(
            for: particle,
            elapsed: particle.visibleDuration,
            burstFromCenter: true
        )
        XCTAssertEqual(faded.opacity, 0, accuracy: 0.0001)
    }

    func testConfettiRetainsSystemSymbolsAndSwiftUIThreeDProjection() {
        XCTAssertEqual(ConfettiSymbolGeometry.starSystemName, "star.fill")
        XCTAssertEqual(ConfettiSymbolGeometry.sparkleSystemName, "sparkle")

        let projection = ConfettiParticleProjection.threeDRotation(
            rotationDegrees: 60,
            layoutSize: CGSize(width: 10, height: 10),
            anchor: CGPoint(x: 5, y: 5)
        )

        // Reference values from SwiftUI's former rotation3DEffect at the same angle, axis,
        // centre anchor, default perspective and layout size.
        XCTAssertEqual(projection.m11, 1.0936491673103708, accuracy: 0.0000001)
        XCTAssertEqual(projection.m12, 0.39364916731037075, accuracy: 0.0000001)
        XCTAssertEqual(projection.m13, 0.03872983346207417, accuracy: 0.0000001)
        XCTAssertEqual(projection.m21, -0.18729833462074172, accuracy: 0.0000001)
        XCTAssertEqual(projection.m22, 0.21270166537925844, accuracy: 0.0000001)
        XCTAssertEqual(projection.m23, -0.07745966692414834, accuracy: 0.0000001)
        XCTAssertEqual(projection.m31, 0.4682458365518548, accuracy: 0.0000001)
        XCTAssertEqual(projection.m32, 1.9682458365518543, accuracy: 0.0000001)
        XCTAssertEqual(projection.m33, 1.1936491673103709, accuracy: 0.0000001)

        let fullTransform = ConfettiParticleProjection.transform(
            rotationDegrees: 30,
            scale: 0.75,
            layoutSize: CGSize(width: 10, height: 10),
            anchor: CGPoint(x: 5, y: 5)
        )
        // Reference composition of SwiftUI's old rotationEffect(30),
        // rotation3DEffect(60, axis: (1, 0.5, 0)) and outer scaleEffect(0.75).
        XCTAssertEqual(fullTransform.m11, 0.6336230785566095, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m21, -0.639830969712488, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m31, 5.031039455779393, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m12, 0.32895974156977914, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m22, -0.11752334857715632, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m32, 3.942818035036886, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m13, -0.0051888137995773145, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m23, -0.08644695605603078, accuracy: 0.0000001)
        XCTAssertEqual(fullTransform.m33, 1.4581788492780405, accuracy: 0.0000001)

        let star = ConfettiParticle(
            id: 0,
            x: 0,
            y: 0,
            targetY: 100,
            colorIndex: 0,
            size: 15,
            rotation: 0,
            delay: 0,
            duration: 2,
            horizontalDrift: 0,
            verticalVelocity: 0,
            shape: .star
        )
        XCTAssertEqual(
            ConfettiSymbolGeometry.layoutSize(
                for: star,
                starSourceSize: CGSize(width: 80, height: 100)
            ),
            CGSize(width: 9.6, height: 12),
            "The SF Symbol must be uniformly font-scaled without square stretching"
        )
    }
}

private struct TestSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
