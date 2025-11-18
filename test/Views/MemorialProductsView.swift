//
//  MemorialProductsView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct MemorialProductsView: View {
    @State private var selectedCategory: ProductCategory = .all
    @State private var searchText = ""
    @State private var showingProductDetail = false
    @State private var selectedProduct: Product?
    @State private var showingCart = false
    @State private var showingAddToCartAlert = false
    @State private var addToCartMessage = ""
    
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]
    @Query private var pets: [Pet]
    
    @ObservedObject private var cartService = CartService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color.pink.opacity(0.05),
                        Color.purple.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 分类筛选
                    categoryFilter
                    
                    // 产品网格
                    productGrid
                }
            }
            .navigationTitle("Memorial Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCart = true }) {
                        ZStack {
                            Image(systemName: "cart")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.pink, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if cartService.getTotalItemCount() > 0 {
                                Text("\(cartService.getTotalItemCount())")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search products...")
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailView(product: product, cartService: cartService, isPresented: $showingProductDetail)
            }
        }
        .sheet(isPresented: $showingCart) {
            CartView(cartService: cartService)
        }
        .alert("Shopping Cart", isPresented: $showingAddToCartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addToCartMessage)
        }
        .onAppear {
            cartService.setModelContext(modelContext)
            loadSampleProducts()
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(filteredProducts) { product in
                    MemorialProductCard(product: product) {
                        selectedProduct = product
                        showingProductDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var filteredProducts: [Product] {
        let categoryFiltered = selectedCategory == .all ? products : products.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
(product.productDescription ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadSampleProducts() {
        // 如果已有产品，不重复加载
        guard products.isEmpty else { return }
        
        let sampleProducts = [
            Product(
                name: "Custom Pet Portrait Frame",
                description: "Beautiful wooden frame with your pet's photo and name engraved",
                price: 89.99,
                category: .frames,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=elegant%20wooden%20picture%20frame%20with%20pet%20photo%20memorial%20engraved%20text&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Wood Type", "Engraving Text", "Frame Size"])
            ),
            Product(
                name: "Memorial Stone Garden Marker",
                description: "Durable stone marker for your garden with custom engraving",
                price: 129.99,
                category: .stones,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=beautiful%20memorial%20stone%20garden%20marker%20pet%20remembrance%20engraved&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Stone Material", "Engraving Design", "Size"])
            ),
            Product(
                name: "Pet Memory Jewelry Box",
                description: "Elegant jewelry box to keep your pet's collar and memories safe",
                price: 69.99,
                category: .jewelry,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=elegant%20wooden%20jewelry%20box%20pet%20memorial%20keepsake%20storage&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Material", "Interior Layout", "Engraving"])
            ),
            Product(
                name: "Custom Pet Blanket",
                description: "Soft fleece blanket with your pet's photo printed in high quality",
                price: 49.99,
                category: .textiles,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=soft%20fleece%20blanket%20with%20pet%20photo%20print%20memorial%20keepsake&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Size", "Photo Layout", "Border Design"])
            ),
            Product(
                name: "Memorial Candle Set",
                description: "Set of 3 scented candles with your pet's name and dates",
                price: 39.99,
                category: .candles,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=elegant%20memorial%20candle%20set%20pet%20remembrance%20scented%20candles&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Scent", "Candle Color", "Label Design"])
            ),
            Product(
                name: "Digital Memorial Album",
                description: "Beautiful digital photo album with music and memories",
                price: 29.99,
                category: .digital,
                imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=digital%20photo%20album%20interface%20pet%20memories%20slideshow&image_size=square"),
                customizationOptions: try? JSONEncoder().encode(["Theme", "Music Selection", "Photo Effects"])
            )
        ]
        
        for product in sampleProducts {
            modelContext.insert(product)
        }
        
        try? modelContext.save()
    }
}

struct CategoryChip: View {
    let category: ProductCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.pink, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.systemGray5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MemorialProductCard: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 产品图片
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .aspectRatio(1, contentMode: .fit)
                    
                    if let imageURL = product.imageURL {
                        CachedAsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                    
                    // 收藏按钮
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // TODO: Toggle favorite
                            }) {
                                Image(systemName: "heart")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(product.productDescription ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(product.formattedPrice)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                        
                        if product.hasCustomization {
                            Image(systemName: "paintbrush")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var cartService: CartService
    @Binding var isPresented: Bool
    
    @State private var quantity = 1
    @State private var customizationOptions: [String: String] = [:]
    @State private var showingAddToCartAlert = false
    @State private var addToCartMessage = ""
    @State private var showingQuickBuy = false
    
    private var totalPrice: Double {
        product.price * Double(quantity)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    AsyncImage(url: product.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(String(format: "$%.2f", product.price))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(product.productDescription ?? "")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Customization Options
                        if let customizationData = product.customizationOptions,
                           let decodedOptions = try? JSONDecoder().decode([String].self, from: customizationData),
                           !decodedOptions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Customization Options")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(decodedOptions.sorted(), id: \.self) { option in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        TextField("Enter \(option)", text: Binding(
                                            get: { customizationOptions[option] ?? "" },
                                            set: { customizationOptions[option] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Quantity Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quantity")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(quantity > 1 ? .blue : .gray)
                                }
                                .disabled(quantity <= 1)
                                
                                Text("\(quantity)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 50)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: { quantity += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Subtotal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "$%.2f", totalPrice))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Bottom Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Add to Cart Button
                        Button(action: addToCart) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Add to Cart")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Quick Buy Button
                        Button(action: { showingQuickBuy = true }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Buy Now")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .alert("Add to Cart Result", isPresented: $showingAddToCartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addToCartMessage)
        }
        .sheet(isPresented: $showingQuickBuy) {
            QuickBuyView(
                product: product,
                cartService: cartService,
                isPresented: $showingQuickBuy
            )
        }
    }
    
    private func addToCart() {
        Task {
            do {
                try await cartService.addToCart(
                    product: product,
                    quantity: quantity,
                    customizationOptions: customizationOptions.isEmpty ? nil : customizationOptions
                )
                
                await MainActor.run {
                    addToCartMessage = "Product added to cart successfully"
                    showingAddToCartAlert = true
                }
            } catch {
                await MainActor.run {
                    addToCartMessage = "Failed to add: \(error.localizedDescription)"
                    showingAddToCartAlert = true
                }
            }
        }
    }
}



#Preview {
    MemorialProductsView()
        .modelContainer(for: [Product.self, Pet.self], inMemory: true)
}