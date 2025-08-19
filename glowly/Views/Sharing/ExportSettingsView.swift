//
//  ExportSettingsView.swift
//  Glowly
//
//  Advanced export settings and configuration view
//

import SwiftUI

// MARK: - Export Settings View

struct ExportSettingsView: View {
    let photo: GlowlyPhoto
    let platform: SocialMediaPlatform?
    let onExport: (URL) -> Void
    
    @StateObject private var exportManager = AdvancedExportManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedQuality: ExportQuality = .high
    @State private var selectedFormat: ExportFormat = .jpeg
    @State private var customDimensions: CGSize?
    @State private var watermarkOptions = WatermarkOptions()
    @State private var preserveMetadata = true
    @State private var includeEnhancementHistory = true
    @State private var showingCustomDimensions = false
    @State private var customWidth: String = "1080"
    @State private var customHeight: String = "1080"
    
    var body: some View {
        NavigationView {
            Form {
                // Platform Section
                if let platform = platform {
                    platformOptimizationSection(platform)
                }
                
                // Quality Settings Section
                qualitySettingsSection
                
                // Format Settings Section
                formatSettingsSection
                
                // Dimensions Section
                dimensionsSection
                
                // Watermark Section
                watermarkSection
                
                // Metadata Section
                metadataSection
                
                // Preview Section
                previewSection
            }
            .navigationTitle("Export Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportPhoto()
                    }
                    .fontWeight(.semibold)
                    .disabled(exportManager.isExporting)
                }
            }
            .overlay {
                if exportManager.isExporting {
                    exportProgressOverlay
                }
            }
            .sheet(isPresented: $showingCustomDimensions) {
                CustomDimensionsSheet(
                    width: $customWidth,
                    height: $customHeight,
                    onSave: { width, height in
                        customDimensions = CGSize(width: width, height: height)
                    }
                )
            }
        }
        .onAppear {
            configureDefaultSettings()
        }
    }
    
    // MARK: - Platform Optimization Section
    
    private func platformOptimizationSection(_ platform: SocialMediaPlatform) -> some View {
        Section("Platform Optimization") {
            HStack {
                Image(systemName: platform.icon)
                    .foregroundColor(platform.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(platform.displayName)
                        .font(GlowlyTheme.Typography.bodyFont)
                        .fontWeight(.medium)
                    
                    Text("Optimized for \(platform.displayName)")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(platform.optimalDimensions.width))×\(Int(platform.optimalDimensions.height))")
                        .font(GlowlyTheme.Typography.captionFont)
                        .fontWeight(.medium)
                    
                    Text(platform.recommendedFormat.displayName)
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Quality Settings Section
    
    private var qualitySettingsSection: some View {
        Section("Quality Settings") {
            Picker("Export Quality", selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) { quality in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quality.displayName)
                            .font(GlowlyTheme.Typography.bodyFont)
                        Text(quality.description)
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    }
                    .tag(quality)
                }
            }
            .pickerStyle(NavigationLinkPickerStyle())
            
            // Quality Info
            QualityInfoRow(
                title: "Compression",
                value: "\(Int(selectedQuality.compressionQuality * 100))%"
            )
            
            if let maxDimension = selectedQuality.maxDimension {
                QualityInfoRow(
                    title: "Max Dimension",
                    value: "\(Int(maxDimension))px"
                )
            }
        }
    }
    
    // MARK: - Format Settings Section
    
    private var formatSettingsSection: some View {
        Section("Format Settings") {
            Picker("Export Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    HStack {
                        Text(format.displayName)
                        Spacer()
                        if format.supportsTransparency {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    .tag(format)
                }
            }
            .pickerStyle(NavigationLinkPickerStyle())
            
            // Format capabilities
            FormatCapabilitiesRow(format: selectedFormat)
        }
    }
    
    // MARK: - Dimensions Section
    
    private var dimensionsSection: some View {
        Section("Dimensions") {
            if let platform = platform {
                HStack {
                    Text("Platform Optimal")
                    Spacer()
                    Text("\(Int(platform.optimalDimensions.width))×\(Int(platform.optimalDimensions.height))")
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            
            Button("Custom Dimensions") {
                showingCustomDimensions = true
            }
            
            if let dimensions = customDimensions {
                HStack {
                    Text("Custom Size")
                    Spacer()
                    Text("\(Int(dimensions.width))×\(Int(dimensions.height))")
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    
                    Button("Remove") {
                        customDimensions = nil
                    }
                    .font(GlowlyTheme.Typography.captionFont)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Watermark Section
    
    private var watermarkSection: some View {
        Section("Watermark") {
            Toggle("Include Watermark", isOn: $watermarkOptions.enabled)
            
            if watermarkOptions.enabled {
                HStack {
                    Text("Text")
                    Spacer()
                    TextField("Watermark text", text: $watermarkOptions.text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
                
                Picker("Position", selection: $watermarkOptions.position) {
                    ForEach(WatermarkPosition.allCases, id: \.self) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                
                Picker("Style", selection: $watermarkOptions.style) {
                    ForEach(WatermarkStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(watermarkOptions.opacity * 100))%")
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    }
                    
                    Slider(value: $watermarkOptions.opacity, in: 0...1, step: 0.1)
                        .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                }
                
                Picker("Size", selection: $watermarkOptions.size) {
                    ForEach(WatermarkSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        Section("Metadata & History") {
            Toggle("Preserve Original Metadata", isOn: $preserveMetadata)
            
            if photo.isEnhanced {
                Toggle("Include Enhancement History", isOn: $includeEnhancementHistory)
                
                if includeEnhancementHistory {
                    Text("Enhancement data will be embedded in the exported file")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        Section("Preview") {
            HStack {
                Text("Estimated File Size")
                Spacer()
                Text(estimatedFileSize)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            if let dimensions = targetDimensions {
                HStack {
                    Text("Output Dimensions")
                    Spacer()
                    Text("\(Int(dimensions.width))×\(Int(dimensions.height))")
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            
            HStack {
                Text("Format")
                Spacer()
                Text(selectedFormat.displayName)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
        }
    }
    
    // MARK: - Export Progress Overlay
    
    private var exportProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: GlowlyTheme.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Exporting Photo...")
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(.white)
                
                if exportManager.exportProgress > 0 {
                    ProgressView(value: exportManager.exportProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    Text("\(Int(exportManager.exportProgress * 100))%")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(GlowlyTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.lg)
                    .fill(Color.black.opacity(0.8))
                    .blur(radius: 10)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var targetDimensions: CGSize? {
        if let custom = customDimensions {
            return custom
        }
        return platform?.optimalDimensions
    }
    
    private var estimatedFileSize: String {
        let baseSize = photo.metadata.fileSize
        let qualityMultiplier = selectedQuality.compressionQuality
        let formatMultiplier: Double = selectedFormat == .png ? 1.5 : 1.0
        
        let estimatedSize = Double(baseSize) * Double(qualityMultiplier) * formatMultiplier
        
        return ByteCountFormatter.string(fromByteCount: Int64(estimatedSize), countStyle: .file)
    }
    
    // MARK: - Actions
    
    private func configureDefaultSettings() {
        if let platform = platform {
            selectedFormat = platform.recommendedFormat
            selectedQuality = .high
        }
    }
    
    private func exportPhoto() {
        let configuration = ExportConfiguration(
            quality: selectedQuality,
            format: selectedFormat,
            platform: platform,
            customDimensions: customDimensions,
            watermark: watermarkOptions,
            preserveMetadata: preserveMetadata,
            includeEnhancementHistory: includeEnhancementHistory
        )
        
        Task {
            do {
                let result = try await exportManager.exportPhoto(
                    photo,
                    configuration: configuration
                )
                
                if result.success, let fileURL = result.fileURL {
                    await MainActor.run {
                        onExport(fileURL)
                        dismiss()
                        HapticFeedback.success()
                    }
                }
            } catch {
                await MainActor.run {
                    HapticFeedback.error()
                    // Handle error
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QualityInfoRow: View {
    let title: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            Spacer()
            Text(value)
                .font(GlowlyTheme.Typography.captionFont)
                .fontWeight(.medium)
        }
    }
}

struct FormatCapabilitiesRow: View {
    let format: ExportFormat
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Supports Transparency")
                Spacer()
                Image(systemName: format.supportsTransparency ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(format.supportsTransparency ? .green : .red)
            }
            .font(GlowlyTheme.Typography.captionFont)
            
            HStack {
                Text("MIME Type")
                Spacer()
                Text(format.mimeType)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
            .font(GlowlyTheme.Typography.caption2Font)
        }
    }
}

struct CustomDimensionsSheet: View {
    @Binding var width: String
    @Binding var height: String
    let onSave: (CGFloat, CGFloat) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var aspectRatioLocked = false
    @State private var aspectRatio: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Custom Dimensions") {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("Width", text: $width)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                            .onChange(of: width) { _, newValue in
                                if aspectRatioLocked {
                                    updateHeightFromWidth()
                                }
                            }
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", text: $height)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                            .onChange(of: height) { _, newValue in
                                if aspectRatioLocked {
                                    updateWidthFromHeight()
                                }
                            }
                    }
                    
                    Toggle("Lock Aspect Ratio", isOn: $aspectRatioLocked)
                        .onChange(of: aspectRatioLocked) { _, newValue in
                            if newValue {
                                calculateAspectRatio()
                            }
                        }
                }
                
                Section("Presets") {
                    ForEach(DimensionPreset.allCases, id: \.self) { preset in
                        Button(preset.displayName) {
                            width = String(Int(preset.dimensions.width))
                            height = String(Int(preset.dimensions.height))
                        }
                    }
                }
            }
            .navigationTitle("Custom Dimensions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDimensions()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            calculateAspectRatio()
        }
    }
    
    private func calculateAspectRatio() {
        guard let w = CGFloat(width), let h = CGFloat(height), h > 0 else { return }
        aspectRatio = w / h
    }
    
    private func updateHeightFromWidth() {
        guard let w = CGFloat(width), aspectRatio > 0 else { return }
        height = String(Int(w / aspectRatio))
    }
    
    private func updateWidthFromHeight() {
        guard let h = CGFloat(height) else { return }
        width = String(Int(h * aspectRatio))
    }
    
    private func saveDimensions() {
        guard let w = CGFloat(width), let h = CGFloat(height) else { return }
        onSave(w, h)
        dismiss()
    }
}

// MARK: - Dimension Presets

enum DimensionPreset: CaseIterable {
    case square1080
    case instagram
    case instagramStory
    case tiktok
    case facebook
    case twitter
    case pinterest
    case fullHD
    case fourK
    
    var displayName: String {
        switch self {
        case .square1080:
            return "Square (1080×1080)"
        case .instagram:
            return "Instagram Post (1080×1080)"
        case .instagramStory:
            return "Instagram Story (1080×1920)"
        case .tiktok:
            return "TikTok (1080×1920)"
        case .facebook:
            return "Facebook (1200×630)"
        case .twitter:
            return "Twitter (1200×675)"
        case .pinterest:
            return "Pinterest (1000×1500)"
        case .fullHD:
            return "Full HD (1920×1080)"
        case .fourK:
            return "4K (3840×2160)"
        }
    }
    
    var dimensions: CGSize {
        switch self {
        case .square1080, .instagram:
            return CGSize(width: 1080, height: 1080)
        case .instagramStory, .tiktok:
            return CGSize(width: 1080, height: 1920)
        case .facebook:
            return CGSize(width: 1200, height: 630)
        case .twitter:
            return CGSize(width: 1200, height: 675)
        case .pinterest:
            return CGSize(width: 1000, height: 1500)
        case .fullHD:
            return CGSize(width: 1920, height: 1080)
        case .fourK:
            return CGSize(width: 3840, height: 2160)
        }
    }
}

// MARK: - Preview

#Preview {
    ExportSettingsView(
        photo: GlowlyPhoto(
            originalImage: Data(),
            metadata: PhotoMetadata()
        ),
        platform: .instagram,
        onExport: { _ in }
    )
}