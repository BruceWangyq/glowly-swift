//
//  AnalyticsService.swift
//  Glowly
//
//  Service for analytics and usage tracking
//

import Foundation
import SwiftUI

/// Protocol for analytics operations
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) async
    func trackScreenView(_ screenName: String) async
    func trackError(_ error: Error, context: String?) async
    func trackUserProperty(_ property: String, value: Any) async
    func trackEnhancementUsage(_ enhancement: EnhancementType, intensity: Float) async
    func trackPhotoProcessed(processingTime: TimeInterval, fileSize: Int64) async
    func setUserID(_ userID: String) async
    func flush() async
    var isEnabled: Bool { get set }
}

/// Implementation of analytics service
@MainActor
final class AnalyticsService: AnalyticsServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var isEnabled: Bool = true
    @Published var sessionDuration: TimeInterval = 0
    
    private var sessionStartTime: Date = Date()
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    private var userID: String?
    
    // MARK: - Initialization
    init() {
        sessionStartTime = Date()
        startSessionTimer()
    }
    
    // MARK: - Event Tracking
    
    /// Track a custom event
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) async {
        guard isEnabled else { return }
        
        var eventWithMetadata = event
        eventWithMetadata.timestamp = Date()
        eventWithMetadata.sessionDuration = sessionDuration
        eventWithMetadata.userID = userID
        
        if let parameters = parameters {
            eventWithMetadata.parameters.merge(parameters) { _, new in new }
        }
        
        await queueEvent(eventWithMetadata)
        
        // Log for debugging in development
        #if DEBUG
        print("Analytics Event: \(event.name), Parameters: \(eventWithMetadata.parameters)")
        #endif
    }
    
    /// Track screen view
    func trackScreenView(_ screenName: String) async {
        let event = AnalyticsEvent(
            name: "screen_view",
            category: .navigation,
            parameters: ["screen_name": screenName]
        )
        await trackEvent(event)
    }
    
    /// Track error occurrence
    func trackError(_ error: Error, context: String? = nil) async {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_type": String(describing: type(of: error))
        ]
        
        if let context = context {
            parameters["context"] = context
        }
        
        let event = AnalyticsEvent(
            name: "error_occurred",
            category: .error,
            parameters: parameters
        )
        await trackEvent(event)
    }
    
    /// Track user property
    func trackUserProperty(_ property: String, value: Any) async {
        guard isEnabled else { return }
        
        let event = AnalyticsEvent(
            name: "user_property_set",
            category: .user,
            parameters: [
                "property_name": property,
                "property_value": value
            ]
        )
        await trackEvent(event)
    }
    
    /// Track enhancement usage
    func trackEnhancementUsage(_ enhancement: EnhancementType, intensity: Float) async {
        let event = AnalyticsEvent(
            name: "enhancement_applied",
            category: .enhancement,
            parameters: [
                "enhancement_type": enhancement.rawValue,
                "enhancement_name": enhancement.displayName,
                "intensity": intensity,
                "category": enhancement.category.rawValue,
                "is_premium": enhancement.isPremium
            ]
        )
        await trackEvent(event)
    }
    
    /// Track photo processing metrics
    func trackPhotoProcessed(processingTime: TimeInterval, fileSize: Int64) async {
        let event = AnalyticsEvent(
            name: "photo_processed",
            category: .performance,
            parameters: [
                "processing_time": processingTime,
                "file_size": fileSize,
                "file_size_mb": Double(fileSize) / (1024 * 1024)
            ]
        )
        await trackEvent(event)
    }
    
    // MARK: - User Management
    
    /// Set user ID for tracking
    func setUserID(_ userID: String) async {
        self.userID = userID
        await trackUserProperty("user_id", value: userID)
    }
    
    // MARK: - Session Management
    
    private func startSessionTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.sessionDuration = Date().timeIntervalSince(self.sessionStartTime)
            }
        }
    }
    
    /// Track session start
    func trackSessionStart() async {
        sessionStartTime = Date()
        sessionDuration = 0
        
        let event = AnalyticsEvent(
            name: "session_start",
            category: .session,
            parameters: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "device_model": UIDevice.current.model,
                "ios_version": UIDevice.current.systemVersion
            ]
        )
        await trackEvent(event)
    }
    
    /// Track session end
    func trackSessionEnd() async {
        let event = AnalyticsEvent(
            name: "session_end",
            category: .session,
            parameters: [
                "session_duration": sessionDuration,
                "events_tracked": eventQueue.count
            ]
        )
        await trackEvent(event)
        
        await flush()
    }
    
    // MARK: - Data Management
    
    private func queueEvent(_ event: AnalyticsEvent) async {
        eventQueue.append(event)
        
        // Flush if queue is getting full
        if eventQueue.count >= maxQueueSize {
            await flush()
        }
    }
    
    /// Flush queued events
    func flush() async {
        guard !eventQueue.isEmpty else { return }
        
        // In a real implementation, this would send events to analytics service
        // For now, we'll just log them and clear the queue
        
        #if DEBUG
        print("Flushing \(eventQueue.count) analytics events")
        for event in eventQueue {
            print("Event: \(event.name), Category: \(event.category), Time: \(event.timestamp)")
        }
        #endif
        
        // Simulate network request
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        eventQueue.removeAll()
    }
    
    // MARK: - Privacy Controls
    
    /// Enable analytics tracking
    func enableTracking() async {
        isEnabled = true
        await trackEvent(AnalyticsEvent(name: "analytics_enabled", category: .privacy))
    }
    
    /// Disable analytics tracking
    func disableTracking() async {
        await trackEvent(AnalyticsEvent(name: "analytics_disabled", category: .privacy))
        await flush()
        isEnabled = false
    }
    
    /// Clear all stored analytics data
    func clearData() async {
        eventQueue.removeAll()
        userID = nil
        
        #if DEBUG
        print("Analytics data cleared")
        #endif
    }
}

// MARK: - AnalyticsEvent

struct AnalyticsEvent {
    let name: String
    let category: AnalyticsCategory
    var parameters: [String: Any]
    var timestamp: Date
    var sessionDuration: TimeInterval
    var userID: String?
    
    init(
        name: String,
        category: AnalyticsCategory,
        parameters: [String: Any] = [:]
    ) {
        self.name = name
        self.category = category
        self.parameters = parameters
        self.timestamp = Date()
        self.sessionDuration = 0
        self.userID = nil
    }
}

// MARK: - AnalyticsCategory

enum AnalyticsCategory: String, CaseIterable {
    case navigation = "navigation"
    case enhancement = "enhancement"
    case photo = "photo"
    case user = "user"
    case performance = "performance"
    case error = "error"
    case session = "session"
    case purchase = "purchase"
    case privacy = "privacy"
    case onboarding = "onboarding"
    
    var displayName: String {
        switch self {
        case .navigation:
            return "Navigation"
        case .enhancement:
            return "Enhancement"
        case .photo:
            return "Photo"
        case .user:
            return "User"
        case .performance:
            return "Performance"
        case .error:
            return "Error"
        case .session:
            return "Session"
        case .purchase:
            return "Purchase"
        case .privacy:
            return "Privacy"
        case .onboarding:
            return "Onboarding"
        }
    }
}

// MARK: - Common Analytics Events

extension AnalyticsService {
    
    /// Track app launch
    func trackAppLaunch() async {
        let event = AnalyticsEvent(
            name: "app_launch",
            category: .session,
            parameters: [
                "launch_time": Date().timeIntervalSince1970
            ]
        )
        await trackEvent(event)
    }
    
    /// Track onboarding completion
    func trackOnboardingCompleted(step: String) async {
        let event = AnalyticsEvent(
            name: "onboarding_completed",
            category: .onboarding,
            parameters: [
                "final_step": step
            ]
        )
        await trackEvent(event)
    }
    
    /// Track premium feature access attempt
    func trackPremiumFeatureAccess(feature: String, hasSubscription: Bool) async {
        let event = AnalyticsEvent(
            name: "premium_feature_access",
            category: .purchase,
            parameters: [
                "feature_name": feature,
                "has_subscription": hasSubscription,
                "access_granted": hasSubscription
            ]
        )
        await trackEvent(event)
    }
    
    /// Track photo import
    func trackPhotoImport(source: PhotoSource, success: Bool) async {
        let event = AnalyticsEvent(
            name: "photo_import",
            category: .photo,
            parameters: [
                "source": source.rawValue,
                "success": success
            ]
        )
        await trackEvent(event)
    }
    
    /// Track photo export
    func trackPhotoExport(format: ExportFormat, quality: ImageQuality, success: Bool) async {
        let event = AnalyticsEvent(
            name: "photo_export",
            category: .photo,
            parameters: [
                "format": format.rawValue,
                "quality": quality.rawValue,
                "success": success
            ]
        )
        await trackEvent(event)
    }
}