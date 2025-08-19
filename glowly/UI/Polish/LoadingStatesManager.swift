//
//  LoadingStatesManager.swift
//  Glowly
//
//  Comprehensive loading states and progress indicators for UX polish
//

import SwiftUI
import Combine

// MARK: - Loading State Management

@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    @Published var globalLoadingState: LoadingState = .idle
    @Published var operationProgress: [String: Double] = [:]
    @Published var loadingMessages: [String: String] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGlobalLoadingState()
    }
    
    private func setupGlobalLoadingState() {
        // Monitor overall app loading state
        $operationProgress
            .map { operations in
                operations.isEmpty ? .idle : .loading
            }
            .assign(to: &$globalLoadingState)
    }
    
    func startOperation(_ id: String, message: String = "Loading...") {
        operationProgress[id] = 0.0
        loadingMessages[id] = message
    }
    
    func updateProgress(_ id: String, progress: Double) {
        operationProgress[id] = min(max(progress, 0.0), 1.0)
    }
    
    func updateMessage(_ id: String, message: String) {
        loadingMessages[id] = message
    }
    
    func completeOperation(_ id: String) {
        operationProgress.removeValue(forKey: id)
        loadingMessages.removeValue(forKey: id)
    }
    
    func failOperation(_ id: String, error: Error) {
        operationProgress.removeValue(forKey: id)
        loadingMessages.removeValue(forKey: id)
        // Handle error state
    }
}

enum LoadingState {
    case idle
    case loading
    case error(Error)
    case success
}

// MARK: - Loading Views

struct GlowlyProgressIndicator: View {
    let progress: Double?
    let message: String
    let style: ProgressStyle
    
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    init(
        progress: Double? = nil,
        message: String = "Loading...",
        style: ProgressStyle = .circular
    ) {
        self.progress = progress
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .circular:
                circularProgress
            case .linear:
                linearProgress
            case .pulse:
                pulseProgress
            case .shimmer:
                shimmerProgress
            }
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var circularProgress: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            // Progress circle
            if let progress = progress {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            } else {
                // Indeterminate progress
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, .blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(animationOffset))
            }
        }
    }
    
    private var linearProgress: some View {
        VStack(spacing: 8) {
            // Progress bar background
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 4)
                .overlay(
                    // Progress bar fill
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progress.map { CGFloat($0) } ?? 0.3)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                        
                        Spacer()
                    }
                )
            
            if let progress = progress {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var pulseProgress: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 60)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
        }
    }
    
    private var shimmerProgress: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.white.opacity(0.8),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 200, height: 20)
            .offset(x: animationOffset)
            .clipped()
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            animationOffset = 360
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

enum ProgressStyle {
    case circular
    case linear
    case pulse
    case shimmer
}

// MARK: - Enhanced Loading States

struct PhotoProcessingLoader: View {
    let progress: Double?
    let stage: ProcessingStage
    
    var body: some View {
        VStack(spacing: 20) {
            // Processing animation
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .offset(y: -40)
                        .rotationEffect(.degrees(Double(index) * 120))
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.1),
                            value: index
                        )
                }
                
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .frame(width: 80, height: 80)
            
            VStack(spacing: 8) {
                Text(stage.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(stage.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

enum ProcessingStage: CaseIterable {
    case analyzing
    case enhancing
    case applying
    case finalizing
    
    var displayName: String {
        switch self {
        case .analyzing:
            return "Analyzing Photo"
        case .enhancing:
            return "Enhancing Beauty"
        case .applying:
            return "Applying Filters"
        case .finalizing:
            return "Finalizing"
        }
    }
    
    var description: String {
        switch self {
        case .analyzing:
            return "AI is analyzing your photo for optimal enhancements"
        case .enhancing:
            return "Applying beauty enhancements with precision"
        case .applying:
            return "Adding filters and final touches"
        case .finalizing:
            return "Preparing your enhanced photo"
        }
    }
}

// MARK: - Empty States

struct EmptyStateView: View {
    let type: EmptyStateType
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: type.iconName)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            // Content
            VStack(spacing: 12) {
                Text(type.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(type.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Action button
            if let action = action, let buttonTitle = type.actionTitle {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum EmptyStateType {
    case noPhotos
    case noEnhancements
    case noDrafts
    case noNetwork
    case permissionDenied
    case processing
    
    var iconName: String {
        switch self {
        case .noPhotos:
            return "photo.badge.plus"
        case .noEnhancements:
            return "slider.horizontal.3"
        case .noDrafts:
            return "doc.text"
        case .noNetwork:
            return "wifi.slash"
        case .permissionDenied:
            return "lock.circle"
        case .processing:
            return "gearshape.2"
        }
    }
    
    var title: String {
        switch self {
        case .noPhotos:
            return "No Photos Selected"
        case .noEnhancements:
            return "No Enhancements Applied"
        case .noDrafts:
            return "No Saved Drafts"
        case .noNetwork:
            return "No Internet Connection"
        case .permissionDenied:
            return "Photo Access Required"
        case .processing:
            return "Processing..."
        }
    }
    
    var description: String {
        switch self {
        case .noPhotos:
            return "Choose a photo from your library or take a new one to start enhancing your beauty."
        case .noEnhancements:
            return "Start by selecting enhancement options to transform your photos with AI-powered beauty filters."
        case .noDrafts:
            return "Your saved work will appear here. Start editing photos to create drafts."
        case .noNetwork:
            return "Please check your internet connection and try again. Some features may not be available offline."
        case .permissionDenied:
            return "Glowly needs access to your photos to enhance them. Please grant permission in Settings."
        case .processing:
            return "We're working on enhancing your photo with AI-powered beauty filters."
        }
    }
    
    var actionTitle: String? {
        switch self {
        case .noPhotos:
            return "Select Photo"
        case .noEnhancements:
            return "Browse Enhancements"
        case .noDrafts:
            return "Start Editing"
        case .noNetwork:
            return "Try Again"
        case .permissionDenied:
            return "Open Settings"
        case .processing:
            return nil
        }
    }
}

// MARK: - Smart Loading Overlays

struct LoadingOverlay: View {
    let isVisible: Bool
    let style: LoadingOverlayStyle
    let message: String
    
    var body: some View {
        ZStack {
            if isVisible {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                // Loading content
                VStack(spacing: 16) {
                    switch style {
                    case .minimal:
                        GlowlyProgressIndicator(message: message, style: .circular)
                    case .detailed:
                        PhotoProcessingLoader(progress: nil, stage: .enhancing)
                    case .fullScreen:
                        fullScreenLoader
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }
    
    private var fullScreenLoader: some View {
        VStack(spacing: 32) {
            Spacer()
            
            GlowlyProgressIndicator(message: message, style: .pulse)
            
            Text("Enhancing Your Beauty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AI is analyzing and enhancing your photo")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

enum LoadingOverlayStyle {
    case minimal
    case detailed
    case fullScreen
}

// MARK: - View Modifiers

extension View {
    func loadingOverlay(
        isLoading: Bool,
        message: String = "Loading...",
        style: LoadingOverlayStyle = .minimal
    ) -> some View {
        overlay(
            LoadingOverlay(
                isVisible: isLoading,
                style: style,
                message: message
            )
        )
    }
    
    func emptyState(
        _ type: EmptyStateType,
        isVisible: Bool,
        action: (() -> Void)? = nil
    ) -> some View {
        overlay(
            Group {
                if isVisible {
                    EmptyStateView(type: type, action: action)
                }
            }
        )
    }
}

// MARK: - Usage Examples and Previews

#Preview("Progress Indicators") {
    VStack(spacing: 40) {
        GlowlyProgressIndicator(progress: 0.7, message: "Processing photo...", style: .circular)
        GlowlyProgressIndicator(progress: 0.3, message: "Applying enhancements...", style: .linear)
        GlowlyProgressIndicator(message: "Loading...", style: .pulse)
    }
    .padding()
}

#Preview("Photo Processing Loader") {
    PhotoProcessingLoader(progress: 0.65, stage: .enhancing)
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        EmptyStateView(type: .noPhotos) {
            print("Select photo tapped")
        }
    }
}