//
//  GlowlyNavigation.swift
//  Glowly
//
//  Enhanced navigation and layout components with Glowly design system
//

import SwiftUI

// MARK: - GlowlyTabBar
struct GlowlyTabBar: View {
    @Binding var selectedTab: AppTab
    let tabs: [AppTab]
    var onTabSelected: ((AppTab) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Namespace private var tabSelection
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content Area
            Spacer()
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(tabs, id: \.rawValue) { tab in
                    GlowlyTabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: tabSelection,
                        onTap: {
                            withAnimation(GlowlyTheme.Animation.tabSwitch) {
                                selectedTab = tab
                                onTabSelected?(tab)
                                HapticFeedback.light()
                            }
                        }
                    )
                }
            }
            .padding(.top, GlowlyTheme.Spacing.sm)
            .padding(.bottom, safeAreaInsets.bottom > 0 ? 0 : GlowlyTheme.Spacing.sm)
            .background(
                // Glassmorphism effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(
                // Top border
                Rectangle()
                    .fill(GlowlyTheme.Colors.adaptiveBorder(colorScheme))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
    }
}

// MARK: - GlowlyTabBarItem
struct GlowlyTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Background for selected state
                    if isSelected {
                        Capsule()
                            .fill(GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.15))
                            .frame(width: 50, height: 32)
                            .matchedGeometryEffect(id: "tab_background", in: namespace)
                    }
                    
                    // Icon
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .frame(height: 32)
                
                // Label
                Text(tab.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        isSelected 
            ? GlowlyTheme.Colors.adaptivePrimary(colorScheme)
            : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
    
    private var textColor: Color {
        isSelected 
            ? GlowlyTheme.Colors.adaptivePrimary(colorScheme)
            : GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme)
    }
}

// MARK: - GlowlyNavigationBar
struct GlowlyNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingAction: NavigationAction? = nil
    var trailingActions: [NavigationAction] = []
    var style: NavigationStyle = .standard
    var isTransparent: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: GlowlyTheme.Spacing.sm) {
            // Leading Action
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                if let leadingAction = leadingAction {
                    GlowlyNavigationButton(action: leadingAction)
                } else {
                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .frame(minWidth: 60, alignment: .leading)
            
            // Title Section
            VStack(spacing: 2) {
                Text(title)
                    .font(titleFont)
                    .fontWeight(titleFontWeight)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(GlowlyTheme.Typography.captionFont)
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Trailing Actions
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                ForEach(Array(trailingActions.enumerated()), id: \.offset) { _, action in
                    GlowlyNavigationButton(action: action)
                }
                
                // Placeholder for alignment if no actions
                if trailingActions.isEmpty {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, GlowlyTheme.Spacing.md)
        .frame(height: 44)
        .background(backgroundColor)
        .overlay(
            // Bottom border
            Rectangle()
                .fill(borderColor)
                .frame(height: isTransparent ? 0 : 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Computed Properties
    
    private var titleFont: Font {
        switch style {
        case .standard:
            return GlowlyTheme.Typography.headlineFont
        case .large:
            return GlowlyTheme.Typography.title2Font
        case .compact:
            return GlowlyTheme.Typography.bodyFont
        }
    }
    
    private var titleFontWeight: Font.Weight {
        switch style {
        case .standard, .compact:
            return .semibold
        case .large:
            return .bold
        }
    }
    
    private var titleColor: Color {
        GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme)
    }
    
    private var subtitleColor: Color {
        GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
    }
    
    private var backgroundColor: Color {
        if isTransparent {
            return Color.clear
        } else {
            return GlowlyTheme.Colors.adaptiveSurface(colorScheme)
        }
    }
    
    private var borderColor: Color {
        GlowlyTheme.Colors.adaptiveBorder(colorScheme)
    }
}

// MARK: - Navigation Style
extension GlowlyNavigationBar {
    enum NavigationStyle {
        case standard
        case large
        case compact
    }
}

// MARK: - GlowlyNavigationButton
struct GlowlyNavigationButton: View {
    let action: NavigationAction
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action.handler()
        }) {
            Group {
                switch action.type {
                case .icon(let iconName):
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(backgroundColor)
                                .opacity(backgroundOpacity)
                        )
                case .text(let text):
                    Text(text)
                        .font(GlowlyTheme.Typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                        .padding(.horizontal, GlowlyTheme.Spacing.sm)
                        .padding(.vertical, GlowlyTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(backgroundColor)
                                .opacity(backgroundOpacity)
                        )
                case .image(let imageName):
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(GlowlyTheme.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1.0 : 0.5)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        switch action.style {
        case .primary:
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        case .secondary:
            return GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
        case .destructive:
            return GlowlyTheme.Colors.error
        }
    }
    
    private var textColor: Color {
        switch action.style {
        case .primary:
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        case .secondary:
            return GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)
        case .destructive:
            return GlowlyTheme.Colors.error
        }
    }
    
    private var backgroundColor: Color {
        switch action.style {
        case .primary:
            return GlowlyTheme.Colors.adaptivePrimary(colorScheme)
        case .secondary:
            return GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme)
        case .destructive:
            return GlowlyTheme.Colors.error
        }
    }
    
    private var backgroundOpacity: Double {
        switch action.type {
        case .icon:
            return action.style == .secondary ? 1.0 : 0.1
        case .text:
            return 0.1
        case .image:
            return 0.0
        }
    }
}

// MARK: - NavigationAction
struct NavigationAction {
    let type: ActionType
    let style: ActionStyle
    let isEnabled: Bool
    let handler: () -> Void
    
    init(
        type: ActionType,
        style: ActionStyle = .secondary,
        isEnabled: Bool = true,
        handler: @escaping () -> Void
    ) {
        self.type = type
        self.style = style
        self.isEnabled = isEnabled
        self.handler = handler
    }
    
    enum ActionType {
        case icon(String)
        case text(String)
        case image(String)
    }
    
    enum ActionStyle {
        case primary
        case secondary
        case destructive
    }
}

// MARK: - Convenience NavigationAction creators
extension NavigationAction {
    static func back(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .icon(GlowlyTheme.Icons.back),
            style: .secondary,
            handler: handler
        )
    }
    
    static func close(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .icon(GlowlyTheme.Icons.close),
            style: .secondary,
            handler: handler
        )
    }
    
    static func settings(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .icon(GlowlyTheme.Icons.settings),
            style: .secondary,
            handler: handler
        )
    }
    
    static func share(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .icon(GlowlyTheme.Icons.share),
            style: .primary,
            handler: handler
        )
    }
    
    static func save(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .text("Save"),
            style: .primary,
            handler: handler
        )
    }
    
    static func done(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .text("Done"),
            style: .primary,
            handler: handler
        )
    }
    
    static func cancel(handler: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            type: .text("Cancel"),
            style: .secondary,
            handler: handler
        )
    }
}

// MARK: - GlowlyPageControl
struct GlowlyPageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    var onPageChanged: ((Int) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: GlowlyTheme.Spacing.xs) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Button(action: {
                    withAnimation(GlowlyTheme.Animation.gentle) {
                        currentPage = index
                        onPageChanged?(index)
                        HapticFeedback.selection()
                    }
                }) {
                    Capsule()
                        .fill(index == currentPage ? activeColor : inactiveColor)
                        .frame(
                            width: index == currentPage ? 24 : 8,
                            height: 8
                        )
                        .animation(GlowlyTheme.Animation.gentle, value: currentPage)
                }
            }
        }
        .padding(.horizontal, GlowlyTheme.Spacing.sm)
        .padding(.vertical, GlowlyTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Computed Properties
    
    private var activeColor: Color {
        GlowlyTheme.Colors.adaptivePrimary(colorScheme)
    }
    
    private var inactiveColor: Color {
        GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme).opacity(0.5)
    }
}

// MARK: - GlowlyProgressNavigationBar
struct GlowlyProgressNavigationBar: View {
    let title: String
    let progress: Double
    var leadingAction: NavigationAction? = nil
    var trailingAction: NavigationAction? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation content
            HStack {
                if let leadingAction = leadingAction {
                    GlowlyNavigationButton(action: leadingAction)
                }
                
                Spacer()
                
                Text(title)
                    .font(GlowlyTheme.Typography.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                Spacer()
                
                if let trailingAction = trailingAction {
                    GlowlyNavigationButton(action: trailingAction)
                }
            }
            .padding(.horizontal, GlowlyTheme.Spacing.md)
            .frame(height: 44)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                                    GlowlyTheme.Colors.primaryDark
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 3)
                        .animation(GlowlyTheme.Animation.gentle, value: progress)
                }
            }
            .frame(height: 3)
        }
        .background(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
    }
}

// MARK: - Safe Area Extensions
extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let safeArea = window.safeAreaInsets
            return EdgeInsets(
                top: safeArea.top,
                leading: safeArea.left,
                bottom: safeArea.bottom,
                trailing: safeArea.right
            )
        }
        return EdgeInsets()
    }
}

// MARK: - Preview
#Preview("Navigation Components") {
    VStack(spacing: 0) {
        GlowlyNavigationBar(
            title: "Edit Photo",
            subtitle: "AI Enhancement",
            leadingAction: .back { },
            trailingActions: [
                .share { },
                .save { }
            ]
        )
        
        Spacer()
        
        VStack(spacing: GlowlyTheme.Spacing.lg) {
            GlowlyPageControl(
                numberOfPages: 4,
                currentPage: .constant(1)
            )
            
            GlowlyProgressNavigationBar(
                title: "Processing",
                progress: 0.7,
                leadingAction: .cancel { },
                trailingAction: .done { }
            )
        }
        
        Spacer()
        
        GlowlyTabBar(
            selectedTab: .constant(.edit),
            tabs: AppTab.allCases
        )
    }
    .themed()
}