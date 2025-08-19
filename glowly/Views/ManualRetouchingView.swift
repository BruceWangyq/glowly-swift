//
//  ManualRetouchingView.swift
//  Glowly
//
//  Comprehensive manual retouching interface with category-based tool organization
//

import SwiftUI

struct ManualRetouchingView: View {
    @StateObject private var viewModel: ManualRetouchingViewModel
    @Environment(\.dismiss) private var dismiss
    @GestureState private var magnification: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var currentZoom: CGFloat = 1.0
    
    init(photo: GlowlyPhoto) {
        _viewModel = StateObject(wrappedValue: ManualRetouchingViewModel(photo: photo))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Main Content
                HStack(spacing: 0) {
                    // Photo Canvas
                    photoCanvasSection
                        .frame(width: geometry.size.width * 0.75)
                    
                    // Tool Panel
                    toolPanelSection
                        .frame(width: geometry.size.width * 0.25)
                        .background(Color(.systemGray6))
                }
                
                // Bottom Controls
                bottomControlsSection
                    .frame(height: 80)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingBeforeAfter) {
            BeforeAfterComparisonView(
                originalImage: viewModel.originalImage,
                processedImage: viewModel.currentImage
            )
        }
        .sheet(isPresented: $viewModel.showingColorPicker) {
            ColorPickerView(
                selectedColor: $viewModel.selectedColor,
                colorPalettes: viewModel.availableColorPalettes
            )
        }
        .alert("Processing Error", isPresented: $viewModel.showingError) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            if viewModel.isProcessing {
                ProcessingOverlay(progress: viewModel.processingProgress)
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("Manual Retouching")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    viewModel.showingBeforeAfter = true
                } label: {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.title3)
                }
                
                Button {
                    viewModel.undoLastOperation()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                }
                .disabled(!viewModel.canUndo)
                
                Button {
                    viewModel.redoLastOperation()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title3)
                }
                .disabled(!viewModel.canRedo)
                
                Button("Done") {
                    Task {
                        await viewModel.saveChanges()
                        dismiss()
                    }
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Photo Canvas Section
    
    private var photoCanvasSection: some View {
        ZStack {
            Color.black
            
            if let image = viewModel.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(currentZoom * magnification)
                    .offset(x: offset.x + lastOffset.x, y: offset.y + lastOffset.y)
                    .gesture(
                        SimultaneousGesture(
                            // Magnification gesture
                            MagnificationGesture()
                                .updating($magnification) { value, state, _ in
                                    state = value
                                }
                                .onEnded { value in
                                    currentZoom *= value
                                    currentZoom = min(max(currentZoom, 0.5), 3.0)
                                },
                            
                            // Pan gesture
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                                .onEnded { value in
                                    lastOffset.width += value.translation.width
                                    lastOffset.height += value.translation.height
                                    offset = .zero
                                }
                        )
                    )
                    .gesture(
                        // Brush gesture for retouching
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if viewModel.activeTool != nil {
                                    viewModel.addTouchPoint(value.location, pressure: 1.0)
                                }
                            }
                            .onEnded { _ in
                                if viewModel.activeTool != nil {
                                    Task {
                                        await viewModel.applyCurrentBrushStroke()
                                    }
                                }
                            }
                    )
            }
            
            // Tool overlay indicators
            if let activeTool = viewModel.activeTool {
                BrushCursorView(
                    position: viewModel.lastTouchPoint,
                    size: CGFloat(viewModel.brushConfiguration.size),
                    hardness: CGFloat(viewModel.brushConfiguration.hardness),
                    opacity: CGFloat(viewModel.brushConfiguration.opacity)
                )
            }
            
            // Zoom controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZoomControlsView(
                        currentZoom: $currentZoom,
                        onReset: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentZoom = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    )
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Tool Panel Section
    
    private var toolPanelSection: some View {
        VStack(spacing: 0) {
            // Tool Categories
            toolCategoriesHeader
            
            Divider()
            
            // Tool Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.toolsForSelectedCategory, id: \.self) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: viewModel.activeTool == tool,
                            action: {
                                viewModel.selectTool(tool)
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Tool Settings
            if viewModel.activeTool != nil {
                toolSettingsSection
            }
        }
    }
    
    private var toolCategoriesHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EnhancementCategory.allCases.filter { $0 != .basic && $0 != .ai }, id: \.self) { category in
                    CategoryTabButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            viewModel.selectCategory(category)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var toolSettingsSection: some View {
        VStack(spacing: 16) {
            Text("Tool Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Brush Size
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\\(Int(viewModel.brushConfiguration.size))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.brushConfiguration.size },
                        set: { viewModel.updateBrushSize($0) }
                    ),
                    in: 1...100,
                    step: 1
                )
                .accentColor(.blue)
            }
            
            // Hardness
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hardness")
                        .font(.subheadline)
                    Spacer()
                    Text("\\(Int(viewModel.brushConfiguration.hardness * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.brushConfiguration.hardness },
                        set: { viewModel.updateBrushHardness($0) }
                    ),
                    in: 0...1,
                    step: 0.01
                )
                .accentColor(.blue)
            }
            
            // Opacity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Opacity")
                        .font(.subheadline)
                    Spacer()
                    Text("\\(Int(viewModel.brushConfiguration.opacity * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.brushConfiguration.opacity },
                        set: { viewModel.updateBrushOpacity($0) }
                    ),
                    in: 0...1,
                    step: 0.01
                )
                .accentColor(.blue)
            }
            
            // Intensity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Intensity")
                        .font(.subheadline)
                    Spacer()
                    Text("\\(Int(viewModel.toolIntensity * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $viewModel.toolIntensity,
                    in: 0...1,
                    step: 0.01
                )
                .accentColor(.blue)
            }
            
            // Color selection for color-changing tools
            if viewModel.isColorTool {
                Button {
                    viewModel.showingColorPicker = true
                } label: {
                    HStack {
                        Text("Color")
                            .font(.subheadline)
                        Spacer()
                        Circle()
                            .fill(viewModel.selectedColor.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bottom Controls Section
    
    private var bottomControlsSection: some View {
        HStack {
            Button {
                viewModel.resetToOriginal()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .disabled(!viewModel.hasChanges)
            
            Spacer()
            
            if viewModel.hasChanges {
                VStack(spacing: 2) {
                    Text("Operations: \\(viewModel.operationCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Time: \\(viewModel.totalProcessingTime, specifier: \"%.1f\")s")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button {
                // Additional options
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Supporting Views

struct ToolButton: View {
    let tool: EnhancementType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(height: 50)
                    
                    Image(systemName: iconForTool(tool))
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(tool.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if tool.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func iconForTool(_ tool: EnhancementType) -> String {
        switch tool {
        // Skin tools
        case .skinBrightening, .skinSmoothing: return "sparkles"
        case .oilControl, .matteFinish: return "drop.fill"
        case .poreMinimizer: return "circle.grid.cross.fill"
        case .acneRemover: return "cross.circle.fill"
        case .skinTemperature: return "thermometer"
        
        // Face shape tools
        case .faceSlimming, .jawlineDefinition: return "oval"
        case .noseReshaping: return "triangle"
        case .chinAdjustment: return "diamond"
        case .cheekEnhancement: return "heart"
        case .faceContour: return "paintbrush"
        
        // Eye tools
        case .eyeEnlargement, .eyeSymmetry: return "eye"
        case .eyeColorChanger: return "eyedropper"
        case .darkCircleRemoval: return "circle.slash"
        case .eyelashEnhancement: return "line.3.horizontal"
        case .eyebrowShaping: return "minus"
        case .eyeContrast, .eyeBrightening: return "sun.max"
        
        // Mouth tools
        case .teethWhitening, .advancedTeethWhitening: return "mouth"
        case .lipPlumping, .lipEnhancement: return "lips.fill"
        case .lipColorChanger: return "paintpalette"
        case .lipGloss: return "wand.and.stars"
        case .smileAdjustment: return "face.smiling"
        case .lipLineDefinition: return "pencil"
        
        // Hair tools
        case .hairColorChanger: return "paintpalette.fill"
        case .hairVolumeEnhancement: return "waveform"
        case .hairShine: return "sparkle"
        case .hairTexture: return "scribble"
        case .hairHighlights: return "sun.max.fill"
        case .hairBoundaryRefinement: return "scissors"
        
        // Body tools
        case .bodySlimming, .bodyReshaping: return "figure.stand"
        case .heightAdjustment: return "arrow.up.and.down"
        case .muscleDefinition: return "figure.strengthtraining.traditional"
        case .postureCorrection: return "figure.stand.line.dotted.figure.stand"
        case .bodyProportioning: return "rectangle.resize"
        
        default: return "slider.horizontal.3"
        }
    }
}

struct CategoryTabButton: View {
    let category: EnhancementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
}

struct BrushCursorView: View {
    let position: CGPoint
    let size: CGFloat
    let hardness: CGFloat
    let opacity: CGFloat
    
    var body: some View {
        ZStack {
            // Outer circle (soft edge)
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: size, height: size)
            
            // Inner circle (hard edge)
            if hardness > 0.5 {
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    .frame(width: size * hardness, height: size * hardness)
            }
            
            // Center dot
            Circle()
                .fill(Color.white.opacity(opacity))
                .frame(width: 2, height: 2)
        }
        .position(position)
        .allowsHitTesting(false)
    }
}

struct ZoomControlsView: View {
    @Binding var currentZoom: CGFloat
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                currentZoom = min(currentZoom * 1.5, 3.0)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            
            Button {
                onReset()
            } label: {
                Text("\\(Int(currentZoom * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.black.opacity(0.5)))
            }
            
            Button {
                currentZoom = max(currentZoom / 1.5, 0.5)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let samplePhoto = GlowlyPhoto(
        originalImage: Data(),
        metadata: PhotoMetadata()
    )
    
    return ManualRetouchingView(photo: samplePhoto)
}