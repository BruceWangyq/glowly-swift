//
//  PaywallView.swift
//  Glowly
//
//  Beautiful paywall screen for subscription conversion
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.diContainer) var diContainer
    
    @State private var selectedTier: SubscriptionTier = .premiumMonthly
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let context: PaywallContext
    let onDismiss: () -> Void
    
    init(context: PaywallContext = .general, onDismiss: @escaping () -> Void = {}) {
        self.context = context
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.85, blue: 1.0),
                        Color(red: 1.0, green: 0.9, blue: 0.95),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.top, 20)
                        
                        // Features showcase
                        featuresSection
                            .padding(.vertical, 30)
                        
                        // Pricing options
                        pricingSection
                            .padding(.horizontal, 20)
                        
                        // CTA Button
                        ctaSection
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        // Trial information
                        trialInformation
                            .padding(.top, 20)
                        
                        // Legal links
                        legalSection
                            .padding(.vertical, 30)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // Close button
            Button(action: dismissPaywall) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .onAppear {
            trackPaywallViewed()
        }
        .onChange(of: subscriptionManager.purchaseState) { state in
            handlePurchaseStateChange(state)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon or illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.purple)
            }
            
            // Headline based on context
            VStack(spacing: 8) {
                Text(context.headline)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(context.subheadline)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            ForEach(getDisplayFeatures(), id: \.feature) { item in
                FeatureRow(
                    icon: item.icon,
                    title: item.feature.displayName,
                    description: item.feature.description,
                    isHighlighted: item.isHighlighted
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2.bold())
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                // Monthly option
                PricingOptionCard(
                    tier: .premiumMonthly,
                    isSelected: selectedTier == .premiumMonthly,
                    product: subscriptionManager.getProduct(for: .premiumMonthly),
                    trialStatus: subscriptionManager.getTrialStatus(),
                    onSelect: { selectedTier = .premiumMonthly }
                )
                
                // Yearly option with savings badge
                PricingOptionCard(
                    tier: .premiumYearly,
                    isSelected: selectedTier == .premiumYearly,
                    product: subscriptionManager.getProduct(for: .premiumYearly),
                    trialStatus: subscriptionManager.getTrialStatus(),
                    showSavings: true,
                    onSelect: { selectedTier = .premiumYearly }
                )
            }
        }
    }
    
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button(action: purchaseSelected) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(context.ctaText)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPurchasing || subscriptionManager.isLoading)
            
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
    
    private var trialInformation: some View {
        VStack(spacing: 8) {
            if case .notStarted = subscriptionManager.getTrialStatus() {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.green)
                    Text("7-day free trial, cancel anytime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }
    
    private var legalSection: some View {
        HStack(spacing: 20) {
            Button("Terms of Service") {
                showingTerms = true
                Task {
                    await subscriptionManager.trackPaywallInteraction(.termsClicked, tier: selectedTier)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button("Privacy Policy") {
                showingPrivacy = true
                Task {
                    await subscriptionManager.trackPaywallInteraction(.privacyClicked, tier: selectedTier)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSelected() {
        isPurchasing = true
        
        Task {
            await subscriptionManager.trackPaywallInteraction(.purchaseStarted, tier: selectedTier)
            
            do {
                let result = try await subscriptionManager.purchaseSubscription(selectedTier)
                
                switch result {
                case .success:
                    await subscriptionManager.trackPaywallInteraction(.purchaseCompleted, tier: selectedTier)
                    presentationMode.wrappedValue.dismiss()
                    onDismiss()
                case .cancelled:
                    break
                case .failed(let error):
                    await subscriptionManager.trackPaywallInteraction(.purchaseFailed, tier: selectedTier)
                    showError(error.localizedDescription)
                case .pending:
                    showError("Purchase is pending approval")
                }
            } catch {
                await subscriptionManager.trackPaywallInteraction(.purchaseFailed, tier: selectedTier)
                showError(error.localizedDescription)
            }
            
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            await subscriptionManager.trackPaywallInteraction(.restoreClicked, tier: nil)
            
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.isPremiumUser {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss()
                }
            } catch {
                showError("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }
    
    private func dismissPaywall() {
        Task {
            await subscriptionManager.trackPaywallInteraction(.dismissed, tier: nil)
        }
        presentationMode.wrappedValue.dismiss()
        onDismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func handlePurchaseStateChange(_ state: PurchaseState) {
        switch state {
        case .succeeded:
            isPurchasing = false
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        case .failed(let error):
            isPurchasing = false
            showError(error.localizedDescription)
        case .cancelled:
            isPurchasing = false
        default:
            break
        }
    }
    
    private func trackPaywallViewed() {
        Task {
            await subscriptionManager.trackPaywallInteraction(.viewed, tier: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDisplayFeatures() -> [(feature: PremiumFeature, icon: String, isHighlighted: Bool)] {
        let allFeatures: [(PremiumFeature, String, Bool)] = [
            (.unlimitedFilters, "camera.filters", true),
            (.unlimitedRetouch, "wand.and.stars", true),
            (.hdExport, "4k.tv", true),
            (.watermarkRemoval, "eye.slash", false),
            (.exclusiveFilters, "sparkles", false),
            (.premiumMakeupPacks, "paintbrush", false),
            (.batchProcessing, "rectangle.stack", false),
            (.cloudStorage, "icloud", false)
        ]
        
        // Show different features based on context
        switch context.type {
        case .limitReached:
            return Array(allFeatures.prefix(6))
        case .featureAccess:
            return allFeatures
        case .trial:
            return Array(allFeatures.prefix(4))
        case .general:
            return Array(allFeatures.prefix(6))
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isHighlighted ? .purple : .secondary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isHighlighted {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PricingOptionCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let product: Product?
    let trialStatus: TrialStatus
    let showSavings: Bool
    let onSelect: () -> Void
    
    init(
        tier: SubscriptionTier,
        isSelected: Bool,
        product: Product?,
        trialStatus: TrialStatus,
        showSavings: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.tier = tier
        self.isSelected = isSelected
        self.product = product
        self.trialStatus = trialStatus
        self.showSavings = showSavings
        self.onSelect = onSelect
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.displayName)
                            .font(.subheadline.bold())
                        
                        if showSavings {
                            Text("SAVE 50%")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    Text(tier.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if case .notStarted = trialStatus, tier == .premiumMonthly {
                        Text("Includes 7-day free trial")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product?.displayPrice ?? tier.price.formatted(.currency(code: "USD")))
                        .font(.headline.bold())
                    
                    if tier == .premiumYearly {
                        Text("$2.50/month")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Paywall Context

struct PaywallContext {
    let type: PaywallType
    let headline: String
    let subheadline: String
    let ctaText: String
    
    enum PaywallType {
        case general
        case limitReached
        case featureAccess
        case trial
    }
    
    static let general = PaywallContext(
        type: .general,
        headline: "Unlock Your Creative Potential",
        subheadline: "Get unlimited access to all premium filters, tools, and features",
        ctaText: "Start Free Trial"
    )
    
    static let filterLimitReached = PaywallContext(
        type: .limitReached,
        headline: "You've Reached Your Daily Limit",
        subheadline: "Upgrade to apply unlimited filters and enhance photos without restrictions",
        ctaText: "Upgrade Now"
    )
    
    static let exportLimitReached = PaywallContext(
        type: .limitReached,
        headline: "Export Limit Reached",
        subheadline: "Save unlimited photos in HD quality with Premium",
        ctaText: "Get Unlimited Exports"
    )
    
    static let premiumFeature = PaywallContext(
        type: .featureAccess,
        headline: "Premium Feature",
        subheadline: "This feature is available with Premium subscription",
        ctaText: "Unlock Premium"
    )
    
    static let trialEnding = PaywallContext(
        type: .trial,
        headline: "Your Trial Is Ending Soon",
        subheadline: "Continue enjoying all premium features without interruption",
        ctaText: "Continue with Premium"
    )
}