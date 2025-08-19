//
//  IntegratedFilterView.swift
//  Glowly
//
//  Example of how to integrate monetization with existing filter functionality
//

import SwiftUI

/// Example filter application view with integrated monetization
struct IntegratedFilterView: View {
    let photo: GlowlyPhoto
    let availableFilters: [FilterPreset]
    
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @StateObject private var featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as! FeatureGatingService
    
    @State private var selectedFilter: FilterPreset?
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Usage limit indicator for filter applications
            UsageLimitGateView(action: .filterApplication) {
                // Photo preview
                photoPreviewSection
            }
            
            // Filter grid with premium gating
            filterGridSection
            
            // Apply button with usage tracking
            applyButtonSection
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var photoPreviewSection: some View {
        ZStack {
            // Photo display
            AsyncImage(url: URL(string: photo.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(4/3, contentMode: .fit)
            }
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if isProcessing {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Applying Filter...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var filterGridSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(categorizedFilters, id: \.category) { section in
                    FilterCategorySection(
                        category: section.category,
                        filters: section.filters,
                        selectedFilter: $selectedFilter
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 120)
    }
    
    private var applyButtonSection: some View {
        VStack(spacing: 12) {
            if let filter = selectedFilter {
                Button("Apply \(filter.name)") {
                    applyFilter(filter)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isProcessing)
            }
            
            // Show upgrade prompt if needed
            if !subscriptionManager.isPremiumUser,
               !featureGating.canPerformAction(.filterApplication) {
                UpgradePromptCard(
                    context: .filterLimitReached,
                    onUpgrade: {
                        // Show paywall
                    },
                    onDismiss: {
                        // Dismiss prompt
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var categorizedFilters: [FilterCategorySection] {
        let freeFilters = availableFilters.filter { !$0.isPremium }
        let premiumFilters = availableFilters.filter { $0.isPremium }
        
        var sections: [FilterCategorySection] = []
        
        // Free filters always visible
        if !freeFilters.isEmpty {
            sections.append(FilterCategorySection(category: .free, filters: freeFilters))
        }
        
        // Premium filters - show with lock if not premium user
        if !premiumFilters.isEmpty {
            sections.append(FilterCategorySection(category: .premium, filters: premiumFilters))
        }
        
        return sections
    }
    
    private func applyFilter(_ filter: FilterPreset) {
        // Use the UsageLimitGateView to handle the action
        if let parentView = self.superview as? UsageLimitGateView<IntegratedFilterView> {
            parentView.performAction {
                await performFilterApplication(filter)
            }
        } else {
            // Fallback - direct action
            Task {
                await performFilterApplication(filter)
            }
        }
    }
    
    private func performFilterApplication(_ filter: FilterPreset) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate filter processing
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Apply the filter to the photo
        // This would integrate with your existing filter processing logic
        
        // Track analytics
        await subscriptionManager.trackPaywallInteraction(.featureUsed, tier: nil)
    }
}

// MARK: - Supporting Types

struct FilterCategorySection {
    let category: FilterCategory
    let filters: [FilterPreset]
}

enum FilterCategory {
    case free
    case premium
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }
}

struct FilterCategorySection: View {
    let category: FilterCategory
    let filters: [FilterPreset]
    @Binding var selectedFilter: FilterPreset?
    
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.id) { filter in
                        FilterThumbnailView(
                            filter: filter,
                            isSelected: selectedFilter?.id == filter.id,
                            isLocked: category == .premium && !subscriptionManager.isPremiumUser,
                            onSelect: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
            }
        }
    }
}

struct FilterThumbnailView: View {
    let filter: FilterPreset
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Thumbnail image
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: filter.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 80)
                
                // Filter name
                VStack {
                    Spacer()
                    Text(filter.name)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(4)
                
                // Premium lock overlay
                if isLocked {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                        .overlay {
                            VStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Text("PRO")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            }
                        }
                }
                
                // Selection indicator
                if isSelected && !isLocked {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple, lineWidth: 3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .gateFeature(.exclusiveFilters) {
            // Fallback when feature is locked
            print("Premium filter access denied")
        }
    }
}

// MARK: - Filter Preset Extension

extension FilterPreset {
    var isPremium: Bool {
        // Determine if filter requires premium subscription
        // This would be based on your actual filter categorization
        return ["cinematic", "professional", "exclusive"].contains(category?.lowercased() ?? "")
    }
    
    var gradientColors: [Color] {
        // Generate gradient colors based on filter type
        switch category?.lowercased() ?? "" {
        case "vintage":
            return [Color.brown.opacity(0.7), Color.orange.opacity(0.7)]
        case "cinematic":
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]
        case "portrait":
            return [Color.pink.opacity(0.7), Color.red.opacity(0.7)]
        case "fashion":
            return [Color.black.opacity(0.7), Color.gray.opacity(0.7)]
        default:
            return [Color.green.opacity(0.7), Color.teal.opacity(0.7)]
        }
    }
}

// MARK: - Usage Example

struct ExampleIntegratedFilterUsage: View {
    let photo: GlowlyPhoto
    
    var body: some View {
        // This demonstrates how to use the integrated filter view
        IntegratedFilterView(
            photo: photo,
            availableFilters: FilterPresetLibrary.shared.getAllFilters()
        )
        // The view automatically handles:
        // - Usage limit tracking for filter applications
        // - Premium feature gating for exclusive filters
        // - Upgrade prompts when limits are reached
        // - Analytics tracking for monetization events
    }
}