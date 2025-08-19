//
//  ColorPickerView.swift
//  Glowly
//
//  Advanced color picker for manual retouching tools with palette support
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: ColorInfo
    let colorPalettes: [ColorPalette]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPalette: ColorPalette?
    @State private var customColor: Color = .red
    @State private var showingCustomPicker = false
    @State private var searchText = ""
    
    var filteredPalettes: [ColorPalette] {
        if searchText.isEmpty {
            return colorPalettes
        } else {
            return colorPalettes.filter { palette in
                palette.name.localizedCaseInsensitiveContains(searchText) ||
                palette.colors.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Palette Categories
                paletteCategories
                
                Divider()
                
                // Color Grid
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredPalettes, id: \\.name) { palette in
                            PaletteSection(
                                palette: palette,
                                selectedColor: $selectedColor,
                                isSelected: selectedPalette?.name == palette.name
                            ) {
                                selectedPalette = palette
                            }
                        }
                        
                        // Custom Color Section
                        customColorSection
                    }
                    .padding()
                }
                
                // Selected Color Preview
                selectedColorPreview
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedPalette = colorPalettes.first
            customColor = selectedColor.color
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search colors...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Palette Categories
    
    private var paletteCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ColorCategory.allCases, id: \\.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedPalette?.category == category,
                        action: {
                            if let palette = colorPalettes.first(where: { $0.category == category }) {
                                selectedPalette = palette
                            }
                        }
                    )
                }
                
                Button {
                    showingCustomPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "eyedropper")
                            .font(.title3)
                        
                        Text("Custom")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(showingCustomPicker ? .blue : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showingCustomPicker ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Custom Color Section
    
    private var customColorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Custom Color")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingCustomPicker.toggle()
                } label: {
                    Image(systemName: showingCustomPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if showingCustomPicker {
                VStack(spacing: 16) {
                    // Color Wheel
                    ColorPicker("Select Color", selection: $customColor)
                        .labelsHidden()
                        .onChange(of: customColor) { newColor in
                            selectedColor = ColorInfo(name: "Custom", uiColor: UIColor(newColor))
                        }
                    
                    // RGB Sliders
                    VStack(spacing: 12) {
                        ColorSlider(
                            label: "Red",
                            value: .constant(Double(selectedColor.red)),
                            color: .red
                        ) { value in
                            selectedColor = ColorInfo(
                                name: selectedColor.name,
                                red: Float(value),
                                green: selectedColor.green,
                                blue: selectedColor.blue,
                                alpha: selectedColor.alpha
                            )
                        }
                        
                        ColorSlider(
                            label: "Green",
                            value: .constant(Double(selectedColor.green)),
                            color: .green
                        ) { value in
                            selectedColor = ColorInfo(
                                name: selectedColor.name,
                                red: selectedColor.red,
                                green: Float(value),
                                blue: selectedColor.blue,
                                alpha: selectedColor.alpha
                            )
                        }
                        
                        ColorSlider(
                            label: "Blue",
                            value: .constant(Double(selectedColor.blue)),
                            color: .blue
                        ) { value in
                            selectedColor = ColorInfo(
                                name: selectedColor.name,
                                red: selectedColor.red,
                                green: selectedColor.green,
                                blue: Float(value),
                                alpha: selectedColor.alpha
                            )
                        }
                        
                        ColorSlider(
                            label: "Alpha",
                            value: .constant(Double(selectedColor.alpha)),
                            color: .gray
                        ) { value in
                            selectedColor = ColorInfo(
                                name: selectedColor.name,
                                red: selectedColor.red,
                                green: selectedColor.green,
                                blue: selectedColor.blue,
                                alpha: Float(value)
                            )
                        }
                    }
                    
                    // Hex Input
                    HStack {
                        Text("Hex:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("#FFFFFF", text: .constant(selectedColor.hexString))
                            .textFieldStyle(.roundedBorder)
                            .font(.monospaced(.body)())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Selected Color Preview
    
    private var selectedColorPreview: some View {
        HStack {
            // Color Swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedColor.color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedColor.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("RGB(\\(Int(selectedColor.red * 255)), \\(Int(selectedColor.green * 255)), \\(Int(selectedColor.blue * 255)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Supporting Views

struct PaletteSection: View {
    let palette: ColorPalette
    @Binding var selectedColor: ColorInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(palette.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(palette.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(palette.colors, id: \\.name) { color in
                    ColorSwatch(
                        color: color,
                        isSelected: selectedColor.name == color.name,
                        action: {
                            selectedColor = color
                            onSelect()
                        }
                    )
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct ColorSwatch: View {
    let color: ColorInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                    : nil
                )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryButton: View {
    let category: ColorCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .blue : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                )
        }
    }
}

struct ColorSlider: View {
    let label: String
    let value: Binding<Double>
    let color: Color
    let onChange: (Double) -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)
            
            Slider(value: value, in: 0...1) { _ in
                onChange(value.wrappedValue)
            }
            .accentColor(color)
            
            Text("\\(Int(value.wrappedValue * 255))")
                .font(.caption)
                .monospaced()
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - ColorInfo Extensions

extension ColorInfo {
    var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    var hexString: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    ColorPickerView(
        selectedColor: .constant(ColorInfo(name: "Sample", red: 0.8, green: 0.6, blue: 0.4)),
        colorPalettes: [.naturalEyeColors, .vibrantEyeColors, .naturalHairColors]
    )
}