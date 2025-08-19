//
//  HomeView.swift
//  Glowly
//
//  Home screen view showing recent photos and import options
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var coordinator: MainCoordinator
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Import Actions
                    importActionsSection
                    
                    // Recent Photos
                    if viewModel.hasPhotos {
                        recentPhotosSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .navigationTitle("Glowly")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Navigate to settings
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .photosPicker(
            isPresented: $viewModel.showingImagePicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $viewModel.showingCamera) {
            CameraView()
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
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            Task {
                await viewModel.handleSelectedPhoto(newItem)
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enhance your photos with AI")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Stats or quick info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.recentPhotos.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Import Actions Section
    
    private var importActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Start Creating")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Camera Button
                ActionButton(
                    title: "Camera",
                    icon: "camera",
                    color: .blue,
                    action: {
                        viewModel.importPhotoFromCamera()
                    }
                )
                
                // Photo Library Button
                ActionButton(
                    title: "Photo Library",
                    icon: "photo.on.rectangle",
                    color: .green,
                    action: {
                        viewModel.importPhotoFromLibrary()
                    }
                )
            }
        }
    }
    
    // MARK: - Recent Photos Section
    
    private var recentPhotosSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Photos")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to all photos
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.recentPhotos.prefix(6)) { photo in
                    PhotoCard(
                        photo: photo,
                        onTap: {
                            coordinator.navigateToEdit(photo: photo)
                        },
                        onDelete: {
                            Task {
                                await viewModel.deletePhoto(photo)
                            }
                        },
                        onShare: {
                            Task {
                                await viewModel.sharePhoto(photo)
                            }
                        },
                        onSave: {
                            Task {
                                await viewModel.saveToLibrary(photo)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State Section
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Photos Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Import your first photo to start enhancing with AI")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Take Photo") {
                    viewModel.importPhotoFromCamera()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Choose from Library") {
                    viewModel.importPhotoFromLibrary()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PhotoCard: View {
    let photo: GlowlyPhoto
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                
                if let thumbnailData = photo.thumbnailImage,
                   let image = UIImage(data: thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                
                // Enhancement indicator
                if photo.enhancedImage != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                )
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                contextMenuItems
            }
            
            // Photo info
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(photo.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !photo.enhancementHistory.isEmpty {
                    Text("\(photo.enhancementHistory.count) enhancements")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            onTap()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Button {
            onShare()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button {
            onSave()
        } label: {
            Label("Save to Library", systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Processing...")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.8))
            )
        }
    }
}


#Preview {
    HomeView()
        .environmentObject(DIContainer.shared.resolve(MainCoordinatorProtocol.self) as! MainCoordinator)
}