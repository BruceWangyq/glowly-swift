//
//  FilterPresetLibrary.swift
//  Glowly
//
//  Comprehensive filter preset library with predefined professional filters
//

import Foundation
import SwiftUI

/// Comprehensive filter preset library
final class FilterPresetLibrary {
    
    /// Get all predefined filters organized by category
    static func getAllFilters() -> [FilterCategory: [BeautyFilter]] {
        var filtersByCategory: [FilterCategory: [BeautyFilter]] = [:]
        
        filtersByCategory[.warm] = getWarmFilters()
        filtersByCategory[.cool] = getCoolFilters()
        filtersByCategory[.cinematic] = getCinematicFilters()
        filtersByCategory[.vintage] = getVintageFilters()
        filtersByCategory[.portrait] = getPortraitFilters()
        filtersByCategory[.natural] = getNaturalFilters()
        filtersByCategory[.dramatic] = getDramaticFilters()
        filtersByCategory[.blackAndWhite] = getBlackAndWhiteFilters()
        filtersByCategory[.colorPop] = getColorPopFilters()
        filtersByCategory[.artistic] = getArtisticFilters()
        filtersByCategory[.seasonal] = getSeasonalFilters()
        filtersByCategory[.trending] = getTrendingFilters()
        
        return filtersByCategory
    }
    
    /// Get featured makeup looks
    static func getFeaturedMakeupLooks() -> [MakeupLook] {
        return [
            createEverydayNaturalLook(),
            createGlamourEveningLook(),
            createVintageClassicLook(),
            createEditorialBoldLook(),
            createBridalRomanticLook(),
            createColorfulCreativeLook()
        ]
    }
    
    /// Get background effects collection
    static func getBackgroundEffects() -> [BackgroundEffect] {
        return [
            createStudioBackgroundEffects(),
            createNatureBackgroundEffects(),
            createUrbanBackgroundEffects(),
            createAbstractBackgroundEffects(),
            createMinimalistBackgroundEffects(),
            createLuxuriousBackgroundEffects()
        ].flatMap { $0 }
    }
    
    // MARK: - Warm Filters
    
    private static func getWarmFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "golden_hour",
                displayName: "Golden Hour",
                description: "Warm, magical golden hour lighting that makes every moment feel cinematic",
                category: .warm,
                style: .goldenHour,
                intensity: 0.8,
                isPopular: true,
                isTrending: true,
                downloadCount: 850000,
                rating: 4.8,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.15,
                        contrast: 0.1,
                        saturation: 0.2,
                        warmth: 0.4,
                        exposure: 0.1,
                        highlights: -0.1,
                        shadows: 0.2,
                        vibrance: 0.15
                    )
                )
            ),
            
            BeautyFilter(
                name: "honey_glow",
                displayName: "Honey Glow",
                description: "Sweet honey-toned warmth with a subtle glow that enhances skin beautifully",
                category: .warm,
                style: .honey,
                intensity: 0.7,
                isPopular: true,
                downloadCount: 620000,
                rating: 4.6,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.1,
                        saturation: 0.25,
                        warmth: 0.35,
                        highlights: 0.1,
                        shadows: 0.15,
                        vibrance: 0.2
                    )
                )
            ),
            
            BeautyFilter(
                name: "amber_dreams",
                displayName: "Amber Dreams",
                description: "Rich amber color grading with deep, warm tones perfect for cozy moments",
                category: .warm,
                style: .amber,
                intensity: 0.75,
                downloadCount: 480000,
                rating: 4.5,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.05,
                        contrast: 0.15,
                        saturation: 0.3,
                        warmth: 0.45,
                        shadows: 0.25,
                        clarity: 0.1
                    ),
                    colorGrading: ColorGrading(
                        highlightColor: ColorVector(r: 1.0, g: 0.9, b: 0.7),
                        midtoneColor: ColorVector(r: 1.0, g: 0.8, b: 0.6),
                        shadowColor: ColorVector(r: 0.9, g: 0.6, b: 0.4),
                        highlightIntensity: 0.2,
                        midtoneIntensity: 0.3,
                        shadowIntensity: 0.15
                    )
                )
            ),
            
            BeautyFilter(
                name: "bronze_beauty",
                displayName: "Bronze Beauty",
                description: "Luxurious bronze metallic finish that adds warmth and sophistication",
                category: .warm,
                style: .bronze,
                intensity: 0.65,
                downloadCount: 390000,
                rating: 4.4,
                isPremium: true,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        contrast: 0.2,
                        saturation: 0.2,
                        warmth: 0.3,
                        highlights: 0.15,
                        clarity: 0.2
                    )
                )
            ),
            
            BeautyFilter(
                name: "sunset_vibes",
                displayName: "Sunset Vibes",
                description: "Dreamy sunset atmosphere with soft pink and orange hues",
                category: .warm,
                style: .sunset,
                intensity: 0.7,
                downloadCount: 720000,
                rating: 4.7,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.12,
                        saturation: 0.28,
                        warmth: 0.38,
                        exposure: 0.08,
                        vibrance: 0.25
                    ),
                    colorGrading: ColorGrading(
                        highlightColor: ColorVector(r: 1.0, g: 0.8, b: 0.6),
                        midtoneColor: ColorVector(r: 1.0, g: 0.7, b: 0.5),
                        shadowColor: ColorVector(r: 0.8, g: 0.5, b: 0.4),
                        highlightIntensity: 0.25,
                        midtoneIntensity: 0.2,
                        shadowIntensity: 0.1
                    )
                )
            )
        ]
    }
    
    // MARK: - Cool Filters
    
    private static func getCoolFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "arctic_frost",
                displayName: "Arctic Frost",
                description: "Cool, crisp winter atmosphere with icy blue undertones",
                category: .cool,
                style: .arctic,
                intensity: 0.75,
                isPopular: true,
                downloadCount: 540000,
                rating: 4.5,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.1,
                        contrast: 0.15,
                        saturation: -0.1,
                        warmth: -0.4,
                        highlights: 0.2,
                        shadows: 0.1,
                        clarity: 0.15
                    )
                )
            ),
            
            BeautyFilter(
                name: "ice_blue",
                displayName: "Ice Blue",
                description: "Cool blue color grading that creates a serene, ethereal mood",
                category: .cool,
                style: .iceBlue,
                intensity: 0.8,
                isTrending: true,
                downloadCount: 670000,
                rating: 4.6,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.05,
                        contrast: 0.1,
                        saturation: 0.1,
                        warmth: -0.35,
                        highlights: 0.15,
                        vibrance: 0.1
                    ),
                    colorGrading: ColorGrading(
                        highlightColor: ColorVector(r: 0.8, g: 0.9, b: 1.0),
                        midtoneColor: ColorVector(r: 0.7, g: 0.8, b: 0.95),
                        shadowColor: ColorVector(r: 0.6, g: 0.7, b: 0.9),
                        highlightIntensity: 0.2,
                        midtoneIntensity: 0.15,
                        shadowIntensity: 0.1
                    )
                )
            ),
            
            BeautyFilter(
                name: "silver_shine",
                displayName: "Silver Shine",
                description: "Elegant metallic silver finish with sophisticated cool tones",
                category: .cool,
                style: .silver,
                intensity: 0.7,
                downloadCount: 430000,
                rating: 4.4,
                isPremium: true,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.08,
                        contrast: 0.18,
                        saturation: -0.05,
                        warmth: -0.25,
                        highlights: 0.25,
                        clarity: 0.2
                    )
                )
            )
        ]
    }
    
    // MARK: - Cinematic Filters
    
    private static func getCinematicFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "film_noir",
                displayName: "Film Noir",
                description: "Classic black and white cinema with dramatic contrast and shadows",
                category: .cinematic,
                style: .filmNoir,
                intensity: 0.85,
                isPopular: true,
                downloadCount: 720000,
                rating: 4.7,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: -0.1,
                        contrast: 0.4,
                        saturation: -1.0, // Black and white
                        highlights: -0.2,
                        shadows: 0.3,
                        clarity: 0.3
                    )
                )
            ),
            
            BeautyFilter(
                name: "blockbuster",
                displayName: "Blockbuster",
                description: "Hollywood movie-style color grading with orange and teal tones",
                category: .cinematic,
                style: .blockbuster,
                intensity: 0.8,
                isTrending: true,
                downloadCount: 890000,
                rating: 4.8,
                isPremium: true,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.05,
                        contrast: 0.25,
                        saturation: 0.15,
                        highlights: -0.1,
                        shadows: 0.2,
                        clarity: 0.15
                    ),
                    colorGrading: ColorGrading(
                        highlightColor: ColorVector(r: 1.0, g: 0.7, b: 0.5),
                        midtoneColor: ColorVector(r: 0.9, g: 0.8, b: 0.7),
                        shadowColor: ColorVector(r: 0.4, g: 0.6, b: 0.7),
                        highlightIntensity: 0.3,
                        midtoneIntensity: 0.2,
                        shadowIntensity: 0.25
                    )
                )
            )
        ]
    }
    
    // MARK: - Portrait Filters
    
    private static func getPortraitFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "soft_portrait",
                displayName: "Soft Portrait",
                description: "Gentle skin softening with natural beauty enhancement",
                category: .portrait,
                style: .softPortrait,
                intensity: 0.6,
                isPopular: true,
                downloadCount: 1200000,
                rating: 4.9,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.1,
                        contrast: -0.05,
                        saturation: 0.1,
                        warmth: 0.15,
                        highlights: 0.1,
                        shadows: 0.15
                    ),
                    faceAware: true
                )
            ),
            
            BeautyFilter(
                name: "professional_headshot",
                displayName: "Professional Headshot",
                description: "Studio-quality lighting perfect for business portraits",
                category: .portrait,
                style: .professionalHeadshot,
                intensity: 0.7,
                downloadCount: 680000,
                rating: 4.6,
                isPremium: true,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.12,
                        contrast: 0.1,
                        saturation: 0.05,
                        highlights: 0.15,
                        shadows: 0.1,
                        clarity: 0.1
                    ),
                    faceAware: true
                )
            )
        ]
    }
    
    // MARK: - Natural Filters
    
    private static func getNaturalFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "fresh_morning",
                displayName: "Fresh Morning",
                description: "Natural morning light with subtle enhancement",
                category: .natural,
                style: .fresh,
                intensity: 0.5,
                isPopular: true,
                downloadCount: 980000,
                rating: 4.7,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.08,
                        saturation: 0.05,
                        warmth: 0.1,
                        highlights: 0.05,
                        vibrance: 0.1
                    )
                )
            ),
            
            BeautyFilter(
                name: "clean_minimal",
                displayName: "Clean Minimal",
                description: "Minimal processing for a clean, natural look",
                category: .natural,
                style: .clean,
                intensity: 0.3,
                downloadCount: 560000,
                rating: 4.5,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.03,
                        contrast: 0.05,
                        saturation: 0.02,
                        clarity: 0.05
                    )
                )
            )
        ]
    }
    
    // MARK: - Additional Categories (abbreviated for brevity)
    
    private static func getDramaticFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "moody_dramatic",
                displayName: "Moody Dramatic",
                description: "High contrast dramatic look with deep shadows",
                category: .dramatic,
                style: .dramaticLighting,
                intensity: 0.9,
                downloadCount: 450000,
                rating: 4.3,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: -0.1,
                        contrast: 0.5,
                        saturation: 0.2,
                        highlights: -0.3,
                        shadows: 0.4,
                        clarity: 0.3
                    )
                )
            )
        ]
    }
    
    private static func getBlackAndWhiteFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "classic_bw",
                displayName: "Classic B&W",
                description: "Timeless black and white with perfect contrast",
                category: .blackAndWhite,
                style: .oldFilm,
                intensity: 1.0,
                isPopular: true,
                downloadCount: 780000,
                rating: 4.6,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        contrast: 0.2,
                        saturation: -1.0,
                        clarity: 0.15
                    )
                )
            )
        ]
    }
    
    private static func getColorPopFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "vibrant_pop",
                displayName: "Vibrant Pop",
                description: "Bold, vibrant colors that make images pop",
                category: .colorPop,
                style: .minimal,
                intensity: 0.8,
                isTrending: true,
                downloadCount: 650000,
                rating: 4.5,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        saturation: 0.4,
                        vibrance: 0.5,
                        contrast: 0.15,
                        clarity: 0.1
                    )
                )
            )
        ]
    }
    
    private static func getArtisticFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "painterly",
                displayName: "Painterly",
                description: "Artistic painting-like effect with soft textures",
                category: .artistic,
                style: .minimal,
                intensity: 0.7,
                downloadCount: 320000,
                rating: 4.2,
                isPremium: true,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        contrast: -0.1,
                        saturation: 0.3,
                        clarity: -0.3
                    )
                )
            )
        ]
    }
    
    private static func getSeasonalFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "autumn_warmth",
                displayName: "Autumn Warmth",
                description: "Warm autumn colors with golden leaves vibes",
                category: .seasonal,
                style: .honey,
                intensity: 0.75,
                downloadCount: 420000,
                rating: 4.4,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.1,
                        saturation: 0.25,
                        warmth: 0.4,
                        vibrance: 0.2
                    )
                )
            )
        ]
    }
    
    private static func getVintageFilters() -> [BeautyFilter] {
        return [
            BeautyFilter(
                name: "vintage_film",
                displayName: "Vintage Film",
                description: "Classic vintage film look with grain and faded colors",
                category: .vintage,
                style: .vintageFilm,
                intensity: 0.8,
                isPopular: true,
                downloadCount: 890000,
                rating: 4.7,
                processingConfig: FilterProcessingConfig(
                    adjustments: FilterAdjustments(
                        brightness: 0.05,
                        contrast: -0.1,
                        saturation: -0.2,
                        warmth: 0.2,
                        highlights: -0.15,
                        shadows: 0.2
                    )
                )
            )
        ]
    }
    
    private static func getTrendingFilters() -> [BeautyFilter] {
        // Return a mix of trending filters from different categories
        return [
            getWarmFilters().first(where: { $0.isTrending }),
            getCoolFilters().first(where: { $0.isTrending }),
            getCinematicFilters().first(where: { $0.isTrending }),
            getColorPopFilters().first(where: { $0.isTrending })
        ].compactMap { $0 }
    }
    
    // MARK: - Makeup Looks
    
    private static func createEverydayNaturalLook() -> MakeupLook {
        let components = [
            MakeupComponent(
                type: .foundation,
                color: MakeupColor(
                    name: "Natural Glow",
                    rgb: ColorVector(r: 0.95, g: 0.85, b: 0.75),
                    opacity: 0.6,
                    finish: .natural
                ),
                intensity: 0.4,
                applicationArea: [.forehead, .leftCheek, .rightCheek, .nose, .chin],
                layerOrder: 1
            ),
            MakeupComponent(
                type: .blush,
                color: MakeupColor(
                    name: "Soft Peach",
                    rgb: ColorVector(r: 1.0, g: 0.7, b: 0.6),
                    opacity: 0.4,
                    finish: .natural
                ),
                intensity: 0.3,
                applicationArea: [.leftCheek, .rightCheek],
                layerOrder: 2
            ),
            MakeupComponent(
                type: .lipstick,
                color: MakeupColor(
                    name: "My Lips But Better",
                    rgb: ColorVector(r: 0.9, g: 0.6, b: 0.5),
                    opacity: 0.5,
                    finish: .satin
                ),
                intensity: 0.4,
                applicationArea: [.upperLip, .lowerLip],
                layerOrder: 3
            )
        ]
        
        return MakeupLook(
            name: "everyday_natural",
            displayName: "Everyday Natural",
            description: "Perfect natural look for daily wear with subtle enhancement",
            category: .natural,
            style: .everyday,
            components: components,
            isPopular: true,
            difficulty: .easy,
            estimatedTime: 5
        )
    }
    
    private static func createGlamourEveningLook() -> MakeupLook {
        // Implementation for glamour evening look
        return MakeupLook(
            name: "glamour_evening",
            displayName: "Glamour Evening",
            description: "Sophisticated evening glamour with dramatic eyes and bold lips",
            category: .glamour,
            style: .smokyEye,
            components: [],
            isPremium: true,
            difficulty: .hard,
            estimatedTime: 15
        )
    }
    
    private static func createVintageClassicLook() -> MakeupLook {
        // Implementation for vintage classic look
        return MakeupLook(
            name: "vintage_classic",
            displayName: "Vintage Classic",
            description: "Timeless vintage makeup inspired by classic Hollywood",
            category: .vintage,
            style: .wingedEyeliner,
            components: [],
            difficulty: .medium,
            estimatedTime: 12
        )
    }
    
    private static func createEditorialBoldLook() -> MakeupLook {
        // Implementation for editorial bold look
        return MakeupLook(
            name: "editorial_bold",
            displayName: "Editorial Bold",
            description: "High-fashion editorial makeup with creative color blocking",
            category: .editorial,
            style: .colorBlock,
            components: [],
            isPremium: true,
            difficulty: .expert,
            estimatedTime: 20
        )
    }
    
    private static func createBridalRomanticLook() -> MakeupLook {
        // Implementation for bridal romantic look
        return MakeupLook(
            name: "bridal_romantic",
            displayName: "Bridal Romantic",
            description: "Soft, romantic bridal makeup perfect for your special day",
            category: .bridal,
            style: .highlighting,
            components: [],
            isPopular: true,
            difficulty: .medium,
            estimatedTime: 18
        )
    }
    
    private static func createColorfulCreativeLook() -> MakeupLook {
        // Implementation for colorful creative look
        return MakeupLook(
            name: "colorful_creative",
            displayName: "Colorful Creative",
            description: "Bold, creative makeup with vibrant colors and artistic flair",
            category: .colorful,
            style: .gradient,
            components: [],
            isPremium: true,
            difficulty: .expert,
            estimatedTime: 25
        )
    }
    
    // MARK: - Background Effects
    
    private static func createStudioBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "professional_studio",
                displayName: "Professional Studio",
                description: "Clean white studio background for professional photos",
                type: .replacement,
                category: .studio,
                intensity: 1.0,
                processingConfig: BackgroundProcessingConfig()
            ),
            BackgroundEffect(
                name: "soft_bokeh",
                displayName: "Soft Bokeh",
                description: "Beautiful soft bokeh blur for portrait photography",
                type: .blur,
                category: .studio,
                intensity: 0.8,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
    
    private static func createNatureBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "forest_blur",
                displayName: "Forest Blur",
                description: "Natural forest background with dreamy blur effect",
                type: .blur,
                category: .nature,
                intensity: 0.7,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
    
    private static func createUrbanBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "city_lights",
                displayName: "City Lights",
                description: "Urban cityscape with beautiful bokeh lights",
                type: .replacement,
                category: .urban,
                intensity: 0.8,
                isPremium: true,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
    
    private static func createAbstractBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "gradient_flow",
                displayName: "Gradient Flow",
                description: "Abstract flowing gradient background",
                type: .gradient,
                category: .abstract,
                intensity: 0.9,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
    
    private static func createMinimalistBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "clean_white",
                displayName: "Clean White",
                description: "Minimalist clean white background",
                type: .replacement,
                category: .minimalist,
                intensity: 1.0,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
    
    private static func createLuxuriousBackgroundEffects() -> [BackgroundEffect] {
        return [
            BackgroundEffect(
                name: "golden_luxury",
                displayName: "Golden Luxury",
                description: "Luxurious golden background with elegant texture",
                type: .texture,
                category: .luxurious,
                intensity: 0.8,
                isPremium: true,
                processingConfig: BackgroundProcessingConfig()
            )
        ]
    }
}

// MARK: - Filter Collection Presets

extension FilterPresetLibrary {
    
    /// Get predefined filter collections for quick access
    static func getPredefinedCollections() -> [FilterCollection] {
        return [
            FilterCollection(
                name: "Everyday Essentials",
                description: "Perfect filters for daily use and social sharing",
                isPrivate: false,
                filters: [
                    UUID(), // These would be actual filter IDs in production
                    UUID(),
                    UUID()
                ]
            ),
            FilterCollection(
                name: "Professional Portraits",
                description: "Studio-quality filters for professional photography",
                isPrivate: false,
                filters: [
                    UUID(),
                    UUID()
                ]
            ),
            FilterCollection(
                name: "Creative & Artistic",
                description: "Unique artistic filters for creative expression",
                isPrivate: false,
                filters: [
                    UUID(),
                    UUID(),
                    UUID(),
                    UUID()
                ]
            )
        ]
    }
    
    /// Get trending filter combinations
    static func getTrendingCombinations() -> [(primary: BeautyFilter, secondary: BeautyFilter)] {
        let warmFilters = getWarmFilters()
        let coolFilters = getCoolFilters()
        let portraitFilters = getPortraitFilters()
        
        return [
            (warmFilters[0], portraitFilters[0]), // Golden Hour + Soft Portrait
            (coolFilters[0], portraitFilters[1]), // Arctic Frost + Professional Headshot
            // Add more trending combinations
        ]
    }
}

// MARK: - Helper Extensions

extension BeautyFilter {
    /// Create filter with social metadata
    convenience init(
        name: String,
        displayName: String,
        description: String,
        category: FilterCategory,
        style: FilterStyle,
        intensity: Float = 1.0,
        isPremium: Bool = false,
        isPopular: Bool = false,
        isTrending: Bool = false,
        downloadCount: Int = 0,
        rating: Float = 0.0,
        processingConfig: FilterProcessingConfig,
        tags: [String] = []
    ) {
        let socialMetadata = FilterSocialMetadata(
            likeCount: Int.random(in: 100...10000),
            shareCount: Int.random(in: 10...1000),
            saveCount: Int.random(in: 50...5000),
            commentCount: Int.random(in: 5...500),
            tags: tags.isEmpty ? [category.rawValue, style.rawValue] : tags
        )
        
        self.init(
            name: name,
            displayName: displayName,
            description: description,
            category: category,
            style: style,
            intensity: intensity,
            isPremium: isPremium,
            isPopular: isPopular,
            isTrending: isTrending,
            downloadCount: downloadCount,
            rating: rating,
            socialMetadata: socialMetadata,
            processingConfig: processingConfig
        )
    }
}