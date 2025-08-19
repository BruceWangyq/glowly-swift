//
//  ComparisonSettingsView.swift
//  Glowly
//
//  Settings and preferences for the before/after comparison system
//

import SwiftUI

// MARK: - ComparisonSettingsView
struct ComparisonSettingsView: View {
    @Binding var preferences: ComparisonPreferences
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingResetAlert = false
    @State private var hasUnsavedChanges = false
    
    private let originalPreferences: ComparisonPreferences
    
    init(preferences: Binding<ComparisonPreferences>) {
        self._preferences = preferences
        self.originalPreferences = preferences.wrappedValue
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Default Behavior Section
                defaultBehaviorSection
                
                // Interaction Settings
                interactionSection
                
                // Visual Settings
                visualSection
                
                // Export Settings
                exportSection
                
                // Performance Settings
                performanceSection
                
                // Reset Section
                resetSection
            }
            .navigationTitle("Comparison Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            preferences = originalPreferences
                        }
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        savePreferences()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will reset all comparison settings to their default values. This action cannot be undone.")
            }
        }
        .onChange(of: preferences.defaultMode) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.enableHaptics) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.autoSaveComparisons) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.watermarkEnabled) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.defaultExportFormat) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.zoomSensitivity) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.panSensitivity) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.enableMagnifier) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.magnifierSize) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.showEnhancementHighlights) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.preferredSplitDirection) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.enableAutoTransitions) { _ in hasUnsavedChanges = true }
        .onChange(of: preferences.transitionSpeed) { _ in hasUnsavedChanges = true }
    }
    
    // MARK: - Default Behavior Section
    
    private var defaultBehaviorSection: some View {
        Section {
            // Default comparison mode
            Picker("Default Mode", selection: $preferences.defaultMode) {
                ForEach(ComparisonMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            
            // Preferred split direction
            Picker("Split Direction", selection: $preferences.preferredSplitDirection) {
                ForEach(SplitDirection.allCases, id: \.self) { direction in
                    Label(direction.rawValue, systemImage: direction.icon)
                        .tag(direction)
                }
            }
            
        } header: {
            Text("Default Behavior")
        } footer: {
            Text("Choose the default comparison mode and split direction when opening comparisons.")
        }
    }
    
    // MARK: - Interaction Section
    
    private var interactionSection: some View {
        Section {
            // Haptic feedback
            Toggle("Haptic Feedback", isOn: $preferences.enableHaptics)
            
            // Zoom sensitivity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Zoom Sensitivity")
                    Spacer()
                    Text("\(Int(preferences.zoomSensitivity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $preferences.zoomSensitivity, in: 0.5...2.0, step: 0.1)
                    .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
            }
            
            // Pan sensitivity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pan Sensitivity")
                    Spacer()
                    Text("\(Int(preferences.panSensitivity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $preferences.panSensitivity, in: 0.5...2.0, step: 0.1)
                    .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
            }
            
        } header: {
            Text("Interaction")
        } footer: {
            Text("Adjust how sensitive gestures are when zooming and panning images.")
        }
    }
    
    // MARK: - Visual Section
    
    private var visualSection: some View {
        Section {
            // Enhancement highlights
            Toggle("Show Enhancement Areas", isOn: $preferences.showEnhancementHighlights)
            
            // Magnifier
            Toggle("Enable Magnifier", isOn: $preferences.enableMagnifier)
            
            if preferences.enableMagnifier {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Magnifier Size")
                        Spacer()
                        Text("\(Int(preferences.magnifierSize))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $preferences.magnifierSize, in: 60...150, step: 10)
                        .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                }
            }
            
            // Auto transitions
            Toggle("Auto Transitions", isOn: $preferences.enableAutoTransitions)
            
            if preferences.enableAutoTransitions {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transition Speed")
                        Spacer()
                        Text(speedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $preferences.transitionSpeed, in: 0.5...2.0, step: 0.1)
                        .tint(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                }
            }
            
        } header: {
            Text("Visual")
        } footer: {
            Text("Customize the visual elements and animations in the comparison view.")
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section {
            // Auto save
            Toggle("Auto-Save Comparisons", isOn: $preferences.autoSaveComparisons)
            
            // Watermark
            Toggle("Include Watermark", isOn: $preferences.watermarkEnabled)
            
            // Default export format
            Picker("Default Export Format", selection: $preferences.defaultExportFormat) {
                ForEach(ExportOptions.ExportFormat.allCases, id: \.self) { format in
                    Label(format.rawValue, systemImage: format.icon)
                        .tag(format)
                }
            }
            
        } header: {
            Text("Export")
        } footer: {
            Text("Configure default settings for exporting before/after comparisons.")
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Image Quality")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Image Quality", selection: .constant(ImageQuality.medium)) {
                    Text("High Quality").tag(ImageQuality.high)
                    Text("Balanced").tag(ImageQuality.medium)
                    Text("Performance").tag(ImageQuality.low)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Cache Management")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button("Clear Image Cache") {
                    clearImageCache()
                }
                .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
            }
            
        } header: {
            Text("Performance")
        } footer: {
            Text("Adjust performance settings to optimize the comparison experience based on your device's capabilities.")
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Section {
            Button("Reset All Settings") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
            
        } footer: {
            Text("Reset all comparison settings to their default values.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var speedDescription: String {
        switch preferences.transitionSpeed {
        case 0.5..<0.8:
            return "Slow"
        case 0.8..<1.2:
            return "Normal"
        case 1.2..<1.5:
            return "Fast"
        default:
            return "Very Fast"
        }
    }
    
    // MARK: - Actions
    
    private func savePreferences() {
        // Save preferences to UserDefaults
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "ComparisonPreferences")
        }
        
        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: NSNotification.Name("ComparisonPreferencesChanged"),
            object: preferences
        )
        
        if preferences.enableHaptics {
            HapticFeedback.success()
        }
    }
    
    private func resetToDefaults() {
        preferences = ComparisonPreferences()
        hasUnsavedChanges = true
        
        if preferences.enableHaptics {
            HapticFeedback.medium()
        }
    }
    
    private func clearImageCache() {
        // Clear the image cache
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearImageCache"),
            object: nil
        )
        
        if preferences.enableHaptics {
            HapticFeedback.light()
        }
    }
}

// MARK: - Enhanced Toggle Style
struct GlowlyToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : Color.gray.opacity(0.3))
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 27, height: 27)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                    HapticFeedback.light()
                }
        }
    }
}

// MARK: - Settings Card View
struct SettingsCard<Content: View>: View {
    let title: String
    let description: String?
    let icon: String?
    @ViewBuilder let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GlowlyTheme.Typography.headlineFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    if let description = description {
                        Text(description)
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    }
                }
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.card)
                .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                .stroke(GlowlyTheme.Colors.adaptiveBorder(colorScheme), lineWidth: 1)
        )
    }
}

// MARK: - Preference Row
struct PreferenceRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    @ViewBuilder let control: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
            }
            
            Spacer()
            
            control
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    ComparisonSettingsView(preferences: .constant(ComparisonPreferences.shared))
}