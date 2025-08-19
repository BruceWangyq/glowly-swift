//
//  AdvancedExportManager.swift
//  Glowly
//
//  Advanced export manager with multiple quality settings, batch export, and enhancement history
//

import Foundation
import UIKit
import AVFoundation
import ImageIO
import CoreImage
import VideoToolbox

// MARK: - Advanced Export Manager

@MainActor
class AdvancedExportManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var lastExportResult: ExportResult?
    @Published var exportHistory: [ExportResult] = []
    
    // MARK: - Private Properties
    
    private let imageProcessor = ImageProcessor()
    private let watermarkRenderer = WatermarkRenderer()
    private let metadataProcessor = MetadataProcessor()
    
    // MARK: - Public Methods
    
    /// Export a single photo with advanced options
    func exportPhoto(
        _ photo: GlowlyPhoto,
        configuration: ExportConfiguration,
        progressCallback: @escaping (Double) async -> Void = { _ in }
    ) async throws -> ExportResult {
        
        isExporting = true
        exportProgress = 0.0
        currentOperation = "Preparing export..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentOperation = ""
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Step 1: Validate input
            await progressCallback(0.1)
            currentOperation = "Validating photo..."
            
            guard let imageData = photo.enhancedImage ?? photo.originalImage else {
                throw ExportError.noImageData
            }
            
            guard let originalImage = UIImage(data: imageData) else {
                throw ExportError.invalidImageData
            }
            
            // Step 2: Process image for export
            await progressCallback(0.3)
            currentOperation = "Processing image..."
            
            let processedImage = try await processImageForExport(
                originalImage,
                configuration: configuration,
                photo: photo
            )
            
            // Step 3: Apply watermark if needed
            await progressCallback(0.6)
            currentOperation = "Applying watermark..."
            
            let finalImage = try await applyWatermarkIfNeeded(
                processedImage,
                configuration: configuration,
                photo: photo
            )
            
            // Step 4: Generate final file
            await progressCallback(0.8)
            currentOperation = "Generating file..."
            
            let fileURL = try await generateFinalFile(
                finalImage,
                configuration: configuration,
                photo: photo
            )
            
            // Step 5: Add metadata
            await progressCallback(0.9)
            currentOperation = "Adding metadata..."
            
            try await addMetadataToFile(
                fileURL,
                configuration: configuration,
                photo: photo
            )
            
            // Step 6: Create result
            await progressCallback(1.0)
            currentOperation = "Finalizing..."
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
            
            let result = ExportResult(
                success: true,
                fileURL: fileURL,
                fileSize: fileSize,
                dimensions: finalImage.size,
                format: configuration.format,
                quality: configuration.quality,
                processingTime: processingTime
            )
            
            lastExportResult = result
            exportHistory.append(result)
            
            return result
            
        } catch {
            let result = ExportResult(
                success: false,
                format: configuration.format,
                quality: configuration.quality,
                processingTime: CFAbsoluteTimeGetCurrent() - startTime,
                error: error.localizedDescription
            )
            
            lastExportResult = result
            throw error
        }
    }
    
    /// Export multiple photos as a batch
    func exportBatch(
        _ configuration: BatchExportConfiguration,
        progressCallback: @escaping (Double) async -> Void = { _ in }
    ) async throws -> BatchExportResult {
        
        isExporting = true
        exportProgress = 0.0
        currentOperation = "Starting batch export..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentOperation = ""
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [ExportResult] = []
        let totalPhotos = configuration.photos.count
        var totalFileSize: Int64 = 0
        
        for (index, photo) in configuration.photos.enumerated() {
            let baseProgress = Double(index) / Double(totalPhotos)
            let stepProgress = 1.0 / Double(totalPhotos)
            
            currentOperation = "Exporting photo \(index + 1) of \(totalPhotos)..."
            
            do {
                let result = try await exportPhoto(
                    photo,
                    configuration: configuration.baseConfiguration
                ) { photoProgress in
                    let overallProgress = baseProgress + (photoProgress * stepProgress)
                    await progressCallback(overallProgress)
                    await MainActor.run {
                        self.exportProgress = overallProgress
                    }
                }
                
                results.append(result)
                totalFileSize += result.fileSize
                
            } catch {
                let failedResult = ExportResult(
                    success: false,
                    format: configuration.baseConfiguration.format,
                    quality: configuration.baseConfiguration.quality,
                    error: error.localizedDescription
                )
                results.append(failedResult)
            }
        }
        
        let totalProcessingTime = CFAbsoluteTimeGetCurrent() - startTime
        let successfulExports = results.filter { $0.success }.count
        
        return BatchExportResult(
            totalPhotos: totalPhotos,
            successfulExports: successfulExports,
            failedExports: totalPhotos - successfulExports,
            results: results,
            totalProcessingTime: totalProcessingTime,
            totalFileSize: totalFileSize
        )
    }
    
    /// Create before/after collage
    func createBeforeAfterCollage(
        originalPhoto: GlowlyPhoto,
        enhancedPhoto: GlowlyPhoto,
        template: BeforeAfterTemplate,
        configuration: ExportConfiguration
    ) async throws -> ExportResult {
        
        isExporting = true
        exportProgress = 0.0
        currentOperation = "Creating before/after collage..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentOperation = ""
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Get images
            guard let originalImage = originalPhoto.originalUIImage,
                  let enhancedImage = enhancedPhoto.enhancedUIImage ?? enhancedPhoto.originalUIImage else {
                throw ExportError.invalidImageData
            }
            
            exportProgress = 0.2
            
            // Create collage
            let collageImage = try await createCollageImage(
                original: originalImage,
                enhanced: enhancedImage,
                template: template,
                targetSize: configuration.targetDimensions ?? CGSize(width: 1080, height: 1080)
            )
            
            exportProgress = 0.6
            
            // Apply watermark if needed
            let finalImage = try await applyWatermarkIfNeeded(
                collageImage,
                configuration: configuration,
                photo: enhancedPhoto
            )
            
            exportProgress = 0.8
            
            // Generate file
            let fileURL = try await generateFinalFile(
                finalImage,
                configuration: configuration,
                photo: enhancedPhoto
            )
            
            exportProgress = 1.0
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
            
            let result = ExportResult(
                success: true,
                fileURL: fileURL,
                fileSize: fileSize,
                dimensions: finalImage.size,
                format: configuration.format,
                quality: configuration.quality,
                processingTime: processingTime
            )
            
            lastExportResult = result
            return result
            
        } catch {
            let result = ExportResult(
                success: false,
                format: configuration.format,
                quality: configuration.quality,
                processingTime: CFAbsoluteTimeGetCurrent() - startTime,
                error: error.localizedDescription
            )
            
            lastExportResult = result
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func processImageForExport(
        _ image: UIImage,
        configuration: ExportConfiguration,
        photo: GlowlyPhoto
    ) async throws -> UIImage {
        
        var processedImage = image
        
        // Resize if needed
        if let targetDimensions = configuration.targetDimensions {
            processedImage = try await imageProcessor.resize(
                image: processedImage,
                to: targetDimensions,
                quality: configuration.quality
            )
        } else if let maxDimension = configuration.quality.maxDimension {
            processedImage = try await imageProcessor.resizeToMaxDimension(
                image: processedImage,
                maxDimension: maxDimension
            )
        }
        
        // Apply format-specific optimizations
        processedImage = try await imageProcessor.optimizeForFormat(
            image: processedImage,
            format: configuration.format,
            quality: configuration.quality
        )
        
        return processedImage
    }
    
    private func applyWatermarkIfNeeded(
        _ image: UIImage,
        configuration: ExportConfiguration,
        photo: GlowlyPhoto
    ) async throws -> UIImage {
        
        guard configuration.watermark.enabled else {
            return image
        }
        
        return try await watermarkRenderer.addWatermark(
            to: image,
            options: configuration.watermark,
            photo: photo
        )
    }
    
    private func generateFinalFile(
        _ image: UIImage,
        configuration: ExportConfiguration,
        photo: GlowlyPhoto
    ) async throws -> URL {
        
        let fileName = "glowly_\(photo.id.uuidString).\(configuration.format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let imageData: Data
        
        switch configuration.format {
        case .jpeg:
            guard let data = image.jpegData(compressionQuality: configuration.quality.compressionQuality) else {
                throw ExportError.imageEncodingFailed
            }
            imageData = data
            
        case .png:
            guard let data = image.pngData() else {
                throw ExportError.imageEncodingFailed
            }
            imageData = data
            
        case .heic:
            imageData = try await convertToHEIC(image, quality: configuration.quality.compressionQuality)
        }
        
        try imageData.write(to: tempURL)
        return tempURL
    }
    
    private func convertToHEIC(_ image: UIImage, quality: CGFloat) async throws -> Data {
        guard let cgImage = image.cgImage else {
            throw ExportError.imageEncodingFailed
        }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, AVFileType.heic as CFString, 1, nil) else {
            throw ExportError.imageEncodingFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.imageEncodingFailed
        }
        
        return data as Data
    }
    
    private func addMetadataToFile(
        _ fileURL: URL,
        configuration: ExportConfiguration,
        photo: GlowlyPhoto
    ) async throws {
        
        guard configuration.preserveMetadata || configuration.includeEnhancementHistory else {
            return
        }
        
        try await metadataProcessor.addMetadata(
            to: fileURL,
            photo: photo,
            includeEnhancementHistory: configuration.includeEnhancementHistory
        )
    }
    
    private func createCollageImage(
        original: UIImage,
        enhanced: UIImage,
        template: BeforeAfterTemplate,
        targetSize: CGSize
    ) async throws -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            switch template {
            case .sideBySide:
                drawSideBySideCollage(
                    original: original,
                    enhanced: enhanced,
                    size: targetSize,
                    context: cgContext
                )
                
            case .topBottom:
                drawTopBottomCollage(
                    original: original,
                    enhanced: enhanced,
                    size: targetSize,
                    context: cgContext
                )
                
            case .overlaySlider:
                drawOverlaySliderCollage(
                    original: original,
                    enhanced: enhanced,
                    size: targetSize,
                    context: cgContext
                )
                
            case .splitDiagonal:
                drawDiagonalSplitCollage(
                    original: original,
                    enhanced: enhanced,
                    size: targetSize,
                    context: cgContext
                )
            }
            
            // Add labels
            addBeforeAfterLabels(context: context, size: targetSize, template: template)
        }
    }
    
    // MARK: - Collage Drawing Methods
    
    private func drawSideBySideCollage(
        original: UIImage,
        enhanced: UIImage,
        size: CGSize,
        context: CGContext
    ) {
        let dividerWidth: CGFloat = 2
        let leftRect = CGRect(x: 0, y: 0, width: (size.width - dividerWidth) / 2, height: size.height)
        let rightRect = CGRect(x: (size.width + dividerWidth) / 2, y: 0, width: (size.width - dividerWidth) / 2, height: size.height)
        
        original.draw(in: leftRect)
        enhanced.draw(in: rightRect)
        
        // Draw divider
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: leftRect.maxX, y: 0, width: dividerWidth, height: size.height))
    }
    
    private func drawTopBottomCollage(
        original: UIImage,
        enhanced: UIImage,
        size: CGSize,
        context: CGContext
    ) {
        let dividerHeight: CGFloat = 2
        let topRect = CGRect(x: 0, y: 0, width: size.width, height: (size.height - dividerHeight) / 2)
        let bottomRect = CGRect(x: 0, y: (size.height + dividerHeight) / 2, width: size.width, height: (size.height - dividerHeight) / 2)
        
        original.draw(in: topRect)
        enhanced.draw(in: bottomRect)
        
        // Draw divider
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: topRect.maxY, width: size.width, height: dividerHeight))
    }
    
    private func drawOverlaySliderCollage(
        original: UIImage,
        enhanced: UIImage,
        size: CGSize,
        context: CGContext
    ) {
        let fullRect = CGRect(origin: .zero, size: size)
        
        // Draw original as background
        original.draw(in: fullRect)
        
        // Draw enhanced portion with mask
        let sliderPosition: CGFloat = 0.6
        let maskWidth = size.width * sliderPosition
        let maskRect = CGRect(x: 0, y: 0, width: maskWidth, height: size.height)
        
        context.saveGState()
        context.clip(to: maskRect)
        enhanced.draw(in: fullRect)
        context.restoreGState()
        
        // Draw slider line
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(4)
        context.move(to: CGPoint(x: maskWidth, y: 0))
        context.addLine(to: CGPoint(x: maskWidth, y: size.height))
        context.strokePath()
        
        // Draw slider handle
        let handleSize: CGFloat = 40
        let handleY = size.height / 2
        let handleRect = CGRect(
            x: maskWidth - handleSize / 2,
            y: handleY - handleSize / 2,
            width: handleSize,
            height: handleSize
        )
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: handleRect)
        
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: handleRect)
    }
    
    private func drawDiagonalSplitCollage(
        original: UIImage,
        enhanced: UIImage,
        size: CGSize,
        context: CGContext
    ) {
        let fullRect = CGRect(origin: .zero, size: size)
        
        // Draw original as background
        original.draw(in: fullRect)
        
        // Create diagonal mask
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height * 0.3))
        path.close()
        
        context.saveGState()
        context.addPath(path.cgPath)
        context.clip()
        enhanced.draw(in: fullRect)
        context.restoreGState()
        
        // Draw diagonal divider
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3)
        context.move(to: CGPoint(x: 0, y: size.height * 0.3))
        context.addLine(to: CGPoint(x: size.width * 0.7, y: size.height))
        context.strokePath()
    }
    
    private func addBeforeAfterLabels(context: UIGraphicsImageRendererContext, size: CGSize, template: BeforeAfterTemplate) {
        let beforeText = "BEFORE"
        let afterText = "AFTER"
        
        let font = UIFont.systemFont(ofSize: 18, weight: .bold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        let beforeString = NSAttributedString(string: beforeText, attributes: textAttributes)
        let afterString = NSAttributedString(string: afterText, attributes: textAttributes)
        
        let beforeSize = beforeString.size()
        let afterSize = afterString.size()
        let padding: CGFloat = 20
        
        switch template {
        case .sideBySide:
            let beforeRect = CGRect(
                x: (size.width / 4) - (beforeSize.width / 2),
                y: padding,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: (3 * size.width / 4) - (afterSize.width / 2),
                y: padding,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
            
        case .topBottom:
            let beforeRect = CGRect(
                x: (size.width / 2) - (beforeSize.width / 2),
                y: padding,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: (size.width / 2) - (afterSize.width / 2),
                y: (size.height / 2) + padding,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
            
        case .overlaySlider:
            let beforeRect = CGRect(
                x: size.width * 0.75,
                y: padding,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: padding,
                y: padding,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
            
        case .splitDiagonal:
            let beforeRect = CGRect(
                x: size.width * 0.1,
                y: size.height * 0.8,
                width: beforeSize.width,
                height: beforeSize.height
            )
            let afterRect = CGRect(
                x: size.width * 0.7,
                y: padding,
                width: afterSize.width,
                height: afterSize.height
            )
            
            beforeString.draw(in: beforeRect)
            afterString.draw(in: afterRect)
        }
    }
}

// MARK: - Supporting Classes

class ImageProcessor {
    
    func resize(image: UIImage, to targetSize: CGSize, quality: ExportQuality) async throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func resizeToMaxDimension(image: UIImage, maxDimension: CGFloat) async throws -> UIImage {
        let currentSize = image.size
        let aspectRatio = currentSize.width / currentSize.height
        
        let targetSize: CGSize
        if currentSize.width > currentSize.height {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        return try await resize(image: image, to: targetSize, quality: .high)
    }
    
    func optimizeForFormat(image: UIImage, format: ExportFormat, quality: ExportQuality) async throws -> UIImage {
        // Format-specific optimizations
        switch format {
        case .jpeg:
            // Ensure no transparency for JPEG
            return try await removeTransparency(image)
        case .png, .heic:
            // Preserve transparency
            return image
        }
    }
    
    private func removeTransparency(_ image: UIImage) async throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size, format: UIGraphicsImageRendererFormat())
        return renderer.image { context in
            // Fill with white background
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: image.size))
            
            // Draw image on top
            image.draw(at: .zero)
        }
    }
}

class WatermarkRenderer {
    
    func addWatermark(to image: UIImage, options: WatermarkOptions, photo: GlowlyPhoto) async throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Draw watermark
            drawWatermark(
                context: context,
                size: image.size,
                options: options,
                photo: photo
            )
        }
    }
    
    private func drawWatermark(context: UIGraphicsImageRendererContext, size: CGSize, options: WatermarkOptions, photo: GlowlyPhoto) {
        let cgContext = context.cgContext
        let font = UIFont.systemFont(ofSize: options.size.fontSize, weight: .medium)
        
        var textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(options.opacity)
        ]
        
        // Apply style
        switch options.style {
        case .bold:
            textAttributes[.font] = UIFont.systemFont(ofSize: options.size.fontSize, weight: .bold)
            
        case .outlined:
            textAttributes[.strokeColor] = UIColor.black.withAlphaComponent(options.opacity)
            textAttributes[.strokeWidth] = -2.0
            
        case .shadowed:
            // Add shadow effect
            cgContext.setShadow(offset: CGSize(width: 2, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            
        case .subtle:
            textAttributes[.foregroundColor] = UIColor.white.withAlphaComponent(options.opacity * 0.7)
        }
        
        let attributedString = NSAttributedString(string: options.text, attributes: textAttributes)
        let textSize = attributedString.size()
        let position = options.position.calculatePosition(in: size, textSize: textSize)
        
        // Draw background if needed
        if options.style != .subtle {
            let backgroundRect = CGRect(
                x: position.x - 8,
                y: position.y - 4,
                width: textSize.width + 16,
                height: textSize.height + 8
            )
            
            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            cgContext.fill(backgroundRect.insetBy(dx: -4, dy: -2))
        }
        
        // Draw text
        attributedString.draw(at: position)
    }
}

class MetadataProcessor {
    
    func addMetadata(to fileURL: URL, photo: GlowlyPhoto, includeEnhancementHistory: Bool) async throws {
        // Read existing image data
        guard let imageData = try? Data(contentsOf: fileURL) else {
            throw ExportError.metadataProcessingFailed
        }
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw ExportError.metadataProcessingFailed
        }
        
        // Get existing metadata
        var metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]
        
        // Add Glowly metadata
        var glowlyMetadata: [String: Any] = [:]
        glowlyMetadata["version"] = "1.0"
        glowlyMetadata["photoId"] = photo.id.uuidString
        glowlyMetadata["createdAt"] = ISO8601DateFormatter().string(from: photo.createdAt)
        glowlyMetadata["isEnhanced"] = photo.isEnhanced
        
        if includeEnhancementHistory && !photo.enhancementHistory.isEmpty {
            let enhancementData = photo.enhancementHistory.map { enhancement in
                [
                    "type": enhancement.type.rawValue,
                    "intensity": enhancement.intensity,
                    "appliedAt": ISO8601DateFormatter().string(from: enhancement.appliedAt)
                ]
            }
            glowlyMetadata["enhancements"] = enhancementData
        }
        
        metadata["Glowly"] = glowlyMetadata
        
        // Create new image with metadata
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil) else {
            throw ExportError.metadataProcessingFailed
        }
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ExportError.metadataProcessingFailed
        }
        
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.metadataProcessingFailed
        }
        
        // Write back to file
        try mutableData.write(to: fileURL)
    }
}

// MARK: - Supporting Enums

enum BeforeAfterTemplate: String, CaseIterable, Codable {
    case sideBySide = "side_by_side"
    case topBottom = "top_bottom"
    case overlaySlider = "overlay_slider"
    case splitDiagonal = "split_diagonal"
    
    var displayName: String {
        switch self {
        case .sideBySide:
            return "Side by Side"
        case .topBottom:
            return "Top & Bottom"
        case .overlaySlider:
            return "Overlay Slider"
        case .splitDiagonal:
            return "Diagonal Split"
        }
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case noImageData
    case invalidImageData
    case imageEncodingFailed
    case metadataProcessingFailed
    case fileWriteFailed
    case unsupportedFormat
    case resizeOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .noImageData:
            return "No image data available for export"
        case .invalidImageData:
            return "Invalid image data format"
        case .imageEncodingFailed:
            return "Failed to encode image in requested format"
        case .metadataProcessingFailed:
            return "Failed to process image metadata"
        case .fileWriteFailed:
            return "Failed to write exported file"
        case .unsupportedFormat:
            return "Unsupported export format"
        case .resizeOperationFailed:
            return "Failed to resize image"
        }
    }
}