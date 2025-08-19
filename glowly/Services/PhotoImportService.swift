//
//  PhotoImportService.swift
//  Glowly
//
//  Advanced photo import service with PHPicker and optimizations
//

import Foundation
import SwiftUI
import Photos
import PhotosUI
import CoreImage
import Vision
import UniformTypeIdentifiers

/// Protocol for photo import operations
protocol PhotoImportServiceProtocol: AnyObject {
    func importPhotos(from items: [PhotosPickerItem]) async throws -> [GlowlyPhoto]
    func importFromPHAssets(_ assets: [PHAsset]) async throws -> [GlowlyPhoto]
    func loadRecentPhotos(limit: Int) async throws -> [GlowlyPhoto]
    func processImportedImage(_ image: UIImage, source: PhotoSource) async throws -> GlowlyPhoto
}

/// Advanced photo import service implementation
@MainActor
final class PhotoImportService: NSObject, PhotoImportServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importedPhotos: [GlowlyPhoto] = []
    @Published var recentPhotos: [GlowlyPhoto] = []
    @Published var importError: Error?
    
    // Services
    private let imageProcessingService: ImageProcessingService
    private let analyticsService: AnalyticsServiceProtocol
    
    // Processing queue
    private let processingQueue = DispatchQueue(label: "com.glowly.photo.import", qos: .userInitiated, attributes: .concurrent)
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    // Quality assessment
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - Initialization
    
    init(imageProcessingService: ImageProcessingService,
         analyticsService: AnalyticsServiceProtocol) {
        self.imageProcessingService = imageProcessingService
        self.analyticsService = analyticsService
        super.init()
        configureThumbnailCache()
    }
    
    private func configureThumbnailCache() {
        thumbnailCache.countLimit = 100
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Photo Import from PhotosPicker
    
    func importPhotos(from items: [PhotosPickerItem]) async throws -> [GlowlyPhoto] {
        guard !items.isEmpty else { return [] }
        
        isImporting = true
        importProgress = 0.0
        defer { 
            isImporting = false
            importProgress = 1.0
        }
        
        var importedPhotos: [GlowlyPhoto] = []
        let totalItems = Double(items.count)
        
        for (index, item) in items.enumerated() {
            do {
                // Update progress
                importProgress = Double(index) / totalItems
                
                // Load image from PhotosPickerItem
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    
                    let photo = try await processImportedImage(image, source: .photoLibrary)
                    importedPhotos.append(photo)
                    
                    // Track import event
                    await analyticsService.trackPhotoImported(source: .photoLibrary)
                }
            } catch {
                print("Error importing photo \(index): \(error)")
                // Continue with other photos even if one fails
            }
        }
        
        self.importedPhotos = importedPhotos
        return importedPhotos
    }
    
    // MARK: - Photo Import from PHAssets
    
    func importFromPHAssets(_ assets: [PHAsset]) async throws -> [GlowlyPhoto] {
        guard !assets.isEmpty else { return [] }
        
        isImporting = true
        importProgress = 0.0
        defer { 
            isImporting = false
            importProgress = 1.0
        }
        
        var importedPhotos: [GlowlyPhoto] = []
        let totalAssets = Double(assets.count)
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = false
        
        for (index, asset) in assets.enumerated() {
            importProgress = Double(index) / totalAssets
            
            let photo = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GlowlyPhoto, Error>) in
                imageManager.requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFit,
                    options: requestOptions
                ) { [weak self] image, info in
                    guard let self = self, let image = image else {
                        continuation.resume(throwing: PhotoImportError.failedToLoadAsset)
                        return
                    }
                    
                    Task {
                        do {
                            let photo = try await self.processImportedImage(
                                image,
                                source: .photoLibrary,
                                assetIdentifier: asset.localIdentifier
                            )
                            continuation.resume(returning: photo)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            
            importedPhotos.append(photo)
            await analyticsService.trackPhotoImported(source: .photoLibrary)
        }
        
        self.importedPhotos = importedPhotos
        return importedPhotos
    }
    
    // MARK: - Load Recent Photos
    
    func loadRecentPhotos(limit: Int = 20) async throws -> [GlowlyPhoto] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var recentAssets: [PHAsset] = []
        
        assets.enumerateObjects { asset, _, _ in
            recentAssets.append(asset)
        }
        
        let photos = try await importFromPHAssets(recentAssets)
        self.recentPhotos = photos
        return photos
    }
    
    // MARK: - Image Processing Pipeline
    
    func processImportedImage(_ image: UIImage, source: PhotoSource, assetIdentifier: String? = nil) async throws -> GlowlyPhoto {
        // Step 1: Orientation correction
        let correctedImage = correctImageOrientation(image)
        
        // Step 2: Quality assessment
        let qualityScore = await assessImageQuality(correctedImage)
        
        // Step 3: Face detection
        let faceResults = await detectFaces(in: correctedImage)
        
        // Step 4: Resize for optimal processing
        let processedImage = await resizeImageForProcessing(correctedImage)
        
        // Step 5: Generate thumbnail
        let thumbnail = await generateThumbnail(from: processedImage)
        
        // Step 6: Extract metadata
        let metadata = extractMetadata(from: correctedImage, faceResults: faceResults)
        
        // Step 7: Convert to data
        guard let originalData = processedImage.jpegData(compressionQuality: 0.9),
              let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw PhotoImportError.imageProcessingFailed
        }
        
        // Create GlowlyPhoto object
        let photo = GlowlyPhoto(
            originalAssetIdentifier: assetIdentifier,
            originalImage: originalData,
            thumbnailImage: thumbnailData,
            metadata: metadata
        )
        
        return photo
    }
    
    // MARK: - Image Quality Assessment
    
    private func assessImageQuality(_ image: UIImage) async -> Float {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                guard let ciImage = CIImage(image: image) else {
                    continuation.resume(returning: 0.5)
                    return
                }
                
                var qualityScore: Float = 0.0
                
                // Check resolution
                let resolution = image.size.width * image.size.height
                let resolutionScore = min(Float(resolution) / (3000 * 3000), 1.0)
                qualityScore += resolutionScore * 0.3
                
                // Check brightness
                let brightnessScore = self.assessBrightness(ciImage)
                qualityScore += brightnessScore * 0.3
                
                // Check sharpness
                let sharpnessScore = self.assessSharpness(ciImage)
                qualityScore += sharpnessScore * 0.4
                
                continuation.resume(returning: qualityScore)
            }
        }
    }
    
    private func assessBrightness(_ image: CIImage) -> Float {
        let extent = image.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage"),
              let _ = filter.setValue(image, forKey: kCIInputImageKey) as? Void,
              let _ = filter.setValue(inputExtent, forKey: kCIInputExtentKey) as? Void,
              let outputImage = filter.outputImage else {
            return 0.5
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        let brightness = Float(bitmap[0] + bitmap[1] + bitmap[2]) / (3.0 * 255.0)
        
        // Optimal brightness is around 0.5-0.7
        if brightness < 0.3 {
            return brightness / 0.3 * 0.5 // Too dark
        } else if brightness > 0.8 {
            return (1.0 - brightness) / 0.2 * 0.5 + 0.5 // Too bright
        } else {
            return 1.0 // Good brightness
        }
    }
    
    private func assessSharpness(_ image: CIImage) -> Float {
        guard let filter = CIFilter(name: "CIEdges"),
              let _ = filter.setValue(image, forKey: kCIInputImageKey) as? Void,
              let _ = filter.setValue(10.0, forKey: kCIInputIntensityKey) as? Void,
              let outputImage = filter.outputImage else {
            return 0.5
        }
        
        // Calculate edge intensity as a measure of sharpness
        let extent = outputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        
        guard let avgFilter = CIFilter(name: "CIAreaAverage"),
              let _ = avgFilter.setValue(outputImage, forKey: kCIInputImageKey) as? Void,
              let _ = avgFilter.setValue(inputExtent, forKey: kCIInputExtentKey) as? Void,
              let avgOutput = avgFilter.outputImage else {
            return 0.5
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(avgOutput, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        let edgeIntensity = Float(bitmap[0] + bitmap[1] + bitmap[2]) / (3.0 * 255.0)
        return min(edgeIntensity * 10, 1.0) // Scale up edge intensity
    }
    
    // MARK: - Face Detection
    
    private func detectFaces(in image: UIImage) async -> [FaceDetectionResult] {
        guard let cgImage = image.cgImage else { return [] }
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = observations.map { observation in
                    self.createFaceDetectionResult(from: observation, imageSize: image.size)
                }
                
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            processingQueue.async {
                try? handler.perform([request])
            }
        }
    }
    
    private func createFaceDetectionResult(from observation: VNFaceObservation, imageSize: CGSize) -> FaceDetectionResult {
        // Convert Vision coordinates to UIKit coordinates
        let boundingBox = CGRect(
            x: observation.boundingBox.origin.x * imageSize.width,
            y: (1 - observation.boundingBox.origin.y - observation.boundingBox.height) * imageSize.height,
            width: observation.boundingBox.width * imageSize.width,
            height: observation.boundingBox.height * imageSize.height
        )
        
        // Extract landmarks if available
        var landmarks: FaceLandmarks?
        if let faceLandmarks = observation.landmarks {
            landmarks = FaceLandmarks(
                leftEye: convertPoint(faceLandmarks.leftEye?.normalizedPoints.first, imageSize: imageSize),
                rightEye: convertPoint(faceLandmarks.rightEye?.normalizedPoints.first, imageSize: imageSize),
                nose: convertPoint(faceLandmarks.nose?.normalizedPoints.first, imageSize: imageSize),
                mouth: convertPoint(faceLandmarks.outerLips?.normalizedPoints.first, imageSize: imageSize),
                leftEyebrow: convertPoints(faceLandmarks.leftEyebrow?.normalizedPoints, imageSize: imageSize),
                rightEyebrow: convertPoints(faceLandmarks.rightEyebrow?.normalizedPoints, imageSize: imageSize),
                faceContour: convertPoints(faceLandmarks.faceContour?.normalizedPoints, imageSize: imageSize)
            )
        }
        
        // Assess face quality
        let faceQuality = assessFaceQuality(observation: observation, boundingBox: boundingBox, imageSize: imageSize)
        
        return FaceDetectionResult(
            boundingBox: boundingBox,
            confidence: observation.confidence,
            landmarks: landmarks,
            faceQuality: faceQuality
        )
    }
    
    private func convertPoint(_ point: CGPoint?, imageSize: CGSize) -> CGPoint? {
        guard let point = point else { return nil }
        return CGPoint(
            x: point.x * imageSize.width,
            y: (1 - point.y) * imageSize.height
        )
    }
    
    private func convertPoints(_ points: [CGPoint]?, imageSize: CGSize) -> [CGPoint] {
        guard let points = points else { return [] }
        return points.map { point in
            CGPoint(
                x: point.x * imageSize.width,
                y: (1 - point.y) * imageSize.height
            )
        }
    }
    
    private func assessFaceQuality(observation: VNFaceObservation, boundingBox: CGRect, imageSize: CGSize) -> FaceQuality {
        // Calculate face size relative to image
        let faceArea = (boundingBox.width * boundingBox.height) / (imageSize.width * imageSize.height)
        let sizeScore = min(Float(faceArea * 4), 1.0)
        
        // Check if face is centered
        let centerX = boundingBox.midX / imageSize.width
        let centerY = boundingBox.midY / imageSize.height
        let centerScore = 1.0 - Float(abs(centerX - 0.5) + abs(centerY - 0.5))
        
        // Calculate overall score
        let overallScore = (sizeScore * 0.4 + centerScore * 0.3 + observation.confidence * 0.3)
        
        return FaceQuality(
            overallScore: overallScore,
            lighting: 0.8, // Would need additional processing
            sharpness: 0.8, // Would need additional processing
            pose: centerScore,
            expression: 0.8 // Would need additional processing
        )
    }
    
    // MARK: - Image Resizing
    
    private func resizeImageForProcessing(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let maxDimension: CGFloat = 2048
                let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
                
                if scale >= 1.0 {
                    continuation.resume(returning: image)
                    return
                }
                
                let newSize = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                defer { UIGraphicsEndImageContext() }
                
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
    
    // MARK: - Thumbnail Generation
    
    private func generateThumbnail(from image: UIImage) async -> UIImage {
        let cacheKey = NSString(string: "\(image.hash)")
        
        if let cachedThumbnail = thumbnailCache.object(forKey: cacheKey) {
            return cachedThumbnail
        }
        
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let thumbnailSize = CGSize(width: 300, height: 300)
                
                UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale)
                defer { UIGraphicsEndImageContext() }
                
                let aspectRatio = image.size.width / image.size.height
                var drawRect = CGRect.zero
                
                if aspectRatio > 1 {
                    // Landscape
                    drawRect.size.width = thumbnailSize.width
                    drawRect.size.height = thumbnailSize.width / aspectRatio
                    drawRect.origin.y = (thumbnailSize.height - drawRect.height) / 2
                } else {
                    // Portrait
                    drawRect.size.height = thumbnailSize.height
                    drawRect.size.width = thumbnailSize.height * aspectRatio
                    drawRect.origin.x = (thumbnailSize.width - drawRect.width) / 2
                }
                
                image.draw(in: drawRect)
                let thumbnail = UIGraphicsGetImageFromCurrentImageContext() ?? image
                
                self.thumbnailCache.setObject(thumbnail, forKey: cacheKey)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from image: UIImage, faceResults: [FaceDetectionResult]) -> PhotoMetadata {
        let imageSize = image.size
        let scale = image.scale
        let actualSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        // Estimate file size
        let estimatedFileSize = Int64(actualSize.width * actualSize.height * 4)
        
        return PhotoMetadata(
            width: Int(actualSize.width),
            height: Int(actualSize.height),
            fileSize: estimatedFileSize,
            format: "JPEG",
            colorSpace: "sRGB",
            exifData: [:], // Would need to extract real EXIF data
            faceDetectionResults: faceResults
        )
    }
    
    // MARK: - Helper Methods
    
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

// MARK: - Photo Import Errors

enum PhotoImportError: LocalizedError {
    case failedToLoadAsset
    case imageProcessingFailed
    case qualityTooLow
    case noFacesDetected
    case memoryWarning
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadAsset:
            return "Failed to load photo from library."
        case .imageProcessingFailed:
            return "Failed to process the imported image."
        case .qualityTooLow:
            return "Image quality is too low for enhancement."
        case .noFacesDetected:
            return "No faces detected in the image."
        case .memoryWarning:
            return "Memory warning - please try importing fewer photos."
        }
    }
}