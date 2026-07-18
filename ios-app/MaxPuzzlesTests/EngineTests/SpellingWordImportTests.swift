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

    func testVoiceOverPromptOmitsHostileContextButKeepsNormalContext() {
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(
                for: "cat",
                contextSentence: "c"
            ),
            "Spell the word cat."
        )
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(
                for: "cat",
                contextSentence: "C is for cat"
            ),
            "Spell the word cat."
        )
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(
                for: "cat",
                contextSentence: "I saw a cat."
            ),
            "Spell the word cat. I saw a cat."
        )
    }

    func testVoiceOverPromptNeverTurnsASingleLetterSoundIntoALetterName() {
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(for: "c"),
            "Spell the one-letter sound at the start of cat."
        )
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(for: "C"),
            "Spell the one-letter sound at the start of cat."
        )
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(for: "x"),
            "Spell the one-letter sound at the end of box."
        )
        XCTAssertEqual(
            StarSpellerWordLibrary.spokenPrompt(
                for: "c",
                contextSentence: "c is for cat"
            ),
            "Spell the one-letter sound at the start of cat."
        )
        XCTAssertFalse(StarSpellerWordLibrary.spokenPrompt(for: "c").lowercased().contains("see"))
    }

    func testVoiceOverHandoffCopyUsesOneSafeFocusedInstruction() {
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.practiceWordLabel(for: "c"),
            "Practice the one-letter sound at the start of cat"
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.practiceWordLabel(for: "x"),
            "Practice the one-letter sound at the end of box"
        )
        XCTAssertEqual(StarSpellerAccessibilityCopy.practiceWordLabel(for: "a"), "a")
        XCTAssertEqual(StarSpellerAccessibilityCopy.practiceWordLabel(for: "i"), "i")
        XCTAssertEqual(StarSpellerAccessibilityCopy.practiceWordLabel(for: "I"), "I")
        XCTAssertEqual(StarSpellerAccessibilityCopy.practiceWordLabel(for: "cat"), "cat")
        XCTAssertEqual(StarSpellerAccessibilityCopy.practiceWordLabel(for: "Monday"), "MONDAY")
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.readyWordLabel(for: "c"),
            "Spelled the one-letter sound at the start of cat."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.readyWordLabel(for: "x"),
            "Spelled the one-letter sound at the end of box."
        )
        XCTAssertEqual(StarSpellerAccessibilityCopy.readyWordLabel(for: "a"), "a")
        XCTAssertEqual(StarSpellerAccessibilityCopy.readyWordLabel(for: "I"), "I")
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.handwritingActionLabel(for: "c"),
            "Correct. You spelled the one-letter sound at the start of cat. "
                + "Choose Handwrite to continue."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.handwritingActionLabel(for: "x"),
            "Correct. You spelled the one-letter sound at the end of box. "
                + "Choose Handwrite to continue."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.handwritingActionLabel(for: "cat"),
            "Correct. cat. Choose Handwrite to continue."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: "cat"),
            "Spell cat aloud, letter by letter: C, A, T. "
                + "When you finish, choose Done spelling aloud."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: "c"),
            "Say the one-letter sound at the start of cat aloud. "
                + "When you finish, choose Done spelling aloud."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: "x"),
            "Say the one-letter sound at the end of box aloud. "
                + "When you finish, choose Done spelling aloud."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: "a"),
            "Spell a aloud, letter by letter: A. "
                + "When you finish, choose Done spelling aloud."
        )
        XCTAssertEqual(
            StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: "I"),
            "Spell I aloud, letter by letter: I. "
                + "When you finish, choose Done spelling aloud."
        )
    }

    func testEveryOneLetterNonwordUsesSafeVoiceOverCopy() {
        let oneLetterNonwords = "bcdefghjklmnopqrstuvwxyz".map(String.init)

        for word in oneLetterNonwords {
            guard let description = StarSpellerWordLibrary.oneLetterSoundDescription(for: word) else {
                XCTFail("Missing safe sound description for \(word)")
                continue
            }
            XCTAssertEqual(
                StarSpellerAccessibilityCopy.practiceWordLabel(for: word),
                "Practice \(description)",
                word
            )
            XCTAssertEqual(
                StarSpellerAccessibilityCopy.spellAloudCompletionLabel(for: word),
                "Say \(description) aloud. When you finish, choose Done spelling aloud.",
                word
            )
        }
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

    func testDaysOfWeekDisplayInCapitalsWithoutChangingOtherWords() {
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "Monday"), "MONDAY")
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "monday"), "MONDAY")
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "MONDAY"), "MONDAY")
        XCTAssertEqual(StarSpellerWordLibrary.displayForm(for: "friend"), "friend")
    }

    func testPromptAudioFailureProducesAnExplicitRecoveryState() {
        XCTAssertEqual(
            StarSpellerPromptAudioState.afterPlaybackAttempt(succeeded: true),
            .ready
        )
        XCTAssertEqual(
            StarSpellerPromptAudioState.afterPlaybackAttempt(succeeded: false),
            .failed
        )
    }

    func testMissingCustomPromptRecordingFallsBackToBuiltInVoice() {
        var requestedCustomFilename: String?
        var voiceAttempts = 0

        let succeeded = StarSpellerPromptAudioPlayback.play(
            customRecordingFilename: "missing-family-prompt.m4a",
            customPlayback: { filename, _ in
                requestedCustomFilename = filename
                return false
            },
            voicePlayback: {
                voiceAttempts += 1
                return true
            }
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(requestedCustomFilename, "missing-family-prompt.m4a")
        XCTAssertEqual(voiceAttempts, 1)
    }

    func testSuccessfulCustomPromptDoesNotAlsoSpeakBuiltInVoice() {
        var voiceAttempts = 0

        let succeeded = StarSpellerPromptAudioPlayback.play(
            customRecordingFilename: "family-prompt.m4a",
            customPlayback: { _, _ in true },
            voicePlayback: {
                voiceAttempts += 1
                return true
            }
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(voiceAttempts, 0)
    }

    @MainActor
    func testAsyncCustomPromptPreparationPreservesFallbackPolicy() async {
        var voiceAttempts = 0
        let succeeded = await StarSpellerPromptAudioPlayback.playAsync(
            customRecordingFilename: "unreadable-family-prompt.m4a",
            customPlayback: { _, _ in false },
            voicePlayback: {
                voiceAttempts += 1
                return true
            }
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(voiceAttempts, 1)
    }

    @MainActor
    func testAsyncCustomPromptPreparationDoesNotDoubleSpeak() async {
        var voiceAttempts = 0
        let succeeded = await StarSpellerPromptAudioPlayback.playAsync(
            customRecordingFilename: "family-prompt.m4a",
            customPlayback: { _, _ in true },
            voicePlayback: {
                voiceAttempts += 1
                return true
            }
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(voiceAttempts, 0)
    }

    func testFailedCustomPromptAfterStartingFallsBackToBuiltInVoiceOnce() {
        var customCompletion: ((CustomPromptAudioPlaybackOutcome) -> Void)?
        var voiceAttempts = 0
        var deferredResults: [Bool] = []

        let started = StarSpellerPromptAudioPlayback.play(
            customRecordingFilename: "corrupt-family-prompt.m4a",
            customPlayback: { _, completion in
                customCompletion = completion
                return true
            },
            voicePlayback: {
                voiceAttempts += 1
                return true
            },
            onDeferredFallback: { deferredResults.append($0) }
        )

        XCTAssertTrue(started)
        XCTAssertEqual(voiceAttempts, 0)

        customCompletion?(.failed)

        XCTAssertEqual(voiceAttempts, 1)
        XCTAssertEqual(deferredResults, [true])
    }

    func testSuccessfulCustomPromptCompletionNeverStartsBuiltInVoice() {
        var customCompletion: ((CustomPromptAudioPlaybackOutcome) -> Void)?
        var voiceAttempts = 0
        var deferredResults: [Bool] = []

        let started = StarSpellerPromptAudioPlayback.play(
            customRecordingFilename: "family-prompt.m4a",
            customPlayback: { _, completion in
                customCompletion = completion
                return true
            },
            voicePlayback: {
                voiceAttempts += 1
                return true
            },
            onDeferredFallback: { deferredResults.append($0) }
        )

        XCTAssertTrue(started)
        customCompletion?(.finished)
        XCTAssertEqual(voiceAttempts, 0)
        XCTAssertTrue(deferredResults.isEmpty)
    }

    func testCustomPromptPlayerMapsUnsuccessfulFinishesToFailure() {
        XCTAssertEqual(
            CustomPromptAudioPlaybackOutcome(didFinishSuccessfully: true),
            .finished
        )
        XCTAssertEqual(
            CustomPromptAudioPlaybackOutcome(didFinishSuccessfully: false),
            .failed
        )
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
    func testDetailedHistoryMigratesFromDefaultsToAtomicApplicationSupportFiles() async throws {
        let suiteName = "SpellingWordImportTests.file-migration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MaxPuzzlesHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }

        let profileStore = CometLearningStore(defaults: defaults)
        let profileID = profileStore.activeProfileID
        let legacy = (0..<12).map { index in
            StarSpellerAttemptRecord(
                id: UUID(),
                profileID: profileID,
                word: "moon",
                checkAttempts: 1,
                errorCount: 0,
                hintUses: 0,
                wasSuccessful: true,
                pointsEarned: 100,
                timestamp: Date(timeIntervalSinceReferenceDate: Double(index))
            )
        }
        defaults.set(
            try JSONEncoder().encode(legacy),
            forKey: "maxpuzzles.starSpeller.attempts"
        )

        let migrated = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory,
            deferDetailedHistoryLoad: true
        )
        await migrated.waitForDetailedHistoriesToLoad()
        XCTAssertEqual(migrated.activeSpellingAttempts.map(\.id), legacy.map(\.id))
        await migrated.waitForPendingAttemptPersistence()

        XCTAssertNil(defaults.data(forKey: "maxpuzzles.starSpeller.attempts"))
        let historyFile = directory.appendingPathComponent("spelling-attempts.json")
        XCTAssertGreaterThan(try Data(contentsOf: historyFile).count, 0)

        let reloaded = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory
        )
        XCTAssertEqual(reloaded.activeSpellingAttempts.map(\.id), legacy.map(\.id))
    }

    @MainActor
    func testNewerFallbackHistoryWinsOverAnOlderAtomicFile() async throws {
        let suiteName = "SpellingWordImportTests.newer-fallback.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MaxPuzzlesHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let profileStore = CometLearningStore(defaults: defaults)
        let profileID = profileStore.activeProfileID
        let oldRecord = spellingRecord(profileID: profileID, word: "old")
        let newerRecord = spellingRecord(profileID: profileID, word: "new")
        try JSONEncoder().encode([oldRecord]).write(
            to: directory.appendingPathComponent("spelling-attempts.json"),
            options: .atomic
        )
        defaults.set(
            try JSONEncoder().encode([newerRecord]),
            forKey: "maxpuzzles.starSpeller.attempts"
        )

        let store = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory,
            deferDetailedHistoryLoad: true
        )
        await store.waitForDetailedHistoriesToLoad()
        XCTAssertEqual(store.activeSpellingAttempts.map(\.id), [newerRecord.id])
        await store.waitForPendingAttemptPersistence()

        XCTAssertNil(defaults.data(forKey: "maxpuzzles.starSpeller.attempts"))
        let persisted = try JSONDecoder().decode(
            [StarSpellerAttemptRecord].self,
            from: Data(contentsOf: directory.appendingPathComponent("spelling-attempts.json"))
        )
        XCTAssertEqual(persisted.map(\.id), [newerRecord.id])
    }

    @MainActor
    func testCorruptHistoryIsQuarantinedBeforeFreshProgressIsWritten() async throws {
        let suiteName = "SpellingWordImportTests.corrupt-history.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MaxPuzzlesHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let corruptBytes = Data("not-json-progress".utf8)
        let historyURL = directory.appendingPathComponent("spelling-attempts.json")
        try corruptBytes.write(to: historyURL)

        let store = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory
        )
        XCTAssertTrue(store.recoveredDamagedDetailedHistory)
        XCTAssertFalse(store.detailedHistoryNeedsAttention)
        XCTAssertTrue(store.activeSpellingAttempts.isEmpty)
        let quarantined = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("spelling-attempts.corrupt-") }
        XCTAssertEqual(quarantined.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(quarantined.first)), corruptBytes)

        store.recordSpellingAttempt(
            word: "moon",
            checkAttempts: 1,
            errorCount: 0,
            hintUses: 0,
            wasSuccessful: true,
            pointsEarned: 100
        )
        await store.waitForPendingAttemptPersistence()
        let fresh = try JSONDecoder().decode(
            [StarSpellerAttemptRecord].self,
            from: Data(contentsOf: historyURL)
        )
        XCTAssertEqual(fresh.map(\.word), ["moon"])
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(quarantined.first)), corruptBytes)
    }

    @MainActor
    func testAttemptsMadeDuringDeferredLoadMergeWithDiskHistory() async throws {
        let suiteName = "SpellingWordImportTests.deferred-merge.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MaxPuzzlesHistoryTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let profileStore = CometLearningStore(defaults: defaults)
        let diskRecord = spellingRecord(profileID: profileStore.activeProfileID, word: "disk")
        try JSONEncoder().encode([diskRecord]).write(
            to: directory.appendingPathComponent("spelling-attempts.json"),
            options: .atomic
        )

        let store = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory,
            deferDetailedHistoryLoad: true
        )
        store.recordSpellingAttempt(
            word: "pending",
            checkAttempts: 1,
            errorCount: 0,
            hintUses: 0,
            wasSuccessful: true,
            pointsEarned: 100
        )
        await store.waitForDetailedHistoriesToLoad()
        XCTAssertEqual(Set(store.activeSpellingAttempts.map(\.word)), ["disk", "pending"])
        await store.waitForPendingAttemptPersistence()

        let reloaded = CometLearningStore(
            defaults: defaults,
            detailedHistoryDirectory: directory
        )
        XCTAssertEqual(Set(reloaded.activeSpellingAttempts.map(\.word)), ["disk", "pending"])
    }

    @MainActor
    func testAdaptiveRankingPerformanceAtBoundedHistoryLimit() throws {
        let suiteName = "SpellingWordImportTests.ranking.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let initialStore = CometLearningStore(defaults: defaults)
        let profileID = initialStore.activeProfileID
        let words = StarSpellerWordLibrary.englandYearOne
        let records = (0..<500).map { index in
            StarSpellerAttemptRecord(
                id: UUID(),
                profileID: profileID,
                word: CometLearningStore.normalizedCustomWord(words[index % words.count]),
                checkAttempts: index.isMultiple(of: 3) ? 2 : 1,
                errorCount: index.isMultiple(of: 3) ? 1 : 0,
                hintUses: index.isMultiple(of: 5) ? 1 : 0,
                wasSuccessful: !index.isMultiple(of: 7),
                pointsEarned: index.isMultiple(of: 5) ? 90 : 100,
                timestamp: Date(timeIntervalSinceReferenceDate: Double(index))
            )
        }
        defaults.set(
            try JSONEncoder().encode(records),
            forKey: "maxpuzzles.starSpeller.attempts"
        )
        let store = CometLearningStore(defaults: defaults)

        measure {
            for _ in 0..<25 {
                XCTAssertEqual(
                    store.adaptiveSpellingWords(from: words, count: 10).count,
                    10
                )
            }
        }
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

    private func spellingRecord(
        profileID: UUID,
        word: String
    ) -> StarSpellerAttemptRecord {
        StarSpellerAttemptRecord(
            id: UUID(),
            profileID: profileID,
            word: word,
            checkAttempts: 1,
            errorCount: 0,
            hintUses: 0,
            wasSuccessful: true,
            pointsEarned: 100,
            timestamp: Date()
        )
    }
}

private struct LegacyCustomWord: Encodable {
    let id: UUID
    let profileID: UUID
    let text: String
    let recordingFilename: String?
    let createdAt: Date
}
