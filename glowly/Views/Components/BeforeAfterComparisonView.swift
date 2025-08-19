//
//  BeforeAfterComparisonView.swift
//  Glowly
//
//  Legacy before/after comparison view - redirects to EnhancedBeforeAfterView
//

import SwiftUI

struct BeforeAfterComparisonView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let enhancementHighlights: [EnhancementHighlight]
    
    init(originalImage: UIImage?, processedImage: UIImage?, enhancementHighlights: [EnhancementHighlight] = []) {
        self.originalImage = originalImage
        self.processedImage = processedImage
        self.enhancementHighlights = enhancementHighlights
    }
    
    var body: some View {
        // Redirect to the new enhanced comparison view
        EnhancedBeforeAfterView(
            originalImage: originalImage,
            processedImage: processedImage,
            enhancementHighlights: enhancementHighlights
        )
    }
}

#Preview {
    BeforeAfterComparisonView(
        originalImage: UIImage(systemName: "photo"),
        processedImage: UIImage(systemName: "photo.fill")
    )
}