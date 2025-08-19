//
//  SmartEnhancementPipeline.swift
//  Glowly
//
//  Smart processing pipeline for efficient batch enhancement processing with real-time previews
//

import Foundation
import UIKit
import CoreImage
import Vision
import Combine

/// Protocol for smart enhancement pipeline operations
protocol SmartEnhancementPipelineProtocol {
    func processEnhancement(request: EnhancementRequest) async throws -> EnhancementResult
    func generatePreview(request: PreviewRequest) async throws -> PreviewResult
    func batchProcess(requests: [EnhancementRequest]) async throws -> [EnhancementResult]
    func cancelProcessing(requestId: UUID)
}

/// Smart enhancement processing pipeline
@MainActor
final class SmartEnhancementPipeline: SmartEnhancementPipelineProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeRequests: [UUID: ProcessingStatus] = [:]
    @Published var processingQueue: [EnhancementRequest] = []
    @Published var completedResults: [UUID: EnhancementResult] = [:]
    @Published var isProcessing = false
    @Published var totalProgress: Float = 0.0
    
    // MARK: - Dependencies
    private let imageProcessor: ImageProcessingService
    private let faceProcessor: FaceEnhancementProcessor
    private let effectsProcessor: EffectsProcessor
    private let qualityAssurance: QualityAssuranceService
    private let memoryManager: MemoryManager
    
    // MARK: - Private Properties
    private let ciContext: CIContext
    private let processingQueue_internal = DispatchQueue(label: "enhancement.processing", qos: .userInitiated)
    private let previewQueue = DispatchQueue(label: "enhancement.preview", qos: .userInteractive)
    private var cancellables = Set<AnyCancellable>()
    private var activeProcessingTasks: [UUID: Task<Void, Never>] = [:]
    
    // Processing configuration
    private let maxConcurrentProcessing = 3
    private let previewSize = CGSize(width: 400, height: 400)
    private let processingMemoryLimit = 500 * 1024 * 1024 // 500MB
    
    // MARK: - Initialization
    
    init(
        imageProcessor: ImageProcessingService = ImageProcessingService(),
        memoryManager: MemoryManager = MemoryManager.shared
    ) {
        self.imageProcessor = imageProcessor
        self.faceProcessor = FaceEnhancementProcessor()
        self.effectsProcessor = EffectsProcessor()
        self.qualityAssurance = QualityAssuranceService()
        self.memoryManager = memoryManager
        
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .cacheIntermediates: false,
            .priorityRequestLow: false
        ])
        
        setupPipeline()
    }
    
    // MARK: - Main Processing Methods
    
    /// Process single enhancement request
    func processEnhancement(request: EnhancementRequest) async throws -> EnhancementResult {
        // Update status
        activeRequests[request.id] = .queued
        
        // Check memory availability
        try await memoryManager.ensureAvailableMemory(processingMemoryLimit)
        
        let startTime = Date()
        
        do {
            // Update status to processing
            activeRequests[request.id] = .processing(progress: 0.0)
            
            // Validate and prepare image
            let preparedImage = try await prepareImageForProcessing(request.image)
            updateProgress(request.id, progress: 0.1)
            
            // Apply enhancements in optimal order
            let enhancedImage = try await applyEnhancementsSequentially(
                image: preparedImage,
                enhancements: request.enhancements,
                requestId: request.id
            )
            updateProgress(request.id, progress: 0.8)
            
            // Post-processing and quality assurance
            let finalImage = try await performPostProcessing(
                image: enhancedImage,
                originalImage: request.image,
                quality: request.qualityLevel
            )
            updateProgress(request.id, progress: 0.9)
            
            // Generate result with analytics
            let result = try await generateResult(
                request: request,
                finalImage: finalImage,
                processingTime: Date().timeIntervalSince(startTime)
            )
            updateProgress(request.id, progress: 1.0)
            
            // Update status and cache result
            activeRequests[request.id] = .completed
            completedResults[request.id] = result
            
            return result
            
        } catch {
            activeRequests[request.id] = .failed(error)
            throw error
        }
    }
    
    /// Generate quick preview
    func generatePreview(request: PreviewRequest) async throws -> PreviewResult {
        return try await withCheckedThrowingContinuation { continuation in
            previewQueue.async {
                Task {
                    do {
                        let startTime = Date()
                        
                        // Create preview-sized image
                        let previewImage = request.image.resized(to: self.previewSize)
                        
                        // Apply quick enhancements
                        let quickEnhancedImage = try await self.applyQuickEnhancements(
                            image: previewImage,
                            enhancements: request.quickEnhancements
                        )
                        
                        let result = PreviewResult(
                            previewImage: quickEnhancedImage,
                            estimatedFullProcessingTime: self.estimateProcessingTime(request.enhancements),
                            confidence: request.confidence,
                            previewGenerationTime: Date().timeIntervalSince(startTime)
                        )
                        
                        continuation.resume(returning: result)
                        
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Process multiple requests in batch
    func batchProcess(requests: [EnhancementRequest]) async throws -> [EnhancementResult] {
        guard !requests.isEmpty else { return [] }
        
        isProcessing = true
        totalProgress = 0.0
        
        defer {
            isProcessing = false
            totalProgress = 0.0
        }
        
        // Group requests by priority and complexity
        let prioritizedRequests = prioritizeRequests(requests)
        
        // Process in batches with concurrency control
        let batchSize = min(maxConcurrentProcessing, requests.count)
        var results: [EnhancementResult] = []
        
        for batchIndex in stride(from: 0, to: prioritizedRequests.count, by: batchSize) {
            let batchEnd = min(batchIndex + batchSize, prioritizedRequests.count)
            let batch = Array(prioritizedRequests[batchIndex..<batchEnd])
            
            // Process batch concurrently
            let batchResults = try await withThrowingTaskGroup(of: EnhancementResult.self) { group in
                for request in batch {
                    group.addTask {
                        try await self.processEnhancement(request: request)
                    }
                }
                
                var batchResults: [EnhancementResult] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Update total progress
            totalProgress = Float(results.count) / Float(requests.count)
        }
        
        return results
    }
    
    /// Cancel processing for specific request
    func cancelProcessing(requestId: UUID) {
        activeProcessingTasks[requestId]?.cancel()
        activeProcessingTasks.removeValue(forKey: requestId)
        activeRequests[requestId] = .cancelled
    }
    
    // MARK: - Private Processing Methods
    
    private func setupPipeline() {
        // Setup memory monitoring
        memoryManager.memoryWarningPublisher
            .sink { [weak self] in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func prepareImageForProcessing(_ image: UIImage) async throws -> CIImage {
        guard let ciImage = CIImage(image: image) else {
            throw PipelineError.invalidImage
        }
        
        // Optimize image size for processing
        let optimalSize = calculateOptimalProcessingSize(originalSize: ciImage.extent.size)
        return ciImage.resized(to: optimalSize)
    }
    
    private func applyEnhancementsSequentially(
        image: CIImage,
        enhancements: [Enhancement],
        requestId: UUID
    ) async throws -> CIImage {
        
        var currentImage = image
        let totalEnhancements = enhancements.count
        
        // Sort enhancements by processing order
        let sortedEnhancements = enhancements.sorted { $0.processingOrder < $1.processingOrder }
        
        for (index, enhancement) in sortedEnhancements.enumerated() {
            // Check for cancellation
            guard activeRequests[requestId] != .cancelled else {
                throw PipelineError.processingCancelled
            }
            
            // Apply individual enhancement
            currentImage = try await applyIndividualEnhancement(
                image: currentImage,
                enhancement: enhancement
            )
            
            // Update progress
            let progress = 0.1 + (0.7 * Float(index + 1) / Float(totalEnhancements))
            updateProgress(requestId, progress: progress)
            
            // Memory management
            if index % 3 == 0 {
                await memoryManager.performMemoryCleanup()
            }
        }
        
        return currentImage
    }
    
    private func applyIndividualEnhancement(
        image: CIImage,
        enhancement: Enhancement
    ) async throws -> CIImage {
        
        switch enhancement.type {
        case .autoEnhance:
            return try await effectsProcessor.applyAutoEnhancement(image, intensity: enhancement.intensity)
            
        case .skinSmoothing:
            return try await faceProcessor.applySkinSmoothing(image, intensity: enhancement.intensity)
            
        case .eyeBrightening:
            return try await faceProcessor.applyEyeBrightening(image, intensity: enhancement.intensity)
            
        case .teethWhitening:
            return try await faceProcessor.applyTeethWhitening(image, intensity: enhancement.intensity)
            
        case .blemishRemoval:
            return try await faceProcessor.applyBlemishRemoval(image, intensity: enhancement.intensity)
            
        case .backgroundBlur:
            return try await effectsProcessor.applyBackgroundBlur(image, intensity: enhancement.intensity)
            
        case .brightness, .contrast, .saturation, .exposure, .highlights, .shadows, .clarity, .warmth:
            return try await effectsProcessor.applyBasicAdjustment(image, enhancement: enhancement)
            
        default:
            // Fallback for unsupported enhancements
            return image
        }
    }
    
    private func applyQuickEnhancements(
        image: UIImage,
        enhancements: [EnhancementConfiguration]
    ) async throws -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            throw PipelineError.invalidImage
        }
        
        var currentImage = ciImage
        
        // Apply only quick-processing enhancements for preview
        for config in enhancements.filter({ $0.isQuickProcessing }) {
            let enhancement = Enhancement(
                type: config.type,
                intensity: config.baseIntensity
            )
            
            currentImage = try await applyIndividualEnhancement(
                image: currentImage,
                enhancement: enhancement
            )
        }
        
        guard let cgImage = ciContext.createCGImage(currentImage, from: currentImage.extent) else {
            throw PipelineError.processingFailed("Failed to create preview image")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func performPostProcessing(
        image: CIImage,
        originalImage: UIImage,
        quality: QualityLevel
    ) async throws -> UIImage {
        
        // Apply quality-specific post-processing
        var processedImage = image
        
        switch quality {
        case .preview:
            // Minimal post-processing for preview
            break
            
        case .standard:
            // Standard quality optimizations
            processedImage = try await effectsProcessor.applyStandardOptimizations(processedImage)
            
        case .high:
            // High quality processing with noise reduction and sharpening
            processedImage = try await effectsProcessor.applyHighQualityOptimizations(processedImage)
            
        case .maximum:
            // Maximum quality with advanced processing
            processedImage = try await effectsProcessor.applyMaximumQualityOptimizations(processedImage)
        }
        
        // Quality assurance check
        let qualityCheck = await qualityAssurance.validateEnhancementQuality(
            original: CIImage(image: originalImage)!,
            enhanced: processedImage
        )
        
        if !qualityCheck.passed {
            // Apply corrections if quality check failed
            processedImage = try await qualityAssurance.applyQualityCorrections(
                image: processedImage,
                issues: qualityCheck.issues
            )
        }
        
        guard let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent) else {
            throw PipelineError.processingFailed("Failed to create final image")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func generateResult(
        request: EnhancementRequest,
        finalImage: UIImage,
        processingTime: TimeInterval
    ) async throws -> EnhancementResult {
        
        // Calculate enhancement metrics
        let metrics = try await calculateEnhancementMetrics(
            original: request.image,
            enhanced: finalImage,
            enhancements: request.enhancements
        )
        
        return EnhancementResult(
            id: request.id,
            originalImage: request.image,
            enhancedImage: finalImage,
            appliedEnhancements: request.enhancements,
            processingTime: processingTime,
            qualityLevel: request.qualityLevel,
            metrics: metrics,
            timestamp: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ requestId: UUID, progress: Float) {
        Task { @MainActor in
            activeRequests[requestId] = .processing(progress: progress)
        }
    }
    
    private func prioritizeRequests(_ requests: [EnhancementRequest]) -> [EnhancementRequest] {
        return requests.sorted { request1, request2 in
            // Sort by priority first, then by complexity (simpler first)
            if request1.priority != request2.priority {
                return request1.priority.rawValue > request2.priority.rawValue
            }
            return request1.estimatedComplexity < request2.estimatedComplexity
        }
    }
    
    private func calculateOptimalProcessingSize(originalSize: CGSize) -> CGSize {
        let maxDimension: CGFloat = 2048 // Balance quality and performance
        
        if max(originalSize.width, originalSize.height) <= maxDimension {
            return originalSize
        }
        
        let aspectRatio = originalSize.width / originalSize.height
        
        if originalSize.width > originalSize.height {
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
    
    private func estimateProcessingTime(_ enhancements: [Enhancement]) -> TimeInterval {
        var totalTime: TimeInterval = 0
        
        for enhancement in enhancements {
            totalTime += enhancement.type.estimatedProcessingTime
        }
        
        return totalTime
    }
    
    private func calculateEnhancementMetrics(
        original: UIImage,
        enhanced: UIImage,
        enhancements: [Enhancement]
    ) async throws -> EnhancementMetrics {
        
        // Calculate quality improvement
        let originalQuality = await imageProcessor.assessImageQuality(original)
        let enhancedQuality = await imageProcessor.assessImageQuality(enhanced)
        
        return EnhancementMetrics(
            qualityImprovement: enhancedQuality - originalQuality,
            processingEfficiency: 1.0, // Simplified calculation
            memoryUsage: await memoryManager.getCurrentMemoryUsage(),
            enhancementCount: enhancements.count
        )
    }
    
    private func handleMemoryWarning() {
        // Clear preview cache
        Task { @MainActor in
            // Cancel non-critical processing
            for (requestId, status) in activeRequests {
                if case .processing = status {
                    // Cancel lower priority requests
                    cancelProcessing(requestId: requestId)
                }
            }
            
            // Clear completed results cache
            completedResults.removeAll()
        }
    }
}

// MARK: - Supporting Types

/// Enhancement request structure
struct EnhancementRequest {
    let id: UUID
    let image: UIImage
    let enhancements: [Enhancement]
    let qualityLevel: QualityLevel
    let priority: ProcessingPriority
    let estimatedComplexity: Float
    let metadata: [String: Any]
    
    init(
        id: UUID = UUID(),
        image: UIImage,
        enhancements: [Enhancement],
        qualityLevel: QualityLevel = .standard,
        priority: ProcessingPriority = .normal,
        estimatedComplexity: Float = 0.5,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.image = image
        self.enhancements = enhancements
        self.qualityLevel = qualityLevel
        self.priority = priority
        self.estimatedComplexity = estimatedComplexity
        self.metadata = metadata
    }
}

/// Preview request structure
struct PreviewRequest {
    let image: UIImage
    let quickEnhancements: [EnhancementConfiguration]
    let enhancements: [Enhancement]
    let confidence: Float
}

/// Enhancement result
struct EnhancementResult {
    let id: UUID
    let originalImage: UIImage
    let enhancedImage: UIImage
    let appliedEnhancements: [Enhancement]
    let processingTime: TimeInterval
    let qualityLevel: QualityLevel
    let metrics: EnhancementMetrics
    let timestamp: Date
}

/// Preview result
struct PreviewResult {
    let previewImage: UIImage
    let estimatedFullProcessingTime: TimeInterval
    let confidence: Float
    let previewGenerationTime: TimeInterval
}

/// Enhancement metrics
struct EnhancementMetrics {
    let qualityImprovement: Float
    let processingEfficiency: Float
    let memoryUsage: Int64
    let enhancementCount: Int
}

/// Processing status
enum ProcessingStatus: Equatable {
    case queued
    case processing(progress: Float)
    case completed
    case failed(Error)
    case cancelled
    
    static func ==(lhs: ProcessingStatus, rhs: ProcessingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.queued, .queued), (.completed, .completed), (.cancelled, .cancelled):
            return true
        case (.processing(let lProgress), .processing(let rProgress)):
            return lProgress == rProgress
        case (.failed(let lError), .failed(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}

/// Processing priority levels
enum ProcessingPriority: Int, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
}

/// Quality levels for processing
enum QualityLevel: String, CaseIterable {
    case preview = "preview"
    case standard = "standard"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Pipeline-specific errors
enum PipelineError: LocalizedError {
    case invalidImage
    case processingFailed(String)
    case processingCancelled
    case memoryLimitExceeded
    case unsupportedEnhancement
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed(let details):
            return "Processing failed: \(details)"
        case .processingCancelled:
            return "Processing was cancelled"
        case .memoryLimitExceeded:
            return "Memory limit exceeded"
        case .unsupportedEnhancement:
            return "Unsupported enhancement type"
        }
    }
}

// MARK: - Extensions

extension EnhancementType {
    var estimatedProcessingTime: TimeInterval {
        switch self {
        case .autoEnhance:
            return 0.5
        case .skinSmoothing:
            return 1.0
        case .eyeBrightening:
            return 0.3
        case .teethWhitening:
            return 0.4
        case .blemishRemoval:
            return 0.8
        case .backgroundBlur:
            return 1.5
        case .brightness, .contrast, .saturation, .exposure, .highlights, .shadows, .clarity, .warmth:
            return 0.2
        default:
            return 0.3
        }
    }
}

extension Enhancement {
    var processingOrder: Int {
        switch type {
        case .brightness, .exposure, .highlights, .shadows:
            return 1 // Lighting adjustments first
        case .contrast, .clarity:
            return 2 // Contrast and clarity
        case .saturation, .warmth:
            return 3 // Color adjustments
        case .autoEnhance:
            return 4 // General enhancement
        case .skinSmoothing, .blemishRemoval:
            return 5 // Skin enhancements
        case .eyeBrightening, .teethWhitening:
            return 6 // Feature enhancements
        case .backgroundBlur:
            return 7 // Background effects last
        default:
            return 5 // Default order
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension CIImage {
    func resized(to size: CGSize) -> CIImage {
        let scaleX = size.width / extent.width
        let scaleY = size.height / extent.height
        let scale = min(scaleX, scaleY)
        
        return transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}