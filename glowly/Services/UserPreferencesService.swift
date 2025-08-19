//
//  UserPreferencesService.swift
//  Glowly
//
//  Service for managing user preferences and settings
//

import Foundation
import SwiftUI

/// Protocol for user preferences operations
protocol UserPreferencesServiceProtocol {
    func loadUserPreferences() async throws -> UserPreferences
    func saveUserPreferences(_ preferences: UserPreferences) async throws
    func resetToDefaults() async throws
    func exportSettings() async throws -> Data
    func importSettings(from data: Data) async throws
    var preferences: UserPreferences { get }
}

/// Implementation of user preferences service
@MainActor
final class UserPreferencesService: UserPreferencesServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var preferences: UserPreferences
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "glowly_user_preferences"
    
    // MARK: - Initialization
    init() {
        // Load preferences synchronously for initialization
        if let data = userDefaults.data(forKey: preferencesKey),
           let loadedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = loadedPreferences
        } else {
            self.preferences = UserPreferences()
        }
    }
    
    // MARK: - Preferences Management
    
    /// Load user preferences from storage
    func loadUserPreferences() async throws -> UserPreferences {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: UserPreferences())
                    return
                }
                
                if let data = self.userDefaults.data(forKey: self.preferencesKey) {
                    do {
                        let loadedPreferences = try JSONDecoder().decode(UserPreferences.self, from: data)
                        DispatchQueue.main.async {
                            self.preferences = loadedPreferences
                        }
                        continuation.resume(returning: loadedPreferences)
                    } catch {
                        print("Failed to decode preferences: \(error)")
                        continuation.resume(returning: UserPreferences())
                    }
                } else {
                    continuation.resume(returning: UserPreferences())
                }
            }
        }
    }
    
    /// Save user preferences to storage
    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    let data = try JSONEncoder().encode(preferences)
                    self.userDefaults.set(data, forKey: self.preferencesKey)
                    
                    DispatchQueue.main.async {
                        self.preferences = preferences
                    }
                    
                    continuation.resume()
                } catch {
                    print("Failed to encode preferences: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    /// Reset preferences to default values
    func resetToDefaults() async throws {
        let defaultPreferences = UserPreferences()
        try await saveUserPreferences(defaultPreferences)
    }
    
    /// Export settings as JSON data
    func exportSettings() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PreferencesError.serviceUnavailable)
                    return
                }
                
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(self.preferences)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: PreferencesError.exportFailed(error.localizedDescription))
                }
            }
        }
    }
    
    /// Import settings from JSON data
    func importSettings(from data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PreferencesError.serviceUnavailable)
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let importedPreferences = try decoder.decode(UserPreferences.self, from: data)
                    
                    Task { @MainActor in
                        do {
                            try await self.saveUserPreferences(importedPreferences)
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: PreferencesError.importFailed(error.localizedDescription))
                        }
                    }
                } catch {
                    continuation.resume(throwing: PreferencesError.importFailed(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Update a specific preference
    func updatePreference<T>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) async {
        var updatedPreferences = preferences
        updatedPreferences[keyPath: keyPath] = value
        
        do {
            try await saveUserPreferences(updatedPreferences)
        } catch {
            print("Failed to update preference: \(error)")
        }
    }
    
    /// Get a specific preference value
    func getPreference<T>(_ keyPath: KeyPath<UserPreferences, T>) -> T {
        return preferences[keyPath: keyPath]
    }
    
    /// Check if auto-save is enabled
    var isAutoSaveEnabled: Bool {
        preferences.autoSaveToLibrary
    }
    
    /// Check if auto-enhance is enabled
    var isAutoEnhanceEnabled: Bool {
        preferences.enableAutoEnhance
    }
    
    /// Get default enhancement intensity
    var defaultEnhancementIntensity: Float {
        preferences.defaultEnhancementIntensity
    }
    
    /// Check if haptic feedback is enabled
    var isHapticFeedbackEnabled: Bool {
        preferences.enableHapticFeedback
    }
    
    /// Check if sound effects are enabled
    var isSoundEffectsEnabled: Bool {
        preferences.enableSoundEffects
    }
    
    /// Get preferred image quality
    var preferredQuality: ImageQuality {
        preferences.preferredQuality
    }
    
    /// Check if analytics are enabled
    var isAnalyticsEnabled: Bool {
        preferences.enableAnalytics
    }
    
    /// Check if push notifications are enabled
    var isPushNotificationsEnabled: Bool {
        preferences.enablePushNotifications
    }
    
    /// Check if auto backup is enabled
    var isAutoBackupEnabled: Bool {
        preferences.autoBackup
    }
    
    /// Get interface style preference
    var interfaceStyle: InterfaceStyle {
        preferences.interfaceStyle
    }
    
    /// Get export format preference
    var exportFormat: ExportFormat {
        preferences.exportFormat
    }
}

// MARK: - PreferencesError

enum PreferencesError: LocalizedError {
    case serviceUnavailable
    case saveFailed(String)
    case loadFailed(String)
    case exportFailed(String)
    case importFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "User preferences service is unavailable."
        case .saveFailed(let details):
            return "Failed to save preferences: \(details)"
        case .loadFailed(let details):
            return "Failed to load preferences: \(details)"
        case .exportFailed(let details):
            return "Failed to export settings: \(details)"
        case .importFailed(let details):
            return "Failed to import settings: \(details)"
        case .invalidData:
            return "The provided settings data is invalid."
        }
    }
}