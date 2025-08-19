//
//  DraftDetailView.swift
//  Glowly
//
//  Detailed view for managing individual photo drafts
//

import SwiftUI

// MARK: - Draft Detail View

struct DraftDetailView: View {
    let draft: PhotoDraft
    let draftManager: DraftManager
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editedName: String
    @State private var editedNotes: String
    @State private var showingDeleteConfirmation = false
    @State private var showingExportOptions = false
    @State private var showingEditPhoto = false
    @State private var showingShareSheet = false
    @State private var exportedURL: URL?
    
    init(draft: PhotoDraft, draftManager: DraftManager) {
        self.draft = draft
        self.draftManager = draftManager
        self._editedName = State(initialValue: draft.name)
        self._editedNotes = State(initialValue: draft.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: GlowlyTheme.Spacing.lg) {
                    // Preview Section
                    previewSection
                    
                    // Info Section
                    infoSection
                    
                    // Enhancement Details Section
                    enhancementDetailsSection
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Draft Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDraftChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .confirmationDialog("Delete Draft", isPresented: $showingDeleteConfirmation) {
                Button("Delete Draft", role: .destructive) {
                    deleteDraft()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this draft? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportOptions) {
                DraftExportOptionsView(draft: draft) { url in
                    exportedURL = url
                    showingShareSheet = true
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fullScreenCover(isPresented: $showingEditPhoto) {
                // Navigate to EditView with the draft's photo and enhancements
                EditView(photo: draft.originalPhoto)
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
                    if let previewData = draft.previewImage,
                       let previewImage = UIImage(data: previewData) {
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    } else if let originalImage = draft.originalPhoto.originalUIImage {
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                                    
                                    Text("No Preview Available")
                                        .font(GlowlyTheme.Typography.captionFont)
                                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                                }
                            )
                    }
                    
                    // Enhancement indicator
                    if !draft.currentEnhancements.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                    Text("\(draft.currentEnhancements.count) edits")
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
                .frame(height: 300)
                .cornerRadius(GlowlyTheme.CornerRadius.card)
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Draft Information")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlowlyCard {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        TextField("Draft name", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        TextField("Add notes about this draft...", text: $editedNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(spacing: 8) {
                        InfoRow(title: "Created", value: formatDate(draft.lastModified))
                        InfoRow(title: "Last Modified", value: draft.formattedLastModified)
                        InfoRow(title: "Total Enhancements", value: "\(draft.currentEnhancements.count)")
                        InfoRow(title: "Total Intensity", value: String(format: "%.1f", draft.totalIntensity))
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Enhancement Details Section
    
    private var enhancementDetailsSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Enhancement Details")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if draft.currentEnhancements.isEmpty {
                GlowlyCard {
                    VStack(spacing: GlowlyTheme.Spacing.sm) {
                        Image(systemName: "wand.and.stars")
                            .font(.title2)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        
                        Text("No Enhancements Applied")
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        Text("This draft contains the original photo without any enhancements")
                            .font(GlowlyTheme.Typography.captionFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                GlowlyCard {
                    LazyVStack(spacing: GlowlyTheme.Spacing.sm) {
                        ForEach(draft.currentEnhancements, id: \.id) { enhancement in
                            EnhancementRow(enhancement: enhancement)
                            
                            if enhancement.id != draft.currentEnhancements.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
                
                // Enhancement categories summary
                if !draft.usedCategories.isEmpty {
                    GlowlyCard {
                        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                            Text("Enhancement Categories")
                                .font(GlowlyTheme.Typography.subheadlineFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(draft.usedCategories).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { category in
                                    CategoryChip(category: category)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            Text("Actions")
                .font(GlowlyTheme.Typography.headlineFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                // Continue editing
                GlowlyButton(
                    title: "Continue Editing",
                    action: {
                        showingEditPhoto = true
                    },
                    style: .primary,
                    size: .fullWidth,
                    icon: "photo.badge.plus"
                )
                
                // Export options
                GlowlyButton(
                    title: "Export Options",
                    action: {
                        showingExportOptions = true
                    },
                    style: .secondary,
                    size: .fullWidth,
                    icon: "square.and.arrow.up"
                )
                
                // Delete draft
                GlowlyButton(
                    title: "Delete Draft",
                    action: {
                        showingDeleteConfirmation = true
                    },
                    style: .error,
                    size: .fullWidth,
                    icon: "trash"
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        return editedName != draft.name || editedNotes != (draft.notes ?? "")
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    
    private func saveDraftChanges() {
        Task {
            do {
                _ = try await draftManager.updateDraft(
                    draft.id,
                    with: draft.currentEnhancements,
                    name: editedName.isEmpty ? nil : editedName,
                    notes: editedNotes.isEmpty ? nil : editedNotes
                )
                
                await MainActor.run {
                    dismiss()
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    HapticFeedback.error()
                    // Show error alert
                }
            }
        }
    }
    
    private func deleteDraft() {
        Task {
            do {
                try await draftManager.deleteDraft(draft.id)
                
                await MainActor.run {
                    dismiss()
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    HapticFeedback.error()
                    // Show error alert
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
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
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
        }
    }
}

struct EnhancementRow: View {
    let enhancement: Enhancement
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(enhancement.type.displayName)
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                Text(enhancement.type.category.displayName)
                    .font(GlowlyTheme.Typography.caption2Font)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(enhancement.intensity * 100))%")
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                
                if enhancement.aiGenerated {
                    Text("AI")
                        .font(GlowlyTheme.Typography.caption2Font)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                        )
                }
            }
        }
    }
}

struct CategoryChip: View {
    let category: EnhancementCategory
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            
            Text(category.displayName)
                .font(GlowlyTheme.Typography.caption2Font)
        }
        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                .stroke(GlowlyTheme.Colors.adaptiveBorder(colorScheme), lineWidth: 1)
        )
    }
}

// MARK: - Draft Export Options View

struct DraftExportOptionsView: View {
    let draft: PhotoDraft
    let onExport: (URL) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFormat: ExportFormat = .jpeg
    @State private var selectedQuality: ExportQuality = .high
    @State private var includeEnhancementData = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Quality") {
                    Picker("Quality", selection: $selectedQuality) {
                        ForEach(ExportQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Options") {
                    Toggle("Include Enhancement Data", isOn: $includeEnhancementData)
                }
                
                Section {
                    GlowlyButton(
                        title: "Export Draft",
                        action: {
                            exportDraft()
                        },
                        style: .primary,
                        size: .fullWidth,
                        icon: "square.and.arrow.up"
                    )
                }
            }
            .navigationTitle("Export Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportDraft() {
        Task {
            do {
                let draftManager = DraftManager()
                let exportURL = try await draftManager.exportDraft(draft.id)
                
                await MainActor.run {
                    onExport(exportURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    // Handle error
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DraftDetailView(
        draft: PhotoDraft(
            originalPhoto: GlowlyPhoto(
                originalImage: Data(),
                metadata: PhotoMetadata()
            ),
            currentEnhancements: [
                Enhancement(type: .skinSmoothing, intensity: 0.5),
                Enhancement(type: .eyeBrightening, intensity: 0.3)
            ],
            name: "Sample Draft",
            notes: "Testing draft functionality"
        ),
        draftManager: DraftManager()
    )
}