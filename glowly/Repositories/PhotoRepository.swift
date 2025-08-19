//
//  PhotoRepository.swift
//  Glowly
//
//  Repository for photo data management
//

import Foundation
import SwiftUI
import CoreData

/// Protocol for photo repository operations
protocol PhotoRepositoryProtocol {
    func savePhoto(_ photo: GlowlyPhoto) async throws
    func loadPhoto(id: UUID) async throws -> GlowlyPhoto?
    func loadAllPhotos() async throws -> [GlowlyPhoto]
    func deletePhoto(id: UUID) async throws
    func updatePhoto(_ photo: GlowlyPhoto) async throws
    func searchPhotos(query: String) async throws -> [GlowlyPhoto]
    func getPhotosByDateRange(from: Date, to: Date) async throws -> [GlowlyPhoto]
    func getRecentPhotos(limit: Int) async throws -> [GlowlyPhoto]
}

/// Implementation of photo repository
@MainActor
final class PhotoRepository: PhotoRepositoryProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var photos: [GlowlyPhoto] = []
    @Published var isLoading = false
    
    private let photoService: PhotoServiceProtocol
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private let photosFileName = "glowly_photos.json"
    
    // MARK: - Initialization
    init(photoService: PhotoServiceProtocol) {
        self.photoService = photoService
        self.documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        Task {
            await loadPhotosFromDisk()
        }
    }
    
    // MARK: - Photo Operations
    
    /// Save a photo to the repository
    func savePhoto(_ photo: GlowlyPhoto) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Check if photo already exists
        if let existingIndex = photos.firstIndex(where: { $0.id == photo.id }) {
            // Update existing photo
            photos[existingIndex] = photo
        } else {
            // Add new photo
            photos.insert(photo, at: 0) // Insert at beginning for recency
        }
        
        // Save to disk
        try await savePhotosToDisk()
    }
    
    /// Load a specific photo by ID
    func loadPhoto(id: UUID) async throws -> GlowlyPhoto? {
        return photos.first { $0.id == id }
    }
    
    /// Load all photos
    func loadAllPhotos() async throws -> [GlowlyPhoto] {
        if photos.isEmpty {
            await loadPhotosFromDisk()
        }
        return photos
    }
    
    /// Delete a photo from the repository
    func deletePhoto(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Find and remove photo
        guard let index = photos.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.photoNotFound
        }
        
        let photo = photos[index]
        photos.remove(at: index)
        
        // Delete photo files if they exist
        try await deletePhotoFiles(photo)
        
        // Save updated list to disk
        try await savePhotosToDisk()
    }
    
    /// Update an existing photo
    func updatePhoto(_ photo: GlowlyPhoto) async throws {
        guard let index = photos.firstIndex(where: { $0.id == photo.id }) else {
            throw RepositoryError.photoNotFound
        }
        
        var updatedPhoto = photo
        updatedPhoto = GlowlyPhoto(
            id: photo.id,
            originalAssetIdentifier: photo.originalAssetIdentifier,
            originalImage: photo.originalImage,
            enhancedImage: photo.enhancedImage,
            thumbnailImage: photo.thumbnailImage,
            createdAt: photo.createdAt,
            updatedAt: Date(), // Update timestamp
            metadata: photo.metadata,
            enhancementHistory: photo.enhancementHistory
        )
        
        photos[index] = updatedPhoto
        try await savePhotosToDisk()
    }
    
    /// Search photos by query
    func searchPhotos(query: String) async throws -> [GlowlyPhoto] {
        let lowercasedQuery = query.lowercased()
        
        return photos.filter { photo in
            // Search in enhancement history
            let enhancementTypes = photo.enhancementHistory.map { $0.type.displayName.lowercased() }
            return enhancementTypes.contains { $0.contains(lowercasedQuery) }
        }
    }
    
    /// Get photos by date range
    func getPhotosByDateRange(from: Date, to: Date) async throws -> [GlowlyPhoto] {
        return photos.filter { photo in
            photo.createdAt >= from && photo.createdAt <= to
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Get recent photos with limit
    func getRecentPhotos(limit: Int = 20) async throws -> [GlowlyPhoto] {
        let sortedPhotos = photos.sorted { $0.updatedAt > $1.updatedAt }
        return Array(sortedPhotos.prefix(limit))
    }
    
    // MARK: - Disk Operations
    
    private func savePhotosToDisk() async throws {
        let photosFileURL = documentsURL.appendingPathComponent(photosFileName)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(photos)
            try data.write(to: photosFileURL)
        } catch {
            throw RepositoryError.saveToFailed(error.localizedDescription)
        }
    }
    
    private func loadPhotosFromDisk() async {
        let photosFileURL = documentsURL.appendingPathComponent(photosFileName)
        
        guard fileManager.fileExists(atPath: photosFileURL.path) else {
            photos = []
            return
        }
        
        do {
            let data = try Data(contentsOf: photosFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            photos = try decoder.decode([GlowlyPhoto].self, from: data)
        } catch {
            print("Failed to load photos from disk: \(error)")
            photos = []
        }
    }
    
    private func deletePhotoFiles(_ photo: GlowlyPhoto) async throws {
        // Delete image files if they exist locally
        let photoDirectory = documentsURL.appendingPathComponent("photos")
        
        let originalPath = photoDirectory.appendingPathComponent("\(photo.id)_original.jpg")
        let enhancedPath = photoDirectory.appendingPathComponent("\(photo.id)_enhanced.jpg")
        let thumbnailPath = photoDirectory.appendingPathComponent("\(photo.id)_thumbnail.jpg")
        
        let paths = [originalPath, enhancedPath, thumbnailPath]
        
        for path in paths {
            if fileManager.fileExists(atPath: path.path) {
                try fileManager.removeItem(at: path)
            }
        }
    }
    
    // MARK: - Statistics
    
    /// Get total number of photos
    var totalPhotosCount: Int {
        photos.count
    }
    
    /// Get total number of enhanced photos
    var enhancedPhotosCount: Int {
        photos.filter { $0.enhancedImage != nil }.count
    }
    
    /// Get most used enhancement types
    func getMostUsedEnhancements(limit: Int = 5) -> [EnhancementType] {
        let allEnhancements = photos.flatMap { $0.enhancementHistory }
        let enhancementCounts = Dictionary(grouping: allEnhancements) { $0.type }
            .mapValues { $0.count }
        
        return enhancementCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    /// Get storage usage in bytes
    func getStorageUsage() async -> Int64 {
        var totalSize: Int64 = 0
        
        for photo in photos {
            totalSize += Int64(photo.originalImage?.count ?? 0)
            totalSize += Int64(photo.enhancedImage?.count ?? 0)
            totalSize += Int64(photo.thumbnailImage?.count ?? 0)
        }
        
        return totalSize
    }
    
    // MARK: - Cleanup Operations
    
    /// Clear all photos from repository
    func clearAllPhotos() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Delete all photo files
        for photo in photos {
            try await deletePhotoFiles(photo)
        }
        
        // Clear in-memory array
        photos.removeAll()
        
        // Save empty array to disk
        try await savePhotosToDisk()
    }
    
    /// Clean up old photos (older than specified days)
    func cleanupOldPhotos(olderThanDays days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let photosToDelete = photos.filter { $0.createdAt < cutoffDate }
        
        for photo in photosToDelete {
            try await deletePhoto(id: photo.id)
        }
    }
}

// MARK: - RepositoryError

enum RepositoryError: LocalizedError {
    case photoNotFound
    case saveToFailed(String)
    case loadFailed(String)
    case invalidData
    case diskSpaceInsufficient
    
    var errorDescription: String? {
        switch self {
        case .photoNotFound:
            return "The requested photo could not be found."
        case .saveToFailed(let details):
            return "Failed to save photo: \(details)"
        case .loadFailed(let details):
            return "Failed to load photo: \(details)"
        case .invalidData:
            return "The photo data is invalid or corrupted."
        case .diskSpaceInsufficient:
            return "Not enough disk space to save the photo."
        }
    }
}