//
//  MainTabView.swift
//  Glowly
//
//  Main tab view for app navigation
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var coordinator = DIContainer.shared.resolve(MainCoordinatorProtocol.self) as! MainCoordinator
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Trial countdown at top
            TrialCountdownView()
            
            TabView(selection: $coordinator.selectedTab) {
                // Home Tab
                NavigationStack(path: $coordinator.navigationPath) {
                    HomeView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            destinationView(for: destination)
                        }
                }
                .tabItem {
                    Image(systemName: coordinator.selectedTab == .home ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(AppTab.home)
            
            // Edit Tab
            NavigationStack {
                if let photo = coordinator.currentPhotoForEditing {
                    EditView(photo: photo)
                } else {
                    PhotoSelectionView()
                }
            }
            .tabItem {
                Image(systemName: coordinator.selectedTab == .edit ? "photo.fill" : "photo")
                Text("Edit")
            }
            .tag(AppTab.edit)
            
            // Filters Tab
            NavigationStack {
                FiltersView()
            }
            .tabItem {
                Image(systemName: "camera.filters")
                Text("Filters")
            }
            .tag(AppTab.filters)
            
            // Premium Tab
            NavigationStack {
                if subscriptionManager.isPremiumUser {
                    SubscriptionStatusView()
                } else {
                    MicrotransactionStoreView()
                }
            }
            .tabItem {
                Image(systemName: coordinator.selectedTab == .premium ? "crown.fill" : "crown")
                Text(subscriptionManager.isPremiumUser ? "Premium" : "Store")
            }
            .tag(AppTab.premium)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: coordinator.selectedTab == .profile ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(AppTab.profile)
            }
        }
        .accentColor(.primary)
        .sheet(isPresented: $coordinator.showingOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $coordinator.showingPremiumUpgrade) {
            PaywallView(context: .general) {
                coordinator.showingPremiumUpgrade = false
            }
        }
        .onAppear {
            coordinator.restoreNavigationState()
        }
        .onDisappear {
            coordinator.saveNavigationState()
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .photoEdit(let photo):
            EditView(photo: photo)
        case .photoDetail(let photo):
            PhotoDetailView(photo: photo)
        case .settings:
            SettingsView()
        case .premium:
            PremiumView()
        case .help:
            HelpView()
        case .about:
            AboutView()
        }
    }
}

// MARK: - Placeholder Views

struct PhotoSelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select a Photo to Edit")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Choose a photo from your library or take a new one to start enhancing.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Select Photo") {
                // This would trigger photo selection
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FiltersView: View {
    var body: some View {
        VStack {
            Text("Filters")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Explore and create custom filters")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PremiumView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Glowly Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unlock advanced AI features and unlimited processing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "sparkles", title: "AI-Powered Enhancements")
                FeatureRow(icon: "infinity", title: "Unlimited Processing")
                FeatureRow(icon: "crown", title: "Premium Filters")
                FeatureRow(icon: "icloud", title: "Cloud Backup")
            }
            .padding()
            
            Button("Upgrade to Premium") {
                // Handle premium upgrade
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Manage your account and preferences")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: MainCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to Glowly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enhance your photos with AI-powered beauty filters")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                OnboardingFeature(
                    icon: "face.smiling",
                    title: "Smart Beauty Enhancement",
                    description: "AI analyzes your photos for personalized improvements"
                )
                
                OnboardingFeature(
                    icon: "slider.horizontal.3",
                    title: "Professional Controls",
                    description: "Fine-tune every aspect of your photos"
                )
                
                OnboardingFeature(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "All processing happens on your device"
                )
            }
            
            Button("Get Started") {
                coordinator.completeOnboarding()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Premium Upgrade")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming soon...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Premium")
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

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.bold)
        }
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Placeholder Detail Views

struct PhotoDetailView: View {
    let photo: GlowlyPhoto
    
    var body: some View {
        VStack {
            Text("Photo Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Details for photo: \(photo.id)")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Photo Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Configure your preferences")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        VStack {
            Text("Help")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get support and learn how to use Glowly")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        VStack {
            Text("About Glowly")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
        .environmentObject(DIContainer.shared.resolve(MainCoordinatorProtocol.self) as! MainCoordinator)
}