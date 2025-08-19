//
//  DraftsView.swift
//  Glowly
//
//  View for managing and accessing saved photo drafts
//

import SwiftUI

// MARK: - Drafts View

struct DraftsView: View {
    @StateObject private var draftManager = DraftManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedDrafts: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingDraftDetail: PhotoDraft?
    @State private var searchText = ""
    @State private var sortOption: DraftSortOption = .lastModified
    @State private var showingSortOptions = false
    @State private var isSelectionMode = false
    
    var body: some View {
        NavigationView {
            VStack {
                if draftManager.drafts.isEmpty && !draftManager.isLoading {
                    emptyStateView
                } else {
                    draftsListView
                }
            }
            .navigationTitle("Drafts")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search drafts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            exitSelectionMode()
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isSelectionMode {
                            deleteButton
                        } else {
                            moreButton
                        }
                    }
                }
            }
            .sheet(item: $showingDraftDetail) { draft in
                DraftDetailView(draft: draft, draftManager: draftManager)
            }
            .confirmationDialog("Delete Drafts", isPresented: $showingDeleteConfirmation) {
                Button("Delete \(selectedDrafts.count) Draft\(selectedDrafts.count == 1 ? "" : "s")", role: .destructive) {
                    deleteDrafts()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete the selected drafts? This action cannot be undone.")
            }
            .overlay {
                if draftManager.isLoading {
                    ProgressView("Loading drafts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                }
            }
        }
        .onAppear {
            // Drafts are automatically loaded in DraftManager init
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                Text("No Drafts Yet")
                    .font(GlowlyTheme.Typography.title2Font)
                    .fontWeight(.semibold)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                Text("Start editing a photo and save it as a draft to continue later")
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            GlowlyButton(
                title: "Start Editing",
                action: {
                    // Navigate to photo selection
                    dismiss()
                },
                style: .primary,
                icon: "photo.badge.plus"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlowlyTheme.Colors.adaptiveBackground(colorScheme))
    }
    
    // MARK: - Drafts List View
    
    private var draftsListView: some View {
        VStack {
            // Sort and filter bar
            sortAndFilterBar
            
            // Drafts list
            List {
                ForEach(filteredAndSortedDrafts, id: \.id) { draft in
                    DraftRow(
                        draft: draft,
                        isSelected: selectedDrafts.contains(draft.id),
                        isSelectionMode: isSelectionMode,
                        onTap: {
                            if isSelectionMode {
                                toggleSelection(draft.id)
                            } else {
                                showingDraftDetail = draft
                            }
                        },
                        onLongPress: {
                            if !isSelectionMode {
                                enterSelectionMode(with: draft.id)
                            }
                        }
                    )
                }
                .onDelete { indexSet in
                    deleteDraftsAtIndexes(indexSet)
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                // Refresh drafts
            }
        }
    }
    
    // MARK: - Sort and Filter Bar
    
    private var sortAndFilterBar: some View {
        HStack {
            Text("\(filteredAndSortedDrafts.count) draft\(filteredAndSortedDrafts.count == 1 ? "" : "s")")
                .font(GlowlyTheme.Typography.captionFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
            
            Spacer()
            
            Button(action: {
                showingSortOptions = true
            }) {
                HStack(spacing: 4) {
                    Text(sortOption.displayName)
                        .font(GlowlyTheme.Typography.captionFont)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
            }
            .confirmationDialog("Sort by", isPresented: $showingSortOptions) {
                ForEach(DraftSortOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        sortOption = option
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
    }
    
    // MARK: - Toolbar Buttons
    
    private var deleteButton: some View {
        Button("Delete") {
            showingDeleteConfirmation = true
        }
        .foregroundColor(.red)
        .disabled(selectedDrafts.isEmpty)
    }
    
    private var moreButton: some View {
        Menu {
            Button("Select Multiple") {
                enterSelectionMode()
            }
            
            Divider()
            
            Button("Statistics") {
                // Show statistics
            }
            
            Button("Cleanup Old Drafts") {
                cleanupOldDrafts()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedDrafts: [PhotoDraft] {
        let filtered = searchText.isEmpty ? draftManager.drafts : draftManager.drafts.filter { draft in
            draft.name.localizedCaseInsensitiveContains(searchText) ||
            (draft.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .lastModified:
                return first.lastModified > second.lastModified
            case .name:
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .enhancementCount:
                return first.currentEnhancements.count > second.currentEnhancements.count
            case .intensity:
                return first.totalIntensity > second.totalIntensity
            }
        }
    }
    
    // MARK: - Actions
    
    private func enterSelectionMode(with initialSelection: UUID? = nil) {
        isSelectionMode = true
        selectedDrafts.removeAll()
        if let id = initialSelection {
            selectedDrafts.insert(id)
        }
        HapticFeedback.light()
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedDrafts.removeAll()
    }
    
    private func toggleSelection(_ draftId: UUID) {
        if selectedDrafts.contains(draftId) {
            selectedDrafts.remove(draftId)
        } else {
            selectedDrafts.insert(draftId)
        }
        HapticFeedback.selection()
    }
    
    private func deleteDrafts() {
        Task {
            do {
                try await draftManager.deleteDrafts(Array(selectedDrafts))
                await MainActor.run {
                    exitSelectionMode()
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
    
    private func deleteDraftsAtIndexes(_ indexSet: IndexSet) {
        let draftsToDelete = indexSet.map { filteredAndSortedDrafts[$0].id }
        
        Task {
            do {
                try await draftManager.deleteDrafts(draftsToDelete)
                await MainActor.run {
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
    
    private func cleanupOldDrafts() {
        Task {
            do {
                try await draftManager.cleanupOldDrafts(olderThan: 30)
                await MainActor.run {
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

// MARK: - Draft Row

struct DraftRow: View {
    let draft: PhotoDraft
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GlowlyTheme.Spacing.md) {
                // Selection indicator
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .font(.title3)
                        .animation(GlowlyTheme.Animation.quick, value: isSelected)
                }
                
                // Preview image
                Group {
                    if let previewData = draft.previewImage,
                       let previewImage = UIImage(data: previewData) {
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md))
                
                // Draft info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(draft.name)
                            .font(GlowlyTheme.Typography.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if draft.isRecent {
                            Circle()
                                .fill(GlowlyTheme.Colors.success)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(draft.enhancementSummary)
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    
                    Text(draft.formattedLastModified)
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                }
                
                Spacer()
                
                // Enhancement indicators
                if !draft.currentEnhancements.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(draft.currentEnhancements.count)")
                            .font(GlowlyTheme.Typography.captionFont)
                            .fontWeight(.medium)
                            .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                        
                        Text("edits")
                            .font(GlowlyTheme.Typography.caption2Font)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Draft Sort Option

enum DraftSortOption: CaseIterable {
    case lastModified
    case name
    case enhancementCount
    case intensity
    
    var displayName: String {
        switch self {
        case .lastModified:
            return "Last Modified"
        case .name:
            return "Name"
        case .enhancementCount:
            return "Enhancement Count"
        case .intensity:
            return "Total Intensity"
        }
    }
}

// MARK: - Preview

#Preview {
    DraftsView()
}