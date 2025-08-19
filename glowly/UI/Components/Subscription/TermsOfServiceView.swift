//
//  TermsOfServiceView.swift
//  Glowly
//
//  Terms of Service display for subscription flow
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Group {
                        sectionHeader("1. Subscription Terms")
                        sectionContent("""
                        • Subscriptions auto-renew unless cancelled at least 24 hours before the current period ends
                        • Payment will be charged to your iTunes Account at confirmation of purchase
                        • Subscriptions may be managed and auto-renewal may be turned off by going to Account Settings after purchase
                        • Any unused portion of a free trial period will be forfeited when you purchase a subscription
                        """)
                        
                        sectionHeader("2. Free Trial")
                        sectionContent("""
                        • Free trial period is 7 days for new subscribers
                        • Free trial automatically converts to paid subscription unless cancelled before trial ends
                        • Only one free trial per Apple ID
                        • Trial benefits include access to all premium features
                        """)
                        
                        sectionHeader("3. Acceptable Use")
                        sectionContent("""
                        • Use the app for lawful purposes only
                        • Do not share account credentials
                        • Respect intellectual property rights
                        • Do not attempt to reverse engineer the app
                        • Do not use for commercial redistribution without permission
                        """)
                        
                        sectionHeader("4. Content and Privacy")
                        sectionContent("""
                        • You retain ownership of photos you edit
                        • We may collect usage analytics to improve the service
                        • Photos are processed locally on your device when possible
                        • Cloud features require data transmission for processing
                        • See our Privacy Policy for detailed information
                        """)
                        
                        sectionHeader("5. Refunds and Cancellation")
                        sectionContent("""
                        • Refunds are handled through Apple's App Store policies
                        • Cancel anytime through iOS Settings > Apple ID > Subscriptions
                        • Cancellation takes effect at the end of the current billing period
                        • Access to premium features continues until subscription expires
                        """)
                        
                        sectionHeader("6. Limitation of Liability")
                        sectionContent("""
                        • Service provided "as is" without warranties
                        • We are not liable for any indirect, incidental, or consequential damages
                        • Maximum liability limited to subscription fees paid
                        • Features may change or be discontinued with notice
                        """)
                        
                        sectionHeader("7. Changes to Terms")
                        sectionContent("""
                        • Terms may be updated periodically
                        • Continued use constitutes acceptance of updated terms
                        • Significant changes will be communicated through the app
                        • Previous versions archived and available upon request
                        """)
                    }
                    
                    Text("Last updated: August 19, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    Text("For questions about these terms, contact support@glowlyapp.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
    
    private func sectionContent(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Group {
                        sectionHeader("Information We Collect")
                        sectionContent("""
                        • Photos and images you choose to edit (processed locally when possible)
                        • Device information for app optimization
                        • Usage analytics to improve features
                        • Purchase history through App Store
                        • Crash reports and performance data
                        """)
                        
                        sectionHeader("How We Use Information")
                        sectionContent("""
                        • Process photos and apply filters/effects
                        • Improve app performance and features
                        • Provide customer support
                        • Send important service updates
                        • Analyze usage patterns for optimization
                        """)
                        
                        sectionHeader("Data Storage and Processing")
                        sectionContent("""
                        • Photos processed locally on your device whenever possible
                        • Advanced AI features may require cloud processing
                        • Temporary cloud processing data deleted within 24 hours
                        • No permanent storage of your photos on our servers
                        • Analytics data anonymized and aggregated
                        """)
                        
                        sectionHeader("Sharing and Disclosure")
                        sectionContent("""
                        • We do not sell or rent your personal information
                        • Photos are never shared without your explicit consent
                        • May share aggregated, non-personal analytics data
                        • Required disclosures for legal compliance only
                        • Service providers bound by confidentiality agreements
                        """)
                        
                        sectionHeader("Your Rights and Choices")
                        sectionContent("""
                        • Request deletion of your data at any time
                        • Opt out of analytics collection in app settings
                        • Access information we have about you
                        • Correct inaccurate information
                        • Data portability for supported formats
                        """)
                        
                        sectionHeader("Security")
                        sectionContent("""
                        • Industry-standard encryption for data transmission
                        • Secure processing environments for cloud features
                        • Regular security audits and updates
                        • Limited access to personal data by employees
                        • Prompt notification of any security incidents
                        """)
                        
                        sectionHeader("Children's Privacy")
                        sectionContent("""
                        • App not intended for children under 13
                        • Do not knowingly collect data from children
                        • Parents can request deletion of child's data
                        • Age verification required for certain features
                        """)
                        
                        sectionHeader("International Data Transfers")
                        sectionContent("""
                        • Data may be processed in countries outside your residence
                        • Adequate safeguards in place for international transfers
                        • EU users protected under GDPR provisions
                        • Data processing agreements with all service providers
                        """)
                        
                        sectionHeader("Changes to Privacy Policy")
                        sectionContent("""
                        • Policy updates communicated through the app
                        • Material changes require explicit consent
                        • Historical versions available upon request
                        • Continued use indicates acceptance of updates
                        """)
                    }
                    
                    Text("Last updated: August 19, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    Text("For privacy questions, contact privacy@glowlyapp.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
    
    private func sectionContent(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SubscriptionCancellationView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingConfirmation = false
    @State private var cancellationReason = ""
    @State private var selectedReason: CancellationReason?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current subscription info
                    currentSubscriptionCard
                    
                    // Retention offer
                    if subscriptionManager.subscriptionStatus.isInTrialPeriod {
                        trialRetentionOffer
                    } else {
                        subscriptionRetentionOffer
                    }
                    
                    // Cancellation reasons
                    cancellationReasonsSection
                    
                    // What happens when you cancel
                    cancellationInfoSection
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Confirm Cancellation", isPresented: $showingConfirmation) {
            Button("Keep Subscription", role: .cancel) { }
            Button("Cancel Subscription", role: .destructive) {
                openSubscriptionSettings()
            }
        } message: {
            Text("You'll lose access to all premium features when your current period ends.")
        }
    }
    
    private var currentSubscriptionCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Subscription")
                        .font(.headline)
                    
                    Text(subscriptionManager.currentTier.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.purple)
                    
                    if let expirationDate = subscriptionManager.subscriptionStatus.expirationDate {
                        Text("Renews on \(DateFormatter.localizedString(from: expirationDate, dateStyle: .medium, timeStyle: .none))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if subscriptionManager.subscriptionStatus.isInTrialPeriod {
                    Text("TRIAL")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
    
    private var trialRetentionOffer: some View {
        VStack(spacing: 16) {
            Text("Enjoying Your Trial?")
                .font(.headline)
            
            Text("Continue with all premium features after your trial ends. Cancel anytime from iOS Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Continue with Premium") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.purple)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var subscriptionRetentionOffer: some View {
        VStack(spacing: 16) {
            Text("Before You Go...")
                .font(.headline)
            
            Text("We'd hate to see you leave! Here are some alternatives:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                RetentionOfferRow(
                    icon: "pause.circle",
                    title: "Pause Subscription",
                    subtitle: "Take a break for up to 3 months",
                    action: { /* TODO: Implement pause functionality */ }
                )
                
                RetentionOfferRow(
                    icon: "arrow.down.circle",
                    title: "Downgrade Plan",
                    subtitle: "Switch to monthly billing",
                    action: { /* TODO: Implement downgrade */ }
                )
                
                RetentionOfferRow(
                    icon: "envelope",
                    title: "Contact Support",
                    subtitle: "Let us help resolve any issues",
                    action: { /* TODO: Contact support */ }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var cancellationReasonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why are you considering cancellation?")
                .font(.headline)
            
            Text("Your feedback helps us improve the app for everyone.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(CancellationReason.allCases, id: \.rawValue) { reason in
                    CancellationReasonRow(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        onSelect: { selectedReason = reason }
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
    
    private var cancellationInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What Happens When You Cancel")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "checkmark.circle",
                    text: "Keep premium features until \(subscriptionEndDate)",
                    color: .green
                )
                
                InfoRow(
                    icon: "xmark.circle",
                    text: "Lose access to unlimited filters and tools",
                    color: .red
                )
                
                InfoRow(
                    icon: "arrow.clockwise.circle",
                    text: "Can resubscribe anytime to restore access",
                    color: .blue
                )
                
                InfoRow(
                    icon: "icloud.circle",
                    text: "Cloud storage will be reduced to free tier",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Cancel Subscription") {
                Task {
                    await subscriptionManager.cancelSubscription()
                    showingConfirmation = true
                }
            }
            .font(.subheadline.bold())
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Keep My Subscription") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.subheadline.bold())
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var subscriptionEndDate: String {
        guard let expirationDate = subscriptionManager.subscriptionStatus.expirationDate else {
            return "the end of your current period"
        }
        return DateFormatter.localizedString(from: expirationDate, dateStyle: .medium, timeStyle: .none)
    }
    
    private func openSubscriptionSettings() {
        if let url = subscriptionManager.getSubscriptionManagementURL() {
            UIApplication.shared.open(url)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Types and Views

enum CancellationReason: String, CaseIterable {
    case tooExpensive = "too_expensive"
    case notUsing = "not_using_enough"
    case technicalIssues = "technical_issues"
    case foundAlternative = "found_alternative"
    case temporaryBreak = "temporary_break"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .tooExpensive:
            return "Too expensive"
        case .notUsing:
            return "Don't use it enough"
        case .technicalIssues:
            return "Technical issues"
        case .foundAlternative:
            return "Found an alternative"
        case .temporaryBreak:
            return "Taking a break"
        case .other:
            return "Other reason"
        }
    }
}

struct CancellationReasonRow: View {
    let reason: CancellationReason
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
                
                Text(reason.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RetentionOfferRow: View {
    let icon: String
    let title: String
    let subtitle: String
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

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}