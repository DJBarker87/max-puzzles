import AVFoundation
import Combine
import XCTest
@testable import MaxPuzzles

final class PhonemeAudioFoundationTests: XCTestCase {
    func testCatalogueContainsTheCompleteTraditionalBritishTeachingInventory() {
        let all = BritishEnglishPhonemeCatalogue.all

        XCTAssertEqual(BritishEnglishPhonemeCatalogue.datasetID, "en_gb_primary_phonemes_v1")
        XCTAssertEqual(all.count, 44)
        XCTAssertEqual(all.filter { $0.category == .consonant }.count, 24)
        XCTAssertEqual(all.filter { $0.category == .vowel }.count, 20)
        XCTAssertEqual(Set(all.map(\.id)), Set(BritishEnglishPhoneme.ID.allCases))
        XCTAssertEqual(Set(all.map { $0.id.rawValue }), expectedStableIDs)
        XCTAssertEqual(
            Set(BritishEnglishPhoneme.ID.allCases.map(\.rawValue)),
            expectedStableIDs
        )
        XCTAssertTrue(BritishEnglishPhonemeCatalogue.validationIssues.isEmpty)
    }

    func testEveryPhonemeHasCompleteStableAudioMetadata() {
        let all = BritishEnglishPhonemeCatalogue.all

        XCTAssertEqual(Set(all.map { $0.id.rawValue }).count, 44)
        for phoneme in all {
            XCTAssertFalse(phoneme.curriculumIPA.isEmpty, phoneme.id.rawValue)
            XCTAssertFalse(phoneme.synthesisIPA.isEmpty, phoneme.id.rawValue)
            XCTAssertFalse(phoneme.teachingGrapheme.isEmpty, phoneme.id.rawValue)
            XCTAssertFalse(phoneme.exampleWord.isEmpty, phoneme.id.rawValue)
            XCTAssertFalse(phoneme.commonGraphemes.isEmpty, phoneme.id.rawValue)
            XCTAssertTrue(
                phoneme.commonGraphemes.contains(phoneme.teachingGrapheme),
                "Teaching grapheme is not mapped for \(phoneme.id.rawValue)"
            )
        }
    }

    func testAmbiguousGraphemesReturnEverySoundInsteadOfGuessingFromTheLetter() {
        XCTAssertEqual(
            ids(for: "c"),
            [.consonantK, .consonantS]
        )
        XCTAssertEqual(
            ids(for: "g"),
            [.consonantG, .consonantJ]
        )
        XCTAssertEqual(
            ids(for: "th"),
            [.consonantTHUnvoiced, .consonantTHVoiced]
        )
        XCTAssertTrue(ids(for: "oo").isSuperset(of: [.vowelFoot, .vowelGoose]))
        XCTAssertTrue(
            ids(for: "ear").isSuperset(
                of: [.vowelPalm, .vowelSquare, .vowelNear, .vowelNurse]
            )
        )
    }

    func testXQuAndYooAreSoundSequencesNotInventedPhonemes() {
        XCTAssertTrue(BritishEnglishPhonemeCatalogue.phonemes(forGrapheme: "x").isEmpty)
        XCTAssertTrue(BritishEnglishPhonemeCatalogue.phonemes(forGrapheme: "qu").isEmpty)

        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "x")?.phonemeIDs,
            [.consonantK, .consonantS]
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "qu")?.phonemeIDs,
            [.consonantK, .consonantW]
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "u")?.phonemeIDs,
            [.consonantY, .vowelGoose]
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "ew")?.phonemeIDs,
            [.consonantY, .vowelGoose]
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "u")?.pronunciationLabel,
            "yoo"
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "ew")?.pronunciationLabel,
            "yoo"
        )
        XCTAssertEqual(
            BritishEnglishPhonemeCatalogue.sequence(forGrapheme: "u")?.isContextDependent,
            true
        )
    }

    func testTraditionalCureSoundIsPresentAndExplicitlyDialectDependent() throws {
        let cure = try XCTUnwrap(
            BritishEnglishPhonemeCatalogue.phoneme(for: .vowelCure)
        )

        XCTAssertEqual(cure.curriculumIPA, "ʊə")
        XCTAssertEqual(cure.exampleWord, "pure")
        XCTAssertTrue(cure.isDialectDependent)
    }

    func testYAndWAreKeptShortToAvoidAddingAVowelOrSchwa() throws {
        let y = try XCTUnwrap(
            BritishEnglishPhonemeCatalogue.phoneme(for: .consonantY)
        )
        let w = try XCTUnwrap(
            BritishEnglishPhonemeCatalogue.phoneme(for: .consonantW)
        )

        XCTAssertEqual(y.delivery, .short)
        XCTAssertEqual(w.delivery, .short)
    }

    func testRUsesTheCurriculumSymbolButARealApproximantForIPAPreview() throws {
        let r = try XCTUnwrap(
            BritishEnglishPhonemeCatalogue.phoneme(for: .consonantR)
        )

        XCTAssertEqual(r.curriculumIPA, "r")
        XCTAssertEqual(r.synthesisIPA, "ɹ")
    }

    func testEveryIPAPreviewCarriesAuthoredIPAAndNeverTheDisplayedLetter() throws {
        let ipaKey = NSAttributedString.Key(
            rawValue: AVSpeechSynthesisIPANotationAttribute
        )

        for phoneme in BritishEnglishPhonemeCatalogue.all {
            let attributed = try XCTUnwrap(
                PhonemeAudioService.ipaPreviewAttributedText(for: phoneme),
                phoneme.id.rawValue
            )
            XCTAssertEqual(attributed.string, "sound")
            XCTAssertNotEqual(attributed.string, phoneme.teachingGrapheme)
            XCTAssertNotEqual(attributed.string, phoneme.id.rawValue)
            XCTAssertEqual(
                attributed.attribute(ipaKey, at: 0, effectiveRange: nil) as? String,
                phoneme.synthesisIPA
            )
        }
    }

    func testApprovedRecordingReferencesAreUniqueAndVersionedForAllSounds() {
        let references = BritishEnglishPhoneme.ID.allCases.map {
            PhonemeAudioService.approvedRecordingReference(for: $0)
        }

        XCTAssertEqual(references.count, 44)
        XCTAssertEqual(Set(references).count, 44)
        XCTAssertTrue(references.allSatisfy { $0.fileExtension == "m4a" })
        XCTAssertTrue(
            references.allSatisfy {
                $0.subdirectory == "PhonemeAudio/en-GB/v1"
                    && $0.resourceName == "phoneme_\($0.stableID)"
            }
        )
    }

    func testRecordingContractFolderIsBundledForFutureApprovedClips() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "recording-contract",
                withExtension: "json",
                subdirectory: "PhonemeAudio/en-GB/v1"
            )
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        )
        let bundledStableIDs = try XCTUnwrap(object["expectedStableIDs"] as? [String])

        XCTAssertEqual(object["datasetID"] as? String, BritishEnglishPhonemeCatalogue.datasetID)
        XCTAssertEqual(
            object["humanReviewStatus"] as? String,
            "owner-authorized-for-integration-device-audition-pending"
        )
        XCTAssertEqual(
            object["integrationStatus"] as? String,
            "comet-writer-and-star-speller-enabled"
        )
        XCTAssertEqual(object["rawAudioIncludedInPublicRepository"] as? Bool, false)
        XCTAssertEqual(Set(bundledStableIDs), expectedStableIDs)
    }

    @MainActor
    func testLocallySuppliedRecordingSetIsCompleteAndDecodable() throws {
        let suiteName = "PhonemeAudioAssetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = StorageService(defaults: defaults)
        storage.setVoiceVolume(0)
        let service = PhonemeAudioService(bundle: .main, storage: storage)
        let audit = service.auditApprovedRecordingAssets()

        guard !audit.available.isEmpty else {
            throw XCTSkip("Source audio is intentionally absent from a clean public clone")
        }

        XCTAssertTrue(audit.isComplete, "A recording set must be all-or-nothing")
        XCTAssertEqual(audit.available.count, 44)
        XCTAssertTrue(audit.issues.isEmpty)

        for reference in audit.available {
            let url = try XCTUnwrap(
                Bundle.main.url(
                    forResource: reference.resourceName,
                    withExtension: reference.fileExtension,
                    subdirectory: reference.subdirectory
                ),
                reference.relativePath
            )
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let duration = Double(file.length) / format.sampleRate

            XCTAssertEqual(format.channelCount, 1, reference.relativePath)
            XCTAssertEqual(format.sampleRate, 48_000, accuracy: 0.5, reference.relativePath)
            XCTAssertGreaterThanOrEqual(duration, 0.22, reference.relativePath)
            XCTAssertLessThanOrEqual(duration, 1.50, reference.relativePath)

            let id = try XCTUnwrap(
                BritishEnglishPhoneme.ID(rawValue: reference.stableID),
                reference.stableID
            )
            switch service.play(id) {
            case let .started(stableID, .approvedRecording(source), requestID):
                XCTAssertEqual(stableID, reference.stableID)
                XCTAssertEqual(source, reference)
                XCTAssertGreaterThan(requestID, 0)
            default:
                XCTFail("Could not start recording \(reference.relativePath)")
            }
        }
        service.stop()
    }

    @MainActor
    func testOnlyANaturallyFinishedApprovedClipPublishesItsMatchingRequest() async throws {
        let suiteName = "PhonemeAudioCompletionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = StorageService(defaults: defaults)
        storage.setVoiceVolume(0)
        let service = PhonemeAudioService(bundle: .main, storage: storage)
        guard service.auditApprovedRecordingAssets().isComplete else {
            throw XCTSkip("Commercial audio is intentionally absent from a clean public clone")
        }

        let naturalFinish = expectation(description: "approved clip finishes naturally")
        var naturalCompletion: PhonemeAudioPlaybackCompletion?
        let naturalCancellable = service.approvedPlaybackDidFinish.sink { completion in
            naturalCompletion = completion
            naturalFinish.fulfill()
        }

        let started = service.play(.consonantK)
        let requestID: UInt64
        if case let .started(stableID, _, startedRequestID) = started {
            XCTAssertEqual(stableID, BritishEnglishPhoneme.ID.consonantK.rawValue)
            requestID = startedRequestID
        } else {
            return XCTFail("The /k/ clip did not start: \(started)")
        }

        await fulfillment(of: [naturalFinish], timeout: 2)
        XCTAssertEqual(
            naturalCompletion,
            PhonemeAudioPlaybackCompletion(
                stableID: BritishEnglishPhoneme.ID.consonantK.rawValue,
                requestID: requestID
            )
        )
        withExtendedLifetime(naturalCancellable) {}

        let stoppedClipFinished = expectation(description: "stopped clip must not finish")
        stoppedClipFinished.isInverted = true
        let stoppedCancellable = service.approvedPlaybackDidFinish.sink { _ in
            stoppedClipFinished.fulfill()
        }
        guard case .started = service.play(.consonantS) else {
            return XCTFail("The /s/ clip did not start")
        }
        service.stop()
        await fulfillment(of: [stoppedClipFinished], timeout: 0.25)
        withExtendedLifetime(stoppedCancellable) {}
    }

    @MainActor
    func testProductionPlaybackNeverFallsBackWhenAnApprovedRecordingIsMissing() throws {
        let suiteName = "PhonemeAudioFoundationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = PhonemeAudioService(
            bundle: Bundle(for: PhonemeAudioFoundationTests.self),
            storage: StorageService(defaults: defaults)
        )
        let expectedReference = PhonemeAudioService.approvedRecordingReference(
            for: .consonantK
        )

        XCTAssertEqual(
            service.play(.consonantK),
            .missingApprovedRecording(expectedReference)
        )
        XCTAssertEqual(
            service.state,
            .missingApprovedRecording(expectedReference)
        )

        let audit = service.auditApprovedRecordingAssets()
        XCTAssertEqual(audit.expected.count, 44)
        XCTAssertTrue(audit.available.isEmpty)
        XCTAssertEqual(
            audit.issues.filter {
                if case .missing = $0 { return true }
                return false
            }.count,
            44
        )
    }

    @MainActor
    func testDebugLabCanStartAnIPAControlledPreviewForEveryPhoneme() throws {
        let suiteName = "PhonemeAudioPreviewTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = StorageService(defaults: defaults)
        storage.setVoiceVolume(0)
        let service = PhonemeAudioService(
            bundle: Bundle(for: PhonemeAudioFoundationTests.self),
            storage: storage
        )
        defer { service.stop() }

        for phoneme in BritishEnglishPhonemeCatalogue.all {
            switch service.previewIPAInLab(phoneme) {
            case let .started(stableID, .ipaLabPreview(synthesisIPA), requestID):
                XCTAssertEqual(stableID, phoneme.id.rawValue)
                XCTAssertEqual(synthesisIPA, phoneme.synthesisIPA)
                XCTAssertGreaterThan(requestID, 0)
            default:
                XCTFail("Could not start IPA preview for \(phoneme.id.rawValue)")
            }
        }
    }

    private func ids(
        for grapheme: String
    ) -> Set<BritishEnglishPhoneme.ID> {
        Set(
            BritishEnglishPhonemeCatalogue
                .phonemes(forGrapheme: grapheme)
                .map(\.id)
        )
    }

    private var expectedStableIDs: Set<String> {
        [
            "c_p", "c_b", "c_t", "c_d", "c_k", "c_g", "c_f", "c_v",
            "c_th_vl", "c_th_vd", "c_s", "c_z", "c_sh", "c_zh", "c_h",
            "c_tsh", "c_dzh", "c_m", "c_n", "c_ng", "c_l", "c_r", "c_yod", "c_w",
            "v_fleece", "v_kit", "v_dress", "v_trap", "v_strut", "v_lot",
            "v_foot", "v_goose", "v_face", "v_price", "v_mouth", "v_goat",
            "v_choice", "v_thought", "v_nurse", "v_palm", "v_square", "v_near",
            "v_schwa", "v_cure"
        ]
    }
}
