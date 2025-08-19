//
//  MonetizationAnalyticsService.swift
//  Glowly
//
//  Analytics and conversion tracking for monetization optimization
//

import Foundation
import Combine

protocol MonetizationAnalyticsServiceProtocol: ObservableObject {
    func trackSubscriptionEvent(_ event: SubscriptionEvent, parameters: [String: Any]?) async
    func trackUsageLimitEvent(_ event: UsageLimitEvent, action: UsageAction, parameters: [String: Any]?) async
    func trackPaywallEvent(_ event: PaywallEvent, parameters: [String: Any]?) async
    func trackConversionFunnel(_ step: ConversionStep, parameters: [String: Any]?) async
    func trackRetentionEvent(_ event: RetentionEvent, parameters: [String: Any]?) async
    func getConversionMetrics() async -> ConversionMetrics
    func getChurnPrediction() async -> ChurnPrediction
}

enum SubscriptionEvent: String {
    case subscriptionStarted = "subscription_started"
    case subscriptionRenewed = "subscription_renewed"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionExpired = "subscription_expired"
    case subscriptionUpgraded = "subscription_upgraded"
    case subscriptionDowngraded = "subscription_downgraded"
    case trialStarted = "trial_started"
    case trialConverted = "trial_converted"
    case trialExpired = "trial_expired"
    case purchaseRestored = "purchase_restored"
}

enum UsageLimitEvent: String {
    case limitWarning = "usage_limit_warning"
    case limitReached = "usage_limit_reached"
    case limitExceeded = "usage_limit_exceeded"
    case upgradePrompted = "usage_upgrade_prompted"
    case upgradeFromUsage = "upgrade_from_usage_limit"
}

enum PaywallEvent: String {
    case paywallViewed = "paywall_viewed"
    case paywallDismissed = "paywall_dismissed"
    case planSelected = "paywall_plan_selected"
    case purchaseAttempted = "paywall_purchase_attempted"
    case purchaseCompleted = "paywall_purchase_completed"
    case purchaseFailed = "paywall_purchase_failed"
    case termsViewed = "paywall_terms_viewed"
    case privacyViewed = "paywall_privacy_viewed"
    case restoreAttempted = "paywall_restore_attempted"
}

enum ConversionStep: String {
    case appLaunched = "app_launched"
    case featureDiscovered = "feature_discovered"
    case limitEncountered = "limit_encountered"
    case paywallViewed = "paywall_viewed"
    case planSelected = "plan_selected"
    case purchaseInitiated = "purchase_initiated"
    case purchaseCompleted = "purchase_completed"
    case featureUsed = "premium_feature_used"
}

enum RetentionEvent: String {
    case dailyActive = "daily_active_user"
    case weeklyActive = "weekly_active_user"
    case monthlyActive = "monthly_active_user"
    case featureEngagement = "feature_engagement"
    case sessionLength = "session_length"
    case churnRisk = "churn_risk_detected"
    case retentionCampaign = "retention_campaign_shown"
    case winbackAttempt = "winback_attempt"
}

struct ConversionMetrics {
    let trialToSubscriptionRate: Double
    let freeToPremiumRate: Double
    let averageTimeToConvert: TimeInterval
    let topConversionTriggers: [String]
    let conversionBySource: [String: Double]
    let lifetimeValue: Double
    let paybackPeriod: TimeInterval
}

struct ChurnPrediction {
    let riskLevel: ChurnRisk
    let probability: Double
    let keyFactors: [String]
    let recommendedActions: [String]
    let timeToChurn: TimeInterval?
}

enum ChurnRisk: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

@MainActor
final class MonetizationAnalyticsService: MonetizationAnalyticsServiceProtocol {
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsServiceProtocol
    private let userDefaults: UserDefaults
    private var sessionStartTime: Date?
    private var conversionFunnelSteps: [ConversionStep] = []
    
    // Storage keys
    private let funnelStepsKey = "conversion_funnel_steps"
    private let sessionMetricsKey = "session_metrics"
    private let retentionDataKey = "retention_data"
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.analyticsService = analyticsService
        self.userDefaults = userDefaults
        self.sessionStartTime = Date()
        
        loadConversionFunnel()
        scheduleRetentionTracking()
    }
    
    // MARK: - Subscription Events
    
    func trackSubscriptionEvent(_ event: SubscriptionEvent, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["event_type"] = "subscription"
        eventParameters["timestamp"] = Date().timeIntervalSince1970
        
        // Add subscription context
        if let subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as? SubscriptionManager {
            eventParameters["current_tier"] = subscriptionManager.currentTier.rawValue
            eventParameters["is_premium"] = subscriptionManager.isPremiumUser
            eventParameters["trial_status"] = subscriptionManager.getTrialStatus().message
        }
        
        await analyticsService.trackEvent(event.rawValue, parameters: eventParameters)
        
        // Track conversion funnel progress
        switch event {
        case .trialStarted:
            await trackConversionFunnel(.purchaseCompleted, parameters: eventParameters)
        case .subscriptionStarted:
            await trackConversionFunnel(.purchaseCompleted, parameters: eventParameters)
        default:
            break
        }
        
        // Update retention metrics
        await updateRetentionMetrics(for: event)
    }
    
    // MARK: - Usage Limit Events
    
    func trackUsageLimitEvent(_ event: UsageLimitEvent, action: UsageAction, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["action"] = action.rawValue
        eventParameters["event_type"] = "usage_limit"
        
        // Add usage context
        if let featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as? FeatureGatingService {
            eventParameters["current_usage"] = getCurrentUsage(for: action, featureGating: featureGating)
            eventParameters["usage_limit"] = getUsageLimit(for: action, featureGating: featureGating)
            eventParameters["remaining_usage"] = featureGating.getRemainingUsage(action) ?? -1
        }
        
        await analyticsService.trackEvent(event.rawValue, parameters: eventParameters)
        
        // Track conversion opportunities
        if event == .limitReached || event == .upgradePrompted {
            await trackConversionFunnel(.limitEncountered, parameters: eventParameters)
        }
    }
    
    // MARK: - Paywall Events
    
    func trackPaywallEvent(_ event: PaywallEvent, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["event_type"] = "paywall"
        eventParameters["session_duration"] = getCurrentSessionDuration()
        
        // Add paywall context
        eventParameters["paywall_trigger"] = getCurrentPaywallTrigger()
        eventParameters["funnel_steps"] = conversionFunnelSteps.map { $0.rawValue }
        
        await analyticsService.trackEvent(event.rawValue, parameters: eventParameters)
        
        // Track conversion funnel
        switch event {
        case .paywallViewed:
            await trackConversionFunnel(.paywallViewed, parameters: eventParameters)
        case .planSelected:
            await trackConversionFunnel(.planSelected, parameters: eventParameters)
        case .purchaseAttempted:
            await trackConversionFunnel(.purchaseInitiated, parameters: eventParameters)
        case .purchaseCompleted:
            await trackConversionFunnel(.purchaseCompleted, parameters: eventParameters)
        default:
            break
        }
    }
    
    // MARK: - Conversion Funnel
    
    func trackConversionFunnel(_ step: ConversionStep, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["funnel_step"] = step.rawValue
        eventParameters["step_order"] = conversionFunnelSteps.count
        eventParameters["session_duration"] = getCurrentSessionDuration()
        
        // Add previous steps context
        eventParameters["previous_steps"] = conversionFunnelSteps.map { $0.rawValue }
        
        // Add step to funnel
        conversionFunnelSteps.append(step)
        saveConversionFunnel()
        
        await analyticsService.trackEvent("conversion_funnel_step", parameters: eventParameters)
        
        // Calculate funnel drop-off rates
        if conversionFunnelSteps.count > 1 {
            await calculateFunnelDropoff()
        }
    }
    
    // MARK: - Retention Events
    
    func trackRetentionEvent(_ event: RetentionEvent, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["event_type"] = "retention"
        eventParameters["user_lifecycle_stage"] = getUserLifecycleStage()
        
        await analyticsService.trackEvent(event.rawValue, parameters: eventParameters)
        
        // Update retention data
        await updateRetentionData(event: event, parameters: eventParameters)
    }
    
    // MARK: - Metrics and Predictions
    
    func getConversionMetrics() async -> ConversionMetrics {
        // In a real app, this would query your analytics backend
        // For now, we'll return mock data based on stored metrics
        
        let trialUsers = userDefaults.integer(forKey: "trial_users_count")
        let convertedUsers = userDefaults.integer(forKey: "converted_users_count")
        let trialToSubscriptionRate = trialUsers > 0 ? Double(convertedUsers) / Double(trialUsers) : 0.0
        
        return ConversionMetrics(
            trialToSubscriptionRate: trialToSubscriptionRate,
            freeToPremiumRate: 0.15, // 15% typical conversion rate
            averageTimeToConvert: 3.5 * 24 * 60 * 60, // 3.5 days
            topConversionTriggers: [
                "filter_limit_reached",
                "export_limit_reached",
                "premium_feature_accessed"
            ],
            conversionBySource: [
                "organic": 0.18,
                "paywall": 0.25,
                "usage_limit": 0.32,
                "feature_discovery": 0.12
            ],
            lifetimeValue: 47.88, // Average LTV
            paybackPeriod: 45 * 24 * 60 * 60 // 45 days
        )
    }
    
    func getChurnPrediction() async -> ChurnPrediction {
        let churnFactors = await calculateChurnFactors()
        let riskLevel = determineChurnRisk(factors: churnFactors)
        
        return ChurnPrediction(
            riskLevel: riskLevel,
            probability: churnFactors.probability,
            keyFactors: churnFactors.factors,
            recommendedActions: getChurnPreventionActions(riskLevel: riskLevel),
            timeToChurn: riskLevel == .high || riskLevel == .critical ? 7 * 24 * 60 * 60 : nil
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getCurrentUsage(for action: UsageAction, featureGating: FeatureGatingService) -> Int {
        switch action {
        case .filterApplication:
            return featureGating.dailyUsage.filterApplications
        case .retouchOperation:
            return featureGating.dailyUsage.retouchOperations
        case .export:
            return featureGating.dailyUsage.exports
        }
    }
    
    private func getUsageLimit(for action: UsageAction, featureGating: FeatureGatingService) -> Int {
        let limits = featureGating.getUsageLimits()
        switch action {
        case .filterApplication:
            return limits.dailyFilterApplications
        case .retouchOperation:
            return limits.dailyRetouchOperations
        case .export:
            return limits.dailyExports
        }
    }
    
    private func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    private func getCurrentPaywallTrigger() -> String {
        // Determine what triggered the current paywall based on recent funnel steps
        if conversionFunnelSteps.contains(.limitEncountered) {
            return "usage_limit"
        } else if conversionFunnelSteps.contains(.featureDiscovered) {
            return "feature_discovery"
        } else {
            return "general"
        }
    }
    
    private func loadConversionFunnel() {
        if let data = userDefaults.data(forKey: funnelStepsKey),
           let steps = try? JSONDecoder().decode([String].self, from: data) {
            conversionFunnelSteps = steps.compactMap { ConversionStep(rawValue: $0) }
        }
    }
    
    private func saveConversionFunnel() {
        let stepStrings = conversionFunnelSteps.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(stepStrings) {
            userDefaults.set(data, forKey: funnelStepsKey)
        }
    }
    
    private func calculateFunnelDropoff() async {
        let totalSteps = conversionFunnelSteps.count
        
        for (index, step) in conversionFunnelSteps.enumerated() {
            let dropoffRate = Double(totalSteps - index - 1) / Double(totalSteps)
            
            await analyticsService.trackEvent("funnel_dropoff", parameters: [
                "step": step.rawValue,
                "step_index": index,
                "dropoff_rate": dropoffRate,
                "total_steps": totalSteps
            ])
        }
    }
    
    private func scheduleRetentionTracking() {
        // Track daily active users
        Task {
            await trackRetentionEvent(.dailyActive, parameters: [
                "session_start": Date().timeIntervalSince1970
            ])
        }
    }
    
    private func updateRetentionMetrics(for event: SubscriptionEvent) async {
        var retentionData: [String: Any] = [:]
        
        if let data = userDefaults.data(forKey: retentionDataKey),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            retentionData = existing
        }
        
        switch event {
        case .trialStarted:
            retentionData["trial_start_date"] = Date().timeIntervalSince1970
        case .subscriptionStarted:
            retentionData["subscription_start_date"] = Date().timeIntervalSince1970
            
            // Update conversion metrics
            let trialUsers = userDefaults.integer(forKey: "trial_users_count") + 1
            userDefaults.set(trialUsers, forKey: "trial_users_count")
        case .trialConverted, .subscriptionStarted:
            let convertedUsers = userDefaults.integer(forKey: "converted_users_count") + 1
            userDefaults.set(convertedUsers, forKey: "converted_users_count")
        case .subscriptionCancelled:
            retentionData["cancellation_date"] = Date().timeIntervalSince1970
        default:
            break
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: retentionData) {
            userDefaults.set(data, forKey: retentionDataKey)
        }
    }
    
    private func updateRetentionData(event: RetentionEvent, parameters: [String: Any]) async {
        // Update retention tracking data
        var retentionData: [String: Any] = [:]
        
        if let data = userDefaults.data(forKey: retentionDataKey),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            retentionData = existing
        }
        
        retentionData["last_\(event.rawValue)"] = Date().timeIntervalSince1970
        
        if let data = try? JSONSerialization.data(withJSONObject: retentionData) {
            userDefaults.set(data, forKey: retentionDataKey)
        }
    }
    
    private func getUserLifecycleStage() -> String {
        guard let data = userDefaults.data(forKey: retentionDataKey),
              let retentionData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "new"
        }
        
        let now = Date().timeIntervalSince1970
        
        if let trialStartDate = retentionData["trial_start_date"] as? TimeInterval {
            let daysSinceTrial = (now - trialStartDate) / (24 * 60 * 60)
            
            if daysSinceTrial <= 7 {
                return "trial"
            } else if let subscriptionStartDate = retentionData["subscription_start_date"] as? TimeInterval {
                let daysSinceSubscription = (now - subscriptionStartDate) / (24 * 60 * 60)
                
                if daysSinceSubscription <= 30 {
                    return "new_subscriber"
                } else if daysSinceSubscription <= 90 {
                    return "established_subscriber"
                } else {
                    return "loyal_subscriber"
                }
            } else {
                return "trial_expired"
            }
        }
        
        return "free_user"
    }
    
    private func calculateChurnFactors() async -> (probability: Double, factors: [String]) {
        var churnScore = 0.0
        var factors: [String] = []
        
        // Analyze usage patterns
        if let featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as? FeatureGatingService {
            let usage = featureGating.dailyUsage
            
            // Low usage indicator
            if usage.filterApplications < 2 && usage.retouchOperations < 1 {
                churnScore += 0.3
                factors.append("low_daily_usage")
            }
            
            // Hitting limits frequently
            if !featureGating.canPerformAction(.filterApplication) {
                churnScore += 0.2
                factors.append("frequent_limit_hitting")
            }
        }
        
        // Check subscription status
        if let subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as? SubscriptionManager {
            if subscriptionManager.subscriptionStatus.isInTrialPeriod,
               let daysLeft = subscriptionManager.trialDaysRemaining,
               daysLeft <= 2 {
                churnScore += 0.4
                factors.append("trial_ending_soon")
            }
        }
        
        // Session frequency
        let sessionDuration = getCurrentSessionDuration()
        if sessionDuration < 2 * 60 { // Less than 2 minutes
            churnScore += 0.2
            factors.append("short_session_duration")
        }
        
        // App store rating or feedback (if available)
        // churnScore += 0.1 // Would be based on actual feedback
        
        return (min(1.0, churnScore), factors)
    }
    
    private func determineChurnRisk(factors: (probability: Double, factors: [String])) -> ChurnRisk {
        switch factors.probability {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.6:
            return .medium
        case 0.6..<0.8:
            return .high
        default:
            return .critical
        }
    }
    
    private func getChurnPreventionActions(riskLevel: ChurnRisk) -> [String] {
        switch riskLevel {
        case .low:
            return [
                "Continue monitoring usage patterns",
                "Encourage feature exploration",
                "Send occasional engagement content"
            ]
        case .medium:
            return [
                "Send targeted feature tutorials",
                "Offer usage tips and tricks",
                "Monitor for limit-hitting patterns",
                "Consider in-app guidance"
            ]
        case .high:
            return [
                "Show retention offer",
                "Provide personalized onboarding",
                "Send value reminder notifications",
                "Offer customer support outreach"
            ]
        case .critical:
            return [
                "Immediate retention campaign",
                "Offer discount or extended trial",
                "Direct customer support contact",
                "Gather feedback on pain points",
                "Consider feature customization"
            ]
        }
    }
}

// MARK: - A/B Testing Support

extension MonetizationAnalyticsService {
    
    func trackABTest(_ testName: String, variant: String, parameters: [String: Any]? = nil) async {
        var eventParameters = parameters ?? [:]
        eventParameters["test_name"] = testName
        eventParameters["variant"] = variant
        eventParameters["event_type"] = "ab_test"
        
        await analyticsService.trackEvent("ab_test_exposure", parameters: eventParameters)
    }
    
    func getABTestVariant(for testName: String) -> String {
        // Simple A/B test implementation
        // In production, this would integrate with a proper A/B testing service
        
        let userHash = abs(UIDevice.current.identifierForVendor?.uuidString.hashValue ?? 0)
        let variant = userHash % 2 == 0 ? "A" : "B"
        
        Task {
            await trackABTest(testName, variant: variant)
        }
        
        return variant
    }
}