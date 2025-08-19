//
//  ExportOptionsView.swift
//  Glowly
//
//  Export options and functionality for before/after comparisons
//

import SwiftUI
import Photos
import Social

// MARK: - ExportOptionsView
struct ExportOptionsView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let comparisonState: ComparisonState
    let exportManager: ExportManager
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFormat: ExportOptions.ExportFormat = .collage
    @State private var selectedTemplate: ComparisonTemplate = ComparisonTemplate.defaultTemplates[0]
    @State private var selectedPlatform: ExportOptions.SocialPlatform? = nil
    @State private var includeWatermark = true
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var showingShareSheet = false
    @State private var exportedImageURL: URL?
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Section
                    previewSection
                    
                    // Format Selection
                    formatSelectionSection
                    
                    // Template Selection (for applicable formats)
                    if selectedFormat == .collage || selectedFormat == .splitImage {
                        templateSelectionSection
                    }
                    
                    // Social Platform Optimization
                    socialPlatformSection
                    
                    // Options
                    optionsSection
                    
                    // Export Button
                    exportButtonSection
                }
                .padding()
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    exportProgressOverlay
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedImageURL {
                    ActivityViewController(activityItems: [url])
                }
            }
            .alert("Export Successful", isPresented: $showingSuccessAlert) {
                Button("Share") {
                    showingShareSheet = true
                }
                Button("Save to Photos") {
                    saveToPhotos()
                }
                Button("OK") {}
            } message: {
                Text("Your before/after comparison has been exported successfully.")
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            
            GlowlyCard {
                AsyncImage(url: URL(string: "preview")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    // Live preview of the export
                    ExportPreviewView(
                        originalImage: originalImage,
                        processedImage: processedImage,
                        template: selectedTemplate,
                        format: selectedFormat,
                        state: comparisonState
                    )
                }
                .frame(height: 200)
                .background(Color.black)
                .cornerRadius(GlowlyTheme.CornerRadius.card)
            }
        }
    }
    
    // MARK: - Format Selection
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ExportOptions.ExportFormat.allCases, id: \.self) { format in
                    FormatCard(
                        format: format,
                        isSelected: selectedFormat == format,
                        onSelect: {
                            selectedFormat = format
                            HapticFeedback.selection()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Template Selection
    
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Template")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComparisonTemplate.defaultTemplates, id: \.id) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate.id == template.id,
                            onSelect: {
                                selectedTemplate = template
                                HapticFeedback.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Social Platform Section
    
    private var socialPlatformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimize for Platform")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            
            Text("Choose a platform to automatically optimize dimensions and format")
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // None option
                    PlatformCard(
                        platform: nil,
                        isSelected: selectedPlatform == nil,
                        onSelect: {
                            selectedPlatform = nil
                            HapticFeedback.selection()
                        }
                    )
                    
                    ForEach(ExportOptions.SocialPlatform.allCases, id: \.self) { platform in
                        PlatformCard(
                            platform: platform,
                            isSelected: selectedPlatform == platform,
                            onSelect: {
                                selectedPlatform = platform
                                HapticFeedback.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            
            GlowlyCard {
                VStack(spacing: 16) {
                    // Watermark toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include Watermark")
                                .font(GlowlyTheme.Typography.bodyFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            
                            Text("Add Glowly branding to your export")
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $includeWatermark)
                            .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    }
                    
                    Divider()
                    
                    // Quality selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality")
                            .font(GlowlyTheme.Typography.bodyFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        Picker("Quality", selection: .constant(ImageQuality.high)) {
                            Text("High").tag(ImageQuality.high)
                            Text("Medium").tag(ImageQuality.medium)
                            Text("Low").tag(ImageQuality.low)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Export Button
    
    private var exportButtonSection: some View {
        VStack(spacing: 12) {
            GlowlyButton(
                title: "Export \(selectedFormat.rawValue)",
                action: {
                    exportComparison()
                },
                style: .primary,
                isLoading: isExporting,
                icon: selectedFormat.icon
            )
            .disabled(isExporting || originalImage == nil || processedImage == nil)
            
            if isExporting {
                ProgressView(value: exportProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: GlowlyTheme.Colors.adaptivePrimary(colorScheme)))
                
                Text("Exporting... \(Int(exportProgress * 100))%")
                    .font(GlowlyTheme.Typography.captionFont)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
        }
    }
    
    // MARK: - Export Progress Overlay
    
    private var exportProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Creating your comparison...")
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(.white)
                
                ProgressView(value: exportProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .blur(radius: 10)
            )
        }
    }
    
    // MARK: - Actions
    
    private func exportComparison() {
        guard let originalImage = originalImage,
              let processedImage = processedImage else { return }
        
        isExporting = true
        exportProgress = 0.0
        
        Task {
            do {
                let exportedURL = try await exportManager.exportComparison(
                    original: originalImage,
                    processed: processedImage,
                    format: selectedFormat,
                    template: selectedTemplate,
                    platform: selectedPlatform,
                    includeWatermark: includeWatermark,
                    state: comparisonState
                ) { progress in
                    await MainActor.run {
                        exportProgress = progress
                    }
                }
                
                await MainActor.run {
                    exportedImageURL = exportedURL
                    isExporting = false
                    showingSuccessAlert = true
                    HapticFeedback.success()
                }
                
            } catch {
                await MainActor.run {
                    isExporting = false
                    // Handle error
                    HapticFeedback.error()
                }
            }
        }
    }
    
    private func saveToPhotos() {
        guard let url = exportedImageURL else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        HapticFeedback.success()
                    } else {
                        HapticFeedback.error()
                    }
                }
            }
        }
    }
}

// MARK: - Format Card
struct FormatCard: View {
    let format: ExportOptions.ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                
                Text(format.rawValue)
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .stroke(
                        isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveBorder(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: ComparisonTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 60)
                    .overlay(
                        templatePreview
                    )
                
                Text(template.name)
                    .font(GlowlyTheme.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .stroke(
                        isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveBorder(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var templatePreview: some View {
        // Simplified template preview
        switch template.layout {
        case .sideBySide:
            HStack(spacing: 1) {
                Rectangle().fill(Color.blue.opacity(0.5))
                Rectangle().fill(Color.green.opacity(0.5))
            }
        case .topBottom:
            VStack(spacing: 1) {
                Rectangle().fill(Color.blue.opacity(0.5))
                Rectangle().fill(Color.green.opacity(0.5))
            }
        case .beforeAfterSlider:
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.5))
                Rectangle().fill(Color.green.opacity(0.5))
                    .mask(
                        Rectangle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(width: 40)
                    )
            }
        default:
            Rectangle().fill(Color.gray.opacity(0.3))
        }
    }
}

// MARK: - Platform Card
struct PlatformCard: View {
    let platform: ExportOptions.SocialPlatform?
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: platform?.icon ?? "rectangle.dashed")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                
                Text(platform?.rawValue ?? "Original")
                    .font(GlowlyTheme.Typography.caption2Font)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                if let platform = platform {
                    Text("\(Int(platform.aspectRatio.width)):\(Int(platform.aspectRatio.height))")
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .stroke(
                        isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveBorder(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Export Preview View
struct ExportPreviewView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let template: ComparisonTemplate
    let format: ExportOptions.ExportFormat
    let state: ComparisonState
    
    var body: some View {
        // Simplified preview of how the export will look
        switch template.layout {
        case .sideBySide:
            HStack(spacing: 2) {
                if let originalImage = originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                
                if let processedImage = processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
        case .topBottom:
            VStack(spacing: 2) {
                if let originalImage = originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: .infinity)
                        .clipped()
                }
                
                if let processedImage = processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: .infinity)
                        .clipped()
                }
            }
        default:
            Rectangle()
                .fill(Color.gray.opacity(0.3))
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Manager
@MainActor
class ExportManager: ObservableObject {
    
    func exportComparison(
        original: UIImage,
        processed: UIImage,
        format: ExportOptions.ExportFormat,
        template: ComparisonTemplate,
        platform: ExportOptions.SocialPlatform?,
        includeWatermark: Bool,
        state: ComparisonState,
        progressCallback: @escaping (Double) async -> Void
    ) async throws -> URL {
        
        await progressCallback(0.1)
        
        // Determine target size based on platform
        let targetSize = platform?.aspectRatio ?? CGSize(width: 1080, height: 1080)
        
        await progressCallback(0.3)
        
        switch format {
        case .collage, .splitImage:
            return try await createStaticExport(
                original: original,
                processed: processed,
                template: template,
                targetSize: targetSize,
                includeWatermark: includeWatermark,
                state: state,
                progressCallback: progressCallback
            )
            
        case .animatedGIF:
            return try await createAnimatedGIF(
                original: original,
                processed: processed,
                targetSize: targetSize,
                progressCallback: progressCallback
            )
            
        case .video:
            return try await createVideo(
                original: original,
                processed: processed,
                targetSize: targetSize,
                progressCallback: progressCallback
            )
        }
    }
    
    private func createStaticExport(
        original: UIImage,
        processed: UIImage,
        template: ComparisonTemplate,
        targetSize: CGSize,
        includeWatermark: Bool,
        state: ComparisonState,
        progressCallback: @escaping (Double) async -> Void
    ) async throws -> URL {
        
        await progressCallback(0.5)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { context in
            // Render the comparison based on template
            renderComparison(
                original: original,
                processed: processed,
                template: template,
                state: state,
                targetSize: targetSize,
                context: context
            )
            
            if includeWatermark {
                renderWatermark(context: context, size: targetSize)
            }
        }
        
        await progressCallback(0.9)
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        if let data = image.jpegData(compressionQuality: 0.9) {
            try data.write(to: tempURL)
        }
        
        await progressCallback(1.0)
        
        return tempURL
    }
    
    private func createAnimatedGIF(
        original: UIImage,
        processed: UIImage,
        targetSize: CGSize,
        progressCallback: @escaping (Double) async -> Void
    ) async throws -> URL {
        
        // Implementation for GIF creation
        await progressCallback(1.0)
        
        // Placeholder - would implement actual GIF creation
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")
        
        return tempURL
    }
    
    private func createVideo(
        original: UIImage,
        processed: UIImage,
        targetSize: CGSize,
        progressCallback: @escaping (Double) async -> Void
    ) async throws -> URL {
        
        // Implementation for video creation
        await progressCallback(1.0)
        
        // Placeholder - would implement actual video creation
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        return tempURL
    }
    
    private func renderComparison(
        original: UIImage,
        processed: UIImage,
        template: ComparisonTemplate,
        state: ComparisonState,
        targetSize: CGSize,
        context: UIGraphicsImageRendererContext
    ) {
        let cgContext = context.cgContext
        
        switch template.layout {
        case .sideBySide:
            let leftRect = CGRect(x: 0, y: 0, width: targetSize.width / 2, height: targetSize.height)
            let rightRect = CGRect(x: targetSize.width / 2, y: 0, width: targetSize.width / 2, height: targetSize.height)
            
            original.draw(in: leftRect)
            processed.draw(in: rightRect)
            
        case .topBottom:
            let topRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height / 2)
            let bottomRect = CGRect(x: 0, y: targetSize.height / 2, width: targetSize.width, height: targetSize.height / 2)
            
            original.draw(in: topRect)
            processed.draw(in: bottomRect)
            
        case .beforeAfterSlider:
            let fullRect = CGRect(origin: .zero, size: targetSize)
            original.draw(in: fullRect)
            
            // Mask for processed image
            let maskWidth = targetSize.width * state.sliderPosition
            let maskRect = CGRect(x: 0, y: 0, width: maskWidth, height: targetSize.height)
            
            cgContext.saveGState()
            cgContext.clip(to: maskRect)
            processed.draw(in: fullRect)
            cgContext.restoreGState()
            
        default:
            break
        }
    }
    
    private func renderWatermark(context: UIGraphicsImageRendererContext, size: CGSize) {
        let watermarkText = "✨ Enhanced with Glowly"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: size.width - textSize.width - 20,
            y: size.height - textSize.height - 20,
            width: textSize.width,
            height: textSize.height
        )
        
        // Draw background
        context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.cgContext.fill(textRect.insetBy(dx: -8, dy: -4))
        
        // Draw text
        attributedString.draw(in: textRect)
    }
}

// MARK: - Preview
#Preview {
    ExportOptionsView(
        originalImage: UIImage(systemName: "photo"),
        processedImage: UIImage(systemName: "photo.fill"),
        comparisonState: ComparisonState(),
        exportManager: ExportManager()
    )
}