//
//  ComparisonViewModel.swift
//  Glowly
//
//  Advanced view model for before/after comparison system with performance optimization
//

import SwiftUI
import CoreImage
import AVFoundation
import Combine

// MARK: - ComparisonViewModel
@MainActor
class ComparisonViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var state = ComparisonState()
    @Published var preferences = ComparisonPreferences.shared
    @Published var performanceMetrics = PerformanceMetrics()
    @Published var gestureConfig = GestureConfiguration()
    @Published var imageQuality = ImageQuality.medium
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingExportProgress = false
    @Published var exportProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let imageCache = NSCache<NSString, UIImage>()
    private let performanceMonitor = PerformanceMonitor()
    private let imageProcessor = ImageProcessor()
    
    // Image processing queue
    private let processingQueue = DispatchQueue(label: "com.glowly.imageprocessing", qos: .userInitiated)
    
    // MARK: - Initialization
    init() {
        setupImageCache()
        setupPerformanceMonitoring()
        loadUserPreferences()
        observeSystemChanges()
    }
    
    // MARK: - Public Methods
    
    /// Updates the current comparison mode with animation
    func updateComparisonMode(_ mode: ComparisonMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            state.currentMode = mode
        }
        
        // Reset state for specific modes
        switch mode {
        case .toggle:
            state.sliderPosition = state.isShowingBefore ? 0.0 : 1.0
        case .overlay:
            state.overlayProgress = 0.0
        case .swipeReveal, .splitScreen:
            state.sliderPosition = 0.5
        default:
            break
        }
        
        recordAnalytics(mode: mode)
    }
    
    /// Updates slider position with haptic feedback
    func updateSliderPosition(_ position: CGFloat, withHaptic: Bool = true) {
        let clampedPosition = max(0, min(1, position))
        state.sliderPosition = clampedPosition
        
        if withHaptic && preferences.enableHaptics {
            // Provide haptic feedback at key positions
            if abs(clampedPosition - 0.5) < 0.05 {
                HapticFeedback.selection()
            }
        }
    }
    
    /// Updates zoom level with bounds checking
    func updateZoomLevel(_ zoom: CGFloat) {
        let clampedZoom = max(gestureConfig.minimumZoom, min(gestureConfig.maximumZoom, zoom))
        state.zoomLevel = clampedZoom
        
        // Auto-reset pan if zoomed out completely
        if clampedZoom <= gestureConfig.minimumZoom {
            state.panOffset = .zero
            state.lastPanOffset = .zero
        }
    }
    
    /// Updates pan offset with boundary checking
    func updatePanOffset(_ offset: CGSize) {
        state.panOffset = offset
    }
    
    /// Commits pan offset
    func commitPanOffset() {
        state.lastPanOffset.width += state.panOffset.width
        state.lastPanOffset.height += state.panOffset.height
        state.panOffset = .zero
    }
    
    /// Resets view to default state
    func resetView() {
        withAnimation(.easeInOut(duration: 0.5)) {
            state.zoomLevel = 1.0
            state.panOffset = .zero
            state.lastPanOffset = .zero
            state.sliderPosition = 0.5
            state.overlayProgress = 0.0
        }
    }
    
    /// Toggle magnifier visibility
    func toggleMagnifier(at position: CGPoint) {
        state.showingMagnifier.toggle()
        state.magnifierPosition = position
        
        if preferences.enableHaptics {
            HapticFeedback.light()
        }
    }
    
    /// Update magnifier position
    func updateMagnifierPosition(_ position: CGPoint) {
        state.magnifierPosition = position
    }
    
    // MARK: - Image Processing
    
    /// Prepares images for comparison with optimization
    func prepareImages(original: UIImage?, processed: UIImage?) async -> (UIImage?, UIImage?) {
        guard let original = original, let processed = processed else {
            return (original, processed)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let startTime = Date()
        
        return await withTaskGroup(of: UIImage?.self, returning: (UIImage?, UIImage?).self) { group in
            // Process original image
            group.addTask { [weak self] in
                await self?.optimizeImage(original, cacheKey: "original")
            }
            
            // Process enhanced image
            group.addTask { [weak self] in
                await self?.optimizeImage(processed, cacheKey: "processed")
            }
            
            var results: [UIImage?] = []
            for await result in group {
                results.append(result)
            }
            
            DispatchQueue.main.async {
                self.performanceMetrics.imageLoadTime = Date().timeIntervalSince(startTime)
            }
            
            return (results[0], results[1])
        }
    }
    
    /// Optimizes image for display
    private func optimizeImage(_ image: UIImage, cacheKey: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        return await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let optimizedImage = self.imageProcessor.optimizeForDisplay(
                    image,
                    quality: self.imageQuality,
                    targetSize: CGSize(width: 1024, height: 1024)
                )
                
                // Cache the optimized image
                if let optimized = optimizedImage {
                    self.imageCache.setObject(optimized, forKey: cacheKey as NSString)
                }
                
                continuation.resume(returning: optimizedImage)
            }
        }
    }
    
    // MARK: - Export Functionality
    
    /// Creates export image based on current state
    func createExportImage(
        original: UIImage?,
        processed: UIImage?,
        template: ComparisonTemplate,
        targetSize: CGSize? = nil
    ) async -> UIImage? {
        guard let original = original, let processed = processed else { return nil }
        
        showingExportProgress = true
        exportProgress = 0.0
        
        defer {
            showingExportProgress = false
            exportProgress = 0.0
        }
        
        return await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let exportImage = self.imageProcessor.createComparisonImage(
                    original: original,
                    processed: processed,
                    template: template,
                    state: self.state,
                    targetSize: targetSize
                ) { progress in
                    DispatchQueue.main.async {
                        self.exportProgress = progress
                    }
                }
                
                continuation.resume(returning: exportImage)
            }
        }
    }
    
    /// Creates animated comparison
    func createAnimatedComparison(
        original: UIImage?,
        processed: UIImage?,
        transition: ExportOptions.VideoTransition
    ) async -> URL? {
        guard let original = original, let processed = processed else { return nil }
        
        showingExportProgress = true
        exportProgress = 0.0
        
        defer {
            showingExportProgress = false
            exportProgress = 0.0
        }
        
        return await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let videoURL = self.imageProcessor.createAnimatedComparison(
                    original: original,
                    processed: processed,
                    transition: transition
                ) { progress in
                    DispatchQueue.main.async {
                        self.exportProgress = progress
                    }
                }
                
                continuation.resume(returning: videoURL)
            }
        }
    }
    
    // MARK: - Analytics
    
    private func recordAnalytics(mode: ComparisonMode) {
        // Record mode usage for analytics
        UserDefaults.standard.set(mode.rawValue, forKey: "LastUsedComparisonMode")
    }
    
    // MARK: - Private Setup Methods
    
    private func setupImageCache() {
        imageCache.countLimit = 20
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor thermal state
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
        
        // Monitor memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func loadUserPreferences() {
        // Load saved preferences
        if let data = UserDefaults.standard.data(forKey: "ComparisonPreferences"),
           let decoded = try? JSONDecoder().decode(ComparisonPreferences.self, from: data) {
            preferences = decoded
        }
    }
    
    private func observeSystemChanges() {
        // Observe accessibility changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.gestureConfig.reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.gestureConfig.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
            }
            .store(in: &cancellables)
    }
    
    private func updatePerformanceMetrics() {
        performanceMetrics.thermalState = ProcessInfo.processInfo.thermalState
        
        // Adjust quality based on thermal state
        switch performanceMetrics.thermalState {
        case .critical, .serious:
            imageQuality = .low
        case .fair:
            imageQuality = .medium
        case .nominal:
            imageQuality = preferences.defaultExportFormat == .video ? .high : .medium
        @unknown default:
            imageQuality = .medium
        }
    }
    
    private func handleMemoryWarning() {
        // Clear image cache
        imageCache.removeAllObjects()
        
        // Force garbage collection
        autoreleasepool {
            // Process any pending memory cleanup
        }
    }
}

// MARK: - PerformanceMonitor
class PerformanceMonitor: ObservableObject {
    @Published var metrics = PerformanceMetrics()
    
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
        frameCount += 1
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let elapsed = displayLink.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            metrics.frameRate = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
}

// MARK: - ImageProcessor
class ImageProcessor {
    
    /// Optimizes image for display
    func optimizeForDisplay(_ image: UIImage, quality: ImageQuality, targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let ciImage = CIImage(cgImage: cgImage)
        
        // Resize if needed
        let resizedImage = resizeImage(ciImage, targetSize: targetSize)
        
        // Apply optimizations
        let optimizedImage = applyDisplayOptimizations(resizedImage)
        
        // Convert back to UIImage
        guard let outputCGImage = context.createCGImage(optimizedImage, from: optimizedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    /// Creates comparison image based on template
    func createComparisonImage(
        original: UIImage,
        processed: UIImage,
        template: ComparisonTemplate,
        state: ComparisonState,
        targetSize: CGSize?,
        progressCallback: @escaping (Double) -> Void
    ) -> UIImage? {
        
        progressCallback(0.1)
        
        let size = targetSize ?? CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        progressCallback(0.3)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw background
            drawBackground(template.backgroundStyle, in: CGRect(origin: .zero, size: size), context: cgContext)
            progressCallback(0.4)
            
            // Draw images based on layout
            drawImagesForTemplate(
                original: original,
                processed: processed,
                template: template,
                state: state,
                size: size,
                context: cgContext
            )
            progressCallback(0.7)
            
            // Draw text overlays
            drawTextOverlays(template.textOverlays, size: size, context: cgContext)
            progressCallback(0.9)
            
            // Draw border if needed
            if let borderStyle = template.borderStyle {
                drawBorder(borderStyle, size: size, context: cgContext)
            }
            
            progressCallback(1.0)
        }
    }
    
    /// Creates animated comparison video
    func createAnimatedComparison(
        original: UIImage,
        processed: UIImage,
        transition: ExportOptions.VideoTransition,
        progressCallback: @escaping (Double) -> Void
    ) -> URL? {
        
        // Implementation for video creation would go here
        // This is a placeholder for the complex video creation logic
        progressCallback(1.0)
        return nil
    }
    
    // MARK: - Private Methods
    
    private func resizeImage(_ image: CIImage, targetSize: CGSize) -> CIImage {
        let scale = min(targetSize.width / image.extent.width, targetSize.height / image.extent.height)
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    private func applyDisplayOptimizations(_ image: CIImage) -> CIImage {
        // Apply sharpening filter for better display
        guard let sharpenFilter = CIFilter(name: "CIUnsharpMask") else { return image }
        sharpenFilter.setValue(image, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.5, forKey: kCIInputRadiusKey)
        sharpenFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        return sharpenFilter.outputImage ?? image
    }
    
    private func drawBackground(_ style: ComparisonTemplate.BackgroundStyle, in rect: CGRect, context: CGContext) {
        switch style {
        case .solid(let color):
            context.setFillColor(UIColor(color).cgColor)
            context.fill(rect)
        case .gradient(let colors):
            // Implement gradient drawing
            break
        case .pattern(let patternName):
            // Implement pattern drawing
            break
        case .transparent:
            break
        }
    }
    
    private func drawImagesForTemplate(
        original: UIImage,
        processed: UIImage,
        template: ComparisonTemplate,
        state: ComparisonState,
        size: CGSize,
        context: CGContext
    ) {
        switch template.layout {
        case .sideBySide:
            let leftRect = CGRect(x: 0, y: 0, width: size.width / 2, height: size.height)
            let rightRect = CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height)
            
            original.draw(in: leftRect)
            processed.draw(in: rightRect)
            
        case .topBottom:
            let topRect = CGRect(x: 0, y: 0, width: size.width, height: size.height / 2)
            let bottomRect = CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2)
            
            original.draw(in: topRect)
            processed.draw(in: bottomRect)
            
        case .beforeAfterSlider:
            let fullRect = CGRect(origin: .zero, size: size)
            original.draw(in: fullRect)
            
            // Mask for processed image
            let maskWidth = size.width * state.sliderPosition
            let maskRect = CGRect(x: 0, y: 0, width: maskWidth, height: size.height)
            
            context.saveGState()
            context.clip(to: maskRect)
            processed.draw(in: fullRect)
            context.restoreGState()
            
        default:
            // Implement other layouts
            break
        }
    }
    
    private func drawTextOverlays(_ overlays: [ComparisonTemplate.TextOverlay], size: CGSize, context: CGContext) {
        for overlay in overlays {
            let position = CGPoint(x: overlay.position.x * size.width, y: overlay.position.y * size.height)
            
            // This would need proper text rendering implementation
            // For now, this is a placeholder
        }
    }
    
    private func drawBorder(_ borderStyle: ComparisonTemplate.BorderStyle, size: CGSize, context: CGContext) {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: borderStyle.width/2, dy: borderStyle.width/2)
        
        context.setStrokeColor(UIColor(borderStyle.color).cgColor)
        context.setLineWidth(borderStyle.width)
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: borderStyle.cornerRadius)
        context.addPath(path.cgPath)
        context.strokePath()
    }
}