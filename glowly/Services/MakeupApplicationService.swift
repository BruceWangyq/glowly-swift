//
//  MakeupApplicationService.swift
//  Glowly
//
//  Advanced makeup application system with face landmark detection and realistic blending
//

import Foundation
import SwiftUI
import Vision
import CoreImage
import CoreML
import Metal
import MetalKit

/// Protocol for makeup application operations
protocol MakeupApplicationServiceProtocol {
    func applyMakeupLook(_ look: MakeupLook, to image: UIImage, intensity: Float) async throws -> UIImage
    func applyMakeupComponent(_ component: MakeupComponent, to image: UIImage, intensity: Float) async throws -> UIImage
    func detectFaceLandmarks(in image: UIImage) async throws -> [VNFaceObservation]
    func generateMakeupPreview(_ look: MakeupLook, for image: UIImage, size: CGSize) async throws -> UIImage
    func adaptMakeupForSkinTone(_ look: MakeupLook, skinTone: SkinTone) -> MakeupLook
    func blendMakeupLayers(_ layers: [CIImage], blendModes: [FilterBlendMode]) -> CIImage
    var isProcessing: Bool { get }
}

/// Advanced makeup application service with face detection and realistic blending
@MainActor
final class MakeupApplicationService: MakeupApplicationServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var detectedSkinTone: SkinTone?
    
    private let ciContext: CIContext
    private let metalDevice: MTLDevice?
    private let visionQueue = DispatchQueue(label: "com.glowly.makeup.vision", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.glowly.makeup.processing", qos: .userInitiated, attributes: .concurrent)
    
    // Face detection and landmark analysis
    private var faceLandmarkDetector: VNDetectFaceLandmarksRequest
    private var faceQualityRequest: VNDetectFaceQualityRequest?
    private var skinToneDetector: VNClassifyImageRequest?
    
    // Makeup application engines
    private let foundationEngine: FoundationApplicationEngine
    private let eyeMakeupEngine: EyeMakeupApplicationEngine
    private let lipMakeupEngine: LipMakeupApplicationEngine
    private let blushEngine: BlushApplicationEngine
    private let contourEngine: ContourApplicationEngine
    
    // Caching and optimization
    private let landmarkCache = NSCache<NSString, NSArray>()
    private let skinToneCache = NSCache<NSString, NSNumber>()
    
    // MARK: - Initialization
    init() {
        // Initialize Core Image context
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
            ciContext = CIContext(mtlDevice: metalDevice, options: [
                .cacheIntermediates: false,
                .name: "GlowlyMakeupEngine"
            ])
        } else {
            self.metalDevice = nil
            ciContext = CIContext(options: [.useSoftwareRenderer: false])
        }
        
        // Initialize face detection
        faceLandmarkDetector = VNDetectFaceLandmarksRequest()
        faceLandmarkDetector.revision = VNDetectFaceLandmarksRequestRevision3
        
        if #available(iOS 13.0, *) {
            faceQualityRequest = VNDetectFaceQualityRequest()
        }
        
        // Initialize makeup application engines
        foundationEngine = FoundationApplicationEngine(ciContext: ciContext)
        eyeMakeupEngine = EyeMakeupApplicationEngine(ciContext: ciContext)
        lipMakeupEngine = LipMakeupApplicationEngine(ciContext: ciContext)
        blushEngine = BlushApplicationEngine(ciContext: ciContext)
        contourEngine = ContourApplicationEngine(ciContext: ciContext)
        
        // Configure caches
        landmarkCache.countLimit = 50
        skinToneCache.countLimit = 100
        
        setupSkinToneDetection()
    }
    
    // MARK: - Main Application Methods
    
    /// Apply complete makeup look to an image
    func applyMakeupLook(_ look: MakeupLook, to image: UIImage, intensity: Float = 1.0) async throws -> UIImage {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        guard let ciImage = CIImage(image: image) else {
            throw MakeupApplicationError.invalidImage
        }
        
        // Detect face landmarks
        let faceObservations = try await detectFaceLandmarks(in: image)
        guard !faceObservations.isEmpty else {
            throw MakeupApplicationError.noFaceDetected
        }
        
        processingProgress = 0.2
        
        // Detect skin tone for color adaptation
        let skinTone = await detectSkinTone(in: image)
        let adaptedLook = adaptMakeupForSkinTone(look, skinTone: skinTone)
        
        processingProgress = 0.3
        
        // Sort components by layer order for proper application
        let sortedComponents = adaptedLook.components.sorted { $0.layerOrder < $1.layerOrder }
        var makeupLayers: [CIImage] = []
        var blendModes: [FilterBlendMode] = []
        
        // Apply each makeup component
        let totalComponents = Float(sortedComponents.count)
        for (index, component) in sortedComponents.enumerated() {
            let layer = try await applyMakeupComponentToLayer(
                component,
                to: ciImage,
                faceObservations: faceObservations,
                intensity: intensity
            )
            
            makeupLayers.append(layer)
            blendModes.append(component.blendMode)
            
            processingProgress = 0.3 + (Float(index + 1) / totalComponents) * 0.6
        }
        
        // Blend all makeup layers
        let finalImage = blendMakeupLayers(makeupLayers, blendModes: blendModes)
        
        processingProgress = 0.95
        
        // Convert to UIImage
        guard let cgImage = ciContext.createCGImage(finalImage, from: finalImage.extent) else {
            throw MakeupApplicationError.processingFailed
        }
        
        processingProgress = 1.0
        return UIImage(cgImage: cgImage)
    }
    
    /// Apply individual makeup component
    func applyMakeupComponent(_ component: MakeupComponent, to image: UIImage, intensity: Float = 1.0) async throws -> UIImage {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let ciImage = CIImage(image: image) else {
            throw MakeupApplicationError.invalidImage
        }
        
        let faceObservations = try await detectFaceLandmarks(in: image)
        guard !faceObservations.isEmpty else {
            throw MakeupApplicationError.noFaceDetected
        }
        
        let processedImage = try await applyMakeupComponentToLayer(
            component,
            to: ciImage,
            faceObservations: faceObservations,
            intensity: intensity
        )
        
        guard let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent) else {
            throw MakeupApplicationError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Detect face landmarks in image
    func detectFaceLandmarks(in image: UIImage) async throws -> [VNFaceObservation] {
        let cacheKey = "\(image.hashValue)" as NSString
        
        // Check cache first
        if let cachedLandmarks = landmarkCache.object(forKey: cacheKey) as? [VNFaceObservation] {
            return cachedLandmarks
        }
        
        guard let cgImage = image.cgImage else {
            throw MakeupApplicationError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: MakeupApplicationError.processingFailed)
                    return
                }
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try requestHandler.perform([self.faceLandmarkDetector])
                    
                    let faceObservations = self.faceLandmarkDetector.results ?? []
                    
                    // Cache the results
                    self.landmarkCache.setObject(faceObservations as NSArray, forKey: cacheKey)
                    
                    continuation.resume(returning: faceObservations)
                } catch {
                    continuation.resume(throwing: MakeupApplicationError.faceDetectionFailed)
                }
            }
        }
    }
    
    /// Generate optimized makeup preview
    func generateMakeupPreview(_ look: MakeupLook, for image: UIImage, size: CGSize) async throws -> UIImage {
        // Create a simplified version for preview
        let simplifiedComponents = look.components.filter { !$0.isOptional }
        
        let previewLook = MakeupLook(
            name: look.name,
            displayName: look.displayName,
            description: look.description,
            category: look.category,
            style: look.style,
            components: simplifiedComponents,
            isPremium: look.isPremium,
            difficulty: look.difficulty
        )
        
        let resizedImage = resizeImage(image, to: size)
        return try await applyMakeupLook(previewLook, to: resizedImage, intensity: 0.7)
    }
    
    /// Adapt makeup colors for different skin tones
    func adaptMakeupForSkinTone(_ look: MakeupLook, skinTone: SkinTone) -> MakeupLook {
        let adaptedComponents = look.components.map { component in
            adaptMakeupComponentForSkinTone(component, skinTone: skinTone)
        }
        
        return MakeupLook(
            id: look.id,
            name: look.name,
            displayName: look.displayName,
            description: look.description,
            category: look.category,
            style: look.style,
            components: adaptedComponents,
            isPremium: look.isPremium,
            isPopular: look.isPopular,
            difficulty: look.difficulty,
            estimatedTime: look.estimatedTime,
            authorInfo: look.authorInfo,
            socialMetadata: look.socialMetadata,
            thumbnailName: look.thumbnailName,
            createdAt: look.createdAt
        )
    }
    
    /// Blend multiple makeup layers with different blend modes
    func blendMakeupLayers(_ layers: [CIImage], blendModes: [FilterBlendMode]) -> CIImage {
        guard !layers.isEmpty else {
            return CIImage(color: .clear)
        }
        
        var result = layers[0]
        
        for i in 1..<layers.count {
            let blendMode = i < blendModes.count ? blendModes[i] : .normal
            result = blendImages(background: result, foreground: layers[i], mode: blendMode)
        }
        
        return result
    }
    
    // MARK: - Private Implementation Methods
    
    private func applyMakeupComponentToLayer(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        
        switch component.type {
        case .foundation, .concealer:
            return try await foundationEngine.apply(
                component,
                to: image,
                faceObservations: faceObservations,
                intensity: intensity
            )
            
        case .eyeshadow, .eyeliner, .mascara, .eyebrows:
            return try await eyeMakeupEngine.apply(
                component,
                to: image,
                faceObservations: faceObservations,
                intensity: intensity
            )
            
        case .lipstick, .lipGloss, .lipLiner:
            return try await lipMakeupEngine.apply(
                component,
                to: image,
                faceObservations: faceObservations,
                intensity: intensity
            )
            
        case .blush, .highlighter:
            return try await blushEngine.apply(
                component,
                to: image,
                faceObservations: faceObservations,
                intensity: intensity
            )
            
        case .bronzer, .contour:
            return try await contourEngine.apply(
                component,
                to: image,
                faceObservations: faceObservations,
                intensity: intensity
            )
        }
    }
    
    private func detectSkinTone(in image: UIImage) async -> SkinTone {
        let cacheKey = "\(image.hashValue)_skintone" as NSString
        
        if let cachedTone = skinToneCache.object(forKey: cacheKey)?.intValue,
           let skinTone = SkinTone.allCases.first(where: { $0.rawValue == String(cachedTone) }) {
            return skinTone
        }
        
        // Simplified skin tone detection - in production this would use ML
        let averageColor = await calculateAverageImageColor(image)
        let detectedTone = classifySkinTone(from: averageColor)
        
        skinToneCache.setObject(NSNumber(value: SkinTone.allCases.firstIndex(of: detectedTone) ?? 0), forKey: cacheKey)
        
        return detectedTone
    }
    
    private func calculateAverageImageColor(_ image: UIImage) async -> UIColor {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                guard let cgImage = image.cgImage,
                      let dataProvider = cgImage.dataProvider,
                      let data = dataProvider.data,
                      let pixels = CFDataGetBytePtr(data) else {
                    continuation.resume(returning: .gray)
                    return
                }
                
                let pixelCount = cgImage.width * cgImage.height
                var totalRed: UInt64 = 0
                var totalGreen: UInt64 = 0
                var totalBlue: UInt64 = 0
                
                for i in 0..<pixelCount {
                    let pixelIndex = i * 4
                    totalRed += UInt64(pixels[pixelIndex])
                    totalGreen += UInt64(pixels[pixelIndex + 1])
                    totalBlue += UInt64(pixels[pixelIndex + 2])
                }
                
                let averageRed = CGFloat(totalRed) / CGFloat(pixelCount) / 255.0
                let averageGreen = CGFloat(totalGreen) / CGFloat(pixelCount) / 255.0
                let averageBlue = CGFloat(totalBlue) / CGFloat(pixelCount) / 255.0
                
                let averageColor = UIColor(red: averageRed, green: averageGreen, blue: averageBlue, alpha: 1.0)
                continuation.resume(returning: averageColor)
            }
        }
    }
    
    private func classifySkinTone(from color: UIColor) -> SkinTone {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let brightness = (red + green + blue) / 3.0
        
        switch brightness {
        case 0.0..<0.3:
            return .rich
        case 0.3..<0.45:
            return .deep
        case 0.45..<0.6:
            return .tan
        case 0.6..<0.75:
            return .medium
        case 0.75..<0.85:
            return .light
        default:
            return .fair
        }
    }
    
    private func adaptMakeupComponentForSkinTone(_ component: MakeupComponent, skinTone: SkinTone) -> MakeupComponent {
        // Check if this makeup color is compatible with the detected skin tone
        guard !component.color.skinToneCompatibility.contains(skinTone) else {
            return component
        }
        
        // Adjust color for skin tone compatibility
        let adaptedColor = adaptColorForSkinTone(component.color, targetSkinTone: skinTone)
        
        return MakeupComponent(
            id: component.id,
            type: component.type,
            color: adaptedColor,
            intensity: component.intensity,
            blendMode: component.blendMode,
            applicationArea: component.applicationArea,
            layerOrder: component.layerOrder,
            isOptional: component.isOptional
        )
    }
    
    private func adaptColorForSkinTone(_ color: MakeupColor, targetSkinTone: SkinTone) -> MakeupColor {
        // This would implement sophisticated color adaptation algorithms
        // For now, return the original color
        return color
    }
    
    private func blendImages(background: CIImage, foreground: CIImage, mode: FilterBlendMode) -> CIImage {
        let filterName = mode.ciFilterName
        
        guard let filter = CIFilter(name: filterName) else {
            return background
        }
        
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        filter.setValue(foreground, forKey: kCIInputImageKey)
        
        return filter.outputImage ?? background
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func setupSkinToneDetection() {
        // Setup CoreML model for skin tone detection if available
        // This would load a custom trained model for accurate skin tone classification
    }
}

// MARK: - Makeup Application Engines

/// Foundation and base makeup application engine
class FoundationApplicationEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func apply(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        // Generate face mask for foundation application
        let faceMask = generateFaceMask(from: faceObservations, imageSize: image.extent.size)
        
        // Create foundation color overlay
        let foundationColor = CIColor(
            red: CGFloat(component.color.rgb.r),
            green: CGFloat(component.color.rgb.g),
            blue: CGFloat(component.color.rgb.b),
            alpha: CGFloat(component.color.opacity * intensity)
        )
        
        let foundationLayer = CIImage(color: foundationColor).cropped(to: image.extent)
        
        // Apply foundation with face mask
        let maskedFoundation = applyMask(foundationLayer, mask: faceMask)
        
        // Blend with original image
        return blendWithSkinTone(background: image, foreground: maskedFoundation, component: component)
    }
    
    private func generateFaceMask(from observations: [VNFaceObservation], imageSize: CGSize) -> CIImage {
        // Create face mask from landmarks
        // This is a simplified implementation
        guard let face = observations.first else {
            return CIImage(color: .clear).cropped(to: CGRect(origin: .zero, size: imageSize))
        }
        
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))
        let maskRect = CGRect(origin: .zero, size: imageSize)
        
        // Create simple circular mask for face area
        let mask = CIImage(color: .clear).cropped(to: maskRect)
        return mask
    }
    
    private func applyMask(_ image: CIImage, mask: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.backgroundImage = CIImage(color: .clear).cropped(to: image.extent)
        filter.maskImage = mask
        return filter.outputImage ?? image
    }
    
    private func blendWithSkinTone(background: CIImage, foreground: CIImage, component: MakeupComponent) -> CIImage {
        let filterName = component.blendMode.ciFilterName
        guard let filter = CIFilter(name: filterName) else {
            return background
        }
        
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        filter.setValue(foreground, forKey: kCIInputImageKey)
        
        return filter.outputImage ?? background
    }
}

/// Eye makeup application engine
class EyeMakeupApplicationEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func apply(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        // This would implement detailed eye makeup application
        // using precise landmark detection for eyes
        return image
    }
}

/// Lip makeup application engine
class LipMakeupApplicationEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func apply(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        // This would implement detailed lip makeup application
        // using precise landmark detection for lips
        return image
    }
}

/// Blush and highlighting application engine
class BlushApplicationEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func apply(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        // This would implement detailed blush and highlighting
        // using facial structure analysis
        return image
    }
}

/// Contouring application engine
class ContourApplicationEngine {
    private let ciContext: CIContext
    
    init(ciContext: CIContext) {
        self.ciContext = ciContext
    }
    
    func apply(
        _ component: MakeupComponent,
        to image: CIImage,
        faceObservations: [VNFaceObservation],
        intensity: Float
    ) async throws -> CIImage {
        // This would implement detailed contouring
        // using facial structure analysis
        return image
    }
}

// MARK: - Makeup Application Errors

enum MakeupApplicationError: LocalizedError {
    case invalidImage
    case noFaceDetected
    case faceDetectionFailed
    case processingFailed
    case unsupportedMakeupType
    case skinToneDetectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image format is not supported or the image is corrupted."
        case .noFaceDetected:
            return "No face was detected in the image. Please use a photo with a clear face."
        case .faceDetectionFailed:
            return "Face detection failed. Please try again."
        case .processingFailed:
            return "Makeup application failed. Please try again."
        case .unsupportedMakeupType:
            return "This makeup type is not supported."
        case .skinToneDetectionFailed:
            return "Failed to detect skin tone for color adaptation."
        }
    }
}