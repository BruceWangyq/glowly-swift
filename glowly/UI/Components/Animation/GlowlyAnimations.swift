//
//  GlowlyAnimations.swift
//  Glowly
//
//  Animation and interaction components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyAnimatedGradient
struct GlowlyAnimatedGradient: View {
    let colors: [Color]
    var speed: Double = 1.0
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: UnitPoint(x: 0.5 + 0.3 * cos(animationPhase), y: 0.5 + 0.3 * sin(animationPhase)),
            endPoint: UnitPoint(x: 0.5 - 0.3 * cos(animationPhase), y: 0.5 - 0.3 * sin(animationPhase))
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 4.0 / speed)
                    .repeatForever(autoreverses: false)
            ) {
                animationPhase = 2 * .pi
            }
        }
    }
}

// MARK: - GlowlyPulseEffect
struct GlowlyPulseEffect: ViewModifier {
    let isActive: Bool
    let intensity: Double
    let speed: Double
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                if isActive {
                    startPulse()
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    startPulse()
                } else {
                    stopPulse()
                }
            }
    }
    
    private func startPulse() {
        let pulseScale = 1.0 + (intensity * 0.1)
        let pulseOpacity = 1.0 - (intensity * 0.2)
        
        withAnimation(
            Animation.easeInOut(duration: 1.0 / speed)
                .repeatForever(autoreverses: true)
        ) {
            scale = pulseScale
            opacity = pulseOpacity
        }
    }
    
    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
    }
}

extension View {
    func glowlyPulse(isActive: Bool = true, intensity: Double = 0.5, speed: Double = 1.0) -> some View {
        self.modifier(GlowlyPulseEffect(isActive: isActive, intensity: intensity, speed: speed))
    }
}

// MARK: - GlowlyShimmerEffect
struct GlowlyShimmerEffect: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0)
                            ],
                            startPoint: UnitPoint(x: -0.3 + phase, y: -0.3 + phase),
                            endPoint: UnitPoint(x: 0.3 + phase, y: 0.3 + phase)
                        )
                    )
                    .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    startShimmer()
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    startShimmer()
                }
            }
    }
    
    private func startShimmer() {
        withAnimation(
            Animation.linear(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            phase = 1.6
        }
    }
}

extension View {
    func glowlyShimmer(isActive: Bool = true) -> some View {
        self.modifier(GlowlyShimmerEffect(isActive: isActive))
    }
}

// MARK: - GlowlyBouncyButton
struct GlowlyBouncyButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    var intensity: Double = 1.0
    var hapticFeedback: Bool = true
    
    @State private var isPressed = false
    
    init(
        intensity: Double = 1.0,
        hapticFeedback: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.intensity = intensity
        self.hapticFeedback = hapticFeedback
    }
    
    var body: some View {
        Button(action: {
            if hapticFeedback {
                HapticFeedback.light()
            }
            action()
        }) {
            content
                .scaleEffect(isPressed ? 0.95 - (intensity * 0.05) : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: isPressed
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - GlowlyFloatingParticles
struct GlowlyFloatingParticles: View {
    let particleCount: Int
    let colors: [Color]
    var speed: Double = 1.0
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles.indices, id: \.self) { index in
                    Circle()
                        .fill(particles[index].color)
                        .frame(width: particles[index].size, height: particles[index].size)
                        .position(particles[index].position)
                        .opacity(particles[index].opacity)
                        .animation(
                            Animation.linear(duration: particles[index].duration)
                                .repeatForever(autoreverses: false),
                            value: particles[index].position
                        )
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...8),
                color: colors.randomElement() ?? Color.blue,
                opacity: Double.random(in: 0.3...0.8),
                duration: Double.random(in: 2...6) / speed
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for index in particles.indices {
                let dx = CGFloat.random(in: -2...2)
                let dy = CGFloat.random(in: -2...2)
                
                var newX = particles[index].position.x + dx
                var newY = particles[index].position.y + dy
                
                // Wrap around edges
                if newX < 0 { newX = size.width }
                if newX > size.width { newX = 0 }
                if newY < 0 { newY = size.height }
                if newY > size.height { newY = 0 }
                
                particles[index].position = CGPoint(x: newX, y: newY)
            }
        }
    }
    
    private struct Particle {
        var position: CGPoint
        let size: CGFloat
        let color: Color
        let opacity: Double
        let duration: Double
    }
}

// MARK: - GlowlySpringButton
struct GlowlySpringButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    var springResponse: Double = 0.6
    var springDamping: Double = 0.8
    
    @State private var isPressed = false
    
    init(
        springResponse: Double = 0.6,
        springDamping: Double = 0.8,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.springResponse = springResponse
        self.springDamping = springDamping
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            
            // Trigger spring animation
            withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                isPressed = true
            }
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            content
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .rotationEffect(.degrees(isPressed ? 5 : 0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - GlowlyProgressRing
struct GlowlyProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var showPercentage: Bool = false
    var animated: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme),
                    lineWidth: lineWidth
                )
            
            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                            GlowlyTheme.Colors.primaryDark,
                            GlowlyTheme.Colors.adaptivePrimary(colorScheme)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                withAnimation(GlowlyTheme.Animation.gentle.delay(0.2)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            if animated {
                withAnimation(GlowlyTheme.Animation.gentle) {
                    animatedProgress = newProgress
                }
            } else {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - GlowlyInteractiveScale
struct GlowlyInteractiveScale: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = CGFloat(1.0)
    
    var minScale: CGFloat = 0.5
    var maxScale: CGFloat = 3.0
    var onScaleChanged: ((CGFloat) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale * magnifyBy)
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { currentState, gestureState, _ in
                        gestureState = currentState
                        HapticFeedback.selection()
                    }
                    .onEnded { value in
                        let newScale = scale * value
                        scale = max(minScale, min(maxScale, newScale))
                        onScaleChanged?(scale)
                    }
            )
            .animation(GlowlyTheme.Animation.gentle, value: scale)
    }
}

extension View {
    func glowlyInteractiveScale(
        minScale: CGFloat = 0.5,
        maxScale: CGFloat = 3.0,
        onScaleChanged: ((CGFloat) -> Void)? = nil
    ) -> some View {
        self.modifier(GlowlyInteractiveScale(
            minScale: minScale,
            maxScale: maxScale,
            onScaleChanged: onScaleChanged
        ))
    }
}

// MARK: - GlowlyWaveEffect
struct GlowlyWaveEffect: View {
    let color: Color
    var amplitude: CGFloat = 20
    var frequency: CGFloat = 2
    var speed: Double = 1.0
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                    let y = midHeight + (sine * amplitude)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
            .animation(
                Animation.linear(duration: 2.0 / speed)
                    .repeatForever(autoreverses: false),
                value: phase
            )
        }
        .onAppear {
            phase = 2 * .pi
        }
    }
}

// MARK: - GlowlyPhotoZoomContainer
struct GlowlyPhotoZoomContainer<Content: View>: View {
    let content: Content
    var minScale: CGFloat = 1.0
    var maxScale: CGFloat = 4.0
    var doubleTapScale: CGFloat = 2.0
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var panBy: CGSize = .zero
    
    init(
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 4.0,
        doubleTapScale: CGFloat = 2.0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.minScale = minScale
        self.maxScale = maxScale
        self.doubleTapScale = doubleTapScale
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .scaleEffect(scale * magnifyBy)
                .offset(
                    x: offset.width + panBy.width,
                    y: offset.height + panBy.height
                )
                .gesture(
                    SimultaneousGesture(
                        // Zoom gesture
                        MagnificationGesture()
                            .updating($magnifyBy) { currentState, gestureState, _ in
                                gestureState = currentState
                            }
                            .onEnded { value in
                                let newScale = lastScale * value
                                scale = max(minScale, min(maxScale, newScale))
                                lastScale = scale
                                
                                // Reset offset if zoomed out completely
                                if scale <= minScale {
                                    withAnimation(GlowlyTheme.Animation.gentle) {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                                
                                HapticFeedback.light()
                            },
                        
                        // Pan gesture
                        DragGesture()
                            .updating($panBy) { currentState, gestureState, _ in
                                if scale > minScale {
                                    gestureState = currentState.translation
                                }
                            }
                            .onEnded { value in
                                if scale > minScale {
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    
                                    // Constrain offset to keep image visible
                                    let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                    let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                    
                                    offset = CGSize(
                                        width: max(-maxOffsetX, min(maxOffsetX, newOffset.width)),
                                        height: max(-maxOffsetY, min(maxOffsetY, newOffset.height))
                                    )
                                    lastOffset = offset
                                }
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(GlowlyTheme.Animation.bouncy) {
                        if scale > minScale {
                            // Zoom out
                            scale = minScale
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            // Zoom in
                            scale = doubleTapScale
                        }
                        lastScale = scale
                    }
                    HapticFeedback.medium()
                }
                .animation(GlowlyTheme.Animation.gentle, value: scale)
                .animation(GlowlyTheme.Animation.gentle, value: offset)
        }
        .clipped()
    }
}

// MARK: - Preview
#Preview("Animation Components") {
    ScrollView {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            // Animated Gradient Background
            GlowlyAnimatedGradient(
                colors: [
                    GlowlyTheme.Colors.primary,
                    GlowlyTheme.Colors.secondary,
                    GlowlyTheme.Colors.accent
                ]
            )
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.lg))
            
            // Bouncy Button
            GlowlyBouncyButton {
                Text("Tap me!")
                    .padding()
                    .background(GlowlyTheme.Colors.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            } action: {
                print("Bouncy button tapped!")
            }
            
            // Progress Ring
            GlowlyProgressRing(
                progress: 0.75,
                lineWidth: 8,
                size: 100,
                showPercentage: true
            )
            
            // Wave Effect
            GlowlyWaveEffect(
                color: GlowlyTheme.Colors.primary,
                amplitude: 30,
                frequency: 3
            )
            .frame(height: 100)
            
            // Pulse and Shimmer Effects
            HStack {
                Rectangle()
                    .fill(GlowlyTheme.Colors.secondary)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .glowlyPulse()
                
                Rectangle()
                    .fill(GlowlyTheme.Colors.accent)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .glowlyShimmer()
            }
        }
        .padding()
    }
    .themed()
}