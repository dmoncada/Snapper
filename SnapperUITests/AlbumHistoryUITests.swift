import XCTest

final class AlbumHistoryUITests: XCTestCase {
  @MainActor
  func testSelectCancelAndDeleteOneAlbum() throws {
    let app = XCUIApplication()
    app.launchArguments.append("-ui-testing-seed-albums")
    app.launch()

    let historyTab = app.tabBars.buttons["History"]
    XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
    historyTab.tap()

    let deletedAlbum = app.staticTexts["Kiss All The Time. Disco, Occasionally."]
    let retainedAlbum = app.staticTexts["Harry’s House"]
    XCTAssertTrue(deletedAlbum.waitForExistence(timeout: 10))
    XCTAssertTrue(retainedAlbum.exists)

    app.buttons["Select"].tap()
    deletedAlbum.tap()
    app.buttons["history-cancel-selection"].tap()
    XCTAssertTrue(deletedAlbum.exists)

    app.buttons["Select"].tap()
    deletedAlbum.tap()
    app.buttons["history-delete-selection"].tap()

    let confirmation = app.alerts["Delete Albums?"]
    XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
    confirmation.buttons["Delete"].tap()

    XCTAssertFalse(deletedAlbum.waitForExistence(timeout: 2))
    XCTAssertTrue(retainedAlbum.exists)
  }
}
