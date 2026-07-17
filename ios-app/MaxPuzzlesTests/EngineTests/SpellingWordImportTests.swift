import XCTest
@testable import MaxPuzzles

final class SpellingWordImportTests: XCTestCase {
    func testVoiceOverPreventsCompetingPromptAudioAndAutomaticInputFocus() {
        XCTAssertFalse(
            StarSpellerAccessibilityPolicy.shouldUseAppPromptAudio(
                isVoiceOverRunning: true
            )
        )
        XCTAssertFalse(
            StarSpellerAccessibilityPolicy.shouldAutomaticallyFocusInput(
                isVoiceOverRunning: true
            )
        )
        XCTAssertTrue(
            StarSpellerAccessibilityPolicy.shouldUseAppPromptAudio(
                isVoiceOverRunning: false
            )
        )
        XCTAssertTrue(
            StarSpellerAccessibilityPolicy.shouldAutomaticallyFocusInput(
                isVoiceOverRunning: false
            )
        )
    }

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

    func testEveryAvailableHintReducesWordScore() {
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 0), 100)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 1), 90)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 3), 70)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 10), 0)
        XCTAssertEqual(StarSpellerScoring.points(forHintUses: 20), 0)
        XCTAssertTrue(StarSpellerScoring.canUseAnotherHint(after: 9))
        XCTAssertFalse(StarSpellerScoring.canUseAnotherHint(after: 10))
    }

    func testLongWordsUseAFingerFriendlyFourCharacterWritingWindow() {
        XCTAssertEqual(
            WordMissionLayout.visibleIndices(characterCount: 9, activeIndex: 0),
            [0, 1, 2, 3]
        )
        XCTAssertEqual(
            WordMissionLayout.visibleIndices(characterCount: 9, activeIndex: 8),
            [5, 6, 7, 8]
        )
        XCTAssertEqual(
            WordMissionLayout.aspectRatio(characterCount: 9),
            CGFloat(4) / 1.18,
            accuracy: 0.001
        )
    }

    func testEnglandYearOneStarterListIncludesEveryDayOfTheWeek() {
        let starterWords = Set(StarSpellerWordLibrary.englandYearOne)

        XCTAssertTrue(Set(StarSpellerWordLibrary.englandYearOneDays).isSubset(of: starterWords))
        XCTAssertEqual(
            StarSpellerWordLibrary.englandYearOneDays,
            ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        )
    }

    func testEveryDefaultWordHasAnAuthoredContextSentence() {
        XCTAssertEqual(StarSpellerWordLibrary.contextSentences.count, 100)

        for word in StarSpellerWordLibrary.englandYearOne {
            let context = StarSpellerWordLibrary.contextSentence(for: word)
            XCTAssertNotNil(context, "Missing context sentence for \(word)")
            XCTAssertFalse(context?.isEmpty ?? true, "Empty context sentence for \(word)")
        }
    }

    func testSpokenPromptInterpolatesTheTargetAndDisambiguatingContext() {
        let context = "The red ball is over there."
        let prompt = StarSpellerWordLibrary.spokenPrompt(
            for: "there",
            contextSentence: context
        )

        XCTAssertTrue(prompt.contains("Spell the word there."))
        XCTAssertTrue(prompt.contains(context))
        XCTAssertFalse(prompt.contains("(word)"))
        XCTAssertFalse(prompt.contains("(context)"))
        XCTAssertNotEqual(
            StarSpellerWordLibrary.contextSentence(for: "there"),
            StarSpellerWordLibrary.contextSentence(for: "their")
        )
    }

    func testPracticeGroupsExposeClearPhonicsAndDifficultyChoices() {
        XCTAssertEqual(
            Set(StarSpellerPracticeGroup.starterPhonics.words(customWords: [])),
            Set(StarSpellerWordLibrary.starterPhonicsWords)
        )
        XCTAssertTrue(StarSpellerPracticeGroup.starterPhonics.difficulty.contains("Phonics"))
        XCTAssertTrue(StarSpellerPracticeGroup.soundPatterns.difficulty.contains("Phonics"))
        XCTAssertEqual(
            StarSpellerPracticeGroup.daysOfWeek.words(customWords: []),
            StarSpellerWordLibrary.englandYearOneDays
        )
        XCTAssertEqual(
            StarSpellerPracticeGroup.custom.words(customWords: ["max", "rocket"]),
            ["max", "rocket"]
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
    func testCustomWordCanStoreAndImportAnOptionalContextSentence() throws {
        let suiteName = "SpellingWordImportTests.context.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)

        let added = try XCTUnwrap(
            store.addCustomWord(
                "hare",
                contextSentence: "The brown hare ran across the field."
            )
        )
        XCTAssertEqual(
            added.contextSentence,
            "The brown hare ran across the field."
        )

        let result = store.importCustomWords(
            from: """
            word,context
            pair,A matching pair of socks.
            knight,The knight rode a horse.
            """
        )
        XCTAssertEqual(result.addedWords, ["pair", "knight"])
        XCTAssertEqual(
            store.activeCustomWords.first(where: { $0.text == "knight" })?.contextSentence,
            "The knight rode a horse."
        )
    }

    func testCustomWordCodableRemainsCompatibleWithoutAContextField() throws {
        let legacy = LegacyCustomWord(
            id: UUID(),
            profileID: UUID(),
            text: "moon",
            recordingFilename: nil,
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(CometCustomWord.self, from: data)

        XCTAssertEqual(decoded.text, "moon")
        XCTAssertNil(decoded.contextSentence)
    }

    @MainActor
    func testSpellingMasterySummaryAndAdaptiveRepetitionAreProfileScoped() {
        let suiteName = "SpellingWordImportTests.mastery.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)
        let firstProfileID = store.activeProfileID

        store.recordSpellingAttempt(
            word: "rain",
            checkAttempts: 2,
            errorCount: 1,
            hintUses: 1,
            wasSuccessful: false,
            pointsEarned: 0
        )
        let adaptive = store.adaptiveSpellingWords(
            from: ["coin", "rain"],
            count: 3
        )
        XCTAssertEqual(adaptive.first, "rain")
        XCTAssertEqual(adaptive.count, 3)

        for _ in 0..<3 {
            store.recordSpellingAttempt(
                word: "coin",
                checkAttempts: 1,
                errorCount: 0,
                hintUses: 0,
                wasSuccessful: true,
                pointsEarned: 100
            )
        }
        XCTAssertEqual(store.spellingMastery(for: "coin"), .mastered)
        XCTAssertEqual(store.activeSpellingSummary.masteredWords, 1)
        XCTAssertEqual(store.activeSpellingSummary.totalErrors, 1)
        XCTAssertEqual(store.activeSpellingSummary.totalHints, 1)

        store.addProfile(name: "Second", writingHand: .left)
        XCTAssertTrue(store.activeSpellingAttempts.isEmpty)
        XCTAssertEqual(store.spellingMastery(for: "coin"), .new)

        store.setActiveProfile(firstProfileID)
        XCTAssertEqual(store.spellingMastery(for: "coin"), .mastered)
    }

    @MainActor
    func testUnfinishedSpellingSessionRestoresWordStageAndScore() {
        let suiteName = "SpellingWordImportTests.resume.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)

        store.saveSpellingSession(
            words: ["rain", "night", "blue"],
            currentIndex: 1,
            score: 90,
            currentWordIsReadyToWrite: true
        )

        let reloaded = CometLearningStore(defaults: defaults)
        XCTAssertEqual(reloaded.activeSpellingSession?.words, ["rain", "night", "blue"])
        XCTAssertEqual(reloaded.activeSpellingSession?.currentIndex, 1)
        XCTAssertEqual(reloaded.activeSpellingSession?.score, 90)
        XCTAssertEqual(reloaded.activeSpellingSession?.currentWordIsReadyToWrite, true)
    }

    @MainActor
    func testSpellingAttemptHistoryPersistsOffTheMainActor() async throws {
        let suiteName = "SpellingWordImportTests.durable.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)

        store.recordSpellingAttempt(
            word: "night",
            checkAttempts: 2,
            errorCount: 1,
            hintUses: 0,
            wasSuccessful: true,
            pointsEarned: 100
        )

        await store.waitForPendingAttemptPersistence()
        let reloaded = CometLearningStore(defaults: defaults)
        let attempt = try XCTUnwrap(reloaded.activeSpellingAttempts.first)
        XCTAssertEqual(attempt.word, "night")
        XCTAssertEqual(attempt.checkAttempts, 2)
        XCTAssertEqual(attempt.errorCount, 1)
        XCTAssertEqual(attempt.hintUses, 0)
        XCTAssertTrue(attempt.wasSuccessful)
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

private struct LegacyCustomWord: Encodable {
    let id: UUID
    let profileID: UUID
    let text: String
    let recordingFilename: String?
    let createdAt: Date
}
