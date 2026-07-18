import XCTest

final class MaxPuzzlesUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Choose a Puzzle"].waitForExistence(timeout: 5),
            "A music-enabled launch must fail open to the usable hub"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// Shipping launch performance is measured independently from the four visual launch
/// configurations above. Keeping music enabled makes this a regression test for the historical
/// scene-create watchdog rather than a synthetic silent launch.
final class MaxPuzzlesLaunchPerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testColdLaunchPerformanceWithMusicEnabled() {
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            let app = XCUIApplication()
            app.launchArguments = ["-ui-testing-reset", "-ui-testing-skip-onboarding"]
            app.launch()
        }
    }
}
