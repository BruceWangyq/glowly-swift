//
//  MicrotransactionStoreView.swift
//  Glowly
//
//  Store interface for individual filter packs and makeup bundles
//

import SwiftUI
import StoreKit

struct MicrotransactionStoreView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.resolve(SubscriptionManagerProtocol.self) as! SubscriptionManager
    @State private var selectedCategory: MicrotransactionCategory = .filters
    @State private var showingPurchaseConfirmation = false
    @State private var selectedProduct: MicrotransactionProduct?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category selector
                categorySelector
                
                // Products grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(filteredProducts, id: \.rawValue) { product in
                            ProductCard(
                                product: product,
                                storeProduct: subscriptionManager.getProduct(for: product),
                                isPurchased: subscriptionManager.subscriptionStatus.purchasedProducts.contains(product.productID),
                                onPurchase: { purchaseProduct(product) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                }
            }
        }
        .alert("Purchase Confirmation", isPresented: $showingPurchaseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Purchase") {
                if let product = selectedProduct {
                    confirmPurchase(product)
                }
            }
        } message: {
            if let product = selectedProduct,
               let storeProduct = subscriptionManager.getProduct(for: product) {
                Text("Purchase \(product.displayName) for \(storeProduct.displayPrice)?")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MicrotransactionCategory.allCases, id: \.rawValue) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        onSelect: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
    }
    
    private var filteredProducts: [MicrotransactionProduct] {
        MicrotransactionProduct.allCases.filter { $0.category == selectedCategory }
    }
    
    // MARK: - Actions
    
    private func purchaseProduct(_ product: MicrotransactionProduct) {
        selectedProduct = product
        showingPurchaseConfirmation = true
    }
    
    private func confirmPurchase(_ product: MicrotransactionProduct) {
        isPurchasing = true
        
        Task {
            do {
                let result = try await subscriptionManager.purchaseMicrotransaction(product)
                
                switch result {
                case .success:
                    // Purchase successful
                    break
                case .cancelled:
                    break
                case .failed(let error):
                    showError(error.localizedDescription)
                case .pending:
                    showError("Purchase is pending approval")
                }
            } catch {
                showError(error.localizedDescription)
            }
            
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
            } catch {
                showError("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: MicrotransactionCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text(category.displayName)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProductCard: View {
    let product: MicrotransactionProduct
    let storeProduct: Product?
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Product image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                Image(systemName: productIcon)
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(.white)
                
                if isPurchased {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // Product info
            VStack(spacing: 4) {
                Text(product.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Purchase button
            if isPurchased {
                Text("OWNED")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .frame(height: 32)
            } else {
                Button(action: onPurchase) {
                    Text(storeProduct?.displayPrice ?? product.price.formatted(.currency(code: "USD")))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    private var gradientColors: [Color] {
        switch product.category {
        case .filters:
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]
        case .makeup:
            return [Color.pink.opacity(0.7), Color.red.opacity(0.7)]
        case .collections:
            return [Color.orange.opacity(0.7), Color.yellow.opacity(0.7)]
        case .tools:
            return [Color.green.opacity(0.7), Color.teal.opacity(0.7)]
        }
    }
    
    private var productIcon: String {
        switch product.category {
        case .filters:
            return "camera.filters"
        case .makeup:
            return "paintbrush"
        case .collections:
            return "sparkles"
        case .tools:
            return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailSheet: View {
    let product: MicrotransactionProduct
    let storeProduct: Product?
    let isPurchased: Bool
    let onPurchase: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Large product preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                        
                        Image(systemName: productIcon)
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    
                    // Product information
                    VStack(spacing: 16) {
                        Text(product.displayName)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Features included
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's Included")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(getIncludedFeatures(), id: \.self) { feature in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(feature)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Purchase button
                    VStack(spacing: 12) {
                        if isPurchased {
                            Text("Already Owned")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button(action: onPurchase) {
                                Text("Purchase for \(storeProduct?.displayPrice ?? product.price.formatted(.currency(code: "USD")))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch product.category {
        case .filters:
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]
        case .makeup:
            return [Color.pink.opacity(0.7), Color.red.opacity(0.7)]
        case .collections:
            return [Color.orange.opacity(0.7), Color.yellow.opacity(0.7)]
        case .tools:
            return [Color.green.opacity(0.7), Color.teal.opacity(0.7)]
        }
    }
    
    private var productIcon: String {
        switch product.category {
        case .filters:
            return "camera.filters"
        case .makeup:
            return "paintbrush"
        case .collections:
            return "sparkles"
        case .tools:
            return "wrench.and.screwdriver"
        }
    }
    
    private func getIncludedFeatures() -> [String] {
        switch product {
        case .vintageFilters:
            return ["5 vintage-inspired filters", "Film grain effects", "Sepia tones", "Classic color grading"]
        case .cinematicFilters:
            return ["Movie-quality color grading", "Cinematic aspect ratios", "Professional looks", "Color temperature controls"]
        case .portraitFilters:
            return ["Perfect for selfies", "Skin smoothing", "Eye enhancement", "Portrait lighting"]
        case .fashionFilters:
            return ["High-fashion editorial looks", "Bold color palettes", "Professional styling", "Runway-inspired effects"]
        case .glowMakeup:
            return ["Natural glow effects", "Radiant skin", "Subtle highlights", "Healthy complexion"]
        case .dramaticMakeup:
            return ["Bold eye makeup", "Dramatic contouring", "Intense colors", "Evening looks"]
        case .naturalMakeup:
            return ["Everyday makeup", "Subtle enhancements", "Natural colors", "Fresh-faced look"]
        case .festivalMakeup:
            return ["Creative festival looks", "Glitter effects", "Bold colors", "Party-ready styles"]
        case .weddingCollection:
            return ["Romantic filters", "Soft lighting", "Bridal beauty", "Elegant effects"]
        case .holidayCollection:
            return ["Festive themed filters", "Holiday colors", "Seasonal effects", "Celebration looks"]
        case .summerCollection:
            return ["Bright summer vibes", "Sun-kissed effects", "Vibrant colors", "Beach-ready looks"]
        case .influencerPack:
            return ["Trending filters", "Social media optimized", "Influencer favorites", "Viral looks"]
        case .advancedRetouchPack:
            return ["Professional retouching", "Blemish removal", "Skin perfecting", "Detail enhancement"]
        case .professionalToolsPack:
            return ["Industry-standard tools", "Advanced controls", "Professional workflows", "Expert techniques"]
        }
    }
}