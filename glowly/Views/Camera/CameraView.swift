//
//  CameraView.swift
//  Glowly
//
//  Beautiful camera interface for photo capture
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var photoImportService: PhotoImportService
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var showPhotoLibrary = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var capturedImage: UIImage?
    @State private var showCapturedImage = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGridLines = false
    @State private var currentZoom: CGFloat = 1.0
    @State private var showFlashOptions = false
    @State private var focusLocation: CGPoint?
    @State private var showFocusAnimation = false
    
    // Animation states
    @State private var captureButtonScale: CGFloat = 1.0
    @State private var switchCameraRotation: Double = 0
    
    init() {
        let analyticsService = DIContainer.shared.resolve(AnalyticsServiceProtocol.self)
        let imageProcessingService = DIContainer.shared.resolve(ImageProcessingService.self) as! ImageProcessingService
        _photoImportService = StateObject(wrappedValue: PhotoImportService(
            imageProcessingService: imageProcessingService,
            analyticsService: analyticsService
        ))
    }
    
    var body: some View {
        ZStack {
            // Camera preview layer
            CameraPreviewView(cameraService: cameraService)
                .ignoresSafeArea()
                .overlay(
                    Group {
                        if showGridLines {
                            GridLinesOverlay()
                        }
                    }
                )
                .overlay(
                    Group {
                        if let location = focusLocation, showFocusAnimation {
                            FocusIndicator(location: location)
                                .onAppear {
                                    withAnimation(.easeOut(duration: 1.0)) {
                                        showFocusAnimation = false
                                    }
                                }
                        }
                    }
                )
                .onTapGesture { location in
                    handleTapToFocus(at: location)
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / currentZoom
                            currentZoom = value
                            cameraService.setZoom(currentZoom)
                        }
                )
            
            // UI Overlay
            VStack {
                // Top controls
                topControlsView
                
                Spacer()
                
                // Bottom controls
                bottomControlsView
            }
            .padding(.horizontal)
            .padding(.vertical, 30)
            
            // Processing overlay
            if isProcessing {
                ProcessingOverlay()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onAppear {
            Task {
                await setupCamera()
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotos) { items in
            Task {
                await importSelectedPhotos(items)
            }
        }
        .sheet(isPresented: $showCapturedImage) {
            if let image = capturedImage {
                CapturedImageView(
                    image: image,
                    onRetake: {
                        capturedImage = nil
                        showCapturedImage = false
                    },
                    onUse: {
                        Task {
                            await processCapturedImage(image)
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var topControlsView: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Flash control
            Menu {
                Button {
                    cameraService.setFlashMode(.auto)
                } label: {
                    Label("Auto", systemImage: "bolt.badge.a")
                }
                
                Button {
                    cameraService.setFlashMode(.on)
                } label: {
                    Label("On", systemImage: "bolt.fill")
                }
                
                Button {
                    cameraService.setFlashMode(.off)
                } label: {
                    Label("Off", systemImage: "bolt.slash")
                }
            } label: {
                Image(systemName: flashIconName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Grid lines toggle
            Button {
                withAnimation {
                    showGridLines.toggle()
                }
            } label: {
                Image(systemName: showGridLines ? "grid" : "grid.circle")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
    
    private var bottomControlsView: some View {
        HStack(spacing: 50) {
            // Photo library button
            Button {
                showPhotoLibrary = true
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundStyle(.white)
                    )
            }
            
            // Capture button
            Button {
                Task {
                    await capturePhoto()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 3)
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 65, height: 65)
                }
                .scaleEffect(captureButtonScale)
            }
            .disabled(isProcessing || cameraService.isCapturing)
            
            // Switch camera button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    switchCameraRotation += 180
                    cameraService.switchCamera()
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .rotation3DEffect(
                        .degrees(switchCameraRotation),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
        }
        .padding(.bottom, 20)
    }
    
    private var flashIconName: String {
        switch cameraService.flashMode {
        case .auto:
            return "bolt.badge.a.fill"
        case .on:
            return "bolt.fill"
        case .off:
            return "bolt.slash.fill"
        @unknown default:
            return "bolt.slash.fill"
        }
    }
    
    // MARK: - Methods
    
    private func setupCamera() async {
        do {
            try await cameraService.setupCamera()
            cameraService.startSession()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func capturePhoto() async {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate capture button
        withAnimation(.easeInOut(duration: 0.1)) {
            captureButtonScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                captureButtonScale = 1.0
            }
        }
        
        do {
            let image = try await cameraService.capturePhoto()
            capturedImage = image
            showCapturedImage = true
            
            // Success haptic
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            
            // Error haptic
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }
    
    private func handleTapToFocus(at location: CGPoint) {
        // Convert tap location to camera coordinate
        let screenSize = UIScreen.main.bounds.size
        let focusPoint = CGPoint(
            x: location.x / screenSize.width,
            y: location.y / screenSize.height
        )
        
        // Set focus and exposure
        cameraService.focus(at: focusPoint)
        cameraService.setExposure(at: focusPoint)
        
        // Show focus animation
        focusLocation = location
        showFocusAnimation = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func importSelectedPhotos(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        
        do {
            let photos = try await photoImportService.importPhotos(from: items)
            
            // Navigate to edit view with imported photos
            if let firstPhoto = photos.first {
                await MainActor.run {
                    coordinator.navigateToEdit(photo: firstPhoto)
                    dismiss()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
        selectedPhotos = []
    }
    
    private func processCapturedImage(_ image: UIImage) async {
        isProcessing = true
        showCapturedImage = false
        
        do {
            let photo = try await photoImportService.processImportedImage(image, source: .camera)
            
            await MainActor.run {
                coordinator.navigateToEdit(photo: photo)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }
}

// MARK: - Grid Lines Overlay

struct GridLinesOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))
                
                path.move(to: CGPoint(x: 2 * width / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * width / 3, y: height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))
                
                path.move(to: CGPoint(x: 0, y: 2 * height / 3))
                path.addLine(to: CGPoint(x: width, y: 2 * height / 3))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        }
    }
}

// MARK: - Focus Indicator

struct FocusIndicator: View {
    let location: CGPoint
    @State private var animationScale: CGFloat = 1.5
    @State private var animationOpacity: Double = 1.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 80, height: 80)
            .position(location)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    animationScale = 1.0
                }
                
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    animationOpacity = 0.0
                }
            }
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Captured Image View

struct CapturedImageView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 50) {
                        Button {
                            onRetake()
                        } label: {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                Text("Retake")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        Button {
                            onUse()
                        } label: {
                            VStack {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                Text("Use Photo")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}