import XCTest
import SwiftUI
import UIKit
@testable import MaxPuzzles

@MainActor
final class MaxPuzzlesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here
    }

    override func tearDownWithError() throws {
        // Put teardown code here
    }

    func testAppStateInitialization() throws {
        let appState = AppState()
        XCTAssertTrue(appState.isLoading, "App should start in loading state")
        XCTAssertTrue(appState.isGuest, "App should start in guest mode")
        XCTAssertNotNil(appState.currentUser, "A local guest should be available immediately")
        XCTAssertTrue(appState.currentUser?.isGuest == true)
    }

    func testGuestUserCreation() throws {
        let guest = User.guest()
        XCTAssertEqual(guest.displayName, "Guest")
        XCTAssertTrue(guest.isGuest)
        XCTAssertEqual(guest.coins, 0)
        XCTAssertEqual(guest.role, .child)
    }

    func testColorHexInitialization() throws {
        // Test 6-character hex
        let green = Color(hex: "22c55e")
        XCTAssertNotNil(green, "Color should be created from hex")

        // Test 3-character hex
        let shortHex = Color(hex: "fff")
        XCTAssertNotNil(shortHex, "Color should be created from 3-char hex")
    }

    func testDotToDotCatalogContainsOnlyTheAuditedDownloadedPack() throws {
        let puzzles = DotPuzzleCatalog.all
        XCTAssertEqual(DotPuzzleCatalog.downloadedReferencePuzzles.count, 84)
        XCTAssertEqual(puzzles.count, 84)
        XCTAssertEqual(Set(puzzles.map(\.id)).count, 84, "Every picture needs a durable unique ID")
        XCTAssertEqual(puzzles.map(\.id), DotPuzzleCatalog.downloadedReferencePuzzles.map(\.id))
        XCTAssertEqual(Set(DotPuzzleCatalog.availableTiers), Set(DotToDotTier.allCases))

        let referenceSheets = Set(DotPuzzleCatalog.downloadedReferencePuzzles.compactMap(\.sourceSheet))
        XCTAssertEqual(referenceSheets, ["D1/D2", "D3", "D4", "D5", "D6", "D7"])

        for puzzle in puzzles {
            XCTAssertFalse(puzzle.title.isEmpty, puzzle.id)
            XCTAssertGreaterThanOrEqual(puzzle.revealOutline.count, 3, puzzle.id)
            XCTAssertEqual(puzzle.points.count, puzzle.tier.maxNumeral, puzzle.id)
            XCTAssertEqual(
                puzzle.revealOutline,
                puzzle.points,
                "\(puzzle.id) has an exterior turn that the numbered trail cannot draw"
            )

            let artworkPoints = puzzle.guidePaths.flatMap { $0 } + puzzle.detailPaths.flatMap { $0 }
            for point in puzzle.revealOutline + puzzle.points + artworkPoints {
                XCTAssertTrue((0...1).contains(point.x), "\(puzzle.id) x=\(point.x)")
                XCTAssertTrue((0...1).contains(point.y), "\(puzzle.id) y=\(point.y)")
            }

            XCTAssertGreaterThanOrEqual(
                DotPuzzleGeometry.meaningfulChoiceCount(in: puzzle.points),
                1,
                "\(puzzle.id) needs at least one spatially plausible choice as well as numeral 1"
            )
        }

        for puzzle in DotPuzzleCatalog.downloadedReferencePuzzles {
            XCTAssertNotNil(puzzle.sourceSheet, puzzle.id)
            let art = try XCTUnwrap(puzzle.referenceArt, "\(puzzle.id) needs its downloaded worksheet art")
            XCTAssertEqual(art.columns, 5, puzzle.id)
            XCTAssertEqual(art.rows, 3, puzzle.id)
            XCTAssertTrue((0..<art.columns).contains(art.column), puzzle.id)
            XCTAssertTrue((0..<art.rows).contains(art.row), puzzle.id)
        }

        let artTiles = DotPuzzleCatalog.downloadedReferencePuzzles.compactMap { puzzle in
            puzzle.referenceArt.map { "\($0.assetName):\($0.column):\($0.row)" }
        }
        XCTAssertEqual(Set(artTiles).count, 84, "Every downloaded picture must use its own atlas tile")
    }

    func testDotCatalogueIgnoresRemovedLegacyProgress() throws {
        let currentID = try XCTUnwrap(DotPuzzleCatalog.all.first?.id)
        let sanitized = DotPuzzleCatalog.sanitizedCompletedIDs([currentID, "rocket", "unicorn"])
        XCTAssertEqual(sanitized, [currentID])
    }

    func testEveryDownloadedPictureHasAnAuthoredSemanticColourPlan() throws {
        var maskTiles = Set<String>()
        var semanticSignatures = Set<String>()
        var planCount = 0
        var swatchCount = 0

        for puzzle in DotPuzzleCatalog.downloadedReferencePuzzles {
            let sheet = try XCTUnwrap(puzzle.sourceSheet, puzzle.id)
            let reference = try XCTUnwrap(puzzle.referenceArt, puzzle.id)
            let slot = reference.row * reference.columns + reference.column + 1
            let plan = try XCTUnwrap(
                DownloadedDotPuzzleColourArtwork.plan(sheet: sheet, slot: slot),
                "\(puzzle.id) needs an authored semantic colour plan"
            )
            planCount += 1

            XCTAssertTrue(
                (4...5).contains(plan.swatches.count),
                "\(puzzle.id) needs four or five meaningful colour groups"
            )
            XCTAssertEqual(
                plan.swatches.map(\.id),
                Array(1...plan.swatches.count),
                "\(puzzle.id) colour identifiers must be consecutive"
            )
            XCTAssertEqual(
                plan.swatches.filter(\.isBackground).count,
                1,
                "\(puzzle.id) needs exactly one semantic background"
            )
            XCTAssertTrue(
                plan.swatches.last?.isBackground == true,
                "\(puzzle.id) background must be hit-tested behind specific foreground regions"
            )

            let names = plan.swatches.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            XCTAssertEqual(
                Set(names.map { $0.lowercased() }).count,
                names.count,
                "\(puzzle.id) needs a distinct semantic name for every colour"
            )
            let signature = names.map { $0.lowercased() }.sorted().joined(separator: "|")
            XCTAssertTrue(
                semanticSignatures.insert(signature).inserted,
                "\(puzzle.id) reused another picture's semantic plan instead of describing this image"
            )

            for swatch in plan.swatches {
                swatchCount += 1
                let name = swatch.name.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(name.isEmpty, "\(puzzle.id) contains an unnamed colour group")
                XCTAssertNil(
                    name.range(
                        of: #"^(region|area|part|colou?r)\s*[0-9]*$"#,
                        options: [.regularExpression, .caseInsensitive]
                    ),
                    "\(puzzle.id) uses the generic name '\(name)' instead of describing the picture"
                )
                XCTAssertNotNil(
                    swatch.hex.range(of: #"^[0-9A-Fa-f]{6}$"#, options: .regularExpression),
                    "\(puzzle.id) \(name) has invalid RGB colour \(swatch.hex)"
                )

                let mask = swatch.maskArt
                XCTAssertEqual(mask.columns, 5, puzzle.id)
                XCTAssertEqual(mask.rows, 3, puzzle.id)
                XCTAssertEqual(mask.column, reference.column, "\(puzzle.id) mask is horizontally misaligned")
                XCTAssertEqual(mask.row, reference.row, "\(puzzle.id) mask is vertically misaligned")
                XCTAssertTrue((0..<mask.columns).contains(mask.column), puzzle.id)
                XCTAssertTrue((0..<mask.rows).contains(mask.row), puzzle.id)
                XCTAssertTrue(mask.assetName.hasPrefix("dot_colour_mask_"), mask.assetName)
                let maskImage = try XCTUnwrap(
                    UIImage(named: mask.assetName),
                    "Missing colour-mask asset \(mask.assetName) for \(puzzle.id)"
                )
                let coverage = try sampledAlphaCoverage(of: maskImage, tile: mask)
                XCTAssertGreaterThan(coverage.visible, 0, "\(puzzle.id) \(name) has an empty mask")
                XCTAssertLessThan(
                    coverage.visible,
                    coverage.total,
                    "\(puzzle.id) \(name) mask incorrectly covers the entire tile"
                )

                let key = "\(mask.assetName):\(mask.column):\(mask.row)"
                XCTAssertTrue(
                    maskTiles.insert(key).inserted,
                    "Colour-mask tile \(key) is incorrectly shared by multiple semantic regions"
                )
                XCTAssertFalse(swatch.labelPoints.isEmpty, "\(puzzle.id) \(name) needs a touch/number anchor")
                for point in swatch.labelPoints {
                    XCTAssertTrue((0...1).contains(point.x), "\(puzzle.id) \(name) x=\(point.x)")
                    XCTAssertTrue((0...1).contains(point.y), "\(puzzle.id) \(name) y=\(point.y)")
                }
            }
        }

        XCTAssertEqual(planCount, 84)
        XCTAssertEqual(semanticSignatures.count, 84)
        XCTAssertEqual(maskTiles.count, swatchCount, "Every semantic group needs its own exact mask tile")
    }

    func testGiraffeUsesRealWorldSemanticColours() throws {
        let plan = try XCTUnwrap(DownloadedDotPuzzleColourArtwork.plan(sheet: "D1/D2", slot: 1))
        XCTAssertEqual(plan.swatches.count, 4)

        let background = try semanticSwatch(containing: "background", in: plan)
        let body = try semanticSwatch(containing: "body", in: plan)
        let spots = try semanticSwatch(containing: "spots", in: plan)
        let features = try semanticSwatch(containing: "features", in: plan)

        let skyRGB = try rgbComponents(background.hex)
        XCTAssertGreaterThan(skyRGB.blue, skyRGB.red, "The giraffe background should be blue")
        XCTAssertGreaterThan(skyRGB.blue, skyRGB.green, "The giraffe background should be blue")

        let bodyRGB = try rgbComponents(body.hex)
        XCTAssertGreaterThan(bodyRGB.red, bodyRGB.blue, "The giraffe body should be golden yellow")
        XCTAssertGreaterThan(bodyRGB.green, bodyRGB.blue, "The giraffe body should be golden yellow")

        let spotRGB = try rgbComponents(spots.hex)
        XCTAssertGreaterThan(spotRGB.red, spotRGB.green, "The giraffe spots should be warm brown")
        XCTAssertGreaterThan(spotRGB.green, spotRGB.blue, "The giraffe spots should be warm brown")

        let featureRGB = try rgbComponents(features.hex)
        XCTAssertGreaterThan(featureRGB.red, featureRGB.green, "The giraffe muzzle/inner ears should be pink")
        XCTAssertGreaterThan(featureRGB.red, featureRGB.blue, "The giraffe muzzle/inner ears should be pink")
    }

    func testSemanticColourProgressAwardsEachRegionOnlyOnce() throws {
        let puzzle = try XCTUnwrap(
            DotPuzzleCatalog.downloadedReferencePuzzles.first { $0.sourceSheet == "D1/D2" }
        )
        let plan = try XCTUnwrap(DownloadedDotPuzzleColourArtwork.plan(sheet: "D1/D2", slot: 1))
        let suiteName = "MaxPuzzlesTests.semanticColourProgress.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storage = StorageService(defaults: defaults)
        let profile = UUID()
        storage.activateProfile(profile)

        let firstThree = Array(plan.swatches.prefix(3).map(\.id))
        for id in firstThree {
            storage.colorDotToDotRegion(id, for: puzzle.id)
            storage.colorDotToDotRegion(id, for: puzzle.id)
        }
        XCTAssertEqual(
            storage.coloredDotToDotRegions(for: puzzle.id),
            Set(firstThree),
            "Repeated taps or drag samples must not award duplicate marks"
        )
        XCTAssertNotEqual(
            storage.coloredDotToDotRegions(for: puzzle.id),
            Set(plan.swatches.map(\.id)),
            "Colouring is not complete while a semantic region remains untouched"
        )

        for id in plan.swatches.map(\.id) {
            storage.colorDotToDotRegion(id, for: puzzle.id)
        }
        XCTAssertEqual(
            storage.coloredDotToDotRegions(for: puzzle.id),
            Set(plan.swatches.map(\.id)),
            "Completion should mean every distinct semantic region has work"
        )

        storage.resetDotToDotColoring(for: puzzle.id)
        XCTAssertTrue(storage.coloredDotToDotRegions(for: puzzle.id).isEmpty)
    }

    func testTapAndPencilModesShareUniqueSemanticProgress() {
        XCTAssertEqual(DotColouringMode.allCases.map(\.rawValue), ["tapToFill", "shade"])

        var progress = DotColouringProgress(requiredRegionIDs: [1, 2, 3, 4])
        XCTAssertFalse(progress.isComplete)
        XCTAssertEqual(progress.completedCount, 0)

        XCTAssertTrue(progress.recordTap(in: 1))
        XCTAssertFalse(progress.recordTap(in: 1), "Repeated taps cannot award another mark")
        XCTAssertFalse(progress.recordTap(in: 99), "Unknown regions cannot award progress")
        XCTAssertEqual(progress.completedCount, 1)

        XCTAssertFalse(
            progress.recordStroke(
                in: 2,
                coverage: DotColourCoverageEvaluator.completionThreshold - 0.001
            ),
            "A tiny stroke must not complete an entire semantic region"
        )
        XCTAssertTrue(
            progress.recordStroke(in: 2, coverage: DotColourCoverageEvaluator.completionThreshold)
        )
        XCTAssertFalse(
            progress.recordStroke(in: 2, coverage: 1),
            "Many drag samples in one region count once"
        )
        XCTAssertFalse(
            progress.recordStroke(in: 1, coverage: 1),
            "Shading a region already tap-filled cannot award another mark"
        )
        XCTAssertEqual(progress.completedRegionIDs, [1, 2])
        XCTAssertFalse(progress.isComplete)

        XCTAssertTrue(progress.recordStroke(in: 3, coverage: 1))
        XCTAssertTrue(progress.recordTap(in: 4))
        XCTAssertEqual(progress.completedCount, progress.requiredCount)
        XCTAssertTrue(progress.isComplete, "Tap fills and genuine pencil strokes should combine")

        progress.reset()
        XCTAssertEqual(progress.completedCount, 0)
        XCTAssertFalse(progress.isComplete)
    }

    func testColouringOnlyAcceptsTheSelectedSemanticMask() {
        XCTAssertTrue(
            DotColouringInteractionPolicy.accepts(selectedSwatchID: 3, semanticRegionID: 3)
        )
        XCTAssertFalse(
            DotColouringInteractionPolicy.accepts(selectedSwatchID: 3, semanticRegionID: 2),
            "A selected brown-spots pot must not paint the yellow-body mask"
        )
        XCTAssertFalse(
            DotColouringInteractionPolicy.accepts(selectedSwatchID: 3, semanticRegionID: nil),
            "Touches outside all masks must not paint"
        )

        let inside = DotColouringInteractionPolicy.normalizedPoint(
            CGPoint(x: 80, y: 30),
            in: CGSize(width: 100, height: 60)
        )
        XCTAssertEqual(inside.x, 0.8, accuracy: 0.000_1)
        XCTAssertEqual(inside.y, 0.5, accuracy: 0.000_1)

        let clamped = DotColouringInteractionPolicy.normalizedPoint(
            CGPoint(x: -20, y: 90),
            in: CGSize(width: 100, height: 60)
        )
        XCTAssertEqual(clamped, CGPoint(x: 0, y: 1))

        let stroke = DotColourStroke(
            regionID: 3,
            swatchID: 3,
            points: [inside, clamped],
            normalizedLineWidth: 0.04
        )
        XCTAssertEqual(stroke.regionID, 3)
        XCTAssertEqual(stroke.swatchID, 3)
        XCTAssertEqual(stroke.points, [inside, clamped])
        XCTAssertEqual(stroke.normalizedLineWidth, 0.04, accuracy: 0.000_1)
    }

    func testPencilModeRequiresMeaningfulShadingBeforeAwardingProgress() {
        XCTAssertFalse(
            DotColouringInteractionPolicy.isMeaningfulStroke(
                inMaskSampleCount: 1,
                cumulativeInMaskDistance: 0
            ),
            "A tap in pencil mode is not shading"
        )
        XCTAssertFalse(
            DotColouringInteractionPolicy.isMeaningfulStroke(
                inMaskSampleCount: 2,
                cumulativeInMaskDistance: 0.20
            ),
            "A gesture needs enough actual in-mask samples"
        )
        XCTAssertFalse(
            DotColouringInteractionPolicy.isMeaningfulStroke(
                inMaskSampleCount: 3,
                cumulativeInMaskDistance: 0.011
            ),
            "Tiny accidental movement must not be stored as shading"
        )
        XCTAssertTrue(
            DotColouringInteractionPolicy.isMeaningfulStroke(
                inMaskSampleCount: 3,
                cumulativeInMaskDistance: 0.012
            )
        )
    }

    func testPencilCoverageAndPersistenceAreBounded() throws {
        let plan = try XCTUnwrap(DownloadedDotPuzzleColourArtwork.plan(sheet: "D1/D2", slot: 1))
        let swatch = try XCTUnwrap(plan.swatches.first)
        let atlas = try XCTUnwrap(UIImage(named: swatch.maskArt.assetName)?.cgImage)
        let cropped = try XCTUnwrap(DotSemanticMaskHitTester.croppedImage(for: swatch.maskArt)?.cgImage)
        XCTAssertEqual(cropped.width, atlas.width / swatch.maskArt.columns)
        XCTAssertEqual(cropped.height, atlas.height / swatch.maskArt.rows)
        XCTAssertLessThan(cropped.width, atlas.width, "Runtime should retain a tile, not the full atlas")
        XCTAssertLessThanOrEqual(DotSemanticMaskHitTester.maximumCacheCostBytes, 24 * 1_024 * 1_024)
        XCTAssertTrue(DotSemanticMaskHitTester.hasCachedImage(for: swatch.maskArt))
        DotSemanticMaskHitTester.release(plan, referenceArt: nil)
        XCTAssertFalse(DotSemanticMaskHitTester.hasCachedImage(for: swatch.maskArt))

        let anchor = try XCTUnwrap(swatch.labelPoints.first)
        let tinyStroke = DotColourStroke(
            regionID: swatch.id,
            swatchID: swatch.id,
            points: [anchor, CGPoint(x: anchor.x + 0.015, y: anchor.y)]
        )
        XCTAssertLessThan(
            DotColourCoverageEvaluator.coverage(of: [tinyStroke], in: swatch.maskArt),
            DotColourCoverageEvaluator.completionThreshold,
            "One small mark must not fill the whole colour group"
        )

        var sampled = DotColourStroke(regionID: 1, swatchID: 1, points: [.zero])
        for index in 1...2_000 {
            let point = CGPoint(
                x: CGFloat(index % 101) / 100,
                y: CGFloat((index * 7) % 101) / 100
            )
            _ = DotColourStrokeSampler.append(point, to: &sampled)
        }
        XCTAssertLessThanOrEqual(sampled.points.count, DotColourStrokeSampler.maximumPointsPerStroke)

        let suiteName = "MaxPuzzlesTests.dotColourSnapshot.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = DotColouringSnapshotStore(defaults: defaults)
        let profile = UUID()
        let snapshot = DotColouringSnapshot(tapFilledRegionIDs: [2], strokes: [tinyStroke, sampled])
        store.save(snapshot, puzzleID: "picture", profileID: profile)
        XCTAssertEqual(store.load(puzzleID: "picture", profileID: profile), snapshot)
        XCTAssertEqual(store.load(puzzleID: "picture", profileID: UUID()), .empty)

        let backgroundSnapshot = DotColouringSnapshot(
            tapFilledRegionIDs: [2, 3],
            strokes: [tinyStroke]
        )
        store.saveInBackground(backgroundSnapshot, puzzleID: "picture", profileID: profile)
        XCTAssertEqual(
            store.load(puzzleID: "picture", profileID: profile),
            backgroundSnapshot,
            "A read must wait for any earlier background snapshot write"
        )

        store.reset(puzzleID: "picture", profileID: profile)
        XCTAssertEqual(store.load(puzzleID: "picture", profileID: profile), .empty)
    }

    func testSubitizingBonusUsesDistinctChoicesAndStandardOneToFivePatterns() {
        for quantity in 1...5 {
            let choices = SubitizingChallenge.choices(for: quantity, puzzleID: "picture-\(quantity)")
            XCTAssertEqual(choices.count, 3)
            XCTAssertEqual(Set(choices).count, 3)
            XCTAssertTrue(choices.contains(quantity))
            XCTAssertEqual(SubitizingChallenge.pattern(for: quantity).count, quantity)
        }
    }

    func testDotToDotProgressAndPlayStyleStaySeparatePerProfile() {
        let suiteName = "MaxPuzzlesTests.dotProfiles.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storage = StorageService(defaults: defaults)
        let mia = UUID()
        let leo = UUID()
        let miaPuzzle = DotPuzzleCatalog.all[0]
        let leoPuzzle = DotPuzzleCatalog.all[1]

        storage.activateProfile(mia)
        XCTAssertTrue(storage.markDotToDotPuzzleCompleted(miaPuzzle.id))
        XCTAssertFalse(storage.markDotToDotPuzzleCompleted(miaPuzzle.id), "A replay is not a new milestone")
        storage.setDotToDotInteractionMode(.trace)
        storage.colorDotToDotRegion(1, for: miaPuzzle.id)
        storage.colorDotToDotRegion(2, for: miaPuzzle.id)

        storage.activateProfile(leo)
        XCTAssertTrue(storage.dotToDotCompletedPuzzles.isEmpty)
        XCTAssertEqual(storage.dotToDotInteractionMode, .tap)
        XCTAssertTrue(storage.coloredDotToDotRegions(for: miaPuzzle.id).isEmpty)
        XCTAssertTrue(storage.markDotToDotPuzzleCompleted(leoPuzzle.id))
        storage.colorDotToDotRegion(1, for: leoPuzzle.id)

        storage.activateProfile(mia)
        XCTAssertEqual(storage.dotToDotCompletedPuzzles, [miaPuzzle.id])
        XCTAssertEqual(storage.dotToDotInteractionMode, .trace)
        XCTAssertEqual(storage.coloredDotToDotRegions(for: miaPuzzle.id), [1, 2])
        XCTAssertTrue(storage.coloredDotToDotRegions(for: leoPuzzle.id).isEmpty)
    }

    func testCloudMergeKeepsTheStrongestProgressFromBothDevices() {
        let profileID = UUID()
        let older = CometChildProfile(
            id: profileID,
            name: "Mia",
            writingHand: .right,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        var renamed = older
        renamed.name = "Mia Rose"

        var localProgress = CloudProfileProgress()
        localProgress.dotToDotCompletedPuzzles = ["rocket", "star"]
        localProgress.dotToDotColoredRegions = ["rocket": [1, 2]]
        localProgress.cometWriterCompletedLetters = ["a"]
        localProgress.cometWriterBestScores = ["a": 82]
        localProgress.storyLevels["1-1"] = CloudLevelProgress(
            completed: true, stars: 2, bestTimeSeconds: 42, attempts: 3
        )

        var remoteProgress = CloudProfileProgress()
        remoteProgress.dotToDotCompletedPuzzles = ["star", "fish"]
        remoteProgress.dotToDotColoredRegions = ["rocket": [2, 3], "fish": [1]]
        remoteProgress.cometWriterCompletedLetters = ["b"]
        remoteProgress.cometWriterBestScores = ["a": 94, "b": 76]
        remoteProgress.storyLevels["1-1"] = CloudLevelProgress(
            completed: true, stars: 3, bestTimeSeconds: 38, attempts: 2
        )

        let local = CloudProgressEnvelope(
            profiles: [older],
            profileModifiedAt: [profileID.uuidString: Date(timeIntervalSince1970: 200)],
            deletedProfileAt: [:],
            progressByProfile: [profileID.uuidString: localProgress]
        )
        let remote = CloudProgressEnvelope(
            profiles: [renamed],
            profileModifiedAt: [profileID.uuidString: Date(timeIntervalSince1970: 300)],
            deletedProfileAt: [:],
            progressByProfile: [profileID.uuidString: remoteProgress]
        )

        let merged = CloudProgressMerger.merge(local: local, remote: remote)
        XCTAssertEqual(merged.profiles.first?.name, "Mia Rose")
        let progress = try! XCTUnwrap(merged.progressByProfile[profileID.uuidString])
        XCTAssertEqual(Set(progress.dotToDotCompletedPuzzles), ["rocket", "star", "fish"])
        XCTAssertEqual(progress.dotToDotColoredRegions?["rocket"], [1, 2, 3])
        XCTAssertEqual(progress.dotToDotColoredRegions?["fish"], [1])
        XCTAssertEqual(Set(progress.cometWriterCompletedLetters), ["a", "b"])
        XCTAssertEqual(progress.cometWriterBestScores["a"], 94)
        XCTAssertEqual(progress.storyLevels["1-1"]?.stars, 3)
        XCTAssertEqual(progress.storyLevels["1-1"]?.bestTimeSeconds, 38)
        XCTAssertEqual(progress.storyLevels["1-1"]?.attempts, 3)
    }

    func testCloudProfileDeletionWinsOnlyWhenItIsNewerThanTheProfile() {
        let profile = CometChildProfile(
            id: UUID(),
            name: "Leo",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let id = profile.id.uuidString
        let local = CloudProgressEnvelope(
            profiles: [profile],
            profileModifiedAt: [id: Date(timeIntervalSince1970: 200)],
            deletedProfileAt: [:],
            progressByProfile: [id: CloudProfileProgress()]
        )
        let remote = CloudProgressEnvelope(
            profiles: [],
            profileModifiedAt: [:],
            deletedProfileAt: [id: Date(timeIntervalSince1970: 300)],
            progressByProfile: [:]
        )

        // The merger's last-profile guard keeps one usable child even under a concurrent delete.
        let merged = CloudProgressMerger.merge(local: local, remote: remote)
        XCTAssertEqual(merged.profiles.count, 1)
        XCTAssertNil(merged.deletedProfileAt[id])
    }

    func testNewerCloudResetCannotBeUndoneByStaleDeviceProgress() {
        let oldProfile = CometChildProfile(
            id: UUID(),
            name: "Old progress",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let freshProfile = CometChildProfile(
            id: UUID(),
            name: "Fresh start",
            createdAt: Date(timeIntervalSince1970: 400)
        )
        var oldProgress = CloudProfileProgress()
        oldProgress.dotToDotCompletedPuzzles = ["rocket"]
        let stale = CloudProgressEnvelope(
            resetAt: nil,
            profiles: [oldProfile],
            profileModifiedAt: [oldProfile.id.uuidString: Date(timeIntervalSince1970: 300)],
            deletedProfileAt: [:],
            progressByProfile: [oldProfile.id.uuidString: oldProgress]
        )
        let reset = CloudProgressEnvelope(
            resetAt: Date(timeIntervalSince1970: 500),
            profiles: [freshProfile],
            profileModifiedAt: [freshProfile.id.uuidString: Date(timeIntervalSince1970: 500)],
            deletedProfileAt: [:],
            progressByProfile: [freshProfile.id.uuidString: CloudProfileProgress()]
        )

        let resetWinsAsRemote = CloudProgressMerger.merge(local: stale, remote: reset)
        let resetWinsAsLocal = CloudProgressMerger.merge(local: reset, remote: stale)
        XCTAssertEqual(resetWinsAsRemote.profiles.map(\.id), [freshProfile.id])
        XCTAssertEqual(resetWinsAsLocal.profiles.map(\.id), [freshProfile.id])
        XCTAssertTrue(
            resetWinsAsRemote.progressByProfile[freshProfile.id.uuidString]?
                .dotToDotCompletedPuzzles.isEmpty == true
        )
    }

    private func semanticSwatch(
        containing token: String,
        in plan: DotSemanticColourPlan,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> DotSemanticColourSwatch {
        try XCTUnwrap(
            plan.swatches.first { $0.name.localizedCaseInsensitiveContains(token) },
            "Missing semantic giraffe colour containing '\(token)'",
            file: file,
            line: line
        )
    }

    private func rgbComponents(
        _ hex: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (red: Int, green: Int, blue: Int) {
        let value = try XCTUnwrap(
            UInt32(hex, radix: 16),
            "Invalid six-digit RGB value '\(hex)'",
            file: file,
            line: line
        )
        return (
            red: Int((value >> 16) & 0xff),
            green: Int((value >> 8) & 0xff),
            blue: Int(value & 0xff)
        )
    }

    private func sampledAlphaCoverage(
        of image: UIImage,
        tile: DotPuzzleReferenceArt,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (visible: Int, total: Int) {
        let source = try XCTUnwrap(image.cgImage, "Mask asset has no CGImage", file: file, line: line)
        let tileWidth = source.width / tile.columns
        let tileHeight = source.height / tile.rows
        let cropRect = CGRect(
            x: tile.column * tileWidth,
            y: tile.row * tileHeight,
            width: tileWidth,
            height: tileHeight
        )
        let cropped = try XCTUnwrap(
            source.cropping(to: cropRect),
            "Could not crop mask tile \(tile.assetName):\(tile.column):\(tile.row)",
            file: file,
            line: line
        )

        // A small render is enough to catch empty or accidentally opaque tiles while keeping this
        // exhaustive 84-picture check quick on CI and the simulator.
        let sampleSide = 96
        var rgba = [UInt8](repeating: 0, count: sampleSide * sampleSide * 4)
        try rgba.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(
                CGContext(
                    data: bytes.baseAddress,
                    width: sampleSide,
                    height: sampleSide,
                    bitsPerComponent: 8,
                    bytesPerRow: sampleSide * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ),
                "Could not inspect mask pixels",
                file: file,
                line: line
            )
            context.interpolationQuality = .high
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: sampleSide, height: sampleSide))
        }
        let visible = stride(from: 3, to: rgba.count, by: 4).reduce(into: 0) { count, index in
            if rgba[index] > 8 { count += 1 }
        }
        return (visible, sampleSide * sampleSide)
    }
}
