//
//  EditView.swift
//  Glowly
//
//  Photo editing view with enhancement controls
//

import SwiftUI

struct EditView: View {
    @StateObject private var viewModel: EditViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: MainCoordinator
    
    init(photo: GlowlyPhoto) {
        _viewModel = StateObject(wrappedValue: EditViewModel(photo: photo))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Photo Preview
                photoPreviewSection
                    .frame(height: geometry.size.height * 0.6)
                
                // Enhancement Controls
                enhancementControlsSection
                    .frame(height: geometry.size.height * 0.4)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingPresets) {
            PresetsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingExportOptions) {
            ExportOptionsView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
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
            
            Text("Edit Photo")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    Task {
                        await viewModel.resetToOriginal()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(!viewModel.hasChanges)
                
                Button("Save") {
                    Task {
                        await viewModel.saveToLibrary()
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
    
    // MARK: - Photo Preview Section
    
    private var photoPreviewSection: some View {
        ZStack {
            Color.black
            
            if let image = viewModel.previewImage ?? viewModel.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Image")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // Undo/Redo buttons overlay
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button {
                            viewModel.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                )
                        }
                        .disabled(!viewModel.canUndo)
                        
                        Button {
                            viewModel.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                )
                        }
                        .disabled(!viewModel.canRedo)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Enhancement Controls Section
    
    private var enhancementControlsSection: some View {
        VStack(spacing: 0) {
            // Enhancement Categories
            enhancementCategoriesBar
            
            Divider()
            
            // Selected Enhancement Controls
            if let selectedEnhancement = viewModel.selectedEnhancement {
                enhancementControlPanel(for: selectedEnhancement)
            } else {
                enhancementGridView
            }
            
            Divider()
            
            // Bottom Action Bar
            bottomActionBar
        }
        .background(Color(.systemBackground))
    }
    
    private var enhancementCategoriesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(viewModel.enhancementCategories, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: false, // Would track selected category
                        action: {
                            // Handle category selection
                        }
                    )
                }
                
                // Presets button
                Button {
                    viewModel.showingPresets = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                        
                        Text("Presets")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                }
                
                // Manual Retouching button
                NavigationLink(destination: ManualRetouchingView(photo: viewModel.originalPhoto)) {
                    VStack(spacing: 6) {
                        Image(systemName: "paintbrush.pointed")
                            .font(.title3)
                        
                        Text("Manual")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    private var enhancementGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(EnhancementType.allCases.prefix(12), id: \.self) { enhancement in
                    EnhancementButton(
                        enhancement: enhancement,
                        isSelected: viewModel.selectedEnhancement == enhancement,
                        action: {
                            viewModel.selectEnhancement(enhancement)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private func enhancementControlPanel(for enhancement: EnhancementType) -> some View {
        VStack(spacing: 20) {
            // Enhancement info
            VStack(spacing: 8) {
                Text(enhancement.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Adjust the intensity of the enhancement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Intensity slider
            VStack(spacing: 12) {
                HStack {
                    Text("Intensity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.enhancementIntensity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Slider(
                    value: $viewModel.enhancementIntensity,
                    in: 0...1,
                    step: 0.01
                ) {
                    viewModel.updateEnhancementIntensity(viewModel.enhancementIntensity)
                }
                .accentColor(.blue)
            }
            .padding(.horizontal)
            
            // Apply/Cancel buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.selectedEnhancement = nil
                    viewModel.previewImage = viewModel.currentImage
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Apply") {
                    Task {
                        await viewModel.applyCurrentEnhancement()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canApplyEnhancement)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var bottomActionBar: some View {
        HStack {
            Button {
                Task {
                    await viewModel.exportPhoto()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            
            Spacer()
            
            if viewModel.hasChanges {
                VStack(spacing: 2) {
                    Text("Processing Time:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.totalProcessingTime, specifier: "%.1f")s")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button {
                // Show more options
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: EnhancementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title3)
                
                Text(category.displayName)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .padding(.horizontal, 8)
        }
    }
}

struct EnhancementButton: View {
    let enhancement: EnhancementType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                        .frame(height: 50)
                    
                    Image(systemName: iconForEnhancement(enhancement))
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(enhancement.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if enhancement.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func iconForEnhancement(_ enhancement: EnhancementType) -> String {
        switch enhancement.category {
        case .basic:
            return "slider.horizontal.3"
        case .beauty:
            return "face.smiling"
        case .ai:
            return "brain.head.profile"
        }
    }
}

struct ProcessingOverlay: View {
    let progress: Float
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing Enhancement...")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Sheet Views (Placeholders)

struct PresetsView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.availablePresets) { preset in
                        PresetCard(preset: preset) {
                            Task {
                                await viewModel.applyPreset(preset)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PresetCard: View {
    let preset: EnhancementPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Preset preview (placeholder)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(preset.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if preset.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(preset.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ExportOptionsView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export Options")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose how to save your enhanced photo")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                VStack(spacing: 16) {
                    Button("Save to Photo Library") {
                        Task {
                            await viewModel.saveToLibrary()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Share") {
                        // Handle sharing
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let samplePhoto = GlowlyPhoto(
        originalImage: Data(),
        metadata: PhotoMetadata()
    )
    
    return EditView(photo: samplePhoto)
        .environmentObject(DIContainer.shared.resolve(MainCoordinatorProtocol.self) as! MainCoordinator)
}