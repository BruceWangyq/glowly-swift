//
//  ShareView.swift
//  Glowly
//
//  Comprehensive sharing interface with native iOS integration and custom platforms
//

import SwiftUI
import PhotosUI

// MARK: - Share View

struct ShareView: View {
    let photo: GlowlyPhoto
    @StateObject private var shareViewModel: ShareViewModel
    @StateObject private var socialSharingService = SocialMediaSharingService()
    @StateObject private var photoLibraryManager = PhotoLibraryManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedPlatform: SocialMediaPlatform?
    @State private var showingExportOptions = false
    @State private var showingNativeShareSheet = false
    @State private var showingBeforeAfterSheet = false
    @State private var shareURL: URL?
    @State private var customCaption = ""
    @State private var selectedHashtags: Set<String> = []
    
    init(photo: GlowlyPhoto) {
        self.photo = photo
        self._shareViewModel = StateObject(wrappedValue: ShareViewModel(photo: photo))
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: GlowlyTheme.Spacing.lg) {
                        // Photo Preview Section
                        photoPreviewSection
                            .frame(height: geometry.size.height * 0.4)
                        
                        // Quick Actions Section
                        quickActionsSection
                        
                        // Social Media Platforms Section
                        socialMediaSection
                        
                        // Advanced Options Section
                        advancedOptionsSection
                        
                        // Content Suggestions Section
                        if let suggestions = shareViewModel.contentSuggestions {
                            contentSuggestionsSection(suggestions)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Share Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("More") {
                        showingNativeShareSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportSettingsView(
                    photo: photo,
                    platform: selectedPlatform,
                    onExport: { url in
                        shareURL = url
                        showingNativeShareSheet = true
                    }
                )
            }
            .sheet(isPresented: $showingBeforeAfterSheet) {
                BeforeAfterShareView(photo: photo)
            }
            .sheet(isPresented: $showingNativeShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url, customCaption])
                }
            }
            .overlay {
                if shareViewModel.isSharing {
                    sharingProgressOverlay
                }
            }
            .alert("Share Complete", isPresented: $shareViewModel.showingShareSuccess) {
                Button("OK") {}
            } message: {
                Text("Your photo has been shared successfully!")
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
            shareViewModel.generateContentSuggestions()
        }
    }
    
    // MARK: - Photo Preview Section
    
    private var photoPreviewSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Preview")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                ZStack {
                    Color.black
                    
                    if let image = photo.enhancedUIImage ?? photo.originalUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    }
                    
                    // Enhancement indicator
                    if photo.isEnhanced {
                        VStack {
                            HStack {
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                    Text("Enhanced")
                                        .font(GlowlyTheme.Typography.captionFont)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.6))
                                )
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }
                .cornerRadius(GlowlyTheme.CornerRadius.card)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Quick Actions")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: GlowlyTheme.Spacing.md) {
                QuickActionCard(
                    title: "Save to Photos",
                    subtitle: "Save to your library",
                    icon: "photo.badge.plus",
                    color: GlowlyTheme.Colors.success,
                    action: {
                        Task {
                            await saveToPhotoLibrary()
                        }
                    }
                )
                
                QuickActionCard(
                    title: "Share Original",
                    subtitle: "Share via system",
                    icon: "square.and.arrow.up",
                    color: GlowlyTheme.Colors.secondary,
                    action: {
                        shareOriginalPhoto()
                    }
                )
                
                QuickActionCard(
                    title: "Before & After",
                    subtitle: "Create comparison",
                    icon: "rectangle.split.2x1",
                    color: GlowlyTheme.Colors.accent,
                    action: {
                        showingBeforeAfterSheet = true
                    }
                )
                
                QuickActionCard(
                    title: "Export Options",
                    subtitle: "Custom settings",
                    icon: "gear",
                    color: GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                    action: {
                        showingExportOptions = true
                    }
                )
            }
        }
    }
    
    // MARK: - Social Media Section
    
    private var socialMediaSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Share to Social Media")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Optimized for each platform")
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: GlowlyTheme.Spacing.md) {
                ForEach(SocialMediaPlatform.allCases, id: \.self) { platform in
                    SocialPlatformCard(
                        platform: platform,
                        isAvailable: socialSharingService.isPlatformAvailable(platform),
                        isSelected: selectedPlatform == platform,
                        action: {
                            selectPlatform(platform)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Advanced Options")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    // Custom Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Caption")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        TextField("Add your caption...", text: $customCaption, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Watermark Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include Watermark")
                                .font(GlowlyTheme.Typography.bodyFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            
                            Text("Add Glowly branding")
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $shareViewModel.includeWatermark)
                            .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    }
                    
                    // Quality Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Quality")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        Picker("Quality", selection: $shareViewModel.exportQuality) {
                            ForEach(ExportQuality.allCases, id: \.self) { quality in
                                Text(quality.displayName).tag(quality)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Content Suggestions Section
    
    private func contentSuggestionsSection(_ suggestions: SharingContentSuggestions) -> some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Content Suggestions")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.md) {
                    // Caption Suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption Ideas")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions.captions.prefix(3), id: \.self) { caption in
                                    CaptionSuggestionChip(
                                        caption: caption,
                                        action: {
                                            customCaption = caption
                                            HapticFeedback.selection()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    Divider()
                    
                    // Hashtag Suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hashtag Suggestions")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        FlowLayout(spacing: 8) {
                            ForEach(suggestions.hashtags, id: \.self) { hashtag in
                                HashtagChip(
                                    hashtag: hashtag,
                                    isSelected: selectedHashtags.contains(hashtag),
                                    action: {
                                        toggleHashtag(hashtag)
                                    }
                                )
                            }
                        }
                        
                        if !selectedHashtags.isEmpty {
                            Button("Add Selected to Caption") {
                                addSelectedHashtagsToCaption()
                            }
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Sharing Progress Overlay
    
    private var sharingProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: GlowlyTheme.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Preparing to share...")
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
    
    // MARK: - Actions
    
    private func selectPlatform(_ platform: SocialMediaPlatform) {
        selectedPlatform = platform
        shareViewModel.selectedPlatform = platform
        
        Task {
            await shareViewModel.shareToSocialMedia(
                platform: platform,
                customCaption: customCaption.isEmpty ? nil : customCaption
            )
        }
    }
    
    private func saveToPhotoLibrary() async {
        do {
            _ = try await photoLibraryManager.savePhoto(photo)
            await MainActor.run {
                shareViewModel.showingShareSuccess = true
                HapticFeedback.success()
            }
        } catch {
            await MainActor.run {
                shareViewModel.shareError = error.localizedDescription
                shareViewModel.showingShareError = true
                HapticFeedback.error()
            }
        }
    }
    
    private func shareOriginalPhoto() {
        guard let imageData = photo.enhancedImage ?? photo.originalImage,
              let image = UIImage(data: imageData) else {
            return
        }
        
        shareURL = createTemporaryImageURL(from: image)
        showingNativeShareSheet = true
    }
    
    private func createTemporaryImageURL(from image: UIImage) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        do {
            try imageData.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    private func toggleHashtag(_ hashtag: String) {
        if selectedHashtags.contains(hashtag) {
            selectedHashtags.remove(hashtag)
        } else {
            selectedHashtags.insert(hashtag)
        }
        HapticFeedback.selection()
    }
    
    private func addSelectedHashtagsToCaption() {
        let hashtagString = selectedHashtags.sorted().joined(separator: " ")
        if !customCaption.isEmpty && !customCaption.hasSuffix(" ") {
            customCaption += " "
        }
        customCaption += hashtagString
        selectedHashtags.removeAll()
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(GlowlyTheme.Typography.subheadlineFont)
                        .fontWeight(.medium)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    Text(subtitle)
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .shadow(color: GlowlyTheme.Shadow.card.color, radius: GlowlyTheme.Shadow.card.radius, x: GlowlyTheme.Shadow.card.offset.width, y: GlowlyTheme.Shadow.card.offset.height)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SocialPlatformCard: View {
    let platform: SocialMediaPlatform
    let isAvailable: Bool
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: GlowlyTheme.Spacing.xs) {
                Image(systemName: platform.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isAvailable ? platform.color : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    .frame(width: 32, height: 32)
                
                Text(platform.displayName)
                    .font(GlowlyTheme.Typography.caption2Font)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !isAvailable {
                    Text("Not Available")
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            .padding(GlowlyTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .stroke(
                        isSelected ? platform.color : GlowlyTheme.Colors.adaptiveBorder(colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
    }
}

struct CaptionSuggestionChip: View {
    let caption: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(caption)
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        .stroke(GlowlyTheme.Colors.adaptiveBorder(colorScheme), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HashtagChip: View {
    let hashtag: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(hashtag)
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(
                    isSelected ? .white : GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += row.height + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow: [LayoutSubview] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + size.width > maxWidth && !currentRow.isEmpty {
                rows.append(Row(subviews: currentRow, height: currentRowHeight))
                currentRow = []
                currentRowWidth = 0
                currentRowHeight = 0
            }
            
            currentRow.append(subview)
            currentRowWidth += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        if !currentRow.isEmpty {
            rows.append(Row(subviews: currentRow, height: currentRowHeight))
        }
        
        return rows
    }
    
    private struct Row {
        let subviews: [LayoutSubview]
        let height: CGFloat
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Card Component

struct GlowlyCard<Content: View>: View {
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                    .shadow(
                        color: GlowlyTheme.Shadow.card.color,
                        radius: GlowlyTheme.Shadow.card.radius,
                        x: GlowlyTheme.Shadow.card.offset.width,
                        y: GlowlyTheme.Shadow.card.offset.height
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    ShareView(photo: GlowlyPhoto(
        originalImage: Data(),
        metadata: PhotoMetadata()
    ))
}