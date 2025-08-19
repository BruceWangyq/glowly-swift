//
//  ShareViewModel.swift
//  Glowly
//
//  View model for managing photo sharing functionality
//

import Foundation
import SwiftUI

// MARK: - Share View Model

@MainActor
class ShareViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSharing = false
    @Published var shareProgress: Double = 0.0
    @Published var showingShareSuccess = false
    @Published var showingShareError = false
    @Published var shareError: String?
    
    @Published var selectedPlatform: SocialMediaPlatform?
    @Published var contentSuggestions: SharingContentSuggestions?
    @Published var exportQuality: ExportQuality = .high
    @Published var includeWatermark = true
    @Published var shareHistory: [ShareResult] = []
    
    // MARK: - Private Properties
    
    private let photo: GlowlyPhoto
    private let socialSharingService = SocialMediaSharingService()
    private let exportManager = AdvancedExportManager()
    private let contentGenerator = ContentSuggestionGenerator()
    
    // MARK: - Initialization
    
    init(photo: GlowlyPhoto) {
        self.photo = photo
    }
    
    // MARK: - Public Methods
    
    /// Generate content suggestions for the current photo
    func generateContentSuggestions() {
        guard let platform = selectedPlatform else {
            // Generate generic suggestions
            contentSuggestions = SharingContentSuggestions(platform: .instagram)
            return
        }
        
        contentSuggestions = contentGenerator.generateSuggestions(
            for: platform,
            photo: photo,
            includeEnhancements: photo.isEnhanced
        )
    }
    
    /// Share photo to selected social media platform
    func shareToSocialMedia(
        platform: SocialMediaPlatform,
        customCaption: String? = nil
    ) async {
        isSharing = true
        shareProgress = 0.0
        shareError = nil
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        do {
            let exportConfig = createExportConfiguration(for: platform)
            
            let result = try await socialSharingService.sharePhoto(
                photo,
                to: platform,
                with: exportConfig,
                includeEnhancements: photo.isEnhanced,
                customCaption: customCaption
            )
            
            shareHistory.append(result)
            
            if result.success {
                showingShareSuccess = true
                HapticFeedback.success()
            } else {
                shareError = result.error ?? "Unknown sharing error"
                showingShareError = true
                HapticFeedback.error()
            }
            
        } catch {
            shareError = error.localizedDescription
            showingShareError = true
            HapticFeedback.error()
        }
    }
    
    /// Create before/after comparison and share
    func shareBeforeAfterComparison(
        template: CollageTemplate = .sideBySide,
        platform: SocialMediaPlatform
    ) async {
        guard photo.isEnhanced else {
            shareError = "This photo hasn't been enhanced yet"
            showingShareError = true
            return
        }
        
        // For before/after, we need both original and enhanced versions
        guard let originalImage = photo.originalUIImage,
              let enhancedImage = photo.enhancedUIImage else {
            shareError = "Unable to load photo images"
            showingShareError = true
            return
        }
        
        isSharing = true
        shareProgress = 0.0
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        do {
            // Create a temporary enhanced photo object for comparison
            let enhancedPhotoForComparison = GlowlyPhoto(
                originalImage: photo.originalImage,
                enhancedImage: photo.enhancedImage,
                metadata: photo.metadata,
                enhancementHistory: photo.enhancementHistory
            )
            
            let result = try await socialSharingService.shareBeforeAfterComparison(
                originalPhoto: photo,
                enhancedPhoto: enhancedPhotoForComparison,
                to: platform,
                template: template
            )
            
            shareHistory.append(result)
            
            if result.success {
                showingShareSuccess = true
                HapticFeedback.success()
            } else {
                shareError = result.error ?? "Unknown sharing error"
                showingShareError = true
                HapticFeedback.error()
            }
            
        } catch {
            shareError = error.localizedDescription
            showingShareError = true
            HapticFeedback.error()
        }
    }
    
    /// Export photo with custom settings
    func exportPhotoWithCustomSettings(
        _ configuration: ExportConfiguration
    ) async -> ExportResult? {
        isSharing = true
        shareProgress = 0.0
        
        defer {
            isSharing = false
            shareProgress = 0.0
        }
        
        do {
            let result = try await exportManager.exportPhoto(
                photo,
                configuration: configuration
            ) { progress in
                await MainActor.run {
                    self.shareProgress = progress
                }
            }
            
            return result
            
        } catch {
            shareError = error.localizedDescription
            showingShareError = true
            HapticFeedback.error()
            return nil
        }
    }
    
    /// Get platform availability status
    func getPlatformAvailability() -> [SocialMediaPlatform: Bool] {
        return socialSharingService.getPlatformAvailability()
    }
    
    /// Clear sharing error
    func clearError() {
        shareError = nil
        showingShareError = false
    }
    
    /// Get sharing statistics
    func getSharingStats() -> SharingStats {
        let totalShares = shareHistory.count
        let successfulShares = shareHistory.filter { $0.success }.count
        let platformBreakdown = Dictionary(grouping: shareHistory) { $0.platform }
            .mapValues { $0.count }
        
        return SharingStats(
            totalShares: totalShares,
            successfulShares: successfulShares,
            failedShares: totalShares - successfulShares,
            platformBreakdown: platformBreakdown,
            lastShareDate: shareHistory.last?.timestamp
        )
    }
    
    // MARK: - Private Methods
    
    private func createExportConfiguration(for platform: SocialMediaPlatform) -> ExportConfiguration {
        let watermarkOptions = WatermarkOptions(
            enabled: includeWatermark,
            text: "✨ Enhanced with Glowly",
            position: .bottomRight,
            style: .subtle,
            opacity: 0.7,
            size: .medium
        )
        
        return ExportConfiguration(
            quality: exportQuality,
            format: platform.recommendedFormat,
            platform: platform,
            customDimensions: platform.optimalDimensions,
            watermark: watermarkOptions,
            preserveMetadata: true,
            includeEnhancementHistory: true
        )
    }
}

// MARK: - Supporting Models

struct SharingStats: Codable {
    let totalShares: Int
    let successfulShares: Int
    let failedShares: Int
    let platformBreakdown: [SocialMediaPlatform: Int]
    let lastShareDate: Date?
    
    var successRate: Double {
        guard totalShares > 0 else { return 0 }
        return Double(successfulShares) / Double(totalShares)
    }
    
    var mostUsedPlatform: SocialMediaPlatform? {
        return platformBreakdown.max { $0.value < $1.value }?.key
    }
}

// MARK: - Share Result Extension

extension ShareResult {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var shareTypeDescription: String {
        return isBeforeAfter ? "Before & After" : "Single Photo"
    }
}

// MARK: - Platform Analytics

struct PlatformAnalytics {
    static func trackShare(platform: SocialMediaPlatform, success: Bool, photo: GlowlyPhoto) {
        // Analytics tracking implementation
        let eventData: [String: Any] = [
            "platform": platform.rawValue,
            "success": success,
            "photo_enhanced": photo.isEnhanced,
            "enhancement_count": photo.enhancementHistory.count,
            "timestamp": Date()
        ]
        
        // Send to analytics service
        print("Analytics: Share event tracked - \(eventData)")
    }
    
    static func trackExport(configuration: ExportConfiguration, result: ExportResult) {
        let eventData: [String: Any] = [
            "quality": configuration.quality.rawValue,
            "format": configuration.format.rawValue,
            "platform": configuration.platform?.rawValue ?? "none",
            "watermark_enabled": configuration.watermark.enabled,
            "success": result.success,
            "file_size": result.fileSize,
            "processing_time": result.processingTime,
            "timestamp": Date()
        ]
        
        print("Analytics: Export event tracked - \(eventData)")
    }
}