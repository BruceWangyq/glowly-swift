//
//  PhotoImportButton.swift
//  Glowly
//
//  Reusable photo import button with multiple options
//

import SwiftUI
import PhotosUI

struct PhotoImportButton: View {
    @State private var showImportOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    let onPhotoImported: (GlowlyPhoto) -> Void
    
    var body: some View {
        Button {
            showImportOptions = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Import Photo")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .confirmationDialog("Import Photo", isPresented: $showImportOptions) {
            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera.fill")
            }
            
            Button {
                showPhotoLibrary = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .fullScreenCover(isPresented: $showPhotoLibrary) {
            PhotoLibraryView()
        }
    }
}

// MARK: - Quick Import Card

struct QuickImportCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { _ in
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Photo Import Options View

struct PhotoImportOptionsView: View {
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showRecentPhotos = false
    
    let onPhotoImported: (GlowlyPhoto) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Import Your Photo")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            HStack(spacing: 12) {
                QuickImportCard(
                    title: "Camera",
                    subtitle: "Take a new selfie",
                    icon: "camera.fill",
                    gradientColors: [.pink, .orange]
                ) {
                    showCamera = true
                }
                
                QuickImportCard(
                    title: "Photos",
                    subtitle: "Choose from library",
                    icon: "photo.fill",
                    gradientColors: [.purple, .blue]
                ) {
                    showPhotoLibrary = true
                }
            }
            .frame(height: 120)
            
            // Recent photos section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Photos")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showRecentPhotos = true
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }
                
                RecentPhotosRow(onPhotoSelected: onPhotoImported)
            }
            .padding(.top)
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .fullScreenCover(isPresented: $showPhotoLibrary) {
            PhotoLibraryView()
        }
        .sheet(isPresented: $showRecentPhotos) {
            RecentPhotosView(onPhotoSelected: onPhotoImported)
        }
    }
}

// MARK: - Recent Photos Row

struct RecentPhotosRow: View {
    @StateObject private var viewModel = RecentPhotosViewModel()
    let onPhotoSelected: (GlowlyPhoto) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            )
                    }
                } else {
                    ForEach(viewModel.recentPhotos.prefix(10)) { photo in
                        RecentPhotoThumbnail(
                            photo: photo,
                            onTap: {
                                onPhotoSelected(photo)
                            }
                        )
                    }
                }
            }
        }
        .frame(height: 80)
        .onAppear {
            viewModel.loadRecentPhotos()
        }
    }
}

// MARK: - Recent Photo Thumbnail

struct RecentPhotoThumbnail: View {
    let photo: GlowlyPhoto
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnailData = photo.thumbnailImage,
                   let image = UIImage(data: thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.gray)
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Recent Photos View

struct RecentPhotosView: View {
    @StateObject private var viewModel = RecentPhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onPhotoSelected: (GlowlyPhoto) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.recentPhotos) { photo in
                        Button {
                            onPhotoSelected(photo)
                            dismiss()
                        } label: {
                            if let thumbnailData = photo.thumbnailImage,
                               let image = UIImage(data: thumbnailData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fill)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(.gray)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .navigationTitle("Recent Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadRecentPhotos()
        }
    }
}

// MARK: - Recent Photos View Model

@MainActor
class RecentPhotosViewModel: ObservableObject {
    @Published var recentPhotos: [GlowlyPhoto] = []
    @Published var isLoading = false
    
    private let photoImportService: PhotoImportService
    
    init() {
        let analyticsService = DIContainer.shared.resolve(AnalyticsServiceProtocol.self)
        let imageProcessingService = DIContainer.shared.resolve(ImageProcessingService.self) as! ImageProcessingService
        self.photoImportService = PhotoImportService(
            imageProcessingService: imageProcessingService,
            analyticsService: analyticsService
        )
    }
    
    func loadRecentPhotos() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let photos = try await photoImportService.loadRecentPhotos(limit: 30)
                self.recentPhotos = photos
            } catch {
                print("Error loading recent photos: \(error)")
            }
            
            isLoading = false
        }
    }
}