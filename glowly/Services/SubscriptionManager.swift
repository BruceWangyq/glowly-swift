//
//  SubscriptionManager.swift
//  Glowly
//
//  Central subscription management service coordinating all monetization features
//

import Foundation
import Combine
import StoreKit

protocol SubscriptionManagerProtocol: ObservableObject {
    var subscriptionStatus: SubscriptionStatus { get }
    var availableProducts: [Product] { get }
    var isLoading: Bool { get }
    var purchaseState: PurchaseState { get }
    
    func initializeSubscriptionSystem() async
    func purchaseSubscription(_ tier: SubscriptionTier) async throws -> PurchaseResult
    func purchaseMicrotransaction(_ product: MicrotransactionProduct) async throws -> PurchaseResult
    func restorePurchases() async throws
    func cancelSubscription() async
    func getSubscriptionManagementURL() -> URL?
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool
    func canPerformAction(_ action: UsageAction) -> Bool
    func recordUsage(_ action: UsageAction) async
    func getTrialStatus() -> TrialStatus
    func startFreeTrial() async throws -> PurchaseResult
}

@MainActor
final class SubscriptionManager: SubscriptionManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var subscriptionStatus: SubscriptionStatus
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var purchaseState: PurchaseState = .idle
    
    // MARK: - Private Properties
    
    private let storeKitService: StoreKitServiceProtocol
    private let featureGatingService: FeatureGatingServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        storeKitService: StoreKitServiceProtocol,
        featureGatingService: FeatureGatingServiceProtocol,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.storeKitService = storeKitService
        self.featureGatingService = featureGatingService
        self.analyticsService = analyticsService
        self.subscriptionStatus = storeKitService.subscriptionStatus
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func initializeSubscriptionSystem() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load products from App Store
            try await storeKitService.loadProducts()
            
            // Check current subscription status
            subscriptionStatus = await storeKitService.checkSubscriptionStatus()
            
            // Track subscription system initialization
            await analyticsService.trackEvent("subscription_system_initialized", parameters: [
                "subscription_tier": subscriptionStatus.tier.rawValue,
                "is_premium": subscriptionStatus.isPremium,
                "is_trial": subscriptionStatus.isInTrialPeriod,
                "products_loaded": availableProducts.count
            ])
            
        } catch {
            await analyticsService.trackEvent("subscription_system_init_failed", parameters: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    func purchaseSubscription(_ tier: SubscriptionTier) async throws -> PurchaseResult {
        guard let product = storeKitService.getSubscriptionProduct(for: tier) else {
            throw StoreKitError.productNotFound
        }
        
        // Track purchase attempt
        await analyticsService.trackEvent("subscription_purchase_started", parameters: [
            "tier": tier.rawValue,
            "price": product.price,
            "is_trial_eligible": !subscriptionStatus.isPremium && getTrialStatus() == .notStarted
        ])
        
        do {
            let result = try await storeKitService.purchase(product)
            
            // Track purchase result
            switch result {
            case .success:
                await analyticsService.trackEvent("subscription_purchase_success", parameters: [
                    "tier": tier.rawValue,
                    "price": product.price,
                    "previous_tier": subscriptionStatus.tier.rawValue
                ])
            case .cancelled:
                await analyticsService.trackEvent("subscription_purchase_cancelled", parameters: [
                    "tier": tier.rawValue,
                    "price": product.price
                ])
            case .failed(let error):
                await analyticsService.trackEvent("subscription_purchase_failed", parameters: [
                    "tier": tier.rawValue,
                    "price": product.price,
                    "error": error.localizedDescription
                ])
            case .pending:
                await analyticsService.trackEvent("subscription_purchase_pending", parameters: [
                    "tier": tier.rawValue,
                    "price": product.price
                ])
            }
            
            return result
        } catch {
            await analyticsService.trackEvent("subscription_purchase_error", parameters: [
                "tier": tier.rawValue,
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    func purchaseMicrotransaction(_ product: MicrotransactionProduct) async throws -> PurchaseResult {
        guard let storeProduct = storeKitService.getMicrotransactionProduct(for: product) else {
            throw StoreKitError.productNotFound
        }
        
        // Track microtransaction attempt
        await analyticsService.trackEvent("microtransaction_purchase_started", parameters: [
            "product": product.rawValue,
            "category": product.category.rawValue,
            "price": storeProduct.price
        ])
        
        do {
            let result = try await storeKitService.purchase(storeProduct)
            
            // Track purchase result
            switch result {
            case .success:
                await analyticsService.trackEvent("microtransaction_purchase_success", parameters: [
                    "product": product.rawValue,
                    "category": product.category.rawValue,
                    "price": storeProduct.price
                ])
            case .cancelled:
                await analyticsService.trackEvent("microtransaction_purchase_cancelled", parameters: [
                    "product": product.rawValue,
                    "category": product.category.rawValue
                ])
            case .failed(let error):
                await analyticsService.trackEvent("microtransaction_purchase_failed", parameters: [
                    "product": product.rawValue,
                    "error": error.localizedDescription
                ])
            case .pending:
                await analyticsService.trackEvent("microtransaction_purchase_pending", parameters: [
                    "product": product.rawValue
                ])
            }
            
            return result
        } catch {
            await analyticsService.trackEvent("microtransaction_purchase_error", parameters: [
                "product": product.rawValue,
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    func restorePurchases() async throws {
        await analyticsService.trackEvent("restore_purchases_started")
        
        do {
            try await storeKitService.restorePurchases()
            await analyticsService.trackEvent("restore_purchases_success", parameters: [
                "subscription_tier": subscriptionStatus.tier.rawValue,
                "purchased_products_count": subscriptionStatus.purchasedProducts.count
            ])
        } catch {
            await analyticsService.trackEvent("restore_purchases_failed", parameters: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    func cancelSubscription() async {
        guard subscriptionStatus.isPremium else { return }
        
        await analyticsService.trackEvent("subscription_cancellation_requested", parameters: [
            "current_tier": subscriptionStatus.tier.rawValue,
            "days_until_expiration": subscriptionStatus.daysUntilExpiration ?? 0
        ])
        
        // Note: iOS doesn't allow apps to directly cancel subscriptions
        // Users must go to Settings > Apple ID > Subscriptions
        // We can track the intent and provide guidance
    }
    
    func getSubscriptionManagementURL() -> URL? {
        // iOS Settings URL for managing subscriptions
        return URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool {
        return featureGatingService.canAccessFeature(feature)
    }
    
    func canPerformAction(_ action: UsageAction) -> Bool {
        return featureGatingService.canPerformAction(action)
    }
    
    func recordUsage(_ action: UsageAction) async {
        await featureGatingService.recordUsage(action)
    }
    
    func getTrialStatus() -> TrialStatus {
        return featureGatingService.checkTrialStatus()
    }
    
    func startFreeTrial() async throws -> PurchaseResult {
        // Start with monthly subscription which includes the trial
        return try await purchaseSubscription(.premiumMonthly)
    }
    
    // MARK: - Conversion Optimization
    
    func getOptimalUpgradeOffer(for context: String) -> UpgradeOffer? {
        let trialStatus = getTrialStatus()
        let usagePatterns = getUsagePatterns()
        
        // Personalized upgrade offers based on user behavior
        switch context {
        case "filter_limit_reached":
            if case .notStarted = trialStatus {
                return UpgradeOffer(
                    tier: .premiumMonthly,
                    discountPercentage: 0,
                    headline: "Start Your Free Trial",
                    subheadline: "Get unlimited filters for 7 days free",
                    ctaText: "Start Free Trial"
                )
            } else {
                return UpgradeOffer(
                    tier: .premiumMonthly,
                    discountPercentage: 0,
                    headline: "Unlock Unlimited Filters",
                    subheadline: "Apply as many filters as you want",
                    ctaText: "Upgrade Now"
                )
            }
        case "export_limit_reached":
            if usagePatterns.isHighVolumeUser {
                return UpgradeOffer(
                    tier: .premiumYearly,
                    discountPercentage: 50,
                    headline: "Save 50% with Annual Plan",
                    subheadline: "Unlimited exports + HD quality",
                    ctaText: "Get Annual Plan"
                )
            } else {
                return UpgradeOffer(
                    tier: .premiumMonthly,
                    discountPercentage: 0,
                    headline: "Export Without Limits",
                    subheadline: "Save your creations in HD",
                    ctaText: "Go Premium"
                )
            }
        case "premium_feature_accessed":
            return UpgradeOffer(
                tier: .premiumYearly,
                discountPercentage: 50,
                headline: "Unlock All Premium Features",
                subheadline: "Best value - save 50% annually",
                ctaText: "Get Premium"
            )
        default:
            return getDefaultUpgradeOffer()
        }
    }
    
    func getDefaultUpgradeOffer() -> UpgradeOffer {
        let trialStatus = getTrialStatus()
        
        if case .notStarted = trialStatus {
            return UpgradeOffer(
                tier: .premiumMonthly,
                discountPercentage: 0,
                headline: "Try Premium Free for 7 Days",
                subheadline: "Unlimited everything, cancel anytime",
                ctaText: "Start Free Trial"
            )
        } else {
            return UpgradeOffer(
                tier: .premiumYearly,
                discountPercentage: 50,
                headline: "Go Premium and Save 50%",
                subheadline: "Annual plan with all features included",
                ctaText: "Get Premium"
            )
        }
    }
    
    // MARK: - Analytics & Insights
    
    func getSubscriptionMetrics() -> SubscriptionMetrics {
        return SubscriptionMetrics(
            tier: subscriptionStatus.tier,
            isActive: subscriptionStatus.isActive,
            daysAsSubscriber: getDaysAsSubscriber(),
            totalSpent: getTotalSpent(),
            usagePatterns: getUsagePatterns(),
            conversionTriggers: getConversionTriggers()
        )
    }
    
    func trackPaywallInteraction(_ action: PaywallAction, tier: SubscriptionTier?) async {
        await analyticsService.trackEvent("paywall_interaction", parameters: [
            "action": action.rawValue,
            "tier": tier?.rawValue ?? "",
            "current_subscription": subscriptionStatus.tier.rawValue,
            "trial_status": getTrialStatus().message
        ])
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind StoreKit service updates
        storeKitService.$subscriptionStatus
            .assign(to: \.subscriptionStatus, on: self)
            .store(in: &cancellables)
        
        storeKitService.$products
            .assign(to: \.availableProducts, on: self)
            .store(in: &cancellables)
        
        storeKitService.$purchaseState
            .assign(to: \.purchaseState, on: self)
            .store(in: &cancellables)
        
        storeKitService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    private func getDaysAsSubscriber() -> Int {
        // Calculate days since first subscription
        guard let firstSubscriptionDate = UserDefaults.standard.object(forKey: "first_subscription_date") as? Date else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: firstSubscriptionDate, to: Date()).day ?? 0
    }
    
    private func getTotalSpent() -> Decimal {
        // Calculate total amount spent (would need transaction history)
        let monthlyPrice = SubscriptionTier.premiumMonthly.price
        let yearlyPrice = SubscriptionTier.premiumYearly.price
        
        // This is simplified - in production you'd track actual purchases
        if subscriptionStatus.tier == .premiumYearly {
            return yearlyPrice
        } else if subscriptionStatus.tier == .premiumMonthly {
            return monthlyPrice
        }
        
        return 0.00
    }
    
    private func getUsagePatterns() -> UsagePatterns {
        return UsagePatterns(
            dailyUsage: featureGatingService.dailyUsage,
            limits: featureGatingService.getUsageLimits(),
            isHighVolumeUser: isHighVolumeUser(),
            mostUsedFeatures: getMostUsedFeatures(),
            peakUsageHours: getPeakUsageHours()
        )
    }
    
    private func isHighVolumeUser() -> Bool {
        let usage = featureGatingService.dailyUsage
        return usage.filterApplications > 10 || usage.retouchOperations > 8 || usage.exports > 5
    }
    
    private func getMostUsedFeatures() -> [String] {
        // This would be tracked over time
        return ["filters", "retouch", "export"]
    }
    
    private func getPeakUsageHours() -> [Int] {
        // This would be tracked over time
        return [19, 20, 21] // 7-9 PM
    }
    
    private func getConversionTriggers() -> [String] {
        var triggers: [String] = []
        
        if !canPerformAction(.filterApplication) {
            triggers.append("filter_limit_reached")
        }
        
        if !canPerformAction(.export) {
            triggers.append("export_limit_reached")
        }
        
        if case .active(let days) = getTrialStatus(), days <= 2 {
            triggers.append("trial_ending_soon")
        }
        
        return triggers
    }
}

// MARK: - Supporting Types

struct UpgradeOffer {
    let tier: SubscriptionTier
    let discountPercentage: Int
    let headline: String
    let subheadline: String
    let ctaText: String
}

struct SubscriptionMetrics {
    let tier: SubscriptionTier
    let isActive: Bool
    let daysAsSubscriber: Int
    let totalSpent: Decimal
    let usagePatterns: UsagePatterns
    let conversionTriggers: [String]
}

struct UsagePatterns {
    let dailyUsage: DailyUsage
    let limits: UsageLimits
    let isHighVolumeUser: Bool
    let mostUsedFeatures: [String]
    let peakUsageHours: [Int]
}

enum PaywallAction: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case termsClicked = "terms_clicked"
    case privacyClicked = "privacy_clicked"
    case restoreClicked = "restore_clicked"
    case subscriptionSelected = "subscription_selected"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
}

// MARK: - Convenience Extensions

extension SubscriptionManager {
    
    func getProduct(for tier: SubscriptionTier) -> Product? {
        return availableProducts.first { $0.id == tier.productID }
    }
    
    func getProduct(for microtransaction: MicrotransactionProduct) -> Product? {
        return availableProducts.first { $0.id == microtransaction.productID }
    }
    
    func getLocalizedPrice(for tier: SubscriptionTier) -> String? {
        return getProduct(for: tier)?.displayPrice
    }
    
    func getLocalizedPrice(for product: MicrotransactionProduct) -> String? {
        return getProduct(for: product)?.displayPrice
    }
    
    var isSubscriptionActive: Bool {
        return subscriptionStatus.isActive
    }
    
    var currentTier: SubscriptionTier {
        return subscriptionStatus.tier
    }
    
    var isPremiumUser: Bool {
        return subscriptionStatus.isPremium
    }
    
    var trialDaysRemaining: Int? {
        return subscriptionStatus.daysUntilTrialEnd
    }
}