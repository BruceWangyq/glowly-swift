//
//  FilterDiscoveryViewModel.swift
//  Glowly
//
//  ViewModel for filter discovery with search, filtering, and recommendation logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FilterDiscoveryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var allFilters: [BeautyFilter] = []
    @Published var filteredFilters: [BeautyFilter] = []
    @Published var trendingFilters: [BeautyFilter] = []
    @Published var popularFilters: [BeautyFilter] = []
    @Published var favoriteFilters: [BeautyFilter] = []
    @Published var recentlyUsedFilters: [BeautyFilter] = []
    
    @Published var makeupLooks: [MakeupLook] = []
    @Published var filteredMakeupLooks: [MakeupLook] = []
    @Published var backgroundEffects: [BackgroundEffect] = []
    @Published var filteredBackgroundEffects: [BackgroundEffect] = []
    
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var selectedCategory: FilterCategory = .warm
    @Published var selectedMakeupCategory: MakeupCategory = .natural
    @Published var selectedBackgroundCategory: BackgroundCategory = .studio
    
    @Published var filterCollections: [FilterCollection] = []
    @Published var recommendedFilters: [BeautyFilter] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let filterService = FilterService()
    private let makeupService = MakeupService()
    private let backgroundService = BackgroundService()
    private let analyticsService = AnalyticsService()
    private let userPreferencesService = UserPreferencesService()
    
    // MARK: - Initialization
    init() {
        setupSearchBinding()
        setupRecommendationEngine()
    }
    
    // MARK: - Public Methods
    
    /// Load all filters and initialize data
    func loadFilters() {
        isLoading = true
        
        Task {
            do {
                // Load beauty filters
                allFilters = try await filterService.loadBeautyFilters()
                trendingFilters = try await filterService.getTrendingFilters()
                popularFilters = try await filterService.getPopularFilters()
                favoriteFilters = try await filterService.getFavoriteFilters()
                recentlyUsedFilters = try await filterService.getRecentlyUsedFilters()
                
                // Load makeup looks
                makeupLooks = try await makeupService.loadMakeupLooks()
                
                // Load background effects
                backgroundEffects = try await backgroundService.loadBackgroundEffects()
                
                // Initialize filtered results
                filterByCategory(selectedCategory)
                filterMakeupByCategory(selectedMakeupCategory)
                filterBackgroundsByCategory(selectedBackgroundCategory)
                
                // Load user collections
                filterCollections = try await filterService.getUserCollections()
                
                // Generate recommendations
                await generateRecommendations()
                
                isLoading = false
            } catch {
                print("Error loading filters: \(error)")
                isLoading = false
            }
        }
    }
    
    /// Filter beauty filters by category
    func filterByCategory(_ category: FilterCategory) {
        selectedCategory = category
        
        let categoryFilters = allFilters.filter { $0.category == category }
        filteredFilters = applySortingAndFiltering(to: categoryFilters)
        
        analyticsService.trackFilterCategoryView(category)
    }
    
    /// Filter makeup looks by category
    func filterMakeupByCategory(_ category: MakeupCategory) {
        selectedMakeupCategory = category
        
        filteredMakeupLooks = makeupLooks.filter { $0.category == category }
            .sorted { lhs, rhs in
                // Sort by popularity, then by difficulty
                if lhs.isPopular != rhs.isPopular {
                    return lhs.isPopular && !rhs.isPopular
                }
                return lhs.difficulty.rawValue < rhs.difficulty.rawValue
            }
        
        analyticsService.trackMakeupCategoryView(category)
    }
    
    /// Filter background effects by category
    func filterBackgroundsByCategory(_ category: BackgroundCategory) {
        selectedBackgroundCategory = category
        
        filteredBackgroundEffects = backgroundEffects.filter { $0.category == category }
            .sorted { lhs, rhs in
                // Sort by premium status, then by popularity
                if lhs.isPremium != rhs.isPremium {
                    return !lhs.isPremium && rhs.isPremium
                }
                return lhs.socialMetadata.likeCount > rhs.socialMetadata.likeCount
            }
        
        analyticsService.trackBackgroundCategoryView(category)
    }
    
    /// Search filters with query
    func searchFilters(query: String) {
        searchQuery = query.lowercased()
        
        if searchQuery.isEmpty {
            filterByCategory(selectedCategory)
            return
        }
        
        let searchResults = allFilters.filter { filter in
            filter.displayName.lowercased().contains(searchQuery) ||
            filter.description.lowercased().contains(searchQuery) ||
            filter.style.displayName.lowercased().contains(searchQuery) ||
            filter.socialMetadata.tags.contains { $0.lowercased().contains(searchQuery) }
        }
        
        filteredFilters = applySortingAndFiltering(to: searchResults)
        
        analyticsService.trackFilterSearch(query: query, resultCount: filteredFilters.count)
    }
    
    /// Show favorite filters
    func showFavoriteFilters() {
        filteredFilters = favoriteFilters
        analyticsService.trackFavoritesView()
    }
    
    /// Toggle filter favorite status
    func toggleFavorite(for filter: BeautyFilter) {
        Task {
            do {
                if favoriteFilters.contains(where: { $0.id == filter.id }) {
                    try await filterService.removeFavorite(filterId: filter.id)
                    favoriteFilters.removeAll { $0.id == filter.id }
                } else {
                    try await filterService.addFavorite(filterId: filter.id)
                    favoriteFilters.append(filter)
                }
                
                analyticsService.trackFilterFavoriteToggle(filterId: filter.id, isFavorite: favoriteFilters.contains { $0.id == filter.id })
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    /// Record filter usage
    func recordFilterUsage(_ filter: BeautyFilter) {
        Task {
            do {
                try await filterService.recordUsage(filterId: filter.id)
                
                // Update recently used
                recentlyUsedFilters.removeAll { $0.id == filter.id }
                recentlyUsedFilters.insert(filter, at: 0)
                
                // Keep only recent 10
                if recentlyUsedFilters.count > 10 {
                    recentlyUsedFilters = Array(recentlyUsedFilters.prefix(10))
                }
                
                analyticsService.trackFilterUsage(filterId: filter.id)
            } catch {
                print("Error recording filter usage: \(error)")
            }
        }
    }
    
    /// Create new filter collection
    func createCollection(name: String, description: String, filterIds: [UUID]) {
        Task {
            do {
                let collection = FilterCollection(
                    name: name,
                    description: description,
                    filters: filterIds
                )
                
                try await filterService.saveCollection(collection)
                filterCollections.append(collection)
                
                analyticsService.trackCollectionCreated(collectionId: collection.id)
            } catch {
                print("Error creating collection: \(error)")
            }
        }
    }
    
    /// Generate personalized recommendations
    func generateRecommendations() async {
        do {
            // Get user preferences
            let preferences = await userPreferencesService.getUserPreferences()
            
            // Get usage history
            let usageHistory = try await filterService.getUsageHistory()
            
            // Generate recommendations based on preferences and history
            recommendedFilters = generatePersonalizedRecommendations(
                preferences: preferences,
                usageHistory: usageHistory,
                allFilters: allFilters
            )
            
        } catch {
            print("Error generating recommendations: \(error)")
            // Fallback to popular filters
            recommendedFilters = Array(popularFilters.prefix(10))
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSearchBinding() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchFilters(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func setupRecommendationEngine() {
        // Update recommendations when filters or preferences change
        Publishers.CombineLatest($allFilters, $favoriteFilters)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                Task {
                    await self?.generateRecommendations()
                }
            }
            .store(in: &cancellables)
    }
    
    private func applySortingAndFiltering(to filters: [BeautyFilter]) -> [BeautyFilter] {
        return filters.sorted { lhs, rhs in
            // Prioritize non-premium filters for free users
            if lhs.isPremium != rhs.isPremium {
                return !lhs.isPremium && rhs.isPremium
            }
            
            // Then sort by popularity
            if lhs.isPopular != rhs.isPopular {
                return lhs.isPopular && !rhs.isPopular
            }
            
            // Then by rating
            if lhs.rating != rhs.rating {
                return lhs.rating > rhs.rating
            }
            
            // Finally by download count
            return lhs.downloadCount > rhs.downloadCount
        }
    }
    
    private func generatePersonalizedRecommendations(
        preferences: UserPreferences,
        usageHistory: [FilterUsageAnalytics],
        allFilters: [BeautyFilter]
    ) -> [BeautyFilter] {
        
        var recommendations: [BeautyFilter] = []
        var scores: [UUID: Float] = [:]
        
        for filter in allFilters {
            var score: Float = 0
            
            // Base popularity score
            score += Float(filter.downloadCount) / 1000000.0 // Normalize
            score += filter.rating * 0.2
            
            // Category preference score
            if preferences.preferredCategories.contains(filter.category) {
                score += 0.3
            }
            
            // Style preference score
            if preferences.preferredStyles.contains(filter.style) {
                score += 0.2
            }
            
            // Usage history similarity
            let similarFilters = usageHistory.filter { usage in
                let usedFilter = allFilters.first { $0.id == usage.filterId }
                return usedFilter?.category == filter.category || usedFilter?.style == filter.style
            }
            score += Float(similarFilters.count) * 0.1
            
            // Trending bonus
            if filter.isTrending {
                score += 0.15
            }
            
            // Recently released bonus
            let daysSinceCreated = Calendar.current.dateComponents([.day], from: filter.createdAt, to: Date()).day ?? 0
            if daysSinceCreated < 7 {
                score += 0.1
            }
            
            scores[filter.id] = score
        }
        
        // Sort by score and return top recommendations
        recommendations = allFilters.sorted { lhs, rhs in
            (scores[lhs.id] ?? 0) > (scores[rhs.id] ?? 0)
        }
        
        return Array(recommendations.prefix(20))
    }
}

// MARK: - Supporting Models

struct UserPreferences: Codable {
    let preferredCategories: [FilterCategory]
    let preferredStyles: [FilterStyle]
    let preferredMakeupCategories: [MakeupCategory]
    let preferredBackgroundCategories: [BackgroundCategory]
    let enableAnalytics: Bool
    let enableRecommendations: Bool
    
    init(
        preferredCategories: [FilterCategory] = [],
        preferredStyles: [FilterStyle] = [],
        preferredMakeupCategories: [MakeupCategory] = [],
        preferredBackgroundCategories: [BackgroundCategory] = [],
        enableAnalytics: Bool = true,
        enableRecommendations: Bool = true
    ) {
        self.preferredCategories = preferredCategories
        self.preferredStyles = preferredStyles
        self.preferredMakeupCategories = preferredMakeupCategories
        self.preferredBackgroundCategories = preferredBackgroundCategories
        self.enableAnalytics = enableAnalytics
        self.enableRecommendations = enableRecommendations
    }
}

// MARK: - Service Protocols

protocol FilterServiceProtocol {
    func loadBeautyFilters() async throws -> [BeautyFilter]
    func getTrendingFilters() async throws -> [BeautyFilter]
    func getPopularFilters() async throws -> [BeautyFilter]
    func getFavoriteFilters() async throws -> [BeautyFilter]
    func getRecentlyUsedFilters() async throws -> [BeautyFilter]
    func addFavorite(filterId: UUID) async throws
    func removeFavorite(filterId: UUID) async throws
    func recordUsage(filterId: UUID) async throws
    func getUserCollections() async throws -> [FilterCollection]
    func saveCollection(_ collection: FilterCollection) async throws
    func getUsageHistory() async throws -> [FilterUsageAnalytics]
}

protocol MakeupServiceProtocol {
    func loadMakeupLooks() async throws -> [MakeupLook]
    func getMakeupLooksByCategory(_ category: MakeupCategory) async throws -> [MakeupLook]
}

protocol BackgroundServiceProtocol {
    func loadBackgroundEffects() async throws -> [BackgroundEffect]
    func getBackgroundEffectsByCategory(_ category: BackgroundCategory) async throws -> [BackgroundEffect]
}

// MARK: - Mock Services (for development)

final class FilterService: FilterServiceProtocol {
    func loadBeautyFilters() async throws -> [BeautyFilter] {
        // Mock implementation - replace with actual service calls
        return createMockFilters()
    }
    
    func getTrendingFilters() async throws -> [BeautyFilter] {
        let allFilters = try await loadBeautyFilters()
        return Array(allFilters.filter { $0.isTrending }.prefix(10))
    }
    
    func getPopularFilters() async throws -> [BeautyFilter] {
        let allFilters = try await loadBeautyFilters()
        return Array(allFilters.filter { $0.isPopular }.prefix(10))
    }
    
    func getFavoriteFilters() async throws -> [BeautyFilter] {
        // Mock implementation
        return []
    }
    
    func getRecentlyUsedFilters() async throws -> [BeautyFilter] {
        // Mock implementation
        return []
    }
    
    func addFavorite(filterId: UUID) async throws {
        // Mock implementation
    }
    
    func removeFavorite(filterId: UUID) async throws {
        // Mock implementation
    }
    
    func recordUsage(filterId: UUID) async throws {
        // Mock implementation
    }
    
    func getUserCollections() async throws -> [FilterCollection] {
        // Mock implementation
        return []
    }
    
    func saveCollection(_ collection: FilterCollection) async throws {
        // Mock implementation
    }
    
    func getUsageHistory() async throws -> [FilterUsageAnalytics] {
        // Mock implementation
        return []
    }
    
    private func createMockFilters() -> [BeautyFilter] {
        var filters: [BeautyFilter] = []
        
        // Warm filters
        let warmFilters = [
            ("Golden Hour", FilterStyle.goldenHour, "Warm, golden sunset lighting"),
            ("Honey Glow", FilterStyle.honey, "Sweet honey-toned warmth"),
            ("Amber Dream", FilterStyle.amber, "Rich amber color grading"),
            ("Bronze Beauty", FilterStyle.bronze, "Bronze metallic finish"),
            ("Sunset Vibes", FilterStyle.sunset, "Dreamy sunset atmosphere")
        ]
        
        for (index, (name, style, description)) in warmFilters.enumerated() {
            let filter = BeautyFilter(
                name: name.lowercased().replacingOccurrences(of: " ", with: "_"),
                displayName: name,
                description: description,
                category: .warm,
                style: style,
                intensity: 0.8,
                isPopular: index < 2,
                isTrending: index == 0,
                downloadCount: Int.random(in: 10000...500000),
                rating: Float.random(in: 4.0...5.0),
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.1,
                        contrast: 0.05,
                        saturation: 0.15,
                        warmth: 0.3,
                        exposure: 0.05
                    )
                )
            )
            filters.append(filter)
        }
        
        // Cool filters
        let coolFilters = [
            ("Arctic Frost", FilterStyle.arctic, "Cool, crisp winter atmosphere"),
            ("Ice Blue", FilterStyle.iceBlue, "Cool blue color grading"),
            ("Silver Shine", FilterStyle.silver, "Metallic silver finish"),
            ("Winter Wonder", FilterStyle.winter, "Fresh winter mood"),
            ("Platinum Polish", FilterStyle.platinum, "Elegant platinum tones")
        ]
        
        for (index, (name, style, description)) in coolFilters.enumerated() {
            let filter = BeautyFilter(
                name: name.lowercased().replacingOccurrences(of: " ", with: "_"),
                displayName: name,
                description: description,
                category: .cool,
                style: style,
                intensity: 0.75,
                isPopular: index < 3,
                isTrending: index == 1,
                downloadCount: Int.random(in: 15000...400000),
                rating: Float.random(in: 3.8...4.9),
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.05,
                        contrast: 0.1,
                        saturation: -0.05,
                        warmth: -0.25,
                        shadows: 0.1
                    )
                )
            )
            filters.append(filter)
        }
        
        // Add more categories...
        
        return filters
    }
}

final class MakeupService: MakeupServiceProtocol {
    func loadMakeupLooks() async throws -> [MakeupLook] {
        // Mock implementation
        return createMockMakeupLooks()
    }
    
    func getMakeupLooksByCategory(_ category: MakeupCategory) async throws -> [MakeupLook] {
        let allLooks = try await loadMakeupLooks()
        return allLooks.filter { $0.category == category }
    }
    
    private func createMockMakeupLooks() -> [MakeupLook] {
        // Mock makeup looks
        return []
    }
}

final class BackgroundService: BackgroundServiceProtocol {
    func loadBackgroundEffects() async throws -> [BackgroundEffect] {
        // Mock implementation
        return createMockBackgroundEffects()
    }
    
    func getBackgroundEffectsByCategory(_ category: BackgroundCategory) async throws -> [BackgroundEffect] {
        let allEffects = try await loadBackgroundEffects()
        return allEffects.filter { $0.category == category }
    }
    
    private func createMockBackgroundEffects() -> [BackgroundEffect] {
        // Mock background effects
        return []
    }
}