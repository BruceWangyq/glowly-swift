//
//  GlowlyPhotoComponents.swift
//  Glowly
//
//  Specialized photo and beauty app components with Glowly design system
//

import SwiftUI
import PhotosUI

// MARK: - GlowlyPhotoGrid
struct GlowlyPhotoGrid: View {
    let photos: [GlowlyPhoto]
    let columns: Int
    var spacing: CGFloat = GlowlyTheme.Spacing.sm
    var onPhotoTap: ((GlowlyPhoto) -> Void)?
    var onPhotoLongPress: ((GlowlyPhoto) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: spacing) {
            ForEach(photos, id: \.id) { photo in
                GlowlyPhotoGridItem(
                    photo: photo,
                    onTap: { onPhotoTap?(photo) },
                    onLongPress: { onPhotoLongPress?(photo) }
                )
            }
        }
    }
}

// MARK: - GlowlyPhotoGridItem
struct GlowlyPhotoGridItem: View {
    let photo: GlowlyPhoto
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: photo.thumbnailURL ?? photo.originalImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image))
                    .overlay(
                        // Enhancement Indicator
                        VStack {
                            HStack {
                                Spacer()
                                if photo.isEnhanced {
                                    Image(systemName: GlowlyTheme.Icons.sparkles)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(
                                            Circle()
                                                .fill(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                                        )
                                        .padding(GlowlyTheme.Spacing.xxs)
                                }
                            }
                            Spacer()
                            
                            // Processing Quality Indicator
                            if photo.processingQuality == .high {
                                HStack {
                                    Spacer()
                                    Image(systemName: GlowlyTheme.Icons.starFill)
                                        .font(.caption2)
                                        .foregroundColor(GlowlyTheme.Colors.warning)
                                        .padding(2)
                                        .background(
                                            Circle()
                                                .fill(.white)
                                        )
                                        .padding(GlowlyTheme.Spacing.xxs)
                                }
                            }
                        }
                    )
                    .overlay(
                        // Selection/Pressed State
                        RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image)
                            .stroke(
                                GlowlyTheme.Colors.adaptivePrimary(colorScheme),
                                lineWidth: isPressed ? 2 : 0
                            )
                    )
            } placeholder: {
                RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image)
                    .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme)))
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(GlowlyTheme.Animation.quick, value: isPressed)
        .onTapGesture {
            HapticFeedback.light()
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticFeedback.medium()
            onLongPress?()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - GlowlyPhotoImportButton
struct GlowlyPhotoImportButton: View {
    let onPhotosSelected: ([UIImage]) -> Void
    var style: ImportStyle = .card
    var allowsMultipleSelection: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    var body: some View {
        Group {
            switch style {
            case .card:
                cardStyle
            case .button:
                buttonStyle
            case .floating:
                floatingStyle
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") {
                showingCamera = true
            }
            
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: allowsMultipleSelection ? 10 : 1,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCamera) {
            GlowlyCameraView { image in
                onPhotosSelected([image])
            }
        }
        .onChange(of: selectedPhotos) { items in
            Task {
                var images: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                onPhotosSelected(images)
                selectedPhotos = []
            }
        }
    }
    
    // MARK: - Style Variations
    
    private var cardStyle: some View {
        GlowlyCard(
            style: .outlined,
            onTap: {
                showingActionSheet = true
            }
        ) {
            VStack(spacing: GlowlyTheme.Spacing.md) {
                Image(systemName: GlowlyTheme.Icons.photoLibrary)
                    .font(.system(size: 48))
                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                
                VStack(spacing: GlowlyTheme.Spacing.xs) {
                    Text("Add Photos")
                        .font(GlowlyTheme.Typography.headlineFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                    
                    Text("Tap to select photos or take new ones")
                        .font(GlowlyTheme.Typography.subheadlineFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(minHeight: 120)
        }
    }
    
    private var buttonStyle: some View {
        GlowlyButton(
            title: "Add Photos",
            action: {
                showingActionSheet = true
            },
            icon: GlowlyTheme.Icons.add
        )
    }
    
    private var floatingStyle: some View {
        GlowlyFloatingActionButton(
            icon: GlowlyTheme.Icons.add,
            action: {
                showingActionSheet = true
            }
        )
    }
}

// MARK: - Import Style
extension GlowlyPhotoImportButton {
    enum ImportStyle {
        case card
        case button
        case floating
    }
}

// MARK: - GlowlyBeforeAfterView
struct GlowlyBeforeAfterView: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    var showLabels: Bool = true
    
    @State private var dividerPosition: CGFloat = 0.5
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Before Image (right side)
                Image(uiImage: beforeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(Rectangle())
                
                // After Image (left side, clipped)
                Image(uiImage: afterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(Rectangle())
                    .mask(
                        Rectangle()
                            .frame(width: geometry.size.width * dividerPosition)
                            .offset(x: -geometry.size.width * (1 - dividerPosition) / 2)
                    )
                
                // Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .offset(x: (dividerPosition - 0.5) * geometry.size.width)
                
                // Divider Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    )
                    .offset(x: (dividerPosition - 0.5) * geometry.size.width)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(GlowlyTheme.Animation.quick, value: isDragging)
                
                // Labels
                if showLabels {
                    VStack {
                        HStack {
                            if dividerPosition > 0.3 {
                                VStack {
                                    Text("AFTER")
                                        .font(GlowlyTheme.Typography.captionFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                    Spacer()
                                }
                                .padding(.leading)
                            }
                            
                            Spacer()
                            
                            if dividerPosition < 0.7 {
                                VStack {
                                    Text("BEFORE")
                                        .font(GlowlyTheme.Typography.captionFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                    Spacer()
                                }
                                .padding(.trailing)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GlowlyTheme.CornerRadius.image))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newPosition = value.location.x / geometry.size.width
                        dividerPosition = max(0, min(1, newPosition))
                        HapticFeedback.selection()
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .aspectRatio(beforeImage.size.width / beforeImage.size.height, contentMode: .fit)
    }
}

// MARK: - GlowlyEnhancementSlider
struct GlowlyEnhancementSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var showValue: Bool = true
    var unit: String = "%"
    var onValueChanged: ((Double) -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: GlowlyTheme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
                    .frame(width: 20)
                
                Text(title)
                    .font(GlowlyTheme.Typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextPrimary(colorScheme))
                
                Spacer()
                
                if showValue {
                    Text("\(formattedValue)\(unit)")
                        .font(GlowlyTheme.Typography.footnoteFont)
                        .foregroundColor(GlowlyTheme.Colors.adaptiveTextSecondary(colorScheme))
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
            
            // Slider
            HStack(spacing: GlowlyTheme.Spacing.sm) {
                // Min Label
                Text("\(Int(range.lowerBound))")
                    .font(GlowlyTheme.Typography.caption2Font)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                    .frame(minWidth: 20)
                
                // Custom Slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(GlowlyTheme.Colors.adaptiveBackgroundSecondary(colorScheme))
                            .frame(height: 4)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 2)
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
                            .frame(width: geometry.size.width * progressRatio, height: 4)
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .shadow(
                                color: GlowlyTheme.Shadow.medium.color,
                                radius: GlowlyTheme.Shadow.medium.radius
                            )
                            .offset(x: (geometry.size.width - thumbSize) * progressRatio)
                            .scaleEffect(isDragging ? 1.2 : 1.0)
                            .animation(GlowlyTheme.Animation.quick, value: isDragging)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let newValue = calculateValue(
                                    from: gesture.location.x,
                                    in: geometry.size.width
                                )
                                value = newValue
                                onValueChanged?(newValue)
                                HapticFeedback.selection()
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                }
                .frame(height: thumbSize)
                
                // Max Label
                Text("\(Int(range.upperBound))")
                    .font(GlowlyTheme.Typography.caption2Font)
                    .foregroundColor(GlowlyTheme.Colors.adaptiveTextTertiary(colorScheme))
                    .frame(minWidth: 20)
            }
        }
        .padding(.vertical, GlowlyTheme.Spacing.xs)
    }
    
    // MARK: - Computed Properties
    
    private var progressRatio: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var thumbSize: CGFloat {
        20
    }
    
    private var formattedValue: String {
        if let step = step, step < 1 {
            return String(format: "%.1f", value)
        } else {
            return "\(Int(value))"
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateValue(from position: CGFloat, in width: CGFloat) -> Double {
        let ratio = max(0, min(1, position / width))
        var newValue = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
        
        if let step = step {
            newValue = round(newValue / step) * step
        }
        
        return max(range.lowerBound, min(range.upperBound, newValue))
    }
}

// MARK: - GlowlyCameraView
struct GlowlyCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: GlowlyCameraView
        
        init(_ parent: GlowlyCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview("Photo Components") {
    ScrollView {
        VStack(spacing: GlowlyTheme.Spacing.xl) {
            // Import Button
            GlowlyPhotoImportButton(onPhotosSelected: { _ in })
            
            // Enhancement Slider
            GlowlyEnhancementSlider(
                title: "Brightness",
                icon: GlowlyTheme.Icons.brightness,
                value: .constant(75),
                range: 0...100
            ) { _ in }
            
            GlowlyEnhancementSlider(
                title: "Contrast",
                icon: GlowlyTheme.Icons.contrast,
                value: .constant(50),
                range: -100...100,
                unit: ""
            ) { _ in }
        }
        .padding()
    }
    .themed()
}