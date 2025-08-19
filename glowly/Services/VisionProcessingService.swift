//
//  VisionProcessingService.swift
//  Glowly
//
//  Vision framework processing pipeline for face analysis and enhancement preparation
//

import Foundation
import Vision
import CoreML
import UIKit
import CoreImage

/// Protocol for vision processing operations
protocol VisionProcessingServiceProtocol {
    func analyzeImage(_ image: UIImage) async throws -> ImageAnalysisResult
    func detectFaces(in image: UIImage) async throws -> [DetailedFaceDetectionResult]
    func detectFacialLandmarks(in image: UIImage) async throws -> [DetailedFaceLandmarks]
    func analyzeSkinTone(in image: UIImage, faceRegion: CGRect) async throws -> SkinToneAnalysisResult
    func segmentFace(in image: UIImage, boundingBox: CGRect) async throws -> UIImage
    func cropFaceForML(image: UIImage, boundingBox: CGRect, padding: CGFloat) -> UIImage?
    func preprocessImageForModel(_ image: UIImage, targetSize: CGSize) throws -> CVPixelBuffer
}

/// Comprehensive vision processing service
@MainActor
final class VisionProcessingService: VisionProcessingServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    
    private let ciContext: CIContext
    private let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    // MARK: - Initialization
    
    init() {
        // Initialize Core Image context with GPU acceleration
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice)
        } else {
            self.ciContext = CIContext()
        }
    }
    
    // MARK: - Main Analysis Pipeline
    
    /// Comprehensive image analysis combining multiple vision techniques
    func analyzeImage(_ image: UIImage) async throws -> ImageAnalysisResult {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            // Step 1: Basic image quality assessment
            let imageQuality = await assessImageQuality(image)
            processingProgress = 0.2
            
            // Step 2: Face detection with detailed analysis
            let faces = try await detectFaces(in: image)
            processingProgress = 0.5
            
            // Step 3: Scene analysis
            let sceneAnalysis = try await analyzeScene(image)
            processingProgress = 0.7
            
            // Step 4: Enhancement opportunities analysis
            let enhancementOpportunities = await analyzeEnhancementOpportunities(
                image: image,
                faces: faces,
                sceneAnalysis: sceneAnalysis
            )
            processingProgress = 1.0
            
            return ImageAnalysisResult(
                faces: faces,
                imageQuality: imageQuality,
                sceneAnalysis: sceneAnalysis,
                enhancementOpportunities: enhancementOpportunities,
                processingTime: Date().timeIntervalSince1970 - Date().timeIntervalSince1970
            )
            
        } catch {
            throw VisionProcessingError.analysisFailure(error.localizedDescription)
        }
    }
    
    // MARK: - Face Detection
    
    /// Advanced face detection with detailed analysis
    func detectFaces(in image: UIImage) async throws -> [DetailedFaceDetectionResult] {
        guard let cgImage = image.cgImage else {
            throw VisionProcessingError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create face landmarks request
            let faceRequest = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionProcessingError.faceDetectionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                Task {
                    do {
                        let detailedResults = try await self.processDetailedFaceObservations(observations, in: image)
                        continuation.resume(returning: detailedResults)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Configure request for maximum accuracy
            faceRequest.revision = VNDetectFaceLandmarksRequestRevision3
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([faceRequest])
                } catch {
                    continuation.resume(throwing: VisionProcessingError.faceDetectionFailed(error.localizedDescription))
                }
            }
        }
    }
    
    private func processDetailedFaceObservations(_ observations: [VNFaceObservation], in image: UIImage) async throws -> [DetailedFaceDetectionResult] {
        var results: [DetailedFaceDetectionResult] = []
        
        for (index, observation) in observations.enumerated() {
            // Convert normalized coordinates to image coordinates
            let imageSize = image.size
            let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(imageSize.width), Int(imageSize.height))
            
            // Analyze face quality
            let faceQuality = await assessDetailedFaceQuality(observation: observation, in: image)
            
            // Extract detailed landmarks
            let detailedLandmarks = extractDetailedLandmarks(from: observation)
            
            // Analyze face orientation and expression
            let faceAnalysis = await analyzeFaceCharacteristics(observation: observation, in: image)
            
            // Skin tone analysis for the face region
            let skinToneResult = try await analyzeSkinTone(in: image, faceRegion: boundingBox)
            
            let result = DetailedFaceDetectionResult(
                id: UUID(),
                faceIndex: index,
                boundingBox: boundingBox,
                normalizedBoundingBox: observation.boundingBox,
                confidence: observation.confidence,
                landmarks: detailedLandmarks,
                faceQuality: faceQuality,
                faceAnalysis: faceAnalysis,
                skinToneAnalysis: skinToneResult
            )
            
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Facial Landmarks
    
    func detectFacialLandmarks(in image: UIImage) async throws -> [DetailedFaceLandmarks] {
        let faces = try await detectFaces(in: image)
        return faces.compactMap { $0.landmarks }
    }
    
    private func extractDetailedLandmarks(from observation: VNFaceObservation) -> DetailedFaceLandmarks? {
        guard let landmarks = observation.landmarks else { return nil }
        
        return DetailedFaceLandmarks(
            // Eyes
            leftEye: landmarks.leftEye?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            rightEye: landmarks.rightEye?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            leftPupil: landmarks.leftPupil?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
            rightPupil: landmarks.rightPupil?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
            
            // Eyebrows
            leftEyebrow: landmarks.leftEyebrow?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            rightEyebrow: landmarks.rightEyebrow?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            
            // Nose
            nose: landmarks.nose?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            noseCrest: landmarks.noseCrest?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            
            // Mouth
            outerLips: landmarks.outerLips?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            innerLips: landmarks.innerLips?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            
            // Face contour
            faceContour: landmarks.faceContour?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? [],
            
            // Median line
            medianLine: landmarks.medianLine?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) } ?? []
        )
    }
    
    // MARK: - Skin Tone Analysis
    
    func analyzeSkinTone(in image: UIImage, faceRegion: CGRect) async throws -> SkinToneAnalysisResult {
        guard let cgImage = image.cgImage else {
            throw VisionProcessingError.invalidImage
        }
        
        // Crop face region for analysis
        guard let croppedImage = cgImage.cropping(to: faceRegion) else {
            throw VisionProcessingError.regionExtractionFailed
        }
        
        let ciImage = CIImage(cgImage: croppedImage)
        
        // Analyze skin tone using Core Image filters
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.performSkinToneAnalysis(ciImage: ciImage)
                continuation.resume(returning: result)
            }
        }
    }
    
    private func performSkinToneAnalysis(ciImage: CIImage) -> SkinToneAnalysisResult {
        // Sample pixels from multiple regions of the face
        let sampleRegions = generateSkinSampleRegions(imageSize: ciImage.extent.size)
        var colorSamples: [UIColor] = []
        
        for region in sampleRegions {
            if let averageColor = getAverageColor(from: ciImage, region: region) {
                colorSamples.append(averageColor)
            }
        }
        
        // Analyze color samples to determine skin tone
        let skinToneClassification = classifySkinTone(from: colorSamples)
        let undertone = analyzeUndertone(from: colorSamples)
        
        return SkinToneAnalysisResult(
            dominantColor: calculateDominantSkinColor(from: colorSamples),
            skinToneCategory: skinToneClassification,
            undertone: undertone,
            colorSamples: colorSamples,
            confidence: calculateSkinToneConfidence(samples: colorSamples)
        )
    }
    
    // MARK: - Face Quality Assessment
    
    private func assessDetailedFaceQuality(observation: VNFaceObservation, in image: UIImage) async -> DetailedFaceQuality {
        // Lighting analysis
        let lightingScore = await analyzeLighting(observation: observation, in: image)
        
        // Sharpness analysis
        let sharpnessScore = await analyzeSharpness(observation: observation, in: image)
        
        // Pose analysis
        let poseScore = analyzePose(observation: observation)
        
        // Expression analysis
        let expressionScore = analyzeExpression(observation: observation)
        
        // Occlusion analysis
        let occlusionScore = analyzeOcclusion(observation: observation)
        
        let overallScore = (lightingScore + sharpnessScore + poseScore + expressionScore + occlusionScore) / 5.0
        
        return DetailedFaceQuality(
            overallScore: overallScore,
            lighting: lightingScore,
            sharpness: sharpnessScore,
            pose: poseScore,
            expression: expressionScore,
            occlusion: occlusionScore,
            resolution: assessResolution(observation: observation, in: image),
            suitabilityForEnhancement: calculateEnhancementSuitability(
                lighting: lightingScore,
                sharpness: sharpnessScore,
                pose: poseScore
            )
        )
    }
    
    // MARK: - Face Segmentation
    
    func segmentFace(in image: UIImage, boundingBox: CGRect) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw VisionProcessingError.invalidImage
        }
        
        // Use Vision's person segmentation for face area
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionProcessingError.segmentationFailed(error.localizedDescription))
                    return
                }
                
                guard let observation = request.results?.first as? VNPixelBufferObservation else {
                    continuation.resume(throwing: VisionProcessingError.segmentationFailed("No segmentation result"))
                    return
                }
                
                // Process segmentation mask to focus on face region
                Task {
                    do {
                        let segmentedImage = try await self.applyFaceSegmentationMask(
                            originalImage: image,
                            mask: observation.pixelBuffer,
                            faceRegion: boundingBox
                        )
                        continuation.resume(returning: segmentedImage)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: VisionProcessingError.segmentationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Image Preprocessing
    
    func cropFaceForML(image: UIImage, boundingBox: CGRect, padding: CGFloat = 0.2) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Expand bounding box with padding
        let expandedRect = boundingBox.insetBy(dx: -boundingBox.width * padding, dy: -boundingBox.height * padding)
        
        // Ensure the expanded rect is within image bounds
        let imageRect = CGRect(origin: .zero, size: image.size)
        let clampedRect = expandedRect.intersection(imageRect)
        
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func preprocessImageForModel(_ image: UIImage, targetSize: CGSize) throws -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            throw VisionProcessingError.invalidImage
        }
        
        // Create pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(targetSize.width),
            Int(targetSize.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw VisionProcessingError.pixelBufferCreationFailed
        }
        
        // Render image to pixel buffer
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        
        return buffer
    }
    
    // MARK: - Private Helper Methods
    
    private func assessImageQuality(_ image: UIImage) async -> ImageQualityResult {
        // Placeholder implementation for image quality assessment
        // In production, this would use more sophisticated algorithms
        
        let imageSize = image.size
        let pixelCount = imageSize.width * imageSize.height
        
        let resolutionScore = min(pixelCount / 2_000_000, 1.0) // 2MP baseline
        let aspectRatioScore = calculateAspectRatioScore(size: imageSize)
        
        return ImageQualityResult(
            overallScore: Float((resolutionScore + aspectRatioScore) / 2.0),
            resolution: Float(resolutionScore),
            sharpness: 0.8, // Placeholder
            noise: 0.1,     // Placeholder
            exposure: 0.7   // Placeholder
        )
    }
    
    private func analyzeScene(_ image: UIImage) async throws -> SceneAnalysisResult {
        // Placeholder for scene analysis
        // In production, this would use Core ML models for scene classification
        return SceneAnalysisResult(
            sceneType: .portrait,
            lightingConditions: .indoor,
            backgroundComplexity: .simple,
            colorPalette: ["neutral", "warm"]
        )
    }
    
    private func analyzeEnhancementOpportunities(
        image: UIImage,
        faces: [DetailedFaceDetectionResult],
        sceneAnalysis: SceneAnalysisResult
    ) async -> EnhancementOpportunitiesResult {
        // Analyze what enhancements would be most beneficial
        var opportunities: [EnhancementOpportunity] = []
        
        if !faces.isEmpty {
            let faceQuality = faces.first?.faceQuality ?? DetailedFaceQuality()
            
            // Skin smoothing opportunity
            if faceQuality.sharpness > 0.7 {
                opportunities.append(EnhancementOpportunity(
                    type: .skinSmoothing,
                    confidence: 0.8,
                    recommendedIntensity: 0.3,
                    reasoning: "High detail face detected, skin smoothing would enhance appearance"
                ))
            }
            
            // Eye brightening opportunity
            opportunities.append(EnhancementOpportunity(
                type: .eyeBrightening,
                confidence: 0.7,
                recommendedIntensity: 0.4,
                reasoning: "Eyes detected, brightening would enhance engagement"
            ))
        }
        
        return EnhancementOpportunitiesResult(
            opportunities: opportunities,
            overallScore: calculateOverallEnhancementScore(opportunities),
            primaryRecommendations: opportunities.prefix(3).map { $0 }
        )
    }
    
    // Additional helper methods would be implemented here...
    private func generateSkinSampleRegions(imageSize: CGSize) -> [CGRect] {
        // Generate multiple small regions across the face for skin sampling
        let regionSize = CGSize(width: imageSize.width * 0.1, height: imageSize.height * 0.1)
        
        return [
            CGRect(x: imageSize.width * 0.3, y: imageSize.height * 0.3, width: regionSize.width, height: regionSize.height), // Left cheek
            CGRect(x: imageSize.width * 0.6, y: imageSize.height * 0.3, width: regionSize.width, height: regionSize.height), // Right cheek
            CGRect(x: imageSize.width * 0.45, y: imageSize.height * 0.5, width: regionSize.width, height: regionSize.height), // Nose area
            CGRect(x: imageSize.width * 0.4, y: imageSize.height * 0.6, width: regionSize.width, height: regionSize.height)   // Chin area
        ]
    }
    
    private func getAverageColor(from image: CIImage, region: CGRect) -> UIColor? {
        // Extract average color from a specific region
        let extent = region.intersection(image.extent)
        guard !extent.isEmpty else { return nil }
        
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        // Extract pixel data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: 4)
        
        let red = CGFloat(pixels[0]) / 255.0
        let green = CGFloat(pixels[1]) / 255.0
        let blue = CGFloat(pixels[2]) / 255.0
        let alpha = CGFloat(pixels[3]) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // Additional helper methods for skin tone classification, lighting analysis, etc. would be implemented here...
    
    private func classifySkinTone(from samples: [UIColor]) -> SkinTone {
        // Simplified skin tone classification based on color analysis
        // In production, this would use more sophisticated algorithms
        
        guard !samples.isEmpty else { return .medium }
        
        let avgBrightness = samples.map { color in
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (red + green + blue) / 3.0
        }.reduce(0, +) / CGFloat(samples.count)
        
        switch avgBrightness {
        case 0.0..<0.2:
            return .veryDark
        case 0.2..<0.4:
            return .dark
        case 0.4..<0.6:
            return .tan
        case 0.6..<0.75:
            return .medium
        case 0.75..<0.9:
            return .light
        default:
            return .veryLight
        }
    }
    
    private func analyzeUndertone(from samples: [UIColor]) -> SkinUndertone {
        // Simplified undertone analysis
        // In production, this would analyze color temperature and hue
        return .neutral // Placeholder
    }
    
    private func calculateDominantSkinColor(from samples: [UIColor]) -> UIColor {
        guard !samples.isEmpty else { return UIColor.systemPink }
        
        // Calculate average color
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0
        
        for color in samples {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            totalRed += red
            totalGreen += green
            totalBlue += blue
        }
        
        let count = CGFloat(samples.count)
        return UIColor(
            red: totalRed / count,
            green: totalGreen / count,
            blue: totalBlue / count,
            alpha: 1.0
        )
    }
    
    private func calculateSkinToneConfidence(samples: [UIColor]) -> Float {
        // Calculate confidence based on color consistency
        guard samples.count > 1 else { return 0.5 }
        
        // Measure color variance to determine confidence
        // Lower variance = higher confidence
        let dominantColor = calculateDominantSkinColor(from: samples)
        
        // This is a simplified confidence calculation
        // In production, this would be more sophisticated
        return Float.random(in: 0.7...0.95) // Placeholder
    }
    
    private func analyzeLighting(observation: VNFaceObservation, in image: UIImage) async -> Float {
        // Placeholder lighting analysis
        // In production, this would analyze histogram, contrast, etc.
        return 0.8
    }
    
    private func analyzeSharpness(observation: VNFaceObservation, in image: UIImage) async -> Float {
        // Placeholder sharpness analysis
        // In production, this would use edge detection algorithms
        return 0.9
    }
    
    private func analyzePose(observation: VNFaceObservation) -> Float {
        // Analyze face pose based on landmark positions
        // Frontal face scores higher than profile
        return observation.confidence // Simplified
    }
    
    private func analyzeExpression(observation: VNFaceObservation) -> Float {
        // Placeholder expression analysis
        // In production, this would analyze facial expressions
        return 0.8
    }
    
    private func analyzeOcclusion(observation: VNFaceObservation) -> Float {
        // Analyze if face is partially occluded
        // Check landmark confidence and completeness
        return observation.confidence // Simplified
    }
    
    private func assessResolution(observation: VNFaceObservation, in image: UIImage) -> Float {
        let faceArea = observation.boundingBox.width * observation.boundingBox.height
        let imageArea = 1.0 // Normalized
        let relativeSize = Float(faceArea / imageArea)
        
        // Larger faces in the image indicate better resolution for processing
        return min(relativeSize * 10, 1.0) // Scale and clamp
    }
    
    private func calculateEnhancementSuitability(lighting: Float, sharpness: Float, pose: Float) -> Float {
        return (lighting + sharpness + pose) / 3.0
    }
    
    private func analyzeFaceCharacteristics(observation: VNFaceObservation, in image: UIImage) async -> FaceCharacteristicsAnalysis {
        // Placeholder for face characteristics analysis
        return FaceCharacteristicsAnalysis(
            age: .adult,
            gender: .unknown,
            expression: .neutral,
            eyeOpenness: 0.9,
            mouthOpenness: 0.1,
            headPose: HeadPose(yaw: 0.0, pitch: 0.0, roll: 0.0)
        )
    }
    
    private func applyFaceSegmentationMask(originalImage: UIImage, mask: CVPixelBuffer, faceRegion: CGRect) async throws -> UIImage {
        // Apply segmentation mask to isolate face region
        // This is a simplified implementation
        return originalImage // Placeholder
    }
    
    private func calculateAspectRatioScore(size: CGSize) -> Double {
        let aspectRatio = size.width / size.height
        // Score based on how close to ideal portrait ratio (3:4 or 4:3)
        let idealRatios = [3.0/4.0, 4.0/3.0, 1.0] // Portrait, landscape, square
        let closestRatio = idealRatios.min { abs($0 - aspectRatio) < abs($1 - aspectRatio) } ?? 1.0
        return 1.0 - min(abs(aspectRatio - closestRatio), 0.5) / 0.5
    }
    
    private func calculateOverallEnhancementScore(_ opportunities: [EnhancementOpportunity]) -> Float {
        guard !opportunities.isEmpty else { return 0.0 }
        return opportunities.map { $0.confidence }.reduce(0, +) / Float(opportunities.count)
    }
}

// MARK: - Error Types

enum VisionProcessingError: LocalizedError {
    case invalidImage
    case faceDetectionFailed(String)
    case landmarkDetectionFailed(String)
    case segmentationFailed(String)
    case regionExtractionFailed
    case pixelBufferCreationFailed
    case analysisFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or cannot be processed."
        case .faceDetectionFailed(let details):
            return "Face detection failed: \(details)"
        case .landmarkDetectionFailed(let details):
            return "Facial landmark detection failed: \(details)"
        case .segmentationFailed(let details):
            return "Face segmentation failed: \(details)"
        case .regionExtractionFailed:
            return "Failed to extract the specified region from the image."
        case .pixelBufferCreationFailed:
            return "Failed to create pixel buffer for Core ML processing."
        case .analysisFailure(let details):
            return "Image analysis failed: \(details)"
        }
    }
}