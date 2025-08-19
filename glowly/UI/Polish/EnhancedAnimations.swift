//
//  EnhancedAnimations.swift
//  Glowly
//
//  Smooth animations and transitions for premium UX experience
//

import SwiftUI

// MARK: - Animation Manager

@MainActor
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    // Animation preferences
    @Published var reducedMotionEnabled: Bool
    @Published var animationSpeed: Double = 1.0
    
    // Common animations
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.3)
    static let bounceAnimation = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    init() {
        self.reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
    }
    
    func animation(_ animation: Animation) -> Animation {
        if reducedMotionEnabled {
            return .linear(duration: 0.1) // Minimal animation for accessibility
        }
        return animation.speed(animationSpeed)
    }
    
    func withAnimation<T>(_ animation: Animation, _ body: () -> T) -> T {
        SwiftUI.withAnimation(self.animation(animation), body)
    }
}

// MARK: - Photo Enhancement Animations

struct PhotoEnhancementTransition: View {
    @State private var isEnhanced = false
    @State private var glowIntensity: Double = 0
    @State private var sparkleOffset: CGFloat = 0
    
    let originalImage: Image
    let enhancedImage: Image?
    let isProcessing: Bool
    
    var body: some View {
        ZStack {
            // Original image
            originalImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(isEnhanced ? 0.3 : 1.0)
                .scaleEffect(isEnhanced ? 0.95 : 1.0)
                .blur(radius: isProcessing ? 2 : 0)
                .animation(.easeInOut(duration: 0.8), value: isEnhanced)
                .animation(.easeInOut(duration: 0.3), value: isProcessing)
            
            // Enhanced image overlay
            if let enhancedImage = enhancedImage {
                enhancedImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(isEnhanced ? 1.0 : 0.0)
                    .scaleEffect(isEnhanced ? 1.0 : 1.05)
                    .shadow(color: .white.opacity(glowIntensity), radius: 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isEnhanced)
            }
            
            // Sparkle effect during processing
            if isProcessing {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(Double(index) * .pi / 4) * (50 + sparkleOffset),
                            y: sin(Double(index) * .pi / 4) * (50 + sparkleOffset)
                        )
                        .opacity(sin(sparkleOffset * 0.1 + Double(index)) * 0.5 + 0.5)
                }
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: sparkleOffset
                )
            }
            
            // Enhancement glow effect
            if isProcessing {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(0.6)
                    .scaleEffect(1.02)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isProcessing)
            }
        }
        .onAppear {
            if isProcessing {
                startProcessingAnimations()
            }
        }
        .onChange(of: enhancedImage) { _, newValue in
            if newValue != nil {
                completeEnhancement()
            }
        }
    }
    
    private func startProcessingAnimations() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            sparkleOffset = 100
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowIntensity = 0.8
        }
    }
    
    private func completeEnhancement() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            isEnhanced = true
        }
        
        // Celebration effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                glowIntensity = 0
            }
        }
    }
}

// MARK: - Tab Transition Animations

struct TabTransitionModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.95)
            .opacity(isActive ? 1.0 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Button Animations

struct PressableButtonStyle: ButtonStyle {
    let hapticFeedback: Bool
    
    init(hapticFeedback: Bool = true) {
        self.hapticFeedback = hapticFeedback
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticFeedback {
                    HapticFeedbackManager.shared.impact(.light)
                }
            }
    }
}

struct FloatingButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: .blue.opacity(0.3),
                        radius: isHovered || configuration.isPressed ? 15 : 8,
                        x: 0,
                        y: isHovered || configuration.isPressed ? 8 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - List and Collection Animations

struct StaggeredAppearance: ViewModifier {
    let index: Int
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * delay),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

struct PhotoGridItemTransition: ViewModifier {
    @State private var hasAppeared = false
    let index: Int
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1.0 : 0.0)
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .rotation3DEffect(
                .degrees(hasAppeared ? 0 : -15),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

// MARK: - Page Transitions

struct PageTransition: ViewModifier {
    let direction: TransitionDirection
    
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: .move(edge: direction.insertionEdge).combined(with: .opacity),
                    removal: .move(edge: direction.removalEdge).combined(with: .opacity)
                )
            )
    }
}

enum TransitionDirection {
    case leading
    case trailing
    case top
    case bottom
    
    var insertionEdge: Edge {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        }
    }
    
    var removalEdge: Edge {
        switch self {
        case .leading: return .trailing
        case .trailing: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}

// MARK: - Morphing Animations

struct MorphingIcon: View {
    let fromIcon: String
    let toIcon: String
    let isTransformed: Bool
    
    @State private var morphProgress: Double = 0
    
    var body: some View {
        ZStack {
            Image(systemName: fromIcon)
                .font(.title2)
                .opacity(1.0 - morphProgress)
                .scaleEffect(1.0 - morphProgress * 0.5)
                .rotationEffect(.degrees(morphProgress * 180))
            
            Image(systemName: toIcon)
                .font(.title2)
                .opacity(morphProgress)
                .scaleEffect(morphProgress * 0.5 + 0.5)
                .rotationEffect(.degrees(-180 + morphProgress * 180))
        }
        .onChange(of: isTransformed) { _, transformed in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                morphProgress = transformed ? 1.0 : 0.0
            }
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var shimmerOffset: CGFloat = -200
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.5),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(45))
                    .offset(x: shimmerOffset)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
    }
}

// MARK: - Haptic Feedback Manager

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
}

// MARK: - View Extensions

extension View {
    func staggeredAppearance(index: Int, delay: Double = 0.1) -> some View {
        modifier(StaggeredAppearance(index: index, delay: delay))
    }
    
    func photoGridTransition(index: Int) -> some View {
        modifier(PhotoGridItemTransition(index: index))
    }
    
    func pageTransition(direction: TransitionDirection) -> some View {
        modifier(PageTransition(direction: direction))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func pressableStyle(hapticFeedback: Bool = true) -> some View {
        buttonStyle(PressableButtonStyle(hapticFeedback: hapticFeedback))
    }
    
    func floatingStyle() -> some View {
        buttonStyle(FloatingButtonStyle())
    }
    
    func tabTransition(isActive: Bool) -> some View {
        modifier(TabTransitionModifier(isActive: isActive))
    }
}

// MARK: - Usage Examples and Previews

#Preview("Photo Enhancement Transition") {
    PhotoEnhancementTransition(
        originalImage: Image(systemName: "photo"),
        enhancedImage: Image(systemName: "sparkles"),
        isProcessing: true
    )
    .frame(width: 300, height: 300)
}

#Preview("Morphing Icon") {
    VStack {
        MorphingIcon(
            fromIcon: "heart",
            toIcon: "heart.fill",
            isTransformed: true
        )
        
        MorphingIcon(
            fromIcon: "star",
            toIcon: "star.fill",
            isTransformed: false
        )
    }
}

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Press Me") {
            HapticFeedbackManager.shared.impact(.medium)
        }
        .pressableStyle()
        
        Button("Floating Button") {
            HapticFeedbackManager.shared.notification(.success)
        }
        .floatingStyle()
        .padding()
    }
}