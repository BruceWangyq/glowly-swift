//
//  MainCoordinator.swift
//  Glowly
//
//  Main coordinator for app navigation and flow
//

import Foundation
import SwiftUI

/// Protocol for main coordinator operations
protocol MainCoordinatorProtocol: ObservableObject {
    var selectedTab: AppTab { get set }
    var navigationPath: NavigationPath { get set }
    var showingOnboarding: Bool { get set }
    var showingPremiumUpgrade: Bool { get set }
    var currentPhotoForEditing: GlowlyPhoto? { get set }
    
    func navigateToEdit(photo: GlowlyPhoto)
    func navigateToHome()
    func navigateToPremium()
    func navigateBack()
    func resetNavigation()
    func handleDeepLink(_ url: URL) -> Bool
}

/// Implementation of main coordinator
@MainActor
final class MainCoordinator: MainCoordinatorProtocol {
    
    // MARK: - Published Properties
    @Published var selectedTab: AppTab = .home
    @Published var navigationPath = NavigationPath()
    @Published var showingOnboarding = false
    @Published var showingPremiumUpgrade = false
    @Published var currentPhotoForEditing: GlowlyPhoto?
    
    // MARK: - Dependencies
    @Inject private var userPreferencesService: UserPreferencesServiceProtocol
    @Inject private var analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Initialization
    init() {
        checkOnboardingStatus()
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to photo editing screen
    func navigateToEdit(photo: GlowlyPhoto) {
        currentPhotoForEditing = photo
        selectedTab = .edit
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "navigation_edit", category: .navigation),
                parameters: ["photo_id": photo.id.uuidString]
            )
        }
    }
    
    /// Navigate to home screen
    func navigateToHome() {
        selectedTab = .home
        currentPhotoForEditing = nil
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "navigation_home", category: .navigation)
            )
        }
    }
    
    /// Navigate to premium upgrade screen
    func navigateToPremium() {
        showingPremiumUpgrade = true
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "navigation_premium", category: .navigation)
            )
        }
    }
    
    /// Navigate back in the navigation stack
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "navigation_back", category: .navigation)
            )
        }
    }
    
    /// Reset navigation to root
    func resetNavigation() {
        navigationPath = NavigationPath()
        selectedTab = .home
        currentPhotoForEditing = nil
        showingOnboarding = false
        showingPremiumUpgrade = false
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "navigation_reset", category: .navigation)
            )
        }
    }
    
    // MARK: - Deep Linking
    
    /// Handle deep link URLs
    func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == "glowly" else { return false }
        
        let host = url.host
        let pathComponents = url.pathComponents
        
        switch host {
        case "edit":
            // Handle edit deep links
            if let photoIdString = pathComponents.last,
               let photoId = UUID(uuidString: photoIdString) {
                // This would typically load the photo and navigate to edit
                // For MVP, we'll just navigate to edit tab
                selectedTab = .edit
                return true
            }
            
        case "premium":
            // Handle premium upgrade deep links
            navigateToPremium()
            return true
            
        case "home":
            // Handle home deep links
            navigateToHome()
            return true
            
        default:
            break
        }
        
        return false
    }
    
    // MARK: - Onboarding
    
    private func checkOnboardingStatus() {
        // Check if user has completed onboarding
        // For MVP, we'll assume first launch needs onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        showingOnboarding = !hasCompletedOnboarding
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        showingOnboarding = false
        
        Task {
            await analyticsService.trackOnboardingCompleted(step: "final")
        }
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: AppTab) {
        selectedTab = tab
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "tab_selected", category: .navigation),
                parameters: ["tab": tab.rawValue]
            )
        }
    }
    
    // MARK: - Premium Features
    
    func checkPremiumAccess(for feature: String) -> Bool {
        // For MVP, assume all features are available
        // In production, this would check subscription status
        
        Task {
            await analyticsService.trackPremiumFeatureAccess(
                feature: feature,
                hasSubscription: false // Would check actual subscription
            )
        }
        
        return true // For MVP
    }
    
    func requestPremiumAccess(for feature: String) {
        // Show premium upgrade screen
        showingPremiumUpgrade = true
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "premium_access_requested", category: .purchase),
                parameters: ["feature": feature]
            )
        }
    }
    
    // MARK: - State Management
    
    func saveNavigationState() {
        // Save current navigation state for restoration
        let state = NavigationState(
            selectedTab: selectedTab,
            hasOnboarded: !showingOnboarding
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "navigation_state")
        }
    }
    
    func restoreNavigationState() {
        guard let data = UserDefaults.standard.data(forKey: "navigation_state"),
              let state = try? JSONDecoder().decode(NavigationState.self, from: data) else {
            return
        }
        
        selectedTab = state.selectedTab
        showingOnboarding = !state.hasOnboarded
    }
}

// MARK: - AppTab

enum AppTab: String, CaseIterable {
    case home = "home"
    case edit = "edit"
    case filters = "filters"
    case premium = "premium"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .edit:
            return "Edit"
        case .filters:
            return "Filters"
        case .premium:
            return "Premium"
        case .profile:
            return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house"
        case .edit:
            return "photo"
        case .filters:
            return "camera.filters"
        case .premium:
            return "crown"
        case .profile:
            return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home:
            return "house.fill"
        case .edit:
            return "photo.fill"
        case .filters:
            return "camera.filters"
        case .premium:
            return "crown.fill"
        case .profile:
            return "person.fill"
        }
    }
}

// MARK: - NavigationState

private struct NavigationState: Codable {
    let selectedTab: AppTab
    let hasOnboarded: Bool
}

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    case photoEdit(GlowlyPhoto)
    case photoDetail(GlowlyPhoto)
    case settings
    case premium
    case help
    case about
    
    var title: String {
        switch self {
        case .photoEdit:
            return "Edit Photo"
        case .photoDetail:
            return "Photo Details"
        case .settings:
            return "Settings"
        case .premium:
            return "Premium"
        case .help:
            return "Help"
        case .about:
            return "About"
        }
    }
}