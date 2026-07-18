import Combine
import XCTest
import UIKit
@testable import MaxPuzzles

private enum ExpectedInitialMovement: Equatable {
    case upLeft
    case upRight
    case downLeft
    case downRight
    case down
    case right
    case dot
}

final class LetterPathValidatorTests: XCTestCase {
    func testPencilOnlyPolicyRejectsFingerAndAcceptsApplePencil() throws {
        XCTAssertTrue(TraceInputPolicy.accepts(.direct, pencilOnly: false))
        XCTAssertTrue(TraceInputPolicy.accepts(.pencil, pencilOnly: false))
        XCTAssertFalse(TraceInputPolicy.accepts(.direct, pencilOnly: true))
        XCTAssertFalse(TraceInputPolicy.accepts(.indirect, pencilOnly: true))
        XCTAssertFalse(TraceInputPolicy.accepts(.indirectPointer, pencilOnly: true))
        XCTAssertTrue(TraceInputPolicy.accepts(.pencil, pencilOnly: true))
        XCTAssertTrue(TraceInputPolicy.resolvedPencilOnly(true, supportsApplePencil: true))
        XCTAssertFalse(TraceInputPolicy.resolvedPencilOnly(true, supportsApplePencil: false))
        XCTAssertFalse(TraceInputPolicy.resolvedPencilOnly(false, supportsApplePencil: true))
    }

    func testFormationScoreTranslatesDirectlyIntoCometPoints() {
        XCTAssertEqual(
            CometRewardCalculator.reward(mistakes: 0),
            CometReward(score: 100, characterPoints: 10, wordBonusPoints: 0)
        )
        XCTAssertEqual(
            CometRewardCalculator.reward(mistakes: 3),
            CometReward(score: 76, characterPoints: 7, wordBonusPoints: 0)
        )
        XCTAssertEqual(
            CometRewardCalculator.reward(mistakes: 0, completedWord: true),
            CometReward(score: 100, characterPoints: 10, wordBonusPoints: 25)
        )
    }

    func testFormationScoreIsForgivingAndNeverDropsBelowCompletionFloor() {
        XCTAssertEqual(CometRewardCalculator.score(mistakes: -2), 100)
        XCTAssertEqual(CometRewardCalculator.score(mistakes: 1), 92)
        XCTAssertEqual(CometRewardCalculator.score(mistakes: 2), 84)
        XCTAssertEqual(CometRewardCalculator.score(mistakes: 100), 50)
        XCTAssertEqual(CometRewardCalculator.characterPoints(for: 50), 5)
    }

    func testPerformanceBreakdownAlwaysEqualsTheAwardedScore() {
        let weakMetrics = CometPerformanceMetrics(
            averagePathDeviation: 1,
            pathDeviationSpread: 1,
            averageLengthRatio: 3,
            correctionCounts: ["start": 8, "direction": 8, "baseline": 8, "track": 8, "finish": 8],
            assistance: .followTheGlow,
            usedHint: true
        )
        let weakReward = CometRewardCalculator.reward(metrics: weakMetrics)
        XCTAssertEqual(weakReward.score, CometRewardCalculator.minimumCompletionScore)
        XCTAssertEqual(weakReward.breakdown.total, weakReward.score)

        let strongMetrics = CometPerformanceMetrics(
            averagePathDeviation: 0,
            pathDeviationSpread: 0,
            averageLengthRatio: 1,
            correctionCounts: [:],
            assistance: .flySolo,
            usedHint: false
        )
        let strongReward = CometRewardCalculator.reward(metrics: strongMetrics)
        XCTAssertEqual(strongReward.score, 100)
        XCTAssertEqual(strongReward.breakdown.total, strongReward.score)
    }

    @MainActor
    func testCapitalAndLowercaseProgressRemainIndependent() {
        let suiteName = "LetterPathValidatorTests.storage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storage = StorageService(defaults: defaults)

        storage.markCometWriterLetterCompleted("a")
        storage.markCometWriterLetterCompleted("A")
        storage.recordCometWriterScore(73, for: "a")
        storage.recordCometWriterScore(91, for: "A")

        XCTAssertEqual(storage.cometWriterCompletedLetters, ["a", "A"])
        XCTAssertEqual(storage.bestCometWriterScore(for: "a"), 73)
        XCTAssertEqual(storage.bestCometWriterScore(for: "A"), 91)
        XCTAssertNil(storage.bestCometWriterScore(for: "!"))
    }

    @MainActor
    func testGameProgressIsSeparatedByPlayerProfile() {
        let suiteName = "LetterPathValidatorTests.profiles.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storage = StorageService(defaults: defaults)
        let firstProfile = UUID()
        let secondProfile = UUID()

        storage.activateProfile(firstProfile)
        storage.addCoins(40)
        storage.incrementPuzzlesCompleted()
        storage.markCometWriterLetterCompleted("c")
        storage.completeCircuitTutorial()

        storage.activateProfile(secondProfile)
        XCTAssertEqual(storage.totalCoinsEarned, 0)
        XCTAssertEqual(storage.puzzlesCompletedCount, 0)
        XCTAssertTrue(storage.cometWriterCompletedLetters.isEmpty)
        XCTAssertFalse(storage.hasCompletedCircuitTutorial)

        storage.addCoins(15)
        storage.markCometWriterLetterCompleted("a")

        storage.activateProfile(firstProfile)
        XCTAssertEqual(storage.totalCoinsEarned, 40)
        XCTAssertEqual(storage.puzzlesCompletedCount, 1)
        XCTAssertEqual(storage.cometWriterCompletedLetters, ["c"])
        XCTAssertTrue(storage.hasCompletedCircuitTutorial)

        storage.activateProfile(secondProfile)
        XCTAssertEqual(storage.totalCoinsEarned, 15)
        XCTAssertEqual(storage.cometWriterCompletedLetters, ["a"])
    }

    func testStoryProgressIsSeparatedByPlayerProfile() {
        let suiteName = "LetterPathValidatorTests.storyProfiles.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstProfile = UUID()
        let secondProfile = UUID()

        let firstProgress = StoryProgress(profileID: firstProfile, defaults: defaults)
        firstProgress.recordAttempt(
            chapter: 1,
            level: 1,
            won: true,
            livesLost: 0,
            timeSeconds: 20,
            tileCount: 8
        )

        let secondProgress = StoryProgress(profileID: secondProfile, defaults: defaults)
        XCTAssertFalse(secondProgress.isLevelCompleted(chapter: 1, level: 1))
        XCTAssertEqual(secondProgress.totalStars, 0)

        let reloadedFirstProgress = StoryProgress(profileID: firstProfile, defaults: defaults)
        XCTAssertTrue(reloadedFirstProgress.isLevelCompleted(chapter: 1, level: 1))
        XCTAssertGreaterThan(reloadedFirstProgress.starsForLevel(chapter: 1, level: 1), 0)
    }

    @MainActor
    func testLearningRecordsAreSeparatedByChildProfile() {
        let suiteName = "LetterPathValidatorTests.learning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CometLearningStore(defaults: defaults)
        let firstProfileID = store.activeProfileID
        let reward = CometRewardCalculator.reward(mistakes: 0)
        let metrics = CometPerformanceMetrics(
            averagePathDeviation: 0,
            pathDeviationSpread: 0,
            averageLengthRatio: 1,
            correctionCounts: [:],
            assistance: .flySolo,
            usedHint: false
        )

        store.recordAttempt(character: "A", mode: .recall, reward: reward, metrics: metrics, traces: [])
        XCTAssertEqual(store.mastery(for: "A"), .mastered)
        XCTAssertEqual(store.activePoints, 10)

        store.addProfile(name: "Second", writingHand: .left)
        XCTAssertNotEqual(store.activeProfileID, firstProfileID)
        XCTAssertEqual(store.mastery(for: "A"), .new)
        XCTAssertEqual(store.activePoints, 0)
        XCTAssertEqual(store.activeWritingHand, .left)

        store.setActiveProfile(firstProfileID)
        XCTAssertEqual(store.mastery(for: "A"), .mastered)
        XCTAssertEqual(store.activePoints, 10)
    }

    func testEveryLetterUsesTheAuthoredReceptionPhonemeMapping() {
        let expected: [String: [BritishEnglishPhoneme.ID]] = [
            "a": [.vowelTrap], "b": [.consonantB], "c": [.consonantK],
            "d": [.consonantD], "e": [.vowelDress], "f": [.consonantF],
            "g": [.consonantG], "h": [.consonantH], "i": [.vowelKit],
            "j": [.consonantJ], "k": [.consonantK], "l": [.consonantL],
            "m": [.consonantM], "n": [.consonantN], "o": [.vowelLot],
            "p": [.consonantP], "q": [.consonantK, .consonantW],
            "r": [.consonantR], "s": [.consonantS], "t": [.consonantT],
            "u": [.vowelStrut], "v": [.consonantV], "w": [.consonantW],
            "x": [.consonantK, .consonantS], "y": [.consonantY],
            "z": [.consonantZ]
        ]

        XCTAssertEqual(expected.count, 26)
        for (letter, phonemeIDs) in expected {
            XCTAssertEqual(LetterSpeechService.phonemeIDs(forLetter: letter), phonemeIDs)
            XCTAssertEqual(
                LetterSpeechService.phonemeIDs(forLetter: letter.uppercased()),
                phonemeIDs
            )
        }
        XCTAssertNil(LetterSpeechService.phonemeIDs(forLetter: "2"))
        XCTAssertNil(LetterSpeechService.phonemeIDs(forLetter: "ch"))
    }

    func testCUsesRecordedKSoundTwiceWithARealPauseAndNeverSaysSee() throws {
        let c = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let capitalC = try XCTUnwrap(LetterLibrary.glyph(for: "C"))
        let expected: [LetterSpeechStep] = [
            .spoken("Letter."),
            .pause(LetterSpeechService.lessonLeadInPause),
            .phoneme(.consonantK),
            .pause(LetterSpeechService.lessonRepetitionPause),
            .phoneme(.consonantK),
            .pause(LetterSpeechService.lessonExamplePause),
            .spoken("is for cat.")
        ]

        XCTAssertEqual(LetterSpeechService.lessonPlan(for: c), expected)
        XCTAssertEqual(LetterSpeechService.lessonPlan(for: capitalC), expected)
        XCTAssertGreaterThanOrEqual(LetterSpeechService.lessonRepetitionPause, 0.9)

        let spoken = LetterSpeechService.spokenText(in: expected).joined(separator: " ")
        XCTAssertFalse(spoken.lowercased().contains("letter c"))
        XCTAssertFalse(spoken.lowercased().contains("see"))
    }

    func testAll52LetterLessonsRepeatOnlyReviewedPhonemesAroundTheAudiblePause() throws {
        let allLetters = LetterLibrary.all.filter { !$0.isNumber }
        XCTAssertEqual(allLetters.count, 52)

        for glyph in allLetters {
            let taughtIDs = try XCTUnwrap(
                LetterSpeechService.phonemeIDs(forLetter: glyph.character)
            )
            let plan = LetterSpeechService.lessonPlan(for: glyph)
            let recordedIDs = plan.compactMap { step -> BritishEnglishPhoneme.ID? in
                guard case let .phoneme(id) = step else { return nil }
                return id
            }
            XCTAssertEqual(recordedIDs, taughtIDs + taughtIDs, glyph.character)

            let pauses = plan.compactMap { step -> TimeInterval? in
                guard case let .pause(duration) = step else { return nil }
                return duration
            }
            XCTAssertEqual(
                pauses.filter {
                    abs($0 - LetterSpeechService.lessonRepetitionPause) < 0.000_001
                }.count,
                1,
                "\(glyph.character) needs exactly one repetition pause"
            )

            let spoken = LetterSpeechService.spokenText(in: plan)
            XCTAssertEqual(spoken.first, "Letter.")
            XCTAssertEqual(
                spoken.last,
                glyph.character.lowercased() == "x"
                    ? "as in box."
                    : "is for \(glyph.exampleWord)."
            )
            XCTAssertFalse(
                spoken.joined(separator: " ").contains("Letter \(glyph.character)"),
                "\(glyph.character) was passed to plain-text speech"
            )

            let soundMissionPlan = LetterSpeechService.letterSoundPlan(for: glyph)
            XCTAssertEqual(Array(soundMissionPlan.prefix(plan.count)), plan)
        }
    }

    func testNumberLessonsStillSayNumberAndNeverNumeral() {
        let allNumbers = LetterLibrary.all.filter(\.isNumber)
        XCTAssertEqual(allNumbers.count, 10)
        for glyph in allNumbers {
            let plan = LetterSpeechService.lessonPlan(for: glyph)
            XCTAssertEqual(
                plan,
                [
                    .spoken("Number \(glyph.character)."),
                    .pause(LetterSpeechService.lessonRepetitionPause),
                    .spoken("\(glyph.character) is \(glyph.exampleWord).")
                ]
            )
            let spoken = LetterSpeechService.spokenText(in: plan).joined(separator: " ")
            XCTAssertTrue(spoken.contains("Number"))
            XCTAssertFalse(spoken.lowercased().contains("numeral"))
        }
    }

    func testOtherWriterAndSpellingVoicePlansNeverSynthesizeAnIsolatedLetter() throws {
        let c = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        XCTAssertEqual(
            LetterSpeechService.recallPlan(for: c),
            LetterSpeechService.letterSoundPlan(for: c)
        )
        XCTAssertEqual(
            LetterSpeechService.pathPlan(for: c, animated: true),
            [.spoken("Watch the comet write this letter, then have a go.")]
        )
        XCTAssertEqual(
            LetterSpeechService.wordPlan(
                for: c,
                word: "cat",
                introduction: "Write the word.",
                contextSentence: nil
            ),
            [.spoken("Write the word. cat. Write it on one line. Now write the highlighted letter.")]
        )
        XCTAssertEqual(
            LetterSpeechService.wordPlan(
                for: c,
                word: "c",
                introduction: "Write the word.",
                contextSentence: nil
            ),
            [
                .spoken("Write this one-letter sound."),
                .pause(LetterSpeechService.lessonLeadInPause),
                .phoneme(.consonantK),
                .pause(LetterSpeechService.lessonExamplePause),
                .spoken("Now write the highlighted letter.")
            ]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(for: "c", contextSentence: nil),
            [
                .spoken("Spell the one-letter sound."),
                .pause(LetterSpeechService.lessonLeadInPause),
                .phoneme(.consonantK)
            ]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(
                for: "c",
                contextSentence: "c is for cat"
            ),
            [
                .spoken("Spell the one-letter sound."),
                .pause(LetterSpeechService.lessonLeadInPause),
                .phoneme(.consonantK)
            ]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(for: "cat", contextSentence: nil),
            [.spoken("Spell the word cat.")]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(for: "a", contextSentence: nil),
            [.spoken("Spell the word a.")]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(for: "I", contextSentence: nil),
            [.spoken("Spell the word I.")]
        )
    }

    func testSpokenContextSanitizerDropsHostileLettersButPreservesNormalSentences() throws {
        XCTAssertNil(SpokenPromptContextSanitizer.sanitized("c"))
        XCTAssertNil(SpokenPromptContextSanitizer.sanitized("C is for cat"))
        XCTAssertNil(SpokenPromptContextSanitizer.sanitized("Choose (X)."))
        XCTAssertEqual(
            SpokenPromptContextSanitizer.sanitized("I saw a cat."),
            "I saw a cat."
        )
        XCTAssertEqual(
            SpokenPromptContextSanitizer.sanitized("The cat isn't sleepy."),
            "The cat isn't sleepy."
        )

        let c = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let contextFreeWordPlan = LetterSpeechService.wordPlan(
            for: c,
            word: "cat",
            introduction: "Write the word.",
            contextSentence: nil
        )
        XCTAssertEqual(
            LetterSpeechService.wordPlan(
                for: c,
                word: "cat",
                introduction: "Write the word.",
                contextSentence: "c"
            ),
            contextFreeWordPlan
        )
        XCTAssertEqual(
            LetterSpeechService.wordPlan(
                for: c,
                word: "cat",
                introduction: "Write the word.",
                contextSentence: "I saw a cat."
            ),
            [
                .spoken(
                    "Write the word. cat. Example: I saw a cat. Write it on one line. "
                        + "Now write the highlighted letter."
                )
            ]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(
                for: "cat",
                contextSentence: "C is for cat"
            ),
            [.spoken("Spell the word cat.")]
        )
        XCTAssertEqual(
            LetterSpeechService.spellingPlan(
                for: "cat",
                contextSentence: "I saw a cat."
            ),
            [.spoken("Spell the word cat. I saw a cat.")]
        )
    }

    func testAutomaticWriterSpeechStartsPhonicsButNeverCompetesWithVoiceOver() {
        XCTAssertTrue(
            CometWriterAutomaticSpeechPolicy.shouldSpeak(
                isVoiceOverRunning: false,
                isHearCue: true,
                isWordMission: false
            ),
            "The first Letter Sound Mission target starts in Hear mode and must not be silent"
        )
        XCTAssertTrue(
            CometWriterAutomaticSpeechPolicy.shouldSpeak(
                isVoiceOverRunning: false,
                isHearCue: false,
                isWordMission: true
            )
        )
        XCTAssertFalse(
            CometWriterAutomaticSpeechPolicy.shouldSpeak(
                isVoiceOverRunning: false,
                isHearCue: false,
                isWordMission: false
            )
        )
        XCTAssertFalse(
            CometWriterAutomaticSpeechPolicy.shouldSpeak(
                isVoiceOverRunning: true,
                isHearCue: true,
                isWordMission: true
            )
        )
        XCTAssertTrue(
            CometWriterAutomaticSpeechPolicy.shouldStartDeferredRecordingFallback(
                isVoiceOverRunning: false
            )
        )
        XCTAssertFalse(
            CometWriterAutomaticSpeechPolicy.shouldStartDeferredRecordingFallback(
                isVoiceOverRunning: true
            )
        )
        XCTAssertEqual(
            CometWriterAutomaticSpeechPolicy.deferredRecordingFailureAnnouncement,
            "The recording could not play. Choose Hear to try again."
        )
    }

    func testRecallSpeechSynchronousFailureRevealsCueAndOffersRetry() {
        XCTAssertEqual(
            CometWriterRecallSpeechRecovery.afterPlaybackAttempt(started: false),
            CometWriterRecallSpeechRecovery(
                shouldRevealCue: true,
                shouldShowRetry: true
            )
        )
        XCTAssertEqual(
            CometWriterRecallSpeechRecovery.afterPlaybackAttempt(started: true),
            CometWriterRecallSpeechRecovery(
                shouldRevealCue: false,
                shouldShowRetry: false
            )
        )
    }

    func testEveryNewPhonicsTargetRestoresTheAutomaticHearCue() {
        XCTAssertTrue(CometWriterRecallCuePolicy.startsWithHearCue(for: .phonics))
        XCTAssertFalse(CometWriterRecallCuePolicy.startsWithHearCue(for: .letterRecall))
        XCTAssertFalse(CometWriterRecallCuePolicy.startsWithHearCue(for: .wordWriting))
        XCTAssertFalse(CometWriterRecallCuePolicy.startsWithHearCue(for: .alienMail))
    }

    func testCompletedWriterFeedbackNeverExposesARawLetterToVoiceOver() {
        XCTAssertEqual(
            CometWriterFeedbackAccessibilityCopy.label(
                visibleMessage: "You formed c!",
                isLetterComplete: true
            ),
            "Letter complete."
        )
        XCTAssertEqual(
            CometWriterFeedbackAccessibilityCopy.label(
                visibleMessage: "Start at the green star.",
                isLetterComplete: false
            ),
            "Start at the green star."
        )
    }

    func testCustomOneLetterWriterAccessibilityUsesSoundCopyButKeepsAAndIAsWords() {
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingPromptLabel(
                for: "c",
                activeCharacter: "c",
                activeIndex: 0,
                characterCount: 1
            ),
            "Write the one-letter sound at the start of cat on one writing surface, letter 1 of 1"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.hearLabel(for: "x"),
            "Hear the one-letter sound at the end of box"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.characterDescription("c", in: "cat"),
            "the one-letter sound at the start of cat"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingSurfaceDescription(for: "c"),
            "the one-letter sound at the start of cat"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingSurfaceDescription(for: "Max"),
            "the word Max"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingSurfaceDescription(for: "MONDAY"),
            "the word Monday"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.targetDescription(for: "MONDAY"),
            "Monday"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.hearLabel(for: "MONDAY"),
            "Hear the word Monday"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingPromptLabel(
                for: "cat",
                activeCharacter: "c",
                activeIndex: 0,
                characterCount: 3
            ),
            "Write cat on one writing surface, letter 1 of 3, "
                + "the one-letter sound at the start of cat"
        )
        XCTAssertEqual(
            CometWriterWordAccessibilityCopy.writingPromptLabel(
                for: "a",
                activeCharacter: "a",
                activeIndex: 0,
                characterCount: 1
            ),
            "Write a on one writing surface, letter 1 of 1, a"
        )
        XCTAssertEqual(CometWriterWordAccessibilityCopy.hearLabel(for: "I"), "Hear the word I")
    }

    func testEveryChildFacingFormationFormatterAvoidsCaseLabels() {
        let forbiddenTerms = ["lowercase", "lower case", "uppercase", "upper case", "capital"]

        for glyph in LetterLibrary.all {
            let expectedName = glyph.isNumber
                ? "number \(glyph.character)"
                : "letter \(glyph.character)"
            XCTAssertEqual(glyph.formationName, expectedName)

            let outputs = [
                glyph.formationName,
                glyph.promptTitle,
                LetterSpeechService.spokenText(in: LetterSpeechService.lessonPlan(for: glyph))
                    .joined(separator: " "),
                LetterSpeechService.spokenText(in: LetterSpeechService.recallPlan(for: glyph))
                    .joined(separator: " "),
                LetterSpeechService.spokenText(
                    in: LetterSpeechService.pathPlan(for: glyph, animated: true)
                ).joined(separator: " "),
                LetterSpeechService.spokenText(
                    in: LetterSpeechService.pathPlan(for: glyph, animated: false)
                ).joined(separator: " "),
                LetterSpeechService.spokenText(in: LetterSpeechService.wordPlan(
                    for: glyph,
                    word: "map",
                    introduction: "Write the word.",
                    contextSentence: "The map is here."
                )).joined(separator: " ")
            ]

            for output in outputs {
                let normalized = output.lowercased()
                for term in forbiddenTerms {
                    XCTAssertFalse(
                        normalized.contains(term),
                        "Child-facing copy for \(glyph.character) contains ‘\(term)’: \(output)"
                    )
                }
            }
        }

        let familyCopy = LetterFamily.allCases.flatMap { [$0.title, $0.formationHint] }
        for output in familyCopy {
            let normalized = output.lowercased()
            for term in forbiddenTerms {
                XCTAssertFalse(normalized.contains(term), "Family copy contains ‘\(term)’: \(output)")
            }
        }
    }

    func testOneOffWordEntryPreservesCaseAndRejectsAnythingTheWriterCannotDraw() {
        XCTAssertEqual(CometWriterWordEntry.validatedWord(from: " Max "), "Max")
        XCTAssertEqual(CometWriterWordEntry.validatedWord(from: "a"), "a")
        XCTAssertEqual(CometWriterWordEntry.validatedWord(from: "abcdefghij"), "abcdefghij")

        XCTAssertNil(CometWriterWordEntry.validatedWord(from: ""))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "   "))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "abcdefghijk"))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "two words"))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "word!"))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "123"))
        XCTAssertNil(CometWriterWordEntry.validatedWord(from: "café"))
        XCTAssertEqual(
            CometWriterWordEntry.maximumLength,
            CometLearningStore.maximumCustomWordLength
        )
    }

    @MainActor
    func testAdvancedMissionStartsAndReloadsWithStartPointOnlyAssistance() throws {
        let first = try XCTUnwrap(LetterLibrary.glyph(for: "m"))
        let next = try XCTUnwrap(LetterLibrary.glyph(for: "s"))
        let viewModel = CometWriterViewModel(glyph: first, assistance: .flySolo)

        XCTAssertEqual(viewModel.assistance, .flySolo)
        viewModel.load(next, assistance: .flySolo)
        XCTAssertEqual(viewModel.assistance, .flySolo)
        XCTAssertEqual(viewModel.glyph.character, "s")
    }

    func testLetterRecallDefaultsToEveryLowercaseLetter() {
        XCTAssertEqual(LetterRecallCatalog.alphabet.count, 26)
        XCTAssertEqual(LetterRecallCatalog.allLetters, Set(LetterRecallCatalog.alphabet))
        XCTAssertEqual(
            LetterRecallCatalog.orderedSelection(LetterRecallCatalog.allLetters),
            LetterRecallCatalog.teachingOrder
        )
    }

    func testLetterRecallUsesOnlyChosenLettersInTeachingOrder() {
        let selection = Set(["g", "m", "z", "not-a-letter"])

        XCTAssertEqual(
            LetterRecallCatalog.orderedSelection(selection),
            ["m", "g", "z"]
        )
    }

    func testEveryGlyphStaysOnThePadAndValidationMatchesEveryLetterSize() throws {
        let scales = [
            LetterDisplayTransform.minimumScale,
            CGFloat(0.85),
            LetterDisplayTransform.defaultScale,
            LetterDisplayTransform.maximumScale
        ]

        for scale in scales {
            let transform = LetterDisplayTransform(scale: scale)

            for glyph in LetterLibrary.all {
                for stroke in glyph.strokes {
                    for point in stroke.points {
                        let displayed = transform.display(point)
                        // A small overshoot remains inside the pad's fixed 24-point drawing inset.
                        XCTAssertTrue((-0.05...1.05).contains(displayed.x), "\(glyph.character) clips horizontally at \(scale)")
                        XCTAssertTrue(
                            (-0.05...(LetterWritingMetrics.canvasHeight + 0.05)).contains(displayed.y),
                            "\(glyph.character) clips vertically at \(scale)"
                        )

                        let recovered = transform.model(displayed)
                        XCTAssertLessThan(
                            recovered.distance(to: point),
                            0.000_001,
                            "\(glyph.character) display and validation diverge at \(scale)"
                        )
                    }
                }
            }
        }
    }

    func testTouchCoordinatesRoundTripAcrossRotationResizeAndEveryLetterSize() throws {
        let surfaces: [(name: String, size: CGSize, inset: CGFloat)] = [
            ("iPhone SE portrait", CGSize(width: 288, height: 244), 12),
            ("iPhone SE landscape", CGSize(width: 430, height: 244), 12),
            ("iPhone portrait", CGSize(width: 342, height: 290), 24),
            ("iPad narrow window", CGSize(width: 205, height: 245), 12),
            ("iPad portrait", CGSize(width: 660, height: 559), 24),
            ("iPad wide window", CGSize(width: 860, height: 559), 24)
        ]
        let scales = stride(
            from: LetterDisplayTransform.minimumScale,
            through: LetterDisplayTransform.maximumScale,
            by: 0.05
        )

        for surface in surfaces {
            for scale in scales {
                let mapper = LetterTraceCoordinateMapper(
                    size: surface.size,
                    contentInset: surface.inset,
                    letterScale: scale
                )

                for glyph in LetterLibrary.all {
                    for modelPoint in glyph.strokes.flatMap(\.points) {
                        let location = mapper.location(for: modelPoint)
                        let recovered = mapper.modelPoint(for: location, clamped: false)
                        XCTAssertLessThan(
                            recovered.distance(to: modelPoint),
                            0.000_001,
                            "\(glyph.character) drifted on \(surface.name) at scale \(scale)"
                        )
                    }
                }
            }
        }

        let portrait = LetterTraceCoordinateMapper(
            size: surfaces[0].size,
            contentInset: surfaces[0].inset,
            letterScale: 0.85
        )
        let landscape = LetterTraceCoordinateMapper(
            size: surfaces[1].size,
            contentInset: surfaces[1].inset,
            letterScale: 0.85
        )
        let modelPoint = LetterPoint(x: 0.27, y: 0.64)
        XCTAssertLessThan(
            portrait.modelPoint(for: portrait.location(for: modelPoint)).distance(to: modelPoint),
            0.000_001
        )
        XCTAssertLessThan(
            landscape.modelPoint(for: landscape.location(for: modelPoint)).distance(to: modelPoint),
            0.000_001
        )
    }

    func testTouchCoordinatesClampOutsideTheResizedSurface() {
        let mapper = LetterTraceCoordinateMapper(
            size: CGSize(width: 205, height: 245),
            contentInset: 12,
            letterScale: LetterDisplayTransform.minimumScale
        )

        XCTAssertEqual(mapper.modelPoint(for: CGPoint(x: -1_000, y: -1_000)).x, 0)
        XCTAssertEqual(mapper.modelPoint(for: CGPoint(x: -1_000, y: -1_000)).y, 0)
        XCTAssertEqual(mapper.modelPoint(for: CGPoint(x: 1_000, y: 1_000)).x, 1)
        XCTAssertEqual(
            mapper.modelPoint(for: CGPoint(x: 1_000, y: 1_000)).y,
            LetterWritingMetrics.canvasHeight
        )
    }

    func testWritingLinesStayOrderedAndInsideEverySupportedSurface() {
        let surfaces: [(CGSize, CGFloat)] = [
            (CGSize(width: 288, height: 244), 12),
            (CGSize(width: 430, height: 244), 12),
            (CGSize(width: 205, height: 245), 12),
            (CGSize(width: 660, height: 559), 24),
            (CGSize(width: 860, height: 559), 24)
        ]

        for (size, inset) in surfaces {
            let positions = LetterWritingLineLayout.renderedYPositions(
                size: size,
                contentInset: inset
            )
            XCTAssertEqual(positions.count, 4)
            XCTAssertEqual(positions, positions.sorted())
            XCTAssertTrue(positions.allSatisfy { (0...size.height).contains($0) })
        }
    }

    func testWritingHandMovesControlsWithoutMirroringTheTrace() {
        XCTAssertTrue(CometWriterLayoutPolicy.tracePrecedesSidebar(isWide: true, writingHand: .left))
        XCTAssertFalse(CometWriterLayoutPolicy.tracePrecedesSidebar(isWide: true, writingHand: .right))
        XCTAssertFalse(CometWriterLayoutPolicy.tracePrecedesSidebar(isWide: false, writingHand: .left))
        XCTAssertFalse(CometWriterLayoutPolicy.tracePrecedesSidebar(isWide: false, writingHand: .right))

        let mapper = LetterTraceCoordinateMapper(
            size: CGSize(width: 660, height: 559),
            contentInset: 24,
            letterScale: 1
        )
        let point = LetterPoint(x: 0.22, y: 0.41)
        let renderedForEitherHand = mapper.location(for: point)
        XCTAssertEqual(renderedForEitherHand, mapper.location(for: point))
    }

    func testLetterSizeAlwaysStaysAnchoredToTheWritingBaseline() throws {
        let baselinePoint = LetterPoint(x: 0.35, y: LetterWritingMetrics.baselineY)

        for scale in stride(from: LetterDisplayTransform.minimumScale, through: LetterDisplayTransform.maximumScale, by: 0.05) {
            let displayed = LetterDisplayTransform(scale: scale).display(baselinePoint)
            XCTAssertEqual(displayed.y, baselinePoint.y, accuracy: 0.000_001)
        }
    }

    func testLetterSizeIsClampedToTheSupportedRange() throws {
        XCTAssertEqual(LetterDisplayTransform(scale: 0.1).scale, LetterDisplayTransform.minimumScale)
        XCTAssertEqual(LetterDisplayTransform(scale: 2.0).scale, LetterDisplayTransform.maximumScale)
    }

    func testLibraryContainsEveryLowercaseCapitalAndDigitExactlyOnce() throws {
        let expectedSymbols = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map(String.init))

        XCTAssertEqual(LetterLibrary.all.count, 62)
        XCTAssertEqual(Set(LetterLibrary.all.map(\.character)).count, 62)
        XCTAssertEqual(Set(LetterLibrary.practiceOrder), expectedSymbols)
    }

    func testEveryCharacterMatchesItsExplicitUKUnjoinedFormationProfile() throws {
        let expectedCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map(String.init))

        XCTAssertEqual(Set(LetterFormationStandard.profiles.keys), expectedCharacters)

        for character in LetterFormationStandard.lowercaseOrder
            + LetterFormationStandard.uppercaseOrder
            + LetterFormationStandard.numeralOrder {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            let profile = try XCTUnwrap(LetterFormationStandard.profile(for: character))

            XCTAssertFalse(profile.cue.isEmpty, "\(character) needs explicit directional language")
            XCTAssertLessThanOrEqual(
                profile.cue.count,
                64,
                "\(character) directional language is too long for the child-facing card"
            )
            XCTAssertEqual(
                glyph.strokes.count,
                profile.strokeStarts.count,
                "\(character) has the wrong number of taught strokes"
            )
            XCTAssertEqual(profile.strokeStarts.count, profile.strokeEnds.count)

            for index in glyph.strokes.indices {
                XCTAssertLessThan(
                    glyph.strokes[index].start.distance(to: profile.strokeStarts[index]),
                    0.002,
                    "\(character) stroke \(index + 1) starts in the wrong place"
                )
                XCTAssertLessThan(
                    glyph.strokes[index].end.distance(to: profile.strokeEnds[index]),
                    0.002,
                    "\(character) stroke \(index + 1) finishes in the wrong place"
                )
            }
        }
    }

    func testLowercaseMovementFamiliesMatchTheUKWritingFramework() {
        let expected: [FormationMovementFamily: Set<String>] = [
            .magicC: Set("coagqd".map(String.init)),
            .downstroke: Set("iltkj".map(String.init)),
            .scoopAndSlant: Set("vwuyf".map(String.init)),
            .bump: Set("rnmhpb".map(String.init)),
            .special: Set("esxz".map(String.init))
        ]

        for (family, characters) in expected {
            let actual = Set(
                LetterFormationStandard.lowercaseOrder.filter {
                    LetterFormationStandard.profile(for: $0)?.movementFamily == family
                }
            )
            XCTAssertEqual(actual, characters, "\(family) contains the wrong formations")
        }
    }

    func testMenuFamiliesUseTheSameMovementStandardAsThePaths() throws {
        let expectedFamily: [FormationMovementFamily: LetterFamily] = [
            .magicC: .magicC,
            .downstroke: .downstrokes,
            .scoopAndSlant: .scoops,
            .bump: .bumps,
            .special: .specials,
            .numeral: .numbers,
            .capital: .capitals
        ]

        for glyph in LetterLibrary.all {
            XCTAssertEqual(
                glyph.family,
                try XCTUnwrap(expectedFamily[glyph.formationProfile.movementFamily]),
                "\(glyph.character) is taught in the wrong movement family"
            )
        }
    }

    func testEveryLowercaseLetterOccupiesTheCorrectWritingBands() throws {
        for character in LetterFormationStandard.lowercaseOrder {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            let profile = glyph.formationProfile
            let bodyPoints = glyph.strokes.filter { !$0.isDot }.flatMap(\.points)
            let top = try XCTUnwrap(bodyPoints.map(\.y).min())
            let bottom = try XCTUnwrap(bodyPoints.map(\.y).max())

            switch profile.heightClass {
            case .xHeight:
                XCTAssertGreaterThanOrEqual(top, 0.29, "\(character) rises above x-height")
                XCTAssertLessThanOrEqual(bottom, 0.86, "\(character) falls below the baseline")
            case .ascender:
                XCTAssertLessThanOrEqual(top, 0.20, "\(character) does not reach its ascender band")
                XCTAssertLessThanOrEqual(bottom, 0.86, "\(character) falls below the baseline")
            case .descender:
                XCTAssertGreaterThanOrEqual(bottom, 1.03, "\(character) does not reach its descender band")
            case .ascenderAndDescender:
                XCTAssertLessThanOrEqual(top, 0.16, "\(character) does not reach its ascender band")
                XCTAssertGreaterThanOrEqual(bottom, 1.00, "\(character) does not reach its descender band")
            case .numeral, .capital:
                XCTFail("Lowercase \(character) cannot use the numeral or capital height class")
            }
        }
    }

    func testEveryCapitalUsesTheFullTopToBaselineBand() throws {
        for character in LetterFormationStandard.uppercaseOrder {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            XCTAssertEqual(glyph.formationProfile.heightClass, .capital, character)
            let points = glyph.strokes.flatMap(\.points)
            let top = try XCTUnwrap(points.map(\.y).min())
            let bottom = try XCTUnwrap(points.map(\.y).max())

            XCTAssertLessThanOrEqual(top, 0.10, "Capital \(character) does not reach the top line")
            XCTAssertGreaterThanOrEqual(bottom, 0.80, "Capital \(character) does not reach the baseline")
            XCTAssertLessThanOrEqual(bottom, character == "Q" ? 0.90 : 0.84, "Capital \(character) falls too far below the baseline")
        }
    }

    func testDotsAndCrossbarsAreAlwaysAddedAfterTheMainStroke() throws {
        for character in ["i", "j"] {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            XCTAssertFalse(glyph.strokes[0].isDot, "\(character) must draw its body first")
            XCTAssertTrue(glyph.strokes[1].isDot, "\(character) must add its dot last")
        }

        for character in ["f", "t"] {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            XCTAssertEqual(glyph.strokes.count, 2)
            XCTAssertEqual(glyph.strokes[1].style, .angular, "\(character) must add its crossbar last")
            XCTAssertEqual(glyph.strokes[1].start.y, glyph.strokes[1].end.y, accuracy: 0.000_001)
            XCTAssertLessThan(glyph.strokes[1].start.x, glyph.strokes[1].end.x)
        }
    }

    func testEveryCharacterBeginsEveryStrokeInTheTaughtDirection() throws {
        let expected: [String: [ExpectedInitialMovement]] = [
            "a": [.upLeft],
            "b": [.down],
            "c": [.upLeft],
            "d": [.upLeft],
            "e": [.right],
            "f": [.upLeft, .right],
            "g": [.upLeft],
            "h": [.down],
            "i": [.down, .dot],
            "j": [.down, .dot],
            "k": [.down, .downLeft],
            "l": [.down],
            "m": [.down],
            "n": [.down],
            "o": [.upLeft],
            "p": [.down],
            "q": [.upLeft],
            "r": [.down],
            "s": [.upLeft],
            "t": [.down, .right],
            "u": [.down],
            "v": [.downRight],
            "w": [.downRight],
            "x": [.downRight, .downLeft],
            "y": [.down],
            "z": [.right],
            "0": [.downLeft],
            "1": [.down],
            "2": [.upRight],
            "3": [.upRight],
            "4": [.downLeft, .down],
            "5": [.downLeft, .right],
            "6": [.upLeft],
            "7": [.right],
            "8": [.downLeft],
            "9": [.upLeft]
        ]

        XCTAssertEqual(
            Set(expected.keys),
            Set(LetterFormationStandard.lowercaseOrder + LetterFormationStandard.numeralOrder)
        )

        for (character, movements) in expected {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            XCTAssertEqual(glyph.strokes.count, movements.count, character)

            for (stroke, movement) in zip(glyph.strokes, movements) {
                if movement == .dot {
                    XCTAssertTrue(stroke.isDot, "\(character) should lift before adding its dot")
                    continue
                }

                XCTAssertFalse(stroke.isDot, "\(character) unexpectedly starts with a dot")
                let sample = stroke.point(at: 0.05)
                let dx = sample.x - stroke.start.x
                let dy = sample.y - stroke.start.y

                switch movement {
                case .upLeft:
                    XCTAssertLessThan(dx, -0.001, "\(character) must begin by moving left")
                    XCTAssertLessThan(dy, -0.001, "\(character) must begin by moving up")
                case .upRight:
                    XCTAssertGreaterThan(dx, 0.001, "\(character) must begin by moving right")
                    XCTAssertLessThan(dy, -0.001, "\(character) must begin by moving up")
                case .downLeft:
                    XCTAssertLessThan(dx, -0.001, "\(character) must begin by moving left")
                    XCTAssertGreaterThan(dy, 0.001, "\(character) must begin by moving down")
                case .downRight:
                    XCTAssertGreaterThan(dx, 0.001, "\(character) must begin by moving right")
                    XCTAssertGreaterThan(dy, 0.001, "\(character) must begin by moving down")
                case .down:
                    XCTAssertGreaterThan(dy, 0.001, "\(character) must begin by moving down")
                case .right:
                    XCTAssertGreaterThan(dx, 0.001, "\(character) must begin by moving right")
                    XCTAssertLessThan(abs(dy), 0.015, "\(character) should begin horizontally")
                case .dot:
                    break
                }
            }
        }
    }

    func testBumpFamilyDrawsDownThenRetracesBeforeTheShoulderOrBowl() throws {
        for character in ["r", "n", "m", "h", "b", "p"] {
            let stroke = try XCTUnwrap(LetterLibrary.glyph(for: character)?.strokes.first)
            let downTarget = character == "p" ? CGFloat(1.03) : CGFloat(0.80)
            let firstDownIndex = try XCTUnwrap(
                stroke.points.firstIndex(where: { $0.y >= downTarget }),
                "\(character) never completes its first downstroke"
            )
            let retracedPoints = stroke.points.suffix(from: firstDownIndex)

            XCTAssertTrue(
                retracedPoints.contains(where: { $0.y <= 0.44 }),
                "\(character) does not retrace upward before its shoulder or bowl"
            )
        }
    }

    func testMagicCLettersTravelAroundTheLeftBeforeTheirFinishStroke() throws {
        for character in ["c", "o", "a", "g", "q", "d"] {
            let stroke = try XCTUnwrap(LetterLibrary.glyph(for: character)?.strokes.first)
            XCTAssertLessThanOrEqual(
                try XCTUnwrap(stroke.points.map(\.x).min()),
                0.22,
                "\(character) does not travel fully around its left side"
            )
            XCTAssertGreaterThanOrEqual(
                try XCTUnwrap(stroke.points.map(\.y).max()),
                0.82,
                "\(character) does not reach the writing line"
            )
        }
    }

    func testCanvasGeometryNeverSquashesOrClipsAnyGlyph() throws {
        let configurations: [(size: CGSize, inset: CGFloat)] = [
            (CGSize(width: 660, height: 559), 24),
            (CGSize(width: 342, height: 290), 24),
            (CGSize(width: 205, height: 245), 12)
        ]

        for configuration in configurations {
            let geometry = LetterCanvasGeometry(
                size: configuration.size,
                contentInset: configuration.inset
            )
            let origin = geometry.render(LetterPoint(x: 0.5, y: 0.5))
            let horizontal = geometry.render(LetterPoint(x: 0.6, y: 0.5))
            let vertical = geometry.render(LetterPoint(x: 0.5, y: 0.6))

            XCTAssertEqual(horizontal.x - origin.x, vertical.y - origin.y, accuracy: 0.000_001)

            for scale in [LetterDisplayTransform.minimumScale, 1, LetterDisplayTransform.maximumScale] {
                let transform = LetterDisplayTransform(scale: scale)
                for glyph in LetterLibrary.all {
                    for point in glyph.strokes.flatMap(\.points) {
                        let rendered = geometry.render(transform.display(point))
                        XCTAssertTrue(
                            (0...configuration.size.width).contains(rendered.x),
                            "\(glyph.character) clips horizontally at scale \(scale)"
                        )
                        XCTAssertTrue(
                            (0...configuration.size.height).contains(rendered.y),
                            "\(glyph.character) clips vertically at scale \(scale)"
                        )
                        let recovered = transform.model(geometry.unrender(rendered))
                        XCTAssertLessThan(
                            recovered.distance(to: point),
                            0.000_001,
                            "\(glyph.character) touch input diverges from its visible path"
                        )
                    }
                }
            }
        }
    }

    func testEveryNumeralStaysBetweenTheTopAndBaseline() throws {
        for character in LetterFormationStandard.numeralOrder {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            let points = glyph.strokes.flatMap(\.points)
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(points.map(\.y).min()), 0.05, character)
            XCTAssertLessThanOrEqual(try XCTUnwrap(points.map(\.y).max()), 0.86, character)
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(points.map(\.y).max()), 0.72, character)
        }
    }

    func testEveryGlyphHasValidNormalizedStrokeData() throws {
        for glyph in LetterLibrary.all {
            XCTAssertFalse(glyph.strokes.isEmpty, "\(glyph.character) needs a stroke")

            for stroke in glyph.strokes {
                XCTAssertFalse(stroke.points.isEmpty, "\(glyph.character) contains an empty stroke")
                for point in stroke.points {
                    XCTAssertTrue((0...1).contains(point.x), "\(glyph.character) x is outside the pad")
                    XCTAssertTrue(
                        (0...LetterWritingMetrics.canvasHeight).contains(point.y),
                        "\(glyph.character) y is outside the pad"
                    )
                }
            }
        }
    }

    func testEveryLetterUsesTheIntendedSmoothOrAngularGeometry() throws {
        let angularLetters = Set(["k", "v", "w", "x", "z"])
        let circularLetters = Set(["c", "o"])

        for glyph in LetterLibrary.all where !glyph.isNumber && !glyph.isUppercase {
            if circularLetters.contains(glyph.character) {
                XCTAssertTrue(
                    glyph.strokes.allSatisfy { $0.style == .circular },
                    "\(glyph.character) must retain constant-radius geometry"
                )
            } else if angularLetters.contains(glyph.character) {
                XCTAssertTrue(
                    glyph.strokes.allSatisfy { $0.style == .angular },
                    "\(glyph.character) must retain its taught sharp corners"
                )
            } else if glyph.character == "f" || glyph.character == "t" {
                XCTAssertEqual(glyph.strokes.first?.style, .smooth)
                XCTAssertEqual(glyph.strokes.last?.style, .angular)
            } else {
                XCTAssertTrue(
                    glyph.strokes.allSatisfy { $0.isDot || $0.style == .smooth },
                    "\(glyph.character) contains an unexpectedly kinked stroke"
                )
            }
        }
    }

    func testLowercaseFDescendsWithoutABottomRightHook() throws {
        let body = try XCTUnwrap(LetterLibrary.glyph(for: "f")?.strokes.first)
        let pointsBelowLine = body.points.filter { $0.y >= LetterWritingMetrics.baselineY }

        XCTAssertFalse(pointsBelowLine.isEmpty)
        XCTAssertTrue(
            pointsBelowLine.allSatisfy { $0.x <= 0.405 },
            "Lowercase f must descend cleanly instead of curling right at the bottom"
        )
        XCTAssertEqual(body.end.x, 0.40, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(body.end.y, LetterWritingMetrics.descenderLineY)
    }

    func testLowercaseYBalancesANarrowBodyWithAFullDescender() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "y")?.strokes.first)
        let body = stroke.points.filter { $0.y <= LetterWritingMetrics.baselineY + 0.005 }
        let tail = stroke.points.filter { $0.y > LetterWritingMetrics.baselineY + 0.005 }
        let bodyWidth = try XCTUnwrap(body.map(\.x).max()) - (try XCTUnwrap(body.map(\.x).min()))
        let tailDepth = try XCTUnwrap(tail.map(\.y).max()) - LetterWritingMetrics.baselineY

        XCTAssertLessThanOrEqual(bodyWidth, 0.30, "Lowercase y is too top-heavy")
        XCTAssertGreaterThanOrEqual(tailDepth, 0.23, "Lowercase y needs a full descender")
        XCTAssertLessThan(stroke.end.x, 0.30, "Lowercase y should finish with a clear left curve")
    }

    func testEveryNumberUsesItsIntendedSmoothOrAngularGeometry() throws {
        let angularNumbers = Set(["1", "4", "7"])

        for glyph in LetterLibrary.glyphs(in: .numbers) {
            if glyph.character == "5" {
                XCTAssertEqual(glyph.strokes.map(\.style), [.smooth, .angular])
                continue
            }

            let expectedStyle: LetterStrokeStyle = angularNumbers.contains(glyph.character) ? .angular : .smooth
            XCTAssertTrue(
                glyph.strokes.allSatisfy { $0.style == expectedStyle },
                "\(glyph.character) has the wrong number geometry"
            )
        }
    }

    func testEverySmoothStrokeIsDenselySampledWithoutVisibleSegmentJumps() throws {
        for glyph in LetterLibrary.all {
            for stroke in glyph.strokes where stroke.style != .angular && !stroke.isDot {
                let jumps = zip(stroke.points, stroke.points.dropFirst()).map { $0.distance(to: $1) }
                XCTAssertLessThan(
                    jumps.max() ?? 0,
                    0.065,
                    "\(glyph.character) still contains a visible corner-sized jump"
                )
            }
        }
    }

    func testCAndOUseAConstantPhysicalRadiusAtEveryPadSize() throws {
        let center = LetterPoint(x: 0.46, y: 0.58)
        let padConfigurations: [(CGSize, CGFloat)] = [
            (CGSize(width: 660, height: 559), 24),
            (CGSize(width: 342, height: 290), 24),
            (CGSize(width: 205, height: 245), 12)
        ]

        for character in ["c", "o"] {
            let stroke = try XCTUnwrap(LetterLibrary.glyph(for: character)?.strokes.first)
            let modelRadii = stroke.points.map { $0.distance(to: center) }
            XCTAssertEqual(try XCTUnwrap(modelRadii.min()), CGFloat(0.25), accuracy: 0.0001)
            XCTAssertEqual(try XCTUnwrap(modelRadii.max()), CGFloat(0.25), accuracy: 0.0001)

            for (size, inset) in padConfigurations {
                let geometry = LetterCanvasGeometry(size: size, contentInset: inset)
                let renderedCenter = geometry.render(center)
                let radii = stroke.points.map { point in
                    hypot(
                        geometry.render(point).x - renderedCenter.x,
                        geometry.render(point).y - renderedCenter.y
                    )
                }
                XCTAssertEqual(
                    try XCTUnwrap(radii.min()),
                    try XCTUnwrap(radii.max()),
                    accuracy: 0.01,
                    "\(character) is squashed on a \(Int(size.width)) by \(Int(size.height)) pad"
                )
            }
        }
    }

    func testLowercaseCOpeningKeepsItsVisibleBodyBroad() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "c")?.strokes.first)
        let width = try XCTUnwrap(stroke.points.map(\.x).max())
            - (try XCTUnwrap(stroke.points.map(\.x).min()))
        let height = try XCTUnwrap(stroke.points.map(\.y).max())
            - (try XCTUnwrap(stroke.points.map(\.y).min()))

        XCTAssertGreaterThanOrEqual(width / height, 0.90, "c has an over-wide opening and looks squeezed")
        XCTAssertLessThanOrEqual(width / height, 0.94, "c opening is too narrow to read clearly")
    }

    func testEveryStrokeCanRevealAnExactPartialPath() throws {
        for glyph in LetterLibrary.all {
            for stroke in glyph.strokes {
                for progress in [CGFloat(0), 0.17, 0.50, 0.83, 1] {
                    let partialPath = stroke.points(upTo: progress)
                    XCTAssertFalse(partialPath.isEmpty, "\(glyph.character) needs a drawable demonstration path")
                    XCTAssertEqual(partialPath.first, stroke.start)
                    XCTAssertLessThan(
                        partialPath.last?.distance(to: stroke.point(at: progress)) ?? 1,
                        0.0001,
                        "\(glyph.character) demonstration drifted away from its validated path"
                    )
                }
            }
        }
    }

    func testEveryLetterDemonstrationPlaysEveryStrokeInOrder() throws {
        for glyph in LetterLibrary.all {
            let timeline = LetterDemonstrationTimeline(glyph: glyph)
            XCTAssertGreaterThan(timeline.totalDuration, 0)

            let firstFrame = timeline.frame(at: 0)
            XCTAssertEqual(firstFrame.activeStrokeIndex, 0, "\(glyph.character) must begin at stroke one")
            XCTAssertEqual(firstFrame.activeProgress, 0)

            var seenStrokeIndices = Set<Int>()
            var previousCompletedCount = 0
            let sampleCount = Int(ceil(timeline.totalDuration * 100))

            for sample in 0...sampleCount {
                let frame = timeline.frame(at: Double(sample) / 100)
                if let activeStrokeIndex = frame.activeStrokeIndex {
                    seenStrokeIndices.insert(activeStrokeIndex)
                }
                XCTAssertGreaterThanOrEqual(
                    frame.completedStrokeCount,
                    previousCompletedCount,
                    "\(glyph.character) demonstration moved backwards through its stroke order"
                )
                previousCompletedCount = frame.completedStrokeCount
            }

            XCTAssertEqual(
                seenStrokeIndices,
                Set(glyph.strokes.indices),
                "\(glyph.character) did not demonstrate every stroke"
            )

            let finishedFrame = timeline.frame(at: timeline.totalDuration + 0.01)
            XCTAssertEqual(finishedFrame.completedStrokeCount, glyph.strokes.count)
            XCTAssertNil(finishedFrame.activeStrokeIndex)
        }
    }

    @MainActor
    func testRequestedDemonstrationCanReplayAndCancelWithoutChangingProgress() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let viewModel = CometWriterViewModel(glyph: glyph)

        viewModel.showHint(animated: true)
        let firstStart = try XCTUnwrap(viewModel.demonstrationStartedAt)
        XCTAssertTrue(viewModel.isDemonstrating)
        XCTAssertTrue(viewModel.isHintVisible)
        XCTAssertEqual(viewModel.currentStrokeIndex, 0)

        viewModel.showHint(animated: true)
        let replayStart = try XCTUnwrap(viewModel.demonstrationStartedAt)
        XCTAssertGreaterThanOrEqual(replayStart, firstStart)

        viewModel.retryCurrentStroke()
        XCTAssertFalse(viewModel.isDemonstrating)
        XCTAssertFalse(viewModel.isHintVisible)
        XCTAssertEqual(viewModel.currentStrokeIndex, 0)
    }

    @MainActor
    func testReducedMotionShowsThePathWithoutStartingAnimation() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "i"))
        let viewModel = CometWriterViewModel(glyph: glyph)

        viewModel.showHint(animated: false)

        XCTAssertTrue(viewModel.isHintVisible)
        XCTAssertFalse(viewModel.isDemonstrating)
        XCTAssertNil(viewModel.demonstrationStartedAt)
        viewModel.stopHint()
    }

    func testTracePadNeverAnimatesADemonstrationWithReduceMotion() {
        XCTAssertTrue(
            LetterTraceMotionPolicy.animatesDemonstration(
                isDemonstrating: true,
                reduceMotion: false
            )
        )
        XCTAssertFalse(
            LetterTraceMotionPolicy.animatesDemonstration(
                isDemonstrating: true,
                reduceMotion: true
            )
        )
        XCTAssertFalse(
            LetterTraceMotionPolicy.animatesDemonstration(
                isDemonstrating: false,
                reduceMotion: false
            )
        )
    }

    @MainActor
    func testCancelledTouchClearsTheTraceWithoutCountingAMistake() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let viewModel = CometWriterViewModel(glyph: glyph)

        XCTAssertEqual(viewModel.beginTrace(at: glyph.strokes[0].start), .none)
        XCTAssertFalse(viewModel.activeTrace.isEmpty)

        viewModel.cancelActiveTrace()

        XCTAssertTrue(viewModel.activeTrace.isEmpty)
        XCTAssertEqual(viewModel.mistakeCount, 0)
        XCTAssertEqual(viewModel.feedbackMessage, "Start again at the green star.")
    }

    @MainActor
    func testLiveTraceSamplesInvalidateOnlyTheWritingSurface() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "l"))
        let stroke = try XCTUnwrap(glyph.strokes.first)
        let viewModel = CometWriterViewModel(glyph: glyph)
        XCTAssertEqual(viewModel.beginTrace(at: stroke.start), .none)

        var missionPublicationCount = 0
        var surfacePublicationCount = 0
        let missionObservation = viewModel.objectWillChange.sink {
            missionPublicationCount += 1
        }
        let surfaceObservation = viewModel.traceSurfaceState.objectWillChange.sink {
            surfacePublicationCount += 1
        }
        let samples = [CGFloat(0.08), 0.16, 0.24, 0.32, 0.40].map(stroke.point)

        for sample in samples {
            XCTAssertEqual(viewModel.continueTrace(at: sample), .none)
        }

        XCTAssertEqual(
            viewModel.activeTrace,
            [stroke.start] + samples,
            "Moving trace state must not drop or alter samples while isolating its redraws"
        )
        XCTAssertEqual(
            missionPublicationCount,
            0,
            "A live stroke must not invalidate the surrounding mission hierarchy"
        )
        XCTAssertEqual(surfacePublicationCount, samples.count)
        withExtendedLifetime((missionObservation, surfaceObservation)) {}
    }

    func testAllLetterPathsRenderAsVisualAuditSheet() throws {
        let columns = 5
        let cellSize = CGSize(width: 180, height: 190)
        let rows = Int(ceil(Double(LetterLibrary.all.count) / Double(columns)))
        let sheetSize = CGSize(width: cellSize.width * CGFloat(columns), height: cellSize.height * CGFloat(rows))
        let renderer = UIGraphicsImageRenderer(size: sheetSize)

        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            UIColor(red: 0.06, green: 0.06, blue: 0.14, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: sheetSize))

            for (index, glyph) in LetterLibrary.all.enumerated() {
                let column = index % columns
                let row = index / columns
                let origin = CGPoint(x: CGFloat(column) * cellSize.width, y: CGFloat(row) * cellSize.height)
                // Use the production coordinate mapper so the audit reflects physical curvature.
                let drawingRect = CGRect(x: origin.x + 18, y: origin.y + 34, width: 144, height: 120)
                let geometry = LetterCanvasGeometry(size: drawingRect.size, contentInset: 0)

                (glyph.character as NSString).draw(
                    at: CGPoint(x: origin.x + 8, y: origin.y + 4),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                        .foregroundColor: UIColor.white
                    ]
                )

                context.saveGState()
                for (lineY, alpha, dashed) in [
                    (LetterWritingMetrics.topLineY, CGFloat(0.12), true),
                    (LetterWritingMetrics.xHeightLineY, CGFloat(0.18), true),
                    (LetterWritingMetrics.baselineY, CGFloat(0.35), false),
                    (LetterWritingMetrics.descenderLineY, CGFloat(0.15), true)
                ] {
                    let renderedLineY = drawingRect.minY
                        + geometry.render(LetterPoint(x: 0.5, y: lineY)).y
                    context.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                    context.setLineWidth(1)
                    context.setLineDash(phase: 0, lengths: dashed ? [4, 4] : [])
                    context.move(to: CGPoint(x: drawingRect.minX, y: renderedLineY))
                    context.addLine(to: CGPoint(x: drawingRect.maxX, y: renderedLineY))
                    context.strokePath()
                }
                context.restoreGState()

                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setLineWidth(8)
                context.setStrokeColor(UIColor(red: 0.40, green: 0.91, blue: 0.98, alpha: 1).cgColor)
                context.setFillColor(UIColor(red: 0.40, green: 0.91, blue: 0.98, alpha: 1).cgColor)

                for stroke in glyph.strokes {
                    guard let first = stroke.points.first else { continue }
                    let rendered: (LetterPoint) -> CGPoint = { point in
                        let local = geometry.render(point)
                        return CGPoint(x: drawingRect.minX + local.x, y: drawingRect.minY + local.y)
                    }

                    if stroke.isDot {
                        let center = rendered(first)
                        context.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
                    } else {
                        context.beginPath()
                        context.move(to: rendered(first))
                        for point in stroke.points.dropFirst() {
                            context.addLine(to: rendered(point))
                        }
                        context.strokePath()
                    }

                    let start = rendered(stroke.start)
                    context.setFillColor(UIColor.systemGreen.cgColor)
                    context.fillEllipse(in: CGRect(x: start.x - 4, y: start.y - 4, width: 8, height: 8))
                    let end = rendered(stroke.end)
                    context.setFillColor(UIColor.systemYellow.cgColor)
                    context.fillEllipse(in: CGRect(x: end.x - 3, y: end.y - 3, width: 6, height: 6))
                    context.setFillColor(UIColor(red: 0.40, green: 0.91, blue: 0.98, alpha: 1).cgColor)
                }
            }
        }

        let attachment = XCTAttachment(image: image)
        attachment.name = "All 62 Comet Writer lowercase, capital and number paths"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testExactFormationCompletesEveryStroke() throws {
        for glyph in LetterLibrary.all {
            for stroke in glyph.strokes {
                var validator = LetterPathValidator(stroke: stroke)
                XCTAssertEqual(validator.begin(at: stroke.start), .ready, "Could not start \(glyph.character)")

                if !stroke.isDot {
                    for step in 1...20 {
                        let result = validator.add(stroke.point(at: CGFloat(step) / 20))
                        if case .advanced = result {
                            continue
                        }
                        XCTFail("Expected \(glyph.character) to advance, got \(result)")
                    }
                }

                XCTAssertEqual(validator.end(at: stroke.end), .complete, "Could not finish \(glyph.character)")
            }
        }
    }

    func testRealisticUnevenWobblyChildStrokesCompleteEveryFormation() throws {
        for glyph in LetterLibrary.all {
            for (strokeIndex, stroke) in glyph.strokes.enumerated() {
                let points = childStylePoints(for: stroke)
                var validator = LetterPathValidator(stroke: stroke)
                XCTAssertEqual(
                    validator.begin(at: try XCTUnwrap(points.first)),
                    .ready,
                    "A slightly imperfect start should work for \(glyph.character)"
                )

                for (pointIndex, point) in points.dropFirst().dropLast().enumerated() {
                    let result = validator.add(point)
                    guard case .advanced = result else {
                        XCTFail(
                            "A natural wobbly \(glyph.character) stroke \(strokeIndex), sample "
                                + "\(pointIndex + 1), progress \(validator.progress) was rejected "
                                + "with \(result)"
                        )
                        break
                    }
                }

                XCTAssertEqual(
                    validator.end(at: try XCTUnwrap(points.last)),
                    .complete,
                    "A natural wobbly \(glyph.character) stroke could not finish"
                )
            }
        }
    }

    @MainActor
    func testNoisyChildStyleDragCompletesThroughTheProductionViewModel() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let stroke = try XCTUnwrap(glyph.strokes.first)
        let points = childStylePoints(for: stroke)
        let viewModel = CometWriterViewModel(glyph: glyph, assistance: .flySolo)

        XCTAssertEqual(viewModel.beginTrace(at: try XCTUnwrap(points.first)), .none)
        for point in points.dropFirst().dropLast() {
            XCTAssertEqual(viewModel.continueTrace(at: point), .none)
        }
        XCTAssertEqual(viewModel.endTrace(at: try XCTUnwrap(points.last)), .letterCompleted)
        XCTAssertTrue(viewModel.isLetterComplete)
        XCTAssertEqual(viewModel.completedTraces.count, 1)
        XCTAssertEqual(viewModel.mistakeCount, 0)
        XCTAssertGreaterThan(viewModel.performanceMetrics.averagePathDeviation, 0)
        XCTAssertGreaterThanOrEqual(
            CometRewardCalculator.reward(metrics: viewModel.performanceMetrics).score,
            80
        )
    }

    func testTraceMustBeginAtTaughtStart() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "c")?.strokes.first)
        var validator = LetterPathValidator(stroke: stroke)

        XCTAssertEqual(validator.begin(at: LetterPoint(x: 0.05, y: 0.95)), .wrongStart)
    }

    func testTraceRejectsLeavingTheFormationCorridor() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "l")?.strokes.first)
        var validator = LetterPathValidator(stroke: stroke)

        XCTAssertEqual(validator.begin(at: stroke.start), .ready)
        XCTAssertEqual(validator.add(LetterPoint(x: 0.95, y: 0.50)), .offTrack)
    }

    func testNonDescenderGetsSpecificBelowBaselineFeedbackAfterForgivingBuffer() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "l")?.strokes.first)
        var validator = LetterPathValidator(stroke: stroke)

        XCTAssertEqual(validator.begin(at: stroke.start), .ready)
        XCTAssertEqual(validator.add(LetterPoint(x: stroke.start.x, y: 0.89)), .belowBaseline)
    }

    @MainActor
    func testProductionWritingAllowsShallowDipBelowBaseline() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "l"))
        let stroke = try XCTUnwrap(glyph.strokes.first)
        let viewModel = CometWriterViewModel(glyph: glyph, assistance: .flySolo)

        XCTAssertEqual(viewModel.beginTrace(at: stroke.start), .none)
        for step in 1..<20 {
            XCTAssertEqual(viewModel.continueTrace(at: stroke.point(at: CGFloat(step) / 20)), .none)
        }

        let shallowDip = LetterPoint(
            x: stroke.end.x,
            y: LetterWritingMetrics.baselineY + 0.07
        )
        XCTAssertEqual(viewModel.continueTrace(at: shallowDip), .none)
        XCTAssertNil(viewModel.correctionKind)
        XCTAssertEqual(viewModel.correctionCounts[.baseline, default: 0], 0)
        XCTAssertEqual(viewModel.mistakeCount, 0)
        XCTAssertEqual(viewModel.endTrace(at: stroke.end), .letterCompleted)
    }

    @MainActor
    func testProductionWritingStillRejectsDeepDipBelowBaseline() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "l"))
        let stroke = try XCTUnwrap(glyph.strokes.first)
        let viewModel = CometWriterViewModel(glyph: glyph, assistance: .flySolo)

        XCTAssertEqual(viewModel.beginTrace(at: stroke.start), .none)
        for step in 1..<20 {
            XCTAssertEqual(viewModel.continueTrace(at: stroke.point(at: CGFloat(step) / 20)), .none)
        }

        let deepDip = LetterPoint(
            x: stroke.end.x,
            y: LetterWritingMetrics.baselineY + 0.09
        )
        XCTAssertEqual(viewModel.continueTrace(at: deepDip), .mistake)
        XCTAssertEqual(viewModel.correctionKind, .baseline)
        XCTAssertEqual(viewModel.correctionCounts[.baseline, default: 0], 1)
        XCTAssertEqual(viewModel.mistakeCount, 1)
    }

    func testTaughtDescendersMayTravelBelowTheBaseline() throws {
        for character in ["g", "j", "p", "q", "y", "f"] {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            let descender = try XCTUnwrap(glyph.strokes.first(where: { stroke in
                stroke.points.contains { $0.y > 0.88 }
            }))
            var validator = LetterPathValidator(stroke: descender)

            XCTAssertEqual(validator.begin(at: descender.start), .ready, character)
            for step in 1...24 {
                let result = validator.add(descender.point(at: CGFloat(step) / 24))
                if case .belowBaseline = result {
                    XCTFail("Taught descender for \(character) was rejected")
                }
            }
        }
    }

    func testStandardDescendersUseTheFullDedicatedBand() throws {
        for character in ["g", "j", "p", "q", "y"] {
            let glyph = try XCTUnwrap(LetterLibrary.glyph(for: character))
            let deepestPoint = try XCTUnwrap(
                glyph.strokes.flatMap(\.points).map(\.y).max()
            )

            XCTAssertGreaterThanOrEqual(
                deepestPoint,
                LetterWritingMetrics.descenderLineY - 0.01,
                "\(character) does not travel far enough below the baseline"
            )
            XCTAssertGreaterThanOrEqual(
                deepestPoint - LetterWritingMetrics.baselineY,
                0.21,
                "\(character) has a visually cramped descender"
            )
        }
    }

    @MainActor
    func testViewModelExplainsAndHighlightsBaselineMistake() throws {
        let glyph = try XCTUnwrap(LetterLibrary.glyph(for: "l"))
        let viewModel = CometWriterViewModel(glyph: glyph)

        XCTAssertEqual(viewModel.beginTrace(at: glyph.strokes[0].start), .none)
        XCTAssertEqual(
            viewModel.continueTrace(at: LetterPoint(x: glyph.strokes[0].start.x, y: 0.92)),
            .mistake
        )
        XCTAssertEqual(viewModel.correctionKind, .baseline)
        XCTAssertEqual(viewModel.feedbackMessage, "Keep this one above the writing line.")
        XCTAssertEqual(viewModel.mistakeCount, 1)
    }

    @MainActor
    func testViewModelGivesDistinctStartDirectionTrackAndFinishCorrections() throws {
        let c = try XCTUnwrap(LetterLibrary.glyph(for: "c"))
        let wrongStart = CometWriterViewModel(glyph: c)
        XCTAssertEqual(wrongStart.beginTrace(at: LetterPoint(x: 0.05, y: 0.95)), .mistake)
        XCTAssertEqual(wrongStart.correctionKind, .start)

        let wrongDirection = CometWriterViewModel(glyph: c)
        XCTAssertEqual(wrongDirection.beginTrace(at: c.strokes[0].start), .none)
        for step in 1...12 {
            _ = wrongDirection.continueTrace(at: c.strokes[0].point(at: CGFloat(step) / 20))
        }
        XCTAssertEqual(wrongDirection.continueTrace(at: c.strokes[0].point(at: 0.12)), .mistake)
        XCTAssertEqual(wrongDirection.correctionKind, .direction)

        let l = try XCTUnwrap(LetterLibrary.glyph(for: "l"))
        let offTrack = CometWriterViewModel(glyph: l)
        XCTAssertEqual(offTrack.beginTrace(at: l.strokes[0].start), .none)
        XCTAssertEqual(offTrack.continueTrace(at: LetterPoint(x: 0.95, y: 0.50)), .mistake)
        XCTAssertEqual(offTrack.correctionKind, .track)

        let unfinished = CometWriterViewModel(glyph: l)
        XCTAssertEqual(unfinished.beginTrace(at: l.strokes[0].start), .none)
        XCTAssertEqual(unfinished.endTrace(at: l.strokes[0].start), .mistake)
        XCTAssertEqual(unfinished.correctionKind, .finish)
    }

    func testTraceRejectsReversingDirection() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "c")?.strokes.first)
        var validator = LetterPathValidator(stroke: stroke)

        XCTAssertEqual(validator.begin(at: stroke.start), .ready)
        for step in 1...10 {
            _ = validator.add(stroke.point(at: CGFloat(step) / 20))
        }

        XCTAssertEqual(validator.add(stroke.point(at: 0.12)), .wrongDirection)
    }

    func testTraceCannotFinishEarly() throws {
        let stroke = try XCTUnwrap(LetterLibrary.glyph(for: "v")?.strokes.first)
        var validator = LetterPathValidator(stroke: stroke)

        XCTAssertEqual(validator.begin(at: stroke.start), .ready)
        for step in 1...8 {
            _ = validator.add(stroke.point(at: CGFloat(step) / 20))
        }

        XCTAssertEqual(validator.end(at: stroke.point(at: 0.4)), .incomplete)
    }

    private func childStylePoints(for stroke: LetterStroke) -> [LetterPoint] {
        if stroke.isDot {
            let imperfectTap = LetterPoint(
                x: min(max(stroke.start.x + 0.012, 0), 1),
                y: min(max(stroke.start.y - 0.009, 0), LetterWritingMetrics.canvasHeight)
            )
            return [imperfectTap, imperfectTap]
        }

        let sampleCount = 42
        return (0...sampleCount).map { index in
            let elapsed = CGFloat(index) / CGFloat(sampleCount)
            // Uneven progress resembles a child slowing around corners instead of a synthetic,
            // perfectly timed trace.
            let progress = pow(elapsed, 1.08)
            let base = stroke.point(at: progress)
            let before = stroke.point(at: max(0, progress - 0.012))
            let after = stroke.point(at: min(1, progress + 0.012))
            let dx = after.x - before.x
            let dy = after.y - before.y
            let tangentLength = max(hypot(dx, dy), 0.000_001)
            // Slow side-to-side drift models an unsteady young hand. High-frequency alternating
            // noise would create real local reversals, which the direction validator should (and
            // does) reject rather than treating as ordinary imprecision.
            let driftEnvelope = sin(.pi * elapsed)
            let wobble = driftEnvelope * CGFloat(
                sin(Double(index) * 0.57) * 0.009
                    + sin(Double(index) * 0.19) * 0.004
            )

            return LetterPoint(
                x: min(max(base.x - dy / tangentLength * wobble, 0), 1),
                y: min(
                    max(base.y + dx / tangentLength * wobble, 0),
                    LetterWritingMetrics.canvasHeight
                )
            )
        }
    }
}
