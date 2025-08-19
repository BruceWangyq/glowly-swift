//
//  EnhancedBeforeAfterView.swift
//  Glowly
//
//  Comprehensive before/after preview comparison system with multiple modes and advanced features
//

import SwiftUI
import CoreImage
import AVFoundation

// MARK: - EnhancedBeforeAfterView
struct EnhancedBeforeAfterView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let enhancementHighlights: [EnhancementHighlight]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ComparisonViewModel()
    @StateObject private var exportManager = ExportManager()
    
    @State private var showingExportSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingFullScreen = false
    @State private var sessionStartTime = Date()
    
    // Animation states
    @State private var overlayOpacity: Double = 0.0
    @State private var transitionProgress: Double = 0.0
    @State private var isAnimating = false
    
    init(
        originalImage: UIImage?,
        processedImage: UIImage?,
        enhancementHighlights: [EnhancementHighlight] = []
    ) {
        self.originalImage = originalImage
        self.processedImage = processedImage
        self.enhancementHighlights = enhancementHighlights
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Mode Selector
                        if !showingFullScreen {
                            comparisonModeSelector
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Main Comparison Area
                        ZStack {
                            comparisonView(geometry: geometry)
                            
                            // Enhancement Highlights
                            if viewModel.preferences.showEnhancementHighlights && !enhancementHighlights.isEmpty {
                                enhancementHighlightOverlay(geometry: geometry)
                            }
                            
                            // Magnifier
                            if viewModel.state.showingMagnifier {
                                magnifierView(geometry: geometry)
                            }
                            
                            // Controls Overlay
                            if !showingFullScreen {
                                controlsOverlay
                            }
                        }
                        .onTapGesture(count: 2) {
                            handleDoubleTap()
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            toggleFullScreen()
                        }
                        
                        // Bottom Controls
                        if !showingFullScreen {
                            bottomControlsBar
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .navigationTitle(showingFullScreen ? "" : "Compare")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(showingFullScreen)
            .toolbar {
                if !showingFullScreen {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                showingSettingsSheet = true
                            } label: {
                                Image(systemName: "gear")
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                showingExportSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .statusBarHidden(showingFullScreen)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsView(
                originalImage: originalImage,
                processedImage: processedImage,
                comparisonState: viewModel.state,
                exportManager: exportManager
            )
        }
        .sheet(isPresented: $showingSettingsSheet) {
            ComparisonSettingsView(preferences: $viewModel.preferences)
        }
        .onAppear {
            setupImages()
        }
    }
    
    // MARK: - Mode Selector
    
    private var comparisonModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ComparisonMode.allCases, id: \.self) { mode in
                    ModeButton(
                        mode: mode,
                        isSelected: viewModel.state.currentMode == mode,
                        action: {
                            selectMode(mode)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 60)
        .background(
            Color.black.opacity(0.7)
                .blur(radius: 10)
        )
    }
    
    // MARK: - Comparison Views
    
    @ViewBuilder
    private func comparisonView(geometry: GeometryProxy) -> some View {
        switch viewModel.state.currentMode {
        case .swipeReveal:
            swipeRevealView(geometry: geometry)
        case .sideBySide:
            sideBySideView(geometry: geometry)
        case .toggle:
            toggleView(geometry: geometry)
        case .splitScreen:
            splitScreenView(geometry: geometry)
        case .overlay:
            overlayView(geometry: geometry)
        case .fullScreen:
            fullScreenView(geometry: geometry)
        }
    }
    
    // MARK: - Swipe Reveal Mode
    
    private func swipeRevealView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Background image (original)
            if let originalImage = originalImage {
                ImageView(
                    image: originalImage,
                    geometry: geometry,
                    zoomLevel: viewModel.state.zoomLevel,
                    panOffset: totalPanOffset
                )
            }
            
            // Foreground image (processed) with mask
            if let processedImage = processedImage {
                ImageView(
                    image: processedImage,
                    geometry: geometry,
                    zoomLevel: viewModel.state.zoomLevel,
                    panOffset: totalPanOffset
                )
                .mask(
                    Rectangle()
                        .frame(width: geometry.size.width * viewModel.state.sliderPosition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
            }
            
            // Divider and handle
            SliderDivider(
                position: viewModel.state.sliderPosition,
                geometry: geometry,
                onPositionChanged: { position in
                    viewModel.updateSliderPosition(position)
                }
            )
        }
        .gesture(panAndZoomGesture)
    }
    
    // MARK: - Side by Side Mode
    
    private func sideBySideView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 2) {
            // Original Image
            if let originalImage = originalImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: originalImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .overlay(
                        ImageLabel(text: "BEFORE", position: .topLeading)
                            .opacity(overlayOpacity)
                    )
                }
                .frame(width: geometry.size.width / 2)
            }
            
            // Processed Image
            if let processedImage = processedImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: processedImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .overlay(
                        ImageLabel(text: "AFTER", position: .topTrailing)
                            .opacity(overlayOpacity)
                    )
                }
                .frame(width: geometry.size.width / 2)
            }
        }
        .gesture(panAndZoomGesture)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(1.0)) {
                overlayOpacity = 1.0
            }
        }
    }
    
    // MARK: - Toggle Mode
    
    private func toggleView(geometry: GeometryProxy) -> some View {
        ZStack {
            Group {
                if viewModel.state.isShowingBefore {
                    if let originalImage = originalImage {
                        ImageView(
                            image: originalImage,
                            geometry: geometry,
                            zoomLevel: viewModel.state.zoomLevel,
                            panOffset: totalPanOffset
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                } else {
                    if let processedImage = processedImage {
                        ImageView(
                            image: processedImage,
                            geometry: geometry,
                            zoomLevel: viewModel.state.zoomLevel,
                            panOffset: totalPanOffset
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.state.isShowingBefore)
            
            // Toggle indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ToggleIndicator(isShowingBefore: viewModel.state.isShowingBefore)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.state.isShowingBefore.toggle()
                            }
                            HapticFeedback.light()
                        }
                    Spacer()
                }
                .padding(.bottom, 80)
            }
        }
        .gesture(panAndZoomGesture)
        .onTapGesture {
            toggleImages()
        }
    }
    
    // MARK: - Split Screen Mode
    
    private func splitScreenView(geometry: GeometryProxy) -> some View {
        Group {
            if viewModel.state.splitDirection == .horizontal {
                horizontalSplitView(geometry: geometry)
            } else {
                verticalSplitView(geometry: geometry)
            }
        }
        .gesture(panAndZoomGesture)
    }
    
    private func horizontalSplitView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 2) {
            // Top half - Original
            if let originalImage = originalImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: originalImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .clipped()
                }
                .frame(height: geometry.size.height * viewModel.state.sliderPosition)
            }
            
            // Bottom half - Processed
            if let processedImage = processedImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: processedImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .clipped()
                }
                .frame(height: geometry.size.height * (1 - viewModel.state.sliderPosition))
            }
        }
        .overlay(
            HorizontalSplitHandle(
                position: viewModel.state.sliderPosition,
                geometry: geometry,
                onPositionChanged: { position in
                    viewModel.updateSliderPosition(position)
                }
            )
        )
    }
    
    private func verticalSplitView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 2) {
            // Left half - Original
            if let originalImage = originalImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: originalImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .clipped()
                }
                .frame(width: geometry.size.width * viewModel.state.sliderPosition)
            }
            
            // Right half - Processed
            if let processedImage = processedImage {
                GeometryReader { subGeometry in
                    ImageView(
                        image: processedImage,
                        geometry: subGeometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset
                    )
                    .clipped()
                }
                .frame(width: geometry.size.width * (1 - viewModel.state.sliderPosition))
            }
        }
        .overlay(
            VerticalSplitHandle(
                position: viewModel.state.sliderPosition,
                geometry: geometry,
                onPositionChanged: { position in
                    viewModel.updateSliderPosition(position)
                }
            )
        )
    }
    
    // MARK: - Overlay Mode
    
    private func overlayView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Base image (original)
            if let originalImage = originalImage {
                ImageView(
                    image: originalImage,
                    geometry: geometry,
                    zoomLevel: viewModel.state.zoomLevel,
                    panOffset: totalPanOffset
                )
            }
            
            // Overlay image (processed) with opacity animation
            if let processedImage = processedImage {
                ImageView(
                    image: processedImage,
                    geometry: geometry,
                    zoomLevel: viewModel.state.zoomLevel,
                    panOffset: totalPanOffset
                )
                .opacity(viewModel.state.overlayProgress)
            }
            
            // Progress indicator
            VStack {
                Spacer()
                OverlayProgressView(
                    progress: viewModel.state.overlayProgress,
                    onProgressChanged: { progress in
                        viewModel.state.overlayProgress = progress
                    }
                )
                .padding(.bottom, 100)
            }
        }
        .gesture(panAndZoomGesture)
        .onAppear {
            startOverlayAnimation()
        }
    }
    
    // MARK: - Full Screen Mode
    
    private func fullScreenView(geometry: GeometryProxy) -> some View {
        ZStack {
            if viewModel.state.isShowingBefore {
                if let originalImage = originalImage {
                    ImageView(
                        image: originalImage,
                        geometry: geometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset,
                        allowFullZoom: true
                    )
                }
            } else {
                if let processedImage = processedImage {
                    ImageView(
                        image: processedImage,
                        geometry: geometry,
                        zoomLevel: viewModel.state.zoomLevel,
                        panOffset: totalPanOffset,
                        allowFullZoom: true
                    )
                }
            }
            
            // Full screen controls
            VStack {
                HStack {
                    Button("Exit") {
                        toggleFullScreen()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Button(viewModel.state.isShowingBefore ? "Show After" : "Show Before") {
                        toggleImages()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
        }
        .gesture(panAndZoomGesture)
        .background(Color.black)
    }
    
    // MARK: - Supporting Views
    
    private var controlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // Zoom controls
                VStack(spacing: 12) {
                    Button {
                        zoomIn()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        zoomOut()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        resetView()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private var bottomControlsBar: some View {
        HStack {
            // Info button
            Button {
                // Show image info
            } label: {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Split direction toggle (for split mode)
            if viewModel.state.currentMode == .splitScreen {
                Button {
                    toggleSplitDirection()
                } label: {
                    Image(systemName: viewModel.state.splitDirection.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Quick export
            Button {
                quickExport()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .background(
            Color.black.opacity(0.7)
                .blur(radius: 10)
        )
    }
    
    // MARK: - Enhancement Highlights
    
    private func enhancementHighlightOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(enhancementHighlights) { highlight in
                EnhancementHighlightView(
                    highlight: highlight,
                    imageSize: geometry.size,
                    zoomLevel: viewModel.state.zoomLevel,
                    panOffset: totalPanOffset
                )
            }
        }
    }
    
    // MARK: - Magnifier
    
    private func magnifierView(geometry: GeometryProxy) -> some View {
        MagnifierView(
            originalImage: originalImage,
            processedImage: processedImage,
            center: viewModel.state.magnifierPosition,
            size: viewModel.preferences.magnifierSize,
            showingBefore: viewModel.state.isShowingBefore
        )
        .position(viewModel.state.magnifierPosition)
    }
    
    // MARK: - Computed Properties
    
    private var totalPanOffset: CGSize {
        CGSize(
            width: viewModel.state.panOffset.width + viewModel.state.lastPanOffset.width,
            height: viewModel.state.panOffset.height + viewModel.state.lastPanOffset.height
        )
    }
    
    // MARK: - Gestures
    
    private var panAndZoomGesture: some Gesture {
        SimultaneousGesture(
            // Magnification gesture
            MagnificationGesture()
                .onChanged { value in
                    let newZoom = viewModel.state.zoomLevel * value
                    viewModel.updateZoomLevel(newZoom)
                }
                .onEnded { value in
                    let finalZoom = viewModel.state.zoomLevel * value
                    viewModel.updateZoomLevel(finalZoom)
                    
                    if viewModel.preferences.enableHaptics {
                        HapticFeedback.light()
                    }
                },
            
            // Pan gesture
            DragGesture()
                .onChanged { value in
                    viewModel.updatePanOffset(value.translation)
                }
                .onEnded { value in
                    viewModel.commitPanOffset()
                }
        )
    }
    
    // MARK: - Actions
    
    private func selectMode(_ mode: ComparisonMode) {
        viewModel.updateComparisonMode(mode)
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.selection()
        }
    }
    
    private func handleDoubleTap() {
        if viewModel.state.zoomLevel > 1.0 {
            resetView()
        } else {
            let targetZoom = viewModel.gestureConfig.doubleTapZoomLevel
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.updateZoomLevel(targetZoom)
            }
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.medium()
        }
    }
    
    private func toggleFullScreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingFullScreen.toggle()
            if showingFullScreen {
                viewModel.updateComparisonMode(.fullScreen)
            }
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.medium()
        }
    }
    
    private func toggleImages() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.state.isShowingBefore.toggle()
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.light()
        }
    }
    
    private func toggleSplitDirection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.state.splitDirection = viewModel.state.splitDirection == .horizontal ? .vertical : .horizontal
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.selection()
        }
    }
    
    private func zoomIn() {
        let newZoom = min(viewModel.state.zoomLevel * 1.5, viewModel.gestureConfig.maximumZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.updateZoomLevel(newZoom)
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.light()
        }
    }
    
    private func zoomOut() {
        let newZoom = max(viewModel.state.zoomLevel / 1.5, viewModel.gestureConfig.minimumZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.updateZoomLevel(newZoom)
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.light()
        }
    }
    
    private func resetView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.resetView()
        }
        
        if viewModel.preferences.enableHaptics {
            HapticFeedback.medium()
        }
    }
    
    private func startOverlayAnimation() {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // Auto-animate overlay if enabled
        if viewModel.preferences.enableAutoTransitions {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                viewModel.state.overlayProgress = 1.0
            }
        }
    }
    
    private func quickExport() {
        // Quick export functionality
        showingExportSheet = true
    }
    
    private func setupImages() {
        Task {
            let optimizedImages = await viewModel.prepareImages(
                original: originalImage,
                processed: processedImage
            )
            
            // Images are now optimized and cached
        }
    }
}

// MARK: - Preview
#Preview {
    EnhancedBeforeAfterView(
        originalImage: UIImage(systemName: "photo"),
        processedImage: UIImage(systemName: "photo.fill"),
        enhancementHighlights: []
    )
}