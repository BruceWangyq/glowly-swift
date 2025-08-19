# Before/After Comparison System

A comprehensive before/after preview comparison system for the Glowly beauty app with multiple viewing modes, advanced interaction features, and optimized performance.

## 🌟 Features

### Core Comparison Modes

1. **Swipe Reveal** - Interactive slider to reveal before/after
2. **Side-by-Side** - View both images simultaneously  
3. **Toggle Mode** - Quick tap to switch between images
4. **Split Screen** - Adjustable horizontal/vertical split view
5. **Overlay Mode** - Animated opacity transition
6. **Full Screen** - Immersive detailed view

### Interactive Features

- **Smooth Gesture Controls** - Pinch to zoom, pan to navigate
- **Synchronized Pan & Zoom** - Coordinated movement across both images
- **Visual Indicators** - Clear state indicators and labels
- **Quick Action Buttons** - Zoom controls, reset, and mode switching
- **Haptic Feedback** - Responsive tactile feedback for interactions

### Performance & Integration

- **Efficient Image Loading** - Optimized caching and memory management
- **GPU-Accelerated Rendering** - Smooth 60fps animations
- **Real-time Preview Updates** - Live enhancement previews
- **Thermal State Awareness** - Adaptive quality based on device state
- **Accessibility Support** - VoiceOver and accessibility features

### Export Features

- **Before/After Collage Creation** - Multiple template options
- **Social Media Ready Formats** - Platform-optimized exports
- **Animated Transformation Previews** - GIF and video exports
- **Custom Templates** - Branded comparison layouts

## 🏗️ Architecture

### Components Structure

```
Views/Components/
├── EnhancedBeforeAfterView.swift      # Main comparison interface
├── ComparisonSupportingViews.swift    # UI components and utilities
├── ExportOptionsView.swift            # Export functionality
├── ComparisonSettingsView.swift       # User preferences
├── ComparisonSystemDemo.swift         # Integration examples
└── BeforeAfterComparisonView.swift    # Legacy compatibility

ViewModels/
└── ComparisonViewModel.swift          # Business logic and state

Models/
└── ComparisonModels.swift             # Data models and enums
```

### Key Classes

#### `EnhancedBeforeAfterView`
Main comparison interface with all viewing modes and interactions.

#### `ComparisonViewModel`  
Manages state, preferences, and image processing with performance optimization.

#### `ExportManager`
Handles export functionality including templates, formats, and social media optimization.

## 🚀 Quick Start

### Basic Usage

```swift
import SwiftUI

struct MyView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    
    @State private var showingComparison = false
    
    var body: some View {
        Button("Compare") {
            showingComparison = true
        }
        .sheet(isPresented: $showingComparison) {
            EnhancedBeforeAfterView(
                originalImage: originalImage,
                processedImage: processedImage
            )
        }
    }
}
```

### With Enhancement Highlights

```swift
EnhancedBeforeAfterView(
    originalImage: originalImage,
    processedImage: processedImage,
    enhancementHighlights: [
        EnhancementHighlight(
            region: CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.3),
            enhancementType: .skinSmoothing,
            intensity: 0.8,
            color: .pink
        )
    ]
)
```

### Photo Integration

```swift
struct PhotoEditingView: View {
    let photo: GlowlyPhoto
    @State private var showingComparison = false
    
    var body: some View {
        VStack {
            // Photo editing interface
            
            Button("View Before & After") {
                showingComparison = true
            }
            .sheet(isPresented: $showingComparison) {
                EnhancedBeforeAfterView(
                    originalImage: photo.originalUIImage,
                    processedImage: photo.enhancedUIImage
                )
            }
        }
    }
}
```

## ⚙️ Configuration

### User Preferences

The system supports extensive customization through `ComparisonPreferences`:

```swift
var preferences = ComparisonPreferences()
preferences.defaultMode = .sideBySide
preferences.enableHaptics = true
preferences.zoomSensitivity = 1.2
preferences.enableMagnifier = true
preferences.watermarkEnabled = true
```

### Performance Settings

```swift
var imageQuality = ImageQuality.medium
imageQuality.compression = 0.85
imageQuality.maxDimension = 2048
imageQuality.format = .jpeg
```

### Gesture Configuration

```swift
var gestureConfig = GestureConfiguration()
gestureConfig.minimumZoom = 0.5
gestureConfig.maximumZoom = 4.0
gestureConfig.doubleTapZoomLevel = 2.0
gestureConfig.hapticFeedbackEnabled = true
```

## 🎨 Customization

### Custom Templates

Create custom export templates:

```swift
let customTemplate = ComparisonTemplate(
    name: "Brand Template",
    layout: .sideBySide,
    textOverlays: [
        TextOverlay(
            text: "BEFORE",
            position: CGPoint(x: 0.25, y: 0.05),
            font: .caption,
            color: .white,
            backgroundColor: .black.opacity(0.6),
            opacity: 0.9
        )
    ],
    backgroundStyle: .gradient([.black, .gray]),
    borderStyle: BorderStyle(color: .white, width: 2, cornerRadius: 12)
)
```

### Social Media Optimization

```swift
let exportOptions = ExportOptions(
    format: .collage,
    includeWatermark: true,
    socialPlatform: .instagram,
    customTemplate: customTemplate
)
```

## 📱 Supported Modes

### Swipe Reveal Mode
- Interactive slider divider
- Smooth gesture tracking
- Visual position indicator
- Haptic feedback at center position

### Side-by-Side Mode  
- Synchronized zoom and pan
- Individual image labels
- Equal split layout
- Smooth transitions

### Toggle Mode
- Tap to switch between images
- Visual state indicator
- Fade transition animation
- Accessibility support

### Split Screen Mode
- Horizontal or vertical splits
- Adjustable split position
- Drag handles for interaction
- Dynamic layout adaptation

### Overlay Mode
- Opacity-based blending
- Progress slider control
- Auto-animation option
- Smooth transitions

### Full Screen Mode
- Immersive viewing experience
- Maximum zoom capabilities
- Minimal UI overlay
- Gesture-based navigation

## 🔧 Performance Optimization

### Image Caching
- LRU cache with size limits
- Automatic memory management
- Thermal state awareness
- Background processing

### GPU Acceleration
- Metal-optimized rendering
- Core Animation integration
- Smooth 60fps animations
- Efficient memory usage

### Adaptive Quality
- Device capability detection
- Battery level awareness
- Thermal throttling
- Quality degradation strategies

## 📤 Export Capabilities

### Static Formats
- **Collage**: Side-by-side with templates
- **Split Image**: Single image with divider
- **High Resolution**: Up to 4K output

### Animated Formats
- **GIF**: Animated transitions
- **Video**: MP4 with custom transitions
- **Live Photos**: iOS Live Photo format

### Social Media
- **Instagram**: 1:1 square format
- **TikTok**: 9:16 vertical format
- **Facebook**: 16:9 landscape format
- **Twitter**: 16:9 landscape format

## 🎯 Accessibility

### VoiceOver Support
- Descriptive labels for all UI elements
- Gesture-based navigation
- Audio feedback for state changes
- Screen reader optimization

### Visual Accessibility
- High contrast mode support
- Dynamic Type compatibility
- Reduced motion options
- Color blindness considerations

### Motor Accessibility
- Adjustable gesture sensitivity
- Alternative interaction methods
- Larger touch targets
- Simplified gesture options

## 🧪 Testing

### Unit Tests
```swift
func testComparisonViewModel() {
    let viewModel = ComparisonViewModel()
    viewModel.updateComparisonMode(.sideBySide)
    XCTAssertEqual(viewModel.state.currentMode, .sideBySide)
}
```

### UI Tests
```swift
func testModeSelection() {
    let app = XCUIApplication()
    app.buttons["Swipe Reveal"].tap()
    XCTAssertTrue(app.staticTexts["Swipe Reveal"].exists)
}
```

## 🐛 Troubleshooting

### Common Issues

**Images not loading**
- Check image data is valid
- Verify sufficient memory available
- Ensure background thread usage

**Poor performance**
- Enable performance monitoring
- Check thermal state
- Reduce image quality settings

**Export failures**
- Verify write permissions
- Check available storage space
- Validate template configuration

### Debug Mode

Enable debug logging:
```swift
viewModel.enableDebugMode = true
```

## 📚 API Reference

### Core Classes

#### EnhancedBeforeAfterView
Main comparison interface view.

**Properties:**
- `originalImage: UIImage?` - Source image
- `processedImage: UIImage?` - Enhanced image  
- `enhancementHighlights: [EnhancementHighlight]` - Visual indicators

#### ComparisonViewModel
Business logic and state management.

**Key Methods:**
- `updateComparisonMode(_:)` - Change viewing mode
- `updateSliderPosition(_:)` - Update reveal position
- `updateZoomLevel(_:)` - Control zoom level
- `resetView()` - Return to default state

#### ExportManager
Export and sharing functionality.

**Key Methods:**
- `exportComparison(...)` - Create export image
- `createAnimatedComparison(...)` - Generate video
- `shareComparison(...)` - Social sharing

## 🔄 Migration Guide

### From Legacy BeforeAfterComparisonView

Old usage:
```swift
BeforeAfterComparisonView(
    originalImage: image1,
    processedImage: image2
)
```

New usage:
```swift
EnhancedBeforeAfterView(
    originalImage: image1,
    processedImage: image2
)
```

The legacy view automatically redirects to the enhanced version.

## 🤝 Contributing

1. Follow existing code patterns
2. Add unit tests for new features
3. Update documentation
4. Test accessibility features
5. Verify performance on older devices

## 📄 License

Part of the Glowly beauty app. See main project license.

---

For more examples and advanced usage, see `ComparisonSystemDemo.swift`.