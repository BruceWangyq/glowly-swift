//
//  ManualRetouchingService.swift
//  Glowly
//
//  Service for advanced manual retouching operations with brush-based application
//

import Foundation
import SwiftUI
import Metal
import MetalKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// Protocol for manual retouching operations
protocol ManualRetouchingServiceProtocol {
    func applyBrushOperation(_ operation: ManualRetouchingOperation, to image: UIImage) async throws -> ManualRetouchingResult
    func detectFaceRegions(in image: UIImage) async throws -> DetectedFaceRegions
    func createMask(from touchPoints: [TouchPoint], imageSize: CGSize, brushConfig: BrushConfiguration) -> UIImage?
    func blendImages(_ base: UIImage, _ overlay: UIImage, mask: UIImage, blendMode: BlendMode) -> UIImage?
    func generateColorPalette(for region: FaceRegion, from image: UIImage) async -> ColorPalette?
}

/// Advanced manual retouching service with GPU acceleration and face detection
@MainActor
final class ManualRetouchingService: ManualRetouchingServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    private let metalDevice: MTLDevice?
    private let ciContext: CIContext
    private let visionQueue = DispatchQueue(label: "com.glowly.vision", qos: .userInitiated)
    
    // Face detection
    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3
        return request
    }()
    
    private lazy var faceLandmarksRequest: VNDetectFaceLandmarksRequest = {
        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision3
        return request
    }()
    
    // MARK: - Initialization
    init() {
        metalDevice = MTLCreateSystemDefaultDevice()
        
        if let metalDevice = metalDevice {
            ciContext = CIContext(mtlDevice: metalDevice)
        } else {
            ciContext = CIContext()
        }
    }
    
    // MARK: - Main Processing Methods
    
    /// Apply a brush-based manual retouching operation
    func applyBrushOperation(_ operation: ManualRetouchingOperation, to image: UIImage) async throws -> ManualRetouchingResult {
        let startTime = Date()
        
        do {
            // Create mask from touch points
            guard let mask = createMask(
                from: operation.touchPoints,
                imageSize: image.size,
                brushConfig: operation.brushConfiguration
            ) else {
                throw ManualRetouchingError.maskCreationFailed
            }
            
            // Apply enhancement to the entire image
            let enhancement = Enhancement(
                type: operation.enhancementType,
                intensity: operation.intensity,
                parameters: operation.parameters
            )
            
            let imageProcessingService = ImageProcessingService()
            let enhancedImage = try await imageProcessingService.applyEnhancement(enhancement, to: image)
            
            // Blend enhanced image with original using mask
            guard let finalImage = blendImages(
                image,
                enhancedImage,
                mask: mask,
                blendMode: operation.brushConfiguration.blendMode
            ) else {
                throw ManualRetouchingError.blendingFailed
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Convert result to data
            let imageData = finalImage.jpegData(compressionQuality: 0.9)
            let maskData = mask.jpegData(compressionQuality: 0.8)
            
            // Calculate quality metrics
            let qualityMetrics = calculateQualityMetrics(
                original: image,
                processed: finalImage,
                enhancement: operation.enhancementType
            )
            
            return ManualRetouchingResult(
                operationId: operation.id,
                enhancementType: operation.enhancementType,
                processedImageData: imageData,
                maskData: maskData,
                processingTime: processingTime,
                success: true,
                qualityMetrics: qualityMetrics
            )
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            return ManualRetouchingResult(
                operationId: operation.id,
                enhancementType: operation.enhancementType,
                processingTime: processingTime,
                success: false,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    // MARK: - Face Detection
    
    /// Detect face regions for targeted enhancements
    func detectFaceRegions(in image: UIImage) async throws -> DetectedFaceRegions {
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ManualRetouchingError.serviceUnavailable)
                    return
                }
                
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: ManualRetouchingError.invalidImage)
                    return
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    // Perform face detection
                    try handler.perform([self.faceDetectionRequest, self.faceLandmarksRequest])
                    
                    let detectedRegions = self.processFaceDetectionResults()
                    continuation.resume(returning: detectedRegions)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processFaceDetectionResults() -> DetectedFaceRegions {
        var faceRect = CGRect.zero
        var regions: [FaceRegion: CGRect] = [:]
        var landmarks: [FaceLandmark] = []
        var confidence: Float = 0.0
        
        // Process face rectangles
        if let faceResults = faceDetectionRequest.results?.first {
            faceRect = faceResults.boundingBox
            confidence = faceResults.confidence
            
            // Estimate face regions from bounding box
            regions = estimateFaceRegions(from: faceRect)
        }
        
        // Process face landmarks
        if let landmarkResults = faceLandmarksRequest.results?.first {
            landmarks = processFaceLandmarks(landmarkResults)
        }
        
        return DetectedFaceRegions(
            faceRect: faceRect,
            regions: regions,
            landmarks: landmarks,
            confidence: confidence
        )
    }
    
    private func estimateFaceRegions(from faceRect: CGRect) -> [FaceRegion: CGRect] {
        var regions: [FaceRegion: CGRect] = [:]
        
        // Estimate regions based on face proportions
        let faceWidth = faceRect.width
        let faceHeight = faceRect.height
        
        // Eyes (upper third of face)
        let eyeY = faceRect.minY + faceHeight * 0.25
        let eyeHeight = faceHeight * 0.15
        let eyeWidth = faceWidth * 0.25
        
        regions[.leftEye] = CGRect(
            x: faceRect.minX + faceWidth * 0.2,
            y: eyeY,
            width: eyeWidth,
            height: eyeHeight
        )
        
        regions[.rightEye] = CGRect(
            x: faceRect.minX + faceWidth * 0.55,
            y: eyeY,
            width: eyeWidth,
            height: eyeHeight
        )
        
        // Nose (center of face)
        regions[.nose] = CGRect(
            x: faceRect.minX + faceWidth * 0.4,
            y: faceRect.minY + faceHeight * 0.35,
            width: faceWidth * 0.2,
            height: faceHeight * 0.25
        )
        
        // Mouth (lower third)
        regions[.mouth] = CGRect(
            x: faceRect.minX + faceWidth * 0.3,
            y: faceRect.minY + faceHeight * 0.65,
            width: faceWidth * 0.4,
            height: faceHeight * 0.2
        )
        
        // Skin regions
        regions[.skin] = faceRect
        regions[.forehead] = CGRect(
            x: faceRect.minX,
            y: faceRect.minY,
            width: faceWidth,
            height: faceHeight * 0.3
        )
        
        regions[.cheeks] = CGRect(
            x: faceRect.minX,
            y: faceRect.minY + faceHeight * 0.3,
            width: faceWidth,
            height: faceHeight * 0.4
        )
        
        regions[.chin] = CGRect(
            x: faceRect.minX + faceWidth * 0.2,
            y: faceRect.minY + faceHeight * 0.8,
            width: faceWidth * 0.6,
            height: faceHeight * 0.2
        )
        
        return regions
    }
    
    private func processFaceLandmarks(_ landmarkResult: VNFaceObservation) -> [FaceLandmark] {
        var landmarks: [FaceLandmark] = []
        
        if let leftEye = landmarkResult.landmarks?.leftEye {
            let points = leftEye.normalizedPoints.map { CGPoint(x: $0.x, y: 1 - $0.y) }
            landmarks.append(FaceLandmark(type: .leftEyeContour, points: points, confidence: landmarkResult.confidence))
        }
        
        if let rightEye = landmarkResult.landmarks?.rightEye {
            let points = rightEye.normalizedPoints.map { CGPoint(x: $0.x, y: 1 - $0.y) }
            landmarks.append(FaceLandmark(type: .rightEyeContour, points: points, confidence: landmarkResult.confidence))
        }
        
        if let nose = landmarkResult.landmarks?.nose {
            let points = nose.normalizedPoints.map { CGPoint(x: $0.x, y: 1 - $0.y) }
            landmarks.append(FaceLandmark(type: .noseContour, points: points, confidence: landmarkResult.confidence))
        }
        
        if let outerLips = landmarkResult.landmarks?.outerLips {
            let points = outerLips.normalizedPoints.map { CGPoint(x: $0.x, y: 1 - $0.y) }
            landmarks.append(FaceLandmark(type: .lipContour, points: points, confidence: landmarkResult.confidence))
        }
        
        if let faceContour = landmarkResult.landmarks?.faceContour {
            let points = faceContour.normalizedPoints.map { CGPoint(x: $0.x, y: 1 - $0.y) }
            landmarks.append(FaceLandmark(type: .faceContour, points: points, confidence: landmarkResult.confidence))
        }
        
        return landmarks
    }
    
    // MARK: - Mask Creation
    
    /// Create a mask from touch points and brush configuration
    func createMask(from touchPoints: [TouchPoint], imageSize: CGSize, brushConfig: BrushConfiguration) -> UIImage? {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Set up context for mask drawing
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(origin: .zero, size: scaledSize))
        
        // Configure brush
        context.setBlendMode(.normal)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw brush strokes
        for i in 0..<touchPoints.count {
            let point = touchPoints[i]
            let scaledPoint = CGPoint(
                x: point.location.x * scale,
                y: point.location.y * scale
            )
            
            // Calculate brush size with pressure sensitivity
            let brushSize = CGFloat(brushConfig.size * point.pressure * scale)
            let alpha = CGFloat(brushConfig.opacity * brushConfig.flow * point.pressure)
            
            // Create brush stroke
            if brushConfig.hardness > 0.8 {
                // Hard brush
                context.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                context.fillEllipse(in: CGRect(
                    x: scaledPoint.x - brushSize / 2,
                    y: scaledPoint.y - brushSize / 2,
                    width: brushSize,
                    height: brushSize
                ))
            } else {
                // Soft brush with gradient
                drawSoftBrush(
                    at: scaledPoint,
                    size: brushSize,
                    hardness: CGFloat(brushConfig.hardness),
                    alpha: alpha,
                    in: context
                )
            }
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func drawSoftBrush(at point: CGPoint, size: CGFloat, hardness: CGFloat, alpha: CGFloat, in context: CGContext) {
        let radius = size / 2
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let gradientColors = [
            UIColor.white.withAlphaComponent(alpha).cgColor,
            UIColor.white.withAlphaComponent(alpha * hardness).cgColor,
            UIColor.clear.cgColor
        ]
        
        let locations: [CGFloat] = [0.0, hardness, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: gradientColors as CFArray,
            locations: locations
        ) else { return }
        
        context.drawRadialGradient(
            gradient,
            startCenter: point,
            startRadius: 0,
            endCenter: point,
            endRadius: radius,
            options: []
        )
    }
    
    // MARK: - Image Blending
    
    /// Blend two images using a mask and blend mode
    func blendImages(_ base: UIImage, _ overlay: UIImage, mask: UIImage, blendMode: BlendMode) -> UIImage? {
        guard let baseCIImage = CIImage(image: base),
              let overlayCIImage = CIImage(image: overlay),
              let maskCIImage = CIImage(image: mask) else {
            return nil
        }
        
        // Apply mask to overlay image
        let maskedOverlay = overlayCIImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputImageKey: overlayCIImage,
            kCIInputMaskImageKey: maskCIImage
        ])
        
        // Blend masked overlay with base
        let blendFilter = getBlendFilter(for: blendMode)
        blendFilter.setValue(baseCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(maskedOverlay, forKey: kCIInputBackgroundImageKey)
        
        guard let outputCIImage = blendFilter.outputImage,
              let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func getBlendFilter(for blendMode: BlendMode) -> CIFilter {
        switch blendMode {
        case .normal:
            return CIFilter.sourceOverCompositing()
        case .overlay:
            return CIFilter.overlayBlendMode()
        case .softLight:
            return CIFilter.softLightBlendMode()
        case .hardLight:
            return CIFilter.hardLightBlendMode()
        case .multiply:
            return CIFilter.multiplyBlendMode()
        case .screen:
            return CIFilter.screenBlendMode()
        case .colorDodge:
            return CIFilter.colorDodgeBlendMode()
        case .colorBurn:
            return CIFilter.colorBurnBlendMode()
        case .lighten:
            return CIFilter.lightenBlendMode()
        case .darken:
            return CIFilter.darkenBlendMode()
        }
    }
    
    // MARK: - Color Analysis
    
    /// Generate a color palette for a specific face region
    func generateColorPalette(for region: FaceRegion, from image: UIImage) async -> ColorPalette? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Sample colors from the region
                let colors = self.sampleColorsFromRegion(region, in: cgImage)
                
                let palette = ColorPalette(
                    name: "\(region.displayName) Colors",
                    colors: colors,
                    category: .natural
                )
                
                continuation.resume(returning: palette)
            }
        }
    }
    
    private func sampleColorsFromRegion(_ region: FaceRegion, in cgImage: CGImage) -> [ColorInfo] {
        // This would implement sophisticated color sampling
        // For now, return some default colors based on region
        switch region {
        case .eyes:
            return ColorPalette.naturalEyeColors.colors
        case .hair:
            return ColorPalette.naturalHairColors.colors
        case .lips, .mouth:
            return ColorPalette.naturalLipColors.colors
        default:
            return [
                ColorInfo(name: "Sample 1", red: 0.8, green: 0.7, blue: 0.6),
                ColorInfo(name: "Sample 2", red: 0.7, green: 0.6, blue: 0.5),
                ColorInfo(name: "Sample 3", red: 0.9, green: 0.8, blue: 0.7)
            ]
        }
    }
    
    // MARK: - Quality Metrics
    
    private func calculateQualityMetrics(
        original: UIImage,
        processed: UIImage,
        enhancement: EnhancementType
    ) -> ProcessingQualityMetrics {
        // This would implement sophisticated quality analysis
        // For now, provide reasonable estimates based on enhancement type
        
        let baseQuality: Float = 0.85
        let naturalness: Float = enhancement.category == .ai ? 0.75 : 0.9
        let sharpness: Float = enhancement == .clarity ? 0.95 : 0.85
        let colorAccuracy: Float = 0.9
        let artifactLevel: Float = enhancement.isPremium ? 0.1 : 0.2
        
        return ProcessingQualityMetrics(
            overallQuality: baseQuality,
            naturalness: naturalness,
            sharpness: sharpness,
            colorAccuracy: colorAccuracy,
            artifactLevel: artifactLevel
        )
    }
}

// MARK: - Manual Retouching Errors

enum ManualRetouchingError: LocalizedError {
    case invalidImage
    case maskCreationFailed
    case blendingFailed
    case faceDetectionFailed
    case serviceUnavailable
    case insufficientMemory
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image format is not supported or the image is corrupted."
        case .maskCreationFailed:
            return "Failed to create brush mask from touch points."
        case .blendingFailed:
            return "Failed to blend images with the specified blend mode."
        case .faceDetectionFailed:
            return "Face detection failed. Please try with a clearer image."
        case .serviceUnavailable:
            return "Manual retouching service is temporarily unavailable."
        case .insufficientMemory:
            return "Not enough memory available to process this operation."
        }
    }
}