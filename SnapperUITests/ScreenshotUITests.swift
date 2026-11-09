import XCTest

@MainActor
final class ScreenshotUITests: XCTestCase {
  func testScreenshots() {
    let app = XCUIApplication()
    setupSnapshot(app)
    app.launchArguments.append(contentsOf: [
      "-screenshot-fixtures", "-colorSchemePreference", "system",
    ])
    app.launchEnvironment["TZ"] = "UTC"
    app.launch()

    let searchField = app.textFields["album-search-field"]
    XCTAssertTrue(searchField.waitForExistence(timeout: 30))
    searchField.tap()
    searchField.typeText("Natalia\n")
    XCTAssertTrue(app.staticTexts["Natalia Lafourcade"].firstMatch.waitForExistence(timeout: 20))
    snapshot("01-search", timeWaitingForIdle: 0)

    app.buttons["History"].tap()
    let latestAlbum = app.staticTexts["The Womack Sisters"].firstMatch
    XCTAssertTrue(latestAlbum.waitForExistence(timeout: 20))
    snapshot("02-history", timeWaitingForIdle: 0)

    latestAlbum.tap()
    XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.staticTexts["Tracks"].waitForExistence(timeout: 20))
    snapshot("03-detail", timeWaitingForIdle: 0)
  }
}
