//
//  DraftManager.swift
//  Glowly
//
//  Manager for saving and managing photo drafts for re-editing
//

import Foundation
import UIKit

// MARK: - Draft Manager

@MainActor
class DraftManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var drafts: [PhotoDraft] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var lastSaveResult: DraftSaveResult?
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let draftsDirectory: URL
    private let userDefaults = UserDefaults.standard
    private let draftIndexKey = "glowly_draft_index"
    
    // MARK: - Initialization
    
    init() {
        // Create drafts directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        draftsDirectory = documentsPath.appendingPathComponent("Glowly_Drafts", isDirectory: true)
        
        createDraftsDirectoryIfNeeded()
        loadDrafts()
    }
    
    // MARK: - Public Methods
    
    /// Save a photo as a draft
    func saveDraft(
        from photo: GlowlyPhoto,
        with enhancements: [Enhancement],
        name: String? = nil,
        notes: String? = nil
    ) async throws -> PhotoDraft {
        
        isSaving = true
        
        defer {
            isSaving = false
        }
        
        do {
            // Generate preview image
            let previewImageData = try await generatePreviewImage(from: photo, with: enhancements)
            
            // Create draft
            let draft = PhotoDraft(
                originalPhoto: photo,
                currentEnhancements: enhancements,
                previewImage: previewImageData,
                name: name ?? generateDefaultDraftName(),
                notes: notes
            )
            
            // Save draft to disk
            try await saveDraftToDisk(draft)
            
            // Update in-memory collection
            drafts.append(draft)
            drafts.sort { $0.lastModified > $1.lastModified }
            
            // Update index
            updateDraftIndex()
            
            let result = DraftSaveResult(
                success: true,
                draft: draft,
                savedAt: Date()
            )
            
            lastSaveResult = result
            return draft
            
        } catch {
            let result = DraftSaveResult(
                success: false,
                error: error.localizedDescription,
                savedAt: Date()
            )
            
            lastSaveResult = result
            throw error
        }
    }
    
    /// Update an existing draft
    func updateDraft(
        _ draftId: UUID,
        with enhancements: [Enhancement],
        name: String? = nil,
        notes: String? = nil
    ) async throws -> PhotoDraft {
        
        guard let index = drafts.firstIndex(where: { $0.id == draftId }) else {
            throw DraftError.draftNotFound
        }
        
        isSaving = true
        
        defer {
            isSaving = false
        }
        
        do {
            let originalDraft = drafts[index]
            
            // Generate new preview image
            let previewImageData = try await generatePreviewImage(
                from: originalDraft.originalPhoto,
                with: enhancements
            )
            
            // Create updated draft
            let updatedDraft = PhotoDraft(
                id: originalDraft.id,
                originalPhoto: originalDraft.originalPhoto,
                currentEnhancements: enhancements,
                previewImage: previewImageData,
                lastModified: Date(),
                name: name ?? originalDraft.name,
                notes: notes ?? originalDraft.notes
            )
            
            // Save to disk
            try await saveDraftToDisk(updatedDraft)
            
            // Update in-memory collection
            drafts[index] = updatedDraft
            drafts.sort { $0.lastModified > $1.lastModified }
            
            let result = DraftSaveResult(
                success: true,
                draft: updatedDraft,
                savedAt: Date()
            )
            
            lastSaveResult = result
            return updatedDraft
            
        } catch {
            let result = DraftSaveResult(
                success: false,
                error: error.localizedDescription,
                savedAt: Date()
            )
            
            lastSaveResult = result
            throw error
        }
    }
    
    /// Load a draft for editing
    func loadDraft(_ draftId: UUID) async throws -> PhotoDraft {
        guard let draft = drafts.first(where: { $0.id == draftId }) else {
            throw DraftError.draftNotFound
        }
        
        // Verify file still exists
        let draftURL = getDraftFileURL(for: draft.id)
        guard fileManager.fileExists(atPath: draftURL.path) else {
            // Remove from collection if file is missing
            drafts.removeAll { $0.id == draftId }
            updateDraftIndex()
            throw DraftError.draftFileNotFound
        }
        
        return draft
    }
    
    /// Delete a draft
    func deleteDraft(_ draftId: UUID) async throws {
        guard let index = drafts.firstIndex(where: { $0.id == draftId }) else {
            throw DraftError.draftNotFound
        }
        
        // Delete file
        let draftURL = getDraftFileURL(for: draftId)
        try fileManager.removeItem(at: draftURL)
        
        // Remove from collection
        drafts.remove(at: index)
        updateDraftIndex()
    }
    
    /// Delete multiple drafts
    func deleteDrafts(_ draftIds: [UUID]) async throws {
        for draftId in draftIds {
            try await deleteDraft(draftId)
        }
    }
    
    /// Get draft statistics
    func getDraftStatistics() -> DraftStatistics {
        let totalDrafts = drafts.count
        let totalSize = calculateTotalDraftSize()
        let averageEnhancements = drafts.isEmpty ? 0 : Double(drafts.reduce(0) { $0 + $1.currentEnhancements.count }) / Double(totalDrafts)
        
        let categoryBreakdown = Dictionary(grouping: drafts.flatMap { $0.usedCategories }) { $0 }
            .mapValues { $0.count }
        
        return DraftStatistics(
            totalDrafts: totalDrafts,
            totalSizeBytes: totalSize,
            averageEnhancementsPerDraft: averageEnhancements,
            categoryBreakdown: categoryBreakdown,
            oldestDraft: drafts.min { $0.lastModified < $1.lastModified },
            newestDraft: drafts.max { $0.lastModified < $1.lastModified }
        )
    }
    
    /// Clean up old drafts
    func cleanupOldDrafts(olderThan days: Int = 30) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldDrafts = drafts.filter { $0.lastModified < cutoffDate }
        
        for draft in oldDrafts {
            try await deleteDraft(draft.id)
        }
    }
    
    /// Export draft as JSON
    func exportDraft(_ draftId: UUID) async throws -> URL {
        guard let draft = drafts.first(where: { $0.id == draftId }) else {
            throw DraftError.draftNotFound
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(draft)
        
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent("draft_\(draft.name)_\(draft.id.uuidString)")
            .appendingPathExtension("json")
        
        try jsonData.write(to: tempURL)
        return tempURL
    }
    
    /// Import draft from JSON
    func importDraft(from url: URL) async throws -> PhotoDraft {
        let jsonData = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var importedDraft = try decoder.decode(PhotoDraft.self, from: jsonData)
        
        // Generate new ID to avoid conflicts
        importedDraft = PhotoDraft(
            originalPhoto: importedDraft.originalPhoto,
            currentEnhancements: importedDraft.currentEnhancements,
            previewImage: importedDraft.previewImage,
            name: "\(importedDraft.name) (Imported)",
            notes: importedDraft.notes
        )
        
        // Save imported draft
        try await saveDraftToDisk(importedDraft)
        
        drafts.append(importedDraft)
        drafts.sort { $0.lastModified > $1.lastModified }
        updateDraftIndex()
        
        return importedDraft
    }
    
    // MARK: - Private Methods
    
    private func createDraftsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: draftsDirectory.path) {
            try? fileManager.createDirectory(at: draftsDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func loadDrafts() {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        // Load draft index
        guard let indexData = userDefaults.data(forKey: draftIndexKey),
              let draftIndex = try? JSONDecoder().decode([UUID].self, from: indexData) else {
            return
        }
        
        var loadedDrafts: [PhotoDraft] = []
        
        for draftId in draftIndex {
            if let draft = loadDraftFromDisk(draftId) {
                loadedDrafts.append(draft)
            }
        }
        
        drafts = loadedDrafts.sorted { $0.lastModified > $1.lastModified }
    }
    
    private func loadDraftFromDisk(_ draftId: UUID) -> PhotoDraft? {
        let draftURL = getDraftFileURL(for: draftId)
        
        guard let data = try? Data(contentsOf: draftURL),
              let draft = try? JSONDecoder().decode(PhotoDraft.self, from: data) else {
            return nil
        }
        
        return draft
    }
    
    private func saveDraftToDisk(_ draft: PhotoDraft) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(draft)
        let draftURL = getDraftFileURL(for: draft.id)
        
        try data.write(to: draftURL)
    }
    
    private func getDraftFileURL(for draftId: UUID) -> URL {
        return draftsDirectory.appendingPathComponent("\(draftId.uuidString).json")
    }
    
    private func updateDraftIndex() {
        let draftIds = drafts.map { $0.id }
        
        if let indexData = try? JSONEncoder().encode(draftIds) {
            userDefaults.set(indexData, forKey: draftIndexKey)
        }
    }
    
    private func generateDefaultDraftName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "Draft \(formatter.string(from: Date()))"
    }
    
    private func generatePreviewImage(from photo: GlowlyPhoto, with enhancements: [Enhancement]) async throws -> Data? {
        guard let originalImage = photo.originalUIImage else {
            return nil
        }
        
        // Create a simple preview by resizing the original image
        let targetSize = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let previewImage = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return previewImage.jpegData(compressionQuality: 0.7)
    }
    
    private func calculateTotalDraftSize() -> Int64 {
        var totalSize: Int64 = 0
        
        for draft in drafts {
            let draftURL = getDraftFileURL(for: draft.id)
            if let attributes = try? fileManager.attributesOfItem(atPath: draftURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return totalSize
    }
}

// MARK: - Supporting Models

struct DraftSaveResult: Codable {
    let success: Bool
    let draft: PhotoDraft?
    let error: String?
    let savedAt: Date
    
    init(success: Bool, draft: PhotoDraft? = nil, error: String? = nil, savedAt: Date) {
        self.success = success
        self.draft = draft
        self.error = error
        self.savedAt = savedAt
    }
}

struct DraftStatistics: Codable {
    let totalDrafts: Int
    let totalSizeBytes: Int64
    let averageEnhancementsPerDraft: Double
    let categoryBreakdown: [EnhancementCategory: Int]
    let oldestDraft: PhotoDraft?
    let newestDraft: PhotoDraft?
    let generatedAt: Date
    
    var totalSizeMB: Double {
        return Double(totalSizeBytes) / (1024 * 1024)
    }
    
    var mostUsedCategory: EnhancementCategory? {
        return categoryBreakdown.max { $0.value < $1.value }?.key
    }
    
    init(
        totalDrafts: Int,
        totalSizeBytes: Int64,
        averageEnhancementsPerDraft: Double,
        categoryBreakdown: [EnhancementCategory: Int],
        oldestDraft: PhotoDraft?,
        newestDraft: PhotoDraft?
    ) {
        self.totalDrafts = totalDrafts
        self.totalSizeBytes = totalSizeBytes
        self.averageEnhancementsPerDraft = averageEnhancementsPerDraft
        self.categoryBreakdown = categoryBreakdown
        self.oldestDraft = oldestDraft
        self.newestDraft = newestDraft
        self.generatedAt = Date()
    }
}

// MARK: - Draft Errors

enum DraftError: LocalizedError {
    case draftNotFound
    case draftFileNotFound
    case saveFailed(String)
    case loadFailed(String)
    case invalidDraftData
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .draftNotFound:
            return "Draft not found"
        case .draftFileNotFound:
            return "Draft file not found on disk"
        case .saveFailed(let reason):
            return "Failed to save draft: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load draft: \(reason)"
        case .invalidDraftData:
            return "Invalid draft data format"
        case .insufficientStorage:
            return "Insufficient storage space to save draft"
        }
    }
}

// MARK: - Draft Extensions

extension PhotoDraft {
    /// Create a new PhotoDraft with updated modifications
    func withUpdatedModifications(
        enhancements: [Enhancement]? = nil,
        name: String? = nil,
        notes: String? = nil
    ) -> PhotoDraft {
        return PhotoDraft(
            id: self.id,
            originalPhoto: self.originalPhoto,
            currentEnhancements: enhancements ?? self.currentEnhancements,
            previewImage: self.previewImage,
            lastModified: Date(),
            name: name ?? self.name,
            notes: notes ?? self.notes
        )
    }
    
    /// Get formatted last modified date
    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
    
    /// Get enhancement summary
    var enhancementSummary: String {
        let categories = Array(usedCategories)
        
        if categories.isEmpty {
            return "No enhancements"
        } else if categories.count == 1 {
            return categories.first?.displayName ?? "1 enhancement"
        } else {
            return "\(categories.count) enhancement types"
        }
    }
    
    /// Check if draft is recent (within last 24 hours)
    var isRecent: Bool {
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastModified > dayAgo
    }
}