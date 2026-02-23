import XCTest

final class AppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests

    func testAppLaunches() throws {
        // App should launch and have at least one window
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }

    func testWebViewExists() throws {
        // Capacitor apps render in a WKWebView
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 15), "Web view should exist")
    }

    // MARK: - Content Loading Tests

    func testWebViewLoadsContent() throws {
        let webView = app.webViews.firstMatch
        guard webView.waitForExistence(timeout: 15) else {
            XCTFail("Web view did not appear")
            return
        }

        // Wait for page content to load — look for the HealthMe heading
        let healthMeText = webView.staticTexts["HealthMe"]
        let loaded = healthMeText.waitForExistence(timeout: 20)
        XCTAssertTrue(loaded, "HealthMe text should appear in the web view")
    }

    // MARK: - Login Page Tests (unauthenticated state)

    func testLoginPageShowsTagline() throws {
        let webView = app.webViews.firstMatch
        guard webView.waitForExistence(timeout: 15) else {
            XCTFail("Web view did not appear")
            return
        }

        let tagline = webView.staticTexts["Sign in with your keypair"]
        XCTAssertTrue(tagline.waitForExistence(timeout: 20), "Login tagline should be visible")
    }

    func testLoginPageShowsAuthTabs() throws {
        let webView = app.webViews.firstMatch
        guard webView.waitForExistence(timeout: 15) else {
            XCTFail("Web view did not appear")
            return
        }

        let newKeypairTab = webView.buttons["New Keypair"]
        let existingKeyTab = webView.buttons["I Have a Key"]

        XCTAssertTrue(newKeypairTab.waitForExistence(timeout: 20), "New Keypair tab should be visible")
        XCTAssertTrue(existingKeyTab.exists, "I Have a Key tab should be visible")
    }

    func testLoginPageShowsGenerateButton() throws {
        let webView = app.webViews.firstMatch
        guard webView.waitForExistence(timeout: 15) else {
            XCTFail("Web view did not appear")
            return
        }

        let generateBtn = webView.buttons["Generate Keypair"]
        XCTAssertTrue(generateBtn.waitForExistence(timeout: 20), "Generate Keypair button should be visible")
    }

    func testSwitchToExistingKeyTab() throws {
        let webView = app.webViews.firstMatch
        guard webView.waitForExistence(timeout: 15) else {
            XCTFail("Web view did not appear")
            return
        }

        let existingKeyTab = webView.buttons["I Have a Key"]
        guard existingKeyTab.waitForExistence(timeout: 20) else {
            XCTFail("I Have a Key tab not found")
            return
        }

        existingKeyTab.tap()

        // Verify the existing key panel shows a Sign In button
        let signInBtn = webView.buttons["Sign In"]
        XCTAssertTrue(signInBtn.waitForExistence(timeout: 10), "Sign In button should appear on existing key tab")
    }
}
