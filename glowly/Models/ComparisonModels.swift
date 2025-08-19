//
//  ComparisonModels.swift
//  Glowly
//
//  Comprehensive models for before/after comparison system
//

import SwiftUI
import CoreGraphics

// MARK: - ComparisonMode
enum ComparisonMode: String, CaseIterable, Identifiable, Codable {
    case swipeReveal = "Swipe Reveal"
    case sideBySide = "Side by Side"
    case toggle = "Toggle"
    case splitScreen = "Split Screen"
    case overlay = "Overlay"
    case fullScreen = "Full Screen"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .swipeReveal: return "slider.horizontal.2.goforward"
        case .sideBySide: return "rectangle.split.2x1"
        case .toggle: return "arrow.left.arrow.right"
        case .splitScreen: return "rectangle.split.1x2"
        case .overlay: return "photo.stack"
        case .fullScreen: return "arrow.up.left.and.arrow.down.right"
        }
    }
    
    var description: String {
        switch self {
        case .swipeReveal: return "Swipe to reveal before/after"
        case .sideBySide: return "View both images side by side"
        case .toggle: return "Tap to switch between images"
        case .splitScreen: return "Adjustable split view"
        case .overlay: return "Animated transition overlay"
        case .fullScreen: return "Full screen detailed view"
        }
    }
    
    var supportsZoom: Bool {
        switch self {
        case .swipeReveal, .sideBySide, .splitScreen, .fullScreen:
            return true
        case .toggle, .overlay:
            return false
        }
    }
    
    var supportsPan: Bool {
        return supportsZoom
    }
}

// MARK: - SplitDirection
enum SplitDirection: String, CaseIterable, Codable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    
    var icon: String {
        switch self {
        case .horizontal: return "rectangle.split.2x1"
        case .vertical: return "rectangle.split.1x2"
        }
    }
}

// MARK: - ComparisonState
struct ComparisonState {
    var currentMode: ComparisonMode = .sideBySide
    var splitDirection: SplitDirection = .horizontal
    var sliderPosition: CGFloat = 0.5
    var overlayProgress: Double = 0.0
    var isShowingBefore: Bool = true
    var zoomLevel: CGFloat = 1.0
    var panOffset: CGSize = .zero
    var lastPanOffset: CGSize = .zero
    var isZoomSynced: Bool = true
    var showingMagnifier: Bool = false
    var magnifierPosition: CGPoint = .zero
}

// MARK: - ExportOptions
struct ExportOptions {
    var format: ExportFormat = .collage
    var includeWatermark: Bool = true
    var socialPlatform: SocialPlatform? = nil
    var customTemplate: ComparisonTemplate? = nil
    var videoTransition: VideoTransition? = nil
    
    enum ExportFormat: String, CaseIterable {
        case collage = "Collage"
        case splitImage = "Split Image"
        case animatedGIF = "Animated GIF"
        case video = "Video"
        
        var icon: String {
            switch self {
            case .collage: return "photo.stack"
            case .splitImage: return "rectangle.split.2x1"
            case .animatedGIF: return "photo.badge.ellipsis"
            case .video: return "video"
            }
        }
    }
    
    enum SocialPlatform: String, CaseIterable {
        case instagram = "Instagram"
        case tiktok = "TikTok"
        case snapchat = "Snapchat"
        case facebook = "Facebook"
        case twitter = "Twitter"
        
        var aspectRatio: CGSize {
            switch self {
            case .instagram: return CGSize(width: 1, height: 1)
            case .tiktok: return CGSize(width: 9, height: 16)
            case .snapchat: return CGSize(width: 9, height: 16)
            case .facebook: return CGSize(width: 16, height: 9)
            case .twitter: return CGSize(width: 16, height: 9)
            }
        }
        
        var icon: String {
            switch self {
            case .instagram: return "camera.aperture"
            case .tiktok: return "music.note"
            case .snapchat: return "camera.viewfinder"
            case .facebook: return "person.2"
            case .twitter: return "bird"
            }
        }
    }
    
    enum VideoTransition: String, CaseIterable {
        case fade = "Fade"
        case slide = "Slide"
        case zoom = "Zoom"
        case flip = "Flip"
        case morph = "Morph"
        
        var duration: TimeInterval {
            switch self {
            case .fade: return 1.0
            case .slide: return 0.8
            case .zoom: return 1.2
            case .flip: return 0.6
            case .morph: return 1.5
            }
        }
    }
}

// MARK: - ComparisonTemplate
struct ComparisonTemplate: Identifiable {
    let id = UUID()
    let name: String
    let layout: TemplateLayout
    let textOverlays: [TextOverlay]
    let backgroundStyle: BackgroundStyle
    let borderStyle: BorderStyle?
    
    enum TemplateLayout {
        case sideBySide
        case topBottom
        case overlaid
        case carousel
        case beforeAfterSlider
    }
    
    struct TextOverlay {
        let text: String
        let position: CGPoint
        let font: Font
        let color: Color
        let backgroundColor: Color?
        let opacity: Double
    }
    
    enum BackgroundStyle {
        case solid(Color)
        case gradient([Color])
        case pattern(String)
        case transparent
    }
    
    struct BorderStyle {
        let color: Color
        let width: CGFloat
        let cornerRadius: CGFloat
    }
    
    static let defaultTemplates: [ComparisonTemplate] = [
        ComparisonTemplate(
            name: "Classic",
            layout: .sideBySide,
            textOverlays: [
                TextOverlay(text: "BEFORE", position: CGPoint(x: 0.25, y: 0.05), font: .caption, color: .white, backgroundColor: .black.opacity(0.6), opacity: 0.9),
                TextOverlay(text: "AFTER", position: CGPoint(x: 0.75, y: 0.05), font: .caption, color: .white, backgroundColor: .black.opacity(0.6), opacity: 0.9)
            ],
            backgroundStyle: .solid(.white),
            borderStyle: BorderStyle(color: .gray.opacity(0.3), width: 1, cornerRadius: 8)
        ),
        ComparisonTemplate(
            name: "Modern",
            layout: .beforeAfterSlider,
            textOverlays: [],
            backgroundStyle: .gradient([Color.black, Color.gray]),
            borderStyle: nil
        ),
        ComparisonTemplate(
            name: "Social",
            layout: .topBottom,
            textOverlays: [
                TextOverlay(text: "✨ Enhanced with Glowly", position: CGPoint(x: 0.5, y: 0.95), font: .footnote, color: .white, backgroundColor: .clear, opacity: 1.0)
            ],
            backgroundStyle: .solid(.black),
            borderStyle: BorderStyle(color: .white, width: 2, cornerRadius: 12)
        )
    ]
}

// MARK: - EnhancementHighlight
struct EnhancementHighlight: Identifiable {
    let id = UUID()
    let region: CGRect
    let enhancementType: EnhancementType
    let intensity: Double
    let color: Color
    
    enum EnhancementType: String, CaseIterable {
        case skinSmoothing = "Skin Smoothing"
        case eyeBrightening = "Eye Brightening"
        case teethWhitening = "Teeth Whitening"
        case faceSlimming = "Face Slimming"
        case backgroundBlur = "Background Blur"
        case colorCorrection = "Color Correction"
        
        var color: Color {
            switch self {
            case .skinSmoothing: return .pink
            case .eyeBrightening: return .blue
            case .teethWhitening: return .white
            case .faceSlimming: return .purple
            case .backgroundBlur: return .gray
            case .colorCorrection: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .skinSmoothing: return "face.smiling"
            case .eyeBrightening: return "eye"
            case .teethWhitening: return "mouth"
            case .faceSlimming: return "oval"
            case .backgroundBlur: return "circle.fill"
            case .colorCorrection: return "paintbrush"
            }
        }
    }
}

// MARK: - ComparisonAnalytics
struct ComparisonAnalytics {
    var viewDuration: TimeInterval = 0
    var modeUsageCount: [ComparisonMode: Int] = [:]
    var exportCount: [ExportOptions.ExportFormat: Int] = [:]
    var zoomLevel: CGFloat = 1.0
    var interactionCount: Int = 0
    var shareCount: Int = 0
    
    mutating func recordModeUsage(_ mode: ComparisonMode) {
        modeUsageCount[mode, default: 0] += 1
    }
    
    mutating func recordExport(_ format: ExportOptions.ExportFormat) {
        exportCount[format, default: 0] += 1
    }
    
    mutating func recordInteraction() {
        interactionCount += 1
    }
    
    mutating func recordShare() {
        shareCount += 1
    }
}

// MARK: - UserPreferences
struct ComparisonPreferences: Codable {
    var defaultMode: ComparisonMode = .sideBySide
    var enableHaptics: Bool = true
    var autoSaveComparisons: Bool = false
    var watermarkEnabled: Bool = true
    var defaultExportFormat: ExportOptions.ExportFormat = .collage
    var zoomSensitivity: Double = 1.0
    var panSensitivity: Double = 1.0
    var enableMagnifier: Bool = true
    var magnifierSize: CGFloat = 100
    var showEnhancementHighlights: Bool = true
    var preferredSplitDirection: SplitDirection = .horizontal
    var enableAutoTransitions: Bool = false
    var transitionSpeed: Double = 1.0
    
    static let shared = ComparisonPreferences()
}

// MARK: - PerformanceMetrics
struct PerformanceMetrics {
    var imageLoadTime: TimeInterval = 0
    var renderTime: TimeInterval = 0
    var memoryUsage: Double = 0
    var thermalState: ProcessInfo.ThermalState = .nominal
    var batteryLevel: Float = 1.0
    var frameRate: Double = 60.0
    
    var isPerformanceOptimal: Bool {
        return imageLoadTime < 0.5 && 
               renderTime < 0.1 && 
               memoryUsage < 500_000_000 && // 500MB
               thermalState != .critical &&
               frameRate >= 30.0
    }
    
    var shouldOptimizeForPerformance: Bool {
        return !isPerformanceOptimal || 
               thermalState == .serious ||
               batteryLevel < 0.2
    }
}

// MARK: - GestureConfiguration
struct GestureConfiguration {
    var panSensitivity: CGFloat = 1.0
    var zoomSensitivity: CGFloat = 1.0
    var minimumZoom: CGFloat = 0.5
    var maximumZoom: CGFloat = 4.0
    var doubleTapZoomLevel: CGFloat = 2.0
    var hapticFeedbackEnabled: Bool = true
    var gestureVelocityThreshold: CGFloat = 300
    var longPressDelay: TimeInterval = 0.5
    
    // Accessibility configurations
    var voiceOverEnabled: Bool = false
    var largeTextEnabled: Bool = false
    var reduceMotionEnabled: Bool = false
    var increaseContrastEnabled: Bool = false
}

// MARK: - ImageQuality
struct ImageQuality {
    var compression: CGFloat = 0.9
    var maxDimension: CGFloat = 2048
    var format: ImageFormat = .jpeg
    var preserveMetadata: Bool = false
    
    enum ImageFormat: String, CaseIterable {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
        
        var fileExtension: String {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            case .heic: return "heic"
            }
        }
        
        var supportsTransparency: Bool {
            return self == .png
        }
    }
    
    static let high = ImageQuality(compression: 0.95, maxDimension: 4096, format: .heic)
    static let medium = ImageQuality(compression: 0.85, maxDimension: 2048, format: .jpeg)
    static let low = ImageQuality(compression: 0.7, maxDimension: 1024, format: .jpeg)
}