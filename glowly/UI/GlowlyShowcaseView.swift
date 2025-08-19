//
//  GlowlyShowcaseView.swift
//  Glowly
//
//  Comprehensive showcase of all Glowly UI components
//

import SwiftUI

// MARK: - GlowlyShowcaseView
struct GlowlyShowcaseView: View {
    @State private var selectedCategory: GlowlyComponentRegistry.ComponentCategory = .buttons
    @State private var showingToast = false
    @State private var showingAlert = false
    @State private var selectedTool: BeautyTool? = nil
    @State private var intensity: Double = 50
    @State private var sliderValue: Double = 75
    
    var body: some View {
        GlowlyScreenContainer(
            navigationTitle: "Glowly UI Showcase",
            navigationSubtitle: "v\(GlowlyUIFramework.version)",
            trailingActions: [
                NavigationAction(
                    type: .icon(GlowlyTheme.Icons.info),
                    handler: {
                        showingAlert = true
                    }
                )
            ]
        ) {
            VStack(spacing: 0) {
                // Category Selector
                categorySelector
                
                // Component Showcase
                GlowlyScrollableContainer(refreshable: true) {
                    showcaseContent
                }
            }
        }
        .withToasts()
        .overlay(
            // Alert Overlay
            GlowlyAlert(
                title: "Glowly UI Framework",
                message: "A comprehensive SwiftUI component library for beauty and photo enhancement apps.",
                type: .info,
                primaryAction: GlowlyAlert.AlertAction(
                    title: "Got it!",
                    style: .primary,
                    action: {}
                ),
                isPresented: $showingAlert
            )
        )
        .themed()
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                ForEach(GlowlyComponentRegistry.ComponentCategory.allCases, id: \.rawValue) { category in
                    Button(category.rawValue) {
                        withAnimation(GlowlyTheme.Animation.standard) {
                            selectedCategory = category
                        }
                        HapticFeedback.light()
                    }
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .fontWeight(selectedCategory == category ? .semibold : .medium)
                    .foregroundColor(
                        selectedCategory == category
                            ? GlowlyTheme.Colors.primary
                            : GlowlyTheme.Colors.textSecondary
                    )
                    .padding(.horizontal, GlowlyTheme.Spacing.md)
                    .padding(.vertical, GlowlyTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(
                                selectedCategory == category
                                    ? GlowlyTheme.Colors.primary.opacity(0.1)
                                    : Color.clear
                            )
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, GlowlyTheme.Spacing.sm)
        .background(GlowlyTheme.Colors.surface)
    }
    
    // MARK: - Showcase Content
    
    @ViewBuilder
    private var showcaseContent: some View {
        switch selectedCategory {
        case .theme:
            themeShowcase
        case .buttons:
            buttonsShowcase
        case .cards:
            cardsShowcase
        case .loading:
            loadingShowcase
        case .alerts:
            alertsShowcase
        case .photo:
            photoShowcase
        case .beauty:
            beautyShowcase
        case .navigation:
            navigationShowcase
        case .layout:
            layoutShowcase
        case .animation:
            animationShowcase
        case .accessibility:
            accessibilityShowcase
        }
    }
    
    // MARK: - Theme Showcase
    
    private var themeShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Color Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: GlowlyTheme.Spacing.sm) {
                    colorSwatch("Primary", GlowlyTheme.Colors.primary)
                    colorSwatch("Secondary", GlowlyTheme.Colors.secondary)
                    colorSwatch("Accent", GlowlyTheme.Colors.accent)
                    colorSwatch("Success", GlowlyTheme.Colors.success)
                    colorSwatch("Warning", GlowlyTheme.Colors.warning)
                    colorSwatch("Error", GlowlyTheme.Colors.error)
                }
            }
            
            GlowlySection(title: "Typography") {
                VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                    Text("Large Title").font(GlowlyTheme.Typography.largeTitle)
                    Text("Title 1").font(GlowlyTheme.Typography.title1Font)
                    Text("Title 2").font(GlowlyTheme.Typography.title2Font)
                    Text("Headline").font(GlowlyTheme.Typography.headlineFont)
                    Text("Body Text").font(GlowlyTheme.Typography.bodyFont)
                    Text("Caption").font(GlowlyTheme.Typography.captionFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GlowlySection(title: "Spacing & Corner Radius") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    HStack(spacing: GlowlyTheme.Spacing.sm) {
                        spacingSample("XS", GlowlyTheme.Spacing.xs)
                        spacingSample("SM", GlowlyTheme.Spacing.sm)
                        spacingSample("MD", GlowlyTheme.Spacing.md)
                        spacingSample("LG", GlowlyTheme.Spacing.lg)
                    }
                    
                    HStack(spacing: GlowlyTheme.Spacing.sm) {
                        cornerRadiusSample("SM", GlowlyTheme.CornerRadius.sm)
                        cornerRadiusSample("MD", GlowlyTheme.CornerRadius.md)
                        cornerRadiusSample("LG", GlowlyTheme.CornerRadius.lg)
                        cornerRadiusSample("XL", GlowlyTheme.CornerRadius.xl)
                    }
                }
            }
        }
    }
    
    // MARK: - Buttons Showcase
    
    private var buttonsShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Button Styles") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyButton(title: "Primary Button", action: { showToast("Primary button tapped") })
                    GlowlyButton(title: "Secondary Button", action: { showToast("Secondary button tapped") }, style: .secondary)
                    GlowlyButton(title: "Success Button", action: { showToast("Success button tapped") }, style: .success)
                    GlowlyButton(title: "With Icon", action: { showToast("Icon button tapped") }, icon: GlowlyTheme.Icons.sparkles)
                }
            }
            
            GlowlySection(title: "Icon Buttons") {
                HStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyIconButton(icon: GlowlyTheme.Icons.settings, action: { showToast("Settings") })
                    GlowlyIconButton(icon: GlowlyTheme.Icons.share, action: { showToast("Share") }, style: .primary)
                    GlowlyIconButton(icon: GlowlyTheme.Icons.heart, action: { showToast("Favorite") }, style: .error)
                    GlowlyIconButton(icon: GlowlyTheme.Icons.bookmark, action: { showToast("Bookmark") }, style: .secondary)
                }
            }
            
            GlowlySection(title: "Interactive Buttons") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyBouncyButton {
                        Text("Bouncy Button")
                            .padding()
                            .background(GlowlyTheme.Colors.primary)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } action: {
                        showToast("Bouncy!")
                    }
                    
                    GlowlySpringButton {
                        Text("Spring Button")
                            .padding()
                            .background(GlowlyTheme.Colors.secondary)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } action: {
                        showToast("Spring!")
                    }
                    
                    GlowlyFloatingActionButton(icon: GlowlyTheme.Icons.add) {
                        showToast("FAB tapped!")
                    }
                }
            }
        }
    }
    
    // MARK: - Cards Showcase
    
    private var cardsShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Card Styles") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyCard {
                        VStack(alignment: .leading) {
                            Text("Default Card")
                                .font(GlowlyTheme.Typography.headlineFont)
                            Text("This is a default card with standard styling.")
                                .font(GlowlyTheme.Typography.bodyFont)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    GlowlyCard(style: .elevated) {
                        Text("Elevated Card")
                            .font(GlowlyTheme.Typography.headlineFont)
                    }
                    
                    GlowlyCard(style: .outlined) {
                        Text("Outlined Card")
                            .font(GlowlyTheme.Typography.headlineFont)
                    }
                }
            }
            
            GlowlySection(title: "Feature Cards") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyFeatureCard(
                        icon: GlowlyTheme.Icons.sparkles,
                        title: "AI Enhancement",
                        description: "Automatically enhance your photos with AI",
                        isPremium: false,
                        onTap: { showToast("AI Enhancement selected") }
                    )
                    
                    GlowlyFeatureCard(
                        icon: GlowlyTheme.Icons.crown,
                        title: "Premium Filters",
                        description: "Access exclusive premium filters",
                        isPremium: true,
                        onTap: { showToast("Premium feature - upgrade required") }
                    )
                }
            }
        }
    }
    
    // MARK: - Loading Showcase
    
    private var loadingShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Loading Indicators") {
                HStack(spacing: GlowlyTheme.Spacing.xl) {
                    VStack {
                        GlowlyLoadingIndicator(size: .small, style: .circular)
                        Text("Circular")
                            .font(GlowlyTheme.Typography.captionFont)
                    }
                    
                    VStack {
                        GlowlyLoadingIndicator(size: .medium, style: .dots)
                        Text("Dots")
                            .font(GlowlyTheme.Typography.captionFont)
                    }
                    
                    VStack {
                        GlowlyLoadingIndicator(size: .large, style: .pulse)
                        Text("Pulse")
                            .font(GlowlyTheme.Typography.captionFont)
                    }
                }
            }
            
            GlowlySection(title: "Progress Views") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlyProgressView(progress: 0.7, style: .linear)
                    
                    HStack(spacing: GlowlyTheme.Spacing.lg) {
                        GlowlyProgressView(progress: 0.6, style: .circular)
                        GlowlyProgressRing(progress: 0.8, lineWidth: 8, size: 80, showPercentage: true)
                    }
                }
            }
            
            GlowlySection(title: "Skeleton Loaders") {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    GlowlySkeletonLoader(style: .text)
                    GlowlySkeletonLoader(style: .image)
                }
            }
        }
    }
    
    // MARK: - Alerts Showcase
    
    private var alertsShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Toast Notifications") {
                VStack(spacing: GlowlyTheme.Spacing.sm) {
                    GlowlyButton(title: "Success Toast", action: { showToast("Success!", type: .success) }, style: .success)
                    GlowlyButton(title: "Warning Toast", action: { showToast("Warning!", type: .warning) }, style: .warning)
                    GlowlyButton(title: "Error Toast", action: { showToast("Error!", type: .error) }, style: .error)
                    GlowlyButton(title: "Info Toast", action: { showToast("Info!", type: .info) }, style: .secondary)
                }
            }
            
            GlowlySection(title: "Alerts") {
                GlowlyButton(title: "Show Alert", action: { showingAlert = true })
            }
            
            GlowlySection(title: "Banners") {
                GlowlyBanner(
                    title: "Premium Feature",
                    message: "Upgrade to access advanced AI enhancements",
                    type: .premium,
                    action: GlowlyBanner.BannerAction(title: "Upgrade Now", action: { showToast("Upgrade tapped") }),
                    isPresented: .constant(true)
                )
            }
        }
    }
    
    // MARK: - Photo Showcase
    
    private var photoShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Photo Import") {
                GlowlyPhotoImportButton(
                    onPhotosSelected: { images in
                        showToast("Selected \(images.count) photo(s)")
                    },
                    style: .card
                )
            }
            
            GlowlySection(title: "Enhancement Slider") {
                GlowlyEnhancementSlider(
                    title: "Brightness",
                    icon: GlowlyTheme.Icons.brightness,
                    value: $sliderValue,
                    range: 0...100,
                    unit: "%"
                ) { value in
                    showToast("Brightness: \(Int(value))%")
                }
            }
            
            GlowlySection(title: "Photo Grid") {
                Text("Photo grid would display actual photos here")
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(GlowlyTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md))
            }
        }
    }
    
    // MARK: - Beauty Showcase
    
    private var beautyShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Beauty Tools") {
                GlowlyBeautyToolSelector(
                    tools: BeautyTool.sampleTools,
                    selectedTool: $selectedTool
                ) { tool in
                    showToast("\(tool.name) selected")
                }
            }
            
            if let selectedTool = selectedTool {
                GlowlySection(title: "Intensity Control") {
                    GlowlyBeautyIntensityControl(
                        tool: selectedTool,
                        intensity: $intensity
                    ) { newIntensity in
                        showToast("\(selectedTool.name): \(Int(newIntensity))%")
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Showcase
    
    private var navigationShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Page Control") {
                GlowlyPageControl(
                    numberOfPages: 4,
                    currentPage: .constant(1)
                ) { page in
                    showToast("Page \(page + 1) selected")
                }
            }
            
            GlowlySection(title: "Progress Navigation") {
                GlowlyProgressNavigationBar(
                    title: "Processing",
                    progress: 0.7,
                    leadingAction: .cancel { showToast("Cancelled") },
                    trailingAction: .done { showToast("Done") }
                )
            }
        }
    }
    
    // MARK: - Layout Showcase
    
    private var layoutShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Grid Layout") {
                GlowlyGridLayout(columns: 3) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(GlowlyTheme.Colors.primary.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image))
                            .overlay(
                                Text("\(index + 1)")
                                    .font(GlowlyTheme.Typography.headlineFont)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            
            GlowlySection(title: "Divider") {
                VStack {
                    Text("Content above")
                    GlowlyDivider()
                    Text("Content below")
                }
            }
            
            GlowlySection(title: "Empty State") {
                GlowlyEmptyState(
                    icon: GlowlyTheme.Icons.photo,
                    title: "No Photos",
                    description: "Add some photos to get started",
                    primaryAction: GlowlyEmptyState.EmptyStateAction(title: "Add Photos") {
                        showToast("Add photos tapped")
                    }
                )
            }
        }
    }
    
    // MARK: - Animation Showcase
    
    private var animationShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Animated Gradient") {
                GlowlyAnimatedGradient(
                    colors: [
                        GlowlyTheme.Colors.primary,
                        GlowlyTheme.Colors.secondary,
                        GlowlyTheme.Colors.accent
                    ]
                )
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.lg))
            }
            
            GlowlySection(title: "Wave Effect") {
                GlowlyWaveEffect(
                    color: GlowlyTheme.Colors.primary,
                    amplitude: 20,
                    frequency: 2
                )
                .frame(height: 60)
            }
            
            GlowlySection(title: "Effects") {
                HStack(spacing: GlowlyTheme.Spacing.lg) {
                    Rectangle()
                        .fill(GlowlyTheme.Colors.secondary)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .glowlyPulse()
                        .overlay(
                            Text("Pulse")
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        )
                    
                    Rectangle()
                        .fill(GlowlyTheme.Colors.accent)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .glowlyShimmer()
                        .overlay(
                            Text("Shimmer")
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        )
                }
            }
        }
    }
    
    // MARK: - Accessibility Showcase
    
    private var accessibilityShowcase: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlySection(title: "Accessible Slider") {
                GlowlyAccessibleSlider(
                    title: "Volume",
                    value: $sliderValue,
                    range: 0...100,
                    step: 5,
                    unit: "%"
                ) { value in
                    showToast("Volume: \(Int(value))%")
                }
            }
            
            GlowlySection(title: "Accessible Card") {
                GlowlyAccessibleCard(
                    accessibilityLabel: "Feature card",
                    accessibilityHint: "Double tap to select this feature",
                    accessibilityValue: "Premium feature available",
                    isSelected: true,
                    onTap: { showToast("Accessible card tapped") }
                ) {
                    VStack(alignment: .leading) {
                        Text("Accessible Feature")
                            .font(GlowlyTheme.Typography.headlineFont)
                            .fontWeight(.semibold)
                        
                        Text("This card is fully accessible with VoiceOver support")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            GlowlySection(title: "Focus Guide") {
                GlowlyFocusGuide(identifier: "showcase_focus_guide", debugMode: true)
                    .frame(height: 50)
                    .overlay(
                        Text("Focus Guide (Debug Mode)")
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showToast(_ message: String, type: GlowlyToast.ToastType = .info) {
        // In a real implementation, this would use the toast manager
        print("Toast: \(message)")
        HapticFeedback.light()
    }
    
    // MARK: - Helper Views
    
    private func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: GlowlyTheme.Spacing.xs) {
            RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.sm)
                .fill(color)
                .frame(height: 60)
            
            Text(name)
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(.secondary)
        }
    }
    
    private func spacingSample(_ name: String, _ spacing: CGFloat) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(GlowlyTheme.Colors.primary)
                .frame(width: spacing, height: 30)
            
            Text(name)
                .font(GlowlyTheme.Typography.caption2Font)
                .foregroundColor(.secondary)
        }
    }
    
    private func cornerRadiusSample(_ name: String, _ radius: CGFloat) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(GlowlyTheme.Colors.secondary)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: radius))
            
            Text(name)
                .font(GlowlyTheme.Typography.caption2Font)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    GlowlyShowcaseView()
}