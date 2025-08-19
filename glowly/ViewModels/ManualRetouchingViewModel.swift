//
//  ManualRetouchingViewModel.swift
//  Glowly
//
//  ViewModel for manual retouching operations with advanced brush controls
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ManualRetouchingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var originalPhoto: GlowlyPhoto
    @Published var originalImage: UIImage?
    @Published var currentImage: UIImage?
    @Published var selectedCategory: EnhancementCategory = .skinTools
    @Published var activeTool: EnhancementType?
    @Published var brushConfiguration = BrushConfiguration()
    @Published var toolIntensity: Float = 0.5
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var showingBeforeAfter = false
    @Published var showingColorPicker = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    // Touch handling
    @Published var lastTouchPoint: CGPoint = .zero
    @Published var currentTouchPoints: [TouchPoint] = []
    
    // Color selection
    @Published var selectedColor = ColorInfo(name: "Natural", red: 0.8, green: 0.6, blue: 0.5)
    @Published var availableColorPalettes: [ColorPalette] = []
    
    // History management
    @Published var operationHistory: [ManualRetouchingOperation] = []
    @Published var redoHistory: [ManualRetouchingOperation] = []
    @Published var canUndo = false
    @Published var canRedo = false
    
    // Face detection
    @Published var detectedFaceRegions: DetectedFaceRegions?
    @Published var isAnalyzingFace = false
    
    // MARK: - Dependencies
    @Inject private var manualRetouchingService: ManualRetouchingServiceProtocol
    @Inject private var photoRepository: PhotoRepositoryProtocol
    @Inject private var analyticsService: AnalyticsServiceProtocol
    @Inject private var errorHandlingService: ErrorHandlingServiceProtocol
    
    // MARK: - Computed Properties
    var toolsForSelectedCategory: [EnhancementType] {
        EnhancementType.allCases.filter { $0.category == selectedCategory }
    }
    
    var isColorTool: Bool {
        guard let tool = activeTool else { return false }
        return [.eyeColorChanger, .hairColorChanger, .lipColorChanger].contains(tool)
    }
    
    var hasChanges: Bool {
        !operationHistory.isEmpty
    }
    
    var operationCount: Int {
        operationHistory.count
    }
    
    var totalProcessingTime: TimeInterval {
        operationHistory.reduce(0) { $0 + $1.processingTime }
    }
    
    // MARK: - Initialization
    init(photo: GlowlyPhoto) {
        self.originalPhoto = photo
        
        // Load original image
        if let imageData = photo.originalImage {
            self.originalImage = UIImage(data: imageData)
            self.currentImage = UIImage(data: imageData)
        }
        
        // Initialize color palettes
        self.availableColorPalettes = [
            .naturalEyeColors,
            .vibrantEyeColors,
            .naturalHairColors,
            .naturalLipColors
        ]
        
        Task {
            await performInitialFaceDetection()
            await trackScreenView()
        }
    }
    
    // MARK: - Tool Selection
    
    func selectCategory(_ category: EnhancementCategory) {
        selectedCategory = category
        activeTool = nil
        clearCurrentTouchPoints()
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "retouching_category_selected", category: .ui),
                parameters: ["category": category.rawValue]
            )
        }
    }
    
    func selectTool(_ tool: EnhancementType) {
        activeTool = tool
        toolIntensity = tool.defaultIntensity
        clearCurrentTouchPoints()
        
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "retouching_tool_selected", category: .enhancement),
                parameters: [
                    "tool": tool.rawValue,
                    "category": tool.category.rawValue,
                    "is_premium": tool.isPremium
                ]
            )
        }
    }
    
    // MARK: - Brush Configuration
    
    func updateBrushSize(_ size: Float) {
        brushConfiguration = BrushConfiguration(
            size: size,
            hardness: brushConfiguration.hardness,
            opacity: brushConfiguration.opacity,
            flow: brushConfiguration.flow,
            spacing: brushConfiguration.spacing,
            blendMode: brushConfiguration.blendMode
        )
    }
    
    func updateBrushHardness(_ hardness: Float) {
        brushConfiguration = BrushConfiguration(
            size: brushConfiguration.size,
            hardness: hardness,
            opacity: brushConfiguration.opacity,
            flow: brushConfiguration.flow,
            spacing: brushConfiguration.spacing,
            blendMode: brushConfiguration.blendMode
        )
    }
    
    func updateBrushOpacity(_ opacity: Float) {
        brushConfiguration = BrushConfiguration(
            size: brushConfiguration.size,
            hardness: brushConfiguration.hardness,
            opacity: opacity,
            flow: brushConfiguration.flow,
            spacing: brushConfiguration.spacing,
            blendMode: brushConfiguration.blendMode
        )
    }
    
    // MARK: - Touch Handling
    
    func addTouchPoint(_ location: CGPoint, pressure: Float) {
        lastTouchPoint = location
        let touchPoint = TouchPoint(location: location, pressure: pressure)
        currentTouchPoints.append(touchPoint)
    }
    
    func clearCurrentTouchPoints() {
        currentTouchPoints.removeAll()
        lastTouchPoint = .zero
    }
    
    // MARK: - Brush Operations
    
    func applyCurrentBrushStroke() async {
        guard let tool = activeTool,
              let image = currentImage,
              !currentTouchPoints.isEmpty else {
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        let operation = ManualRetouchingOperation(
            enhancementType: tool,
            brushConfiguration: brushConfiguration,
            touchPoints: currentTouchPoints,
            intensity: toolIntensity,
            parameters: buildToolParameters()
        )
        
        do {
            let result = try await manualRetouchingService.applyBrushOperation(operation, to: image)
            
            if result.success, let processedImageData = result.processedImageData {
                if let processedImage = UIImage(data: processedImageData) {
                    currentImage = processedImage
                    
                    // Add to history
                    operationHistory.append(operation)
                    redoHistory.removeAll()
                    updateUndoRedoState()
                    
                    // Save current state
                    await saveCurrentState()
                    
                    // Track analytics
                    await analyticsService.trackEvent(
                        AnalyticsEvent(name: "retouching_operation_applied", category: .enhancement),
                        parameters: [
                            "tool": tool.rawValue,
                            "intensity": toolIntensity,
                            "touch_points": currentTouchPoints.count,
                            "processing_time": result.processingTime,
                            "success": true
                        ]
                    )
                }
            } else {
                await handleError(ManualRetouchingError.blendingFailed, context: "Applying \\(tool.displayName)")
            }
            
        } catch {
            await handleError(error, context: "Applying \\(tool.displayName)")
        }
        
        clearCurrentTouchPoints()
        isProcessing = false
        processingProgress = 0.0
    }
    
    private func buildToolParameters() -> [String: Float] {
        var parameters: [String: Float] = [:]
        
        if isColorTool {
            parameters["color_red"] = selectedColor.red
            parameters["color_green"] = selectedColor.green
            parameters["color_blue"] = selectedColor.blue
            parameters["color_alpha"] = selectedColor.alpha
        }
        
        return parameters
    }
    
    // MARK: - History Management
    
    func undoLastOperation() {
        guard !operationHistory.isEmpty else { return }
        
        let lastOperation = operationHistory.removeLast()
        redoHistory.append(lastOperation)
        
        // Reapply all remaining operations
        Task {
            await reapplyAllOperations()
            updateUndoRedoState()
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "retouching_undo", category: .enhancement)
            )
        }
    }
    
    func redoLastOperation() {
        guard !redoHistory.isEmpty else { return }
        
        let operation = redoHistory.removeLast()
        operationHistory.append(operation)
        
        // Reapply all operations
        Task {
            await reapplyAllOperations()
            updateUndoRedoState()
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "retouching_redo", category: .enhancement)
            )
        }
    }
    
    private func reapplyAllOperations() async {
        guard let originalImage = originalImage else { return }
        
        var workingImage = originalImage
        
        for operation in operationHistory {
            do {
                let result = try await manualRetouchingService.applyBrushOperation(operation, to: workingImage)
                if result.success, let processedImageData = result.processedImageData {
                    if let processedImage = UIImage(data: processedImageData) {
                        workingImage = processedImage
                    }
                }
            } catch {
                await handleError(error, context: "Reapplying operations")
                break
            }
        }
        
        currentImage = workingImage
        await saveCurrentState()
    }
    
    private func updateUndoRedoState() {
        canUndo = !operationHistory.isEmpty
        canRedo = !redoHistory.isEmpty
    }
    
    // MARK: - Face Detection
    
    private func performInitialFaceDetection() async {
        guard let image = originalImage else { return }
        
        isAnalyzingFace = true
        
        do {
            detectedFaceRegions = try await manualRetouchingService.detectFaceRegions(in: image)
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "face_detection_completed", category: .analysis),
                parameters: [
                    "confidence": detectedFaceRegions?.confidence ?? 0.0,
                    "regions_detected": detectedFaceRegions?.regions.count ?? 0
                ]
            )
            
        } catch {
            await handleError(error, context: "Face detection")
        }
        
        isAnalyzingFace = false
    }
    
    // MARK: - Color Management
    
    func updateSelectedColor(_ color: ColorInfo) {
        selectedColor = color
        
        // Generate adaptive palette if needed
        if let tool = activeTool, isColorTool {
            Task {
                await generateAdaptiveColorPalette(for: tool)
            }
        }
    }
    
    private func generateAdaptiveColorPalette(for tool: EnhancementType) async {
        guard let image = currentImage else { return }
        
        let region: FaceRegion
        switch tool {
        case .eyeColorChanger:
            region = .eyes
        case .hairColorChanger:
            region = .hair
        case .lipColorChanger:
            region = .lips
        default:
            return
        }
        
        if let palette = await manualRetouchingService.generateColorPalette(for: region, from: image) {
            if !availableColorPalettes.contains(where: { $0.name == palette.name }) {
                availableColorPalettes.append(palette)
            }
        }
    }
    
    // MARK: - Save and Reset
    
    func saveChanges() async {
        guard let image = currentImage,
              hasChanges else {
            return
        }
        
        do {
            let imageData = image.jpegData(compressionQuality: 0.9) ?? Data()
            
            let updatedPhoto = GlowlyPhoto(
                id: originalPhoto.id,
                originalAssetIdentifier: originalPhoto.originalAssetIdentifier,
                originalImage: originalPhoto.originalImage,
                enhancedImage: imageData,
                thumbnailImage: originalPhoto.thumbnailImage,
                createdAt: originalPhoto.createdAt,
                updatedAt: Date(),
                metadata: originalPhoto.metadata,
                enhancementHistory: [] // Manual operations aren't stored as Enhancement objects
            )
            
            try await photoRepository.updatePhoto(updatedPhoto)
            originalPhoto = updatedPhoto
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "manual_retouching_saved", category: .enhancement),
                parameters: [
                    "operation_count": operationCount,
                    "total_processing_time": totalProcessingTime,
                    "categories_used": Set(operationHistory.map { $0.enhancementType.category.rawValue }).count
                ]
            )
            
        } catch {
            await handleError(error, context: "Saving changes")
        }
    }
    
    func resetToOriginal() {
        currentImage = originalImage
        operationHistory.removeAll()
        redoHistory.removeAll()
        updateUndoRedoState()
        
        Task {
            await saveCurrentState()
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "manual_retouching_reset", category: .enhancement)
            )
        }
    }
    
    private func saveCurrentState() async {
        // Auto-save current state periodically
        // Implementation would save to temporary storage
    }
    
    private func trackScreenView() async {
        await analyticsService.trackScreenView("manual_retouching")
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error, context: String) async {
        await errorHandlingService.logError(error, context: context)
        
        let action = await errorHandlingService.handleError(error, context: context)
        
        switch action {
        case .showUserError(let userError):
            await showError(userError.message)
        case .silent:
            break
        default:
            await showError("An unexpected error occurred during \\(context.lowercased()). Please try again.")
        }
    }
    
    @MainActor
    private func showError(_ message: String) async {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
}

// MARK: - Color Extension
extension ColorInfo {
    var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}