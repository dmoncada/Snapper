import XCTest

@MainActor
final class ScreenshotUITests: XCTestCase {
  func testScreenshots() {
    continueAfterFailure = false

    let app = XCUIApplication()
    setupSnapshot(app)
    app.launchArguments.append(contentsOf: [
      AppLaunchConfiguration.uiTest, "-colorSchemePreference", "system",
    ])
    app.launchEnvironment["TZ"] = "America/Los_Angeles"
    app.launch()

    let searchField = app.textFields["album-search-field"]
    XCTAssertTrue(searchField.waitForExistence(timeout: 30))
    searchField.tap()
    searchField.typeText("natalia macorinos")
    XCTAssertTrue(app.staticTexts["Natalia Lafourcade"].firstMatch.waitForExistence(timeout: 20))
    if app.keyboards.firstMatch.exists {
      searchField.typeText("\n")
    }
    capture("01-search")

    app.buttons["History"].tap()
    let latestAlbum =
      app.staticTexts[
        "Musas (Un Homenaje al Folclore Latinoamericano en Manos de Los Macorinos), Vol. 2"
      ]
      .firstMatch
    XCTAssertTrue(latestAlbum.waitForExistence(timeout: 20))
    capture("02-history")

    latestAlbum.tap()
    XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.staticTexts["Tracks"].waitForExistence(timeout: 20))
    capture("03-detail")

    captureSpatial(in: app)
  }

  private func captureSpatial(in app: XCUIApplication) {
    app.buttons["Spatial"].tap()
    XCTAssertTrue(app.buttons["10"].waitForExistence(timeout: 15), app.debugDescription)
    let zoomPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.60))
    zoomPoint.doubleTap()

    let sixAlbums = app.buttons["6"]
    let fourAlbums = app.buttons["4"]
    XCTAssertTrue(sixAlbums.waitForExistence(timeout: 10), app.debugDescription)
    XCTAssertTrue(fourAlbums.waitForExistence(timeout: 10), app.debugDescription)

    // Frame both clusters above the sheet before opening it.
    let viewport = app.frame
    let sixFrame = sixAlbums.frame
    let fourFrame = fourAlbums.frame
    XCTAssertGreaterThan(fourFrame.midX, sixFrame.midX)
    let clusterCenterX = (sixFrame.midX + fourFrame.midX) / 2
    let clusterCenterY = (sixFrame.midY + fourFrame.midY) / 2
    let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.58))
    let end = start.withOffset(
      CGVector(
        dx: viewport.minX + viewport.width * 0.30 - clusterCenterX,
        dy: viewport.minY + viewport.height * 0.32 - clusterCenterY,
      )
    )
    start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)

    XCTAssertTrue(sixAlbums.isHittable)
    XCTAssertTrue(fourAlbums.isHittable)
    fourAlbums.tap()
    XCTAssertTrue(app.staticTexts["4 albums"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Ladytron"].firstMatch.isHittable)
    capture("04-spatial")
  }

  private func capture(_ name: String) {
    snapshot(name, timeWaitingForIdle: 0)
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
