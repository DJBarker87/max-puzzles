import XCTest
@testable import MaxPuzzles

/// Stress test puzzle generation for all story mode configurations
/// Run with: xcodebuild test -project MaxPuzzles.xcodeproj -scheme MaxPuzzles -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:MaxPuzzlesTests/GenerationStressTest
final class GenerationStressTest: XCTestCase {

    /// Test 400 puzzles per story level configuration
    func testStoryModeGenerationReliability() {
        let iterations = 400

        var results: [(level: String, successes: Int, failures: Int)] = []

        // Test all 50 story levels (10 chapters × 5 levels)
        for chapter in 1...10 {
            for level in 1...5 {
                let storyLevel = StoryLevel(chapter: chapter, level: level)
                let settings = StoryDifficulty.settings(for: storyLevel)

                var successes = 0
                var failures = 0

                for _ in 0..<iterations {
                    let result = PuzzleGenerator.generatePuzzle(difficulty: settings)
                    switch result {
                    case .success:
                        successes += 1
                    case .failure:
                        failures += 1
                    }
                }

                let levelName = "\(chapter)-\(["A", "B", "C", "D", "E"][level - 1])"
                results.append((levelName, successes, failures))

                // Print progress
                let successRate = Double(successes) / Double(iterations) * 100
                print("\(levelName): \(successes)/\(iterations) (\(String(format: "%.1f", successRate))% success)")
            }
        }

        // Print summary
        print("\n=== SUMMARY ===")
        let failedLevels = results.filter { $0.failures > 0 }
        if failedLevels.isEmpty {
            print("All levels achieved 100% generation success!")
        } else {
            print("Levels with failures:")
            for level in failedLevels {
                let failRate = Double(level.failures) / Double(iterations) * 100
                print("  \(level.level): \(level.failures) failures (\(String(format: "%.1f", failRate))%)")
            }
        }

        // Total stats
        let totalSuccesses = results.reduce(0) { $0 + $1.successes }
        let totalFailures = results.reduce(0) { $0 + $1.failures }
        let totalRate = Double(totalSuccesses) / Double(totalSuccesses + totalFailures) * 100
        print("\nTotal: \(totalSuccesses)/\(totalSuccesses + totalFailures) (\(String(format: "%.1f", totalRate))% success)")

        // Fail test if any level has more than 5% failure rate
        for level in results {
            let failRate = Double(level.failures) / Double(iterations) * 100
            XCTAssertLessThan(failRate, 5.0, "Level \(level.level) has \(String(format: "%.1f", failRate))% failure rate")
        }
    }

    /// Quick test - fewer iterations for faster feedback
    func testQuickGenerationCheck() {
        let iterations = 50

        print("Quick generation test (50 iterations per level)...")

        var anyFailures = false

        for chapter in 1...10 {
            for level in 1...5 {
                let storyLevel = StoryLevel(chapter: chapter, level: level)
                let settings = StoryDifficulty.settings(for: storyLevel)

                var failures = 0
                for _ in 0..<iterations {
                    if case .failure = PuzzleGenerator.generatePuzzle(difficulty: settings) {
                        failures += 1
                    }
                }

                if failures > 0 {
                    let levelName = "\(chapter)-\(["A", "B", "C", "D", "E"][level - 1])"
                    print("  \(levelName): \(failures)/\(iterations) failures")
                    anyFailures = true
                }
            }
        }

        if !anyFailures {
            print("All levels passed quick check!")
        }
    }
}
