//
//  GlowlyBeautyComponents.swift
//  Glowly
//
//  Beauty-specific enhancement components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyBeautyToolSelector
struct GlowlyBeautyToolSelector: View {
    let tools: [BeautyTool]
    @Binding var selectedTool: BeautyTool?
    var onToolSelected: ((BeautyTool) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                ForEach(tools, id: \.id) { tool in
                    GlowlyBeautyToolItem(
                        tool: tool,
                        isSelected: selectedTool?.id == tool.id,
                        onTap: {
                            selectedTool = tool
                            onToolSelected?(tool)
                            HapticFeedback.light()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - GlowlyBeautyToolItem
struct GlowlyBeautyToolItem: View {
    let tool: BeautyTool
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: GlowlyTheme.Spacing.xs) {
                // Tool Icon
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                    
                    Image(systemName: tool.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(GlowlyTheme.Animation.quick, value: isPressed)
                
                // Tool Name
                Text(tool.name)
                    .font(GlowlyTheme.Typography.captionFont)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Premium Badge
                if tool.isPremium {
                    Image(systemName: GlowlyTheme.Icons.crown)
                        .font(.system(size: 10))
                        .foregroundColor(GlowlyTheme.Colors.warning)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        } else {
            return GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
        }
    }
    
    private var iconColor: Color {
        if isSelected {
            return .white
        } else {
            return GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
        } else {
            return GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        } else {
            return GlowlyTheme.Colors.adaptiveBorder(colorScheme)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 1
    }
}

// MARK: - BeautyTool Model
struct BeautyTool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: BeautyCategory
    let isPremium: Bool
    let description: String
    
    enum BeautyCategory {
        case skin
        case face
        case eyes
        case lips
        case body
        
        var displayName: String {
            switch self {
            case .skin: return "Skin"
            case .face: return "Face"
            case .eyes: return "Eyes"
            case .lips: return "Lips"
            case .body: return "Body"
            }
        }
    }
}

// MARK: - GlowlyBeautyIntensityControl
struct GlowlyBeautyIntensityControl: View {
    let tool: BeautyTool
    @Binding var intensity: Double
    var isEnabled: Bool = true
    var onIntensityChanged: ((Double) -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: tool.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(headerIconColor)
                
                Text(tool.name)
                    .font(GlowlyTheme.Typography.headlineFont)
                    .foregroundColor(headerTextColor)
                
                if tool.isPremium {
                    Image(systemName: GlowlyTheme.Icons.crown)
                        .font(.caption)
                        .foregroundColor(GlowlyTheme.Colors.warning)
                }
                
                Spacer()
                
                Text("\(Int(intensity))%")
                    .font(GlowlyTheme.Typography.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundColor(intensityTextColor)
                    .monospacedDigit()
            }
            
            // Intensity Slider with Visual Feedback
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                // Custom circular slider
                GeometryReader { geometry in
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(
                                GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme),
                                lineWidth: 8
                            )
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: intensity / 100)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.3),
                                        GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                                        GlowlyTheme.Colors.primaryDark
                                    ],
                                    center: .center
                                ),
                                style: StrokeStyle(
                                    lineWidth: 8,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(GlowlyTheme.Animation.gentle, value: intensity)
                        
                        // Center content
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(centerIconColor)
                                .scaleEffect(isDragging ? 1.1 : 1.0)
                                .animation(GlowlyTheme.Animation.quick, value: isDragging)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let angle = atan2(
                                    value.location.y - geometry.size.height / 2,
                                    value.location.x - geometry.size.width / 2
                                )
                                let normalizedAngle = (angle + .pi / 2) / (2 * .pi)
                                let newIntensity = max(0, min(100, normalizedAngle * 100))
                                
                                if abs(newIntensity - intensity) > 1 {
                                    intensity = newIntensity
                                    onIntensityChanged?(newIntensity)
                                    HapticFeedback.selection()
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 120, maxHeight: 120)
                
                // Quick intensity presets
                HStack(spacing: GlowlyTheme.Spacing.sm) {
                    ForEach([25, 50, 75, 100], id: \.self) { preset in
                        Button("\(preset)%") {
                            withAnimation(GlowlyTheme.Animation.gentle) {
                                intensity = Double(preset)
                                onIntensityChanged?(Double(preset))
                                HapticFeedback.light()
                            }
                        }
                        .font(GlowlyTheme.Typography.caption2Font)
                        .foregroundColor(
                            abs(intensity - Double(preset)) < 5 
                                ? GlowlyTheme.Colors.adaptivePrimary(colorScheme)
                                : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
                        )
                        .fontWeight(abs(intensity - Double(preset)) < 5 ? .semibold : .regular)
                    }
                }
            }
            
            // Description
            Text(tool.description)
                .font(GlowlyTheme.Typography.footnoteFont)
                .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(GlowlyTheme.Spacing.md)
        .background(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.lg))
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Computed Properties
    
    private var headerIconColor: Color {
        isEnabled 
            ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) 
            : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
    
    private var headerTextColor: Color {
        isEnabled 
            ? GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme) 
            : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
    
    private var intensityTextColor: Color {
        isEnabled 
            ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) 
            : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
    
    private var centerIconColor: Color {
        if !isEnabled {
            return GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
        }
        
        let alpha = intensity / 100
        return GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.3 + alpha * 0.7)
    }
}

// MARK: - GlowlyFilterPreviewGrid
struct GlowlyFilterPreviewGrid: View {
    let filters: [BeautyFilter]
    @Binding var selectedFilter: BeautyFilter?
    let originalImage: UIImage
    var onFilterSelected: ((BeautyFilter) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: GlowlyTheme.Spacing.sm) {
            // Original (no filter)
            GlowlyFilterPreviewItem(
                name: "Original",
                previewImage: originalImage,
                isSelected: selectedFilter == nil,
                isPremium: false,
                onTap: {
                    selectedFilter = nil
                    onFilterSelected?(nil as BeautyFilter?)
                }
            )
            
            ForEach(filters, id: \.id) { filter in
                GlowlyFilterPreviewItem(
                    name: filter.name,
                    previewImage: filter.previewImage ?? originalImage,
                    isSelected: selectedFilter?.id == filter.id,
                    isPremium: filter.isPremium,
                    onTap: {
                        selectedFilter = filter
                        onFilterSelected?(filter)
                    }
                )
            }
        }
    }
}

// MARK: - GlowlyFilterPreviewItem
struct GlowlyFilterPreviewItem: View {
    let name: String
    let previewImage: UIImage
    let isSelected: Bool
    let isPremium: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(spacing: GlowlyTheme.Spacing.xs) {
                // Preview Image
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.sm)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .overlay(
                        // Premium badge
                        Group {
                            if isPremium {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: GlowlyTheme.Icons.crown)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(
                                                Circle()
                                                    .fill(GlowlyTheme.Colors.warning)
                                            )
                                            .padding(4)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(GlowlyTheme.Animation.quick, value: isPressed)
                
                // Filter Name
                Text(name)
                    .font(GlowlyTheme.Typography.caption2Font)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 0
    }
    
    private var textColor: Color {
        if isSelected {
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        } else {
            return GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
        }
    }
}

// MARK: - BeautyFilter Model
struct BeautyFilter: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: FilterCategory
    let isPremium: Bool
    let intensity: Double
    let previewImage: UIImage?
    
    enum FilterCategory {
        case natural
        case dramatic
        case vintage
        case artistic
        case beauty
        
        var displayName: String {
            switch self {
            case .natural: return "Natural"
            case .dramatic: return "Dramatic"
            case .vintage: return "Vintage"
            case .artistic: return "Artistic"
            case .beauty: return "Beauty"
            }
        }
    }
    
    static func == (lhs: BeautyFilter, rhs: BeautyFilter) -> Bool {
        lhs.id == rhs.id
    }
}

// Allow nil comparison for BeautyFilter
extension Optional where Wrapped == BeautyFilter {
    static func == (lhs: BeautyFilter?, rhs: BeautyFilter?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.some(l), .some(r)):
            return l.id == r.id
        default:
            return false
        }
    }
}

// MARK: - GlowlyBeautyControlPanel
struct GlowlyBeautyControlPanel: View {
    @Binding var selectedTool: BeautyTool?
    @Binding var toolIntensities: [UUID: Double]
    let availableTools: [BeautyTool]
    var onToolIntensityChanged: ((BeautyTool, Double) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAllTools = false
    
    private var visibleTools: [BeautyTool] {
        showingAllTools ? availableTools : Array(availableTools.prefix(6))
    }
    
    var body: some View {
        VStack(spacing: GlowlyTheme.Spacing.md) {
            // Tool Selector
            VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
                HStack {
                    Text("Beauty Tools")
                        .font(GlowlyTheme.Typography.headlineFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    Spacer()
                    
                    if availableTools.count > 6 {
                        Button(showingAllTools ? "Show Less" : "Show All") {
                            withAnimation(GlowlyTheme.Animation.standard) {
                                showingAllTools.toggle()
                            }
                        }
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    }
                }
                
                GlowlyBeautyToolSelector(
                    tools: visibleTools,
                    selectedTool: $selectedTool
                ) { tool in
                    // Auto-set intensity if not set
                    if toolIntensities[tool.id] == nil {
                        toolIntensities[tool.id] = 50
                        onToolIntensityChanged?(tool, 50)
                    }
                }
            }
            
            // Intensity Control for Selected Tool
            if let selectedTool = selectedTool {
                GlowlyBeautyIntensityControl(
                    tool: selectedTool,
                    intensity: Binding(
                        get: { toolIntensities[selectedTool.id] ?? 0 },
                        set: { newValue in
                            toolIntensities[selectedTool.id] = newValue
                            onToolIntensityChanged?(selectedTool, newValue)
                        }
                    )
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(GlowlyTheme.Animation.standard, value: selectedTool?.id)
    }
}

// MARK: - Sample Data
extension BeautyTool {
    static let sampleTools: [BeautyTool] = [
        BeautyTool(name: "Smooth Skin", icon: GlowlyTheme.Icons.skinSmooth, category: .skin, isPremium: false, description: "Softens skin texture and reduces imperfections"),
        BeautyTool(name: "Brighten Eyes", icon: GlowlyTheme.Icons.eyeBrighten, category: .eyes, isPremium: false, description: "Enhances eye brightness and clarity"),
        BeautyTool(name: "Whiten Teeth", icon: GlowlyTheme.Icons.teethWhiten, category: .lips, isPremium: true, description: "Brightens and whitens teeth naturally"),
        BeautyTool(name: "Slim Face", icon: GlowlyTheme.Icons.faceSlim, category: .face, isPremium: true, description: "Subtly slims facial features"),
        BeautyTool(name: "Thin Nose", icon: GlowlyTheme.Icons.noseThin, category: .face, isPremium: true, description: "Refines nose shape naturally"),
        BeautyTool(name: "Enhance Lips", icon: GlowlyTheme.Icons.lipEnhance, category: .lips, isPremium: true, description: "Adds fullness and color to lips"),
    ]
}

// MARK: - Preview
#Preview("Beauty Components") {
    ScrollView {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            GlowlyBeautyToolSelector(
                tools: BeautyTool.sampleTools,
                selectedTool: .constant(BeautyTool.sampleTools.first)
            )
            
            if let sampleTool = BeautyTool.sampleTools.first {
                GlowlyBeautyIntensityControl(
                    tool: sampleTool,
                    intensity: .constant(75)
                )
            }
        }
        .padding()
    }
    .themed()
}