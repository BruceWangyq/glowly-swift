//
//  FilterDiscoveryView.swift
//  Glowly
//
//  Beautiful filter discovery interface with live previews and advanced filtering
//

import SwiftUI

/// Main filter discovery interface
struct FilterDiscoveryView: View {
    @StateObject private var viewModel = FilterDiscoveryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var searchText = ""
    @State private var selectedCategory: FilterCategory = .warm
    @State private var showingFilterSheet = false
    @State private var selectedFilter: BeautyFilter?
    @State private var showingMakeupLooks = false
    @State private var showingBackgroundEffects = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                GlowlyTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with image selection
                    headerSection
                    
                    // Content tabs
                    contentTabsSection
                    
                    // Main content
                    mainContentSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadFilters()
            }
            .sheet(isPresented: $showingFilterSheet) {
                if let filter = selectedFilter {
                    FilterDetailView(filter: filter, selectedImage: selectedImage)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(GlowlyTheme.text)
                        .frame(width: 32, height: 32)
                        .background(GlowlyTheme.cardBackground)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Filters & Effects")
                    .font(GlowlyTheme.headingFont)
                    .foregroundColor(GlowlyTheme.text)
                
                Spacer()
                
                Button(action: { /* Settings */ }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(GlowlyTheme.text)
                        .frame(width: 32, height: 32)
                        .background(GlowlyTheme.cardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            // Image preview area
            imagePreviewSection
            
            // Search bar
            searchBarSection
        }
        .padding(.vertical, 16)
    }
    
    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                // Image with filter preview
                ImageWithFilterPreview(
                    image: image,
                    selectedFilter: selectedFilter,
                    onImageTap: { showImagePicker() }
                )
            } else {
                // Image selection placeholder
                Button(action: { showImagePicker() }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(GlowlyTheme.accent)
                        
                        Text("Select Photo")
                            .font(GlowlyTheme.bodyFont)
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(GlowlyTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(GlowlyTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
                    )
                }
            }
            
            // Quick action buttons
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "camera",
                    title: "Camera",
                    action: { openCamera() }
                )
                
                QuickActionButton(
                    icon: "photo.on.rectangle",
                    title: "Gallery",
                    action: { showImagePicker() }
                )
                
                QuickActionButton(
                    icon: "wand.and.stars",
                    title: "Random",
                    action: { selectRandomFilter() }
                )
                
                QuickActionButton(
                    icon: "heart",
                    title: "Favorites",
                    action: { showFavorites() }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GlowlyTheme.secondaryText)
                
                TextField("Search filters...", text: $searchText)
                    .font(GlowlyTheme.bodyFont)
                    .foregroundColor(GlowlyTheme.text)
                    .onChange(of: searchText) { value in
                        viewModel.searchFilters(query: value)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(GlowlyTheme.cardBackground)
            .clipShape(Capsule())
            
            // Filter button
            Button(action: { /* Show filter options */ }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(GlowlyTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(GlowlyTheme.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Content Tabs Section
    
    private var contentTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ContentTab(
                    title: "Beauty Filters",
                    icon: "sparkles",
                    isSelected: !showingMakeupLooks && !showingBackgroundEffects,
                    action: {
                        showingMakeupLooks = false
                        showingBackgroundEffects = false
                    }
                )
                
                ContentTab(
                    title: "Makeup Looks",
                    icon: "paintbrush",
                    isSelected: showingMakeupLooks,
                    action: {
                        showingMakeupLooks = true
                        showingBackgroundEffects = false
                    }
                )
                
                ContentTab(
                    title: "Backgrounds",
                    icon: "photo.stack",
                    isSelected: showingBackgroundEffects,
                    action: {
                        showingMakeupLooks = false
                        showingBackgroundEffects = true
                    }
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Main Content Section
    
    private var mainContentSection: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                if !showingMakeupLooks && !showingBackgroundEffects {
                    // Beauty Filters Content
                    beautyFiltersContent
                } else if showingMakeupLooks {
                    // Makeup Looks Content
                    makeupLooksContent
                } else {
                    // Background Effects Content
                    backgroundEffectsContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    private var beautyFiltersContent: some View {
        Group {
            // Categories
            Section {
                FilterCategoriesView(
                    selectedCategory: $selectedCategory,
                    onCategorySelected: { category in
                        viewModel.filterByCategory(category)
                    }
                )
            } header: {
                SectionHeader(title: "Categories", subtitle: "Explore different filter styles")
            }
            
            // Trending Filters
            if !viewModel.trendingFilters.isEmpty {
                Section {
                    FilterHorizontalScrollView(
                        title: "Trending",
                        filters: viewModel.trendingFilters,
                        selectedImage: selectedImage,
                        onFilterSelected: { filter in
                            selectedFilter = filter
                            showingFilterSheet = true
                        }
                    )
                } header: {
                    SectionHeader(title: "Trending Now", subtitle: "Popular filters this week")
                }
            }
            
            // Filter Grid
            Section {
                FilterGridView(
                    filters: viewModel.filteredFilters,
                    selectedImage: selectedImage,
                    onFilterSelected: { filter in
                        selectedFilter = filter
                        showingFilterSheet = true
                    }
                )
            } header: {
                SectionHeader(
                    title: selectedCategory.displayName,
                    subtitle: "\(viewModel.filteredFilters.count) filters available"
                )
            }
        }
    }
    
    private var makeupLooksContent: some View {
        Group {
            // Makeup Categories
            Section {
                MakeupCategoriesView(onCategorySelected: { category in
                    viewModel.filterMakeupByCategory(category)
                })
            } header: {
                SectionHeader(title: "Makeup Styles", subtitle: "Choose your perfect look")
            }
            
            // Featured Looks
            Section {
                MakeupLooksGridView(
                    looks: viewModel.makeupLooks,
                    selectedImage: selectedImage,
                    onLookSelected: { look in
                        // Handle makeup look selection
                    }
                )
            } header: {
                SectionHeader(title: "Featured Looks", subtitle: "Curated by makeup artists")
            }
        }
    }
    
    private var backgroundEffectsContent: some View {
        Group {
            // Background Categories
            Section {
                BackgroundCategoriesView(onCategorySelected: { category in
                    viewModel.filterBackgroundsByCategory(category)
                })
            } header: {
                SectionHeader(title: "Background Styles", subtitle: "Transform your photo background")
            }
            
            // Background Effects Grid
            Section {
                BackgroundEffectsGridView(
                    effects: viewModel.backgroundEffects,
                    selectedImage: selectedImage,
                    onEffectSelected: { effect in
                        // Handle background effect selection
                    }
                )
            } header: {
                SectionHeader(title: "Effects", subtitle: "AI-powered background transformation")
            }
        }
    }
    
    // MARK: - Action Methods
    
    private func showImagePicker() {
        // Implementation for image picker
    }
    
    private func openCamera() {
        // Implementation for camera
    }
    
    private func selectRandomFilter() {
        if let randomFilter = viewModel.filteredFilters.randomElement() {
            selectedFilter = randomFilter
            if selectedImage != nil {
                showingFilterSheet = true
            }
        }
    }
    
    private func showFavorites() {
        viewModel.showFavoriteFilters()
    }
}

// MARK: - Supporting Views

/// Quick action button component
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(GlowlyTheme.accent)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(GlowlyTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(GlowlyTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// Content tab component
struct ContentTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : GlowlyTheme.secondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected ? GlowlyTheme.accent : GlowlyTheme.cardBackground
            )
            .clipShape(Capsule())
        }
    }
}

/// Section header component
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(GlowlyTheme.headingFont)
                    .foregroundColor(GlowlyTheme.text)
                
                Spacer()
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(GlowlyTheme.captionFont)
                    .foregroundColor(GlowlyTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
        .background(GlowlyTheme.background)
    }
}

/// Image with filter preview component
struct ImageWithFilterPreview: View {
    let image: UIImage
    let selectedFilter: BeautyFilter?
    let onImageTap: () -> Void
    
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview = false
    
    var body: some View {
        Button(action: onImageTap) {
            ZStack {
                // Base image or preview
                Image(uiImage: previewImage ?? image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Loading overlay
                if isLoadingPreview {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                
                // Filter name overlay
                if let filter = selectedFilter {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text(filter.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.6))
                                )
                            
                            Spacer()
                        }
                        .padding(.bottom, 12)
                        .padding(.leading, 16)
                    }
                }
            }
        }
        .onChange(of: selectedFilter) { filter in
            generatePreview(for: filter)
        }
    }
    
    private func generatePreview(for filter: BeautyFilter?) {
        guard let filter = filter else {
            previewImage = nil
            return
        }
        
        isLoadingPreview = true
        
        Task {
            do {
                let filterEngine = FilterProcessingEngine()
                let preview = try await filterEngine.generateFilterPreview(
                    filter,
                    for: image,
                    size: CGSize(width: 400, height: 300)
                )
                
                await MainActor.run {
                    previewImage = preview
                    isLoadingPreview = false
                }
            } catch {
                await MainActor.run {
                    previewImage = nil
                    isLoadingPreview = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FilterDiscoveryView()
}