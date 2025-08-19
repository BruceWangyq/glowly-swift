//
//  ComparisonSupportingViews.swift
//  Glowly
//
//  Supporting views and components for the before/after comparison system
//

import SwiftUI

// MARK: - ImageView
struct ImageView: View {
    let image: UIImage
    let geometry: GeometryProxy
    let zoomLevel: CGFloat
    let panOffset: CGSize
    var allowFullZoom: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scaleEffect(zoomLevel)
            .offset(panOffset)
            .clipped()
    }
}

// MARK: - ModeButton
struct ModeButton: View {
    let mode: ComparisonMode
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : .white.opacity(0.7))
                
                Text(mode.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : .white.opacity(0.7))
            }
            .frame(width: 80, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme).opacity(0.2) : Color.clear)
                    .stroke(
                        isSelected ? GlowlyTheme.Colors.adaptivePrimary(colorScheme) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SliderDivider
struct SliderDivider: View {
    let position: CGFloat
    let geometry: GeometryProxy
    let onPositionChanged: (CGFloat) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Divider line
            Rectangle()
                .fill(Color.white)
                .frame(width: 2)
                .shadow(color: .black.opacity(0.5), radius: 2)
                .position(x: geometry.size.width * position, y: geometry.size.height / 2)
            
            // Handle
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.3), radius: 4)
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                )
                .position(x: geometry.size.width * position, y: geometry.size.height / 2)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newPosition = value.location.x / geometry.size.width
                    let clampedPosition = max(0, min(1, newPosition))
                    onPositionChanged(clampedPosition)
                    HapticFeedback.selection()
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - ImageLabel
struct ImageLabel: View {
    let text: String
    let position: LabelPosition
    
    enum LabelPosition {
        case topLeading, topTrailing, center
    }
    
    var body: some View {
        VStack {
            if position == .topLeading || position == .topTrailing {
                HStack {
                    if position == .topLeading {
                        labelView
                        Spacer()
                    } else {
                        Spacer()
                        labelView
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                Spacer()
            } else {
                Spacer()
                labelView
                Spacer()
            }
        }
    }
    
    private var labelView: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .blur(radius: 1)
            )
    }
}

// MARK: - ToggleIndicator
struct ToggleIndicator: View {
    let isShowingBefore: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isShowingBefore ? Color.white : Color.white.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Text("B")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isShowingBefore ? .black : .white)
                )
            
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 2)
            
            Circle()
                .fill(!isShowingBefore ? Color.white : Color.white.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Text("A")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(!isShowingBefore ? .black : .white)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
                .blur(radius: 1)
        )
    }
}

// MARK: - HorizontalSplitHandle
struct HorizontalSplitHandle: View {
    let position: CGFloat
    let geometry: GeometryProxy
    let onPositionChanged: (CGFloat) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: geometry.size.height * position - 20)
            
            HStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 4)
                    .cornerRadius(2)
                Spacer()
                    .frame(width: 40)
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 4)
                    .cornerRadius(2)
            }
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
            )
            
            Spacer()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newPosition = value.location.y / geometry.size.height
                    let clampedPosition = max(0.1, min(0.9, newPosition))
                    onPositionChanged(clampedPosition)
                    HapticFeedback.selection()
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - VerticalSplitHandle
struct VerticalSplitHandle: View {
    let position: CGFloat
    let geometry: GeometryProxy
    let onPositionChanged: (CGFloat) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: geometry.size.width * position - 20)
            
            VStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4)
                    .cornerRadius(2)
                Spacer()
                    .frame(height: 40)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4)
                    .cornerRadius(2)
            }
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
            )
            
            Spacer()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newPosition = value.location.x / geometry.size.width
                    let clampedPosition = max(0.1, min(0.9, newPosition))
                    onPositionChanged(clampedPosition)
                    HapticFeedback.selection()
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - OverlayProgressView
struct OverlayProgressView: View {
    let progress: Double
    let onProgressChanged: (Double) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Blend: \(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(x: (geometry.size.width - 20) * progress)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                            onProgressChanged(newProgress)
                            HapticFeedback.selection()
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .blur(radius: 1)
        )
    }
}

// MARK: - EnhancementHighlightView
struct EnhancementHighlightView: View {
    let highlight: EnhancementHighlight
    let imageSize: CGSize
    let zoomLevel: CGFloat
    let panOffset: CGSize
    
    @State private var isVisible = false
    
    var body: some View {
        let scaledRect = CGRect(
            x: highlight.region.origin.x * imageSize.width,
            y: highlight.region.origin.y * imageSize.height,
            width: highlight.region.size.width * imageSize.width,
            height: highlight.region.size.height * imageSize.height
        )
        
        RoundedRectangle(cornerRadius: 4)
            .stroke(highlight.enhancementType.color, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(highlight.enhancementType.color.opacity(0.1))
            )
            .frame(width: scaledRect.width * zoomLevel, height: scaledRect.height * zoomLevel)
            .position(
                x: (scaledRect.midX * zoomLevel) + panOffset.width,
                y: (scaledRect.midY * zoomLevel) + panOffset.height
            )
            .overlay(
                VStack {
                    HStack {
                        Image(systemName: highlight.enhancementType.icon)
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Text(highlight.enhancementType.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(highlight.enhancementType.color)
                    )
                    .position(
                        x: (scaledRect.midX * zoomLevel) + panOffset.width,
                        y: (scaledRect.minY * zoomLevel) + panOffset.height - 20
                    )
                    
                    Spacer()
                }
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 0.3).delay(Double(highlight.id.hashValue % 5) * 0.1), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - MagnifierView
struct MagnifierView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let center: CGPoint
    let size: CGFloat
    let showingBefore: Bool
    
    private let magnificationLevel: CGFloat = 3.0
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .shadow(color: .black.opacity(0.5), radius: 8)
            )
            .overlay(
                magnifiedContent
                    .clipShape(Circle())
            )
            .overlay(
                // Crosshairs
                Group {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 1, height: size * 0.3)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: size * 0.3, height: 1)
                }
            )
    }
    
    private var magnifiedContent: some View {
        Group {
            if showingBefore, let originalImage = originalImage {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(magnificationLevel)
            } else if let processedImage = processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(magnificationLevel)
            }
        }
    }
}

// MARK: - Geometry Utilities
struct GeometryInfo {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    
    init(size: CGSize, safeAreaInsets: EdgeInsets = EdgeInsets()) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview("Mode Buttons") {
    HStack {
        ForEach(ComparisonMode.allCases, id: \.self) { mode in
            ModeButton(
                mode: mode,
                isSelected: mode == .sideBySide,
                action: {}
            )
        }
    }
    .padding()
    .background(Color.black)
}

#Preview("Image Labels") {
    ZStack {
        Color.black
        
        VStack {
            ImageLabel(text: "BEFORE", position: .topLeading)
            Spacer()
            ImageLabel(text: "CENTER", position: .center)
            Spacer()
            ImageLabel(text: "AFTER", position: .topTrailing)
        }
    }
    .frame(height: 300)
}

#Preview("Toggle Indicator") {
    VStack(spacing: 20) {
        ToggleIndicator(isShowingBefore: true)
        ToggleIndicator(isShowingBefore: false)
    }
    .padding()
    .background(Color.black)
}