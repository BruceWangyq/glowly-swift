//
//  FeatureGateView.swift
//  Glowly
//
//  Feature gating component to integrate with existing app features
//

import SwiftUI

/// A view modifier that gates features behind subscription requirements
struct FeatureGateModifier: ViewModifier {
    let feature: PremiumFeature
    let fallbackAction: (() -> Void)?
    
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @StateObject private var featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as! FeatureGatingService
    @State private var showingPaywall = false
    
    init(feature: PremiumFeature, fallbackAction: (() -> Void)? = nil) {
        self.feature = feature
        self.fallbackAction = fallbackAction
    }
    
    func body(content: Content) -> some View {
        Group {
            if featureGating.canAccessFeature(feature) {
                content
            } else {
                content
                    .disabled(true)
                    .overlay {
                        // Premium feature lock overlay
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Premium")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .onTapGesture {
                                showPremiumUpgrade()
                            }
                    }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: .premiumFeature) {
                showingPaywall = false
            }
        }
    }
    
    private func showPremiumUpgrade() {
        if featureGating.shouldShowUpgradePrompt(for: feature) {
            featureGating.recordUpgradePromptShown()
            showingPaywall = true
            
            Task {
                await subscriptionManager.trackPaywallInteraction(.paywallViewed, tier: nil)
            }
        } else if let fallback = fallbackAction {
            fallback()
        }
    }
}

/// A view that shows usage limits and upgrade prompts for actions
struct UsageLimitGateView<Content: View>: View {
    let action: UsageAction
    let content: () -> Content
    let onActionBlocked: (() -> Void)?
    
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @StateObject private var featureGating = DIContainer.shared.resolve(FeatureGatingServiceProtocol.self) as! FeatureGatingService
    @State private var showingPaywall = false
    @State private var showingLimitReached = false
    
    init(
        action: UsageAction,
        onActionBlocked: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.action = action
        self.onActionBlocked = onActionBlocked
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Usage indicator bar
            if !subscriptionManager.isPremiumUser {
                usageIndicatorBar
            }
            
            // Main content
            content()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: getPaywallContext()) {
                showingPaywall = false
            }
        }
        .alert("Daily Limit Reached", isPresented: $showingLimitReached) {
            Button("Upgrade to Premium") {
                showingPaywall = true
            }
            Button("OK") { }
        } message: {
            Text("You've reached your daily limit for \(action.displayName.lowercased()). Upgrade to Premium for unlimited access.")
        }
    }
    
    private var usageIndicatorBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text(action.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(featureGating.getUsageDescription(for: action))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !featureGating.canPerformAction(action) {
                    Button("Upgrade") {
                        showingPaywall = true
                    }
                    .font(.caption.bold())
                    .foregroundColor(.purple)
                }
            }
            
            // Progress bar
            ProgressView(value: featureGating.getUsageProgress(for: action))
                .progressViewStyle(LinearProgressViewStyle(
                    tint: getProgressColor()
                ))
                .scaleEffect(y: 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }
    
    private func getProgressColor() -> Color {
        let progress = featureGating.getUsageProgress(for: action)
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else if progress >= 0.6 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getPaywallContext() -> PaywallContext {
        switch action {
        case .filterApplication:
            return .filterLimitReached
        case .export:
            return .exportLimitReached
        case .retouchOperation:
            return PaywallContext(
                type: .limitReached,
                headline: "Retouch Limit Reached",
                subheadline: "Enhance unlimited photos with Premium",
                ctaText: "Get Unlimited Retouching"
            )
        }
    }
    
    func performAction(_ actionBlock: @escaping () async -> Void) {
        Task {
            if featureGating.canPerformAction(action) {
                await featureGating.recordUsage(action)
                await actionBlock()
            } else {
                // Show upgrade prompt or limit reached alert
                if featureGating.shouldShowUpgradePrompt(for: action) {
                    featureGating.recordUpgradePromptShown()
                    showingPaywall = true
                } else {
                    showingLimitReached = true
                }
                
                onActionBlocked?()
            }
        }
    }
}

/// A compact upgrade prompt component
struct UpgradePromptCard: View {
    let context: PaywallContext
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "crown.fill")
                    .foregroundColor(.purple)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(context.headline)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(context.subheadline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Button(context.ctaText) {
                    onUpgrade()
                }
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            Task {
                await subscriptionManager.trackPaywallInteraction(.viewed, tier: nil)
            }
        }
    }
}

/// Trial countdown component
struct TrialCountdownView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @State private var showingPaywall = false
    
    var body: some View {
        Group {
            if case .active(let daysRemaining) = subscriptionManager.getTrialStatus(),
               daysRemaining <= 3 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        
                        Text("Trial ends in \(daysRemaining) days")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Continue") {
                            showingPaywall = true
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    
                    if daysRemaining == 1 {
                        Text("Don't lose access to your premium features!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .sheet(isPresented: $showingPaywall) {
                    PaywallView(context: .trialEnding) {
                        showingPaywall = false
                    }
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Gates a feature behind premium subscription
    func gateFeature(_ feature: PremiumFeature, fallback: (() -> Void)? = nil) -> some View {
        modifier(FeatureGateModifier(feature: feature, fallbackAction: fallback))
    }
    
    /// Wraps content with usage limit tracking for an action
    func withUsageGate(for action: UsageAction, onBlocked: (() -> Void)? = nil) -> some View {
        UsageLimitGateView(action: action, onActionBlocked: onBlocked) {
            self
        }
    }
}