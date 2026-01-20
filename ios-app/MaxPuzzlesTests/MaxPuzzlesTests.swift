import XCTest
@testable import MaxPuzzles

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
        XCTAssertNil(appState.currentUser, "No user should be set initially")
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
}
