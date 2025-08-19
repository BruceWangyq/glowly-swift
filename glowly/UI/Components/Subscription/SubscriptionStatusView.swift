//
//  SubscriptionStatusView.swift
//  Glowly
//
//  Subscription status and management interface
//

import SwiftUI

struct SubscriptionStatusView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @StateObject private var featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as! FeatureGatingService
    
    @State private var showingPaywall = false
    @State private var showingCancellation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current status card
                    currentStatusCard
                    
                    // Usage summary
                    if !subscriptionManager.isPremiumUser {
                        usageSummaryCard
                    }
                    
                    // Features overview
                    featuresOverviewCard
                    
                    // Billing and management
                    billingManagementCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshSubscriptionStatus()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: .general) {
                showingPaywall = false
            }
        }
        .sheet(isPresented: $showingCancellation) {
            SubscriptionCancellationView()
        }
    }
    
    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(subscriptionManager.currentTier.displayName)
                            .font(.title2.bold())
                            .foregroundColor(subscriptionManager.isPremiumUser ? .purple : .secondary)
                        
                        if subscriptionManager.subscriptionStatus.isInTrialPeriod {
                            Text("TRIAL")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subscriptionStatusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                statusIndicator
            }
            
            if subscriptionManager.isPremiumUser {
                premiumStatusDetails
            } else {
                upgradePrompt
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(subscriptionManager.isPremiumUser ? 
                     LinearGradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                     Color.gray.opacity(0.05))
        )
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(subscriptionManager.isPremiumUser ? Color.green : Color.gray)
            .frame(width: 12, height: 12)
    }
    
    private var subscriptionStatusDescription: String {
        if subscriptionManager.subscriptionStatus.isInTrialPeriod {
            if let daysLeft = subscriptionManager.trialDaysRemaining {
                return "\(daysLeft) days left in trial"
            }
        }
        
        if subscriptionManager.isPremiumUser {
            if let expirationDate = subscriptionManager.subscriptionStatus.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Renews on \(formatter.string(from: expirationDate))"
            }
        }
        
        return subscriptionManager.currentTier.description
    }
    
    private var premiumStatusDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("All premium features unlocked")
                    .font(.subheadline.bold())
                Spacer()
            }
            
            if subscriptionManager.subscriptionStatus.isInTrialPeriod,
               let daysLeft = subscriptionManager.trialDaysRemaining {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Trial ends in \(daysLeft) days")
                        .font(.subheadline)
                    Spacer()
                    
                    Button("Manage") {
                        showingCancellation = true
                    }
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var upgradePrompt: some View {
        Button(action: { showingPaywall = true }) {
            HStack {
                Text("Upgrade to Premium")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var usageSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Usage")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                UsageProgressRow(
                    title: "Filters Applied",
                    current: featureGating.dailyUsage.filterApplications,
                    limit: featureGating.getUsageLimits().dailyFilterApplications,
                    icon: "camera.filters"
                )
                
                UsageProgressRow(
                    title: "Retouch Operations",
                    current: featureGating.dailyUsage.retouchOperations,
                    limit: featureGating.getUsageLimits().dailyRetouchOperations,
                    icon: "wand.and.stars"
                )
                
                UsageProgressRow(
                    title: "Photo Exports",
                    current: featureGating.dailyUsage.exports,
                    limit: featureGating.getUsageLimits().dailyExports,
                    icon: "square.and.arrow.up"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var featuresOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(getFeaturesList(), id: \.feature) { item in
                    FeatureStatusCard(
                        feature: item.feature,
                        icon: item.icon,
                        isUnlocked: item.isUnlocked
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var billingManagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing & Management")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if subscriptionManager.isPremiumUser {
                    BillingActionRow(
                        title: "Manage Subscription",
                        subtitle: "View billing details and cancel",
                        icon: "gear",
                        action: { showingCancellation = true }
                    )
                    
                    BillingActionRow(
                        title: "App Store Settings",
                        subtitle: "Manage in iOS Settings",
                        icon: "app.badge",
                        action: { openAppStoreSubscriptions() }
                    )
                } else {
                    BillingActionRow(
                        title: "Restore Purchases",
                        subtitle: "Restore previous purchases",
                        icon: "arrow.clockwise",
                        action: { restorePurchases() }
                    )
                    
                    BillingActionRow(
                        title: "Start Free Trial",
                        subtitle: "Try Premium for 7 days",
                        icon: "gift",
                        action: { showingPaywall = true }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFeaturesList() -> [(feature: PremiumFeature, icon: String, isUnlocked: Bool)] {
        [
            (.unlimitedFilters, "camera.filters", subscriptionManager.checkFeatureAccess(.unlimitedFilters)),
            (.unlimitedRetouch, "wand.and.stars", subscriptionManager.checkFeatureAccess(.unlimitedRetouch)),
            (.hdExport, "4k.tv", subscriptionManager.checkFeatureAccess(.hdExport)),
            (.watermarkRemoval, "eye.slash", subscriptionManager.checkFeatureAccess(.watermarkRemoval)),
            (.exclusiveFilters, "sparkles", subscriptionManager.checkFeatureAccess(.exclusiveFilters)),
            (.premiumMakeupPacks, "paintbrush", subscriptionManager.checkFeatureAccess(.premiumMakeupPacks)),
            (.batchProcessing, "rectangle.stack", subscriptionManager.checkFeatureAccess(.batchProcessing)),
            (.cloudStorage, "icloud", subscriptionManager.checkFeatureAccess(.cloudStorage))
        ]
    }
    
    private func refreshSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            print("Failed to refresh subscription status: \(error)")
        }
    }
    
    private func restorePurchases() {
        Task {
            try await subscriptionManager.restorePurchases()
        }
    }
    
    private func openAppStoreSubscriptions() {
        if let url = subscriptionManager.getSubscriptionManagementURL() {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct UsageProgressRow: View {
    let title: String
    let current: Int
    let limit: Int
    let icon: String
    
    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(1.0, Double(current) / Double(limit))
    }
    
    private var isAtLimit: Bool {
        limit > 0 && current >= limit
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(limit == -1 ? "∞" : "\(current)/\(limit)")
                    .font(.subheadline.bold())
                    .foregroundColor(isAtLimit ? .red : .secondary)
            }
            
            if limit > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: isAtLimit ? .red : .blue))
                    .scaleEffect(y: 1.5)
            }
        }
    }
}

struct FeatureStatusCard: View {
    let feature: PremiumFeature
    let icon: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .green : .gray)
                
                Spacer()
                
                Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(isUnlocked ? "Unlocked" : "Premium")
                    .font(.caption2)
                    .foregroundColor(isUnlocked ? .green : .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

struct BillingActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}