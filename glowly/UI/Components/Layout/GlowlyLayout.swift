//
//  GlowlyLayout.swift
//  Glowly
//
//  Layout components and containers with Glowly design system
//

import SwiftUI

// MARK: - GlowlyScreenContainer
struct GlowlyScreenContainer<Content: View>: View {
    let content: Content
    var style: ScreenStyle = .standard
    var showsNavigationBar: Bool = true
    var navigationTitle: String = ""
    var navigationSubtitle: String? = nil
    var leadingAction: NavigationAction? = nil
    var trailingActions: [NavigationAction] = []
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        style: ScreenStyle = .standard,
        showsNavigationBar: Bool = true,
        navigationTitle: String = "",
        navigationSubtitle: String? = nil,
        leadingAction: NavigationAction? = nil,
        trailingActions: [NavigationAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.showsNavigationBar = showsNavigationBar
        self.navigationTitle = navigationTitle
        self.navigationSubtitle = navigationSubtitle
        self.leadingAction = leadingAction
        self.trailingActions = trailingActions
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            if showsNavigationBar {
                GlowlyNavigationBar(
                    title: navigationTitle,
                    subtitle: navigationSubtitle,
                    leadingAction: leadingAction,
                    trailingActions: trailingActions,
                    style: navigationStyle,
                    isTransparent: style == .fullScreen
                )
                .zIndex(1)
            }
            
            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
        }
        .ignoresSafeArea(edges: style == .fullScreen ? .all : [])
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .standard:
            return GlowlyTheme.Colors.adaptiveBackground(colorScheme)
        case .surface:
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        case .fullScreen:
            return Color.black
        case .gradient:
            return Color.clear
        }
    }
    
    private var navigationStyle: GlowlyNavigationBar.NavigationStyle {
        switch style {
        case .standard, .surface:
            return .standard
        case .fullScreen:
            return .compact
        case .gradient:
            return .large
        }
    }
}

// MARK: - Screen Style
extension GlowlyScreenContainer {
    enum ScreenStyle {
        case standard
        case surface
        case fullScreen
        case gradient
    }
}

// MARK: - GlowlyScrollableContainer
struct GlowlyScrollableContainer<Content: View>: View {
    let content: Content
    var style: ScrollStyle = .standard
    var showsIndicators: Bool = false
    var refreshable: Bool = false
    var onRefresh: (() async -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        style: ScrollStyle = .standard,
        showsIndicators: Bool = false,
        refreshable: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.showsIndicators = showsIndicators
        self.refreshable = refreshable
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            LazyVStack(spacing: contentSpacing) {
                content
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .background(backgroundColor)
        .refreshable {
            if refreshable, let onRefresh = onRefresh {
                await onRefresh()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .standard:
            return GlowlyTheme.Colors.adaptiveBackground(colorScheme)
        case .surface:
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        case .compact:
            return GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
        }
    }
    
    private var contentSpacing: CGFloat {
        switch style {
        case .standard:
            return GlowlyTheme.Spacing.lg
        case .surface:
            return GlowlyTheme.Spacing.md
        case .compact:
            return GlowlyTheme.Spacing.sm
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard, .surface:
            return GlowlyTheme.Spacing.screenPadding
        case .compact:
            return GlowlyTheme.Spacing.sm
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .standard:
            return GlowlyTheme.Spacing.lg
        case .surface:
            return GlowlyTheme.Spacing.md
        case .compact:
            return GlowlyTheme.Spacing.sm
        }
    }
}

// MARK: - Scroll Style
extension GlowlyScrollableContainer {
    enum ScrollStyle {
        case standard
        case surface
        case compact
    }
}

// MARK: - GlowlySection
struct GlowlySection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content
    var style: SectionStyle = .standard
    var headerAction: SectionAction? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String? = nil,
        subtitle: String? = nil,
        style: SectionStyle = .standard,
        headerAction: SectionAction? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.headerAction = headerAction
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            // Header
            if title != nil || subtitle != nil || headerAction != nil {
                VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.xxs) {
                    if let title = title {
                        HStack {
                            Text(title)
                                .font(titleFont)
                                .fontWeight(titleFontWeight)
                                .foregroundColor(titleColor)
                            
                            Spacer()
                            
                            if let headerAction = headerAction {
                                Button(headerAction.title) {
                                    headerAction.action()
                                }
                                .font(GlowlyTheme.Typography.subheadlineFont)
                                .fontWeight(.medium)
                                .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                            }
                        }
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(GlowlyTheme.Typography.subheadlineFont)
                            .foregroundColor(subtitleColor)
                    }
                }
                .padding(.horizontal, headerPadding)
            }
            
            // Content
            content
        }
    }
    
    // MARK: - Computed Properties
    
    private var titleFont: Font {
        switch style {
        case .standard:
            return GlowlyTheme.Typography.title3Font
        case .compact:
            return GlowlyTheme.Typography.headlineFont
        case .card:
            return GlowlyTheme.Typography.headlineFont
        }
    }
    
    private var titleFontWeight: Font.Weight {
        switch style {
        case .standard:
            return .bold
        case .compact, .card:
            return .semibold
        }
    }
    
    private var titleColor: Color {
        GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
    }
    
    private var subtitleColor: Color {
        GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
    }
    
    private var sectionSpacing: CGFloat {
        switch style {
        case .standard:
            return GlowlyTheme.Spacing.md
        case .compact:
            return GlowlyTheme.Spacing.sm
        case .card:
            return GlowlyTheme.Spacing.md
        }
    }
    
    private var headerPadding: CGFloat {
        switch style {
        case .standard, .compact:
            return 0
        case .card:
            return GlowlyTheme.Spacing.md
        }
    }
}

// MARK: - Section Style and Action
extension GlowlySection {
    enum SectionStyle {
        case standard
        case compact
        case card
    }
    
    struct SectionAction {
        let title: String
        let action: () -> Void
    }
}

// MARK: - GlowlyGridLayout
struct GlowlyGridLayout<Content: View>: View {
    let content: Content
    let columns: Int
    var spacing: CGFloat = GlowlyTheme.Spacing.md
    var style: GridStyle = .standard
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        columns: Int,
        spacing: CGFloat = GlowlyTheme.Spacing.md,
        style: GridStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.style = style
        self.content = content()
    }
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: spacing) {
            content
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    // MARK: - Computed Properties
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard:
            return GlowlyTheme.Spacing.md
        case .compact:
            return GlowlyTheme.Spacing.sm
        case .expanded:
            return 0
        }
    }
}

// MARK: - Grid Style
extension GlowlyGridLayout {
    enum GridStyle {
        case standard
        case compact
        case expanded
    }
}

// MARK: - GlowlyEmptyState
struct GlowlyEmptyState: View {
    let icon: String
    let title: String
    let description: String
    var primaryAction: EmptyStateAction? = nil
    var secondaryAction: EmptyStateAction? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            VStack(spacing: GlowlyTheme.Spacing.lg) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                
                // Text Content
                VStack(spacing: GlowlyTheme.Spacing.sm) {
                    Text(title)
                        .font(GlowlyTheme.Typography.title2Font)
                        .fontWeight(.semibold)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(GlowlyTheme.Typography.bodyFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            // Actions
            VStack(spacing: GlowlyTheme.Spacing.sm) {
                if let primaryAction = primaryAction {
                    GlowlyButton(
                        title: primaryAction.title,
                        action: primaryAction.action,
                        style: .primary,
                        size: .fullWidth
                    )
                }
                
                if let secondaryAction = secondaryAction {
                    GlowlyButton(
                        title: secondaryAction.title,
                        action: secondaryAction.action,
                        style: .secondary,
                        size: .fullWidth
                    )
                }
            }
            .padding(.horizontal, GlowlyTheme.Spacing.xl)
        }
        .frame(maxWidth: 320)
        .padding(GlowlyTheme.Spacing.xl)
    }
    
    struct EmptyStateAction {
        let title: String
        let action: () -> Void
    }
}

// MARK: - GlowlyDivider
struct GlowlyDivider: View {
    var style: DividerStyle = .standard
    var color: Color? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: dividerHeight)
            .padding(.horizontal, horizontalPadding)
    }
    
    // MARK: - Computed Properties
    
    private var dividerColor: Color {
        color ?? GlowlyTheme.Colors.adaptiveBorder(colorScheme)
    }
    
    private var dividerHeight: CGFloat {
        switch style {
        case .standard:
            return 1
        case .thick:
            return 2
        case .thin:
            return 0.5
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard, .thick:
            return GlowlyTheme.Spacing.md
        case .thin:
            return 0
        }
    }
}

// MARK: - Divider Style
extension GlowlyDivider {
    enum DividerStyle {
        case standard
        case thick
        case thin
    }
}

// MARK: - GlowlyCollapsibleSection
struct GlowlyCollapsibleSection<Content: View>: View {
    let title: String
    let icon: String?
    let content: Content
    @State private var isExpanded: Bool
    var onToggle: ((Bool) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        icon: String? = nil,
        isInitiallyExpanded: Bool = false,
        onToggle: ((Bool) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: isInitiallyExpanded)
        self.onToggle = onToggle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(GlowlyTheme.Animation.standard) {
                    isExpanded.toggle()
                    onToggle?(isExpanded)
                    HapticFeedback.light()
                }
            }) {
                HStack(spacing: GlowlyTheme.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    }
                    
                    Text(title)
                        .font(GlowlyTheme.Typography.headlineFont)
                        .fontWeight(.semibold)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(GlowlyTheme.Animation.standard, value: isExpanded)
                }
                .padding(.vertical, GlowlyTheme.Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                content
                    .padding(.top, GlowlyTheme.Spacing.sm)
                    .transition(.opacity.combined(with: .slide))
            }
        }
    }
}

// MARK: - Preview
#Preview("Layout Components") {
    GlowlyScreenContainer(
        navigationTitle: "Layout Components",
        leadingAction: .back { }
    ) {
        GlowlyScrollableContainer {
            GlowlySection(
                title: "Photo Grid",
                subtitle: "Your recent photos"
            ) {
                GlowlyGridLayout(columns: 3) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(.light))
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image))
                    }
                }
            }
            
            GlowlyDivider()
            
            GlowlyCollapsibleSection(
                title: "Advanced Settings",
                icon: GlowlyTheme.Icons.settings,
                isInitiallyExpanded: false
            ) {
                VStack(spacing: GlowlyTheme.Spacing.md) {
                    Text("Collapsible content goes here")
                    Text("This section can be expanded or collapsed")
                }
            }
            
            GlowlyEmptyState(
                icon: GlowlyTheme.Icons.photo,
                title: "No Photos",
                description: "Add some photos to get started with AI enhancement",
                primaryAction: GlowlyEmptyState.EmptyStateAction(title: "Add Photos") { }
            )
        }
    }
    .themed()
}