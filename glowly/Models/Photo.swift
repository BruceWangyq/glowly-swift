//
//  Photo.swift
//  Glowly
//
//  Data model for photos in the app
//

import Foundation
import SwiftUI
import Photos

/// Represents a photo in the Glowly app
struct GlowlyPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    let originalAssetIdentifier: String?
    let originalImage: Data?
    let enhancedImage: Data?
    let thumbnailImage: Data?
    let createdAt: Date
    let updatedAt: Date
    let metadata: PhotoMetadata
    let enhancementHistory: [Enhancement]
    
    init(
        id: UUID = UUID(),
        originalAssetIdentifier: String? = nil,
        originalImage: Data? = nil,
        enhancedImage: Data? = nil,
        thumbnailImage: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: PhotoMetadata = PhotoMetadata(),
        enhancementHistory: [Enhancement] = []
    ) {
        self.id = id
        self.originalAssetIdentifier = originalAssetIdentifier
        self.originalImage = originalImage
        self.enhancedImage = enhancedImage
        self.thumbnailImage = thumbnailImage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
        self.enhancementHistory = enhancementHistory
    }
}

/// Metadata associated with a photo
struct PhotoMetadata: Codable, Hashable {
    let width: Int
    let height: Int
    let fileSize: Int64
    let format: String
    let colorSpace: String?
    let exifData: [String: String]
    let faceDetectionResults: [FaceDetectionResult]
    
    init(
        width: Int = 0,
        height: Int = 0,
        fileSize: Int64 = 0,
        format: String = "JPEG",
        colorSpace: String? = nil,
        exifData: [String: String] = [:],
        faceDetectionResults: [FaceDetectionResult] = []
    ) {
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.format = format
        self.colorSpace = colorSpace
        self.exifData = exifData
        self.faceDetectionResults = faceDetectionResults
    }
}

/// Face detection result from Vision framework
struct FaceDetectionResult: Codable, Hashable, Identifiable {
    let id: UUID
    let boundingBox: CGRect
    let confidence: Float
    let landmarks: FaceLandmarks?
    let faceQuality: FaceQuality
    
    init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        confidence: Float,
        landmarks: FaceLandmarks? = nil,
        faceQuality: FaceQuality = FaceQuality()
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.landmarks = landmarks
        self.faceQuality = faceQuality
    }
}

/// Face landmarks detected by Vision framework
struct FaceLandmarks: Codable, Hashable {
    let leftEye: CGPoint?
    let rightEye: CGPoint?
    let nose: CGPoint?
    let mouth: CGPoint?
    let leftEyebrow: [CGPoint]
    let rightEyebrow: [CGPoint]
    let faceContour: [CGPoint]
    
    init(
        leftEye: CGPoint? = nil,
        rightEye: CGPoint? = nil,
        nose: CGPoint? = nil,
        mouth: CGPoint? = nil,
        leftEyebrow: [CGPoint] = [],
        rightEyebrow: [CGPoint] = [],
        faceContour: [CGPoint] = []
    ) {
        self.leftEye = leftEye
        self.rightEye = rightEye
        self.nose = nose
        self.mouth = mouth
        self.leftEyebrow = leftEyebrow
        self.rightEyebrow = rightEyebrow
        self.faceContour = faceContour
    }
}

/// Quality assessment of detected face
struct FaceQuality: Codable, Hashable {
    let overallScore: Float
    let lighting: Float
    let sharpness: Float
    let pose: Float
    let expression: Float
    
    init(
        overallScore: Float = 0.0,
        lighting: Float = 0.0,
        sharpness: Float = 0.0,
        pose: Float = 0.0,
        expression: Float = 0.0
    ) {
        self.overallScore = overallScore
        self.lighting = lighting
        self.sharpness = sharpness
        self.pose = pose
        self.expression = expression
    }
}

/// Photo source type
enum PhotoSource: String, Codable, CaseIterable {
    case camera = "camera"
    case photoLibrary = "photo_library"
    case imported = "imported"
    
    var displayName: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Photo Library"
        case .imported:
            return "Imported"
        }
    }
}

// MARK: - GlowlyPhoto Extensions for Comparison System

extension GlowlyPhoto {
    /// Whether this photo has been enhanced
    var isEnhanced: Bool {
        return enhancedImage != nil && !enhancementHistory.isEmpty
    }
    
    /// Processing quality indicator
    var processingQuality: ProcessingQuality {
        if enhancementHistory.isEmpty {
            return .original
        }
        
        let totalIntensity = enhancementHistory.reduce(0.0) { sum, enhancement in
            return sum + enhancement.intensity
        }
        
        if totalIntensity > 2.0 {
            return .high
        } else if totalIntensity > 1.0 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// URL for original image (for AsyncImage compatibility)
    var originalImageURL: URL? {
        guard let originalImage = originalImage else { return nil }
        return createTemporaryImageURL(from: originalImage, suffix: "original")
    }
    
    /// URL for enhanced image (for AsyncImage compatibility)
    var enhancedImageURL: URL? {
        guard let enhancedImage = enhancedImage else { return nil }
        return createTemporaryImageURL(from: enhancedImage, suffix: "enhanced")
    }
    
    /// URL for thumbnail image (for AsyncImage compatibility)
    var thumbnailURL: URL? {
        guard let thumbnailImage = thumbnailImage else { return nil }
        return createTemporaryImageURL(from: thumbnailImage, suffix: "thumbnail")
    }
    
    /// Create a temporary URL for image data
    private func createTemporaryImageURL(from data: Data, suffix: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "\(id.uuidString)_\(suffix).jpg"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to create temporary image file: \(error)")
            return nil
        }
    }
    
    /// Convert image data to UIImage
    var originalUIImage: UIImage? {
        guard let data = originalImage else { return nil }
        return UIImage(data: data)
    }
    
    /// Convert enhanced image data to UIImage
    var enhancedUIImage: UIImage? {
        guard let data = enhancedImage else { return nil }
        return UIImage(data: data)
    }
    
    /// Convert thumbnail image data to UIImage
    var thumbnailUIImage: UIImage? {
        guard let data = thumbnailImage else { return nil }
        return UIImage(data: data)
    }
}

/// Processing quality levels
enum ProcessingQuality: String, Codable, CaseIterable {
    case original = "Original"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .original:
            return "No enhancements applied"
        case .low:
            return "Light enhancements"
        case .medium:
            return "Moderate enhancements"
        case .high:
            return "Heavy enhancements"
        }
    }
}