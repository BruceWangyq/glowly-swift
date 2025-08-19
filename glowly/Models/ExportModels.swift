//
//  ExportModels.swift
//  Glowly
//
//  Comprehensive export models for photo sharing and export functionality
//

import Foundation
import SwiftUI
import Photos

// MARK: - Export Quality Settings

/// Quality settings for photo export
enum ExportQuality: String, CaseIterable, Codable {
    case original = "Original"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .original:
            return "Full resolution, no compression"
        case .high:
            return "High quality, minimal compression"
        case .medium:
            return "Balanced quality and file size"
        case .low:
            return "Smaller file size, more compression"
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .original:
            return 1.0
        case .high:
            return 0.9
        case .medium:
            return 0.75
        case .low:
            return 0.6
        }
    }
    
    var maxDimension: CGFloat? {
        switch self {
        case .original:
            return nil
        case .high:
            return 4096
        case .medium:
            return 2048
        case .low:
            return 1024
        }
    }
}

// MARK: - Export Formats

/// Supported export formats
enum ExportFormat: String, CaseIterable, Codable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    
    var displayName: String {
        return rawValue
    }
    
    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        }
    }
    
    var mimeType: String {
        switch self {
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .heic:
            return "image/heic"
        }
    }
    
    var supportsTransparency: Bool {
        switch self {
        case .jpeg:
            return false
        case .png, .heic:
            return true
        }
    }
}

// MARK: - Social Media Platforms

/// Social media platform specifications
enum SocialMediaPlatform: String, CaseIterable, Codable {
    case instagram = "Instagram"
    case instagramStory = "Instagram Story"
    case tiktok = "TikTok"
    case snapchat = "Snapchat"
    case facebook = "Facebook"
    case twitter = "Twitter"
    case pinterest = "Pinterest"
    case linkedin = "LinkedIn"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .instagram, .instagramStory:
            return "camera.macro"
        case .tiktok:
            return "music.note"
        case .snapchat:
            return "camera.circle"
        case .facebook:
            return "person.2.circle"
        case .twitter:
            return "bubble.left.and.bubble.right"
        case .pinterest:
            return "pin.circle"
        case .linkedin:
            return "briefcase.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram, .instagramStory:
            return Color.purple
        case .tiktok:
            return Color.black
        case .snapchat:
            return Color.yellow
        case .facebook:
            return Color.blue
        case .twitter:
            return Color.cyan
        case .pinterest:
            return Color.red
        case .linkedin:
            return Color.blue
        }
    }
    
    var optimalDimensions: CGSize {
        switch self {
        case .instagram:
            return CGSize(width: 1080, height: 1080)
        case .instagramStory:
            return CGSize(width: 1080, height: 1920)
        case .tiktok:
            return CGSize(width: 1080, height: 1920)
        case .snapchat:
            return CGSize(width: 1080, height: 1920)
        case .facebook:
            return CGSize(width: 1200, height: 630)
        case .twitter:
            return CGSize(width: 1200, height: 675)
        case .pinterest:
            return CGSize(width: 1000, height: 1500)
        case .linkedin:
            return CGSize(width: 1200, height: 627)
        }
    }
    
    var aspectRatio: CGFloat {
        let dimensions = optimalDimensions
        return dimensions.width / dimensions.height
    }
    
    var maxFileSize: Int {
        switch self {
        case .instagram, .instagramStory:
            return 30_000_000 // 30MB
        case .tiktok:
            return 500_000_000 // 500MB
        case .snapchat:
            return 32_000_000 // 32MB
        case .facebook:
            return 30_000_000 // 30MB
        case .twitter:
            return 5_000_000 // 5MB
        case .pinterest:
            return 20_000_000 // 20MB
        case .linkedin:
            return 10_000_000 // 10MB
        }
    }
    
    var supportedFormats: [ExportFormat] {
        switch self {
        case .instagram, .instagramStory, .facebook, .twitter, .pinterest, .linkedin:
            return [.jpeg, .png]
        case .tiktok, .snapchat:
            return [.jpeg, .png, .heic]
        }
    }
    
    var recommendedFormat: ExportFormat {
        switch self {
        case .instagram, .instagramStory, .facebook, .twitter, .pinterest, .linkedin:
            return .jpeg
        case .tiktok, .snapchat:
            return .jpeg
        }
    }
}

// MARK: - Watermark Options

/// Watermark configuration
struct WatermarkOptions: Codable {
    let enabled: Bool
    let text: String
    let position: WatermarkPosition
    let style: WatermarkStyle
    let opacity: CGFloat
    let size: WatermarkSize
    
    init(
        enabled: Bool = true,
        text: String = "✨ Enhanced with Glowly",
        position: WatermarkPosition = .bottomRight,
        style: WatermarkStyle = .subtle,
        opacity: CGFloat = 0.8,
        size: WatermarkSize = .medium
    ) {
        self.enabled = enabled
        self.text = text
        self.position = position
        self.style = style
        self.opacity = opacity
        self.size = size
    }
}

enum WatermarkPosition: String, CaseIterable, Codable {
    case topLeft = "top_left"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"
    case center = "center"
    
    var displayName: String {
        switch self {
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        case .center:
            return "Center"
        }
    }
    
    func calculatePosition(in size: CGSize, textSize: CGSize, padding: CGFloat = 20) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: padding, y: padding)
        case .topRight:
            return CGPoint(x: size.width - textSize.width - padding, y: padding)
        case .bottomLeft:
            return CGPoint(x: padding, y: size.height - textSize.height - padding)
        case .bottomRight:
            return CGPoint(x: size.width - textSize.width - padding, y: size.height - textSize.height - padding)
        case .center:
            return CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2)
        }
    }
}

enum WatermarkStyle: String, CaseIterable, Codable {
    case subtle = "subtle"
    case bold = "bold"
    case outlined = "outlined"
    case shadowed = "shadowed"
    
    var displayName: String {
        switch self {
        case .subtle:
            return "Subtle"
        case .bold:
            return "Bold"
        case .outlined:
            return "Outlined"
        case .shadowed:
            return "Shadowed"
        }
    }
}

enum WatermarkSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 18
        case .large:
            return 24
        }
    }
}

// MARK: - Export Configuration

/// Complete export configuration
struct ExportConfiguration: Codable {
    let quality: ExportQuality
    let format: ExportFormat
    let platform: SocialMediaPlatform?
    let customDimensions: CGSize?
    let watermark: WatermarkOptions
    let preserveMetadata: Bool
    let includeEnhancementHistory: Bool
    
    init(
        quality: ExportQuality = .high,
        format: ExportFormat = .jpeg,
        platform: SocialMediaPlatform? = nil,
        customDimensions: CGSize? = nil,
        watermark: WatermarkOptions = WatermarkOptions(),
        preserveMetadata: Bool = true,
        includeEnhancementHistory: Bool = true
    ) {
        self.quality = quality
        self.format = format
        self.platform = platform
        self.customDimensions = customDimensions
        self.watermark = watermark
        self.preserveMetadata = preserveMetadata
        self.includeEnhancementHistory = includeEnhancementHistory
    }
    
    /// Get optimal dimensions based on platform or custom settings
    var targetDimensions: CGSize? {
        if let customDimensions = customDimensions {
            return customDimensions
        }
        return platform?.optimalDimensions
    }
    
    /// Get recommended format based on platform
    var recommendedFormat: ExportFormat {
        return platform?.recommendedFormat ?? format
    }
    
    /// Check if configuration is valid for selected platform
    var isValidForPlatform: Bool {
        guard let platform = platform else { return true }
        return platform.supportedFormats.contains(format)
    }
}

// MARK: - Batch Export Options

/// Configuration for batch export operations
struct BatchExportConfiguration: Codable {
    let photos: [GlowlyPhoto]
    let baseConfiguration: ExportConfiguration
    let naming: BatchNamingStrategy
    let outputDirectory: URL?
    let includeOriginals: Bool
    let createSubfolders: Bool
    
    init(
        photos: [GlowlyPhoto],
        baseConfiguration: ExportConfiguration = ExportConfiguration(),
        naming: BatchNamingStrategy = .sequential,
        outputDirectory: URL? = nil,
        includeOriginals: Bool = false,
        createSubfolders: Bool = false
    ) {
        self.photos = photos
        self.baseConfiguration = baseConfiguration
        self.naming = naming
        self.outputDirectory = outputDirectory
        self.includeOriginals = includeOriginals
        self.createSubfolders = createSubfolders
    }
}

enum BatchNamingStrategy: String, CaseIterable, Codable {
    case sequential = "sequential"
    case timestamp = "timestamp"
    case original = "original"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .sequential:
            return "Sequential (1, 2, 3...)"
        case .timestamp:
            return "Timestamp"
        case .original:
            return "Original Names"
        case .custom:
            return "Custom Pattern"
        }
    }
    
    func generateFileName(for photo: GlowlyPhoto, index: Int, customPattern: String? = nil) -> String {
        switch self {
        case .sequential:
            return "glowly_enhanced_\(index + 1)"
        case .timestamp:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            return "glowly_\(formatter.string(from: photo.createdAt))"
        case .original:
            return photo.id.uuidString
        case .custom:
            return customPattern ?? "glowly_enhanced_\(index + 1)"
        }
    }
}

// MARK: - Export Result

/// Result of an export operation
struct ExportResult: Codable {
    let success: Bool
    let fileURL: URL?
    let fileSize: Int64
    let dimensions: CGSize
    let format: ExportFormat
    let quality: ExportQuality
    let processingTime: TimeInterval
    let error: String?
    
    init(
        success: Bool,
        fileURL: URL? = nil,
        fileSize: Int64 = 0,
        dimensions: CGSize = .zero,
        format: ExportFormat = .jpeg,
        quality: ExportQuality = .high,
        processingTime: TimeInterval = 0,
        error: String? = nil
    ) {
        self.success = success
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.dimensions = dimensions
        self.format = format
        self.quality = quality
        self.processingTime = processingTime
        self.error = error
    }
}

// MARK: - Batch Export Result

/// Result of a batch export operation
struct BatchExportResult: Codable {
    let totalPhotos: Int
    let successfulExports: Int
    let failedExports: Int
    let results: [ExportResult]
    let totalProcessingTime: TimeInterval
    let totalFileSize: Int64
    
    var successRate: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(successfulExports) / Double(totalPhotos)
    }
    
    var averageFileSize: Int64 {
        guard successfulExports > 0 else { return 0 }
        return totalFileSize / Int64(successfulExports)
    }
}

// MARK: - Caption and Hashtag Suggestions

/// Content suggestions for social media sharing
struct SharingContentSuggestions: Codable {
    let captions: [String]
    let hashtags: [String]
    let platform: SocialMediaPlatform
    
    init(platform: SocialMediaPlatform) {
        self.platform = platform
        self.captions = Self.generateCaptions(for: platform)
        self.hashtags = Self.generateHashtags(for: platform)
    }
    
    private static func generateCaptions(for platform: SocialMediaPlatform) -> [String] {
        let baseCaptions = [
            "✨ Enhanced with Glowly - bringing out my natural beauty!",
            "💫 Before and after magic with Glowly ✨",
            "🌟 Loving this glow-up! Thanks @Glowly",
            "✨ Natural enhancement at its finest",
            "💖 Feeling confident and radiant!"
        ]
        
        switch platform {
        case .instagram, .instagramStory:
            return baseCaptions + [
                "📸 Swipe to see the transformation ➡️",
                "🔥 This filter is everything! #GlowlyEnhanced"
            ]
        case .tiktok:
            return [
                "✨ Watch this glow-up transformation!",
                "🔥 The before and after hits different",
                "💫 POV: You discovered Glowly"
            ]
        case .snapchat:
            return [
                "✨ Glowly magic ✨",
                "🔥 Enhanced but still me",
                "💫 Natural glow activated"
            ]
        default:
            return baseCaptions
        }
    }
    
    private static func generateHashtags(for platform: SocialMediaPlatform) -> [String] {
        let baseHashtags = [
            "#GlowlyEnhanced",
            "#NaturalBeauty",
            "#ConfidenceBoost",
            "#BeautyTech",
            "#GlowUp"
        ]
        
        switch platform {
        case .instagram, .instagramStory:
            return baseHashtags + [
                "#InstagramBeauty",
                "#SelfieEnhancement",
                "#BeautyFilter",
                "#PhotoEditing",
                "#PortraitMode"
            ]
        case .tiktok:
            return baseHashtags + [
                "#TikTokBeauty",
                "#Transformation",
                "#BeforeAndAfter",
                "#ViralBeauty",
                "#TechTok"
            ]
        case .snapchat:
            return baseHashtags + [
                "#SnapchatBeauty",
                "#FilterFun",
                "#SelfieLove"
            ]
        default:
            return baseHashtags
        }
    }
}

// MARK: - Draft System

/// Draft photo for re-editing
struct PhotoDraft: Identifiable, Codable {
    let id: UUID
    let originalPhoto: GlowlyPhoto
    let currentEnhancements: [Enhancement]
    let previewImage: Data?
    let lastModified: Date
    let name: String
    let notes: String?
    
    init(
        id: UUID = UUID(),
        originalPhoto: GlowlyPhoto,
        currentEnhancements: [Enhancement] = [],
        previewImage: Data? = nil,
        lastModified: Date = Date(),
        name: String = "Untitled Draft",
        notes: String? = nil
    ) {
        self.id = id
        self.originalPhoto = originalPhoto
        self.currentEnhancements = currentEnhancements
        self.previewImage = previewImage
        self.lastModified = lastModified
        self.name = name
        self.notes = notes
    }
    
    /// Calculate total enhancement intensity
    var totalIntensity: Float {
        return currentEnhancements.reduce(0) { $0 + $1.intensity }
    }
    
    /// Check if draft has any enhancements
    var hasEnhancements: Bool {
        return !currentEnhancements.isEmpty
    }
    
    /// Get enhancement categories used
    var usedCategories: Set<EnhancementCategory> {
        return Set(currentEnhancements.map { $0.type.category })
    }
}

// MARK: - Album Organization

/// Photo album for organizing Glowly enhanced photos
struct GlowlyPhotoAlbum: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let createdAt: Date
    let photoIds: [UUID]
    let coverPhotoId: UUID?
    let isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        photoIds: [UUID] = [],
        coverPhotoId: UUID? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.photoIds = photoIds
        self.coverPhotoId = coverPhotoId
        self.isDefault = isDefault
    }
    
    static let defaultAlbums: [GlowlyPhotoAlbum] = [
        GlowlyPhotoAlbum(name: "Glowly Enhanced", description: "All your Glowly enhanced photos", isDefault: true),
        GlowlyPhotoAlbum(name: "Favorites", description: "Your favorite enhancements"),
        GlowlyPhotoAlbum(name: "Before & After", description: "Comparison photos"),
        GlowlyPhotoAlbum(name: "Shared", description: "Photos you've shared on social media")
    ]
}