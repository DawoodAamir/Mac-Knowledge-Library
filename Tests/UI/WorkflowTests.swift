import XCTest

@MainActor final class WorkflowTests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }
  func testSearchAndArchiveSource() throws {
    let app = XCUIApplication()
    app.launchEnvironment["LIBRARY_TEST_STORE"] = UUID().uuidString
    app.launch()
    app.menuBars.menuBarItems["Library"].click()
    app.menuItems["Load sample document"].click()
    XCTAssertTrue(
      app.descendants(matching: .any)
        .matching(NSPredicate(format: "identifier BEGINSWITH %@", "library-document-"))
        .firstMatch.waitForExistence(timeout: 15), app.debugDescription)
    let question =
      app.textFields["question"].exists ? app.textFields["question"] : app.textViews["question"]
    question.click()
    question.typeText("artwork handover")
    app.buttons["Find passages"].click()
    XCTAssertTrue(app.staticTexts["Source passages"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["Sample: Studio handover · page 1"].waitForExistence(timeout: 10))
    app.buttons["Sample: Studio handover · page 1"].click()
    XCTAssertTrue(app.buttons["Archive document"].waitForExistence(timeout: 10))
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Source passages"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    app.buttons["Archive document"].click()
    XCTAssertTrue(
      app.staticTexts["Source passages"].waitForNonExistence(timeout: 10), app.debugDescription)
    app.terminate()
    app.launch()
    question.click()
    question.typeText("artwork handover")
    app.buttons["Find passages"].click()
    XCTAssertTrue(
      app.staticTexts["Source passages"].waitForNonExistence(timeout: 10), app.debugDescription)
  }
}
