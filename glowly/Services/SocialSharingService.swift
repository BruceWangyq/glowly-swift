//
//  SocialSharingService.swift
//  Glowly
//
//  Social sharing and filter attribution system for community engagement
//

import Foundation
import SwiftUI
import UIKit
import Social
import AVFoundation
import Photos
import LinkPresentation

/// Protocol for social sharing operations
protocol SocialSharingServiceProtocol {
    func shareFilterResult(_ result: FilteredImageResult, to platforms: [SocialPlatform]) async throws
    func generateShareableContent(for result: FilteredImageResult) async throws -> ShareableContent
    func createFilterAttribution(for filters: [BeautyFilter]) -> FilterAttribution
    func trackSharingAnalytics(for platform: SocialPlatform, filterId: UUID)
    func saveToPhotoLibrary(_ image: UIImage, with metadata: FilterMetadata) async throws
    func generateSocialPreview(for result: FilteredImageResult, platform: SocialPlatform) async throws -> UIImage
}

/// Social platforms supported for sharing
enum SocialPlatform: String, CaseIterable {
    case instagram = "instagram"
    case tiktok = "tiktok"
    case snapchat = "snapchat"
    case facebook = "facebook"
    case twitter = "twitter"
    case pinterest = "pinterest"
    case photoLibrary = "photo_library"
    case messages = "messages"
    case email = "email"
    case airdrop = "airdrop"
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .snapchat: return "Snapchat"
        case .facebook: return "Facebook"
        case .twitter: return "Twitter"
        case .pinterest: return "Pinterest"
        case .photoLibrary: return "Save to Photos"
        case .messages: return "Messages"
        case .email: return "Email"
        case .airdrop: return "AirDrop"
        }
    }
    
    var icon: String {
        switch self {
        case .instagram: return "camera.circle"
        case .tiktok: return "music.note"
        case .snapchat: return "camera.badge.ellipsis"
        case .facebook: return "person.2.circle"
        case .twitter: return "bird"
        case .pinterest: return "pin.circle"
        case .photoLibrary: return "photo.on.rectangle"
        case .messages: return "message.circle"
        case .email: return "envelope.circle"
        case .airdrop: return "airplayaudio.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return Color(red: 0.83, green: 0.35, blue: 0.65)
        case .tiktok: return .black
        case .snapchat: return .yellow
        case .facebook: return Color(red: 0.24, green: 0.35, blue: 0.60)
        case .twitter: return Color(red: 0.11, green: 0.63, blue: 0.95)
        case .pinterest: return Color(red: 0.73, green: 0.11, blue: 0.13)
        case .photoLibrary: return .blue
        case .messages: return .green
        case .email: return .orange
        case .airdrop: return .blue
        }
    }
    
    var urlScheme: String? {
        switch self {
        case .instagram: return "instagram://camera"
        case .tiktok: return "tiktok://camera"
        case .snapchat: return "snapchat://camera"
        case .facebook: return "fb://sharer"
        case .twitter: return "twitter://post"
        case .pinterest: return "pinterest://pin"
        default: return nil
        }
    }
    
    var isAppRequired: Bool {
        switch self {
        case .instagram, .tiktok, .snapchat: return true
        case .facebook, .twitter, .pinterest: return true
        default: return false
        }
    }
    
    var recommendedAspectRatio: CGFloat {
        switch self {
        case .instagram: return 1.0 // Square
        case .tiktok: return 9.0/16.0 // Vertical
        case .snapchat: return 9.0/16.0 // Vertical
        case .pinterest: return 2.0/3.0 // Vertical
        default: return 4.0/3.0 // Horizontal
        }
    }
}

/// Filtered image result with metadata
struct FilteredImageResult {
    let originalImage: UIImage
    let filteredImage: UIImage
    let appliedFilters: [BeautyFilter]
    let appliedMakeup: MakeupLook?
    let backgroundEffect: BackgroundEffect?
    let processingMetadata: ProcessingMetadata
    let createdAt: Date
    let sessionId: UUID
    
    init(
        originalImage: UIImage,
        filteredImage: UIImage,
        appliedFilters: [BeautyFilter] = [],
        appliedMakeup: MakeupLook? = nil,
        backgroundEffect: BackgroundEffect? = nil,
        processingMetadata: ProcessingMetadata = ProcessingMetadata(),
        createdAt: Date = Date(),
        sessionId: UUID = UUID()
    ) {
        self.originalImage = originalImage
        self.filteredImage = filteredImage
        self.appliedFilters = appliedFilters
        self.appliedMakeup = appliedMakeup
        self.backgroundEffect = backgroundEffect
        self.processingMetadata = processingMetadata
        self.createdAt = createdAt
        self.sessionId = sessionId
    }
}

/// Processing metadata for attribution
struct ProcessingMetadata: Codable {
    let processingTime: TimeInterval
    let deviceModel: String
    let appVersion: String
    let filterVersion: String
    let qualitySettings: ProcessingQuality
    
    init(
        processingTime: TimeInterval = 0,
        deviceModel: String = UIDevice.current.model,
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        filterVersion: String = "1.0",
        qualitySettings: ProcessingQuality = .high
    ) {
        self.processingTime = processingTime
        self.deviceModel = deviceModel
        self.appVersion = appVersion
        self.filterVersion = filterVersion
        self.qualitySettings = qualitySettings
    }
}

/// Shareable content with platform optimization
struct ShareableContent {
    let image: UIImage
    let text: String
    let hashtags: [String]
    let attribution: FilterAttribution
    let metadata: FilterMetadata
    let linkPreview: LinkPreview?
    
    init(
        image: UIImage,
        text: String,
        hashtags: [String] = [],
        attribution: FilterAttribution,
        metadata: FilterMetadata,
        linkPreview: LinkPreview? = nil
    ) {
        self.image = image
        self.text = text
        self.hashtags = hashtags
        self.attribution = attribution
        self.metadata = metadata
        self.linkPreview = linkPreview
    }
}

/// Filter attribution for crediting creators
struct FilterAttribution: Codable {
    let filtersUsed: [FilterCredit]
    let makeupCredit: MakeupCredit?
    let backgroundCredit: BackgroundCredit?
    let appAttribution: AppAttribution
    let createdWith: String
    
    init(
        filtersUsed: [FilterCredit],
        makeupCredit: MakeupCredit? = nil,
        backgroundCredit: BackgroundCredit? = nil,
        appAttribution: AppAttribution = AppAttribution(),
        createdWith: String = "Created with Glowly"
    ) {
        self.filtersUsed = filtersUsed
        self.makeupCredit = makeupCredit
        self.backgroundCredit = backgroundCredit
        self.appAttribution = appAttribution
        self.createdWith = createdWith
    }
}

struct FilterCredit: Codable, Identifiable {
    let id = UUID()
    let filterName: String
    let authorName: String?
    let authorHandle: String?
    let filterUrl: String?
}

struct MakeupCredit: Codable {
    let lookName: String
    let artistName: String?
    let artistHandle: String?
    let lookUrl: String?
}

struct BackgroundCredit: Codable {
    let effectName: String
    let artistName: String?
    let sourceUrl: String?
}

struct AppAttribution: Codable {
    let appName: String
    let appUrl: String
    let downloadUrl: String
    
    init(
        appName: String = "Glowly",
        appUrl: String = "https://glowly.app",
        downloadUrl: String = "https://apps.apple.com/app/glowly"
    ) {
        self.appName = appName
        self.appUrl = appUrl
        self.downloadUrl = downloadUrl
    }
}

/// Filter metadata for photo library
struct FilterMetadata: Codable {
    let filters: [String]
    let makeup: String?
    let background: String?
    let processingTime: TimeInterval
    let createdAt: Date
    let appVersion: String
}

/// Link preview for social sharing
struct LinkPreview {
    let title: String
    let subtitle: String?
    let image: UIImage?
    let url: URL?
}

/// Advanced social sharing service
@MainActor
final class SocialSharingService: SocialSharingServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSharing = false
    @Published var sharingProgress: Float = 0.0
    @Published var availablePlatforms: [SocialPlatform] = []
    @Published var recentShares: [SharingAnalytics] = []
    
    // MARK: - Private Properties
    private let analyticsService = AnalyticsService()
    private let contentGenerator = SocialContentGenerator()
    private let platformOptimizer = SocialPlatformOptimizer()
    private let linkPreviewGenerator = LinkPreviewGenerator()
    
    private let photoLibraryManager = PhotoLibraryManager()
    private let sharingQueue = DispatchQueue(label: "com.glowly.sharing", qos: .userInitiated)
    
    // MARK: - Initialization
    init() {
        detectAvailablePlatforms()
        loadRecentShares()
    }
    
    // MARK: - Public Methods
    
    /// Share filtered image result to multiple platforms
    func shareFilterResult(_ result: FilteredImageResult, to platforms: [SocialPlatform]) async throws {
        isSharing = true
        sharingProgress = 0.0
        
        defer {
            isSharing = false
            sharingProgress = 0.0
        }
        
        let shareableContent = try await generateShareableContent(for: result)
        let totalPlatforms = Float(platforms.count)
        
        for (index, platform) in platforms.enumerated() {
            try await shareToSpecificPlatform(shareableContent, platform: platform, result: result)
            
            // Track analytics
            if let firstFilter = result.appliedFilters.first {
                trackSharingAnalytics(for: platform, filterId: firstFilter.id)
            }
            
            sharingProgress = Float(index + 1) / totalPlatforms
        }
    }
    
    /// Generate shareable content optimized for social platforms
    func generateShareableContent(for result: FilteredImageResult) async throws -> ShareableContent {
        let attribution = createFilterAttribution(for: result.appliedFilters)
        let text = await contentGenerator.generateSharingText(for: result, attribution: attribution)
        let hashtags = await contentGenerator.generateHashtags(for: result)
        let metadata = createFilterMetadata(for: result)
        let linkPreview = await linkPreviewGenerator.generatePreview(for: result)
        
        return ShareableContent(
            image: result.filteredImage,
            text: text,
            hashtags: hashtags,
            attribution: attribution,
            metadata: metadata,
            linkPreview: linkPreview
        )
    }
    
    /// Create filter attribution for crediting creators
    func createFilterAttribution(for filters: [BeautyFilter]) -> FilterAttribution {
        let filterCredits = filters.map { filter in
            FilterCredit(
                filterName: filter.displayName,
                authorName: filter.authorInfo?.displayName,
                authorHandle: filter.authorInfo?.name,
                filterUrl: nil // Would be populated with actual filter URLs
            )
        }
        
        return FilterAttribution(filtersUsed: filterCredits)
    }
    
    /// Track sharing analytics
    func trackSharingAnalytics(for platform: SocialPlatform, filterId: UUID) {
        let analytics = SharingAnalytics(
            platform: platform,
            filterId: filterId,
            timestamp: Date(),
            success: true
        )
        
        recentShares.append(analytics)
        
        // Keep only recent 100 shares
        if recentShares.count > 100 {
            recentShares = Array(recentShares.suffix(100))
        }
        
        analyticsService.trackSocialShare(platform: platform, filterId: filterId)
    }
    
    /// Save image to photo library with metadata
    func saveToPhotoLibrary(_ image: UIImage, with metadata: FilterMetadata) async throws {
        try await photoLibraryManager.saveImage(image, metadata: metadata)
    }
    
    /// Generate social platform optimized preview
    func generateSocialPreview(for result: FilteredImageResult, platform: SocialPlatform) async throws -> UIImage {
        return try await platformOptimizer.optimizeImage(
            result.filteredImage,
            for: platform,
            with: result.appliedFilters
        )
    }
    
    // MARK: - Private Methods
    
    private func detectAvailablePlatforms() {
        var available: [SocialPlatform] = []
        
        // Always available platforms
        available.append(contentsOf: [.photoLibrary, .messages, .email, .airdrop])
        
        // Check for app availability
        for platform in [SocialPlatform.instagram, .tiktok, .snapchat, .facebook, .twitter, .pinterest] {
            if let urlScheme = platform.urlScheme,
               let url = URL(string: urlScheme),
               UIApplication.shared.canOpenURL(url) {
                available.append(platform)
            }
        }
        
        availablePlatforms = available
    }
    
    private func shareToSpecificPlatform(_ content: ShareableContent, platform: SocialPlatform, result: FilteredImageResult) async throws {
        switch platform {
        case .instagram:
            try await shareToInstagram(content, result: result)
        case .tiktok:
            try await shareToTikTok(content, result: result)
        case .snapchat:
            try await shareToSnapchat(content, result: result)
        case .facebook:
            try await shareToFacebook(content)
        case .twitter:
            try await shareToTwitter(content)
        case .pinterest:
            try await shareToPinterest(content)
        case .photoLibrary:
            try await saveToPhotoLibrary(content.image, with: content.metadata)
        case .messages:
            try await shareToMessages(content)
        case .email:
            try await shareToEmail(content)
        case .airdrop:
            try await shareToAirDrop(content)
        }
    }
    
    private func shareToInstagram(_ content: ShareableContent, result: FilteredImageResult) async throws {
        // Generate Instagram-optimized image
        let optimizedImage = try await generateSocialPreview(for: result, platform: .instagram)
        
        // Save to temporary location for Instagram sharing
        let imageData = optimizedImage.jpegData(compressionQuality: 0.9)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("instagram_share.jpg")
        
        try imageData?.write(to: tempURL)
        
        // Open Instagram with image
        if let instagramURL = URL(string: "instagram://library?LocalIdentifier=\(tempURL.lastPathComponent)") {
            await UIApplication.shared.open(instagramURL)
        }
    }
    
    private func shareToTikTok(_ content: ShareableContent, result: FilteredImageResult) async throws {
        // Generate TikTok-optimized image (9:16 aspect ratio)
        let optimizedImage = try await generateSocialPreview(for: result, platform: .tiktok)
        
        // TikTok integration would require their SDK
        // For now, save to photo library and open TikTok
        try await saveToPhotoLibrary(optimizedImage, with: content.metadata)
        
        if let tiktokURL = URL(string: "tiktok://camera") {
            await UIApplication.shared.open(tiktokURL)
        }
    }
    
    private func shareToSnapchat(_ content: ShareableContent, result: FilteredImageResult) async throws {
        // Snapchat sharing implementation
        let optimizedImage = try await generateSocialPreview(for: result, platform: .snapchat)
        
        // Use Snapchat Creative Kit if available
        try await saveToPhotoLibrary(optimizedImage, with: content.metadata)
        
        if let snapchatURL = URL(string: "snapchat://camera") {
            await UIApplication.shared.open(snapchatURL)
        }
    }
    
    private func shareToFacebook(_ content: ShareableContent) async throws {
        // Facebook sharing implementation
        let shareText = generateSocialText(content)
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let facebookURL = URL(string: "fb://sharer?text=\(encodedText)") {
            await UIApplication.shared.open(facebookURL)
        }
    }
    
    private func shareToTwitter(_ content: ShareableContent) async throws {
        // Twitter sharing implementation
        let shareText = generateSocialText(content)
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let twitterURL = URL(string: "twitter://post?message=\(encodedText)") {
            await UIApplication.shared.open(twitterURL)
        }
    }
    
    private func shareToPinterest(_ content: ShareableContent) async throws {
        // Pinterest sharing implementation
        let shareText = generateSocialText(content)
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let pinterestURL = URL(string: "pinterest://pin?description=\(encodedText)") {
            await UIApplication.shared.open(pinterestURL)
        }
    }
    
    private func shareToMessages(_ content: ShareableContent) async throws {
        // Use UIActivityViewController for Messages
        await presentActivityViewController(with: content, excludedTypes: [])
    }
    
    private func shareToEmail(_ content: ShareableContent) async throws {
        // Use UIActivityViewController for Email
        await presentActivityViewController(with: content, excludedTypes: [])
    }
    
    private func shareToAirDrop(_ content: ShareableContent) async throws {
        // Use UIActivityViewController for AirDrop
        await presentActivityViewController(with: content, excludedTypes: [])
    }
    
    private func presentActivityViewController(with content: ShareableContent, excludedTypes: [UIActivity.ActivityType]) async {
        let shareText = generateSocialText(content)
        let activityItems: [Any] = [content.image, shareText]
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = excludedTypes
        
        // Present from root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            await rootViewController.present(activityViewController, animated: true)
        }
    }
    
    private func generateSocialText(_ content: ShareableContent) -> String {
        var text = content.text
        
        if !content.hashtags.isEmpty {
            text += "\n\n" + content.hashtags.map { "#\($0)" }.joined(separator: " ")
        }
        
        text += "\n\n" + content.attribution.createdWith
        
        return text
    }
    
    private func createFilterMetadata(for result: FilteredImageResult) -> FilterMetadata {
        return FilterMetadata(
            filters: result.appliedFilters.map { $0.displayName },
            makeup: result.appliedMakeup?.displayName,
            background: result.backgroundEffect?.displayName,
            processingTime: result.processingMetadata.processingTime,
            createdAt: result.createdAt,
            appVersion: result.processingMetadata.appVersion
        )
    }
    
    private func loadRecentShares() {
        // Load from UserDefaults or Core Data
        // Mock implementation
        recentShares = []
    }
}

// MARK: - Supporting Classes

/// Social content generation
final class SocialContentGenerator {
    
    func generateSharingText(for result: FilteredImageResult, attribution: FilterAttribution) async -> String {
        var text = "✨ Enhanced with "
        
        if !result.appliedFilters.isEmpty {
            let filterNames = result.appliedFilters.map { $0.displayName }
            text += filterNames.joined(separator: " + ")
        }
        
        if let makeup = result.appliedMakeup {
            text += " and \(makeup.displayName) makeup"
        }
        
        if let background = result.backgroundEffect {
            text += " with \(background.displayName) background"
        }
        
        return text
    }
    
    func generateHashtags(for result: FilteredImageResult) async -> [String] {
        var hashtags = ["glowly", "beautify", "selfie", "enhanced"]
        
        // Add filter-specific hashtags
        hashtags.append(contentsOf: result.appliedFilters.flatMap { $0.socialMetadata.tags })
        
        // Add category-based hashtags
        let categories = result.appliedFilters.map { $0.category.rawValue }
        hashtags.append(contentsOf: categories)
        
        // Remove duplicates and limit to 10
        return Array(Set(hashtags).prefix(10))
    }
}

/// Platform-specific optimization
final class SocialPlatformOptimizer {
    
    func optimizeImage(_ image: UIImage, for platform: SocialPlatform, with filters: [BeautyFilter]) async throws -> UIImage {
        let targetSize = calculateOptimalSize(for: platform, originalSize: image.size)
        let targetAspectRatio = platform.recommendedAspectRatio
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let optimizedImage = self.resizeAndCropImage(
                    image,
                    to: targetSize,
                    aspectRatio: targetAspectRatio
                )
                continuation.resume(returning: optimizedImage)
            }
        }
    }
    
    private func calculateOptimalSize(for platform: SocialPlatform, originalSize: CGSize) -> CGSize {
        switch platform {
        case .instagram:
            return CGSize(width: 1080, height: 1080) // Square
        case .tiktok, .snapchat:
            return CGSize(width: 1080, height: 1920) // 9:16
        case .pinterest:
            return CGSize(width: 1000, height: 1500) // 2:3
        default:
            return CGSize(width: 1200, height: 900) // 4:3
        }
    }
    
    private func resizeAndCropImage(_ image: UIImage, to size: CGSize, aspectRatio: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Calculate crop rect to maintain aspect ratio
            let imageAspectRatio = image.size.width / image.size.height
            let targetAspectRatio = aspectRatio
            
            var drawRect: CGRect
            
            if imageAspectRatio > targetAspectRatio {
                // Image is wider, crop width
                let newWidth = image.size.height * targetAspectRatio
                drawRect = CGRect(
                    x: (image.size.width - newWidth) / 2,
                    y: 0,
                    width: newWidth,
                    height: image.size.height
                )
            } else {
                // Image is taller, crop height
                let newHeight = image.size.width / targetAspectRatio
                drawRect = CGRect(
                    x: 0,
                    y: (image.size.height - newHeight) / 2,
                    width: image.size.width,
                    height: newHeight
                )
            }
            
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

/// Link preview generation
final class LinkPreviewGenerator {
    
    func generatePreview(for result: FilteredImageResult) async -> LinkPreview? {
        let title = "Enhanced with Glowly"
        let subtitle = generateSubtitle(for: result)
        let previewImage = generatePreviewThumbnail(from: result.filteredImage)
        
        return LinkPreview(
            title: title,
            subtitle: subtitle,
            image: previewImage,
            url: URL(string: "https://glowly.app")
        )
    }
    
    private func generateSubtitle(for result: FilteredImageResult) -> String {
        var components: [String] = []
        
        if !result.appliedFilters.isEmpty {
            components.append("\(result.appliedFilters.count) filters")
        }
        
        if result.appliedMakeup != nil {
            components.append("makeup")
        }
        
        if result.backgroundEffect != nil {
            components.append("background effect")
        }
        
        if components.isEmpty {
            return "Beautiful photo enhancement"
        } else {
            return "Enhanced with " + components.joined(separator: ", ")
        }
    }
    
    private func generatePreviewThumbnail(from image: UIImage) -> UIImage {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
    }
}

/// Photo library management
final class PhotoLibraryManager {
    
    func saveImage(_ image: UIImage, metadata: FilterMetadata) async throws {
        try await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            // Add metadata to the photo
            if let metadataData = try? JSONEncoder().encode(metadata) {
                request.location = nil // Could add location if desired
                // Additional metadata could be added through EXIF data
            }
        }
    }
}

// MARK: - Supporting Types

struct SharingAnalytics: Codable, Identifiable {
    let id = UUID()
    let platform: SocialPlatform
    let filterId: UUID
    let timestamp: Date
    let success: Bool
    let errorMessage: String?
    
    init(platform: SocialPlatform, filterId: UUID, timestamp: Date, success: Bool, errorMessage: String? = nil) {
        self.platform = platform
        self.filterId = filterId
        self.timestamp = timestamp
        self.success = success
        self.errorMessage = errorMessage
    }
}