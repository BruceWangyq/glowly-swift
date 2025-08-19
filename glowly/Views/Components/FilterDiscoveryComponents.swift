//
//  FilterDiscoveryComponents.swift
//  Glowly
//
//  Supporting UI components for filter discovery interface
//

import SwiftUI

// MARK: - Filter Categories View

struct FilterCategoriesView: View {
    @Binding var selectedCategory: FilterCategory
    let onCategorySelected: (FilterCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    FilterCategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = category
                            onCategorySelected(category)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct FilterCategoryCard: View {
    let category: FilterCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : GlowlyTheme.cardBackground)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : category.color)
                }
                
                // Category name
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? GlowlyTheme.text : GlowlyTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Filter Grid View

struct FilterGridView: View {
    let filters: [BeautyFilter]
    let selectedImage: UIImage?
    let onFilterSelected: (BeautyFilter) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filters) { filter in
                FilterGridCard(
                    filter: filter,
                    selectedImage: selectedImage,
                    onTap: { onFilterSelected(filter) }
                )
            }
        }
    }
}

struct FilterGridCard: View {
    let filter: BeautyFilter
    let selectedImage: UIImage?
    let onTap: () -> Void
    
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview = false
    @State private var isFavorite = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Filter preview
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GlowlyTheme.cardBackground)
                        .frame(height: 140)
                    
                    if let image = selectedImage {
                        // Image preview with filter
                        Image(uiImage: previewImage ?? image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Gradient preview
                        filterGradientPreview
                    }
                    
                    // Loading overlay
                    if isLoadingPreview {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            )
                    }
                    
                    // Favorite button overlay
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: { toggleFavorite() }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.4))
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                    
                    // Premium badge
                    if filter.isPremium {
                        VStack {
                            HStack {
                                PremiumBadge()
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    
                    // Trending badge
                    if filter.isTrending {
                        VStack {
                            Spacer()
                            HStack {
                                TrendingBadge()
                                Spacer()
                            }
                        }
                        .padding(8)
                    }
                }
                
                // Filter info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(filter.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(GlowlyTheme.text)
                        
                        Spacer()
                    }
                    
                    HStack {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", filter.rating))
                                .font(.caption2)
                                .foregroundColor(GlowlyTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Download count
                        Text(formatDownloadCount(filter.downloadCount))
                            .font(.caption2)
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GlowlyTheme.cardBackground)
            }
            .background(GlowlyTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            generatePreview()
        }
        .onChange(of: selectedImage) { _ in
            generatePreview()
        }
    }
    
    private var filterGradientPreview: some View {
        // Create a gradient preview based on filter characteristics
        let colors = getFilterColors(for: filter)
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            VStack {
                Spacer()
                
                Text(filter.style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
            }
            .padding(8)
        )
    }
    
    private func generatePreview() {
        guard let image = selectedImage else {
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
                    size: CGSize(width: 200, height: 140)
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
    
    private func toggleFavorite() {
        isFavorite.toggle()
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func getFilterColors(for filter: BeautyFilter) -> [Color] {
        switch filter.category {
        case .warm:
            return [.orange, .yellow]
        case .cool:
            return [.blue, .cyan]
        case .cinematic:
            return [.indigo, .purple]
        case .vintage:
            return [.brown, .orange]
        case .portrait:
            return [.pink, .purple]
        case .natural:
            return [.green, .mint]
        case .dramatic:
            return [.red, .black]
        case .blackAndWhite:
            return [.gray, .white]
        case .colorPop:
            return [.purple, .pink]
        case .artistic:
            return [.mint, .teal]
        case .seasonal:
            return [.yellow, .orange]
        case .trending:
            return [.cyan, .blue]
        }
    }
    
    private func formatDownloadCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Filter Horizontal Scroll View

struct FilterHorizontalScrollView: View {
    let title: String
    let filters: [BeautyFilter]
    let selectedImage: UIImage?
    let onFilterSelected: (BeautyFilter) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(GlowlyTheme.headingFont)
                    .foregroundColor(GlowlyTheme.text)
                
                Spacer()
                
                Button("See All") {
                    // Show all filters in category
                }
                .font(.caption)
                .foregroundColor(GlowlyTheme.accent)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters.prefix(10)) { filter in
                        FilterHorizontalCard(
                            filter: filter,
                            selectedImage: selectedImage,
                            onTap: { onFilterSelected(filter) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FilterHorizontalCard: View {
    let filter: BeautyFilter
    let selectedImage: UIImage?
    let onTap: () -> Void
    
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Filter preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(GlowlyTheme.cardBackground)
                        .frame(width: 100, height: 100)
                    
                    if let image = selectedImage {
                        Image(uiImage: previewImage ?? image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Gradient preview
                        let colors = getFilterColors(for: filter)
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if isLoadingPreview {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.6)
                            )
                    }
                    
                    // Premium badge
                    if filter.isPremium {
                        VStack {
                            HStack {
                                PremiumBadge(size: .small)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(4)
                    }
                }
                
                // Filter name
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
            }
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        guard let image = selectedImage else {
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
                    size: CGSize(width: 100, height: 100)
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
    
    private func getFilterColors(for filter: BeautyFilter) -> [Color] {
        switch filter.category {
        case .warm: return [.orange, .yellow]
        case .cool: return [.blue, .cyan]
        case .cinematic: return [.indigo, .purple]
        case .vintage: return [.brown, .orange]
        case .portrait: return [.pink, .purple]
        case .natural: return [.green, .mint]
        case .dramatic: return [.red, .black]
        case .blackAndWhite: return [.gray, .white]
        case .colorPop: return [.purple, .pink]
        case .artistic: return [.mint, .teal]
        case .seasonal: return [.yellow, .orange]
        case .trending: return [.cyan, .blue]
        }
    }
}

// MARK: - Makeup Components

struct MakeupCategoriesView: View {
    let onCategorySelected: (MakeupCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MakeupCategory.allCases, id: \.self) { category in
                    MakeupCategoryCard(
                        category: category,
                        onTap: { onCategorySelected(category) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct MakeupCategoryCard: View {
    let category: MakeupCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(GlowlyTheme.accent)
                    .frame(width: 50, height: 50)
                    .background(GlowlyTheme.cardBackground)
                    .clipShape(Circle())
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.text)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70)
        }
    }
}

struct MakeupLooksGridView: View {
    let looks: [MakeupLook]
    let selectedImage: UIImage?
    let onLookSelected: (MakeupLook) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(looks) { look in
                MakeupLookCard(
                    look: look,
                    selectedImage: selectedImage,
                    onTap: { onLookSelected(look) }
                )
            }
        }
    }
}

struct MakeupLookCard: View {
    let look: MakeupLook
    let selectedImage: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GlowlyTheme.cardBackground)
                        .frame(height: 140)
                    
                    VStack {
                        Image(systemName: "paintbrush")
                            .font(.system(size: 30))
                            .foregroundColor(GlowlyTheme.accent)
                        
                        Text("Makeup Preview")
                            .font(.caption)
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                }
                
                // Look info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(look.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(GlowlyTheme.text)
                        
                        Spacer()
                    }
                    
                    HStack {
                        DifficultyIndicator(difficulty: look.difficulty)
                        
                        Spacer()
                        
                        Text("\(Int(look.estimatedTime))min")
                            .font(.caption2)
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GlowlyTheme.cardBackground)
            }
            .background(GlowlyTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Background Components

struct BackgroundCategoriesView: View {
    let onCategorySelected: (BackgroundCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(BackgroundCategory.allCases, id: \.self) { category in
                    BackgroundCategoryCard(
                        category: category,
                        onTap: { onCategorySelected(category) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct BackgroundCategoryCard: View {
    let category: BackgroundCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(GlowlyTheme.accent)
                    .frame(width: 50, height: 50)
                    .background(GlowlyTheme.cardBackground)
                    .clipShape(Circle())
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.text)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70)
        }
    }
}

struct BackgroundEffectsGridView: View {
    let effects: [BackgroundEffect]
    let selectedImage: UIImage?
    let onEffectSelected: (BackgroundEffect) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(effects) { effect in
                BackgroundEffectCard(
                    effect: effect,
                    selectedImage: selectedImage,
                    onTap: { onEffectSelected(effect) }
                )
            }
        }
    }
}

struct BackgroundEffectCard: View {
    let effect: BackgroundEffect
    let selectedImage: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GlowlyTheme.cardBackground)
                        .frame(height: 140)
                    
                    VStack {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 30))
                            .foregroundColor(GlowlyTheme.accent)
                        
                        Text("Background Preview")
                            .font(.caption)
                            .foregroundColor(GlowlyTheme.secondaryText)
                    }
                }
                
                // Effect info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(effect.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(GlowlyTheme.text)
                        
                        Spacer()
                    }
                    
                    Text(effect.type.displayName)
                        .font(.caption2)
                        .foregroundColor(GlowlyTheme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GlowlyTheme.cardBackground)
            }
            .background(GlowlyTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Components

struct PremiumBadge: View {
    enum Size {
        case normal, small
        
        var fontSize: CGFloat {
            switch self {
            case .normal: return 10
            case .small: return 8
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .normal: return 6
            case .small: return 4
            }
        }
    }
    
    let size: Size
    
    init(size: Size = .normal) {
        self.size = size
    }
    
    var body: some View {
        Text("PRO")
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
    }
}

struct TrendingBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 8))
                .foregroundColor(.orange)
            
            Text("TRENDING")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
    }
}

struct DifficultyIndicator: View {
    let difficulty: MakeupDifficulty
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < difficultyLevel ? difficulty.color : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private var difficultyLevel: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }
}