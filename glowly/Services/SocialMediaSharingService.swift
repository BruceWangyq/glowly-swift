//
//  SocialMediaSharingService.swift
//  Glowly
//
//  Service for handling social media sharing with platform-specific optimizations
//

import Foundation
import UIKit
import Social
import Photos
import LinkPresentation

// MARK: - Social Media Sharing Service

@MainActor
class SocialMediaSharingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSharing = false
    @Published var shareProgress: Double = 0.0
    @Published var lastShareResult: ShareResult?
    
    // MARK: - Private Properties
    
    private let exportManager = AdvancedExportManager()
    private let contentSuggestionGenerator = ContentSuggestionGenerator()
    
    // MARK: - Public Methods
    
    /// Share a single photo to specified platform
    func sharePhoto(
        _ photo: GlowlyPhoto,
        to platform: SocialMediaPlatform,
        with configuration: ExportConfiguration = ExportConfiguration(),
        includeEnhancements: Bool = true,
        customCaption: String? = nil
    ) async throws -> ShareResult {
        
        isSharing = true
        shareProgress = 0.0
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        do {
            // Step 1: Optimize photo for platform
            shareProgress = 0.2
            let optimizedConfig = optimizeConfigurationForPlatform(configuration, platform: platform)
            
            // Step 2: Export photo with platform optimization
            shareProgress = 0.4
            let exportResult = try await exportManager.exportPhoto(
                photo,
                configuration: optimizedConfig,
                progressCallback: { progress in
                    await MainActor.run {
                        self.shareProgress = 0.4 + (progress * 0.4)
                    }
                }
            )
            
            guard exportResult.success, let fileURL = exportResult.fileURL else {
                throw SharingError.exportFailed(exportResult.error ?? "Unknown export error")
            }
            
            // Step 3: Generate content suggestions
            shareProgress = 0.9
            let suggestions = contentSuggestionGenerator.generateSuggestions(
                for: platform,
                photo: photo,
                includeEnhancements: includeEnhancements
            )
            
            // Step 4: Create share result
            shareProgress = 1.0
            let shareResult = ShareResult(
                success: true,
                platform: platform,
                fileURL: fileURL,
                contentSuggestions: suggestions,
                customCaption: customCaption,
                exportResult: exportResult
            )
            
            lastShareResult = shareResult
            return shareResult
            
        } catch {
            let shareResult = ShareResult(
                success: false,
                platform: platform,
                error: error.localizedDescription
            )
            lastShareResult = shareResult
            throw error
        }
    }
    
    /// Share multiple photos as a batch
    func sharePhotoBatch(
        _ photos: [GlowlyPhoto],
        to platform: SocialMediaPlatform,
        with configuration: BatchExportConfiguration
    ) async throws -> BatchShareResult {
        
        isSharing = true
        shareProgress = 0.0
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        var results: [ShareResult] = []
        let totalPhotos = photos.count
        
        for (index, photo) in photos.enumerated() {
            do {
                let baseProgress = Double(index) / Double(totalPhotos)
                let stepProgress = 1.0 / Double(totalPhotos)
                
                let result = try await sharePhoto(
                    photo,
                    to: platform,
                    with: configuration.baseConfiguration
                )
                results.append(result)
                
                shareProgress = baseProgress + stepProgress
                
            } catch {
                let failedResult = ShareResult(
                    success: false,
                    platform: platform,
                    error: error.localizedDescription
                )
                results.append(failedResult)
            }
        }
        
        return BatchShareResult(
            platform: platform,
            totalPhotos: totalPhotos,
            results: results
        )
    }
    
    /// Create before/after collage for sharing
    func shareBeforeAfterComparison(
        originalPhoto: GlowlyPhoto,
        enhancedPhoto: GlowlyPhoto,
        to platform: SocialMediaPlatform,
        template: CollageTemplate = .sideBySide,
        customCaption: String? = nil
    ) async throws -> ShareResult {
        
        isSharing = true
        shareProgress = 0.0
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        do {
            // Step 1: Create collage
            shareProgress = 0.3
            let collageURL = try await createBeforeAfterCollage(
                original: originalPhoto,
                enhanced: enhancedPhoto,
                template: template,
                platform: platform
            )
            
            // Step 2: Generate content
            shareProgress = 0.8
            let suggestions = contentSuggestionGenerator.generateBeforeAfterSuggestions(
                for: platform,
                originalPhoto: originalPhoto,
                enhancedPhoto: enhancedPhoto
            )
            
            // Step 3: Create result
            shareProgress = 1.0
            let shareResult = ShareResult(
                success: true,
                platform: platform,
                fileURL: collageURL,
                contentSuggestions: suggestions,
                customCaption: customCaption,
                isBeforeAfter: true
            )
            
            lastShareResult = shareResult
            return shareResult
            
        } catch {
            let shareResult = ShareResult(
                success: false,
                platform: platform,
                error: error.localizedDescription
            )
            lastShareResult = shareResult
            throw error
        }
    }
    
    /// Get platform availability
    func getPlatformAvailability() -> [SocialMediaPlatform: Bool] {
        var availability: [SocialMediaPlatform: Bool] = [:]
        
        for platform in SocialMediaPlatform.allCases {
            availability[platform] = isPlatformAvailable(platform)
        }
        
        return availability
    }
    
    /// Check if platform-specific sharing is available
    func isPlatformAvailable(_ platform: SocialMediaPlatform) -> Bool {
        switch platform {
        case .instagram, .instagramStory:
            return canShareToInstagram()
        case .tiktok:
            return canShareToTikTok()
        case .snapchat:
            return canShareToSnapchat()
        case .facebook:
            return SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)
        case .twitter:
            return SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)
        default:
            return true // Generic sharing available
        }
    }
    
    // MARK: - Private Methods
    
    private func optimizeConfigurationForPlatform(
        _ configuration: ExportConfiguration,
        platform: SocialMediaPlatform
    ) -> ExportConfiguration {
        var optimized = configuration
        optimized = ExportConfiguration(
            quality: configuration.quality,
            format: platform.recommendedFormat,
            platform: platform,
            customDimensions: platform.optimalDimensions,
            watermark: configuration.watermark,
            preserveMetadata: configuration.preserveMetadata,
            includeEnhancementHistory: configuration.includeEnhancementHistory
        )
        return optimized
    }
    
    private func createBeforeAfterCollage(
        original: GlowlyPhoto,
        enhanced: GlowlyPhoto,
        template: CollageTemplate,
        platform: SocialMediaPlatform
    ) async throws -> URL {
        
        guard let originalImage = original.enhancedUIImage ?? original.originalUIImage,
              let enhancedImage = enhanced.enhancedUIImage ?? enhanced.originalUIImage else {
            throw SharingError.invalidImages
        }
        
        let targetSize = platform.optimalDimensions
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let collageImage = renderer.image { context in
            drawCollage(
                original: originalImage,
                enhanced: enhancedImage,
                template: template,
                size: targetSize,
                context: context
            )
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        guard let imageData = collageImage.jpegData(compressionQuality: 0.9) else {
            throw SharingError.imageProcessingFailed
        }
        
        try imageData.write(to: tempURL)
        return tempURL
    }
    
    private func drawCollage(
        original: UIImage,
        enhanced: UIImage,
        template: CollageTemplate,
        size: CGSize,
        context: UIGraphicsImageRendererContext
    ) {
        switch template {
        case .sideBySide:
            let leftRect = CGRect(x: 0, y: 0, width: size.width / 2 - 1, height: size.height)
            let rightRect = CGRect(x: size.width / 2 + 1, y: 0, width: size.width / 2 - 1, height: size.height)
            
            original.draw(in: leftRect)
            enhanced.draw(in: rightRect)
            
            // Draw divider line
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.move(to: CGPoint(x: size.width / 2, y: 0))
            context.cgContext.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            context.cgContext.strokePath()
            
        case .topBottom:
            let topRect = CGRect(x: 0, y: 0, width: size.width, height: size.height / 2 - 1)
            let bottomRect = CGRect(x: 0, y: size.height / 2 + 1, width: size.width, height: size.height / 2 - 1)
            
            original.draw(in: topRect)
            enhanced.draw(in: bottomRect)
            
            // Draw divider line
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.move(to: CGPoint(x: 0, y: size.height / 2))
            context.cgContext.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.cgContext.strokePath()
            
        case .overlaySlider:
            let fullRect = CGRect(origin: .zero, size: size)
            original.draw(in: fullRect)
            
            // Draw enhanced portion with mask
            let maskWidth = size.width * 0.6
            let maskRect = CGRect(x: 0, y: 0, width: maskWidth, height: size.height)
            
            context.cgContext.saveGState()
            context.cgContext.clip(to: maskRect)
            enhanced.draw(in: fullRect)
            context.cgContext.restoreGState()
            
            // Draw slider line
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(4)
            context.cgContext.move(to: CGPoint(x: maskWidth, y: 0))
            context.cgContext.addLine(to: CGPoint(x: maskWidth, y: size.height))
            context.cgContext.strokePath()
        }
        
        // Add labels
        addCollageLabels(context: context, size: size, template: template)
    }
    
    private func addCollageLabels(context: UIGraphicsImageRendererContext, size: CGSize, template: CollageTemplate) {
        let beforeText = "BEFORE"
        let afterText = "AFTER"
        
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        let beforeString = NSAttributedString(string: beforeText, attributes: attributes)
        let afterString = NSAttributedString(string: afterText, attributes: attributes)
        
        let beforeSize = beforeString.size()
        let afterSize = afterString.size()
        
        switch template {
        case .sideBySide:
            let beforeRect = CGRect(
                x: (size.width / 4) - (beforeSize.width / 2),
                y: 20,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: (3 * size.width / 4) - (afterSize.width / 2),
                y: 20,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
            
        case .topBottom:
            let beforeRect = CGRect(
                x: (size.width / 2) - (beforeSize.width / 2),
                y: 20,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: (size.width / 2) - (afterSize.width / 2),
                y: (size.height / 2) + 20,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
            
        case .overlaySlider:
            break // No labels for overlay style
        }
    }
    
    // MARK: - Platform Availability Checks
    
    private func canShareToInstagram() -> Bool {
        guard let instagramURL = URL(string: "instagram://app") else { return false }
        return UIApplication.shared.canOpenURL(instagramURL)
    }
    
    private func canShareToTikTok() -> Bool {
        guard let tiktokURL = URL(string: "tiktok://") else { return false }
        return UIApplication.shared.canOpenURL(tiktokURL)
    }
    
    private func canShareToSnapchat() -> Bool {
        guard let snapchatURL = URL(string: "snapchat://") else { return false }
        return UIApplication.shared.canOpenURL(snapchatURL)
    }
}

// MARK: - Content Suggestion Generator

class ContentSuggestionGenerator {
    
    func generateSuggestions(
        for platform: SocialMediaPlatform,
        photo: GlowlyPhoto,
        includeEnhancements: Bool = true
    ) -> SharingContentSuggestions {
        
        var suggestions = SharingContentSuggestions(platform: platform)
        
        if includeEnhancements && photo.isEnhanced {
            suggestions = enhanceWithEnhancementData(suggestions, photo: photo)
        }
        
        return suggestions
    }
    
    func generateBeforeAfterSuggestions(
        for platform: SocialMediaPlatform,
        originalPhoto: GlowlyPhoto,
        enhancedPhoto: GlowlyPhoto
    ) -> SharingContentSuggestions {
        
        let baseSuggestions = SharingContentSuggestions(platform: platform)
        
        // Add before/after specific content
        var enhancedCaptions = baseSuggestions.captions
        enhancedCaptions.insert("✨ Before vs After - the glow up is real! ➡️", at: 0)
        enhancedCaptions.insert("💫 Swipe to see the magic transformation", at: 1)
        
        var enhancedHashtags = baseSuggestions.hashtags
        enhancedHashtags.append("#BeforeAndAfter")
        enhancedHashtags.append("#Transformation")
        enhancedHashtags.append("#GlowUpChallenge")
        
        return SharingContentSuggestions(
            captions: enhancedCaptions,
            hashtags: enhancedHashtags,
            platform: platform
        )
    }
    
    private func enhanceWithEnhancementData(
        _ suggestions: SharingContentSuggestions,
        photo: GlowlyPhoto
    ) -> SharingContentSuggestions {
        
        let enhancementTypes = photo.enhancementHistory.map { $0.type }
        var enhancedHashtags = suggestions.hashtags
        
        // Add enhancement-specific hashtags
        if enhancementTypes.contains(.skinSmoothing) {
            enhancedHashtags.append("#SkinSmoothing")
        }
        if enhancementTypes.contains(.eyeBrightening) {
            enhancedHashtags.append("#BrightEyes")
        }
        if enhancementTypes.contains(.teethWhitening) {
            enhancedHashtags.append("#BrightSmile")
        }
        
        return SharingContentSuggestions(
            captions: suggestions.captions,
            hashtags: enhancedHashtags,
            platform: suggestions.platform
        )
    }
}

// MARK: - Supporting Models

struct ShareResult: Codable {
    let success: Bool
    let platform: SocialMediaPlatform
    let fileURL: URL?
    let contentSuggestions: SharingContentSuggestions?
    let customCaption: String?
    let exportResult: ExportResult?
    let isBeforeAfter: Bool
    let error: String?
    let timestamp: Date
    
    init(
        success: Bool,
        platform: SocialMediaPlatform,
        fileURL: URL? = nil,
        contentSuggestions: SharingContentSuggestions? = nil,
        customCaption: String? = nil,
        exportResult: ExportResult? = nil,
        isBeforeAfter: Bool = false,
        error: String? = nil
    ) {
        self.success = success
        self.platform = platform
        self.fileURL = fileURL
        self.contentSuggestions = contentSuggestions
        self.customCaption = customCaption
        self.exportResult = exportResult
        self.isBeforeAfter = isBeforeAfter
        self.error = error
        self.timestamp = Date()
    }
}

struct BatchShareResult: Codable {
    let platform: SocialMediaPlatform
    let totalPhotos: Int
    let results: [ShareResult]
    let timestamp: Date
    
    var successfulShares: Int {
        return results.filter { $0.success }.count
    }
    
    var failedShares: Int {
        return results.filter { !$0.success }.count
    }
    
    var successRate: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(successfulShares) / Double(totalPhotos)
    }
    
    init(platform: SocialMediaPlatform, totalPhotos: Int, results: [ShareResult]) {
        self.platform = platform
        self.totalPhotos = totalPhotos
        self.results = results
        self.timestamp = Date()
    }
}

enum CollageTemplate: String, CaseIterable, Codable {
    case sideBySide = "side_by_side"
    case topBottom = "top_bottom"
    case overlaySlider = "overlay_slider"
    
    var displayName: String {
        switch self {
        case .sideBySide:
            return "Side by Side"
        case .topBottom:
            return "Top & Bottom"
        case .overlaySlider:
            return "Overlay Slider"
        }
    }
}

// MARK: - Sharing Errors

enum SharingError: LocalizedError {
    case platformNotAvailable(SocialMediaPlatform)
    case exportFailed(String)
    case invalidImages
    case imageProcessingFailed
    case networkError
    case permissionDenied
    case fileSizeTooLarge(Int, Int)
    case unsupportedFormat(ExportFormat, SocialMediaPlatform)
    
    var errorDescription: String? {
        switch self {
        case .platformNotAvailable(let platform):
            return "\(platform.displayName) is not available on this device"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .invalidImages:
            return "Invalid images provided for sharing"
        case .imageProcessingFailed:
            return "Failed to process image for sharing"
        case .networkError:
            return "Network error occurred during sharing"
        case .permissionDenied:
            return "Permission denied for sharing"
        case .fileSizeTooLarge(let size, let limit):
            return "File size (\(size) bytes) exceeds platform limit (\(limit) bytes)"
        case .unsupportedFormat(let format, let platform):
            return "\(format.displayName) format is not supported by \(platform.displayName)"
        }
    }
}