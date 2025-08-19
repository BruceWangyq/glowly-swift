//
//  ComparisonSystemDemo.swift
//  Glowly
//
//  Demo and integration examples for the before/after comparison system
//

import SwiftUI

// MARK: - Comparison System Demo
struct ComparisonSystemDemo: View {
    @State private var showingComparison = false
    @State private var selectedOriginal: UIImage?
    @State private var selectedProcessed: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Before/After Comparison")
                        .font(GlowlyTheme.Typography.title2Font)
                        .fontWeight(.bold)
                    
                    Text("Advanced comparison system with multiple viewing modes")
                        .font(GlowlyTheme.Typography.subheadlineFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Demo Images
                demoImagesSection
                
                // Features List
                featuresSection
                
                // Launch Button
                GlowlyButton(
                    title: "Try Comparison System",
                    action: {
                        showingComparison = true
                    },
                    style: .primary,
                    icon: "photo.stack"
                )
                .disabled(selectedOriginal == nil || selectedProcessed == nil)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Comparison Demo")
        }
        .sheet(isPresented: $showingComparison) {
            EnhancedBeforeAfterView(
                originalImage: selectedOriginal,
                processedImage: selectedProcessed,
                enhancementHighlights: sampleHighlights
            )
        }
        .onAppear {
            loadSampleImages()
        }
    }
    
    // MARK: - Demo Images Section
    
    private var demoImagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample Images")
                .font(GlowlyTheme.Typography.headlineFont)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Original Image
                VStack(spacing: 8) {
                    if let originalImage = selectedOriginal {
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    Text("Original")
                        .font(GlowlyTheme.Typography.captionFont)
                        .fontWeight(.medium)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Processed Image
                VStack(spacing: 8) {
                    if let processedImage = selectedProcessed {
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(Color.blue)
                                    )
                                    .offset(x: 40, y: -40),
                                alignment: .topTrailing
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    Text("Enhanced")
                        .font(GlowlyTheme.Typography.captionFont)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(GlowlyTheme.Typography.headlineFont)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                FeatureCard(
                    icon: "slider.horizontal.2.goforward",
                    title: "Swipe Reveal",
                    description: "Swipe to reveal before/after"
                )
                
                FeatureCard(
                    icon: "rectangle.split.2x1",
                    title: "Side by Side",
                    description: "Compare images side by side"
                )
                
                FeatureCard(
                    icon: "arrow.left.arrow.right",
                    title: "Toggle Mode",
                    description: "Tap to switch between images"
                )
                
                FeatureCard(
                    icon: "magnifyingglass",
                    title: "Zoom & Pan",
                    description: "Detailed inspection with sync"
                )
                
                FeatureCard(
                    icon: "square.and.arrow.up",
                    title: "Export Options",
                    description: "Multiple export formats"
                )
                
                FeatureCard(
                    icon: "sparkles",
                    title: "Enhancement Highlights",
                    description: "Visual enhancement indicators"
                )
            }
        }
    }
    
    // MARK: - Sample Data
    
    private var sampleHighlights: [EnhancementHighlight] {
        [
            EnhancementHighlight(
                region: CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.3),
                enhancementType: .skinSmoothing,
                intensity: 0.8,
                color: .pink
            ),
            EnhancementHighlight(
                region: CGRect(x: 0.25, y: 0.15, width: 0.2, height: 0.15),
                enhancementType: .eyeBrightening,
                intensity: 0.6,
                color: .blue
            )
        ]
    }
    
    // MARK: - Actions
    
    private func loadSampleImages() {
        // In a real app, these would be loaded from the bundle or network
        // For demo purposes, we'll create simple colored rectangles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedOriginal = createSampleImage(color: .systemGray2)
            selectedProcessed = createSampleImage(color: .systemBlue, enhanced: true)
        }
    }
    
    private func createSampleImage(color: UIColor, enhanced: Bool = false) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Base color
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some details
            UIColor.white.withAlphaComponent(0.3).setFill()
            
            // Simulate face area
            let faceRect = CGRect(x: 75, y: 100, width: 150, height: 200)
            UIBezierPath(ovalIn: faceRect).fill()
            
            if enhanced {
                // Add enhancement effect
                UIColor.systemBlue.withAlphaComponent(0.2).setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Add sparkles for enhancement
                UIColor.white.setFill()
                for _ in 0..<10 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let sparkleSize: CGFloat = 3
                    let sparkleRect = CGRect(x: x, y: y, width: sparkleSize, height: sparkleSize)
                    UIBezierPath(ovalIn: sparkleRect).fill()
                }
            }
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(GlowlyTheme.Colors.adaptivePrimary(colorScheme))
            
            Text(title)
                .font(GlowlyTheme.Typography.subheadlineFont)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(GlowlyTheme.Typography.caption2Font)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(GlowlyTheme.Colors.adaptiveSurface(colorScheme))
                .stroke(GlowlyTheme.Colors.adaptiveBorder(colorScheme), lineWidth: 1)
        )
    }
}

// MARK: - Usage Examples

/// Example integration with photo editing workflow
struct PhotoEditingIntegration: View {
    let photo: GlowlyPhoto
    @State private var showingComparison = false
    
    var body: some View {
        VStack {
            // Photo editing interface here...
            
            Button("Compare Before & After") {
                showingComparison = true
            }
            .sheet(isPresented: $showingComparison) {
                EnhancedBeforeAfterView(
                    originalImage: photo.originalUIImage,
                    processedImage: photo.enhancedUIImage,
                    enhancementHighlights: createHighlights(from: photo.enhancementHistory)
                )
            }
        }
    }
    
    private func createHighlights(from enhancements: [Enhancement]) -> [EnhancementHighlight] {
        // Convert enhancement history to visual highlights
        return enhancements.compactMap { enhancement in
            // This would map enhancement types to visual regions
            // Based on the enhancement data
            return nil // Placeholder
        }
    }
}

/// Example integration with camera workflow
struct CameraIntegration: View {
    @State private var capturedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingComparison = false
    
    var body: some View {
        VStack {
            // Camera interface here...
            
            if capturedImage != nil && processedImage != nil {
                Button("View Comparison") {
                    showingComparison = true
                }
                .sheet(isPresented: $showingComparison) {
                    EnhancedBeforeAfterView(
                        originalImage: capturedImage,
                        processedImage: processedImage
                    )
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ComparisonSystemDemo()
}