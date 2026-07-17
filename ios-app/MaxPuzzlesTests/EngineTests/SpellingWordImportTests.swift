import XCTest
@testable import MaxPuzzles

final class SpellingWordImportTests: XCTestCase {
    func testHintKeyboardShowsExactlyThreeChoicesIncludingTheNextLetter() {
        let firstLetterChoices = StarSpellerHintKeyboard.visibleLetters(
            for: "Monday",
            typedCharacterCount: 0
        )
        let fourthLetterChoices = StarSpellerHintKeyboard.visibleLetters(
            for: "Monday",
            typedCharacterCount: 3
        )

        XCTAssertEqual(firstLetterChoices.count, 3)
        XCTAssertTrue(firstLetterChoices.contains("m"))
        XCTAssertEqual(fourthLetterChoices.count, 3)
        XCTAssertTrue(fourthLetterChoices.contains("d"))
    }

    func testEveryHintReducesWordScoreWithACompletionFloor() {
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 0), 100)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 1), 90)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 3), 70)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 20), 40)
    }

    func testEnglandYearOneStarterListIncludesEveryDayOfTheWeek() {
        let starterWords = Set(StarSpellerWordLibrary.englandYearOne)

        XCTAssertTrue(Set(StarSpellerWordLibrary.englandYearOneDays).isSubset(of: starterWords))
        XCTAssertEqual(
            StarSpellerWordLibrary.englandYearOneDays,
            ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        )
    }

    @MainActor
    func testCapitalisedDayAcceptsLowercaseKeyboardInput() {
        XCTAssertEqual(
            CometLearningStore.normalizedCustomWord("monday"),
            CometLearningStore.normalizedCustomWord("Monday")
        )
    }

    func testDaysOfWeekDisplayInUppercaseWithoutChangingOtherWords() {
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "Monday"), "MONDAY")
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "monday"), "MONDAY")
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "friend"), "friend")
    }

    func testEnglandYearOneStarterListIncludesTheCurriculumExceptionWords() {
        let starterWords = Set(StarSpellerWordLibrary.englandYearOne)

        XCTAssertTrue(
            Set(StarSpellerWordLibrary.englandYearOneCommonExceptionWords)
                .isSubset(of: starterWords)
        )
        XCTAssertTrue(starterWords.contains("I"))
    }

    @MainActor
    func testEnglandYearOneStarterListFitsTheSpellingAndWritingMechanics() {
        let words = StarSpellerWordLibrary.englandYearOne

        XCTAssertEqual(words.count, 100)
        XCTAssertEqual(Set(words).count, words.count)
        XCTAssertTrue(
            words.allSatisfy { word in
                !word.isEmpty
                    && word.count <= CometLearningStore.maximumCustomWordLength
                    && word.allSatisfy(\.isLetter)
                    && word.allSatisfy { LetterLibrary.glyph(for: String($0)) != nil }
            }
        )
    }

    @MainActor
    func testBulkImportAcceptsTextAndCSVSeparators() {
        let suiteName = "SpellingWordImportTests.bulk.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)

        let result = store.importCustomWords(
            from: """
            Words
            Rocket, moon
            friend;ROCKET
            can't | 12345 | elevenletters
            """
        )

        XCTAssertEqual(result.addedWords, ["rocket", "moon", "friend", "cant"])
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertEqual(result.invalidCount, 2)
        XCTAssertEqual(result.overflowCount, 0)
        XCTAssertEqual(store.activeCustomWords.map(\.text), result.addedWords)
    }

    @MainActor
    func testImportedWordsStayWithTheActiveChildProfile() {
        let suiteName = "SpellingWordImportTests.profiles.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)
        let firstProfileID = store.activeProfileID

        store.importCustomWords(from: "cat dog")
        store.addProfile(name: "Second", writingHand: .left)

        XCTAssertTrue(store.activeCustomWords.isEmpty)
        store.importCustomWords(from: "moon star")
        XCTAssertEqual(store.activeCustomWords.map(\.text), ["moon", "star"])

        store.setActiveProfile(firstProfileID)
        XCTAssertEqual(store.activeCustomWords.map(\.text), ["cat", "dog"])
    }

    @MainActor
    func testBulkImportStopsAtTheProfileWordLimit() {
        let suiteName = "SpellingWordImportTests.limit.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let words = (0..<(CometLearningStore.maximumCustomWords + 5)).map { index in
            let first = letters[(index / letters.count) % letters.count]
            let second = letters[index % letters.count]
            return "w\(first)\(second)"
        }

        let result = store.importCustomWords(from: words.joined(separator: "\n"))

        XCTAssertEqual(result.addedWords.count, CometLearningStore.maximumCustomWords)
        XCTAssertEqual(result.overflowCount, 5)
        XCTAssertEqual(store.activeCustomWords.count, CometLearningStore.maximumCustomWords)
    }
}
