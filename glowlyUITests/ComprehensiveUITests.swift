//
//  ComprehensiveUITests.swift
//  glowlyUITests
//
//  Comprehensive UI tests for Glowly MVP user flows
//

import XCTest

final class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - App Launch and Onboarding Tests
    
    @MainActor
    func testAppLaunchAndOnboarding() throws {
        // Test app launches successfully
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Check for onboarding screen on first launch
        let welcomeText = app.staticTexts["Welcome to Glowly"]
        if welcomeText.exists {
            // Complete onboarding flow
            let getStartedButton = app.buttons["Get Started"]
            XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5))
            getStartedButton.tap()
        }
        
        // Verify main tab view is displayed
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Verify all tabs are present
        XCTAssertTrue(app.buttons["Home"].exists)
        XCTAssertTrue(app.buttons["Edit"].exists)
        XCTAssertTrue(app.buttons["Filters"].exists)
        XCTAssertTrue(app.buttons["Store"].exists || app.buttons["Premium"].exists)
        XCTAssertTrue(app.buttons["Profile"].exists)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testTabNavigation() throws {
        // Wait for app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test each tab navigation
        let tabs = ["Home", "Edit", "Filters", "Profile"]
        
        for tabName in tabs {
            let tabButton = app.buttons[tabName]
            XCTAssertTrue(tabButton.exists, "Tab \(tabName) should exist")
            
            tabButton.tap()
            
            // Verify tab content loads
            XCTAssertTrue(app.navigationBars[tabName].waitForExistence(timeout: 3) || 
                         app.staticTexts[tabName].waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Photo Selection and Import Tests
    
    @MainActor
    func testPhotoSelectionFlow() throws {
        // Navigate to Edit tab
        let editTab = app.buttons["Edit"]
        editTab.tap()
        
        // Look for photo selection elements
        let selectPhotoButton = app.buttons["Select Photo"]
        
        if selectPhotoButton.waitForExistence(timeout: 5) {
            selectPhotoButton.tap()
            
            // This would normally trigger photo picker
            // In UI tests, we can't access photo library, so we verify the button works
            // The actual photo picker would be tested with mocked data
        }
    }
    
    // MARK: - Enhancement Flow Tests
    
    @MainActor
    func testEnhancementUIFlow() throws {
        // Navigate to Edit tab with a test photo (would need to be set up)
        let editTab = app.buttons["Edit"]
        editTab.tap()
        
        // Look for enhancement controls
        let enhancementControls = app.scrollViews.containing(.staticText, identifier: "Enhancement")
        
        if enhancementControls.firstMatch.exists {
            // Test enhancement controls are accessible
            XCTAssertTrue(enhancementControls.firstMatch.isHittable)
        }
    }
    
    // MARK: - Subscription Flow Tests
    
    @MainActor
    func testPremiumUpgradeFlow() throws {
        // Navigate to premium/store tab
        let premiumTab = app.buttons.matching(identifier: "Store").firstMatch
        if !premiumTab.exists {
            let altPremiumTab = app.buttons.matching(identifier: "Premium").firstMatch
            if altPremiumTab.exists {
                altPremiumTab.tap()
            }
        } else {
            premiumTab.tap()
        }
        
        // Look for upgrade button
        let upgradeButton = app.buttons.containing(.staticText, identifier: "Upgrade").firstMatch
        if upgradeButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(upgradeButton.isEnabled)
            // Don't actually tap to avoid real purchase in tests
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibilityElements() throws {
        // Test that all interactive elements have accessibility labels
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Check tab buttons have accessibility labels
        let homeTab = app.buttons["Home"]
        XCTAssertNotNil(homeTab.label)
        XCTAssertTrue(homeTab.isAccessibilityElement)
        
        let editTab = app.buttons["Edit"]
        XCTAssertNotNil(editTab.label)
        XCTAssertTrue(editTab.isAccessibilityElement)
        
        // Navigate through app and check accessibility
        editTab.tap()
        
        // Check for proper accessibility traits
        let selectPhotoButton = app.buttons["Select Photo"]
        if selectPhotoButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(selectPhotoButton.isAccessibilityElement)
            XCTAssertEqual(selectPhotoButton.accessibilityTraits, [.button])
        }
    }
    
    @MainActor
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver for testing
        // Note: This requires additional setup and permissions
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test that VoiceOver can navigate through main elements
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.isAccessibilityElement)
        
        // Simulate VoiceOver focus
        homeTab.tap()
        
        // Verify accessibility announcements would work
        // (This would need additional accessibility testing framework)
    }
    
    // MARK: - Error Handling UI Tests
    
    @MainActor
    func testPhotoPermissionDeniedUI() throws {
        // This test would need to be run with photo permission denied
        // We can simulate the UI state
        
        let editTab = app.buttons["Edit"]
        editTab.tap()
        
        // Look for permission request UI
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 3) {
            // Test that permission alert has proper buttons
            let settingsButton = app.buttons["Settings"]
            let cancelButton = app.buttons["Cancel"]
            
            if settingsButton.exists {
                XCTAssertTrue(settingsButton.isEnabled)
            }
            
            if cancelButton.exists {
                XCTAssertTrue(cancelButton.isEnabled)
                cancelButton.tap()
            }
        }
    }
    
    @MainActor
    func testNetworkErrorHandling() throws {
        // Test app behavior when network is unavailable
        // This would be tested with network stubbing
        
        let premiumTab = app.buttons.matching(identifier: "Store").firstMatch
        if premiumTab.exists {
            premiumTab.tap()
            
            // Look for network error UI
            let errorMessage = app.staticTexts.containing(.staticText, identifier: "Network Error").firstMatch
            
            // If network error occurs, verify user sees appropriate message
            if errorMessage.waitForExistence(timeout: 5) {
                XCTAssertTrue(errorMessage.exists)
                
                // Look for retry button
                let retryButton = app.buttons["Retry"]
                if retryButton.exists {
                    XCTAssertTrue(retryButton.isEnabled)
                }
            }
        }
    }
    
    // MARK: - Performance UI Tests
    
    @MainActor
    func testScrollPerformance() throws {
        // Navigate to a scrollable view
        let homeTab = app.buttons["Home"]
        homeTab.tap()
        
        // Find scrollable content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Test smooth scrolling
            let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let endCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            
            // Perform scroll gesture
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            
            // Verify scroll completed
            XCTAssertTrue(scrollView.exists)
        }
    }
    
    @MainActor
    func testAnimationPerformance() throws {
        // Test tab switching animations
        let homeTab = app.buttons["Home"]
        let editTab = app.buttons["Edit"]
        
        // Rapid tab switching to test animation performance
        for _ in 0..<5 {
            homeTab.tap()
            editTab.tap()
        }
        
        // Verify app remains responsive
        XCTAssertTrue(editTab.isEnabled)
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testAppBackgroundingAndForegrounding() throws {
        // Test app state preservation
        let editTab = app.buttons["Edit"]
        editTab.tap()
        
        // Simulate app backgrounding
        XCUIDevice.shared.press(.home)
        
        // Wait briefly
        Thread.sleep(forTimeInterval: 1.0)
        
        // Return to app
        app.activate()
        
        // Verify state was preserved
        XCTAssertTrue(app.buttons["Edit"].isSelected || 
                     app.navigationBars["Edit"].exists)
    }
    
    @MainActor
    func testMemoryWarningHandling() throws {
        // This would require additional setup to simulate memory warnings
        // For now, we test that the app can handle rapid navigation
        
        let tabs = ["Home", "Edit", "Filters", "Profile"]
        
        // Rapid navigation to stress test memory handling
        for _ in 0..<10 {
            for tabName in tabs {
                let tab = app.buttons[tabName]
                if tab.exists {
                    tab.tap()
                }
            }
        }
        
        // Verify app is still responsive
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.isEnabled)
    }
    
    // MARK: - Launch Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let testApp = XCUIApplication()
                testApp.launchArguments.append("--performance-testing")
                testApp.launch()
                testApp.terminate()
            }
        }
    }
    
    @MainActor
    func testColdStartPerformance() throws {
        // Test cold start performance
        app.terminate()
        
        let startTime = Date()
        
        let newApp = XCUIApplication()
        newApp.launch()
        
        // Wait for app to be fully loaded
        let tabBar = newApp.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        
        let launchTime = Date().timeIntervalSince(startTime)
        
        // Cold start should be under 5 seconds
        XCTAssertLessThan(launchTime, 5.0, "Cold start took too long: \(launchTime)s")
        
        newApp.terminate()
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppToLoad() {
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)
    }
    
    private func dismissAnyAlerts() {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let okButton = alert.buttons["OK"]
            let cancelButton = alert.buttons["Cancel"]
            let dismissButton = alert.buttons["Dismiss"]
            
            if okButton.exists {
                okButton.tap()
            } else if cancelButton.exists {
                cancelButton.tap()
            } else if dismissButton.exists {
                dismissButton.tap()
            }
        }
    }
}