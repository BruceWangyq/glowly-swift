//
//  GlowlyAlert.swift
//  Glowly
//
//  Alert and toast components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyAlert
struct GlowlyAlert: View {
    let title: String
    let message: String?
    let type: AlertType
    let primaryAction: AlertAction?
    let secondaryAction: AlertAction?
    var isPresented: Binding<Bool>
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isPresented.wrappedValue {
            ZStack {
                // Background Overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(GlowlyTheme.Animation.standard) {
                            isPresented.wrappedValue = false
                        }
                    }
                
                // Alert Content
                VStack(spacing: GlowlyTheme.Spacing.lg) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(type.color)
                    
                    // Title and Message
                    VStack(spacing: GlowlyTheme.Spacing.sm) {
                        Text(title)
                            .font(GlowlyTheme.Typography.title3Font)
                            .fontWeight(.semibold)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                            .multilineTextAlignment(.center)
                        
                        if let message = message {
                            Text(message)
                                .font(GlowlyTheme.Typography.bodyFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Actions
                    VStack(spacing: GlowlyTheme.Spacing.sm) {
                        if let primaryAction = primaryAction {
                            GlowlyButton(
                                title: primaryAction.title,
                                action: {
                                    primaryAction.action()
                                    withAnimation(GlowlyTheme.Animation.standard) {
                                        isPresented.wrappedValue = false
                                    }
                                },
                                style: primaryAction.style.buttonStyle,
                                size: .fullWidth
                            )
                        }
                        
                        if let secondaryAction = secondaryAction {
                            GlowlyButton(
                                title: secondaryAction.title,
                                action: {
                                    secondaryAction.action()
                                    withAnimation(GlowlyTheme.Animation.standard) {
                                        isPresented.wrappedValue = false
                                    }
                                },
                                style: secondaryAction.style.buttonStyle,
                                size: .fullWidth
                            )
                        }
                    }
                }
                .padding(GlowlyTheme.Spacing.xl)
                .background(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.modal))
                .shadow(
                    color: GlowlyTheme.Shadow.strong.color,
                    radius: GlowlyTheme.Shadow.strong.radius,
                    x: GlowlyTheme.Shadow.strong.offset.width,
                    y: GlowlyTheme.Shadow.strong.offset.height
                )
                .padding(.horizontal, GlowlyTheme.Spacing.xl)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(GlowlyTheme.Animation.standard, value: isPresented.wrappedValue)
        }
    }
}

// MARK: - Alert Types and Actions
extension GlowlyAlert {
    enum AlertType {
        case success
        case warning
        case error
        case info
        case confirmation
        
        var icon: String {
            switch self {
            case .success:
                return GlowlyTheme.Icons.checkmarkCircleFill
            case .warning:
                return GlowlyTheme.Icons.warning
            case .error:
                return GlowlyTheme.Icons.error
            case .info:
                return GlowlyTheme.Icons.info
            case .confirmation:
                return GlowlyTheme.Icons.questionmark + ".circle"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return GlowlyTheme.Colors.success
            case .warning:
                return GlowlyTheme.Colors.warning
            case .error:
                return GlowlyTheme.Colors.error
            case .info:
                return GlowlyTheme.Colors.secondary
            case .confirmation:
                return GlowlyTheme.Colors.primary
            }
        }
    }
    
    struct AlertAction {
        let title: String
        let style: ActionStyle
        let action: () -> Void
        
        enum ActionStyle {
            case primary
            case secondary
            case destructive
            
            var buttonStyle: GlowlyButton.ButtonStyle {
                switch self {
                case .primary:
                    return .primary
                case .secondary:
                    return .secondary
                case .destructive:
                    return .error
                }
            }
        }
    }
}

// MARK: - GlowlyToast
struct GlowlyToast: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    var isPresented: Binding<Bool>
    var onTap: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var timer: Timer?
    
    var body: some View {
        if isPresented.wrappedValue {
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(type.foregroundColor)
                
                // Message
                Text(message)
                    .font(GlowlyTheme.Typography.bodyFont)
                    .foregroundColor(type.foregroundColor)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                // Dismiss Button
                Button(action: {
                    withAnimation(GlowlyTheme.Animation.quick) {
                        isPresented.wrappedValue = false
                    }
                }) {
                    Image(systemName: GlowlyTheme.Icons.close)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(type.foregroundColor.opacity(0.7))
                }
            }
            .padding(.horizontal, GlowlyTheme.Spacing.md)
            .padding(.vertical, GlowlyTheme.Spacing.sm)
            .background(type.backgroundColor(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.md))
            .shadow(
                color: GlowlyTheme.Shadow.medium.color,
                radius: GlowlyTheme.Shadow.medium.radius,
                x: GlowlyTheme.Shadow.medium.offset.width,
                y: GlowlyTheme.Shadow.medium.offset.height
            )
            .onTapGesture {
                onTap?()
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        guard duration > 0 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            withAnimation(GlowlyTheme.Animation.quick) {
                isPresented.wrappedValue = false
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Toast Type
extension GlowlyToast {
    enum ToastType {
        case success
        case warning
        case error
        case info
        
        var icon: String {
            switch self {
            case .success:
                return GlowlyTheme.Icons.checkmarkCircle
            case .warning:
                return GlowlyTheme.Icons.warning
            case .error:
                return GlowlyTheme.Icons.error
            case .info:
                return GlowlyTheme.Icons.info
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .success:
                return .white
            case .warning:
                return GlowlyTheme.Colors.textPrimary
            case .error:
                return .white
            case .info:
                return .white
            }
        }
        
        func backgroundColor(_ colorScheme: ColorScheme) -> Color {
            switch self {
            case .success:
                return GlowlyTheme.Colors.success
            case .warning:
                return GlowlyTheme.Colors.warning
            case .error:
                return GlowlyTheme.Colors.error
            case .info:
                return GlowlyTheme.Colors.secondary
            }
        }
    }
}

// MARK: - GlowlyBanner
struct GlowlyBanner: View {
    let title: String
    let message: String?
    let type: BannerType
    let action: BannerAction?
    var isPresented: Binding<Bool>
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isPresented.wrappedValue {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: GlowlyTheme.Spacing.sm) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(type.accentColor)
                    
                    // Content
                    VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xxs) {
                        Text(title)
                            .font(GlowlyTheme.Typography.headlineFont)
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        
                        if let message = message {
                            Text(message)
                                .font(GlowlyTheme.Typography.bodyFont)
                                .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        }
                        
                        if let action = action {
                            Button(action.title) {
                                action.action()
                                withAnimation(GlowlyTheme.Animation.standard) {
                                    isPresented.wrappedValue = false
                                }
                            }
                            .font(GlowlyTheme.Typography.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(type.accentColor)
                            .padding(.top, GlowlyTheme.Spacing.xs)
                        }
                    }
                    
                    Spacer()
                    
                    // Dismiss Button
                    Button(action: {
                        withAnimation(GlowlyTheme.Animation.standard) {
                            isPresented.wrappedValue = false
                        }
                    }) {
                        Image(systemName: GlowlyTheme.Icons.close)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                    }
                }
                .padding(GlowlyTheme.Spacing.md)
                .background(type.backgroundColor(colorScheme))
                .overlay(
                    Rectangle()
                        .fill(type.accentColor)
                        .frame(width: 4),
                    alignment: .leading
                )
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top),
                removal: .move(edge: .top)
            ))
        }
    }
}

// MARK: - Banner Type and Action
extension GlowlyBanner {
    enum BannerType {
        case info
        case success
        case warning
        case error
        case premium
        
        var icon: String {
            switch self {
            case .info:
                return GlowlyTheme.Icons.info
            case .success:
                return GlowlyTheme.Icons.checkmarkCircle
            case .warning:
                return GlowlyTheme.Icons.warning
            case .error:
                return GlowlyTheme.Icons.error
            case .premium:
                return GlowlyTheme.Icons.crown
            }
        }
        
        var accentColor: Color {
            switch self {
            case .info:
                return GlowlyTheme.Colors.secondary
            case .success:
                return GlowlyTheme.Colors.success
            case .warning:
                return GlowlyTheme.Colors.warning
            case .error:
                return GlowlyTheme.Colors.error
            case .premium:
                return GlowlyTheme.Colors.accent
            }
        }
        
        func backgroundColor(_ colorScheme: ColorScheme) -> Color {
            switch self {
            case .info:
                return GlowlyTheme.Colors.secondary.opacity(0.1)
            case .success:
                return GlowlyTheme.Colors.success.opacity(0.1)
            case .warning:
                return GlowlyTheme.Colors.warning.opacity(0.1)
            case .error:
                return GlowlyTheme.Colors.error.opacity(0.1)
            case .premium:
                return GlowlyTheme.Colors.accent.opacity(0.1)
            }
        }
    }
    
    struct BannerAction {
        let title: String
        let action: () -> Void
    }
}

// MARK: - Toast Manager
@MainActor
class GlowlyToastManager: ObservableObject {
    @Published var currentToast: ToastData?
    
    func show(_ message: String, type: GlowlyToast.ToastType, duration: TimeInterval = 3.0) {
        currentToast = ToastData(
            message: message,
            type: type,
            duration: duration
        )
    }
    
    func dismiss() {
        currentToast = nil
    }
    
    struct ToastData {
        let message: String
        let type: GlowlyToast.ToastType
        let duration: TimeInterval
    }
}

// MARK: - Toast Environment
struct ToastEnvironmentKey: EnvironmentKey {
    static let defaultValue = GlowlyToastManager()
}

extension EnvironmentValues {
    var toastManager: GlowlyToastManager {
        get { self[ToastEnvironmentKey.self] }
        set { self[ToastEnvironmentKey.self] = newValue }
    }
}

// MARK: - Toast Container View
struct GlowlyToastContainer<Content: View>: View {
    let content: Content
    @StateObject private var toastManager = GlowlyToastManager()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            content
                .environment(\.toastManager, toastManager)
            
            if let toast = toastManager.currentToast {
                VStack {
                    GlowlyToast(
                        message: toast.message,
                        type: toast.type,
                        duration: toast.duration,
                        isPresented: .constant(true)
                    )
                    .onDisappear {
                        toastManager.dismiss()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .zIndex(1000)
            }
        }
    }
}

// MARK: - View Extension for Toast
extension View {
    func withToasts() -> some View {
        GlowlyToastContainer {
            self
        }
    }
    
    func showToast(_ message: String, type: GlowlyToast.ToastType = .info, duration: TimeInterval = 3.0) -> some View {
        self.environment(\.toastManager, GlowlyToastManager())
    }
}

// MARK: - Preview
#Preview("Alerts and Toasts") {
    GlowlyToastContainer {
        VStack(spacing: GlowlyTheme.Spacing.lg) {
            GlowlyButton(title: "Show Success Toast") {
                // This would trigger a toast in a real implementation
            }
            
            GlowlyButton(title: "Show Alert") {
                // This would trigger an alert in a real implementation
            }
            
            // Banner Example
            GlowlyBanner(
                title: "Premium Feature",
                message: "Upgrade to access advanced AI enhancements",
                type: .premium,
                action: GlowlyBanner.BannerAction(title: "Upgrade Now", action: {}),
                isPresented: .constant(true)
            )
        }
        .padding()
    }
    .themed()
}