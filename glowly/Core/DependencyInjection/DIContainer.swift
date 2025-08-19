//
//  DIContainer.swift
//  Glowly
//
//  Dependency Injection Container for managing app dependencies
//

import Foundation
import SwiftUI

/// Protocol for dependency injection container
protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T
}

/// Main dependency injection container
final class DIContainer: DIContainerProtocol, ObservableObject {
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    private var instances: [String: Any] = [:]
    
    private init() {
        registerDependencies()
    }
    
    /// Register a dependency with its factory method
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Register a singleton dependency
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check if we have a cached singleton instance
        if let instance = instances[key] as? T {
            return instance
        }
        
        // Create new instance from factory
        guard let factory = factories[key] else {
            fatalError("Dependency \(key) not registered")
        }
        
        guard let instance = factory() as? T else {
            fatalError("Failed to create instance of \(key)")
        }
        
        // Cache singleton instances
        instances[key] = instance
        return instance
    }
    
    /// Register all app dependencies
    private func registerDependencies() {
        // Services
        registerSingleton(PhotoServiceProtocol.self) {
            PhotoService()
        }
        
        registerSingleton(CameraServiceProtocol.self) {
            CameraService()
        }
        
        registerSingleton(PhotoImportServiceProtocol.self) {
            PhotoImportService(
                imageProcessingService: self.resolve(ImageProcessingService.self) as! ImageProcessingService,
                analyticsService: self.resolve(AnalyticsServiceProtocol.self)
            )
        }
        
        registerSingleton(ImageProcessingServiceProtocol.self) {
            ImageProcessingService()
        }
        
        registerSingleton(ImageProcessingService.self) {
            ImageProcessingService()
        }
        
        registerSingleton(CoreMLServiceProtocol.self) {
            CoreMLService()
        }
        
        registerSingleton(UserPreferencesServiceProtocol.self) {
            UserPreferencesService()
        }
        
        registerSingleton(AnalyticsServiceProtocol.self) {
            AnalyticsService()
        }
        
        registerSingleton(ErrorHandlingServiceProtocol.self) {
            ErrorHandlingService()
        }
        
        registerSingleton(ManualRetouchingServiceProtocol.self) {
            ManualRetouchingService()
        }
        
        // Monetization Services
        registerSingleton(StoreKitServiceProtocol.self) {
            StoreKitService()
        }
        
        registerSingleton(FeatureGatingServiceProtocol.self) {
            FeatureGatingService(
                storeKitService: self.resolve(StoreKitServiceProtocol.self)
            )
        }
        
        registerSingleton(MonetizationAnalyticsServiceProtocol.self) {
            MonetizationAnalyticsService(
                analyticsService: self.resolve(AnalyticsServiceProtocol.self)
            )
        }
        
        registerSingleton(SubscriptionManagerProtocol.self) {
            SubscriptionManager(
                storeKitService: self.resolve(StoreKitServiceProtocol.self),
                featureGatingService: self.resolve(FeatureGatingServiceProtocol.self),
                analyticsService: self.resolve(AnalyticsServiceProtocol.self)
            )
        }
        
        // Repositories
        registerSingleton(PhotoRepositoryProtocol.self) {
            PhotoRepository(
                photoService: self.resolve(PhotoServiceProtocol.self)
            )
        }
        
        // Coordinators
        register(MainCoordinatorProtocol.self) {
            MainCoordinator()
        }
    }
}

/// SwiftUI Environment key for dependency injection
struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

/// Property wrapper for dependency injection
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DIContainer, T>
    
    init(_ keyPath: KeyPath<DIContainer, T>) {
        self.keyPath = keyPath
    }
    
    var wrappedValue: T {
        DIContainer.shared[keyPath: keyPath]
    }
}

/// Property wrapper for resolving dependencies
@propertyWrapper
struct Inject<T> {
    let wrappedValue: T
    
    init() {
        self.wrappedValue = DIContainer.shared.resolve(T.self)
    }
}