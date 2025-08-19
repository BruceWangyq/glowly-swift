//
//  AccessibilityEnhancements.swift
//  Glowly
//
//  Comprehensive accessibility improvements for inclusive UX
//

import SwiftUI
import UIKit

// MARK: - Accessibility Manager

@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    // Accessibility states
    @Published var isVoiceOverEnabled: Bool
    @Published var isReduceMotionEnabled: Bool
    @Published var isReduceTransparencyEnabled: Bool
    @Published var preferredContentSizeCategory: ContentSizeCategory
    @Published var isBoldTextEnabled: Bool
    @Published var isButtonShapesEnabled: Bool
    @Published var isOnOffLabelsEnabled: Bool
    
    // Custom accessibility settings
    @Published var useHighContrast: Bool = false
    @Published var announceProgressUpdates: Bool = true
    @Published var hapticFeedbackEnabled: Bool = true
    
    init() {
        // Initialize with current system settings
        self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        self.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        self.preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        self.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        self.isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
        self.isOnOffLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
        
        setupAccessibilityNotifications()
    }
    
    private func setupAccessibilityNotifications() {
        let notifications: [(Notification.Name, Selector)] = [
            (UIAccessibility.voiceOverStatusDidChangeNotification, #selector(voiceOverChanged)),
            (UIAccessibility.reduceMotionStatusDidChangeNotification, #selector(reduceMotionChanged)),
            (UIAccessibility.reduceTransparencyStatusDidChangeNotification, #selector(reduceTransparencyChanged)),
            (UIContentSizeCategory.didChangeNotification, #selector(contentSizeChanged)),
            (UIAccessibility.boldTextStatusDidChangeNotification, #selector(boldTextChanged)),
            (UIAccessibility.buttonShapesEnabledStatusDidChangeNotification, #selector(buttonShapesChanged)),
            (UIAccessibility.onOffSwitchLabelsDidChangeNotification, #selector(onOffLabelsChanged))
        ]
        
        notifications.forEach { notification, selector in
            NotificationCenter.default.addObserver(
                self,
                selector: selector,
                name: notification,
                object: nil
            )
        }
    }
    
    @objc private func voiceOverChanged() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    }
    
    @objc private func reduceMotionChanged() {
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    }
    
    @objc private func reduceTransparencyChanged() {
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    }
    
    @objc private func contentSizeChanged() {
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    @objc private func boldTextChanged() {
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    }
    
    @objc private func buttonShapesChanged() {
        isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
    }
    
    @objc private func onOffLabelsChanged() {
        isOnOffLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
    }
    
    // Accessibility helpers
    func announceProgress(_ message: String) {
        guard isVoiceOverEnabled && announceProgressUpdates else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    func announceCompletion(_ message: String) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    func provideFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticFeedbackEnabled else { return }
        
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(type)
    }
}

// MARK: - Accessible UI Components

struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDestructive: Bool
    let isDisabled: Bool
    
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    init(
        _ title: String,
        icon: String? = nil,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: handleAction) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(accessibilityManager.isBoldTextEnabled ? .semibold : .medium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(accessibilityManager.isButtonShapesEnabled ? 8 : 16)
            .overlay(
                // Button shape indicator for accessibility
                RoundedRectangle(cornerRadius: accessibilityManager.isButtonShapesEnabled ? 8 : 16)
                    .stroke(borderColor, lineWidth: accessibilityManager.isButtonShapesEnabled ? 2 : 0)
            )
        }
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityTraits(accessibilityTraits)
        .accessibilityAddTraits(isDestructive ? .isDestructive : [])
        .dynamicTypeSize(.accessibility1...(.accessibility5))
    }
    
    private var foregroundColor: Color {
        if isDisabled {
            return .secondary
        } else if isDestructive {
            return accessibilityManager.useHighContrast ? .white : .red
        } else {
            return accessibilityManager.useHighContrast ? .white : .primary
        }
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        } else if isDestructive {
            return accessibilityManager.useHighContrast ? .red : Color.red.opacity(0.1)
        } else {
            return accessibilityManager.useHighContrast ? .blue : Color.blue.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isDestructive {
            return .red
        } else {
            return .blue
        }
    }
    
    private var accessibilityLabel: String {
        return title
    }
    
    private var accessibilityHint: String? {
        if isDestructive {
            return "Double tap to \(title.lowercased()). This action cannot be undone."
        } else {
            return "Double tap to \(title.lowercased())"
        }
    }
    
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = .isButton
        
        if isDisabled {
            traits.insert(.isNotEnabled)
        }
        
        return traits
    }
    
    private func handleAction() {
        accessibilityManager.provideFeedback(isDestructive ? .warning : .success)
        action()
    }
}

// MARK: - Accessible Progress Indicator

struct AccessibleProgressView: View {
    let progress: Double?
    let message: String
    let stage: String?
    
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @State private var lastAnnouncedProgress: Int = -1
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress indicator
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 8)
                    .accessibilityValue(progressDescription)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            }
            
            // Message
            VStack(spacing: 4) {
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if let stage = stage {
                    Text(stage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .onChange(of: progress) { _, newProgress in
            announceProgressIfNeeded(newProgress)
        }
    }
    
    private var progressDescription: String {
        guard let progress = progress else { return "In progress" }
        return "\(Int(progress * 100)) percent complete"
    }
    
    private var accessibilityLabel: String {
        return message
    }
    
    private var accessibilityValue: String {
        if let progress = progress {
            return progressDescription
        } else {
            return "In progress"
        }
    }
    
    private func announceProgressIfNeeded(_ progress: Double?) {
        guard let progress = progress else { return }
        
        let currentProgress = Int(progress * 100)
        let shouldAnnounce = currentProgress % 25 == 0 && currentProgress != lastAnnouncedProgress
        
        if shouldAnnounce {
            accessibilityManager.announceProgress("\(currentProgress) percent complete")
            lastAnnouncedProgress = currentProgress
        }
        
        if currentProgress == 100 && lastAnnouncedProgress != 100 {
            accessibilityManager.announceCompletion("Enhancement complete")
            lastAnnouncedProgress = 100
        }
    }
}

// MARK: - Accessible Photo Enhancement View

struct AccessiblePhotoView: View {
    let originalImage: Image
    let enhancedImage: Image?
    let isProcessing: Bool
    let enhancementDescription: String?
    
    @State private var showingComparison = false
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    var body: some View {
        ZStack {
            // Photo display
            Group {
                if showingComparison && enhancedImage != nil {
                    HStack(spacing: 2) {
                        VStack {
                            Text("Original")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            originalImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        
                        VStack {
                            Text("Enhanced")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            enhancedImage!
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                } else {
                    (enhancedImage ?? originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(photoAccessibilityLabel)
            .accessibilityHint(photoAccessibilityHint)
            .accessibilityAddTraits(.isImage)
            
            // Processing overlay
            if isProcessing {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .accessibilityHidden(true)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Enhancing photo...")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 16)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Enhancing photo in progress")
            }
        }
        .onTapGesture {
            if enhancedImage != nil {
                toggleComparison()
            }
        }
        .accessibilityAction(named: "Compare with original") {
            if enhancedImage != nil {
                toggleComparison()
            }
        }
    }
    
    private var photoAccessibilityLabel: String {
        if showingComparison {
            return "Before and after comparison of enhanced photo"
        } else if enhancedImage != nil {
            return "Enhanced photo"
        } else {
            return "Original photo"
        }
    }
    
    private var photoAccessibilityHint: String? {
        if enhancedImage != nil {
            return showingComparison ? 
                "Showing before and after comparison. Double tap to show enhanced photo only." :
                "Double tap to compare with original photo"
        } else {
            return nil
        }
    }
    
    private func toggleComparison() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingComparison.toggle()
        }
        
        let message = showingComparison ? 
            "Showing before and after comparison" : 
            "Showing enhanced photo"
        
        accessibilityManager.announceProgress(message)
        accessibilityManager.provideFeedback(.selection)
    }
}

// MARK: - Accessible Enhancement Controls

struct AccessibleSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let description: String?
    let icon: String?
    
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                }
                
                Text(label)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.0f", value))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(label)
                .accessibilityValue(accessibilityValue)
                .accessibilityAdjustableAction { direction in
                    let adjustment = step * (direction == .increment ? 1 : -1)
                    let newValue = min(max(value + adjustment, range.lowerBound), range.upperBound)
                    value = newValue
                    
                    // Announce value change
                    let announcement = "\(label): \(String(format: "%.0f", value))"
                    accessibilityManager.announceProgress(announcement)
                }
        }
    }
    
    private var accessibilityValue: String {
        return String(format: "%.0f out of %.0f", value, range.upperBound)
    }
}

// MARK: - Accessible Tab View

struct AccessibleTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void
    
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    var body: some View {
        Button(action: handleAction) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: isSelected ? "\(icon).fill" : icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .secondary)
                    
                    if let badgeCount = badgeCount, badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to switch to \(title) tab")
        .accessibilityTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAddTraits(.isTabButton)
    }
    
    private var accessibilityLabel: String {
        var label = title
        
        if let badgeCount = badgeCount, badgeCount > 0 {
            label += ", \(badgeCount) notifications"
        }
        
        if isSelected {
            label += ", selected"
        }
        
        return label
    }
    
    private func handleAction() {
        accessibilityManager.provideFeedback(.selection)
        action()
    }
}

// MARK: - Dynamic Type Support

extension View {
    func accessibleFont(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        self.font(.system(textStyle, design: .default, weight: weight))
    }
    
    func accessiblePadding() -> some View {
        self.dynamicTypeSize(.xSmall...(.accessibility5)) { content in
            content.padding(.horizontal, 16)
                   .padding(.vertical, 12)
        }
    }
}

// MARK: - Accessibility Testing Helper

struct AccessibilityTestingOverlay: View {
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @State private var showingAccessibilityInfo = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button("A11y Info") {
                    showingAccessibilityInfo.toggle()
                }
                .font(.caption)
                .padding(8)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAccessibilityInfo) {
            AccessibilityInfoView()
        }
    }
}

struct AccessibilityInfoView: View {
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("System Settings") {
                    AccessibilityInfoRow(
                        title: "VoiceOver",
                        value: accessibilityManager.isVoiceOverEnabled
                    )
                    AccessibilityInfoRow(
                        title: "Reduce Motion",
                        value: accessibilityManager.isReduceMotionEnabled
                    )
                    AccessibilityInfoRow(
                        title: "Bold Text",
                        value: accessibilityManager.isBoldTextEnabled
                    )
                    AccessibilityInfoRow(
                        title: "Button Shapes",
                        value: accessibilityManager.isButtonShapesEnabled
                    )
                }
                
                Section("Content Size") {
                    Text("Category: \(accessibilityManager.preferredContentSizeCategory.rawValue)")
                }
            }
            .navigationTitle("Accessibility Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AccessibilityInfoRow: View {
    let title: String
    let value: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ? "On" : "Off")
                .foregroundColor(value ? .green : .red)
        }
    }
}

// MARK: - Preview

#Preview("Accessible Components") {
    VStack(spacing: 20) {
        AccessibleButton("Enhance Photo", icon: "sparkles") {
            print("Enhance tapped")
        }
        .environmentObject(AccessibilityManager.shared)
        
        AccessibleProgressView(
            progress: 0.7,
            message: "Enhancing your photo",
            stage: "Applying beauty filters"
        )
        .environmentObject(AccessibilityManager.shared)
        
        AccessibleSlider(
            value: .constant(50),
            range: 0...100,
            step: 1,
            label: "Brightness",
            description: "Adjust the overall brightness of your photo",
            icon: "sun.max"
        )
        .environmentObject(AccessibilityManager.shared)
    }
    .padding()
}