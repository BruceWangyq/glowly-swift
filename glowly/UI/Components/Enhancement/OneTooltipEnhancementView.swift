//
//  OneTapEnhancementView.swift
//  Glowly
//
//  Beautiful UI components for one-tap enhancement interface with smooth animations
//

import SwiftUI
import Combine

/// Main one-tap enhancement interface
struct OneTapEnhancementView: View {
    @StateObject private var enhancementEngine = AutoEnhancementEngine(
        beautyService: BeautyEnhancementService()
    )
    @StateObject private var pipeline = SmartEnhancementPipeline()
    
    @State private var originalImage: UIImage?
    @State private var enhancedImage: UIImage?
    @State private var selectedMode: EnhancementMode = .natural
    @State private var isProcessing = false
    @State private var showingBeforeAfter = false
    @State private var processingProgress: Float = 0.0
    @State private var showingIntensitySlider = false
    @State private var intensityAdjustment: Float = 1.0
    @State private var previewImages: [EnhancementMode: UIImage] = [:]
    
    let image: UIImage
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Main image display
                    imageDisplayView(geometry: geometry)
                        .padding(.horizontal, 20)
                    
                    // Enhancement modes
                    enhancementModesView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    
                    // Processing controls
                    processingControlsView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            originalImage = image
            generatePreviews()
        }
        .animation(.easeInOut(duration: 0.3), value: isProcessing)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedMode)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                // Handle cancel
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Auto Enhance")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Save") {
                // Handle save
            }
            .foregroundColor(.white)
            .disabled(enhancedImage == nil)
        }
    }
    
    // MARK: - Image Display View
    
    private func imageDisplayView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
                .frame(height: geometry.size.height * 0.5)
            
            // Image content
            Group {
                if showingBeforeAfter {
                    beforeAfterView
                } else {
                    mainImageView
                }
            }
            .clipped()
            .cornerRadius(16)
            
            // Processing overlay
            if isProcessing {
                processingOverlayView
            }
            
            // Controls overlay
            imageControlsOverlay
        }
    }
    
    private var mainImageView: some View {
        Group {
            if let enhancedImage = enhancedImage {
                Image(uiImage: enhancedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            } else if let originalImage = originalImage {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
    
    private var beforeAfterView: some View {
        HStack(spacing: 2) {
            // Before (Original)
            VStack {
                Text("Before")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                if let originalImage = originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                }
            }
            
            // After (Enhanced)
            VStack {
                Text("After")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                if let enhancedImage = enhancedImage {
                    Image(uiImage: enhancedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } else if let originalImage = originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                }
            }
        }
    }
    
    private var processingOverlayView: some View {
        ZStack {
            Color.black.opacity(0.6)
            
            VStack(spacing: 16) {
                // Processing animation
                EnhancementProgressView(progress: processingProgress)
                
                // Status text
                Text("Enhancing photo...")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                // Progress percentage
                Text("\(Int(processingProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var imageControlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // Before/After toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingBeforeAfter.toggle()
                    }
                }) {
                    Image(systemName: showingBeforeAfter ? "rectangle.split.2x1" : "rectangle.split.2x1.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
                .disabled(enhancedImage == nil)
            }
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Enhancement Modes View
    
    private var enhancementModesView: some View {
        VStack(spacing: 16) {
            // Mode selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(EnhancementMode.allCases.filter { $0 != .custom }, id: \.self) { mode in
                        EnhancementModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            previewImage: previewImages[mode],
                            onTap: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    selectedMode = mode
                                    applyEnhancement(mode: mode)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Intensity adjustment
            if showingIntensitySlider {
                intensitySliderView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var intensitySliderView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Intensity")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(intensityAdjustment * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack {
                Image(systemName: "sun.min")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                
                Slider(value: $intensityAdjustment, in: 0.1...1.5) { editing in
                    if !editing {
                        applyEnhancement(mode: selectedMode, customIntensity: intensityAdjustment)
                    }
                }
                .accentColor(.blue)
                
                Image(systemName: "sun.max")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
    }
    
    // MARK: - Processing Controls View
    
    private var processingControlsView: some View {
        VStack(spacing: 16) {
            // Main action button
            Button(action: {
                if isProcessing {
                    cancelProcessing()
                } else {
                    applyEnhancement(mode: selectedMode)
                }
            }) {
                HStack {
                    if isProcessing {
                        Image(systemName: "xmark")
                            .font(.title2)
                    } else {
                        Image(systemName: selectedMode.icon)
                            .font(.title2)
                    }
                    
                    Text(isProcessing ? "Cancel" : "Apply \(selectedMode.displayName)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            isProcessing ?
                            Color.red.opacity(0.8) :
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(originalImage == nil)
            
            // Secondary controls
            HStack(spacing: 20) {
                // Intensity toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingIntensitySlider.toggle()
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                        Text("Adjust")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Preview toggle
                Button(action: {
                    // Generate new previews
                    generatePreviews()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.title2)
                        Text("Preview")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Reset
                Button(action: {
                    resetEnhancements()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("Reset")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .disabled(enhancedImage == nil)
            }
        }
    }
    
    // MARK: - Actions
    
    private func generatePreviews() {
        guard let originalImage = originalImage else { return }
        
        Task {
            for mode in EnhancementMode.allCases.filter({ $0 != .custom }) {
                do {
                    let previewRequest = PreviewRequest(
                        image: originalImage,
                        quickEnhancements: EnhancementProfile.getProfile(for: mode).getQuickEnhancements(
                            for: QuickImageAnalysis(
                                hasFace: true,
                                primaryFace: nil,
                                imageQuality: 0.8,
                                sceneType: .portrait
                            )
                        ),
                        enhancements: [],
                        confidence: 0.8
                    )
                    
                    let preview = try await enhancementEngine.previewEnhancement(
                        image: originalImage,
                        mode: mode
                    )
                    
                    await MainActor.run {
                        previewImages[mode] = preview.previewImage
                    }
                } catch {
                    print("Preview generation failed for \(mode): \(error)")
                }
            }
        }
    }
    
    private func applyEnhancement(mode: EnhancementMode, customIntensity: Float? = nil) {
        guard let originalImage = originalImage else { return }
        
        isProcessing = true
        processingProgress = 0.0
        
        Task {
            do {
                let result = try await enhancementEngine.analyzeAndEnhance(
                    image: originalImage,
                    mode: mode
                )
                
                await MainActor.run {
                    enhancedImage = result.enhancedImage
                    isProcessing = false
                    processingProgress = 0.0
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    processingProgress = 0.0
                    // Show error alert
                }
            }
        }
        
        // Monitor progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isProcessing {
                timer.invalidate()
                return
            }
            
            processingProgress = enhancementEngine.processingProgress
        }
    }
    
    private func cancelProcessing() {
        isProcessing = false
        processingProgress = 0.0
        // Cancel any ongoing tasks
    }
    
    private func resetEnhancements() {
        withAnimation(.easeInOut(duration: 0.3)) {
            enhancedImage = nil
            selectedMode = .natural
            intensityAdjustment = 1.0
            showingIntensitySlider = false
            showingBeforeAfter = false
        }
    }
}

// MARK: - Enhancement Mode Card

struct EnhancementModeCard: View {
    let mode: EnhancementMode
    let isSelected: Bool
    let previewImage: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let previewImage = previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Loading placeholder
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
            }
            
            // Mode info
            VStack(spacing: 2) {
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)
                
                Text(mode.description.prefix(20) + "...")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 100)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Enhancement Progress View

struct EnhancementProgressView: View {
    let progress: Float
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
            
            // Center icon
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.white)
                .scaleEffect(0.8)
        }
    }
}

// MARK: - Supporting Extensions

extension EnhancementProfile {
    static func getProfile(for mode: EnhancementMode) -> EnhancementProfile {
        switch mode {
        case .natural: return .natural
        case .glam: return .glam
        case .hd: return .hd
        case .studio: return .studio
        case .custom: return .natural // Fallback
        }
    }
}