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
        let headerTop = app.buttons["settings"].frame.minY
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
        XCTAssertTrue(app.buttons["deleteDrawing"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.buttons["deleteDrawing"].frame.minY, headerTop - 8)
        screenshot("Saved Drawing Preview")
        app.buttons["deleteDrawing"].tap()
        app.buttons["Delete drawing"].tap()
        XCTAssertTrue(app.staticTexts["Nothing here yet."].waitForExistence(timeout: 5))
    }

    func testHomeNavigationFitsWindow() {
        let window = app.windows.firstMatch.frame
        let wordmark = app.images["brandWordmark"]
        XCTAssertTrue(wordmark.exists)
        XCTAssertEqual(wordmark.label, "Just Doodle")
        XCTAssertTrue(window.contains(wordmark.frame))
        for identifier in ["startClassic", "doodleBook", "challenges", "settings"] {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.isHittable, identifier)
            XCTAssertTrue(window.contains(control.frame), identifier)
        }
        screenshot("Ink Window Home")
        app.buttons["doodleBook"].tap()
        XCTAssertTrue(app.staticTexts["Nothing here yet."].waitForExistence(timeout: 5))
        app.buttons["Back to home"].tap()
        app.buttons["challenges"].tap()
        XCTAssertTrue(app.buttons["challenge-build-it"].waitForExistence(timeout: 5))
        app.buttons["Back to home"].tap()
        app.buttons["settings"].tap()
        XCTAssertTrue(app.switches["hapticsToggle"].waitForExistence(timeout: 5))
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

    func testReplayAndBookSearch() {
        startClassic()
        draw()
        app.buttons["finishDrawing"].tap()
        let replay = app.buttons["drawAgain"]
        XCTAssertTrue(replay.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: replay)
        waitForExpectations(timeout: 10)
        replay.tap()
        XCTAssertTrue(app.buttons["finishDrawing"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["finishDrawing"])
        waitForExpectations(timeout: 5)
        draw()
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.buttons["backHome"].waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["backHome"])
        waitForExpectations(timeout: 10)
        app.buttons["backHome"].tap()
        app.buttons["doodleBook"].tap()
        let search = app.textFields["archiveSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("no-such-page")
        XCTAssertTrue(app.staticTexts["No matching pages."].waitForExistence(timeout: 5))
        app.buttons["Clear search"].tap()
        XCTAssertEqual(app.buttons.matching(identifier: "archiveDrawing").count, 2)
    }

    func testCustomChallengeUsesSelectedPalette() {
        app.buttons["challenges"].tap()
        app.swipeUp()
        app.swipeUp()
        app.buttons["Three"].tap()
        app.segmentedControls.buttons["1m"].tap()
        screenshot("Custom Challenge")
        app.buttons["startCustomChallenge"].tap()
        XCTAssertTrue(app.buttons["ink-red"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["ink-red"])
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.buttons["ink-black"].exists)
        XCTAssertTrue(app.buttons["ink-blue"].exists)
        app.buttons["ink-red"].tap()
        draw()
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
    }

    func testResultControlsRespectScreenInsets() {
        let headerTop = app.buttons["settings"].frame.minY
        startClassic()
        draw()
        app.buttons["finishDrawing"].tap()
        let status = app.staticTexts["resultStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "label == 'Saved.'"), evaluatedWith: status)
        waitForExpectations(timeout: 10)
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(status.frame.minY, headerTop - 8)
        XCTAssertLessThanOrEqual(app.buttons["drawAgain"].frame.maxY, window.maxY - 10)
        XCTAssertTrue(window.contains(app.images["finishedImage"].frame))
        screenshot("Result Insets")
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
        let vibration = app.switches["hapticsToggle"].value as? String
        screenshot("Settings")
        app.buttons["Privacy policy"].tap()
        XCTAssertTrue(app.staticTexts["Your drawings belong to you."].waitForExistence(timeout: 5))
        screenshot("Privacy Policy")
        app.buttons["Back to settings"].tap()
        XCTAssertEqual(app.switches["hapticsToggle"].value as? String, vibration)
        app.buttons["Back to home"].tap()
        XCTAssertTrue(app.buttons["startClassic"].waitForExistence(timeout: 5))
    }

    func testLargeTextSecondaryPagesAndEmptyBookStart() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["settings"].waitForExistence(timeout: 10))
        app.buttons["settings"].tap()
        XCTAssertTrue(app.switches["hapticsToggle"].isHittable)
        XCTAssertTrue(app.buttons["Privacy policy"].isHittable)
        screenshot("Large Text Settings")
        app.buttons["Privacy policy"].tap()
        XCTAssertTrue(app.staticTexts["Your drawings belong to you."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Back to settings"].isHittable)
        app.buttons["Back to settings"].tap()
        app.buttons["Back to home"].tap()
        app.buttons["challenges"].tap()
        XCTAssertTrue(app.buttons["challenge-build-it"].isHittable)
        screenshot("Large Text Challenges")
        app.buttons["Back to home"].tap()
        app.buttons["doodleBook"].tap()
        let start = app.buttons["startFromBook"]
        XCTAssertTrue(start.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(start.frame))
        screenshot("Empty Doodle Book")
        start.tap()
        XCTAssertTrue(app.buttons["finishDrawing"].waitForExistence(timeout: 5))
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
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts
            .matching(NSPredicate(format: "label CONTAINS[c] 'Just Doodle' AND label CONTAINS[c] 'Photos'"))
            .firstMatch
        XCTAssertTrue(permission.waitForExistence(timeout: 10))
        let predicate = allow
            ? NSPredicate(format: "label CONTAINS[c] 'Add' OR label == 'Allow' OR label == 'OK'")
            : NSPredicate(format: "label BEGINSWITH[c] 'Don'")
        let response = permission.buttons.matching(predicate).firstMatch
        XCTAssertTrue(response.exists, permission.debugDescription)
        // The system permission sheet can expose buttons before its entrance settles.
        Thread.sleep(forTimeInterval: 0.75)
        response.tap()
        let dismissed = NSPredicate(format: "exists == false")
        if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: dismissed, object: permission)], timeout: 3) != .completed {
            response.tap()
        }
        expectation(for: dismissed, evaluatedWith: permission)
        waitForExpectations(timeout: 5)
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
        screenshot("Large Text Home")
        app.swipeUp()
        startClassic()
        draw()
        XCTAssertTrue(app.buttons["ideaBox"].isHittable)
        XCTAssertTrue(app.buttons["finishDrawing"].isHittable)
        screenshot("Large Text Drawing")
        app.buttons["finishDrawing"].tap()
        XCTAssertTrue(app.images["finishedImage"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.windows.firstMatch.frame.contains(app.images["finishedImage"].frame))
        XCTAssertTrue(app.buttons["drawAgain"].isHittable)
        screenshot("Large Text Result")
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
