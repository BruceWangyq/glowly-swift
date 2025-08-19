//
//  BackgroundEffectsService.swift
//  Glowly
//
//  AI-driven background effects and segmentation system for portrait photography
//

import Foundation
import SwiftUI
import Vision
import CoreImage
import CoreML
import Metal
import MetalKit
import Accelerate

/// Protocol for background effects operations
protocol BackgroundEffectsServiceProtocol {
    func applyBackgroundEffect(_ effect: BackgroundEffect, to image: UIImage, intensity: Float) async throws -> UIImage
    func generatePersonMask(for image: UIImage, quality: MaskingAccuracy) async throws -> UIImage
    func replaceBackground(in image: UIImage, with background: UIImage, feathering: Float) async throws -> UIImage
    func blurBackground(in image: UIImage, intensity: Float, style: BackgroundBlurStyle) async throws -> UIImage
    func applyBackgroundLighting(_ lighting: BackgroundLighting, to image: UIImage) async throws -> UIImage
    func generateBackgroundPreview(_ effect: BackgroundEffect, for image: UIImage, size: CGSize) async throws -> UIImage
    var isProcessing: Bool { get }
    var segmentationAccuracy: Float { get }
}

/// Background blur styles
enum BackgroundBlurStyle: String, Codable, CaseIterable {
    case gaussian = "gaussian"
    case motionBlur = "motion_blur"
    case radialBlur = "radial_blur"
    case bokeh = "bokeh"
    case artistic = "artistic"
    
    var displayName: String {
        switch self {
        case .gaussian: return "Gaussian"
        case .motionBlur: return "Motion Blur"
        case .radialBlur: return "Radial Blur"
        case .bokeh: return "Bokeh"
        case .artistic: return "Artistic"
        }
    }
}

/// Background lighting configurations
struct BackgroundLighting: Codable {
    let type: LightingType
    let intensity: Float
    let color: ColorVector
    let direction: LightDirection
    let softness: Float
    
    enum LightingType: String, Codable, CaseIterable {
        case studio = "studio"
        case natural = "natural"
        case dramatic = "dramatic"
        case ambient = "ambient"
        case directional = "directional"
    }
    
    enum LightDirection: String, Codable, CaseIterable {
        case top = "top"
        case bottom = "bottom"
        case left = "left"
        case right = "right"
        case front = "front"
        case back = "back"
    }
}

/// Advanced background effects service with AI segmentation
@MainActor
final class BackgroundEffectsService: BackgroundEffectsServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var segmentationAccuracy: Float = 0.0
    @Published var processingQuality: ProcessingQuality = .high
    
    private let ciContext: CIContext
    private let metalDevice: MTLDevice?
    private let visionQueue = DispatchQueue(label: "com.glowly.background.vision", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.glowly.background.processing", qos: .userInitiated, attributes: .concurrent)
    
    // AI Models and Vision Requests
    private var personSegmentationRequest: VNGeneratePersonSegmentationRequest?
    private var saliencyRequest: VNGenerateAttentionBasedSaliencyImageRequest?
    private var customSegmentationModel: MLModel?
    
    // Processing engines
    private let segmentationEngine: PersonSegmentationEngine
    private let backgroundBlurEngine: BackgroundBlurEngine
    private let backgroundReplacementEngine: BackgroundReplacementEngine
    private let lightingEngine: BackgroundLightingEngine
    
    // Caching system
    private let maskCache = NSCache<NSString, UIImage>()
    private let effectCache = NSCache<NSString, UIImage>()
    
    // Performance optimization
    private var thermalState: ThermalState = .nominal
    private var adaptiveQuality = true
    
    // MARK: - Initialization
    init() {
        // Initialize Core Image context with Metal
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
            ciContext = CIContext(mtlDevice: metalDevice, options: [
                .cacheIntermediates: false,
                .name: "GlowlyBackgroundEngine"
            ])
        } else {
            self.metalDevice = nil
            ciContext = CIContext(options: [.useSoftwareRenderer: false])
        }
        
        // Initialize processing engines
        segmentationEngine = PersonSegmentationEngine(ciContext: ciContext, metalDevice: metalDevice)
        backgroundBlurEngine = BackgroundBlurEngine(ciContext: ciContext, metalDevice: metalDevice)
        backgroundReplacementEngine = BackgroundReplacementEngine(ciContext: ciContext)
        lightingEngine = BackgroundLightingEngine(ciContext: ciContext)
        
        // Configure caches
        maskCache.countLimit = 30
        maskCache.totalCostLimit = 150 * 1024 * 1024 // 150MB
        effectCache.countLimit = 20
        effectCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        setupVisionRequests()
        setupThermalMonitoring()
    }
    
    // MARK: - Main Processing Methods
    
    /// Apply comprehensive background effect
    func applyBackgroundEffect(_ effect: BackgroundEffect, to image: UIImage, intensity: Float = 1.0) async throws -> UIImage {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        // Check cache first
        let cacheKey = "\(effect.id)_\(image.hashValue)_\(intensity)"
        if let cachedResult = effectCache.object(forKey: cacheKey as NSString) {
            return cachedResult
        }
        
        guard let ciImage = CIImage(image: image) else {
            throw BackgroundEffectsError.invalidImage
        }
        
        processingProgress = 0.1
        
        // Generate high-quality person segmentation mask
        let personMask = try await generatePersonMask(for: image, quality: effect.processingConfig.maskingAccuracy)
        segmentationAccuracy = await segmentationEngine.getLastAccuracyScore()
        
        processingProgress = 0.4
        
        // Apply background effect based on type
        let processedImage = try await applyBackgroundEffectType(
            effect,
            to: ciImage,
            mask: CIImage(image: personMask)!,
            intensity: intensity
        )
        
        processingProgress = 0.9
        
        // Convert to UIImage
        guard let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        let result = UIImage(cgImage: cgImage)
        
        // Cache the result
        effectCache.setObject(result, forKey: cacheKey as NSString)
        
        processingProgress = 1.0
        return result
    }
    
    /// Generate person segmentation mask
    func generatePersonMask(for image: UIImage, quality: MaskingAccuracy = .high) async throws -> UIImage {
        let cacheKey = "\(image.hashValue)_mask_\(quality.rawValue)" as NSString
        
        // Check cache first
        if let cachedMask = maskCache.object(forKey: cacheKey) {
            return cachedMask
        }
        
        let mask = try await segmentationEngine.generatePersonMask(
            for: image,
            quality: quality,
            thermalOptimized: thermalState != .nominal
        )
        
        // Cache the mask
        maskCache.setObject(mask, forKey: cacheKey)
        
        return mask
    }
    
    /// Replace background with custom image
    func replaceBackground(in image: UIImage, with background: UIImage, feathering: Float = 2.0) async throws -> UIImage {
        isProcessing = true
        defer { isProcessing = false }
        
        // Generate person mask
        let personMask = try await generatePersonMask(for: image, quality: .high)
        
        // Replace background
        let result = try await backgroundReplacementEngine.replaceBackground(
            foreground: image,
            background: background,
            mask: personMask,
            feathering: feathering
        )
        
        return result
    }
    
    /// Apply background blur effect
    func blurBackground(in image: UIImage, intensity: Float, style: BackgroundBlurStyle = .gaussian) async throws -> UIImage {
        isProcessing = true
        defer { isProcessing = false }
        
        // Generate person mask
        let personMask = try await generatePersonMask(for: image, quality: .medium)
        
        // Apply background blur
        let result = try await backgroundBlurEngine.applyBlur(
            to: image,
            mask: personMask,
            intensity: intensity,
            style: style
        )
        
        return result
    }
    
    /// Apply background lighting effects
    func applyBackgroundLighting(_ lighting: BackgroundLighting, to image: UIImage) async throws -> UIImage {
        isProcessing = true
        defer { isProcessing = false }
        
        // Generate person mask for selective lighting
        let personMask = try await generatePersonMask(for: image, quality: .medium)
        
        // Apply lighting effect
        let result = try await lightingEngine.applyLighting(
            lighting,
            to: image,
            mask: personMask
        )
        
        return result
    }
    
    /// Generate optimized background effect preview
    func generateBackgroundPreview(_ effect: BackgroundEffect, for image: UIImage, size: CGSize) async throws -> UIImage {
        // Create lower quality version for preview
        let previewConfig = BackgroundProcessingConfig(
            segmentationModel: effect.processingConfig.segmentationModel,
            edgeRefinement: EdgeRefinementConfig(
                featherRadius: 1.0,
                smoothingIterations: 1,
                edgeContrast: 1.0,
                morphologicalOperations: false
            ),
            maskingAccuracy: .medium,
            processingQuality: .standard,
            realTimeOptimized: true
        )
        
        let previewEffect = BackgroundEffect(
            name: effect.name,
            displayName: effect.displayName,
            description: effect.description,
            type: effect.type,
            category: effect.category,
            intensity: effect.intensity * 0.8,
            isPremium: effect.isPremium,
            processingConfig: previewConfig
        )
        
        let resizedImage = resizeImage(image, to: size)
        return try await applyBackgroundEffect(previewEffect, to: resizedImage)
    }
    
    // MARK: - Private Implementation Methods
    
    private func applyBackgroundEffectType(
        _ effect: BackgroundEffect,
        to image: CIImage,
        mask: CIImage,
        intensity: Float
    ) async throws -> CIImage {
        
        switch effect.type {
        case .blur:
            return try await applyBlurEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .replacement:
            return try await applyReplacementEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .colorGrading:
            return try await applyColorGradingEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .lighting:
            return try await applyLightingEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .texture:
            return try await applyTextureEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .pattern:
            return try await applyPatternEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .gradient:
            return try await applyGradientEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
            
        case .artistic:
            return try await applyArtisticEffect(image, mask: mask, intensity: intensity, config: effect.processingConfig)
        }
    }
    
    private func applyBlurEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Create inverted mask for background
        let invertedMask = invertMask(mask)
        
        // Apply blur to background
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = image
        blurFilter.radius = intensity * 20.0 // Scale blur radius
        
        guard let blurredImage = blurFilter.outputImage else {
            throw BackgroundEffectsError.processingFailed
        }
        
        // Composite with mask
        return compositeWithMask(foreground: image, background: blurredImage, mask: mask)
    }
    
    private func applyReplacementEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // This would implement background replacement with custom images
        // For now, apply a simple colored background
        let backgroundColor = CIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // Light blue
        let backgroundImage = CIImage(color: backgroundColor).cropped(to: image.extent)
        
        return compositeWithMask(foreground: image, background: backgroundImage, mask: mask)
    }
    
    private func applyColorGradingEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Apply color grading to background only
        let invertedMask = invertMask(mask)
        
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = image
        colorFilter.saturation = 1.0 + (intensity * 0.5)
        colorFilter.brightness = intensity * 0.2
        
        guard let gradedImage = colorFilter.outputImage else {
            throw BackgroundEffectsError.processingFailed
        }
        
        // Apply only to background using inverted mask
        let maskedGrading = CIFilter.blendWithMask()
        maskedGrading.inputImage = gradedImage
        maskedGrading.backgroundImage = image
        maskedGrading.maskImage = invertedMask
        
        return maskedGrading.outputImage ?? image
    }
    
    private func applyLightingEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Apply lighting effects to background
        let lightingFilter = CIFilter.colorControls()
        lightingFilter.inputImage = image
        lightingFilter.brightness = intensity * 0.3
        lightingFilter.contrast = 1.0 + (intensity * 0.2)
        
        guard let litImage = lightingFilter.outputImage else {
            throw BackgroundEffectsError.processingFailed
        }
        
        let invertedMask = invertMask(mask)
        return applyMaskedEffect(original: image, effect: litImage, mask: invertedMask)
    }
    
    private func applyTextureEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Apply texture overlay to background
        // This would use procedural textures or texture images
        return image
    }
    
    private func applyPatternEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Apply pattern overlay to background
        // This would generate or use predefined patterns
        return image
    }
    
    private func applyGradientEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Create gradient background
        let gradientFilter = CIFilter.linearGradient()
        gradientFilter.point0 = CGPoint(x: 0, y: 0)
        gradientFilter.point1 = CGPoint(x: 0, y: image.extent.height)
        gradientFilter.color0 = CIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)
        gradientFilter.color1 = CIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
        
        guard let gradientImage = gradientFilter.outputImage?.cropped(to: image.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        return compositeWithMask(foreground: image, background: gradientImage, mask: mask)
    }
    
    private func applyArtisticEffect(_ image: CIImage, mask: CIImage, intensity: Float, config: BackgroundProcessingConfig) async throws -> CIImage {
        // Apply artistic filters to background
        let invertedMask = invertMask(mask)
        
        let artisticFilter = CIFilter.crystallize()
        artisticFilter.inputImage = image
        artisticFilter.radius = intensity * 10.0
        
        guard let artisticImage = artisticFilter.outputImage else {
            throw BackgroundEffectsError.processingFailed
        }
        
        return applyMaskedEffect(original: image, effect: artisticImage, mask: invertedMask)
    }
    
    // MARK: - Helper Methods
    
    private func invertMask(_ mask: CIImage) -> CIImage {
        let invertFilter = CIFilter.colorInvert()
        invertFilter.inputImage = mask
        return invertFilter.outputImage ?? mask
    }
    
    private func compositeWithMask(foreground: CIImage, background: CIImage, mask: CIImage) -> CIImage {
        let composite = CIFilter.blendWithMask()
        composite.inputImage = foreground
        composite.backgroundImage = background
        composite.maskImage = mask
        return composite.outputImage ?? foreground
    }
    
    private func applyMaskedEffect(original: CIImage, effect: CIImage, mask: CIImage) -> CIImage {
        let maskedEffect = CIFilter.blendWithMask()
        maskedEffect.inputImage = effect
        maskedEffect.backgroundImage = original
        maskedEffect.maskImage = mask
        return maskedEffect.outputImage ?? original
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - System Setup and Monitoring
    
    private func setupVisionRequests() {
        if #available(iOS 15.0, *) {
            personSegmentationRequest = VNGeneratePersonSegmentationRequest()
            personSegmentationRequest?.qualityLevel = .balanced
            personSegmentationRequest?.outputPixelFormat = kCVPixelFormatType_OneComponent8
        }
        
        saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
    }
    
    private func setupThermalMonitoring() {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalState()
        }
        
        updateThermalState()
    }
    
    private func updateThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            thermalState = .nominal
            processingQuality = .high
        case .fair:
            thermalState = .fair
            processingQuality = .high
        case .serious:
            thermalState = .serious
            processingQuality = .standard
        case .critical:
            thermalState = .critical
            processingQuality = .draft
        @unknown default:
            thermalState = .nominal
            processingQuality = .high
        }
    }
}

// MARK: - Background Processing Engines

/// Person segmentation engine with multiple AI models
class PersonSegmentationEngine {
    private let ciContext: CIContext
    private let metalDevice: MTLDevice?
    private var lastAccuracyScore: Float = 0.0
    
    init(ciContext: CIContext, metalDevice: MTLDevice?) {
        self.ciContext = ciContext
        self.metalDevice = metalDevice
    }
    
    func generatePersonMask(for image: UIImage, quality: MaskingAccuracy, thermalOptimized: Bool) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw BackgroundEffectsError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: BackgroundEffectsError.processingFailed)
                    return
                }
                
                do {
                    let mask = try self.performSegmentation(cgImage: cgImage, quality: quality, thermalOptimized: thermalOptimized)
                    continuation.resume(returning: mask)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getLastAccuracyScore() async -> Float {
        return lastAccuracyScore
    }
    
    private func performSegmentation(cgImage: CGImage, quality: MaskingAccuracy, thermalOptimized: Bool) throws -> UIImage {
        if #available(iOS 15.0, *) {
            return try performVisionSegmentation(cgImage: cgImage, quality: quality)
        } else {
            return try performFallbackSegmentation(cgImage: cgImage)
        }
    }
    
    @available(iOS 15.0, *)
    private func performVisionSegmentation(cgImage: CGImage, quality: MaskingAccuracy) throws -> UIImage {
        let request = VNGeneratePersonSegmentationRequest()
        
        switch quality {
        case .low:
            request.qualityLevel = .fast
        case .medium:
            request.qualityLevel = .balanced
        case .high, .ultra:
            request.qualityLevel = .accurate
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let result = request.results?.first,
              let maskPixelBuffer = result.pixelBuffer else {
            throw BackgroundEffectsError.segmentationFailed
        }
        
        // Convert pixel buffer to UIImage
        let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let cgMask = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        // Calculate accuracy score based on mask quality
        lastAccuracyScore = calculateSegmentationAccuracy(mask: ciImage)
        
        return UIImage(cgImage: cgMask)
    }
    
    private func performFallbackSegmentation(cgImage: CGImage) throws -> UIImage {
        // Fallback segmentation using basic image processing
        // This would implement a simplified person detection algorithm
        lastAccuracyScore = 0.7 // Lower accuracy for fallback
        
        // Create a simple mask based on image center
        let width = cgImage.width
        let height = cgImage.height
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let mask = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let centerRect = CGRect(
                x: width / 4,
                y: height / 6,
                width: width / 2,
                height: height * 2 / 3
            )
            
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fill(rect)
            
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: centerRect)
        }
        
        return mask
    }
    
    private func calculateSegmentationAccuracy(mask: CIImage) -> Float {
        // This would implement quality assessment of the segmentation mask
        // For now, return a fixed value
        return 0.92
    }
}

/// Background blur engine with multiple blur styles
class BackgroundBlurEngine {
    private let ciContext: CIContext
    private let metalDevice: MTLDevice?
    
    init(ciContext: CIContext, metalDevice: MTLDevice?) {
        self.ciContext = ciContext
        self.metalDevice = metalDevice
    }
    
    func applyBlur(to image: UIImage, mask: UIImage, intensity: Float, style: BackgroundBlurStyle) async throws -> UIImage {
        guard let ciImage = CIImage(image: image),
              let ciMask = CIImage(image: mask) else {
            throw BackgroundEffectsError.invalidImage
        }
        
        // Apply blur based on style
        let blurredImage = try applyBlurStyle(to: ciImage, intensity: intensity, style: style)
        
        // Composite with mask
        let composite = CIFilter.blendWithMask()
        composite.inputImage = ciImage
        composite.backgroundImage = blurredImage
        composite.maskImage = invertMask(ciMask)
        
        guard let result = composite.outputImage,
              let cgImage = ciContext.createCGImage(result, from: result.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyBlurStyle(to image: CIImage, intensity: Float, style: BackgroundBlurStyle) throws -> CIImage {
        switch style {
        case .gaussian:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = image
            filter.radius = intensity * 20.0
            return filter.outputImage ?? image
            
        case .motionBlur:
            let filter = CIFilter.motionBlur()
            filter.inputImage = image
            filter.radius = intensity * 15.0
            filter.angle = Float.pi / 4 // 45 degrees
            return filter.outputImage ?? image
            
        case .radialBlur:
            // Custom radial blur implementation
            return applyRadialBlur(to: image, intensity: intensity)
            
        case .bokeh:
            return applyBokehEffect(to: image, intensity: intensity)
            
        case .artistic:
            let filter = CIFilter.crystallize()
            filter.inputImage = image
            filter.radius = intensity * 8.0
            return filter.outputImage ?? image
        }
    }
    
    private func applyRadialBlur(to image: CIImage, intensity: Float) -> CIImage {
        // Implement radial blur using zoom blur
        let filter = CIFilter.zoomBlur()
        filter.inputImage = image
        filter.center = CGPoint(x: image.extent.midX, y: image.extent.midY)
        filter.amount = intensity * 10.0
        return filter.outputImage ?? image
    }
    
    private func applyBokehEffect(to image: CIImage, intensity: Float) -> CIImage {
        // Simulate bokeh effect with disc blur
        let filter = CIFilter.discBlur()
        filter.inputImage = image
        filter.radius = intensity * 12.0
        return filter.outputImage ?? image
    }
    
    private func invertMask(_ mask: CIImage) -> CIImage {
        let invertFilter = CIFilter.colorInvert()
        invertFilter.inputImage = mask
        return invertFilter.outputImage ?? mask
    }
}

/// Background replacement engine
class BackgroundReplacementEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func replaceBackground(foreground: UIImage, background: UIImage, mask: UIImage, feathering: Float) async throws -> UIImage {
        guard let fgImage = CIImage(image: foreground),
              let bgImage = CIImage(image: background),
              let maskImage = CIImage(image: mask) else {
            throw BackgroundEffectsError.invalidImage
        }
        
        // Resize background to match foreground
        let resizedBackground = resizeBackground(bgImage, to: fgImage.extent.size)
        
        // Apply feathering to mask
        let featheredMask = applyFeathering(to: maskImage, radius: feathering)
        
        // Composite images
        let composite = CIFilter.blendWithMask()
        composite.inputImage = fgImage
        composite.backgroundImage = resizedBackground
        composite.maskImage = featheredMask
        
        guard let result = composite.outputImage,
              let cgImage = ciContext.createCGImage(result, from: result.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func resizeBackground(_ background: CIImage, to size: CGSize) -> CIImage {
        let scaleX = size.width / background.extent.width
        let scaleY = size.height / background.extent.height
        let scale = max(scaleX, scaleY) // Scale to fill
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledBackground = background.transformed(by: transform)
        
        // Center and crop
        let offsetX = (scaledBackground.extent.width - size.width) / 2
        let offsetY = (scaledBackground.extent.height - size.height) / 2
        let cropRect = CGRect(x: offsetX, y: offsetY, width: size.width, height: size.height)
        
        return scaledBackground.cropped(to: cropRect)
    }
    
    private func applyFeathering(to mask: CIImage, radius: Float) -> CIImage {
        guard radius > 0 else { return mask }
        
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = mask
        blurFilter.radius = radius
        
        return blurFilter.outputImage ?? mask
    }
}

/// Background lighting engine
class BackgroundLightingEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func applyLighting(_ lighting: BackgroundLighting, to image: UIImage, mask: UIImage) async throws -> UIImage {
        guard let ciImage = CIImage(image: image),
              let ciMask = CIImage(image: mask) else {
            throw BackgroundEffectsError.invalidImage
        }
        
        // Apply lighting effect based on type
        let litImage = try applyLightingType(lighting, to: ciImage)
        
        // Apply only to background using inverted mask
        let invertedMask = invertMask(ciMask)
        let composite = CIFilter.blendWithMask()
        composite.inputImage = litImage
        composite.backgroundImage = ciImage
        composite.maskImage = invertedMask
        
        guard let result = composite.outputImage,
              let cgImage = ciContext.createCGImage(result, from: result.extent) else {
            throw BackgroundEffectsError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyLightingType(_ lighting: BackgroundLighting, to image: CIImage) throws -> CIImage {
        switch lighting.type {
        case .studio:
            return applyStudioLighting(to: image, lighting: lighting)
        case .natural:
            return applyNaturalLighting(to: image, lighting: lighting)
        case .dramatic:
            return applyDramaticLighting(to: image, lighting: lighting)
        case .ambient:
            return applyAmbientLighting(to: image, lighting: lighting)
        case .directional:
            return applyDirectionalLighting(to: image, lighting: lighting)
        }
    }
    
    private func applyStudioLighting(to image: CIImage, lighting: BackgroundLighting) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = lighting.intensity * 0.3
        filter.contrast = 1.0 + (lighting.intensity * 0.2)
        return filter.outputImage ?? image
    }
    
    private func applyNaturalLighting(to image: CIImage, lighting: BackgroundLighting) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 5500 + (lighting.intensity * 1000), y: 0)
        return filter.outputImage ?? image
    }
    
    private func applyDramaticLighting(to image: CIImage, lighting: BackgroundLighting) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.0 + (lighting.intensity * 0.5)
        filter.saturation = 1.0 + (lighting.intensity * 0.3)
        return filter.outputImage ?? image
    }
    
    private func applyAmbientLighting(to image: CIImage, lighting: BackgroundLighting) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = lighting.intensity * 0.15
        return filter.outputImage ?? image
    }
    
    private func applyDirectionalLighting(to image: CIImage, lighting: BackgroundLighting) -> CIImage {
        // This would implement directional lighting effects
        // For now, apply basic brightness adjustment
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = lighting.intensity * 0.25
        filter.contrast = 1.0 + (lighting.intensity * 0.15)
        return filter.outputImage ?? image
    }
    
    private func invertMask(_ mask: CIImage) -> CIImage {
        let invertFilter = CIFilter.colorInvert()
        invertFilter.inputImage = mask
        return invertFilter.outputImage ?? mask
    }
}

// MARK: - Background Effects Errors

enum BackgroundEffectsError: LocalizedError {
    case invalidImage
    case processingFailed
    case segmentationFailed
    case maskGenerationFailed
    case unsupportedEffect
    case insufficientMemory
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image format is not supported or the image is corrupted."
        case .processingFailed:
            return "Background effect processing failed. Please try again."
        case .segmentationFailed:
            return "Failed to separate person from background. Please use a photo with a clear subject."
        case .maskGenerationFailed:
            return "Failed to generate segmentation mask."
        case .unsupportedEffect:
            return "This background effect is not supported on your device."
        case .insufficientMemory:
            return "Not enough memory available to process this background effect."
        }
    }
}