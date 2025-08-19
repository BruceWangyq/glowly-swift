//
//  glowlyApp.swift
//  Glowly
//
//  Main app entry point for Glowly beauty enhancement app
//

import SwiftUI
import AVFoundation

@main
struct GlowlyApp: App {
    @StateObject private var diContainer = DIContainer.shared
    @StateObject private var coordinator = DIContainer.shared.resolve(MainCoordinatorProtocol.self) as! MainCoordinator
    @StateObject private var coreMLService = DIContainer.shared.resolve(CoreMLServiceProtocol.self) as! CoreMLService
    @StateObject private var analyticsService = DIContainer.shared.resolve(AnalyticsServiceProtocol.self) as! AnalyticsService
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(coordinator)
                .environment(\.diContainer, diContainer)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppBecameActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - App Lifecycle
    
    private func setupApp() {
        Task {
            await initializeServices()
            await trackAppLaunch()
        }
    }
    
    private func initializeServices() async {
        // Initialize subscription system first
        do {
            await subscriptionManager.initializeSubscriptionSystem()
            print("✅ Subscription system initialized")
        } catch {
            print("❌ Failed to initialize subscription system: \(error)")
        }
        
        // Load Core ML models in background
        Task.detached(priority: .background) {
            do {
                try await coreMLService.loadModels()
                print("✅ Core ML models loaded successfully")
            } catch {
                print("❌ Failed to load Core ML models: \(error)")
            }
        }
        
        // Initialize analytics
        await analyticsService.trackSessionStart()
        
        // Request permissions if needed
        await requestPermissions()
        
        print("✅ App services initialized")
    }
    
    private func requestPermissions() async {
        // Request photo library permission
        let photoService = DIContainer.shared.resolve(PhotoServiceProtocol.self)
        let hasPhotoPermission = await photoService.requestPhotoLibraryPermission()
        
        if hasPhotoPermission {
            print("✅ Photo library permission granted")
        } else {
            print("⚠️ Photo library permission denied")
        }
        
        // Request camera permission
        let hasCameraPermission = await photoService.requestCameraPermission()
        
        if hasCameraPermission {
            print("✅ Camera permission granted")
        } else {
            print("⚠️ Camera permission denied")
        }
    }
    
    private func trackAppLaunch() async {
        await analyticsService.trackAppLaunch()
    }
    
    private func handleAppBecameActive() {
        Task {
            await analyticsService.trackSessionStart()
        }
    }
    
    private func handleAppWillResignActive() {
        Task {
            await analyticsService.trackSessionEnd()
            coordinator.saveNavigationState()
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        let handled = coordinator.handleDeepLink(url)
        
        if handled {
            print("✅ Deep link handled: \(url)")
        } else {
            print("⚠️ Unhandled deep link: \(url)")
        }
    }
}
