//
//  FilterPerformanceManager.swift
//  Glowly
//
//  Advanced performance optimization and caching system for filter operations
//

import Foundation
import SwiftUI
import Metal
import MetalKit
import CoreImage
import os.log

/// Protocol for performance management operations
protocol FilterPerformanceManagerProtocol {
    func optimizeForDevice() async
    func configureQualitySettings(for deviceCapability: DeviceCapability) -> ProcessingQuality
    func getCachePolicy() -> CachePolicy
    func manageThermalState(_ state: ThermalState)
    func preloadFilters(_ filters: [BeautyFilter], for image: UIImage) async
    func clearCache(type: CacheType)
    func getPerformanceMetrics() -> PerformanceReport
    var isOptimizationEnabled: Bool { get set }
}

/// Device capability assessment
enum DeviceCapability: String, Codable {
    case high = "high"          // iPhone 12 Pro and newer, iPad Pro
    case medium = "medium"      // iPhone X to 11 Pro, iPad Air
    case low = "low"           // iPhone 8 and older, basic iPad
    case ultraHigh = "ultra_high" // iPhone 14 Pro and newer with advanced capabilities
    
    var maxConcurrentFilters: Int {
        switch self {
        case .ultraHigh: return 8
        case .high: return 6
        case .medium: return 4
        case .low: return 2
        }
    }
    
    var defaultProcessingQuality: ProcessingQuality {
        switch self {
        case .ultraHigh: return .ultra
        case .high: return .high
        case .medium: return .standard
        case .low: return .draft
        }
    }
    
    var enableGPUAcceleration: Bool {
        switch self {
        case .ultraHigh, .high: return true
        case .medium: return true
        case .low: return false
        }
    }
    
    var maxMemoryBudget: Int {
        switch self {
        case .ultraHigh: return 1_000_000_000 // 1GB
        case .high: return 750_000_000        // 750MB
        case .medium: return 500_000_000      // 500MB
        case .low: return 250_000_000         // 250MB
        }
    }
}

/// Cache management types
enum CacheType: String, Codable, CaseIterable {
    case filterPreview = "filter_preview"
    case processedImage = "processed_image"
    case maskSegmentation = "mask_segmentation"
    case faceDetection = "face_detection"
    case all = "all"
}

/// Cache policy configuration
struct CachePolicy: Codable {
    let maxMemoryUsage: Int
    let maxDiskUsage: Int
    let timeToLive: TimeInterval
    let compressionEnabled: Bool
    let preloadCount: Int
    let evictionStrategy: EvictionStrategy
    
    enum EvictionStrategy: String, Codable {
        case lru = "lru"           // Least Recently Used
        case lfu = "lfu"           // Least Frequently Used
        case ttl = "ttl"           // Time To Live
        case size = "size"         // Size-based
        case adaptive = "adaptive"  // Adaptive based on usage patterns
    }
}

/// Performance monitoring and reporting
struct PerformanceReport: Codable {
    let timestamp: Date
    let deviceCapability: DeviceCapability
    let thermalState: ThermalState
    let memoryUsage: MemoryUsage
    let processingMetrics: ProcessingMetrics
    let cacheMetrics: CacheMetrics
    let batteryImpact: BatteryImpact
    let recommendations: [PerformanceRecommendation]
}

struct MemoryUsage: Codable {
    let current: Int
    let peak: Int
    let available: Int
    let pressure: MemoryPressure
    
    enum MemoryPressure: String, Codable {
        case normal = "normal"
        case warning = "warning"
        case critical = "critical"
    }
}

struct CacheMetrics: Codable {
    let hitRate: Float
    let missRate: Float
    let evictionCount: Int
    let memoryFootprint: Int
    let diskFootprint: Int
}

struct PerformanceRecommendation: Codable, Identifiable {
    let id = UUID()
    let type: RecommendationType
    let priority: Priority
    let description: String
    let impact: String
    let action: String
    
    enum RecommendationType: String, Codable {
        case qualityReduction = "quality_reduction"
        case memoryOptimization = "memory_optimization"
        case cacheAdjustment = "cache_adjustment"
        case thermalThrottling = "thermal_throttling"
        case backgroundProcessing = "background_processing"
    }
    
    enum Priority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

/// Advanced performance manager with intelligent optimization
@MainActor
final class FilterPerformanceManager: FilterPerformanceManagerProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isOptimizationEnabled = true
    @Published var currentDeviceCapability: DeviceCapability = .medium
    @Published var currentThermalState: ThermalState = .nominal
    @Published var memoryUsage: MemoryUsage = MemoryUsage(current: 0, peak: 0, available: 0, pressure: .normal)
    @Published var performanceRecommendations: [PerformanceRecommendation] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.glowly.performance", category: "FilterPerformanceManager")
    private let performanceQueue = DispatchQueue(label: "com.glowly.performance", qos: .utility)
    private let cacheQueue = DispatchQueue(label: "com.glowly.cache", qos: .background)
    
    // Cache managers
    private let previewCache: AdvancedImageCache
    private let processedImageCache: AdvancedImageCache
    private let segmentationCache: AdvancedImageCache
    private let faceDetectionCache: NSCache<NSString, NSArray>
    
    // Performance monitoring
    private var performanceTimer: Timer?
    private var processingMetrics: [String: ProcessingMetrics] = [:]
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // Optimization state
    private var deviceInfo: DeviceInfo
    private var qualitySettings: ProcessingQuality
    private var cachePolicy: CachePolicy
    
    // Preloading and background processing
    private var preloadQueue = OperationQueue()
    private var backgroundQueue = OperationQueue()
    
    // MARK: - Initialization
    init() {
        // Detect device capabilities
        deviceInfo = Self.detectDeviceInfo()
        currentDeviceCapability = Self.assessDeviceCapability(deviceInfo)
        qualitySettings = currentDeviceCapability.defaultProcessingQuality
        
        // Initialize caches
        let cacheConfig = Self.createCacheConfiguration(for: currentDeviceCapability)
        previewCache = AdvancedImageCache(config: cacheConfig.preview)
        processedImageCache = AdvancedImageCache(config: cacheConfig.processed)
        segmentationCache = AdvancedImageCache(config: cacheConfig.segmentation)
        
        faceDetectionCache = NSCache<NSString, NSArray>()
        faceDetectionCache.countLimit = 50
        faceDetectionCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Set up cache policy
        cachePolicy = Self.createCachePolicy(for: currentDeviceCapability)
        
        // Configure operation queues
        preloadQueue.maxConcurrentOperationCount = currentDeviceCapability.maxConcurrentFilters / 2
        preloadQueue.qualityOfService = .utility
        
        backgroundQueue.maxConcurrentOperationCount = 2
        backgroundQueue.qualityOfService = .background
        
        setupPerformanceMonitoring()
        setupMemoryPressureMonitoring()
        setupThermalMonitoring()
        
        logger.info("FilterPerformanceManager initialized for \(currentDeviceCapability.rawValue) capability device")
    }
    
    deinit {
        performanceTimer?.invalidate()
        memoryPressureSource?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Optimize performance settings for current device
    func optimizeForDevice() async {
        logger.info("Optimizing performance for device capability: \(currentDeviceCapability.rawValue)")
        
        await performanceQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Re-assess device capability
            let newCapability = Self.assessDeviceCapability(self.deviceInfo)
            
            await MainActor.run {
                if newCapability != self.currentDeviceCapability {
                    self.currentDeviceCapability = newCapability
                    self.qualitySettings = newCapability.defaultProcessingQuality
                    self.logger.info("Device capability updated to: \(newCapability.rawValue)")
                }
            }
            
            // Update cache configurations
            self.optimizeCacheConfiguration()
            
            // Generate performance recommendations
            let recommendations = self.generatePerformanceRecommendations()
            
            await MainActor.run {
                self.performanceRecommendations = recommendations
            }
        }
    }
    
    /// Configure quality settings based on device capability
    func configureQualitySettings(for deviceCapability: DeviceCapability) -> ProcessingQuality {
        let baseQuality = deviceCapability.defaultProcessingQuality
        
        // Adjust for thermal state
        switch currentThermalState {
        case .nominal:
            return baseQuality
        case .fair:
            return baseQuality
        case .serious:
            return ProcessingQuality(rawValue: max(0, ProcessingQuality.allCases.firstIndex(of: baseQuality)! - 1))
                ?? .draft
        case .critical:
            return .draft
        }
    }
    
    /// Get current cache policy
    func getCachePolicy() -> CachePolicy {
        return cachePolicy
    }
    
    /// Manage thermal state changes
    func manageThermalState(_ state: ThermalState) {
        guard state != currentThermalState else { return }
        
        logger.info("Thermal state changed from \(currentThermalState.rawValue) to \(state.rawValue)")
        currentThermalState = state
        
        switch state {
        case .nominal, .fair:
            enableFullPerformance()
        case .serious:
            enableReducedPerformance()
        case .critical:
            enableMinimalPerformance()
        }
        
        // Update quality settings
        qualitySettings = configureQualitySettings(for: currentDeviceCapability)
        
        // Generate thermal-specific recommendations
        let thermalRecommendations = generateThermalRecommendations(for: state)
        performanceRecommendations.append(contentsOf: thermalRecommendations)
    }
    
    /// Preload filter previews for improved responsiveness
    func preloadFilters(_ filters: [BeautyFilter], for image: UIImage) async {
        logger.info("Preloading \(filters.count) filter previews")
        
        let preloadCount = min(filters.count, cachePolicy.preloadCount)
        let filtersToPreload = Array(filters.prefix(preloadCount))
        
        await withTaskGroup(of: Void.self) { group in
            for filter in filtersToPreload {
                group.addTask { [weak self] in
                    await self?.preloadFilterPreview(filter, for: image)
                }
            }
        }
        
        logger.info("Completed preloading \(preloadCount) filter previews")
    }
    
    /// Clear cache with specific type
    func clearCache(type: CacheType) {
        logger.info("Clearing cache type: \(type.rawValue)")
        
        switch type {
        case .filterPreview:
            previewCache.removeAllObjects()
        case .processedImage:
            processedImageCache.removeAllObjects()
        case .maskSegmentation:
            segmentationCache.removeAllObjects()
        case .faceDetection:
            faceDetectionCache.removeAllObjects()
        case .all:
            previewCache.removeAllObjects()
            processedImageCache.removeAllObjects()
            segmentationCache.removeAllObjects()
            faceDetectionCache.removeAllObjects()
        }
    }
    
    /// Get comprehensive performance report
    func getPerformanceMetrics() -> PerformanceReport {
        let cacheMetrics = CacheMetrics(
            hitRate: (previewCache.hitRate + processedImageCache.hitRate) / 2,
            missRate: (previewCache.missRate + processedImageCache.missRate) / 2,
            evictionCount: previewCache.evictionCount + processedImageCache.evictionCount,
            memoryFootprint: previewCache.currentMemoryUsage + processedImageCache.currentMemoryUsage,
            diskFootprint: 0 // Implement disk cache if needed
        )
        
        let averageMetrics = calculateAverageProcessingMetrics()
        
        return PerformanceReport(
            timestamp: Date(),
            deviceCapability: currentDeviceCapability,
            thermalState: currentThermalState,
            memoryUsage: memoryUsage,
            processingMetrics: averageMetrics,
            cacheMetrics: cacheMetrics,
            batteryImpact: calculateBatteryImpact(),
            recommendations: performanceRecommendations
        )
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: performanceQueue
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            Task {
                await self?.handleMemoryPressure()
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    private func setupThermalMonitoring() {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let thermalState = ProcessInfo.processInfo.thermalState
            self?.manageThermalState(ThermalState(thermalState))
        }
    }
    
    private func updatePerformanceMetrics() async {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let currentMemory = Int(memoryInfo.resident_size)
            let availableMemory = Int(ProcessInfo.processInfo.physicalMemory) - currentMemory
            
            await MainActor.run {
                self.memoryUsage = MemoryUsage(
                    current: currentMemory,
                    peak: max(self.memoryUsage.peak, currentMemory),
                    available: availableMemory,
                    pressure: self.assessMemoryPressure(currentMemory, available: availableMemory)
                )
            }
        }
    }
    
    private func handleMemoryPressure() async {
        logger.warning("Memory pressure detected, optimizing cache usage")
        
        // Aggressive cache cleanup
        let memoryBudget = currentDeviceCapability.maxMemoryBudget / 2
        
        await MainActor.run {
            if self.memoryUsage.current > memoryBudget {
                self.clearCache(type: .all)
                
                // Add memory optimization recommendation
                let recommendation = PerformanceRecommendation(
                    type: .memoryOptimization,
                    priority: .high,
                    description: "High memory usage detected",
                    impact: "Reduces memory footprint by 50-70%",
                    action: "Cleared all caches and reduced quality settings"
                )
                
                self.performanceRecommendations.append(recommendation)
                
                // Reduce quality settings temporarily
                self.qualitySettings = .draft
            }
        }
    }
    
    private func preloadFilterPreview(_ filter: BeautyFilter, for image: UIImage) async {
        let cacheKey = "\(filter.id)_preview_\(image.hashValue)"
        
        // Check if already cached
        if previewCache.object(forKey: cacheKey) != nil {
            return
        }
        
        do {
            let filterEngine = FilterProcessingEngine()
            let preview = try await filterEngine.generateFilterPreview(
                filter,
                for: image,
                size: CGSize(width: 200, height: 200)
            )
            
            previewCache.setObject(preview, forKey: cacheKey)
        } catch {
            logger.error("Failed to preload filter preview: \(error.localizedDescription)")
        }
    }
    
    private func optimizeCacheConfiguration() {
        let memoryBudget = currentDeviceCapability.maxMemoryBudget
        
        // Distribute memory budget across caches
        let previewBudget = Int(Float(memoryBudget) * 0.4)  // 40%
        let processedBudget = Int(Float(memoryBudget) * 0.4) // 40%
        let segmentationBudget = Int(Float(memoryBudget) * 0.2) // 20%
        
        previewCache.configure(
            memoryLimit: previewBudget,
            countLimit: previewBudget / (200 * 200 * 4), // Estimate based on preview size
            compressionEnabled: currentDeviceCapability == .low
        )
        
        processedImageCache.configure(
            memoryLimit: processedBudget,
            countLimit: processedBudget / (1000 * 1000 * 4), // Estimate based on full size
            compressionEnabled: currentDeviceCapability != .ultraHigh
        )
        
        segmentationCache.configure(
            memoryLimit: segmentationBudget,
            countLimit: segmentationBudget / (500 * 500 * 1), // Grayscale masks
            compressionEnabled: true
        )
    }
    
    private func enableFullPerformance() {
        preloadQueue.maxConcurrentOperationCount = currentDeviceCapability.maxConcurrentFilters
        backgroundQueue.maxConcurrentOperationCount = 4
        isOptimizationEnabled = false
    }
    
    private func enableReducedPerformance() {
        preloadQueue.maxConcurrentOperationCount = max(1, currentDeviceCapability.maxConcurrentFilters / 2)
        backgroundQueue.maxConcurrentOperationCount = 2
        isOptimizationEnabled = true
    }
    
    private func enableMinimalPerformance() {
        preloadQueue.maxConcurrentOperationCount = 1
        backgroundQueue.maxConcurrentOperationCount = 1
        isOptimizationEnabled = true
        
        // Aggressive cache cleanup
        clearCache(type: .all)
    }
    
    private func generatePerformanceRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // Memory-based recommendations
        if memoryUsage.pressure == .warning {
            recommendations.append(PerformanceRecommendation(
                type: .memoryOptimization,
                priority: .medium,
                description: "Memory usage is approaching limits",
                impact: "May cause app slowdown or crashes",
                action: "Consider reducing cache size or clearing unused filters"
            ))
        }
        
        // Cache performance recommendations
        let avgHitRate = (previewCache.hitRate + processedImageCache.hitRate) / 2
        if avgHitRate < 0.6 {
            recommendations.append(PerformanceRecommendation(
                type: .cacheAdjustment,
                priority: .low,
                description: "Cache hit rate is below optimal",
                impact: "Increases processing time and battery usage",
                action: "Increase cache size or improve preloading strategy"
            ))
        }
        
        // Device capability recommendations
        if currentDeviceCapability == .low {
            recommendations.append(PerformanceRecommendation(
                type: .qualityReduction,
                priority: .high,
                description: "Device has limited processing capability",
                impact: "May experience slow filter application",
                action: "Use lower quality settings and limit concurrent operations"
            ))
        }
        
        return recommendations
    }
    
    private func generateThermalRecommendations(for state: ThermalState) -> [PerformanceRecommendation] {
        switch state {
        case .serious:
            return [PerformanceRecommendation(
                type: .thermalThrottling,
                priority: .high,
                description: "Device is getting warm",
                impact: "Performance may be reduced",
                action: "Reduced processing quality and limited background operations"
            )]
            
        case .critical:
            return [PerformanceRecommendation(
                type: .thermalThrottling,
                priority: .critical,
                description: "Device is overheating",
                impact: "Severe performance reduction to prevent damage",
                action: "Minimal processing mode enabled, allow device to cool"
            )]
            
        default:
            return []
        }
    }
    
    private func assessMemoryPressure(_ current: Int, available: Int) -> MemoryUsage.MemoryPressure {
        let usageRatio = Float(current) / Float(current + available)
        
        if usageRatio > 0.9 {
            return .critical
        } else if usageRatio > 0.7 {
            return .warning
        } else {
            return .normal
        }
    }
    
    private func calculateAverageProcessingMetrics() -> ProcessingMetrics {
        let allMetrics = Array(processingMetrics.values)
        
        guard !allMetrics.isEmpty else {
            return ProcessingMetrics(
                processingTime: 0,
                memoryUsage: 0,
                cpuUsage: 0,
                gpuUsage: 0,
                batteryImpact: .minimal,
                thermalState: currentThermalState
            )
        }
        
        let avgProcessingTime = allMetrics.map(\.processingTime).reduce(0, +) / TimeInterval(allMetrics.count)
        let avgMemoryUsage = allMetrics.map(\.memoryUsage).reduce(0, +) / allMetrics.count
        let avgCpuUsage = allMetrics.map(\.cpuUsage).reduce(0, +) / Float(allMetrics.count)
        let avgGpuUsage = allMetrics.map(\.gpuUsage).reduce(0, +) / Float(allMetrics.count)
        
        return ProcessingMetrics(
            processingTime: avgProcessingTime,
            memoryUsage: avgMemoryUsage,
            cpuUsage: avgCpuUsage,
            gpuUsage: avgGpuUsage,
            batteryImpact: calculateBatteryImpact(),
            thermalState: currentThermalState
        )
    }
    
    private func calculateBatteryImpact() -> BatteryImpact {
        // Estimate based on thermal state and processing intensity
        switch currentThermalState {
        case .nominal:
            return qualitySettings == .ultra ? .moderate : .low
        case .fair:
            return .moderate
        case .serious:
            return .high
        case .critical:
            return .severe
        }
    }
    
    // MARK: - Static Methods
    
    static func detectDeviceInfo() -> DeviceInfo {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        
        let physicalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        
        return DeviceInfo(
            model: machine,
            osVersion: UIDevice.current.systemVersion,
            hasMetalSupport: MTLCreateSystemDefaultDevice() != nil,
            hasCoreMLSupport: true, // Assume true for iOS 11+
            memoryCapacity: physicalMemory
        )
    }
    
    static func assessDeviceCapability(_ deviceInfo: DeviceInfo) -> DeviceCapability {
        // Simple capability assessment based on memory and model
        let memoryGB = deviceInfo.memoryCapacity / 1_000_000_000
        
        if memoryGB >= 8 && deviceInfo.model.contains("iPhone15") {
            return .ultraHigh
        } else if memoryGB >= 6 || deviceInfo.model.contains("Pro") {
            return .high
        } else if memoryGB >= 4 {
            return .medium
        } else {
            return .low
        }
    }
    
    static func createCacheConfiguration(for capability: DeviceCapability) -> (
        preview: ImageCacheConfiguration,
        processed: ImageCacheConfiguration,
        segmentation: ImageCacheConfiguration
    ) {
        let memoryBudget = capability.maxMemoryBudget
        
        return (
            preview: ImageCacheConfiguration(
                memoryLimit: Int(Float(memoryBudget) * 0.3),
                diskLimit: 0,
                compressionEnabled: capability == .low
            ),
            processed: ImageCacheConfiguration(
                memoryLimit: Int(Float(memoryBudget) * 0.5),
                diskLimit: 0,
                compressionEnabled: capability != .ultraHigh
            ),
            segmentation: ImageCacheConfiguration(
                memoryLimit: Int(Float(memoryBudget) * 0.2),
                diskLimit: 0,
                compressionEnabled: true
            )
        )
    }
    
    static func createCachePolicy(for capability: DeviceCapability) -> CachePolicy {
        return CachePolicy(
            maxMemoryUsage: capability.maxMemoryBudget,
            maxDiskUsage: 0, // Memory-only for now
            timeToLive: 3600, // 1 hour
            compressionEnabled: capability != .ultraHigh,
            preloadCount: capability.maxConcurrentFilters * 2,
            evictionStrategy: .adaptive
        )
    }
}

// MARK: - Supporting Types

struct ImageCacheConfiguration {
    let memoryLimit: Int
    let diskLimit: Int
    let compressionEnabled: Bool
}

extension ThermalState {
    init(_ processInfoThermalState: ProcessInfo.ThermalState) {
        switch processInfoThermalState {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .nominal
        }
    }
}

// MARK: - Advanced Image Cache

final class AdvancedImageCache {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let accessQueue = DispatchQueue(label: "com.glowly.cache.access", attributes: .concurrent)
    
    // Metrics
    private var hitCount: Int = 0
    private var missCount: Int = 0
    private var _evictionCount: Int = 0
    
    var hitRate: Float {
        let total = hitCount + missCount
        return total > 0 ? Float(hitCount) / Float(total) : 0
    }
    
    var missRate: Float {
        let total = hitCount + missCount
        return total > 0 ? Float(missCount) / Float(total) : 0
    }
    
    var evictionCount: Int { _evictionCount }
    
    var currentMemoryUsage: Int {
        return memoryCache.totalCostLimit
    }
    
    init(config: ImageCacheConfiguration) {
        configure(
            memoryLimit: config.memoryLimit,
            countLimit: config.memoryLimit / (200 * 200 * 4), // Estimate
            compressionEnabled: config.compressionEnabled
        )
    }
    
    func configure(memoryLimit: Int, countLimit: Int, compressionEnabled: Bool) {
        memoryCache.totalCostLimit = memoryLimit
        memoryCache.countLimit = countLimit
        
        memoryCache.delegate = CacheDelegate { [weak self] in
            self?._evictionCount += 1
        }
    }
    
    func object(forKey key: String) -> UIImage? {
        return accessQueue.sync {
            if let image = memoryCache.object(forKey: key as NSString) {
                hitCount += 1
                return image
            } else {
                missCount += 1
                return nil
            }
        }
    }
    
    func setObject(_ object: UIImage, forKey key: String) {
        accessQueue.async(flags: .barrier) { [weak self] in
            let cost = self?.estimateImageCost(object) ?? 0
            self?.memoryCache.setObject(object, forKey: key as NSString, cost: cost)
        }
    }
    
    func removeAllObjects() {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAllObjects()
        }
    }
    
    private func estimateImageCost(_ image: UIImage) -> Int {
        let size = image.size
        let scale = image.scale
        return Int(size.width * scale * size.height * scale * 4) // RGBA
    }
}

private class CacheDelegate: NSObject, NSCacheDelegate {
    private let onEviction: () -> Void
    
    init(onEviction: @escaping () -> Void) {
        self.onEviction = onEviction
        super.init()
    }
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: AnyObject) {
        onEviction()
    }
}