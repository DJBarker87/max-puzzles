import XCTest
import UIKit

final class MaxPuzzlesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFreshLaunchCompletesPrivateNameSetup() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset"]
        app.launch()

        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: nameField
        )
        XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 3), .completed)
        nameField.tap()
        nameField.typeText("Max")

        let playButton = app.buttons["Let's Play!"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2))
        playButton.tap()

        XCTAssertTrue(app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 3))
    }

    func testCircuitChallengePrioritizesAdventure() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let hubTitle = app.staticTexts["Choose a Puzzle"]
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 3))

        let moduleCard = app.buttons["Circuit Challenge"]
        XCTAssertTrue(moduleCard.waitForExistence(timeout: 2))
        moduleCard.tap()

        XCTAssertTrue(app.buttons["Start Adventure"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Quick Play"].exists)
        XCTAssertTrue(app.staticTexts["Grown-ups"].exists)
    }

    func testHubShowsBothGamesEqually() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        let circuit = app.buttons["Circuit Challenge"]
        let cometWriter = app.buttons["Comet Writer"]
        XCTAssertTrue(circuit.waitForExistence(timeout: 3))
        XCTAssertTrue(cometWriter.waitForExistence(timeout: 3))
        XCTAssertTrue(circuit.isHittable)
        XCTAssertTrue(cometWriter.isHittable)

        let circuitFrame = circuit.frame
        let cometFrame = cometWriter.frame
        let screenFrame = app.frame

        XCTAssertEqual(circuitFrame.width, cometFrame.width, accuracy: 1)
        XCTAssertEqual(circuitFrame.height, cometFrame.height, accuracy: 1)
        XCTAssertEqual(circuitFrame.midY, cometFrame.midY, accuracy: 1)
        XCTAssertGreaterThanOrEqual(circuitFrame.width, 140)
        XCTAssertGreaterThanOrEqual(cometFrame.maxX - circuitFrame.maxX, 12)
        XCTAssertGreaterThanOrEqual(circuitFrame.minX, screenFrame.minX)
        XCTAssertLessThanOrEqual(cometFrame.maxX, screenFrame.maxX)
        XCTAssertEqual(
            circuitFrame.minX - screenFrame.minX,
            screenFrame.maxX - cometFrame.maxX,
            accuracy: 2
        )

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Two equally prominent puzzle cards"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testQuickPlayStartsAtLevelOne() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["Circuit Challenge"].waitForExistence(timeout: 3))
        app.buttons["Circuit Challenge"].tap()

        XCTAssertTrue(app.buttons["Quick Play"].waitForExistence(timeout: 2))
        app.buttons["Quick Play"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["Level 1: Tiny Tot"].waitForExistence(timeout: 2))
    }

    func testFirstPuzzleExplainsTheRule() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["Circuit Challenge"].waitForExistence(timeout: 3))
        app.buttons["Circuit Challenge"].tap()
        XCTAssertTrue(app.buttons["Quick Play"].waitForExistence(timeout: 2))
        app.buttons["Quick Play"].tap()

        let startButton = app.buttons["Start Puzzle"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        XCTAssertTrue(app.staticTexts["How to play"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Let me try"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '1. Solve the glowing hex:'")).firstMatch.exists)
    }

    func testCustomQuickPlayOffersExactTimesTableSelection() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["Circuit Challenge"].waitForExistence(timeout: 3))
        app.buttons["Circuit Challenge"].tap()
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
        XCTAssertTrue(moduleCard.waitForExistence(timeout: 4))
        moduleCard.tap()

        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Letter and number missions"].exists)

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

        XCTAssertTrue(app.buttons["Comet Writer"].waitForExistence(timeout: 4))
        app.buttons["Comet Writer"].tap()
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

    func testCometWriterWritingToolsExposePencilLinesAndLetterSize() throws {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(app.buttons["Comet Writer"].waitForExistence(timeout: 4))
        app.buttons["Comet Writer"].tap()
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

        XCTAssertTrue(app.buttons["Comet Writer"].waitForExistence(timeout: 4))
        app.buttons["Comet Writer"].tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

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

        XCTAssertTrue(app.buttons["Comet Writer"].waitForExistence(timeout: 4))
        app.buttons["Comet Writer"].tap()
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let recall = app.buttons["comet-writer-letter-recall"]
        for _ in 0..<3 where !recall.isHittable { app.swipeUp() }
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
        XCTAssertTrue(app.otherElements["comet-writer-menu"].waitForExistence(timeout: 3))

        let wordMission = app.buttons["comet-writer-word-writing"]
        for _ in 0..<3 where !wordMission.isHittable { app.swipeUp() }
        XCTAssertTrue(wordMission.isHittable)
        wordMission.tap()

        XCTAssertTrue(app.staticTexts["Word Mission"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Write the word"].exists)
        XCTAssertFalse(app.buttons["Show path"].exists)
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
}
