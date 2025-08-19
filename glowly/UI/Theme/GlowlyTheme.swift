//
//  GlowlyTheme.swift
//  Glowly
//
//  Comprehensive design system and theme constants for Glowly
//

import SwiftUI

// MARK: - GlowlyTheme
struct GlowlyTheme {
    
    // MARK: - Colors
    struct Colors {
        
        // MARK: - Primary Colors (Soft Pastels)
        static let primary = Color(hex: "E8B4F0")        // Soft lavender pink
        static let primaryDark = Color(hex: "D89CE3")     // Darker lavender
        static let primaryLight = Color(hex: "F2D4F7")    // Lighter lavender
        
        static let secondary = Color(hex: "B4E8F0")       // Soft sky blue
        static let secondaryDark = Color(hex: "9CD8E3")   // Darker sky blue
        static let secondaryLight = Color(hex: "D4F2F7")  // Lighter sky blue
        
        static let accent = Color(hex: "F0E8B4")          // Soft cream yellow
        static let accentDark = Color(hex: "E3D89C")      // Darker cream
        static let accentLight = Color(hex: "F7F2D4")     // Lighter cream
        
        // MARK: - Semantic Colors
        static let success = Color(hex: "B4F0C4")         // Soft mint green
        static let warning = Color(hex: "F0D4B4")         // Soft peach
        static let error = Color(hex: "F0B4C4")           // Soft coral pink
        static let info = secondary                        // Use secondary blue
        
        // MARK: - Neutral Colors
        static let background = Color(hex: "FEFEFE")       // Pure white with slight warmth
        static let backgroundSecondary = Color(hex: "F8F9FA") // Slightly off-white
        static let surface = Color(hex: "FFFFFF")          // Pure white
        static let surfaceElevated = Color(hex: "FDFDFD")  // Slightly elevated surface
        
        // MARK: - Text Colors
        static let textPrimary = Color(hex: "2D2D2D")      // Dark charcoal
        static let textSecondary = Color(hex: "6B7280")    // Medium gray
        static let textTertiary = Color(hex: "9CA3AF")     // Light gray
        static let textOnPrimary = Color.white             // White text on primary
        static let textOnDark = Color.white                // White text on dark backgrounds
        
        // MARK: - Border & Separator Colors
        static let border = Color(hex: "E5E7EB")           // Light border
        static let borderLight = Color(hex: "F3F4F6")      // Very light border
        static let separator = Color(hex: "E5E7EB")        // Separator line
        
        // MARK: - Shadow Colors
        static let shadowLight = Color.black.opacity(0.05) // Very light shadow
        static let shadowMedium = Color.black.opacity(0.1)  // Medium shadow
        static let shadowStrong = Color.black.opacity(0.2)  // Strong shadow
        
        // MARK: - Dark Mode Colors
        struct Dark {
            static let background = Color(hex: "0F0F0F")
            static let backgroundSecondary = Color(hex: "1A1A1A")
            static let surface = Color(hex: "1E1E1E")
            static let surfaceElevated = Color(hex: "2A2A2A")
            
            static let textPrimary = Color(hex: "FFFFFF")
            static let textSecondary = Color(hex: "D1D5DB")
            static let textTertiary = Color(hex: "9CA3AF")
            
            static let border = Color(hex: "374151")
            static let borderLight = Color(hex: "4B5563")
            static let separator = Color(hex: "374151")
            
            // Adjust pastel colors for dark mode (slightly more vibrant)
            static let primary = Color(hex: "E2A8ED")
            static let secondary = Color(hex: "A8E2ED")
            static let accent = Color(hex: "EDE2A8")
        }
        
        // MARK: - Adaptive Colors
        static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.background : background
        }
        
        static func adaptiveBackgroundSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.backgroundSecondary : backgroundSecondary
        }
        
        static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.surface : surface
        }
        
        static func adaptiveTextPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.textPrimary : textPrimary
        }
        
        static func adaptiveTextSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.textSecondary : textSecondary
        }
        
        static func adaptiveBorder(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.border : border
        }
        
        static func adaptivePrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.primary : primary
        }
    }
    
    // MARK: - Typography
    struct Typography {
        
        // MARK: - Font Sizes
        static let title1: CGFloat = 34
        static let title2: CGFloat = 28
        static let title3: CGFloat = 22
        static let headline: CGFloat = 18
        static let body: CGFloat = 16
        static let callout: CGFloat = 15
        static let subheadline: CGFloat = 14
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
        
        // MARK: - Font Weights
        static let thin = Font.Weight.thin
        static let ultraLight = Font.Weight.ultraLight
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        static let heavy = Font.Weight.heavy
        static let black = Font.Weight.black
        
        // MARK: - Font Styles
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1Font = Font.system(size: title1, weight: .bold, design: .default)
        static let title2Font = Font.system(size: title2, weight: .bold, design: .default)
        static let title3Font = Font.system(size: title3, weight: .semibold, design: .default)
        static let headlineFont = Font.system(size: headline, weight: .semibold, design: .default)
        static let bodyFont = Font.system(size: body, weight: .regular, design: .default)
        static let bodyBold = Font.system(size: body, weight: .semibold, design: .default)
        static let calloutFont = Font.system(size: callout, weight: .regular, design: .default)
        static let subheadlineFont = Font.system(size: subheadline, weight: .regular, design: .default)
        static let footnoteFont = Font.system(size: footnote, weight: .regular, design: .default)
        static let captionFont = Font.system(size: caption1, weight: .regular, design: .default)
        static let caption2Font = Font.system(size: caption2, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
        
        // MARK: - Layout Specific
        static let cardPadding = md
        static let sectionSpacing = xl
        static let screenPadding = md
        static let tabBarHeight: CGFloat = 49
        static let navigationBarHeight: CGFloat = 44
        static let minimumTouchTarget: CGFloat = 44
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
        static let round: CGFloat = 50 // For circular elements
        
        // MARK: - Component Specific
        static let button = md
        static let card = lg
        static let modal = xl
        static let image = sm
        static let textField = md
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = (color: Colors.shadowLight, radius: CGFloat(2), offset: CGSize(width: 0, height: 1))
        static let medium = (color: Colors.shadowMedium, radius: CGFloat(4), offset: CGSize(width: 0, height: 2))
        static let strong = (color: Colors.shadowStrong, radius: CGFloat(8), offset: CGSize(width: 0, height: 4))
        static let card = (color: Colors.shadowLight, radius: CGFloat(6), offset: CGSize(width: 0, height: 3))
        static let button = (color: Colors.shadowMedium, radius: CGFloat(3), offset: CGSize(width: 0, height: 2))
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let gentle = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.9)
        
        // MARK: - Component Specific
        static let buttonPress = quick
        static let tabSwitch = standard
        static let modalPresentation = slow
        static let photoTransition = standard
        static let sliderChange = quick
    }
    
    // MARK: - Icons
    struct Icons {
        // MARK: - Navigation
        static let home = "house"
        static let homeFilled = "house.fill"
        static let edit = "photo"
        static let editFilled = "photo.fill"
        static let filters = "camera.filters"
        static let premium = "crown"
        static let premiumFilled = "crown.fill"
        static let profile = "person"
        static let profileFilled = "person.fill"
        
        // MARK: - Actions
        static let add = "plus"
        static let close = "xmark"
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let share = "square.and.arrow.up"
        static let save = "square.and.arrow.down"
        static let delete = "trash"
        static let settings = "gear"
        static let info = "info.circle"
        static let help = "questionmark.circle"
        
        // MARK: - Photo & Camera
        static let camera = "camera"
        static let cameraFill = "camera.fill"
        static let photo = "photo"
        static let photoFill = "photo.fill"
        static let photoLibrary = "photo.on.rectangle"
        static let crop = "crop"
        static let rotate = "rotate.right"
        static let flip = "flip.horizontal"
        static let adjust = "slider.horizontal.3"
        
        // MARK: - Enhancement Tools
        static let brightness = "sun.max"
        static let contrast = "circle.lefthalf.filled"
        static let saturation = "drop"
        static let warmth = "thermometer"
        static let blur = "circle.fill"
        static let sharpen = "triangle"
        static let noise = "waveform"
        
        // MARK: - Beauty Features
        static let skinSmooth = "face.smiling"
        static let eyeBrighten = "eye"
        static let teethWhiten = "mouth"
        static let faceSlim = "oval"
        static let noseThin = "nose"
        static let lipEnhance = "mouth.fill"
        
        // MARK: - Status
        static let checkmark = "checkmark"
        static let checkmarkCircle = "checkmark.circle"
        static let checkmarkCircleFill = "checkmark.circle.fill"
        static let warning = "exclamationmark.triangle"
        static let error = "xmark.circle"
        static let loading = "arrow.2.circlepath"
        static let success = "checkmark.circle.fill"
        
        // MARK: - Premium Features
        static let crown = "crown"
        static let crownFill = "crown.fill"
        static let sparkles = "sparkles"
        static let star = "star"
        static let starFill = "star.fill"
        static let infinity = "infinity"
        static let lock = "lock"
        static let lockFill = "lock.fill"
        static let unlock = "lock.open"
        
        // MARK: - Social & Sharing
        static let heart = "heart"
        static let heartFill = "heart.fill"
        static let bookmark = "bookmark"
        static let bookmarkFill = "bookmark.fill"
        static let message = "message"
        static let messageFill = "message.fill"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Environment
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = GlowlyTheme.self
}

extension EnvironmentValues {
    var theme: GlowlyTheme.Type {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme Access
extension View {
    func themed() -> some View {
        self.environment(\.theme, GlowlyTheme.self)
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}