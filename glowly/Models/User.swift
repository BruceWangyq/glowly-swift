//
//  User.swift
//  Glowly
//
//  User model and preferences
//

import Foundation

/// User profile and preferences
struct User: Identifiable, Codable {
    let id: UUID
    var profile: UserProfile
    var preferences: UserPreferences
    var subscription: SubscriptionInfo?
    var statistics: UserStatistics
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        profile: UserProfile = UserProfile(),
        preferences: UserPreferences = UserPreferences(),
        subscription: SubscriptionInfo? = nil,
        statistics: UserStatistics = UserStatistics(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.profile = profile
        self.preferences = preferences
        self.subscription = subscription
        self.statistics = statistics
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// User profile information
struct UserProfile: Codable {
    var displayName: String?
    var email: String?
    var avatar: Data?
    var skinTone: SkinTone?
    var preferredFilters: [String]
    
    init(
        displayName: String? = nil,
        email: String? = nil,
        avatar: Data? = nil,
        skinTone: SkinTone? = nil,
        preferredFilters: [String] = []
    ) {
        self.displayName = displayName
        self.email = email
        self.avatar = avatar
        self.skinTone = skinTone
        self.preferredFilters = preferredFilters
    }
}

/// User preferences and settings
struct UserPreferences: Codable {
    var autoSaveToLibrary: Bool
    var enableAutoEnhance: Bool
    var defaultEnhancementIntensity: Float
    var enableHapticFeedback: Bool
    var enableSoundEffects: Bool
    var preferredQuality: ImageQuality
    var enableAnalytics: Bool
    var enablePushNotifications: Bool
    var autoBackup: Bool
    var interfaceStyle: InterfaceStyle
    var exportFormat: ExportFormat
    
    init(
        autoSaveToLibrary: Bool = true,
        enableAutoEnhance: Bool = true,
        defaultEnhancementIntensity: Float = 0.5,
        enableHapticFeedback: Bool = true,
        enableSoundEffects: Bool = true,
        preferredQuality: ImageQuality = .high,
        enableAnalytics: Bool = true,
        enablePushNotifications: Bool = true,
        autoBackup: Bool = false,
        interfaceStyle: InterfaceStyle = .system,
        exportFormat: ExportFormat = .jpeg
    ) {
        self.autoSaveToLibrary = autoSaveToLibrary
        self.enableAutoEnhance = enableAutoEnhance
        self.defaultEnhancementIntensity = defaultEnhancementIntensity
        self.enableHapticFeedback = enableHapticFeedback
        self.enableSoundEffects = enableSoundEffects
        self.preferredQuality = preferredQuality
        self.enableAnalytics = enableAnalytics
        self.enablePushNotifications = enablePushNotifications
        self.autoBackup = autoBackup
        self.interfaceStyle = interfaceStyle
        self.exportFormat = exportFormat
    }
}

/// Subscription information
struct SubscriptionInfo: Codable {
    let type: SubscriptionType
    let startDate: Date
    let expiryDate: Date?
    let isActive: Bool
    let features: [PremiumFeature]
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
    
    var daysRemaining: Int? {
        guard let expiryDate = expiryDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return components.day
    }
}

/// User usage statistics
struct UserStatistics: Codable {
    var photosProcessed: Int
    var enhancementsApplied: Int
    var favoriteEnhancements: [EnhancementType]
    var totalProcessingTime: TimeInterval
    var lastActiveDate: Date
    var sessionsCount: Int
    var averageSessionDuration: TimeInterval
    
    init(
        photosProcessed: Int = 0,
        enhancementsApplied: Int = 0,
        favoriteEnhancements: [EnhancementType] = [],
        totalProcessingTime: TimeInterval = 0,
        lastActiveDate: Date = Date(),
        sessionsCount: Int = 0,
        averageSessionDuration: TimeInterval = 0
    ) {
        self.photosProcessed = photosProcessed
        self.enhancementsApplied = enhancementsApplied
        self.favoriteEnhancements = favoriteEnhancements
        self.totalProcessingTime = totalProcessingTime
        self.lastActiveDate = lastActiveDate
        self.sessionsCount = sessionsCount
        self.averageSessionDuration = averageSessionDuration
    }
}

/// Subscription types
enum SubscriptionType: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        case .pro:
            return "Pro"
        }
    }
    
    var monthlyPrice: Decimal {
        switch self {
        case .free:
            return 0.00
        case .premium:
            return 4.99
        case .pro:
            return 9.99
        }
    }
}

/// Premium features
enum PremiumFeature: String, Codable, CaseIterable {
    case unlimitedProcessing = "unlimited_processing"
    case advancedFilters = "advanced_filters"
    case aiEnhancements = "ai_enhancements"
    case batchProcessing = "batch_processing"
    case cloudBackup = "cloud_backup"
    case prioritySupport = "priority_support"
    case noWatermark = "no_watermark"
    case exportHighRes = "export_high_res"
    
    var displayName: String {
        switch self {
        case .unlimitedProcessing:
            return "Unlimited Processing"
        case .advancedFilters:
            return "Advanced Filters"
        case .aiEnhancements:
            return "AI Enhancements"
        case .batchProcessing:
            return "Batch Processing"
        case .cloudBackup:
            return "Cloud Backup"
        case .prioritySupport:
            return "Priority Support"
        case .noWatermark:
            return "No Watermark"
        case .exportHighRes:
            return "High-Res Export"
        }
    }
}

/// Skin tone for personalized enhancements
enum SkinTone: String, Codable, CaseIterable {
    case veryLight = "very_light"
    case light = "light"
    case medium = "medium"
    case tan = "tan"
    case dark = "dark"
    case veryDark = "very_dark"
    
    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Image quality settings
enum ImageQuality: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var compressionQuality: Float {
        switch self {
        case .low:
            return 0.5
        case .medium:
            return 0.7
        case .high:
            return 0.9
        case .ultra:
            return 1.0
        }
    }
}

/// Interface style preference
enum InterfaceStyle: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

/// Export format options
enum ExportFormat: String, Codable, CaseIterable {
    case jpeg = "jpeg"
    case png = "png"
    case heic = "heic"
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var fileExtension: String {
        rawValue
    }
}