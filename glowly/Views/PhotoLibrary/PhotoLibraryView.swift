//
//  PhotoLibraryView.swift
//  Glowly
//
//  Beautiful photo library browser with custom styling
//

import SwiftUI
import Photos
import PhotosUI

struct PhotoLibraryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    // Selection
    @State private var selectedPhotos: Set<PHAsset> = []
    @State private var isSelectionMode = false
    @State private var showPermissionAlert = false
    @State private var isProcessing = false
    @State private var importProgress: Double = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.96, blue: 0.98),
                        Color(red: 0.98, green: 0.94, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Album selector
                    albumSelectorView
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    
                    // Photo grid
                    if viewModel.hasPermission {
                        photoGridView
                    } else {
                        permissionRequestView
                    }
                }
            }
            .navigationTitle("Choose Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        Button("Done") {
                            importSelectedPhotos()
                        }
                        .disabled(selectedPhotos.isEmpty)
                    } else {
                        Button("Select") {
                            isSelectionMode = true
                        }
                    }
                }
            }
            .overlay {
                if isProcessing {
                    importProgressOverlay
                }
            }
        }
        .onAppear {
            viewModel.checkPermission()
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please grant photo library access in Settings to import your photos.")
        }
    }
    
    // MARK: - View Components
    
    private var albumSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.albums) { album in
                    AlbumButton(
                        album: album,
                        isSelected: viewModel.selectedAlbum?.localIdentifier == album.localIdentifier
                    ) {
                        viewModel.selectAlbum(album)
                    }
                }
            }
        }
    }
    
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.photos) { photoAsset in
                    PhotoGridItem(
                        asset: photoAsset.asset,
                        isSelected: selectedPhotos.contains(photoAsset.asset),
                        isSelectionMode: isSelectionMode
                    ) {
                        if isSelectionMode {
                            toggleSelection(photoAsset.asset)
                        } else {
                            importSinglePhoto(photoAsset.asset)
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 10) {
                Text("Photo Access Required")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Grant access to your photos to import and enhance them with Glowly")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                Task {
                    await viewModel.requestPermission()
                    if !viewModel.hasPermission {
                        showPermissionAlert = true
                    }
                }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            
            Spacer()
        }
    }
    
    private var importProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Importing Photos")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                ProgressView(value: importProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
                
                Text("\(Int(importProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Methods
    
    private func toggleSelection(_ asset: PHAsset) {
        if selectedPhotos.contains(asset) {
            selectedPhotos.remove(asset)
        } else {
            selectedPhotos.insert(asset)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func importSinglePhoto(_ asset: PHAsset) {
        isProcessing = true
        
        Task {
            do {
                let photos = try await viewModel.importPhotos([asset]) { progress in
                    importProgress = progress
                }
                
                if let photo = photos.first {
                    await MainActor.run {
                        coordinator.navigateToEdit(photo: photo)
                        dismiss()
                    }
                }
            } catch {
                print("Error importing photo: \(error)")
            }
            
            isProcessing = false
        }
    }
    
    private func importSelectedPhotos() {
        guard !selectedPhotos.isEmpty else { return }
        
        isProcessing = true
        let assetsToImport = Array(selectedPhotos)
        
        Task {
            do {
                let photos = try await viewModel.importPhotos(assetsToImport) { progress in
                    importProgress = progress
                }
                
                if let firstPhoto = photos.first {
                    await MainActor.run {
                        coordinator.navigateToEdit(photo: firstPhoto)
                        dismiss()
                    }
                }
            } catch {
                print("Error importing photos: \(error)")
            }
            
            isProcessing = false
            isSelectionMode = false
            selectedPhotos.removeAll()
        }
    }
}

// MARK: - Album Button

struct AlbumButton: View {
    let album: PHAssetCollection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(isSelected ? .white : .secondary)
                    )
                
                // Title
                Text(album.localizedTitle ?? "Album")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pink : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var iconName: String {
        switch album.assetCollectionType {
        case .smartAlbum:
            switch album.assetCollectionSubtype {
            case .smartAlbumFavorites:
                return "heart.fill"
            case .smartAlbumRecentlyAdded:
                return "clock.fill"
            case .smartAlbumSelfPortraits:
                return "person.crop.square.fill"
            case .smartAlbumScreenshots:
                return "camera.viewfinder"
            default:
                return "photo.fill"
            }
        case .album:
            return "folder.fill"
        default:
            return "photo.fill"
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let asset: PHAsset
    let isSelected: Bool
    let isSelectionMode: Bool
    let action: () -> Void
    
    @State private var thumbnail: UIImage?
    private let imageManager = PHCachingImageManager()
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Photo thumbnail
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        )
                }
                
                // Selection overlay
                if isSelectionMode {
                    Rectangle()
                        .fill(isSelected ? Color.black.opacity(0.3) : Color.clear)
                    
                    // Checkmark
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .pink)
                            .padding(8)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .padding(8)
                    }
                }
                
                // Video indicator
                if asset.mediaType == .video {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.caption)
                        Text(formattedDuration)
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .clipShape(Rectangle())
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private var formattedDuration: String {
        let duration = asset.duration
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    
    private func loadThumbnail() {
        let size = CGSize(width: 200, height: 200)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var albums: [PHAssetCollection] = []
    @Published var selectedAlbum: PHAssetCollection?
    @Published var photos: [PhotoAsset] = []
    @Published var hasPermission = false
    
    private let photoImportService: PhotoImportService
    
    init() {
        let analyticsService = DIContainer.shared.resolve(AnalyticsServiceProtocol.self)
        let imageProcessingService = DIContainer.shared.resolve(ImageProcessingService.self) as! ImageProcessingService
        self.photoImportService = PhotoImportService(
            imageProcessingService: imageProcessingService,
            analyticsService: analyticsService
        )
        
        loadAlbums()
    }
    
    func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        hasPermission = status == .authorized || status == .limited
        
        if hasPermission {
            loadPhotos()
        }
    }
    
    func requestPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        hasPermission = status == .authorized || status == .limited
        
        if hasPermission {
            loadAlbums()
            loadPhotos()
        }
    }
    
    func loadAlbums() {
        var albums: [PHAssetCollection] = []
        
        // Smart albums
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        
        smartAlbums.enumerateObjects { collection, _, _ in
            if collection.assetCollectionSubtype == .smartAlbumUserLibrary ||
               collection.assetCollectionSubtype == .smartAlbumFavorites ||
               collection.assetCollectionSubtype == .smartAlbumRecentlyAdded ||
               collection.assetCollectionSubtype == .smartAlbumSelfPortraits {
                albums.append(collection)
            }
        }
        
        // User albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        
        userAlbums.enumerateObjects { collection, _, _ in
            albums.append(collection)
        }
        
        self.albums = albums
        
        // Select first album by default
        if let firstAlbum = albums.first {
            selectedAlbum = firstAlbum
            loadPhotos(from: firstAlbum)
        }
    }
    
    func selectAlbum(_ album: PHAssetCollection) {
        selectedAlbum = album
        loadPhotos(from: album)
    }
    
    func loadPhotos(from album: PHAssetCollection? = nil) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        let assets: PHFetchResult<PHAsset>
        if let album = album {
            assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        } else {
            assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        
        var photoAssets: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photoAssets.append(PhotoAsset(asset: asset))
        }
        
        self.photos = photoAssets
    }
    
    func importPhotos(_ assets: [PHAsset], progressHandler: @escaping (Double) -> Void) async throws -> [GlowlyPhoto] {
        return try await photoImportService.importFromPHAssets(assets)
    }
}

// MARK: - Photo Asset Model

struct PhotoAsset: Identifiable {
    let id = UUID()
    let asset: PHAsset
}