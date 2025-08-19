//
//  CoreEnhancementAlgorithms.swift
//  Glowly
//
//  Core enhancement algorithms for skin, teeth, eyes, and lighting processing
//

import Foundation
import UIKit
import CoreImage
import Vision
import CoreML

/// Face enhancement processor for beauty-specific algorithms
final class FaceEnhancementProcessor {
    
    private let ciContext: CIContext
    private let faceDetector: VNDetectFaceRectanglesRequest
    private let faceLandmarksDetector: VNDetectFaceLandmarksRequest
    
    init() {
        self.ciContext = CIContext(options: [.useSoftwareRenderer: false])
        self.faceDetector = VNDetectFaceRectanglesRequest()
        self.faceLandmarksDetector = VNDetectFaceLandmarksRequest()
    }
    
    // MARK: - Skin Enhancement
    
    /// Apply intelligent skin smoothing with texture preservation
    func applySkinSmoothing(_ image: CIImage, intensity: Float) async throws -> CIImage {
        // Detect face regions first
        let faceRegions = try await detectFaceRegions(in: image)
        
        guard !faceRegions.isEmpty else {
            // No face detected, apply gentle overall smoothing
            return try await applyGlobalSkinSmoothing(image, intensity: intensity * 0.3)
        }
        
        var result = image
        
        for faceRegion in faceRegions {
            // Create face mask
            let faceMask = try await createFaceMask(for: faceRegion, in: image)
            
            // Apply skin smoothing only to face area
            let smoothedFace = try await applySkinSmoothingToRegion(
                image: image,
                region: faceRegion,
                mask: faceMask,
                intensity: intensity
            )
            
            // Blend smoothed face with original image
            result = try await blendFaceEnhancement(
                original: result,
                enhanced: smoothedFace,
                mask: faceMask
            )
        }
        
        return result
    }
    
    private func applySkinSmoothingToRegion(
        image: CIImage,
        region: CGRect,
        mask: CIImage,
        intensity: Float
    ) async throws -> CIImage {
        
        // Create bilateral filter for skin smoothing while preserving edges
        let bilateralFilter = CIFilter(name: "CIBilateralBlur")!
        bilateralFilter.setValue(image.cropped(to: region), forKey: kCIInputImageKey)
        bilateralFilter.setValue(intensity * 8.0, forKey: "inputRadius")
        
        guard let smoothed = bilateralFilter.outputImage else {
            throw EnhancementError.filterFailed("Bilateral filter failed")
        }
        
        // Apply noise reduction
        let noiseReduction = CIFilter(name: "CINoiseReduction")!
        noiseReduction.setValue(smoothed, forKey: kCIInputImageKey)
        noiseReduction.setValue(intensity * 0.1, forKey: "inputNoiseLevel")
        noiseReduction.setValue(intensity * 0.8, forKey: "inputSharpness")
        
        guard let denoised = noiseReduction.outputImage else {
            throw EnhancementError.filterFailed("Noise reduction failed")
        }
        
        // Blend with original to preserve natural texture
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(image.cropped(to: region), forKey: kCIInputImageKey)
        blendFilter.setValue(denoised, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? image.cropped(to: region)
    }
    
    private func applyGlobalSkinSmoothing(_ image: CIImage, intensity: Float) async throws -> CIImage {
        // Gentle global smoothing for images without detected faces
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")!
        gaussianFilter.setValue(image, forKey: kCIInputImageKey)
        gaussianFilter.setValue(intensity * 2.0, forKey: kCIInputRadiusKey)
        
        guard let blurred = gaussianFilter.outputImage else {
            throw EnhancementError.filterFailed("Gaussian blur failed")
        }
        
        // Blend with original
        let blendFilter = CIFilter(name: "CISourceOverCompositing")!
        blendFilter.setValue(blurred, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Eye Enhancement
    
    /// Apply eye brightening and enhancement
    func applyEyeBrightening(_ image: CIImage, intensity: Float) async throws -> CIImage {
        let eyeRegions = try await detectEyeRegions(in: image)
        
        guard !eyeRegions.isEmpty else {
            return image // No eyes detected
        }
        
        var result = image
        
        for eyeRegion in eyeRegions {
            // Create eye mask
            let eyeMask = try await createEyeMask(for: eyeRegion, in: image)
            
            // Apply brightening
            let brightenedEye = try await applyEyeBrighteningToRegion(
                image: image,
                region: eyeRegion,
                intensity: intensity
            )
            
            // Apply contrast enhancement
            let enhancedEye = try await applyEyeContrastEnhancement(
                image: brightenedEye,
                region: eyeRegion,
                intensity: intensity * 0.6
            )
            
            // Apply subtle sharpening
            let sharpenedEye = try await applyEyeSharpening(
                image: enhancedEye,
                region: eyeRegion,
                intensity: intensity * 0.4
            )
            
            // Blend with original
            result = try await blendRegionEnhancement(
                original: result,
                enhanced: sharpenedEye,
                region: eyeRegion,
                mask: eyeMask,
                blendMode: "multiply"
            )
        }
        
        return result
    }
    
    private func applyEyeBrighteningToRegion(
        image: CIImage,
        region: CGRect,
        intensity: Float
    ) async throws -> CIImage {
        
        // Brightness adjustment
        let brightnessFilter = CIFilter(name: "CIColorControls")!
        brightnessFilter.setValue(image.cropped(to: region), forKey: kCIInputImageKey)
        brightnessFilter.setValue(intensity * 0.3, forKey: kCIInputBrightnessKey)
        brightnessFilter.setValue(1.0 + (intensity * 0.2), forKey: kCIInputContrastKey)
        
        return brightnessFilter.outputImage ?? image.cropped(to: region)
    }
    
    private func applyEyeContrastEnhancement(
        image: CIImage,
        region: CGRect,
        intensity: Float
    ) async throws -> CIImage {
        
        // Enhance contrast specifically for eyes
        let contrastFilter = CIFilter(name: "CIColorControls")!
        contrastFilter.setValue(image.cropped(to: region), forKey: kCIInputImageKey)
        contrastFilter.setValue(1.0 + (intensity * 0.4), forKey: kCIInputContrastKey)
        contrastFilter.setValue(1.0 + (intensity * 0.1), forKey: kCIInputSaturationKey)
        
        return contrastFilter.outputImage ?? image.cropped(to: region)
    }
    
    private func applyEyeSharpening(
        image: CIImage,
        region: CGRect,
        intensity: Float
    ) async throws -> CIImage {
        
        // Subtle sharpening for eye definition
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")!
        sharpenFilter.setValue(image.cropped(to: region), forKey: kCIInputImageKey)
        sharpenFilter.setValue(intensity * 0.8, forKey: kCIInputSharpnessKey)
        
        return sharpenFilter.outputImage ?? image.cropped(to: region)
    }
    
    // MARK: - Teeth Whitening
    
    /// Apply intelligent teeth whitening
    func applyTeethWhitening(_ image: CIImage, intensity: Float) async throws -> CIImage {
        let teethRegions = try await detectTeethRegions(in: image)
        
        guard !teethRegions.isEmpty else {
            return image // No teeth detected
        }
        
        var result = image
        
        for teethRegion in teethRegions {
            // Create teeth mask
            let teethMask = try await createTeethMask(for: teethRegion, in: image)
            
            // Apply whitening
            let whitenedTeeth = try await applyTeethWhiteningToRegion(
                image: image,
                region: teethRegion,
                intensity: intensity
            )
            
            // Blend with original
            result = try await blendRegionEnhancement(
                original: result,
                enhanced: whitenedTeeth,
                region: teethRegion,
                mask: teethMask,
                blendMode: "lighten"
            )
        }
        
        return result
    }
    
    private func applyTeethWhiteningToRegion(
        image: CIImage,
        region: CGRect,
        intensity: Float
    ) async throws -> CIImage {
        
        // Selective color adjustment for teeth whitening
        let teethArea = image.cropped(to: region)
        
        // Increase brightness in yellow/brown tones (teeth)
        let colorCorrection = CIFilter(name: "CIColorControls")!
        colorCorrection.setValue(teethArea, forKey: kCIInputImageKey)
        colorCorrection.setValue(intensity * 0.4, forKey: kCIInputBrightnessKey)
        colorCorrection.setValue(1.0 - (intensity * 0.2), forKey: kCIInputSaturationKey) // Reduce yellow saturation
        
        guard let brightened = colorCorrection.outputImage else {
            return teethArea
        }
        
        // Apply temperature adjustment to reduce yellow cast
        let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
        temperatureFilter.setValue(brightened, forKey: kCIInputImageKey)
        temperatureFilter.setValue(CIVector(x: 6500 + (intensity * 1000), y: 0), forKey: "inputNeutral")
        temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        
        return temperatureFilter.outputImage ?? brightened
    }
    
    // MARK: - Blemish Removal
    
    /// Apply automatic blemish detection and removal
    func applyBlemishRemoval(_ image: CIImage, intensity: Float) async throws -> CIImage {
        let blemishRegions = try await detectBlemishRegions(in: image)
        
        guard !blemishRegions.isEmpty else {
            return image // No blemishes detected
        }
        
        var result = image
        
        for blemish in blemishRegions {
            result = try await removeBlemish(
                from: result,
                blemish: blemish,
                intensity: intensity
            )
        }
        
        return result
    }
    
    private func removeBlemish(
        from image: CIImage,
        blemish: BlemishRegion,
        intensity: Float
    ) async throws -> CIImage {
        
        // Use median filter for blemish removal
        let medianFilter = CIFilter(name: "CIMedianFilter")!
        medianFilter.setValue(image.cropped(to: blemish.region), forKey: kCIInputImageKey)
        
        guard let filtered = medianFilter.outputImage else {
            return image
        }
        
        // Create soft-edge mask for natural blending
        let mask = try await createSoftCircularMask(
            center: blemish.center,
            radius: blemish.radius,
            feather: blemish.radius * 0.5
        )
        
        // Blend the filtered area with original
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(filtered, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Face Detection Helpers
    
    private func detectFaceRegions(in image: CIImage) async throws -> [CGRect] {
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            try? requestHandler.perform([faceDetector])
            
            let faceRegions = faceDetector.results?.compactMap { result in
                let boundingBox = result.boundingBox
                return VNImageRectForNormalizedRect(boundingBox, Int(image.extent.width), Int(image.extent.height))
            } ?? []
            
            continuation.resume(returning: faceRegions)
        }
    }
    
    private func detectEyeRegions(in image: CIImage) async throws -> [CGRect] {
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            try? requestHandler.perform([faceLandmarksDetector])
            
            var eyeRegions: [CGRect] = []
            
            if let results = faceLandmarksDetector.results {
                for result in results {
                    if let landmarks = result.landmarks {
                        // Left eye
                        if let leftEye = landmarks.leftEye {
                            let eyeRegion = calculateEyeRegion(from: leftEye, faceRect: result.boundingBox, imageSize: image.extent.size)
                            eyeRegions.append(eyeRegion)
                        }
                        
                        // Right eye
                        if let rightEye = landmarks.rightEye {
                            let eyeRegion = calculateEyeRegion(from: rightEye, faceRect: result.boundingBox, imageSize: image.extent.size)
                            eyeRegions.append(eyeRegion)
                        }
                    }
                }
            }
            
            continuation.resume(returning: eyeRegions)
        }
    }
    
    private func detectTeethRegions(in image: CIImage) async throws -> [CGRect] {
        // Simplified teeth detection - in production, this would use a specialized ML model
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
            
            try? requestHandler.perform([faceLandmarksDetector])
            
            var teethRegions: [CGRect] = []
            
            if let results = faceLandmarksDetector.results {
                for result in results {
                    if let landmarks = result.landmarks,
                       let outerLips = landmarks.outerLips {
                        
                        let teethRegion = calculateTeethRegion(from: outerLips, faceRect: result.boundingBox, imageSize: image.extent.size)
                        teethRegions.append(teethRegion)
                    }
                }
            }
            
            continuation.resume(returning: teethRegions)
        }
    }
    
    private func detectBlemishRegions(in image: CIImage) async throws -> [BlemishRegion] {
        // Simplified blemish detection - in production, this would use ML models
        // For now, we'll simulate some blemish detection
        return []
    }
    
    // MARK: - Helper Methods
    
    private func createFaceMask(for region: CGRect, in image: CIImage) async throws -> CIImage {
        // Create a soft elliptical mask for the face region
        let maskFilter = CIFilter(name: "CIRadialGradient")!
        maskFilter.setValue(CIVector(x: region.midX, y: region.midY), forKey: "inputCenter")
        maskFilter.setValue(min(region.width, region.height) * 0.3, forKey: "inputRadius0")
        maskFilter.setValue(min(region.width, region.height) * 0.5, forKey: "inputRadius1")
        maskFilter.setValue(CIColor.white, forKey: "inputColor0")
        maskFilter.setValue(CIColor.clear, forKey: "inputColor1")
        
        return maskFilter.outputImage?.cropped(to: image.extent) ?? image
    }
    
    private func createEyeMask(for region: CGRect, in image: CIImage) async throws -> CIImage {
        // Create a circular mask for eye region
        let maskFilter = CIFilter(name: "CIRadialGradient")!
        maskFilter.setValue(CIVector(x: region.midX, y: region.midY), forKey: "inputCenter")
        maskFilter.setValue(min(region.width, region.height) * 0.2, forKey: "inputRadius0")
        maskFilter.setValue(min(region.width, region.height) * 0.4, forKey: "inputRadius1")
        maskFilter.setValue(CIColor.white, forKey: "inputColor0")
        maskFilter.setValue(CIColor.clear, forKey: "inputColor1")
        
        return maskFilter.outputImage?.cropped(to: image.extent) ?? image
    }
    
    private func createTeethMask(for region: CGRect, in image: CIImage) async throws -> CIImage {
        // Create a rectangular mask with soft edges for teeth
        let maskFilter = CIFilter(name: "CIRadialGradient")!
        maskFilter.setValue(CIVector(x: region.midX, y: region.midY), forKey: "inputCenter")
        maskFilter.setValue(min(region.width, region.height) * 0.1, forKey: "inputRadius0")
        maskFilter.setValue(min(region.width, region.height) * 0.3, forKey: "inputRadius1")
        maskFilter.setValue(CIColor.white, forKey: "inputColor0")
        maskFilter.setValue(CIColor.clear, forKey: "inputColor1")
        
        return maskFilter.outputImage?.cropped(to: image.extent) ?? image
    }
    
    private func createSoftCircularMask(center: CGPoint, radius: Float, feather: Float) async throws -> CIImage {
        let maskFilter = CIFilter(name: "CIRadialGradient")!
        maskFilter.setValue(CIVector(x: center.x, y: center.y), forKey: "inputCenter")
        maskFilter.setValue(radius - feather, forKey: "inputRadius0")
        maskFilter.setValue(radius, forKey: "inputRadius1")
        maskFilter.setValue(CIColor.white, forKey: "inputColor0")
        maskFilter.setValue(CIColor.clear, forKey: "inputColor1")
        
        return maskFilter.outputImage ?? CIImage.empty()
    }
    
    private func blendFaceEnhancement(
        original: CIImage,
        enhanced: CIImage,
        mask: CIImage
    ) async throws -> CIImage {
        
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(enhanced, forKey: kCIInputImageKey)
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? original
    }
    
    private func blendRegionEnhancement(
        original: CIImage,
        enhanced: CIImage,
        region: CGRect,
        mask: CIImage,
        blendMode: String
    ) async throws -> CIImage {
        
        // Composite the enhanced region back into the original image
        let sourceOverFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverFilter.setValue(enhanced.cropped(to: region), forKey: kCIInputImageKey)
        sourceOverFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        
        return sourceOverFilter.outputImage ?? original
    }
    
    private func calculateEyeRegion(from eyeLandmarks: VNFaceLandmarkRegion2D, faceRect: CGRect, imageSize: CGSize) -> CGRect {
        let points = eyeLandmarks.normalizedPoints
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        let eyeRect = CGRect(
            x: minX * faceRect.width + faceRect.minX,
            y: minY * faceRect.height + faceRect.minY,
            width: (maxX - minX) * faceRect.width,
            height: (maxY - minY) * faceRect.height
        )
        
        // Expand slightly for better coverage
        return eyeRect.insetBy(dx: -eyeRect.width * 0.2, dy: -eyeRect.height * 0.2)
    }
    
    private func calculateTeethRegion(from lipLandmarks: VNFaceLandmarkRegion2D, faceRect: CGRect, imageSize: CGSize) -> CGRect {
        let points = lipLandmarks.normalizedPoints
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        // Create teeth region as subset of lip region
        let lipRect = CGRect(
            x: minX * faceRect.width + faceRect.minX,
            y: minY * faceRect.height + faceRect.minY,
            width: (maxX - minX) * faceRect.width,
            height: (maxY - minY) * faceRect.height
        )
        
        // Teeth are typically in the center portion of lips
        return CGRect(
            x: lipRect.minX + lipRect.width * 0.2,
            y: lipRect.minY + lipRect.height * 0.3,
            width: lipRect.width * 0.6,
            height: lipRect.height * 0.4
        )
    }
}

// MARK: - Supporting Types

struct BlemishRegion {
    let region: CGRect
    let center: CGPoint
    let radius: Float
    let severity: Float
}

/// Enhancement errors
enum EnhancementError: LocalizedError {
    case filterFailed(String)
    case detectionFailed
    case invalidRegion
    
    var errorDescription: String? {
        switch self {
        case .filterFailed(let details):
            return "Filter processing failed: \(details)"
        case .detectionFailed:
            return "Feature detection failed"
        case .invalidRegion:
            return "Invalid region for enhancement"
        }
    }
}