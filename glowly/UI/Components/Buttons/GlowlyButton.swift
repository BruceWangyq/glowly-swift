//
//  GlowlyButton.swift
//  Glowly
//
//  Core button components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyButton
struct GlowlyButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isLoading && isEnabled {
                HapticFeedback.light()
                action()
            }
        }) {
            HStack(spacing: GlowlyTheme.Spacing.xs) {
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(titleFont)
                        .fontWeight(.medium)
                }
                
                if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                }
            }
            .foregroundColor(textColor)
            .frame(height: buttonHeight)
            .frame(maxWidth: size == .fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.button)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.button))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(GlowlyTheme.Animation.buttonPress, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        case .secondary:
            return GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
        case .tertiary:
            return Color.clear
        case .success:
            return GlowlyTheme.Colors.success
        case .warning:
            return GlowlyTheme.Colors.warning
        case .error:
            return GlowlyTheme.Colors.error
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Colors.textOnPrimary
        case .secondary, .tertiary:
            return GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return Color.clear
        case .secondary:
            return GlowlyTheme.Colors.adaptiveBorder(colorScheme)
        case .tertiary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .tertiary, .success, .warning, .error:
            return 0
        case .secondary:
            return 1
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.color
        case .secondary, .tertiary:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.radius
        case .secondary, .tertiary:
            return 0
        }
    }
    
    private var shadowOffset: CGSize {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.offset
        case .secondary, .tertiary:
            return .zero
        }
    }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 52
        case .fullWidth:
            return 44
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small:
            return GlowlyTheme.Spacing.sm
        case .medium, .fullWidth:
            return GlowlyTheme.Spacing.md
        case .large:
            return GlowlyTheme.Spacing.lg
        }
    }
    
    private var titleFont: Font {
        switch size {
        case .small:
            return GlowlyTheme.Typography.footnoteFont
        case .medium, .fullWidth:
            return GlowlyTheme.Typography.bodyFont
        case .large:
            return GlowlyTheme.Typography.headlineFont
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small:
            return 14
        case .medium, .fullWidth:
            return 16
        case .large:
            return 18
        }
    }
}

// MARK: - Button Styles
extension GlowlyButton {
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case success
        case warning
        case error
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        case fullWidth
    }
    
    enum IconPosition {
        case leading
        case trailing
    }
}

// MARK: - Icon Button
struct GlowlyIconButton: View {
    let icon: String
    let action: () -> Void
    var style: GlowlyButton.ButtonStyle = .secondary
    var size: IconButtonSize = .medium
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isLoading && isEnabled {
                HapticFeedback.light()
                action()
            }
        }) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: iconColor))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(GlowlyTheme.Animation.buttonPress, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        case .secondary:
            return GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
        case .tertiary:
            return Color.clear
        case .success:
            return GlowlyTheme.Colors.success
        case .warning:
            return GlowlyTheme.Colors.warning
        case .error:
            return GlowlyTheme.Colors.error
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Colors.textOnPrimary
        case .secondary, .tertiary:
            return GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return Color.clear
        case .secondary:
            return GlowlyTheme.Colors.adaptiveBorder(colorScheme)
        case .tertiary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .tertiary, .success, .warning, .error:
            return 0
        case .secondary:
            return 1
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.color
        case .secondary, .tertiary:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.radius
        case .secondary, .tertiary:
            return 0
        }
    }
    
    private var shadowOffset: CGSize {
        switch style {
        case .primary, .success, .warning, .error:
            return GlowlyTheme.Shadow.button.offset
        case .secondary, .tertiary:
            return .zero
        }
    }
    
    private var buttonSize: CGFloat {
        switch size {
        case .small:
            return 32
        case .medium:
            return 40
        case .large:
            return 48
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small:
            return 16
        case .medium:
            return 18
        case .large:
            return 20
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            return GlowlyTheme.CornerRadius.sm
        case .medium:
            return GlowlyTheme.CornerRadius.md
        case .large:
            return GlowlyTheme.CornerRadius.lg
        }
    }
}

// MARK: - Icon Button Size
extension GlowlyIconButton {
    enum IconButtonSize {
        case small
        case medium
        case large
    }
}

// MARK: - Floating Action Button
struct GlowlyFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedback.medium()
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                            GlowlyTheme.Colors.primaryDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.6)
                .animation(GlowlyTheme.Animation.bouncy, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview
#Preview("Buttons") {
    VStack(spacing: GlowlyTheme.Spacing.lg) {
        Group {
            GlowlyButton(title: "Primary Button", action: {})
            
            GlowlyButton(
                title: "Secondary Button",
                action: {},
                style: .secondary
            )
            
            GlowlyButton(
                title: "With Icon",
                action: {},
                icon: GlowlyTheme.Icons.sparkles
            )
            
            GlowlyButton(
                title: "Loading",
                action: {},
                isLoading: true
            )
            
            GlowlyButton(
                title: "Disabled",
                action: {},
                isEnabled: false
            )
        }
        
        Group {
            HStack(spacing: GlowlyTheme.Spacing.md) {
                GlowlyIconButton(icon: GlowlyTheme.Icons.settings, action: {})
                GlowlyIconButton(icon: GlowlyTheme.Icons.share, action: {}, style: .primary)
                GlowlyIconButton(icon: GlowlyTheme.Icons.heart, action: {}, style: .error)
            }
            
            GlowlyFloatingActionButton(icon: GlowlyTheme.Icons.add, action: {})
        }
    }
    .padding()
    .themed()
}