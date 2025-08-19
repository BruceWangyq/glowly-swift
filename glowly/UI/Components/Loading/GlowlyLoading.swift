//
//  GlowlyLoading.swift
//  Glowly
//
//  Loading indicators and progress views with Glowly design system
//

import SwiftUI

// MARK: - GlowlyLoadingIndicator
struct GlowlyLoadingIndicator: View {
    var size: LoadingSize = .medium
    var style: LoadingStyle = .circular
    var color: Color? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        Group {
            switch style {
            case .circular:
                circularLoader
            case .dots:
                dotsLoader
            case .pulse:
                pulseLoader
            case .shimmer:
                shimmerLoader
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    // MARK: - Circular Loader
    private var circularLoader: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: loaderColor))
            .scaleEffect(scaleForSize)
    }
    
    // MARK: - Dots Loader
    private var dotsLoader: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(loaderColor)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }
    
    // MARK: - Pulse Loader
    private var pulseLoader: some View {
        Circle()
            .fill(loaderColor)
            .frame(width: pulseSize, height: pulseSize)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
    
    // MARK: - Shimmer Loader
    private var shimmerLoader: some View {
        RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.sm)
            .fill(shimmerGradient)
            .frame(width: shimmerWidth, height: shimmerHeight)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
    
    // MARK: - Computed Properties
    
    private var loaderColor: Color {
        color ?? GlowlyTheme.Colors.adaptivePrimary(colorScheme)
    }
    
    private var scaleForSize: CGFloat {
        switch size {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.4
        }
    }
    
    private var dotSize: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
    
    private var dotSpacing: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    private var pulseSize: CGFloat {
        switch size {
        case .small: return 20
        case .medium: return 30
        case .large: return 40
        }
    }
    
    private var shimmerWidth: CGFloat {
        switch size {
        case .small: return 80
        case .medium: return 120
        case .large: return 200
        }
    }
    
    private var shimmerHeight: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                loaderColor.opacity(0.3),
                loaderColor.opacity(0.7),
                loaderColor.opacity(0.3)
            ],
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
    }
}

// MARK: - Loading Enums
extension GlowlyLoadingIndicator {
    enum LoadingSize {
        case small
        case medium
        case large
    }
    
    enum LoadingStyle {
        case circular
        case dots
        case pulse
        case shimmer
    }
}

// MARK: - GlowlyProgressView
struct GlowlyProgressView: View {
    let progress: Double
    var style: ProgressStyle = .linear
    var showPercentage: Bool = true
    var color: Color? = nil
    var backgroundColor: Color? = nil
    var height: CGFloat? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        switch style {
        case .linear:
            linearProgress
        case .circular:
            circularProgress
        case .ring:
            ringProgress
        }
    }
    
    // MARK: - Linear Progress
    private var linearProgress: some View {
        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xs) {
            if showPercentage {
                HStack {
                    Text("Progress")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: progressHeight / 2)
                        .fill(progressBackgroundColor)
                        .frame(height: progressHeight)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: progressHeight / 2)
                        .fill(progressColor)
                        .frame(width: max(0, geometry.size.width * progress), height: progressHeight)
                        .animation(GlowlyTheme.Animation.gentle, value: progress)
                }
            }
            .frame(height: progressHeight)
        }
    }
    
    // MARK: - Circular Progress
    private var circularProgress: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(progressBackgroundColor, lineWidth: circularLineWidth)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: circularLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(GlowlyTheme.Animation.gentle, value: progress)
            
            // Percentage Text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(GlowlyTheme.Typography.headlineFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            }
        }
        .frame(width: circularSize, height: circularSize)
    }
    
    // MARK: - Ring Progress
    private var ringProgress: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(progressBackgroundColor, lineWidth: ringLineWidth)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [progressColor.opacity(0.3), progressColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(GlowlyTheme.Animation.gentle, value: progress)
            
            // Center Content
            VStack(spacing: 2) {
                if showPercentage {
                    Text("\(Int(progress * 100))")
                        .font(GlowlyTheme.Typography.title3Font)
                        .fontWeight(.bold)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    Text("%")
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
    
    // MARK: - Computed Properties
    
    private var progressColor: Color {
        color ?? GlowlyTheme.Colors.adaptivePrimary(colorScheme)
    }
    
    private var progressBackgroundColor: Color {
        backgroundColor ?? GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
    }
    
    private var progressHeight: CGFloat {
        height ?? 8
    }
    
    private var circularSize: CGFloat {
        80
    }
    
    private var circularLineWidth: CGFloat {
        6
    }
    
    private var ringSize: CGFloat {
        100
    }
    
    private var ringLineWidth: CGFloat {
        8
    }
}

// MARK: - Progress Style
extension GlowlyProgressView {
    enum ProgressStyle {
        case linear
        case circular
        case ring
    }
}

// MARK: - GlowlyLoadingOverlay
struct GlowlyLoadingOverlay: View {
    let message: String
    var isVisible: Bool = true
    var style: OverlayStyle = .blur
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background
                overlayBackground
                
                // Content
                VStack(spacing: GlowlyTheme.Spacing.lg) {
                    GlowlyLoadingIndicator(size: .large, style: .pulse)
                    
                    Text(message)
                        .font(GlowlyTheme.Typography.bodyFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(GlowlyTheme.Spacing.xxl)
                .background(overlayContentBackground)
                .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.lg))
                .shadow(
                    color: GlowlyTheme.Shadow.strong.color,
                    radius: GlowlyTheme.Shadow.strong.radius,
                    x: GlowlyTheme.Shadow.strong.offset.width,
                    y: GlowlyTheme.Shadow.strong.offset.height
                )
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .animation(GlowlyTheme.Animation.gentle, value: isVisible)
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var overlayBackground: some View {
        switch style {
        case .blur:
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        case .solid:
            Color.black.opacity(0.5)
        case .clear:
            Color.clear
        }
    }
    
    private var overlayContentBackground: Color {
        GlowlyTheme.Colors.adaptiveSurface(colorScheme)
    }
}

// MARK: - Overlay Style
extension GlowlyLoadingOverlay {
    enum OverlayStyle {
        case blur
        case solid
        case clear
    }
}

// MARK: - GlowlySkeletonLoader
struct GlowlySkeletonLoader: View {
    var style: SkeletonStyle = .text
    var isAnimating: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animationOffset: CGFloat = -1
    
    var body: some View {
        Group {
            switch style {
            case .text:
                textSkeleton
            case .image:
                imageSkeleton
            case .card:
                cardSkeleton
            case .custom(let width, let height, let cornerRadius):
                customSkeleton(width: width, height: height, cornerRadius: cornerRadius)
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
    }
    
    // MARK: - Skeleton Styles
    
    private var textSkeleton: some View {
        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xs) {
            skeletonRectangle(width: nil, height: 16, cornerRadius: 4)
            skeletonRectangle(width: 200, height: 16, cornerRadius: 4)
            skeletonRectangle(width: 150, height: 16, cornerRadius: 4)
        }
    }
    
    private var imageSkeleton: some View {
        skeletonRectangle(width: nil, height: 200, cornerRadius: GlowlyTheme.CornerRadius.image)
    }
    
    private var cardSkeleton: some View {
        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
            skeletonRectangle(width: nil, height: 120, cornerRadius: GlowlyTheme.CornerRadius.image)
            
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xs) {
                skeletonRectangle(width: 120, height: 16, cornerRadius: 4)
                skeletonRectangle(width: 80, height: 12, cornerRadius: 4)
            }
        }
        .padding(GlowlyTheme.Spacing.cardPadding)
        .background(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card))
    }
    
    private func customSkeleton(width: CGFloat?, height: CGFloat, cornerRadius: CGFloat) -> some View {
        skeletonRectangle(width: width, height: height, cornerRadius: cornerRadius)
    }
    
    private func skeletonRectangle(width: CGFloat?, height: CGFloat, cornerRadius: CGFloat) -> some View {
        Rectangle()
            .fill(shimmerGradient)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            animationOffset = 1
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                skeletonColor.opacity(0.3),
                skeletonColor.opacity(0.7),
                skeletonColor.opacity(0.3)
            ],
            startPoint: UnitPoint(x: animationOffset - 0.3, y: 0.5),
            endPoint: UnitPoint(x: animationOffset + 0.3, y: 0.5)
        )
    }
    
    private var skeletonColor: Color {
        GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
    }
}

// MARK: - Skeleton Style
extension GlowlySkeletonLoader {
    enum SkeletonStyle {
        case text
        case image
        case card
        case custom(width: CGFloat?, height: CGFloat, cornerRadius: CGFloat)
    }
}

// MARK: - Preview
#Preview("Loading Components") {
    ScrollView {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            Group {
                Text("Loading Indicators")
                    .font(GlowlyTheme.Typography.title2Font)
                
                HStack(spacing: GlowlyTheme.Spacing.lg) {
                    GlowlyLoadingIndicator(size: .small, style: .circular)
                    GlowlyLoadingIndicator(size: .medium, style: .dots)
                    GlowlyLoadingIndicator(size: .large, style: .pulse)
                }
                
                Text("Progress Views")
                    .font(GlowlyTheme.Typography.title2Font)
                
                GlowlyProgressView(progress: 0.7, style: .linear)
                
                HStack(spacing: GlowlyTheme.Spacing.lg) {
                    GlowlyProgressView(progress: 0.6, style: .circular)
                    GlowlyProgressView(progress: 0.8, style: .ring)
                }
                
                Text("Skeleton Loaders")
                    .font(GlowlyTheme.Typography.title2Font)
                
                GlowlySkeletonLoader(style: .text)
                GlowlySkeletonLoader(style: .card)
            }
        }
        .padding()
    }
    .overlay(
        GlowlyLoadingOverlay(message: "Processing your photo...", isVisible: false)
    )
    .themed()
}