import XCTest

final class DoodleUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["JUST_DOODLE_TEST_ID"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["startClassic"].waitForExistence(timeout: 10))
    }

    private func startClassic() {
        app.buttons["startClassic"].tap()
        XCTAssertTrue(app.buttons["finishDrawing"].waitForExistence(timeout: 5))
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: app.buttons["finishDrawing"])
        waitForExpectations(timeout: 5)
    }

    private func draw() {
        let canvas = app.descendants(matching: .any)["drawingCanvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        XCTAssertEqual(canvas.frame.width / canvas.frame.height, 0.75, accuracy: 0.01)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(canvas.frame))
        XCTAssertEqual(app.staticTexts["roundTimer"].frame.midX, app.windows.firstMatch.frame.midX, accuracy: 2)
        let from = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.45))
        let to = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.65))
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    private func screenshot(_ name: String) {
        // Capture settled ink, rather than the middle of a screen fade.
        Thread.sleep(forTimeInterval: 0.35)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testClassicFinishAndDeleteFromBook() {
        screenshot("Home")
        startClassic()
        draw()
        screenshot("Classic Drawing")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.staticTexts["resultStatus"].waitForExistence(timeout: 5))
        let saved = NSPredicate(format: "label == 'Saved.'")
        expectation(for: saved, evaluatedWith: app.staticTexts["resultStatus"])
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.images["finishedImage"].exists)
        screenshot("Finished Drawing")
        app.buttons["backHome"].tap()
        app.buttons["doodleBook"].tap()
        let record = app.buttons["archiveDrawing"].firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        screenshot("Doodle Book")
        record.tap()
        app.buttons["deleteDrawing"].tap()
        app.buttons["Delete drawing"].tap()
        XCTAssertTrue(app.staticTexts["Nothing here yet."].waitForExistence(timeout: 5))
    }

    func testChallengePaletteAndRepeatedIdeas() {
        app.buttons["challenges"].tap()
        screenshot("Challenges")
        app.buttons["challenge-build-it"].tap()
        XCTAssertTrue(app.buttons["ink-blue"].waitForExistence(timeout: 5))
        app.buttons["ink-blue"].tap()
        XCTAssertFalse(app.buttons["ink-red"].exists)
        let idea = app.buttons["ideaBox"]
        idea.tap()
        let first = idea.value as? String
        idea.tap()
        XCTAssertNotEqual(first, idea.value as? String)
        draw()
        screenshot("Build It Challenge")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
    }

    func testDraftSurvivesTermination() {
        startClassic()
        draw()
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["resumeDrawing"].waitForExistence(timeout: 10))
        app.buttons["resumeDrawing"].tap()
        XCTAssertTrue(app.buttons["finishDrawing"].waitForExistence(timeout: 5))
        screenshot("Recovered Drawing")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
    }

    func testLeaveCancelKeepsDrawing() {
        startClassic()
        draw()
        app.buttons["leaveDrawing"].tap()
        app.buttons["Keep drawing"].tap()
        XCTAssertTrue(app.buttons["finishDrawing"].isEnabled)
        app.buttons["leaveDrawing"].tap()
        app.buttons["Discard drawing"].tap()
        XCTAssertTrue(app.buttons["startClassic"].waitForExistence(timeout: 5))
    }

    func testSettingsAndPrivacy() {
        app.buttons["settings"].tap()
        XCTAssertTrue(app.switches["hapticsToggle"].waitForExistence(timeout: 5))
        app.switches["hapticsToggle"].tap()
        app.buttons["Privacy policy"].tap()
        XCTAssertTrue(app.staticTexts["Your drawings belong to you."].waitForExistence(timeout: 5))
        screenshot("Privacy Policy")
    }

    func testShareSheetOpensAndDismisses() {
        startClassic()
        draw()
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.buttons["shareDrawing"].waitForExistence(timeout: 10))
        app.buttons["shareDrawing"].tap()
        let close = app.buttons.matching(NSPredicate(format: "label ==[c] 'close'")).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        screenshot("Share Drawing")
        close.tap()
        XCTAssertTrue(app.buttons["backHome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["backHome"].isHittable)
    }

    private func exportWithPhotosPermission(allow: Bool) {
        app.resetAuthorizationStatus(for: .photos)
        app.launch()
        XCTAssertTrue(app.buttons["startClassic"].waitForExistence(timeout: 10))
        startClassic()
        draw()
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.buttons["saveToPhotos"].waitForExistence(timeout: 10))
        app.buttons["saveToPhotos"].tap()
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        XCTAssertTrue(permission.waitForExistence(timeout: 10))
        let predicate = allow
            ? NSPredicate(format: "label CONTAINS[c] 'Add' OR label == 'Allow' OR label == 'OK'")
            : NSPredicate(format: "label BEGINSWITH[c] 'Don'")
        let response = permission.buttons.matching(predicate).firstMatch
        XCTAssertTrue(response.exists, permission.debugDescription)
        response.tap()
    }

    func testPhotosExportAllowed() {
        exportWithPhotosPermission(allow: true)
        XCTAssertTrue(app.alerts.staticTexts["Your drawing is now in Photos."].waitForExistence(timeout: 30))
        app.alerts.buttons["OK"].tap()
    }

    func testPhotosDeniedKeepsDrawingAvailable() {
        exportWithPhotosPermission(allow: false)
        XCTAssertTrue(app.alerts.buttons["Open Settings"].waitForExistence(timeout: 10))
        screenshot("Photos Denied")
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.images["finishedImage"].exists)
        XCTAssertTrue(app.buttons["shareDrawing"].isHittable)
        XCTAssertTrue(app.buttons["backHome"].isHittable)
    }

    func testLargeTextKeepsDrawingControlsReachable() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["startClassic"].waitForExistence(timeout: 10))
        app.swipeUp()
        startClassic()
        draw()
        XCTAssertTrue(app.buttons["ideaBox"].isHittable)
        XCTAssertTrue(app.buttons["finishDrawing"].isHittable)
        screenshot("Large Text Drawing")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
    }

    func testIPadRotationKeepsControlsAndArtwork() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
        defer { XCUIDevice.shared.orientation = .portrait }
        startClassic()
        draw()
        screenshot("iPad Portrait Drawing")
        XCUIDevice.shared.orientation = .landscapeLeft
        draw()
        XCTAssertTrue(app.buttons["finishDrawing"].isHittable)
        XCTAssertTrue(app.buttons["ideaBox"].isHittable)
        screenshot("iPad Landscape Drawing")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
    }
}
