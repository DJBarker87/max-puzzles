import XCTest

final class MaxPuzzlesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here
    }

    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify splash screen shows app name
        XCTAssertTrue(app.staticTexts["Maxi's Mighty\nMindgames"].exists || app.staticTexts["Maxi's Mindgames"].waitForExistence(timeout: 3))
    }

    func testNavigateToCircuitChallenge() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for splash to finish
        let hubTitle = app.staticTexts["Choose a Puzzle"]
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 5))

        // Tap Circuit Challenge module
        let moduleCard = app.buttons["Circuit Challenge"]
        if moduleCard.exists {
            moduleCard.tap()
        }
    }
}
