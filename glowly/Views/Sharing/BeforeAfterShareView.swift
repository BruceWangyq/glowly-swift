//
//  BeforeAfterShareView.swift
//  Glowly
//
//  View for creating and sharing before/after photo comparisons
//

import SwiftUI

// MARK: - Before After Share View

struct BeforeAfterShareView: View {
    let photo: GlowlyPhoto
    
    @StateObject private var shareViewModel: ShareViewModel
    @StateObject private var socialSharingService = SocialMediaSharingService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTemplate: BeforeAfterTemplate = .sideBySide
    @State private var selectedPlatform: SocialMediaPlatform = .instagram
    @State private var showingShareSheet = false
    @State private var generatedCollageURL: URL?
    @State private var customCaption = ""
    @State private var isGeneratingCollage = false
    
    init(photo: GlowlyPhoto) {
        self.photo = photo
        self._shareViewModel = StateObject(wrappedValue: ShareViewModel(photo: photo))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: GlowlyTheme.Spacing.lg) {
                    // Header Section
                    headerSection
                    
                    // Template Selection Section
                    templateSelectionSection
                    
                    // Preview Section
                    previewSection
                    
                    // Platform Selection Section
                    platformSelectionSection
                    
                    // Caption Section
                    captionSection
                    
                    // Action Buttons Section
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Before & After")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = generatedCollageURL {
                    ShareSheet(activityItems: [url, customCaption])
                }
            }
            .overlay {
                if isGeneratingCollage || shareViewModel.isSharing {
                    generatingOverlay
                }
            }
            .alert("Share Complete", isPresented: $shareViewModel.showingShareSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your before & after comparison has been shared successfully!")
            }
            .alert("Share Error", isPresented: $shareViewModel.showingShareError) {
                Button("OK") {}
            } message: {
                if let error = shareViewModel.shareError {
                    Text(error)
                }
            }
        }
        .onAppear {
            generateDefaultCaption()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.sm) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .font(.title2)
                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Comparison")
                        .font(GlowlyTheme.Typography.title3Font)
                        .fontWeight(.semibold)
                    
                    Text("Show your photo's transformation")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                
                Spacer()
            }
            
            if !photo.isEnhanced {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text("This photo hasn't been enhanced yet. Please apply some enhancements first.")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Template Selection Section
    
    private var templateSelectionSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Choose Template")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: GlowlyTheme.Spacing.md) {
                ForEach(BeforeAfterTemplate.allCases, id: \.self) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template,
                        action: {
                            selectedTemplate = template
                            HapticFeedback.selection()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Preview")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                ZStack {
                    // Template preview
                    ComparisonPreview(
                        originalImage: photo.originalUIImage,
                        enhancedImage: photo.enhancedUIImage ?? photo.originalUIImage,
                        template: selectedTemplate
                    )
                    .aspectRatio(selectedPlatform.aspectRatio, contentMode: .fit)
                    .clipped()
                    
                    // Loading overlay
                    if isGeneratingCollage {
                        Color.black.opacity(0.3)
                        
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Generating...")
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(.white)
                        }
                    }
                }
                .cornerRadius(GlowlyTheme.CornerRadius.card)
            }
        }
    }
    
    // MARK: - Platform Selection Section
    
    private var platformSelectionSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Platform")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GlowlyTheme.Spacing.sm) {
                    ForEach([SocialMediaPlatform.instagram, .instagramStory, .tiktok, .facebook, .twitter], id: \.self) { platform in
                        PlatformButton(
                            platform: platform,
                            isSelected: selectedPlatform == platform,
                            action: {
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
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Caption")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    TextField("Write your caption...", text: $customCaption, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md)
                                .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        )
                    
                    // Caption suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(beforeAfterCaptions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    customCaption = suggestion
                                    HapticFeedback.selection()
                                }
                                .font(GlowlyTheme.Typography.captionFont)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                                        .stroke(GlowlyTheme.Colors.adaptiveBorder(colorScheme), lineWidth: 1)
                                )
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            // Share to Platform Button
            GlowlyButton(
                title: "Share to \(selectedPlatform.displayName)",
                action: {
                    shareToSocialMedia()
                },
                style: .primary,
                size: .fullWidth,
                isEnabled: photo.isEnhanced && !isGeneratingCollage,
                isLoading: shareViewModel.isSharing,
                icon: selectedPlatform.icon
            )
            
            // Generate and Share Button
            GlowlyButton(
                title: "Generate & Share More",
                action: {
                    generateCollageAndShare()
                },
                style: .secondary,
                size: .fullWidth,
                isEnabled: photo.isEnhanced && !isGeneratingCollage,
                isLoading: isGeneratingCollage,
                icon: "square.and.arrow.up"
            )
        }
    }
    
    // MARK: - Generating Overlay
    
    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: GlowlyTheme.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(isGeneratingCollage ? "Creating comparison..." : "Preparing to share...")
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(.white)
                
                if shareViewModel.shareProgress > 0 {
                    ProgressView(value: shareViewModel.shareProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    Text("\(Int(shareViewModel.shareProgress * 100))%")
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
    
    // MARK: - Caption Suggestions
    
    private var beforeAfterCaptions: [String] {
        [
            "✨ Before vs After - the glow up is real!",
            "💫 Swipe to see the magic transformation",
            "🌟 Enhanced with Glowly - loving the results!",
            "✨ Natural enhancement at its finest",
            "💖 Feeling confident and radiant!"
        ]
    }
    
    // MARK: - Actions
    
    private func generateDefaultCaption() {
        if customCaption.isEmpty {
            customCaption = beforeAfterCaptions.first ?? ""
        }
    }
    
    private func shareToSocialMedia() {
        guard photo.isEnhanced else { return }
        
        Task {
            await shareViewModel.shareBeforeAfterComparison(
                template: selectedTemplate,
                platform: selectedPlatform
            )
        }
    }
    
    private func generateCollageAndShare() {
        guard photo.isEnhanced else { return }
        
        isGeneratingCollage = true
        
        Task {
            do {
                let exportManager = AdvancedExportManager()
                let exportConfig = ExportConfiguration(
                    quality: .high,
                    format: selectedPlatform.recommendedFormat,
                    platform: selectedPlatform,
                    customDimensions: selectedPlatform.optimalDimensions,
                    watermark: WatermarkOptions(enabled: true),
                    preserveMetadata: true,
                    includeEnhancementHistory: true
                )
                
                // Create temporary enhanced photo for comparison
                let enhancedPhoto = GlowlyPhoto(
                    originalImage: photo.originalImage,
                    enhancedImage: photo.enhancedImage,
                    metadata: photo.metadata,
                    enhancementHistory: photo.enhancementHistory
                )
                
                let result = try await exportManager.createBeforeAfterCollage(
                    originalPhoto: photo,
                    enhancedPhoto: enhancedPhoto,
                    template: selectedTemplate,
                    configuration: exportConfig
                )
                
                await MainActor.run {
                    isGeneratingCollage = false
                    
                    if result.success, let url = result.fileURL {
                        generatedCollageURL = url
                        showingShareSheet = true
                        HapticFeedback.success()
                    } else {
                        shareViewModel.shareError = result.error ?? "Failed to generate collage"
                        shareViewModel.showingShareError = true
                        HapticFeedback.error()
                    }
                }
                
            } catch {
                await MainActor.run {
                    isGeneratingCollage = false
                    shareViewModel.shareError = error.localizedDescription
                    shareViewModel.showingShareError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TemplateCard: View {
    let template: BeforeAfterTemplate
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                // Template preview
                ZStack {
                    RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 80)
                    
                    templateIcon
                        .font(.title2)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                
                Text(template.displayName)
                    .font(GlowlyTheme.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding()
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
    
    @ViewBuilder
    private var templateIcon: some View {
        switch template {
        case .sideBySide:
            Image(systemName: "rectangle.split.2x1")
        case .topBottom:
            Image(systemName: "rectangle.split.1x2")
        case .overlaySlider:
            Image(systemName: "slider.horizontal.below.rectangle")
        case .splitDiagonal:
            Image(systemName: "triangle.righthalf.filled")
        }
    }
}

struct PlatformButton: View {
    let platform: SocialMediaPlatform
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: platform.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : platform.color)
                    .frame(width: 32, height: 32)
                
                Text(platform.displayName)
                    .font(GlowlyTheme.Typography.caption2Font)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    .lineLimit(1)
                
                Text("\(Int(platform.optimalDimensions.width))×\(Int(platform.optimalDimensions.height))")
                    .font(GlowlyTheme.Typography.caption2Font)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md)
                    .fill(isSelected ? platform.color : GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .stroke(
                        isSelected ? Color.clear : GlowlyTheme.Colors.adaptiveBorder(colorScheme),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComparisonPreview: View {
    let originalImage: UIImage?
    let enhancedImage: UIImage?
    let template: BeforeAfterTemplate
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
                switch template {
                case .sideBySide:
                    HStack(spacing: 2) {
                        imageView(originalImage, label: "BEFORE")
                            .frame(maxWidth: .infinity)
                        imageView(enhancedImage, label: "AFTER")
                            .frame(maxWidth: .infinity)
                    }
                    
                case .topBottom:
                    VStack(spacing: 2) {
                        imageView(originalImage, label: "BEFORE")
                            .frame(maxHeight: .infinity)
                        imageView(enhancedImage, label: "AFTER")
                            .frame(maxHeight: .infinity)
                    }
                    
                case .overlaySlider:
                    ZStack {
                        imageView(originalImage, label: nil)
                        
                        HStack {
                            imageView(enhancedImage, label: nil)
                                .frame(maxWidth: geometry.size.width * 0.6)
                                .clipped()
                            
                            Spacer(minLength: 0)
                        }
                        
                        // Slider line
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3)
                            .position(x: geometry.size.width * 0.6, y: geometry.size.height / 2)
                    }
                    
                case .splitDiagonal:
                    ZStack {
                        imageView(originalImage, label: nil)
                        
                        imageView(enhancedImage, label: nil)
                            .mask(
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                                    path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height))
                                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                                    path.closeSubpath()
                                }
                                .fill()
                            )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func imageView(_ image: UIImage?, label: String?) -> some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }
            
            if let label = label {
                VStack {
                    HStack {
                        Text(label)
                            .font(GlowlyTheme.Typography.caption2Font)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                        
                        Spacer()
                    }
                    .padding(8)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BeforeAfterShareView(photo: GlowlyPhoto(
        originalImage: Data(),
        enhancedImage: Data(),
        metadata: PhotoMetadata(),
        enhancementHistory: [
            Enhancement(type: .skinSmoothing, intensity: 0.5),
            Enhancement(type: .eyeBrightening, intensity: 0.3)
        ]
    ))
}