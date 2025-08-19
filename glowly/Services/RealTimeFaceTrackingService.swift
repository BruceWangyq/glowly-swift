//
//  RealTimeFaceTrackingService.swift
//  Glowly
//
//  Real-time face tracking and analysis for camera preview
//

import Foundation
import AVFoundation
import Vision
import UIKit
import Combine

/// Protocol for real-time face tracking
protocol RealTimeFaceTrackingServiceProtocol {
    func startTracking()
    func stopTracking()
    func updateCameraOutput(_ sampleBuffer: CMSampleBuffer)
    var faceTrackingResults: AnyPublisher<RealTimeFaceTrackingResult, Never> { get }
    var isTracking: Bool { get }
}

/// Real-time face tracking service for camera preview
@MainActor
final class RealTimeFaceTrackingService: RealTimeFaceTrackingServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var currentFaces: [RealTimeFaceResult] = []
    @Published var trackingQuality: TrackingQuality = .none
    @Published var processingFPS: Float = 0.0
    
    // MARK: - Publishers
    private let faceTrackingSubject = PassthroughSubject<RealTimeFaceTrackingResult, Never>()
    var faceTrackingResults: AnyPublisher<RealTimeFaceTrackingResult, Never> {
        faceTrackingSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest!
    private var sequenceHandler = VNSequenceRequestHandler()
    private var lastProcessingTime = CACurrentMediaTime()
    private var processingQueue = DispatchQueue(label: "face-tracking", qos: .userInitiated)
    private var frameSkipCounter = 0
    private let frameSkipThreshold = 2 // Process every 3rd frame for performance
    
    // Face tracking state
    private var trackedFaces: [UUID: TrackedFace] = [:]
    private var faceTrackingThreshold: Float = 0.7
    private var maxTrackingDistance: Float = 0.1
    
    // Performance monitoring
    private var frameProcessingTimes: [TimeInterval] = []
    private let maxPerformanceHistory = 30
    
    // MARK: - Initialization
    
    init() {
        setupFaceDetection()
    }
    
    // MARK: - Tracking Control
    
    /// Start real-time face tracking
    func startTracking() {
        guard !isTracking else { return }
        
        isTracking = true
        trackedFaces.removeAll()
        frameSkipCounter = 0
        lastProcessingTime = CACurrentMediaTime()
        
        print("Real-time face tracking started")
    }
    
    /// Stop real-time face tracking
    func stopTracking() {
        guard isTracking else { return }
        
        isTracking = false
        currentFaces.removeAll()
        trackedFaces.removeAll()
        trackingQuality = .none
        
        // Publish final empty result
        let emptyResult = RealTimeFaceTrackingResult(
            faces: [],
            trackingQuality: .none,
            processingTime: 0,
            frameNumber: 0,
            timestamp: Date()
        )
        faceTrackingSubject.send(emptyResult)
        
        print("Real-time face tracking stopped")
    }
    
    // MARK: - Camera Input Processing
    
    /// Process camera frame for face detection and tracking
    func updateCameraOutput(_ sampleBuffer: CMSampleBuffer) {
        guard isTracking else { return }
        
        // Frame skipping for performance
        frameSkipCounter += 1
        if frameSkipCounter < frameSkipThreshold {
            return
        }
        frameSkipCounter = 0
        
        // Extract image from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        processingQueue.async { [weak self] in
            self?.processFrame(pixelBuffer: pixelBuffer)
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("Face detection error: \(error.localizedDescription)")
                    return
                }
                
                self.handleFaceDetectionResults(request.results as? [VNFaceObservation] ?? [])
            }
        }
        
        // Configure for real-time performance
        faceDetectionRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    private func processFrame(pixelBuffer: CVPixelBuffer) {
        let startTime = CACurrentMediaTime()
        
        // Create image request handler
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            // Perform face detection
            try sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer)
            
            // Update performance metrics
            let processingTime = CACurrentMediaTime() - startTime
            updatePerformanceMetrics(processingTime: processingTime)
            
        } catch {
            print("Face detection request failed: \(error.localizedDescription)")
        }
    }
    
    private func handleFaceDetectionResults(_ observations: [VNFaceObservation]) {
        let startTime = CACurrentMediaTime()
        
        // Convert observations to real-time face results
        var newFaces: [RealTimeFaceResult] = []
        var updatedTrackedFaces: [UUID: TrackedFace] = [:]
        
        for observation in observations {
            if let trackedFace = findMatchingTrackedFace(for: observation) {
                // Update existing tracked face
                let updatedFace = updateTrackedFace(trackedFace, with: observation)
                updatedTrackedFaces[updatedFace.id] = updatedFace
                
                let faceResult = createRealTimeFaceResult(from: updatedFace, observation: observation)
                newFaces.append(faceResult)
                
            } else {
                // Create new tracked face
                let newTrackedFace = createNewTrackedFace(from: observation)
                updatedTrackedFaces[newTrackedFace.id] = newTrackedFace
                
                let faceResult = createRealTimeFaceResult(from: newTrackedFace, observation: observation)
                newFaces.append(faceResult)
            }
        }
        
        // Remove faces that are no longer detected
        cleanupLostFaces(currentObservations: observations, updatedFaces: &updatedTrackedFaces)
        
        // Update state
        trackedFaces = updatedTrackedFaces
        currentFaces = newFaces
        
        // Calculate tracking quality
        let quality = calculateTrackingQuality(faces: newFaces)
        trackingQuality = quality
        
        // Create result and publish
        let processingTime = CACurrentMediaTime() - startTime
        let result = RealTimeFaceTrackingResult(
            faces: newFaces,
            trackingQuality: quality,
            processingTime: processingTime,
            frameNumber: Int.random(in: 1000...9999), // Simplified frame counting
            timestamp: Date()
        )
        
        faceTrackingSubject.send(result)
    }
    
    // MARK: - Face Tracking Logic
    
    private func findMatchingTrackedFace(for observation: VNFaceObservation) -> TrackedFace? {
        let observationCenter = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        // Find closest tracked face within threshold
        var closestFace: TrackedFace?
        var closestDistance: Float = Float.greatestFiniteMagnitude
        
        for trackedFace in trackedFaces.values {
            let distance = calculateDistance(
                from: observationCenter,
                to: trackedFace.lastKnownPosition
            )
            
            if distance < maxTrackingDistance && distance < closestDistance {
                closestDistance = distance
                closestFace = trackedFace
            }
        }
        
        return closestFace
    }
    
    private func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> Float {
        let dx = Float(point1.x - point2.x)
        let dy = Float(point1.y - point2.y)
        return sqrt(dx * dx + dy * dy)
    }
    
    private func createNewTrackedFace(from observation: VNFaceObservation) -> TrackedFace {
        let id = UUID()
        let position = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        return TrackedFace(
            id: id,
            lastKnownPosition: position,
            boundingBox: observation.boundingBox,
            confidence: observation.confidence,
            trackingStability: 0.5,
            framesSinceDetection: 0,
            firstDetectedAt: Date(),
            lastUpdatedAt: Date()
        )
    }
    
    private func updateTrackedFace(_ trackedFace: TrackedFace, with observation: VNFaceObservation) -> TrackedFace {
        let newPosition = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        // Update tracking stability based on consistent detection
        let stabilityIncrease: Float = 0.1
        let newStability = min(1.0, trackedFace.trackingStability + stabilityIncrease)
        
        return TrackedFace(
            id: trackedFace.id,
            lastKnownPosition: newPosition,
            boundingBox: observation.boundingBox,
            confidence: observation.confidence,
            trackingStability: newStability,
            framesSinceDetection: 0,
            firstDetectedAt: trackedFace.firstDetectedAt,
            lastUpdatedAt: Date()
        )
    }
    
    private func cleanupLostFaces(currentObservations: [VNFaceObservation], updatedFaces: inout [UUID: TrackedFace]) {
        let maxFramesWithoutDetection = 10
        
        for (id, trackedFace) in trackedFaces {
            var face = updatedFaces[id] ?? trackedFace
            
            // If face wasn't updated this frame, increment frames since detection
            if updatedFaces[id] == nil {
                face.framesSinceDetection += 1
                
                // Remove faces that haven't been detected for too long
                if face.framesSinceDetection > maxFramesWithoutDetection {
                    continue // Don't add to updated faces (effectively removing it)
                }
                
                // Decrease tracking stability for faces not recently detected
                face.trackingStability = max(0.0, face.trackingStability - 0.05)
                updatedFaces[id] = face
            }
        }
    }
    
    private func createRealTimeFaceResult(from trackedFace: TrackedFace, observation: VNFaceObservation) -> RealTimeFaceResult {
        // Extract basic landmarks
        let landmarks = extractBasicLandmarks(from: observation)
        
        // Analyze face orientation
        let orientation = analyzeFaceOrientation(from: observation)
        
        // Calculate quality metrics
        let qualityMetrics = calculateRealTimeQualityMetrics(
            observation: observation,
            trackingStability: trackedFace.trackingStability
        )
        
        // Determine enhancement suggestions
        let suggestions = generateRealTimeEnhancementSuggestions(
            qualityMetrics: qualityMetrics,
            orientation: orientation
        )
        
        return RealTimeFaceResult(
            id: trackedFace.id,
            boundingBox: observation.boundingBox,
            confidence: observation.confidence,
            trackingStability: trackedFace.trackingStability,
            landmarks: landmarks,
            orientation: orientation,
            qualityMetrics: qualityMetrics,
            enhancementSuggestions: suggestions,
            isStable: trackedFace.trackingStability > 0.7
        )
    }
    
    // MARK: - Analysis Methods
    
    private func extractBasicLandmarks(from observation: VNFaceObservation) -> RealTimeFaceLandmarks? {
        guard let landmarks = observation.landmarks else { return nil }
        
        return RealTimeFaceLandmarks(
            leftEye: landmarks.leftEye?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
            rightEye: landmarks.rightEye?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
            nose: landmarks.nose?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) },
            mouth: landmarks.outerLips?.normalizedPoints.first.map { CGPoint(x: $0.x, y: $0.y) }
        )
    }
    
    private func analyzeFaceOrientation(from observation: VNFaceObservation) -> FaceOrientation {
        // Simplified orientation analysis based on bounding box and landmarks
        let bbox = observation.boundingBox
        
        // Analyze based on face position and aspect ratio
        let isProfileLike = bbox.width / bbox.height < 0.8
        let isFrontal = bbox.width / bbox.height > 0.9
        
        if isProfileLike {
            return bbox.midX < 0.5 ? .leftProfile : .rightProfile
        } else if isFrontal {
            return .frontal
        } else {
            return bbox.midX < 0.5 ? .leftThreeQuarter : .rightThreeQuarter
        }
    }
    
    private func calculateRealTimeQualityMetrics(
        observation: VNFaceObservation,
        trackingStability: Float
    ) -> RealTimeQualityMetrics {
        
        // Basic quality assessment for real-time processing
        let lightingScore = observation.confidence // Simplified
        let sharpnessScore = min(observation.confidence + 0.1, 1.0) // Simplified
        let poseScore = observation.confidence // Simplified
        
        return RealTimeQualityMetrics(
            lighting: lightingScore,
            sharpness: sharpnessScore,
            pose: poseScore,
            stability: trackingStability,
            overallQuality: (lightingScore + sharpnessScore + poseScore + trackingStability) / 4.0
        )
    }
    
    private func generateRealTimeEnhancementSuggestions(
        qualityMetrics: RealTimeQualityMetrics,
        orientation: FaceOrientation
    ) -> [RealTimeEnhancementSuggestion] {
        
        var suggestions: [RealTimeEnhancementSuggestion] = []
        
        // Lighting suggestion
        if qualityMetrics.lighting < 0.6 {
            suggestions.append(RealTimeEnhancementSuggestion(
                type: .lighting,
                confidence: 0.8,
                message: "Improve lighting for better quality"
            ))
        }
        
        // Pose suggestion
        if orientation != .frontal && qualityMetrics.pose < 0.7 {
            suggestions.append(RealTimeEnhancementSuggestion(
                type: .pose,
                confidence: 0.9,
                message: "Face camera directly for best results"
            ))
        }
        
        // Stability suggestion
        if qualityMetrics.stability < 0.5 {
            suggestions.append(RealTimeEnhancementSuggestion(
                type: .stability,
                confidence: 0.7,
                message: "Hold steady for better tracking"
            ))
        }
        
        return suggestions
    }
    
    private func calculateTrackingQuality(faces: [RealTimeFaceResult]) -> TrackingQuality {
        guard !faces.isEmpty else { return .none }
        
        let averageStability = faces.map { $0.trackingStability }.reduce(0, +) / Float(faces.count)
        let averageQuality = faces.map { $0.qualityMetrics.overallQuality }.reduce(0, +) / Float(faces.count)
        
        let overallScore = (averageStability + averageQuality) / 2.0
        
        switch overallScore {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func updatePerformanceMetrics(processingTime: TimeInterval) {
        frameProcessingTimes.append(processingTime)
        
        // Keep only recent processing times
        if frameProcessingTimes.count > maxPerformanceHistory {
            frameProcessingTimes.removeFirst()
        }
        
        // Calculate average FPS
        let averageProcessingTime = frameProcessingTimes.reduce(0, +) / Double(frameProcessingTimes.count)
        processingFPS = Float(1.0 / averageProcessingTime)
    }
    
    // MARK: - Public Utility Methods
    
    /// Get the most stable face currently being tracked
    func getMostStableFace() -> RealTimeFaceResult? {
        return currentFaces.max { $0.trackingStability < $1.trackingStability }
    }
    
    /// Check if any face is well-positioned for photo capture
    func hasWellPositionedFace() -> Bool {
        return currentFaces.contains { face in
            face.isStable &&
            face.orientation == .frontal &&
            face.qualityMetrics.overallQuality > 0.7
        }
    }
    
    /// Get enhancement suggestions for the primary face
    func getPrimaryFaceEnhancementSuggestions() -> [RealTimeEnhancementSuggestion] {
        return getMostStableFace()?.enhancementSuggestions ?? []
    }
}

// MARK: - Supporting Data Models

/// Real-time face tracking result
struct RealTimeFaceTrackingResult: Codable {
    let faces: [RealTimeFaceResult]
    let trackingQuality: TrackingQuality
    let processingTime: TimeInterval
    let frameNumber: Int
    let timestamp: Date
    
    var primaryFace: RealTimeFaceResult? {
        faces.max { $0.trackingStability < $1.trackingStability }
    }
    
    var faceCount: Int { faces.count }
    var hasStableFaces: Bool { faces.contains { $0.isStable } }
}

/// Individual real-time face result
struct RealTimeFaceResult: Codable, Identifiable {
    let id: UUID
    let boundingBox: CGRect
    let confidence: Float
    let trackingStability: Float
    let landmarks: RealTimeFaceLandmarks?
    let orientation: FaceOrientation
    let qualityMetrics: RealTimeQualityMetrics
    let enhancementSuggestions: [RealTimeEnhancementSuggestion]
    let isStable: Bool
}

/// Simplified landmarks for real-time processing
struct RealTimeFaceLandmarks: Codable {
    let leftEye: CGPoint?
    let rightEye: CGPoint?
    let nose: CGPoint?
    let mouth: CGPoint?
    
    var hasAllKeyPoints: Bool {
        leftEye != nil && rightEye != nil && nose != nil && mouth != nil
    }
}

/// Face orientation categories
enum FaceOrientation: String, Codable, CaseIterable {
    case frontal = "frontal"
    case leftThreeQuarter = "left_three_quarter"
    case rightThreeQuarter = "right_three_quarter"
    case leftProfile = "left_profile"
    case rightProfile = "right_profile"
    
    var displayName: String {
        switch self {
        case .frontal: return "Frontal"
        case .leftThreeQuarter: return "Left 3/4"
        case .rightThreeQuarter: return "Right 3/4"
        case .leftProfile: return "Left Profile"
        case .rightProfile: return "Right Profile"
        }
    }
    
    var isOptimalForEnhancement: Bool {
        self == .frontal
    }
}

/// Real-time quality metrics
struct RealTimeQualityMetrics: Codable {
    let lighting: Float
    let sharpness: Float
    let pose: Float
    let stability: Float
    let overallQuality: Float
    
    var isGoodQuality: Bool {
        overallQuality > 0.7
    }
    
    var qualityCategory: String {
        switch overallQuality {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Poor"
        }
    }
}

/// Real-time enhancement suggestion
struct RealTimeEnhancementSuggestion: Codable {
    let type: SuggestionType
    let confidence: Float
    let message: String
    
    enum SuggestionType: String, Codable, CaseIterable {
        case lighting = "lighting"
        case pose = "pose"
        case stability = "stability"
        case distance = "distance"
        case angle = "angle"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var icon: String {
            switch self {
            case .lighting: return "sun.max"
            case .pose: return "person.crop.circle"
            case .stability: return "hand.raised"
            case .distance: return "arrow.up.and.down"
            case .angle: return "rotate.3d"
            }
        }
    }
}

/// Tracking quality levels
enum TrackingQuality: String, Codable, CaseIterable {
    case none = "none"
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: UIColor {
        switch self {
        case .none: return .systemGray
        case .poor: return .systemRed
        case .fair: return .systemOrange
        case .good: return .systemBlue
        case .excellent: return .systemGreen
        }
    }
    
    var score: Float {
        switch self {
        case .none: return 0.0
        case .poor: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .excellent: return 1.0
        }
    }
}

/// Internal tracked face state
private struct TrackedFace {
    let id: UUID
    let lastKnownPosition: CGPoint
    let boundingBox: CGRect
    let confidence: Float
    var trackingStability: Float
    var framesSinceDetection: Int
    let firstDetectedAt: Date
    let lastUpdatedAt: Date
}