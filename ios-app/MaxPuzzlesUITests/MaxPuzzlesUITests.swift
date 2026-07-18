import XCTest
import UIKit

final class MaxPuzzlesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testStandalonePhonemeAudioLabExposesTheCompleteAuditionSurface() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-phoneme-audio-lab"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["phoneme-audio-lab"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Phoneme Audio Lab"].exists)
        XCTAssertTrue(app.staticTexts["44 British-English sounds"].exists)
        XCTAssertTrue(app.otherElements["phoneme-audio-source-notice"].exists)
        XCTAssertTrue(app.staticTexts["phoneme-recording-coverage"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["phoneme-play-c_p"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["phoneme-recording-c_p"].exists)

        app.segmentedControls.buttons["Vowels"].tap()
        XCTAssertTrue(app.buttons["phoneme-play-v_fleece"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["phoneme-play-c_p"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Standalone phoneme audio lab"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testExpiredPlayTimerRequiresParentPasscodeBeforeResuming() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-skip-onboarding",
            "-ui-testing-expired-play-timer"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["play-time-lock"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Time for a break"].exists)

        let grownUpOptions = app.buttons["play-time-grown-up-options"]
        XCTAssertTrue(grownUpOptions.waitForExistence(timeout: 2))
        grownUpOptions.tap()

        let passcodeField = app.secureTextFields["parent-passcode-entry"]
        XCTAssertTrue(passcodeField.waitForExistence(timeout: 3))
        passcodeField.tap()
        passcodeField.typeText("1111")
        app.buttons["parent-passcode-continue"].tap()
        XCTAssertTrue(app.staticTexts["Error: That passcode isn't right. Please try again."].waitForExistence(timeout: 2))

        passcodeField.tap()
        passcodeField.typeText("2468")
        app.buttons["parent-passcode-continue"].tap()

        XCTAssertTrue(app.otherElements["play-time-settings"].waitForExistence(timeout: 3))
        let fifteenMinutes = app.buttons["play-time-preset-15"]
        XCTAssertTrue(fifteenMinutes.waitForExistence(timeout: 2))
        fifteenMinutes.tap()
        app.buttons["play-time-apply"].tap()

        XCTAssertFalse(app.otherElements["play-time-lock"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 4))

        let quickTimerButton = app.buttons["parent-play-timer"]
        XCTAssertTrue(quickTimerButton.waitForExistence(timeout: 3))
        XCTAssertTrue((quickTimerButton.value as? String)?.contains("remaining") == true)
        quickTimerButton.tap()
        XCTAssertTrue(app.secureTextFields["parent-passcode-entry"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()

        let timerButton = app.buttons["settings-play-timer"]
        XCTAssertTrue(timerButton.waitForExistence(timeout: 3))
        XCTAssertTrue((timerButton.value as? String)?.contains("remaining") == true)
    }

    func testFreshLaunchCompletesPrivateNameSetup() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Let’s set up your players"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'iCloud'")).firstMatch.exists)

        let nameField = app.textFields["first-run-name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: nameField
        )
        XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 3), .completed)
        XCTAssertFalse(app.buttons["first-run-continue"].isEnabled)
        nameField.tap()
        nameField.typeText("Max")

        let continueButton = app.buttons["first-run-continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        XCTAssertTrue(
            app.scrollViews["player-profile-selection"].waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.buttons["add-player-profile"].exists,
            "Adding another child must be explicit during first onboarding"
        )
        XCTAssertTrue(app.buttons["Max profile"].exists)
        app.buttons["Max profile"].tap()
        XCTAssertTrue(app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 3))
    }

    func testFirstRunIdentitySurvivesTerminationDuringExitAnimation() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        let nameField = app.textFields["first-run-name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        nameField.tap()
        nameField.typeText("Nova")

        let continueButton = app.buttons["first-run-continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.tap()

        // Terminate inside the 0.5-second visual transition. Identity and the completion flag
        // must already be durable, with the profile write occurring before the flag write.
        app.terminate()
        app.launchArguments = ["-ui-testing-preserve-state"]
        app.launch()

        XCTAssertTrue(
            app.scrollViews["player-profile-selection"].waitForExistence(timeout: 4)
        )
        XCTAssertTrue(app.buttons["add-player-profile"].exists)
        XCTAssertTrue(app.buttons["Nova profile"].exists)
        app.buttons["Nova profile"].tap()
        XCTAssertTrue(app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Playing as Nova"].waitForExistence(timeout: 2))
    }

    func testMultipleChildrenChooseAProfileOnLaunchAndSwitchFromTheHub() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 4))
        app.buttons["switch-player"].tap()
        XCTAssertTrue(
            app.scrollViews["player-profile-selection"].waitForExistence(timeout: 3)
        )

        addProfile(named: "Mia", in: app)
        XCTAssertTrue(app.staticTexts["Playing as Mia"].waitForExistence(timeout: 3))

        app.buttons["switch-player"].tap()
        addProfile(named: "Leo", in: app)
        XCTAssertTrue(app.staticTexts["Playing as Leo"].waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(
            app.scrollViews["player-profile-selection"].waitForExistence(timeout: 4)
        )
        XCTAssertTrue(app.buttons["Mia profile"].exists)
        XCTAssertTrue(app.buttons["Leo profile"].exists)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Three-child profile picker"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["Mia profile"].tap()
        XCTAssertTrue(app.staticTexts["Playing as Mia"].waitForExistence(timeout: 3))
    }

    func testCircuitChallengePrioritizesAdventure() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let hubTitle = app.staticTexts["Choose a Puzzle"]
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 3))

        let moduleCard = app.buttons["Circuit Challenge"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()

        XCTAssertTrue(app.buttons["Start Adventure"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Quick Play"].exists)
        XCTAssertTrue(app.staticTexts["Grown-ups"].exists)
    }

    func testHubShowsEveryGameEqually() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        let cometWriter = app.buttons["Comet Writer"]
        let starSpeller = app.buttons["Star Speller"]
        let dotToDot = app.buttons["Dot-to-Dot Discovery"]
        for module in [circuit, cometWriter, starSpeller, dotToDot] {
            XCTAssertTrue(module.waitForExistence(timeout: 3))
            XCTAssertTrue(module.isHittable, "Every game must be directly visible without swiping")
        }

        let circuitFrame = circuit.frame
        XCTAssertGreaterThanOrEqual(circuitFrame.width, 140)

        let dotFrame = dotToDot.frame
        // iOS 16's accessibility snapshot rounds otherwise equal grid-cell bounds by up to
        // two points when titles wrap differently. A three-point tolerance still catches a
        // materially promoted card while keeping the test stable across supported runtimes.
        XCTAssertEqual(dotFrame.width, circuitFrame.width, accuracy: 3)
        XCTAssertEqual(dotFrame.height, circuitFrame.height, accuracy: 3)

        XCTAssertEqual(starSpeller.frame.width, circuitFrame.width, accuracy: 3)
        XCTAssertEqual(starSpeller.frame.height, circuitFrame.height, accuracy: 3)

        XCTAssertEqual(cometWriter.frame.width, circuitFrame.width, accuracy: 3)
        XCTAssertEqual(cometWriter.frame.height, circuitFrame.height, accuracy: 3)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Equally prominent puzzle cards"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testDotToDotOffersTapAndTracePlayStyles() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let dotToDot = app.buttons["Dot-to-Dot Discovery"]
        revealModule(dotToDot, in: app)
        dotToDot.tap()

        XCTAssertTrue(app.otherElements["dot-to-dot-menu"].waitForExistence(timeout: 3))
        let tapMode = app.buttons["dot-mode-tap"]
        XCTAssertTrue(tapMode.exists)
        tapMode.tap()
        XCTAssertTrue(tapMode.isSelected)
        let traceMode = app.buttons["dot-mode-trace"]
        XCTAssertTrue(traceMode.exists)

        let firstAuthoredPuzzle = app.buttons["dot-puzzle-reference-d5-03-cherries"]
        for _ in 0..<4 where !firstAuthoredPuzzle.isHittable { app.swipeUp() }
        XCTAssertTrue(firstAuthoredPuzzle.isHittable)
        firstAuthoredPuzzle.tap()

        XCTAssertTrue(app.otherElements["dot-to-dot-game"].waitForExistence(timeout: 3))
        var first = app.buttons["dot-real-1"]
        var second = app.buttons["dot-real-2"]
        XCTAssertTrue(first.waitForExistence(timeout: 2))
        first.tap()
        second.tap()
        XCTAssertTrue(app.staticTexts["Find number 3"].waitForExistence(timeout: 2))

        app.buttons["Back to picture gallery"].tap()
        XCTAssertTrue(app.otherElements["dot-to-dot-menu"].waitForExistence(timeout: 3))
        traceMode.tap()
        XCTAssertTrue(traceMode.isSelected)
        XCTAssertTrue(firstAuthoredPuzzle.isHittable)
        firstAuthoredPuzzle.tap()

        XCTAssertTrue(app.otherElements["dot-to-dot-game"].waitForExistence(timeout: 3))
        first = app.buttons["dot-real-1"]
        second = app.buttons["dot-real-2"]
        XCTAssertTrue(first.waitForExistence(timeout: 2))
        first.tap()
        XCTAssertTrue(app.staticTexts["Trace to number 2"].waitForExistence(timeout: 2))

        second.tap()
        XCTAssertTrue(app.staticTexts["Start at 1, then draw to 2."].waitForExistence(timeout: 2))

        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(
                forDuration: 0.12,
                thenDragTo: second.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            )
        XCTAssertTrue(app.staticTexts["Trace to number 3"].waitForExistence(timeout: 2))
    }

    func testDotToDotRestartProtectsAndThenClearsProgress() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-app-store-screen", "dot-game-tap"]
        app.launch()

        XCTAssertTrue(app.otherElements["dot-to-dot-game"].waitForExistence(timeout: 4))
        let restart = app.buttons["Restart"]
        XCTAssertTrue(restart.waitForExistence(timeout: 4))
        restart.tap()

        let confirmation = app.alerts["Start this picture again?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 2))
        confirmation.buttons["Keep going"].tap()
        XCTAssertTrue(app.staticTexts["Find number 9"].waitForExistence(timeout: 2))

        restart.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 2))
        confirmation.buttons["Start again"].tap()
        XCTAssertTrue(app.staticTexts["Find number 1"].waitForExistence(timeout: 3))
    }

    func testDotToDotMenuKeepsControlsReadableAtAccessibilityXXXL() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-app-store-screen", "dot-menu",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["dot-to-dot-menu"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Close Dot-to-Dot"].isHittable)

        let title = app.staticTexts["dot-menu-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(title.frame.width, 180, "The title must use the full row, not fragment vertically")

        let progress = app.staticTexts["dot-menu-progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(progress.frame.width, progress.frame.height, "The progress digits must stay on one line")

        let scroll = app.descendants(matching: .any)["dot-menu-scroll"]
        let tapMode = app.buttons["dot-mode-tap"]
        let traceMode = app.buttons["dot-mode-trace"]
        for _ in 0..<4 where !tapMode.isHittable || !traceMode.isHittable {
            scroll.swipeUp()
        }
        XCTAssertTrue(tapMode.isHittable)
        XCTAssertTrue(traceMode.isHittable)

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Dot-to-Dot accessibility XXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testClosingSemanticColouringDoesNotCompletePicture() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-dot-preview-index", "0"]
        app.launch()

        let previewButton = app.buttons["dot-preview-open-colouring"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 4))
        previewButton.tap()

        XCTAssertTrue(app.otherElements["dot-colouring-stage"].waitForExistence(timeout: 6))
        app.buttons["dot-colouring-close"].tap()
        XCTAssertTrue(app.alerts["Leave colouring?"].waitForExistence(timeout: 2))
        app.alerts["Leave colouring?"].buttons["Leave for now"].tap()

        XCTAssertTrue(previewButton.waitForExistence(timeout: 4))
        XCTAssertFalse(app.otherElements["dot-to-dot-complete"].exists)
    }

    func testSemanticShadeGestureCommitsARealStroke() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-dot-preview-index", "0"]
        app.launch()

        let previewButton = app.buttons["dot-preview-open-colouring"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 4))
        previewButton.tap()
        XCTAssertTrue(app.otherElements["dot-colouring-stage"].waitForExistence(timeout: 6))

        let shadeMode = app.buttons["dot-colouring-mode-shade"]
        XCTAssertTrue(shadeMode.waitForExistence(timeout: 2))
        shadeMode.tap()
        app.buttons["dot-colouring-pot-1"].tap()

        let canvas = app.otherElements["dot-colouring-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 2))
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.64))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.53))
        start.press(forDuration: 0.08, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.05)

        XCTAssertTrue(
            app.buttons["dot-colouring-reset"].waitForExistence(timeout: 2),
            "A meaningful finger gesture inside the selected mask must commit a real stroke"
        )
    }

    func testSemanticColouringFinishesThenReturnsToMorePictures() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-dot-preview-index", "0"]
        app.launch()

        let previewButton = app.buttons["dot-preview-open-colouring"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 4))
        previewButton.tap()

        XCTAssertTrue(app.otherElements["dot-colouring-stage"].waitForExistence(timeout: 6))
        for region in 1...4 {
            let pot = app.buttons["dot-colouring-pot-\(region)"]
            XCTAssertTrue(pot.waitForExistence(timeout: 2), "Missing semantic colour pot \(region)")
            pot.tap()

            let target = app.buttons["dot-colouring-region-\(region)-0"]
            XCTAssertTrue(target.waitForExistence(timeout: 2), "Missing semantic region \(region)")
            target.tap()
        }

        let finish = app.buttons["dot-colouring-finish"]
        XCTAssertTrue(finish.isEnabled)
        finish.tap()

        let morePictures = app.buttons["More pictures"]
        XCTAssertTrue(morePictures.waitForExistence(timeout: 4))
        morePictures.tap()
        XCTAssertTrue(app.buttons["dot-preview-open-colouring"].waitForExistence(timeout: 3))
    }

    private func addProfile(named name: String, in app: XCUIApplication) {
        let addChild = app.buttons["add-player-profile"]
        XCTAssertTrue(addChild.waitForExistence(timeout: 3))
        addChild.tap()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText(name)

        let completedTyping = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", name),
            object: nameField
        )
        XCTAssertEqual(XCTWaiter.wait(for: [completedTyping], timeout: 2), .completed)

        let addProfile = app.buttons["Add profile"]
        XCTAssertTrue(addProfile.isEnabled)
        addProfile.tap()
    }

    private func revealModule(_ module: XCUIElement, in _: XCUIApplication) {
        XCTAssertTrue(module.waitForExistence(timeout: 3))
        XCTAssertTrue(module.isHittable, "The 2 by 2 game grid must expose every game directly")
    }

    func testQuickPlayStartsAtLevelOne() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        revealModule(circuit, in: app)
        circuit.tap()

        XCTAssertTrue(app.buttons["Quick Play"].waitForExistence(timeout: 2))
        app.buttons["Quick Play"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["Level 1: Tiny Tot"].waitForExistence(timeout: 2))
    }

    func testFirstPuzzleExplainsTheRule() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        revealModule(circuit, in: app)
        circuit.tap()
        XCTAssertTrue(app.buttons["Quick Play"].waitForExistence(timeout: 2))
        app.buttons["Quick Play"].tap()

        let startButton = app.buttons["Start Puzzle"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        XCTAssertTrue(app.staticTexts["How to play"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Let me try"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '1. Solve the glowing hex:'")).firstMatch.exists)
    }

    func testStoryConfirmationsAreAccessibilityModals() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        revealModule(circuit, in: app)
        circuit.tap()

        let adventure = app.buttons["Start Adventure"]
        XCTAssertTrue(adventure.waitForExistence(timeout: 3))
        adventure.tap()

        let bob = app.staticTexts["Bob"].firstMatch
        XCTAssertTrue(bob.waitForExistence(timeout: 4))
        bob.tap()

        let levelOne = app.buttons["Level 1"]
        XCTAssertTrue(levelOne.waitForExistence(timeout: 4))
        levelOne.tap()

        let finishTutorial = app.buttons["Let me try"]
        XCTAssertTrue(finishTutorial.waitForExistence(timeout: 10))
        let finishTutorialIsHittable = expectation(
            for: NSPredicate(format: "isHittable == true"),
            evaluatedWith: finishTutorial
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [finishTutorialIsHittable], timeout: 5),
            .completed
        )
        finishTutorial.tap()

        let newPuzzle = app.buttons["New puzzle"]
        let newPuzzleIsHittable = expectation(
            for: NSPredicate(format: "isHittable == true"),
            evaluatedWith: newPuzzle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [newPuzzleIsHittable], timeout: 5), .completed)
        newPuzzle.tap()

        let modal = app.descendants(matching: .any)["circuit-new-puzzle-confirmation"]
        XCTAssertTrue(modal.waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["circuit-new-puzzle-confirmation-title"].exists,
            "The modal heading must be exposed as its initial accessibility focus target"
        )
        XCTAssertTrue(app.buttons["Keep This One"].exists)
        XCTAssertTrue(app.buttons["Start New"].exists)
        assertElementLeavesAccessibilityTree(
            app.buttons["circuit-game-back"],
            message: "Gameplay header must leave the accessibility tree"
        )
        assertElementLeavesAccessibilityTree(
            app.buttons["New puzzle"],
            message: "The covered action must not remain reachable"
        )

        app.buttons["Keep This One"].tap()
        XCTAssertFalse(modal.exists)
        let back = app.buttons["circuit-game-back"]
        XCTAssertTrue(back.waitForExistence(timeout: 2))
        back.tap()

        let exitModal = app.descendants(matching: .any)["circuit-exit-confirmation"]
        XCTAssertTrue(exitModal.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["circuit-exit-confirmation-title"].exists)
        XCTAssertTrue(app.buttons["Continue Playing"].exists)
        XCTAssertTrue(app.buttons["Exit"].exists)
        assertElementLeavesAccessibilityTree(
            app.buttons["circuit-game-back"],
            message: "Exit confirmation must hide the covered header"
        )
        assertElementLeavesAccessibilityTree(
            app.buttons["New puzzle"],
            message: "Exit confirmation must hide game actions"
        )

        app.buttons["Continue Playing"].tap()
        XCTAssertFalse(exitModal.exists)
        XCTAssertTrue(app.buttons["circuit-game-back"].waitForExistence(timeout: 2))
    }

    func testCustomQuickPlayOffersExactTimesTableSelection() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        revealModule(circuit, in: app)
        circuit.tap()
        XCTAssertTrue(app.buttons["Quick Play"].waitForExistence(timeout: 2))
        app.buttons["Quick Play"].tap()

        let customToggle = app.switches["Customise Settings"]
        XCTAssertTrue(customToggle.waitForExistence(timeout: 3))
        customToggle.tap()

        let multiplyButton = app.buttons["×"]
        XCTAssertTrue(multiplyButton.waitForExistence(timeout: 2))
        multiplyButton.tap()

        let sevenTable = app.buttons["times-table-7"]
        for _ in 0..<3 where !sevenTable.isHittable { app.swipeUp() }
        XCTAssertTrue(sevenTable.waitForExistence(timeout: 2))
        XCTAssertTrue(sevenTable.isHittable)
        sevenTable.tap()
        XCTAssertTrue(sevenTable.isSelected)
    }

    func testCometWriterLaunchesGuidedLowercaseMission() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()

        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Write with your finger, or use a stylus if you have one."].exists)
        XCTAssertTrue(app.staticTexts["Ready for launch?"].exists)

        let continueButton = app.buttons["Start with c"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["c is for cat"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Restart"].exists)
        XCTAssertTrue(app.buttons["Show path"].exists)

        let prompt = app.staticTexts["c is for cat"]
        let restart = app.buttons["Restart"]
        let promptFrame = prompt.frame
        let restartFrame = restart.frame

        for _ in 0..<5 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            XCTAssertEqual(prompt.frame.minX, promptFrame.minX, accuracy: 0.5, "The writing screen must not zoom horizontally")
            XCTAssertEqual(prompt.frame.minY, promptFrame.minY, accuracy: 0.5, "The writing screen must not zoom vertically")
            XCTAssertEqual(prompt.frame.width, promptFrame.width, accuracy: 0.5, "The writing screen width must remain fixed")
            XCTAssertEqual(restart.frame, restartFrame, "Trace controls must remain completely still")
        }

        let showPath = app.buttons["Show path"]
        XCTAssertTrue(showPath.exists)
        showPath.tap()
        XCTAssertEqual(showPath.value as? String, "Playing")

        for _ in 0..<4 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.20))
            XCTAssertEqual(prompt.frame, promptFrame, "The path animation must not move the writing screen")
            XCTAssertEqual(restart.frame, restartFrame, "The path animation must not move trace controls")
        }

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "On-demand lowercase c formation animation"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let demonstrationFinished = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == 'Ready'"),
            object: showPath
        )
        XCTAssertEqual(XCTWaiter.wait(for: [demonstrationFinished], timeout: 4), .completed)
    }

    func testCometWriterWritingSurfaceStaysFixedInLandscape() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let continueButton = app.buttons["Start with c"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.tap()

        let prompt = app.staticTexts["c is for cat"]
        let restart = app.buttons["Restart"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3))
        XCTAssertTrue(restart.exists)

        let promptFrame = prompt.frame
        let restartFrame = restart.frame
        for _ in 0..<5 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            XCTAssertEqual(prompt.frame, promptFrame, "The landscape writing screen must not zoom")
            XCTAssertEqual(restart.frame, restartFrame, "Landscape trace controls must remain completely still")
        }

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Stable smoothed lowercase c landscape"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCometWriterMenuRemainsUsableAtAccessibilityXXXL() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-app-store-screen", "writer-menu",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 5))

        let close = app.buttons["Close Comet Writer"]
        XCTAssertTrue(close.waitForExistence(timeout: 2))
        XCTAssertTrue(close.isHittable)

        let progress = app.descendants(matching: .any)["comet-writer-progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 2))
        XCTAssertTrue(progress.label.contains("0 of 62"))
        XCTAssertGreaterThan(
            progress.frame.width,
            progress.frame.height,
            "The progress capsule must stay on one readable line"
        )
        XCTAssertTrue(app.staticTexts["Write with your finger, or use a stylus if you have one."].exists)

        let start = app.buttons["comet-writer-continue"]
        let choosePractice = app.buttons["comet-writer-quick-practice"]
        revealVertically(start, in: app)
        XCTAssertTrue(start.isHittable)
        revealVertically(choosePractice, in: app)
        XCTAssertTrue(choosePractice.isHittable)

        attachScreenshot(named: "Comet Writer accessibility XXXL menu", in: app)
    }

    func testCometWriterWritingToolsExposePencilLinesAndLetterSize() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))
        app.buttons["Start with c"].tap()

        let toolsButton = app.buttons["Tools"]
        XCTAssertTrue(toolsButton.waitForExistence(timeout: 3))
        toolsButton.tap()

        XCTAssertTrue(app.navigationBars["Writing tools"].waitForExistence(timeout: 3))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Comet Writer Apple Pencil and letter size controls"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let pencilToggle = app.switches["comet-writer-pencil-only"]
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(pencilToggle.exists)
            XCTAssertEqual(pencilToggle.value as? String, "0")
            pencilToggle.tap()
            XCTAssertEqual(pencilToggle.value as? String, "1")
            pencilToggle.tap()
        } else {
            XCTAssertFalse(
                pencilToggle.exists,
                "Apple Pencil controls should be hidden on iPhone, where Apple Pencil is unsupported"
            )
        }

        let writingLinesToggle = app.switches["comet-writer-writing-lines"]
        XCTAssertTrue(writingLinesToggle.exists)
        XCTAssertEqual(writingLinesToggle.value as? String, "1")
        writingLinesToggle.tap()
        XCTAssertEqual(writingLinesToggle.value as? String, "0")
        writingLinesToggle.tap()

        let sizeSlider = app.sliders["comet-writer-letter-size"]
        XCTAssertTrue(sizeSlider.exists)
        XCTAssertTrue(sizeSlider.isHittable, "Letter size should be immediately available when tools open")
        let initialSize = sizeSlider.value as? String
        sizeSlider.adjust(toNormalizedSliderPosition: 0.0)
        XCTAssertNotEqual(sizeSlider.value as? String, initialSize)

        let resetButton = app.buttons["comet-writer-letter-size-reset"]
        XCTAssertTrue(resetButton.exists)
        resetButton.tap()
        XCTAssertEqual(sizeSlider.value as? String, initialSize)

        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["c is for cat"].waitForExistence(timeout: 2))
        XCTAssertEqual(
            toolsButton.value as? String,
            UIDevice.current.userInterfaceIdiom == .pad ? "Finger or Apple Pencil" : "Finger drawing"
        )
    }

    func testNumberNebulaLaunchesZeroMission() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let morePractice = app.buttons["comet-writer-more-practice"]
        XCTAssertTrue(morePractice.waitForExistence(timeout: 2))
        morePractice.tap()

        let lettersAndNumbers = app.buttons["comet-writer-category-lettersAndNumbers"]
        revealVertically(lettersAndNumbers, in: app)
        lettersAndNumbers.tap()

        let numbers = app.buttons["comet-writer-family-numbers"]
        revealVertically(numbers, in: app)
        numbers.tap()

        let zeroMission = app.buttons["comet-writer-practice-0"]
        for _ in 0..<6 where !zeroMission.exists {
            app.swipeUp()
        }
        XCTAssertTrue(zeroMission.waitForExistence(timeout: 2))
        for _ in 0..<4 where !zeroMission.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(zeroMission.isHittable)
        zeroMission.tap()

        XCTAssertTrue(app.staticTexts["0 is zero"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Show path"].exists)
    }

    func testAdvancedRecallAndWordMissionsUseStartPointOnly() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let morePractice = app.buttons["comet-writer-more-practice"]
        XCTAssertTrue(morePractice.waitForExistence(timeout: 2))
        morePractice.tap()

        let soundAndWords = app.buttons["comet-writer-category-soundAndWords"]
        let menuScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(menuScrollView.waitForExistence(timeout: 2))
        let scrollMenuUp = {
            let start = menuScrollView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.82)
            )
            let end = menuScrollView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.18)
            )
            start.press(forDuration: 0.08, thenDragTo: end)
        }
        for _ in 0..<8 where !(soundAndWords.exists && soundAndWords.isHittable) {
            scrollMenuUp()
        }
        XCTAssertTrue(soundAndWords.exists)
        XCTAssertTrue(soundAndWords.isHittable)
        soundAndWords.tap()

        let recall = app.buttons["comet-writer-letter-recall"]
        for _ in 0..<5 where !recall.isHittable { scrollMenuUp() }
        XCTAssertTrue(recall.isHittable)
        recall.tap()

        XCTAssertTrue(app.staticTexts["Choose recall letters"].waitForExistence(timeout: 3))
        let selectionCount = app.staticTexts["comet-writer-recall-selection-count"]
        XCTAssertTrue(selectionCount.waitForExistence(timeout: 2))
        XCTAssertEqual(selectionCount.label, "26 of 26 selected")

        let aButton = app.buttons["recall-letter-a"]
        let zButton = app.buttons["recall-letter-z"]
        XCTAssertTrue(aButton.isSelected)
        XCTAssertTrue(zButton.isSelected)

        let pickerScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        pickerScreenshot.name = "Letter Recall defaults to all letters"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)

        let toggleAll = app.buttons["comet-writer-recall-toggle-all"]
        XCTAssertEqual(toggleAll.label, "Clear all")
        toggleAll.tap()
        XCTAssertEqual(selectionCount.label, "0 of 26 selected")

        let startRecall = app.buttons["comet-writer-start-recall"]
        XCTAssertFalse(startRecall.isEnabled)

        let gButton = app.buttons["recall-letter-g"]
        gButton.tap()
        XCTAssertTrue(gButton.isSelected)
        XCTAssertEqual(selectionCount.label, "1 of 26 selected")
        XCTAssertTrue(startRecall.isEnabled)
        startRecall.tap()

        let advancedGame = app.descendants(matching: .any)["comet-writer-advanced-game"]
        XCTAssertTrue(advancedGame.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Letter Recall"].exists)
        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", "start star only")
            ).firstMatch.exists
        )
        XCTAssertTrue(app.staticTexts["Write this letter"].exists)
        XCTAssertFalse(app.buttons["Show path"].exists)
        XCTAssertTrue(app.buttons["Restart"].isHittable)
        XCTAssertTrue(app.buttons["Hear"].isHittable)

        app.buttons["Hear it"].tap()
        XCTAssertTrue(app.staticTexts["Listen, then write"].exists)
        XCTAssertTrue(app.staticTexts["?"].exists)

        let recallScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        recallScreenshot.name = "Advanced letter recall with start point only"
        recallScreenshot.lifetime = .keepAlways
        add(recallScreenshot)

        app.buttons["Back to writing missions"].tap()
        let leaveMission = app.buttons["Leave mission"]
        if leaveMission.waitForExistence(timeout: 1) {
            leaveMission.tap()
        }
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let wordMission = app.buttons["comet-writer-word-writing"]
        if !wordMission.exists {
            let morePractice = app.buttons["comet-writer-more-practice"]
            XCTAssertTrue(morePractice.waitForExistence(timeout: 2))
            morePractice.tap()
            let soundAndWords = app.buttons["comet-writer-category-soundAndWords"]
            for _ in 0..<8 where !(soundAndWords.exists && soundAndWords.isHittable) {
                scrollMenuUp()
            }
            XCTAssertTrue(soundAndWords.exists)
            XCTAssertTrue(soundAndWords.isHittable)
            soundAndWords.tap()
        }
        // SwiftUI can report a clipped card as hittable and then resolve its hit point onto the
        // visible hero button above it. Require the entire Word Mission card to be on-screen.
        for _ in 0..<4 {
            let frame = wordMission.frame
            if wordMission.exists,
               frame.minY >= 70,
               frame.maxY <= app.frame.maxY - 20 {
                break
            }
            scrollMenuUp()
        }
        XCTAssertLessThanOrEqual(wordMission.frame.maxY, app.frame.maxY - 20)
        XCTAssertTrue(wordMission.isHittable)
        wordMission.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(app.staticTexts["Word Mission"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Write the word"].exists)
        XCTAssertFalse(app.buttons["Show path"].exists)
        let cometExample = app.buttons["comet-writer-show-comet-example"]
        XCTAssertTrue(cometExample.waitForExistence(timeout: 2))
        XCTAssertTrue(cometExample.isHittable)
        XCTAssertTrue(app.buttons["Restart"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Restart"].isHittable)
        XCTAssertTrue(app.buttons["Tools"].isHittable)

        let wordSurface = app.descendants(matching: .any)["comet-writer-word-trace-pad"]
        XCTAssertTrue(wordSurface.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(
            wordSurface.frame.width,
            wordSurface.frame.height * 2,
            "Word Mission should keep the entire word on one horizontal writing surface"
        )

        let wordScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        wordScreenshot.name = "Advanced common-word mission"
        wordScreenshot.lifetime = .keepAlways
        add(wordScreenshot)
    }

    func testChooseAWordRejectsOverlengthInputThenWritesTheExactEnteredWord() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-skip-onboarding",
            "-ui-testing-disable-voice"
        ]
        app.launch()

        let moduleCard = app.buttons["Comet Writer"]
        revealModule(moduleCard, in: app)
        moduleCard.tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let morePractice = app.buttons["comet-writer-more-practice"]
        XCTAssertTrue(morePractice.waitForExistence(timeout: 2))
        morePractice.tap()

        let soundAndWords = app.buttons["comet-writer-category-soundAndWords"]
        let menuScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(menuScrollView.waitForExistence(timeout: 2))
        let scrollMenuUp = {
            let start = menuScrollView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.82)
            )
            let end = menuScrollView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.18)
            )
            start.press(forDuration: 0.08, thenDragTo: end)
        }
        for _ in 0..<8 where !(soundAndWords.exists && soundAndWords.isHittable) {
            scrollMenuUp()
        }
        XCTAssertTrue(soundAndWords.exists)
        XCTAssertTrue(soundAndWords.isHittable)
        soundAndWords.tap()

        let chooseWord = app.buttons["comet-writer-choose-word"]
        for _ in 0..<5 {
            let frame = chooseWord.frame
            if chooseWord.exists,
               frame.minY >= 70,
               frame.maxY <= app.frame.maxY - 20 {
                break
            }
            scrollMenuUp()
        }
        XCTAssertTrue(chooseWord.exists)
        XCTAssertLessThanOrEqual(chooseWord.frame.maxY, app.frame.maxY - 20)
        XCTAssertTrue(chooseWord.isHittable)
        chooseWord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let entrySheet = app.descendants(matching: .any)["comet-writer-word-entry-sheet"]
        XCTAssertTrue(entrySheet.waitForExistence(timeout: 3))

        let wordField = app.textFields["comet-writer-word-entry-field"]
        XCTAssertTrue(wordField.waitForExistence(timeout: 2))
        wordField.tap()
        wordField.typeText("abcdefghijk")

        let overlengthValue = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "abcdefghijk"),
            object: wordField
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [overlengthValue], timeout: 2),
            .completed,
            "An overlength word must remain visible so the parent can correct it; it must not be silently truncated"
        )

        let validationError = app.descendants(matching: .any)["comet-writer-word-entry-error"]
        XCTAssertTrue(validationError.waitForExistence(timeout: 2))
        let startWriting = app.buttons["comet-writer-start-chosen-word"]
        XCTAssertTrue(startWriting.waitForExistence(timeout: 2))
        XCTAssertFalse(startWriting.isEnabled)
        attachScreenshot(named: "Comet Writer custom word validation", in: app)

        replaceText(in: wordField, with: "Max", app: app)
        let exactValue = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Max"),
            object: wordField
        )
        XCTAssertEqual(XCTWaiter.wait(for: [exactValue], timeout: 2), .completed)
        assertElementLeavesAccessibilityTree(
            validationError,
            message: "Correcting the word should clear the validation error"
        )
        XCTAssertTrue(startWriting.isEnabled)
        XCTAssertTrue(startWriting.isHittable)
        startWriting.tap()

        let advancedGame = app.descendants(matching: .any)["comet-writer-advanced-game"]
        XCTAssertTrue(advancedGame.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Word Mission"].exists)

        let wordPrompt = app.otherElements["comet-writer-word-prompt"]
        XCTAssertTrue(wordPrompt.waitForExistence(timeout: 3))
        XCTAssertTrue(wordPrompt.label.contains("Max"))
        XCTAssertTrue(wordPrompt.label.contains("letter 1 of 3"))
        XCTAssertTrue(wordPrompt.label.contains("M"))

        let wordSurface = app.descendants(matching: .any)["comet-writer-word-trace-pad"]
        XCTAssertTrue(wordSurface.waitForExistence(timeout: 2))
        XCTAssertEqual(wordSurface.label, "Writing surface for the word Max")
        XCTAssertTrue(app.buttons["comet-writer-show-comet-example"].isHittable)
        attachScreenshot(named: "Comet Writer chosen word mission", in: app)
    }

    func testStarSpellerPutsPracticeBeforeProgressiveHelp() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-use-silent-spelling-audio",
            "-star-speller-test-menu"
        ]
        app.launch()

        XCTAssertTrue(app.otherElements["star-speller-menu"].waitForExistence(timeout: 4))
        let start = app.buttons["star-speller-start"]
        let howToPlay = app.buttons["star-speller-how-to-toggle"]
        XCTAssertTrue(start.waitForExistence(timeout: 3))
        XCTAssertTrue(start.isHittable, "The default spelling mission must be immediately startable")
        XCTAssertTrue(howToPlay.exists)
        XCTAssertLessThan(
            start.frame.minY,
            howToPlay.frame.minY,
            "Practice and its primary Start action must come before the tutorial"
        )
        XCTAssertEqual(howToPlay.value as? String, "Expanded")

        attachScreenshot(named: "Star Speller launch-first menu", in: app)
    }

    func testStarSpellerWrongHintCaseInsensitiveCorrectAndHandwritingHandoff() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-use-silent-spelling-audio",
            "-star-speller-test-word", "Monday"
        ]
        app.launch()

        let input = app.textFields["star-speller-word-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        revealVertically(input, in: app)

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(input.waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.descendants(matching: .any)["star-speller-game"].waitForExistence(timeout: 3)
        )
        XCUIDevice.shared.orientation = .portrait
        revealVertically(input, in: app)

        input.tap()
        input.typeText("x")
        submitSpelling(in: app)
        let feedback = app.descendants(matching: .any)["star-speller-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 3))
        XCTAssertTrue(feedback.label.contains("Almost"))

        replaceText(in: input, with: "", app: app)
        let hint = app.buttons["star-speller-hint"]
        revealVertically(hint, in: app)
        hint.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["star-speller-hint-keyboard"]
                .waitForExistence(timeout: 3)
        )
        let mKey = app.buttons["Letter M"]
        XCTAssertTrue(mKey.waitForExistence(timeout: 2))
        mKey.tap()

        // Start a clean attempt for the acceptance/handoff half of the journey. Keeping the
        // two checks in one test still exercises the real wrong-answer and hint flow first,
        // while avoiding a simulator keyboard-focus race as SwiftUI swaps the reduced keyboard.
        app.terminate()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-use-silent-spelling-audio",
            "-star-speller-test-word", "Monday"
        ]
        app.launch()

        let freshInput = app.textFields["star-speller-word-input"]
        XCTAssertTrue(freshInput.waitForExistence(timeout: 5))
        revealVertically(freshInput, in: app)
        freshInput.tap()
        freshInput.typeText("monday")
        submitSpelling(in: app)

        let handwrite = app.buttons["star-speller-open-handwriting"]
        XCTAssertTrue(handwrite.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["MONDAY"].exists)
        XCTAssertFalse(app.staticTexts["Monday"].exists)
        handwrite.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["comet-writer-advanced-game"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(app.buttons["Hear the word Monday"].exists)
        attachScreenshot(named: "Star Speller Monday handwriting handoff", in: app)
    }

    func testStarSpellerResumeSurvivesRelaunchAndCollapsesHelpAfterFirstUse() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-use-silent-spelling-audio",
            "-star-speller-test-menu"
        ]
        app.launch()

        let start = app.buttons["star-speller-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        start.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["star-speller-game"]
                .waitForExistence(timeout: 4)
        )

        app.buttons["Back to Star Speller"].tap()
        let leave = app.alerts["Leave spelling mission?"].buttons["Leave mission"]
        XCTAssertTrue(leave.waitForExistence(timeout: 3))
        leave.tap()
        XCTAssertTrue(app.buttons["star-speller-resume"].waitForExistence(timeout: 4))

        app.terminate()
        app.launchArguments = [
            "-ui-testing-preserve-state",
            "-ui-testing-use-silent-spelling-audio",
            "-star-speller-test-menu"
        ]
        app.launch()

        let resume = app.buttons["star-speller-resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 4))
        let help = app.buttons["star-speller-how-to-toggle"]
        XCTAssertTrue(help.exists)
        XCTAssertEqual(help.value as? String, "Collapsed")
        XCTAssertLessThan(resume.frame.minY, help.frame.minY)
        resume.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["star-speller-game"]
                .waitForExistence(timeout: 4)
        )
    }

    func testStarSpellerVoiceDisabledAndPlaybackFailureHaveRecoveryActions() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-disable-voice",
            "-star-speller-test-menu"
        ]
        app.launch()

        let start = app.buttons["star-speller-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        XCTAssertFalse(start.isEnabled)
        let enableVoice = app.buttons["star-speller-enable-voice"]
        XCTAssertTrue(enableVoice.waitForExistence(timeout: 2))
        enableVoice.tap()
        XCTAssertTrue(start.isEnabled)

        app.terminate()
        app.launchArguments = [
            "-ui-testing-reset",
            "-ui-testing-force-spelling-audio-failure",
            "-star-speller-test-word", "off"
        ]
        app.launch()

        let audioError = app.staticTexts["star-speller-audio-error"]
        XCTAssertTrue(audioError.waitForExistence(timeout: 5))
        XCTAssertTrue(audioError.label.contains("could not play"))
        let retry = app.buttons["star-speller-audio-retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 2))
        retry.tap()
        XCTAssertTrue(audioError.waitForExistence(timeout: 2))
        attachScreenshot(named: "Star Speller audio retry state", in: app)
    }

    func testCometWriterAcceptsRealFingerDragAndStaysResponsiveAcrossRotationAndRelaunch() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-app-store-screen", "guided-c"
        ]
        app.launch()

        let pad = app.descendants(matching: .any)["comet-writer-trace-pad"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5))
        let frame = pad.frame
        XCTAssertGreaterThan(frame.width, 180)
        XCTAssertGreaterThan(frame.height, 180)

        // Follow the beginning of the authored c arc. The gesture intentionally ends early: an
        // incomplete-stroke correction proves UIKit touch capture delivered a genuine continuous
        // finger drag through the production validator, rather than merely finding the view.
        let pointsPerModelUnit = (frame.height - 48) / 1.08
        func coordinate(modelX: CGFloat, modelY: CGFloat) -> XCUICoordinate {
            let localX = frame.width / 2 + (modelX - 0.5) * pointsPerModelUnit
            let localY = 24 + modelY * pointsPerModelUnit
            return app.coordinate(
                withNormalizedOffset: CGVector(
                    dx: (frame.minX + localX) / app.frame.width,
                    dy: (frame.minY + localY) / app.frame.height
                )
            )
        }
        let start = coordinate(modelX: 0.665, modelY: 0.437)
        let earlyArc = coordinate(modelX: 0.510, modelY: 0.335)
        start.press(forDuration: 0.12, thenDragTo: earlyArc)

        XCTAssertFalse(app.staticTexts["Start at the green star."].exists)
        XCTAssertTrue(app.buttons["Restart"].isHittable)
        XCTAssertTrue(app.buttons["Show path"].isHittable)

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(pad.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Restart"].isHittable)
        attachScreenshot(named: "Comet Writer real drag in landscape", in: app)

        app.terminate()
        app.launchArguments = [
            "-ui-testing-preserve-state",
            "-app-store-screen", "guided-c"
        ]
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any)["comet-writer-trace-pad"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["Restart"].isHittable)
    }

    private func assertElementLeavesAccessibilityTree(
        _ element: XCUIElement,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let hidden = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [hidden], timeout: 2),
            .completed,
            message,
            file: file,
            line: line
        )
    }

    private func revealVertically(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
    }

    private func replaceText(in field: XCUIElement, with replacement: String, app: XCUIApplication) {
        field.tap()
        let current = (field.value as? String) ?? ""
        if !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        if !replacement.isEmpty {
            field.typeText(replacement)
        }
    }

    private func submitSpelling(in app: XCUIApplication) {
        let done = app.keyboards.buttons["done"]
        if done.waitForExistence(timeout: 1), done.isHittable {
            done.tap()
            return
        }
        let check = app.buttons["star-speller-check-word"]
        revealVertically(check, in: app)
        check.tap()
    }

    private func attachScreenshot(named name: String, in app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
