import SwiftUI

struct HotProductCard: View {
    let product: Product
    @ObservedObject var cartService: CartService
    @State private var showingAddToCartAlert = false
    @State private var addToCartMessage = ""
    @State private var showingQuickBuy = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                // Product Name
                Text(product.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Product Description
                Text(product.productDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Price and Customization Indicator
                HStack {
                    Text(String(format: "$%.0f", product.price))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if product.hasCustomization {
                        Image(systemName: "paintbrush.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 8) {
                    // Add to Cart Button
                    Button(action: addToCart) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption)
                            Text("Add to Cart")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Quick Buy Button
                    Button(action: { showingQuickBuy = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                            Text("Buy Now")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        print("🎯 HotProductCard addToCart button clicked for product: \(product.name)")
        print("🔍 CartService instance: \(cartService)")
        
        Task {
            do {
                print("🛒 HotProductCard: Adding product to cart: \(product.name)")
                
                try await cartService.addToCart(
                    product: product,
                    quantity: 1,
                    customizationOptions: nil
                )
                
                print("✅ HotProductCard: Product added to cart successfully")
                
                await MainActor.run {
                    addToCartMessage = "Product added to cart successfully"
                    showingAddToCartAlert = true
                }
            } catch {
                print("❌ HotProductCard: Failed to add product to cart: \(error)")
                await MainActor.run {
                    addToCartMessage = "Failed to add: \(error.localizedDescription)"
                    showingAddToCartAlert = true
                }
            }
        }
    }
}

#Preview {
    HotProductCard(
        product: Product(
            name: "定制宠物相框",
            description: "精美的宠物纪念相框，可定制文字和图片，永久保存美好回忆",
            price: 199.0,
            category: .frames,
            imageURL: URL(string: "https://example.com/frame.jpg"),
            customizationOptions: try? JSONEncoder().encode(["文字": "请输入纪念文字", "尺寸": "请选择尺寸"])
        ),
        cartService: CartService.shared
    )
    .padding()
}