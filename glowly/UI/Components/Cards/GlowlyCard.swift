//
//  GlowlyCard.swift
//  Glowly
//
//  Card components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyCard
struct GlowlyCard<Content: View>: View {
    let content: Content
    var style: CardStyle = .default
    var padding: CGFloat = GlowlyTheme.Spacing.cardPadding
    var cornerRadius: CGFloat = GlowlyTheme.CornerRadius.card
    var showShadow: Bool = true
    var onTap: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    init(
        style: CardStyle = .default,
        padding: CGFloat = GlowlyTheme.Spacing.cardPadding,
        cornerRadius: CGFloat = GlowlyTheme.CornerRadius.card,
        showShadow: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        if let onTap = onTap {
            Button(action: {
                HapticFeedback.light()
                onTap()
            }) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(GlowlyTheme.Animation.quick, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
        } else {
            cardContent
        }
    }
    
    private var cardContent: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .conditionalShadow(
                condition: showShadow,
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .default:
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        case .elevated:
            return GlowlyTheme.Colors.surfaceElevated
        case .outlined:
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        case .tinted(let color):
            return color.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .default, .elevated, .tinted:
            return Color.clear
        case .outlined:
            return GlowlyTheme.Colors.adaptiveBorder(colorScheme)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .default, .elevated, .tinted:
            return 0
        case .outlined:
            return 1
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .default, .outlined, .tinted:
            return GlowlyTheme.Shadow.card.color
        case .elevated:
            return GlowlyTheme.Shadow.medium.color
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .default, .outlined, .tinted:
            return GlowlyTheme.Shadow.card.radius
        case .elevated:
            return GlowlyTheme.Shadow.medium.radius
        }
    }
    
    private var shadowOffset: CGSize {
        switch style {
        case .default, .outlined, .tinted:
            return GlowlyTheme.Shadow.card.offset
        case .elevated:
            return GlowlyTheme.Shadow.medium.offset
        }
    }
}

// MARK: - Card Styles
extension GlowlyCard {
    enum CardStyle {
        case `default`
        case elevated
        case outlined
        case tinted(Color)
    }
}

// MARK: - Photo Card
struct GlowlyPhotoCard: View {
    let photo: GlowlyPhoto
    var showMetadata: Bool = true
    var onTap: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        GlowlyCard(onTap: onTap) {
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                // Photo Image
                AsyncImage(url: photo.originalImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)))
                        )
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image))
                
                if showMetadata {
                    // Photo Info
                    VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xxs) {
                        HStack {
                            Text(photo.createdAt, style: .date)
                                .font(GlowlyTheme.Typography.captionFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                            
                            Spacer()
                            
                            if photo.isEnhanced {
                                Image(systemName: GlowlyTheme.Icons.sparkles)
                                    .font(.caption)
                                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                            }
                        }
                        
                        if !photo.enhancements.isEmpty {
                            Text("\(photo.enhancements.count) enhancements")
                                .font(GlowlyTheme.Typography.caption2Font)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: GlowlyTheme.Spacing.sm) {
                        if let onEdit = onEdit {
                            GlowlyIconButton(
                                icon: GlowlyTheme.Icons.edit,
                                action: onEdit,
                                style: .secondary,
                                size: .small
                            )
                        }
                        
                        if let onShare = onShare {
                            GlowlyIconButton(
                                icon: GlowlyTheme.Icons.share,
                                action: onShare,
                                style: .secondary,
                                size: .small
                            )
                        }
                        
                        Spacer()
                        
                        // Quality indicator
                        if photo.processingQuality == .high {
                            Image(systemName: GlowlyTheme.Icons.starFill)
                                .font(.caption)
                                .foregroundColor(GlowlyTheme.Colors.warning)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Feature Card
struct GlowlyFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isPremium: Bool
    var isEnabled: Bool = true
    var onTap: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GlowlyCard(
            style: isPremium ? .tinted(GlowlyTheme.Colors.accent) : .default,
            onTap: isEnabled ? onTap : nil
        ) {
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                HStack {
                    // Icon
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .frame(width: 32, height: 32)
                        .background(iconBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.sm))
                    
                    Spacer()
                    
                    // Premium Badge
                    if isPremium {
                        Image(systemName: GlowlyTheme.Icons.crown)
                            .font(.caption)
                            .foregroundColor(GlowlyTheme.Colors.warning)
                    }
                    
                    // Disabled Overlay
                    if !isEnabled {
                        Image(systemName: GlowlyTheme.Icons.lock)
                            .font(.caption)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                    }
                }
                
                // Title & Description
                VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xxs) {
                    Text(title)
                        .font(GlowlyTheme.Typography.headlineFont)
                        .foregroundColor(titleColor)
                    
                    Text(description)
                        .font(GlowlyTheme.Typography.subheadlineFont)
                        .foregroundColor(descriptionColor)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        if isPremium {
            return GlowlyTheme.Colors.warning
        } else {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        }
    }
    
    private var iconBackgroundColor: Color {
        if isPremium {
            return GlowlyTheme.Colors.warning.opacity(0.1)
        } else {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.1)
        }
    }
    
    private var titleColor: Color {
        isEnabled ? GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
    
    private var descriptionColor: Color {
        isEnabled ? GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme) : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
}

// MARK: - Enhancement Card
struct GlowlyEnhancementCard: View {
    let enhancement: Enhancement
    let isActive: Bool
    let intensity: Double
    var onToggle: (() -> Void)? = nil
    var onIntensityChange: ((Double) -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GlowlyCard(
            style: isActive ? .tinted(GlowlyTheme.Colors.adaptivePrimary(colorScheme)) : .default
        ) {
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                // Header
                HStack {
                    Image(systemName: enhancement.icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(enhancement.displayName)
                            .font(GlowlyTheme.Typography.headlineFont)
                            .foregroundColor(titleColor)
                        
                        Text(enhancement.description)
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(descriptionColor)
                    }
                    
                    Spacer()
                    
                    // Toggle
                    Toggle("", isOn: .constant(isActive))
                        .toggleStyle(SwitchToggleStyle(tint: GlowlyTheme.Colors.adaptivePrimary(colorScheme)))
                        .onChange(of: isActive) { _ in
                            onToggle?()
                        }
                }
                
                // Intensity Slider (if active)
                if isActive, let onIntensityChange = onIntensityChange {
                    VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xxs) {
                        HStack {
                            Text("Intensity")
                                .font(GlowlyTheme.Typography.footnoteFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                            
                            Spacer()
                            
                            Text("\(Int(intensity * 100))%")
                                .font(GlowlyTheme.Typography.footnoteFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        }
                        
                        Slider(value: .constant(intensity), in: 0...1) { _ in
                            onIntensityChange(intensity)
                        }
                        .accentColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        isActive ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
    }
    
    private var titleColor: Color {
        isActive ? GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
    }
    
    private var descriptionColor: Color {
        GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
}

// MARK: - View Extension for Conditional Shadow
extension View {
    @ViewBuilder
    func conditionalShadow(
        condition: Bool,
        color: Color,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        if condition {
            self.shadow(color: color, radius: radius, x: x, y: y)
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview("Cards") {
    ScrollView {
        VStack(spacing: GlowlyTheme.Spacing.lg) {
            // Basic Cards
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
            
            // Feature Card
            GlowlyFeatureCard(
                icon: GlowlyTheme.Icons.sparkles,
                title: "AI Enhancement",
                description: "Automatically enhance your photos with AI",
                isPremium: false
            )
            
            // Premium Feature Card
            GlowlyFeatureCard(
                icon: GlowlyTheme.Icons.crown,
                title: "Premium Filters",
                description: "Access exclusive premium filters",
                isPremium: true
            )
        }
        .padding()
    }
    .themed()
}