//
//  SubscriptionModels.swift
//  Glowly
//
//  Subscription and monetization models for freemium functionality
//

import Foundation
import StoreKit

// MARK: - Subscription Tiers

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premiumMonthly:
            return "Premium Monthly"
        case .premiumYearly:
            return "Premium Yearly"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "Basic filters and limited retouch tools"
        case .premiumMonthly:
            return "Unlimited tools, exclusive content, HD export"
        case .premiumYearly:
            return "All premium features with annual savings"
        }
    }
    
    var price: Decimal {
        switch self {
        case .free:
            return 0.00
        case .premiumMonthly:
            return 4.99
        case .premiumYearly:
            return 29.99
        }
    }
    
    var productID: String {
        switch self {
        case .free:
            return ""
        case .premiumMonthly:
            return "com.novuxlab.glowly.premium.monthly"
        case .premiumYearly:
            return "com.novuxlab.glowly.premium.yearly"
        }
    }
    
    var trialDays: Int {
        switch self {
        case .free:
            return 0
        case .premiumMonthly, .premiumYearly:
            return 7
        }
    }
    
    var isPremium: Bool {
        return self != .free
    }
}

// MARK: - Feature Permissions

enum PremiumFeature: String, CaseIterable, Codable {
    // Basic Enhancement
    case unlimitedFilters = "unlimited_filters"
    case unlimitedRetouch = "unlimited_retouch"
    case advancedBeautyTools = "advanced_beauty_tools"
    
    // Export & Quality
    case hdExport = "hd_export"
    case fourKExport = "4k_export"
    case rawExport = "raw_export"
    case watermarkRemoval = "watermark_removal"
    
    // Content & Filters
    case exclusiveFilters = "exclusive_filters"
    case premiumMakeupPacks = "premium_makeup_packs"
    case seasonalCollections = "seasonal_collections"
    case professionalPresets = "professional_presets"
    
    // Advanced Features
    case batchProcessing = "batch_processing"
    case cloudStorage = "cloud_storage"
    case advancedManualRetouch = "advanced_manual_retouch"
    case aiSkinAnalysis = "ai_skin_analysis"
    case customFilterCreation = "custom_filter_creation"
    
    // Sharing & Social
    case brandedSharing = "branded_sharing"
    case socialScheduling = "social_scheduling"
    case portfolioMode = "portfolio_mode"
    
    var displayName: String {
        switch self {
        case .unlimitedFilters:
            return "Unlimited Filters"
        case .unlimitedRetouch:
            return "Unlimited Retouching"
        case .advancedBeautyTools:
            return "Advanced Beauty Tools"
        case .hdExport:
            return "HD Export"
        case .fourKExport:
            return "4K Export"
        case .rawExport:
            return "RAW Export"
        case .watermarkRemoval:
            return "No Watermark"
        case .exclusiveFilters:
            return "Exclusive Filters"
        case .premiumMakeupPacks:
            return "Premium Makeup"
        case .seasonalCollections:
            return "Seasonal Collections"
        case .professionalPresets:
            return "Pro Presets"
        case .batchProcessing:
            return "Batch Processing"
        case .cloudStorage:
            return "Cloud Storage"
        case .advancedManualRetouch:
            return "Advanced Retouch"
        case .aiSkinAnalysis:
            return "AI Skin Analysis"
        case .customFilterCreation:
            return "Custom Filters"
        case .brandedSharing:
            return "Branded Sharing"
        case .socialScheduling:
            return "Social Scheduling"
        case .portfolioMode:
            return "Portfolio Mode"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedFilters:
            return "Apply unlimited filters without daily limits"
        case .unlimitedRetouch:
            return "Use retouching tools without restrictions"
        case .advancedBeautyTools:
            return "Access professional-grade beauty enhancement tools"
        case .hdExport:
            return "Export photos in high definition quality"
        case .fourKExport:
            return "Export in ultra-high 4K resolution"
        case .rawExport:
            return "Export uncompressed RAW files"
        case .watermarkRemoval:
            return "Remove Glowly watermark from exports"
        case .exclusiveFilters:
            return "Access to premium-only filter collections"
        case .premiumMakeupPacks:
            return "Professional makeup application packs"
        case .seasonalCollections:
            return "Limited-time seasonal filter collections"
        case .professionalPresets:
            return "Curated presets by professional photographers"
        case .batchProcessing:
            return "Apply effects to multiple photos at once"
        case .cloudStorage:
            return "Store your creations in the cloud"
        case .advancedManualRetouch:
            return "Precise manual retouching tools"
        case .aiSkinAnalysis:
            return "AI-powered skin analysis and recommendations"
        case .customFilterCreation:
            return "Create and save custom filter combinations"
        case .brandedSharing:
            return "Share with your personal branding"
        case .socialScheduling:
            return "Schedule posts to social media"
        case .portfolioMode:
            return "Showcase your work in portfolio format"
        }
    }
}

// MARK: - Microtransaction Products

enum MicrotransactionProduct: String, CaseIterable, Codable {
    // Individual Filter Packs
    case vintageFilters = "vintage_filters_pack"
    case cinematicFilters = "cinematic_filters_pack"
    case portraitFilters = "portrait_filters_pack"
    case fashionFilters = "fashion_filters_pack"
    
    // Makeup Packs
    case glowMakeup = "glow_makeup_pack"
    case dramaticMakeup = "dramatic_makeup_pack"
    case naturalMakeup = "natural_makeup_pack"
    case festivalMakeup = "festival_makeup_pack"
    
    // Special Collections
    case weddingCollection = "wedding_collection"
    case holidayCollection = "holiday_collection"
    case summerCollection = "summer_collection"
    case influencerPack = "influencer_pack"
    
    // Tool Packs
    case advancedRetouchPack = "advanced_retouch_pack"
    case professionalToolsPack = "professional_tools_pack"
    
    var displayName: String {
        switch self {
        case .vintageFilters:
            return "Vintage Filters"
        case .cinematicFilters:
            return "Cinematic Filters"
        case .portraitFilters:
            return "Portrait Filters"
        case .fashionFilters:
            return "Fashion Filters"
        case .glowMakeup:
            return "Glow Makeup"
        case .dramaticMakeup:
            return "Dramatic Makeup"
        case .naturalMakeup:
            return "Natural Makeup"
        case .festivalMakeup:
            return "Festival Makeup"
        case .weddingCollection:
            return "Wedding Collection"
        case .holidayCollection:
            return "Holiday Collection"
        case .summerCollection:
            return "Summer Collection"
        case .influencerPack:
            return "Influencer Pack"
        case .advancedRetouchPack:
            return "Advanced Retouch"
        case .professionalToolsPack:
            return "Professional Tools"
        }
    }
    
    var description: String {
        switch self {
        case .vintageFilters:
            return "Classic vintage-inspired filters with film grain effects"
        case .cinematicFilters:
            return "Movie-quality color grading and cinematic looks"
        case .portraitFilters:
            return "Perfect filters for portrait photography"
        case .fashionFilters:
            return "High-fashion editorial style filters"
        case .glowMakeup:
            return "Natural glow and radiant makeup looks"
        case .dramaticMakeup:
            return "Bold and dramatic makeup effects"
        case .naturalMakeup:
            return "Subtle, everyday makeup enhancement"
        case .festivalMakeup:
            return "Creative festival and party makeup"
        case .weddingCollection:
            return "Romantic filters perfect for weddings"
        case .holidayCollection:
            return "Festive holiday-themed effects"
        case .summerCollection:
            return "Bright and vibrant summer vibes"
        case .influencerPack:
            return "Trending filters used by top influencers"
        case .advancedRetouchPack:
            return "Professional retouching tools and techniques"
        case .professionalToolsPack:
            return "Industry-standard professional tools"
        }
    }
    
    var price: Decimal {
        switch self {
        case .vintageFilters, .cinematicFilters, .portraitFilters, .fashionFilters:
            return 0.99
        case .glowMakeup, .naturalMakeup:
            return 1.99
        case .dramaticMakeup, .festivalMakeup:
            return 2.99
        case .weddingCollection, .holidayCollection, .summerCollection:
            return 2.99
        case .influencerPack:
            return 4.99
        case .advancedRetouchPack, .professionalToolsPack:
            return 3.99
        }
    }
    
    var productID: String {
        return "com.novuxlab.glowly.pack.\(rawValue)"
    }
    
    var category: MicrotransactionCategory {
        switch self {
        case .vintageFilters, .cinematicFilters, .portraitFilters, .fashionFilters:
            return .filters
        case .glowMakeup, .dramaticMakeup, .naturalMakeup, .festivalMakeup:
            return .makeup
        case .weddingCollection, .holidayCollection, .summerCollection, .influencerPack:
            return .collections
        case .advancedRetouchPack, .professionalToolsPack:
            return .tools
        }
    }
}

enum MicrotransactionCategory: String, CaseIterable {
    case filters = "filters"
    case makeup = "makeup"
    case collections = "collections"
    case tools = "tools"
    
    var displayName: String {
        switch self {
        case .filters:
            return "Filters"
        case .makeup:
            return "Makeup"
        case .collections:
            return "Collections"
        case .tools:
            return "Tools"
        }
    }
}

// MARK: - Usage Limits

struct UsageLimits: Codable {
    let dailyFilterApplications: Int
    let dailyRetouchOperations: Int
    let dailyExports: Int
    let maxCloudStorageGB: Int
    let maxBatchSize: Int
    
    static let free = UsageLimits(
        dailyFilterApplications: 5,
        dailyRetouchOperations: 3,
        dailyExports: 2,
        maxCloudStorageGB: 0,
        maxBatchSize: 1
    )
    
    static let premium = UsageLimits(
        dailyFilterApplications: -1, // -1 means unlimited
        dailyRetouchOperations: -1,
        dailyExports: -1,
        maxCloudStorageGB: 10,
        maxBatchSize: 50
    )
}

// MARK: - Subscription Status

struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let expirationDate: Date?
    let isInTrialPeriod: Bool
    let trialEndDate: Date?
    let purchasedProducts: Set<String>
    let lastReceiptValidation: Date?
    
    var isPremium: Bool {
        return tier.isPremium && isActive
    }
    
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    var daysUntilTrialEnd: Int? {
        guard let trialEndDate = trialEndDate, isInTrialPeriod else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day
    }
}

// MARK: - Daily Usage Tracking

struct DailyUsage: Codable {
    let date: Date
    var filterApplications: Int
    var retouchOperations: Int
    var exports: Int
    
    init(date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
        self.filterApplications = 0
        self.retouchOperations = 0
        self.exports = 0
    }
    
    func isWithinLimits(_ limits: UsageLimits) -> Bool {
        let filterWithinLimit = limits.dailyFilterApplications == -1 || filterApplications < limits.dailyFilterApplications
        let retouchWithinLimit = limits.dailyRetouchOperations == -1 || retouchOperations < limits.dailyRetouchOperations
        let exportWithinLimit = limits.dailyExports == -1 || exports < limits.dailyExports
        
        return filterWithinLimit && retouchWithinLimit && exportWithinLimit
    }
    
    func canPerformAction(_ action: UsageAction, limits: UsageLimits) -> Bool {
        switch action {
        case .filterApplication:
            return limits.dailyFilterApplications == -1 || filterApplications < limits.dailyFilterApplications
        case .retouchOperation:
            return limits.dailyRetouchOperations == -1 || retouchOperations < limits.dailyRetouchOperations
        case .export:
            return limits.dailyExports == -1 || exports < limits.dailyExports
        }
    }
}

enum UsageAction: String, CaseIterable {
    case filterApplication = "filter_application"
    case retouchOperation = "retouch_operation"
    case export = "export"
    
    var displayName: String {
        switch self {
        case .filterApplication:
            return "Filter Application"
        case .retouchOperation:
            return "Retouch Operation"
        case .export:
            return "Export"
        }
    }
}

// MARK: - Trial Configuration

struct TrialConfiguration {
    static let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    static let reminderDays: [Int] = [6, 3, 1] // Days before trial ends to show reminders
    static let gracePeriodHours: Int = 24 // Hours after trial ends before full restriction
}

// MARK: - Pricing Display

struct PricingDisplay {
    let tier: SubscriptionTier
    let localizedPrice: String
    let savingsPercentage: Int?
    let featuresIncluded: [PremiumFeature]
    
    static func displayForTier(_ tier: SubscriptionTier, product: Product? = nil) -> PricingDisplay {
        let localizedPrice = product?.displayPrice ?? tier.price.formatted(.currency(code: "USD"))
        let savingsPercentage = tier == .premiumYearly ? 50 : nil
        
        let features: [PremiumFeature]
        switch tier {
        case .free:
            features = []
        case .premiumMonthly, .premiumYearly:
            features = [
                .unlimitedFilters,
                .unlimitedRetouch,
                .hdExport,
                .exclusiveFilters,
                .watermarkRemoval,
                .premiumMakeupPacks,
                .batchProcessing,
                .cloudStorage
            ]
        }
        
        return PricingDisplay(
            tier: tier,
            localizedPrice: localizedPrice,
            savingsPercentage: savingsPercentage,
            featuresIncluded: features
        )
    }
}