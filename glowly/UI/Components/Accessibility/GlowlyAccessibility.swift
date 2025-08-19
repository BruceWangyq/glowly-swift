//
//  GlowlyAccessibility.swift
//  Glowly
//
//  Accessibility features and UX enhancements with Glowly design system
//

import SwiftUI

// MARK: - Accessibility Modifiers
extension View {
    /// Adds comprehensive accessibility support to any view
    func glowlyAccessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        identifier: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityIdentifier(identifier ?? "")
    }
    
    /// Adds accessibility support for adjustable elements (sliders, steppers)
    func glowlyAccessibleAdjustable(
        label: String,
        value: String,
        increment: @escaping () -> Void,
        decrement: @escaping () -> Void
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    increment()
                case .decrement:
                    decrement()
                @unknown default:
                    break
                }
            }
    }
    
    /// Adds accessibility grouping for related elements
    func glowlyAccessibilityGroup(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Dynamic Type scaling support
    func glowlyDynamicType(
        minimumScaleFactor: CGFloat = 0.8,
        maximumScaleFactor: CGFloat = 2.0
    ) -> some View {
        self
            .minimumScaleFactor(minimumScaleFactor)
            .allowsTightening(true)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
    
    /// High contrast mode support
    func glowlyHighContrast(
        highContrastBackground: Color? = nil,
        highContrastForeground: Color? = nil
    ) -> some View {
        self
            .background(
                Group {
                    if let background = highContrastBackground {
                        background
                    } else {
                        EmptyView()
                    }
                }
            )
            .foregroundColor(
                highContrastForeground
            )
    }
}

// MARK: - GlowlyAccessibleSlider
struct GlowlyAccessibleSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var unit: String = ""
    var onValueChanged: ((Double) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
            // Title and Value
            HStack {
                Text(title)
                    .font(GlowlyTheme.Typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    .glowlyDynamicType()
                
                Spacer()
                
                Text("\(formattedValue)\(unit)")
                    .font(GlowlyTheme.Typography.footnoteFont)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .glowlyDynamicType()
            }
            
            // Slider with Accessibility
            HStack {
                // Decrease Button
                Button(action: decrementValue) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        )
                }
                .glowlyAccessible(
                    label: "Decrease \(title)",
                    hint: "Decreases the value by \(step)",
                    traits: .button
                )
                
                // Custom Slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                            .frame(height: 4)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                            .frame(width: geometry.size.width * progressRatio, height: 4)
                            .animation(
                                reduceMotion ? .none : GlowlyTheme.Animation.gentle,
                                value: value
                            )
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(
                                color: GlowlyTheme.Shadow.medium.color,
                                radius: GlowlyTheme.Shadow.medium.radius
                            )
                            .offset(x: (geometry.size.width - 20) * progressRatio)
                            .animation(
                                reduceMotion ? .none : GlowlyTheme.Animation.gentle,
                                value: value
                            )
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                let newValue = calculateValue(
                                    from: gestureValue.location.x,
                                    in: geometry.size.width
                                )
                                value = newValue
                                onValueChanged?(newValue)
                                HapticFeedback.selection()
                            }
                    )
                    .glowlyAccessibleAdjustable(
                        label: "\(title) slider",
                        value: "\(formattedValue) \(unit)",
                        increment: incrementValue,
                        decrement: decrementValue
                    )
                }
                .frame(height: 44)
                
                // Increase Button
                Button(action: incrementValue) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        )
                }
                .glowlyAccessible(
                    label: "Increase \(title)",
                    hint: "Increases the value by \(step)",
                    traits: .button
                )
            }
        }
        .padding(.vertical, GlowlyTheme.Spacing.xs)
    }
    
    // MARK: - Helper Methods
    
    private var progressRatio: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var formattedValue: String {
        if step < 1 {
            return String(format: "%.1f", value)
        } else {
            return "\(Int(value))"
        }
    }
    
    private func incrementValue() {
        let newValue = min(range.upperBound, value + step)
        value = newValue
        onValueChanged?(newValue)
        HapticFeedback.light()
    }
    
    private func decrementValue() {
        let newValue = max(range.lowerBound, value - step)
        value = newValue
        onValueChanged?(newValue)
        HapticFeedback.light()
    }
    
    private func calculateValue(from position: CGFloat, in width: CGFloat) -> Double {
        let ratio = max(0, min(1, position / width))
        var newValue = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
        
        // Snap to step
        newValue = round(newValue / step) * step
        
        return max(range.lowerBound, min(range.upperBound, newValue))
    }
}

// MARK: - GlowlyAccessibleCard
struct GlowlyAccessibleCard<Content: View>: View {
    let content: Content
    let accessibilityLabel: String
    let accessibilityHint: String?
    let accessibilityValue: String?
    var onTap: (() -> Void)?
    var isSelected: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
    init(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: {
                    HapticFeedback.light()
                    onTap()
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(
                    reduceMotion ? .none : GlowlyTheme.Animation.quick,
                    value: isPressed
                )
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isPressed = pressing
                }, perform: {})
            } else {
                cardContent
            }
        }
        .glowlyAccessible(
            label: accessibilityLabel,
            hint: accessibilityHint,
            value: accessibilityValue,
            traits: onTap != nil ? [.button] : []
        )
    }
    
    private var cardContent: some View {
        content
            .padding(GlowlyTheme.Spacing.md)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card))
            .shadow(
                color: GlowlyTheme.Shadow.card.color,
                radius: GlowlyTheme.Shadow.card.radius,
                x: GlowlyTheme.Shadow.card.offset.width,
                y: GlowlyTheme.Shadow.card.offset.height
            )
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.1)
        } else {
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 0
    }
}

// MARK: - GlowlyVoiceOverAnnouncement
struct GlowlyVoiceOverAnnouncement {
    static func announce(_ message: String, priority: AccessibilityAnnouncementPriority = .medium) {
        let announcement = AccessibilityAnnouncement(message: message, priority: priority)
        AccessibilityNotification.Announcement(announcement).post()
    }
    
    static func announcePageChange(_ newPage: String) {
        AccessibilityNotification.PageScrolled(newPage).post()
    }
    
    static func announceLayoutChange(focusedElement: Any? = nil) {
        AccessibilityNotification.LayoutChanged(focusedElement).post()
    }
    
    static func announceScreenChange(focusedElement: Any? = nil) {
        AccessibilityNotification.ScreenChanged(focusedElement).post()
    }
}

// MARK: - GlowlyDynamicTypePreview
struct GlowlyDynamicTypePreview<Content: View>: View {
    let content: Content
    
    @State private var selectedTypeSize: DynamicTypeSize = .medium
    
    private let typeSizes: [DynamicTypeSize] = [
        .xSmall,
        .small,
        .medium,
        .large,
        .xLarge,
        .xxLarge,
        .xxxLarge,
        .accessibility1,
        .accessibility2,
        .accessibility3
    ]
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: GlowlyTheme.Spacing.lg) {
            // Type Size Selector
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                Text("Dynamic Type Size")
                    .font(GlowlyTheme.Typography.headlineFont)
                    .fontWeight(.semibold)
                
                Picker("Type Size", selection: $selectedTypeSize) {
                    ForEach(typeSizes, id: \.self) { size in
                        Text(typeSizeDisplayName(size))
                            .tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Content Preview
            content
                .dynamicTypeSize(selectedTypeSize)
                .border(Color.gray.opacity(0.3), width: 1)
        }
        .padding()
    }
    
    private func typeSizeDisplayName(_ size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "2X Large"
        case .xxxLarge: return "3X Large"
        case .accessibility1: return "Accessibility M"
        case .accessibility2: return "Accessibility L"
        case .accessibility3: return "Accessibility XL"
        default: return "Unknown"
        }
    }
}

// MARK: - GlowlyAccessibilityPreferenceObserver
struct GlowlyAccessibilityPreferenceObserver: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityInvertColors) private var invertColors
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    let onPreferencesChanged: (AccessibilityPreferences) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: reduceMotion) { _ in
                notifyPreferencesChanged()
            }
            .onChange(of: reduceTransparency) { _ in
                notifyPreferencesChanged()
            }
            .onChange(of: invertColors) { _ in
                notifyPreferencesChanged()
            }
            .onChange(of: differentiateWithoutColor) { _ in
                notifyPreferencesChanged()
            }
            .onChange(of: colorSchemeContrast) { _ in
                notifyPreferencesChanged()
            }
            .onAppear {
                notifyPreferencesChanged()
            }
    }
    
    private func notifyPreferencesChanged() {
        let preferences = AccessibilityPreferences(
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency,
            invertColors: invertColors,
            differentiateWithoutColor: differentiateWithoutColor,
            isHighContrast: colorSchemeContrast == .increased
        )
        onPreferencesChanged(preferences)
    }
}

// MARK: - AccessibilityPreferences
struct AccessibilityPreferences {
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let invertColors: Bool
    let differentiateWithoutColor: Bool
    let isHighContrast: Bool
}

extension View {
    func glowlyAccessibilityPreferences(
        onPreferencesChanged: @escaping (AccessibilityPreferences) -> Void
    ) -> some View {
        self.modifier(GlowlyAccessibilityPreferenceObserver(onPreferencesChanged: onPreferencesChanged))
    }
}

// MARK: - GlowlyFocusGuide
struct GlowlyFocusGuide: View {
    let identifier: String
    let debugMode: Bool = false
    
    var body: some View {
        Rectangle()
            .fill(debugMode ? Color.red.opacity(0.3) : Color.clear)
            .accessibilityElement()
            .accessibilityIdentifier(identifier)
            .accessibilityLabel("Focus guide")
            .accessibilityHidden(!debugMode)
    }
}

// MARK: - Accessibility Testing Helpers
#if DEBUG
extension View {
    func accessibilitySnapshot() -> some View {
        self
            .accessibility(identifier: "test_view")
            .border(Color.blue, width: 1)
    }
    
    func accessibilityDebugInfo() -> some View {
        self
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("A11Y")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .allowsHitTesting(false)
            )
    }
}
#endif

// MARK: - Preview
#Preview("Accessibility Components") {
    VStack(spacing: GlowlyTheme.Spacing.lg) {
        GlowlyAccessibleSlider(
            title: "Brightness",
            value: .constant(75),
            range: 0...100,
            step: 1,
            unit: "%"
        )
        
        GlowlyAccessibleCard(
            accessibilityLabel: "Photo enhancement options",
            accessibilityHint: "Double tap to view enhancement tools",
            accessibilityValue: "3 tools available",
            isSelected: true,
            onTap: {}
        ) {
            VStack(alignment: .leading) {
                Text("Enhancement Tools")
                    .font(GlowlyTheme.Typography.headlineFont)
                    .fontWeight(.semibold)
                
                Text("Skin smoothing, eye brightening, and more")
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .foregroundColor(.secondary)
            }
        }
        
        GlowlyFocusGuide(identifier: "main_focus_guide", debugMode: true)
            .frame(height: 50)
    }
    .padding()
    .glowlyAccessibilityPreferences { preferences in
        print("Accessibility preferences changed: \(preferences)")
    }
    .themed()
}