//
//  FeatureGatingService.swift
//  Glowly
//
//  Feature gating and usage limit management for freemium functionality
//

import Foundation
import Combine

protocol FeatureGatingServiceProtocol: ObservableObject {
    var dailyUsage: DailyUsage { get }
    var subscriptionStatus: SubscriptionStatus { get }
    
    func canAccessFeature(_ feature: PremiumFeature) -> Bool
    func canPerformAction(_ action: UsageAction) -> Bool
    func recordUsage(_ action: UsageAction) async
    func getRemainingUsage(_ action: UsageAction) -> Int?
    func getUsageLimits() -> UsageLimits
    func checkTrialStatus() -> TrialStatus
    func shouldShowUpgradePrompt(for feature: PremiumFeature) -> Bool
    func shouldShowUpgradePrompt(for action: UsageAction) -> Bool
}

enum TrialStatus {
    case notStarted
    case active(daysRemaining: Int)
    case expired(daysAgo: Int)
    case notEligible
    
    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }
    
    var message: String {
        switch self {
        case .notStarted:
            return "Start your 7-day free trial"
        case .active(let days):
            return "\(days) days left in trial"
        case .expired(let days):
            return "Trial expired \(days) days ago"
        case .notEligible:
            return "Trial not available"
        }
    }
}

struct UpgradePromptContext {
    let feature: PremiumFeature?
    let action: UsageAction?
    let currentUsage: Int
    let limit: Int
    let suggestedTier: SubscriptionTier
    let promptType: PromptType
    
    enum PromptType {
        case limitReached
        case limitWarning(remaining: Int)
        case featureLocked
        case trialEnding(daysLeft: Int)
        case trialExpired
    }
}

@MainActor
final class FeatureGatingService: FeatureGatingServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var dailyUsage: DailyUsage
    @Published private(set) var subscriptionStatus: SubscriptionStatus
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let storeKitService: StoreKitServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let usageStorageKey = "daily_usage_storage"
    private let trialStartDateKey = "trial_start_date"
    private let upgradePromptCountKey = "upgrade_prompt_count"
    private let lastPromptDateKey = "last_prompt_date"
    
    // MARK: - Initialization
    
    init(
        storeKitService: StoreKitServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.storeKitService = storeKitService
        self.userDefaults = userDefaults
        self.subscriptionStatus = storeKitService.subscriptionStatus
        self.dailyUsage = Self.loadDailyUsage(from: userDefaults)
        
        // Subscribe to subscription status changes
        storeKitService.$subscriptionStatus
            .assign(to: \.subscriptionStatus, on: self)
            .store(in: &cancellables)
        
        // Reset daily usage if it's a new day
        resetDailyUsageIfNeeded()
    }
    
    // MARK: - Feature Access
    
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        // Premium users can access all features
        if subscriptionStatus.isPremium {
            return true
        }
        
        // Check if user purchased specific microtransaction for this feature
        if let requiredProduct = getRequiredProduct(for: feature),
           subscriptionStatus.purchasedProducts.contains(requiredProduct.productID) {
            return true
        }
        
        // Free users cannot access premium features
        return false
    }
    
    func canPerformAction(_ action: UsageAction) -> Bool {
        let limits = getUsageLimits()
        return dailyUsage.canPerformAction(action, limits: limits)
    }
    
    func recordUsage(_ action: UsageAction) async {
        guard canPerformAction(action) else { return }
        
        switch action {
        case .filterApplication:
            dailyUsage.filterApplications += 1
        case .retouchOperation:
            dailyUsage.retouchOperations += 1
        case .export:
            dailyUsage.exports += 1
        }
        
        saveDailyUsage()
        
        // Track analytics
        await trackUsageAnalytics(action)
    }
    
    func getRemainingUsage(_ action: UsageAction) -> Int? {
        let limits = getUsageLimits()
        
        switch action {
        case .filterApplication:
            guard limits.dailyFilterApplications != -1 else { return nil }
            return max(0, limits.dailyFilterApplications - dailyUsage.filterApplications)
        case .retouchOperation:
            guard limits.dailyRetouchOperations != -1 else { return nil }
            return max(0, limits.dailyRetouchOperations - dailyUsage.retouchOperations)
        case .export:
            guard limits.dailyExports != -1 else { return nil }
            return max(0, limits.dailyExports - dailyUsage.exports)
        }
    }
    
    func getUsageLimits() -> UsageLimits {
        return subscriptionStatus.isPremium ? .premium : .free
    }
    
    // MARK: - Trial Management
    
    func checkTrialStatus() -> TrialStatus {
        // If user is already premium, trial is not relevant
        if subscriptionStatus.isPremium && !subscriptionStatus.isInTrialPeriod {
            return .notEligible
        }
        
        // If currently in trial period
        if subscriptionStatus.isInTrialPeriod,
           let trialEndDate = subscriptionStatus.trialEndDate {
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
            return daysRemaining > 0 ? .active(daysRemaining: daysRemaining) : .expired(daysAgo: -daysRemaining)
        }
        
        // Check if user has started trial before
        if let trialStartDate = userDefaults.object(forKey: trialStartDateKey) as? Date {
            let trialEndDate = trialStartDate.addingTimeInterval(TrialConfiguration.trialDuration)
            let daysFromEnd = Calendar.current.dateComponents([.day], from: trialEndDate, to: Date()).day ?? 0
            
            if Date() > trialEndDate {
                return .expired(daysAgo: daysFromEnd)
            } else {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
                return .active(daysRemaining: daysRemaining)
            }
        }
        
        return .notStarted
    }
    
    func startTrial() {
        guard checkTrialStatus() == .notStarted else { return }
        userDefaults.set(Date(), forKey: trialStartDateKey)
    }
    
    // MARK: - Upgrade Prompts
    
    func shouldShowUpgradePrompt(for feature: PremiumFeature) -> Bool {
        // Don't show prompts to premium users
        guard !subscriptionStatus.isPremium else { return false }
        
        // Check if user can access feature through microtransaction
        if canAccessFeature(feature) { return false }
        
        // Check prompt frequency limits
        return shouldShowPromptBasedOnFrequency()
    }
    
    func shouldShowUpgradePrompt(for action: UsageAction) -> Bool {
        // Don't show prompts to premium users
        guard !subscriptionStatus.isPremium else { return false }
        
        // Check if action can be performed
        if canPerformAction(action) { return false }
        
        // Check prompt frequency limits
        return shouldShowPromptBasedOnFrequency()
    }
    
    func getUpgradePromptContext(for feature: PremiumFeature) -> UpgradePromptContext? {
        guard shouldShowUpgradePrompt(for: feature) else { return nil }
        
        return UpgradePromptContext(
            feature: feature,
            action: nil,
            currentUsage: 0,
            limit: 0,
            suggestedTier: .premiumMonthly,
            promptType: .featureLocked
        )
    }
    
    func getUpgradePromptContext(for action: UsageAction) -> UpgradePromptContext? {
        guard shouldShowUpgradePrompt(for: action) else { return nil }
        
        let limits = getUsageLimits()
        let currentUsage: Int
        let limit: Int
        
        switch action {
        case .filterApplication:
            currentUsage = dailyUsage.filterApplications
            limit = limits.dailyFilterApplications
        case .retouchOperation:
            currentUsage = dailyUsage.retouchOperations
            limit = limits.dailyRetouchOperations
        case .export:
            currentUsage = dailyUsage.exports
            limit = limits.dailyExports
        }
        
        let promptType: UpgradePromptContext.PromptType
        if currentUsage >= limit {
            promptType = .limitReached
        } else {
            let remaining = limit - currentUsage
            promptType = .limitWarning(remaining: remaining)
        }
        
        // Check trial status for additional context
        let trialStatus = checkTrialStatus()
        let finalPromptType: UpgradePromptContext.PromptType
        switch trialStatus {
        case .active(let days) where days <= 3:
            finalPromptType = .trialEnding(daysLeft: days)
        case .expired:
            finalPromptType = .trialExpired
        default:
            finalPromptType = promptType
        }
        
        return UpgradePromptContext(
            feature: nil,
            action: action,
            currentUsage: currentUsage,
            limit: limit,
            suggestedTier: .premiumMonthly,
            promptType: finalPromptType
        )
    }
    
    func recordUpgradePromptShown() {
        let currentCount = userDefaults.integer(forKey: upgradePromptCountKey)
        userDefaults.set(currentCount + 1, forKey: upgradePromptCountKey)
        userDefaults.set(Date(), forKey: lastPromptDateKey)
    }
    
    // MARK: - Private Methods
    
    private func shouldShowPromptBasedOnFrequency() -> Bool {
        let promptCount = userDefaults.integer(forKey: upgradePromptCountKey)
        let lastPromptDate = userDefaults.object(forKey: lastPromptDateKey) as? Date
        
        // Limit prompts based on frequency
        let maxPromptsPerDay = 3
        let minHoursBetweenPrompts: TimeInterval = 4 * 60 * 60 // 4 hours
        
        // Check daily limit
        if let lastPrompt = lastPromptDate,
           Calendar.current.isDate(lastPrompt, inSameDayAs: Date()) {
            let todayPrompts = promptCount // This would need more sophisticated tracking for actual daily count
            if todayPrompts >= maxPromptsPerDay {
                return false
            }
        }
        
        // Check time between prompts
        if let lastPrompt = lastPromptDate,
           Date().timeIntervalSince(lastPrompt) < minHoursBetweenPrompts {
            return false
        }
        
        return true
    }
    
    private func getRequiredProduct(for feature: PremiumFeature) -> MicrotransactionProduct? {
        // Map features to required microtransaction products
        switch feature {
        case .exclusiveFilters:
            return .vintageFilters // Example mapping
        case .premiumMakeupPacks:
            return .glowMakeup
        case .advancedManualRetouch:
            return .advancedRetouchPack
        case .professionalPresets:
            return .professionalToolsPack
        default:
            return nil // These features are subscription-only
        }
    }
    
    private func resetDailyUsageIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let usageDate = Calendar.current.startOfDay(for: dailyUsage.date)
        
        if today > usageDate {
            dailyUsage = DailyUsage()
            saveDailyUsage()
        }
    }
    
    private func saveDailyUsage() {
        do {
            let data = try JSONEncoder().encode(dailyUsage)
            userDefaults.set(data, forKey: usageStorageKey)
        } catch {
            print("Failed to save daily usage: \(error)")
        }
    }
    
    private static func loadDailyUsage(from userDefaults: UserDefaults) -> DailyUsage {
        guard let data = userDefaults.data(forKey: "daily_usage_storage"),
              let usage = try? JSONDecoder().decode(DailyUsage.self, from: data) else {
            return DailyUsage()
        }
        
        // Check if it's a new day
        let today = Calendar.current.startOfDay(for: Date())
        let usageDate = Calendar.current.startOfDay(for: usage.date)
        
        if today > usageDate {
            return DailyUsage()
        }
        
        return usage
    }
    
    private func trackUsageAnalytics(_ action: UsageAction) async {
        // Track usage analytics for conversion optimization
        let analyticsService = DIContainer.shared.resolve(AnalyticsServiceProtocol.self)
        
        await analyticsService.trackEvent("usage_recorded", parameters: [
            "action": action.rawValue,
            "subscription_tier": subscriptionStatus.tier.rawValue,
            "is_premium": subscriptionStatus.isPremium,
            "remaining_limit": getRemainingUsage(action) ?? -1
        ])
        
        // Track when user is approaching limits
        if let remaining = getRemainingUsage(action), remaining <= 1 {
            await analyticsService.trackEvent("usage_limit_warning", parameters: [
                "action": action.rawValue,
                "remaining": remaining
            ])
        }
    }
}

// MARK: - Usage Tracking Helper

extension FeatureGatingService {
    
    func getUsageProgress(for action: UsageAction) -> Double {
        let limits = getUsageLimits()
        let current: Int
        let limit: Int
        
        switch action {
        case .filterApplication:
            current = dailyUsage.filterApplications
            limit = limits.dailyFilterApplications
        case .retouchOperation:
            current = dailyUsage.retouchOperations
            limit = limits.dailyRetouchOperations
        case .export:
            current = dailyUsage.exports
            limit = limits.dailyExports
        }
        
        guard limit > 0 else { return 0.0 }
        return min(1.0, Double(current) / Double(limit))
    }
    
    func getUsageDescription(for action: UsageAction) -> String {
        if subscriptionStatus.isPremium {
            return "Unlimited"
        }
        
        guard let remaining = getRemainingUsage(action) else {
            return "Unlimited"
        }
        
        if remaining == 0 {
            return "Limit reached"
        }
        
        return "\(remaining) remaining today"
    }
}

// MARK: - Feature Bundling

extension FeatureGatingService {
    
    func getFeatureBundle(for category: MicrotransactionCategory) -> [PremiumFeature] {
        switch category {
        case .filters:
            return [.exclusiveFilters]
        case .makeup:
            return [.premiumMakeupPacks]
        case .collections:
            return [.seasonalCollections, .professionalPresets]
        case .tools:
            return [.advancedManualRetouch, .customFilterCreation]
        }
    }
    
    func suggestMicrotransaction(for feature: PremiumFeature) -> MicrotransactionProduct? {
        return getRequiredProduct(for: feature)
    }
    
    func suggestSubscription(for features: [PremiumFeature]) -> SubscriptionTier {
        // If user wants multiple premium features, suggest subscription
        let premiumFeatureCount = features.filter { !canAccessFeature($0) }.count
        
        if premiumFeatureCount >= 3 {
            return .premiumYearly // Better value for multiple features
        } else {
            return .premiumMonthly
        }
    }
}