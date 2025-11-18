import SwiftUI
import SwiftData

struct CartView: View {
    @ObservedObject var cartService: CartService
    @Environment(\.dismiss) private var dismiss
    @State private var isCheckingOut = false
    @State private var showingCheckoutResult = false
    @State private var checkoutResult: CheckoutResult?
    
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
                
                if cartService.isEmpty() {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !cartService.isEmpty() {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            clearCart()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Checkout Result", isPresented: $showingCheckoutResult) {
            Button("OK", role: .cancel) {
                if checkoutResult?.success == true {
                    dismiss()
                }
            }
        } message: {
            if let result = checkoutResult {
                VStack(alignment: .leading, spacing: 4) {
                    if result.success {
                        Text("Order Number: \(result.orderNumber)")
                        Text("Total Amount: $\(String(format: "%.2f", result.totalAmount))")
                    }
                    Text(result.message)
                }
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.6), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Your cart is empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start shopping for keepsakes")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                dismiss()
            }) {
                Text("Start Shopping")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
            }
        }
    }
    
    private var cartContentView: some View {
        VStack(spacing: 0) {
            // 购物车商品列表
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cartService.getCartItems(), id: \.id) { item in
                        CartItemRow(
                            item: item,
                            onQuantityChange: { newQuantity in
                                updateQuantity(for: item, quantity: newQuantity)
                            },
                            onRemove: {
                                removeItem(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            // 底部结算区域
            VStack(spacing: 16) {
                // 总价信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total \(cartService.getTotalItemCount()) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Total: \(cartService.getFormattedTotalPrice())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Spacer()
                }
                
                // 结算按钮
                Button(action: checkout) {
                    HStack {
                        if isCheckingOut {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        Text(isCheckingOut ? "Processing..." : "Checkout Now")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .disabled(isCheckingOut)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
        }
    }
    
    // MARK: - Actions
    
    private func updateQuantity(for item: CartItem, quantity: Int) {
        Task {
            do {
                try await cartService.updateQuantity(for: item, quantity: quantity)
            } catch {
                print("Failed to update quantity: \(error)")
            }
        }
    }
    
    private func removeItem(_ item: CartItem) {
        Task {
            do {
                try await cartService.removeFromCart(item: item)
            } catch {
                print("Failed to remove item: \(error)")
            }
        }
    }
    
    private func clearCart() {
        Task {
            do {
                try await cartService.clearCart()
            } catch {
                print("Failed to clear cart: \(error)")
            }
        }
    }
    
    private func checkout() {
        isCheckingOut = true
        
        Task {
            do {
                let result = try await cartService.checkout(
                    customerName: "Test User",
                    customerEmail: "test@example.com",
                    customerPhone: "13800138000",
                    shippingAddress: "Test Address"
                )
                
                await MainActor.run {
                    checkoutResult = result
                    showingCheckoutResult = true
                    isCheckingOut = false
                }
            } catch {
                await MainActor.run {
                    checkoutResult = CheckoutResult(
                        success: false,
                        orderNumber: "",
                        totalAmount: 0,
                        message: "Checkout failed: \(error.localizedDescription)"
                    )
                    showingCheckoutResult = true
                    isCheckingOut = false
                }
            }
        }
    }
}

struct CheckoutView: View {
    @ObservedObject var cartService: CartService
    @Binding var isPresented: Bool
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var customerPhone = ""
    @State private var whatsappNumber = ""
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "United States"
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var checkoutResult: CheckoutResult?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Order Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(cartService.cartItems, id: \.id) { item in
                            HStack {
                                AsyncImage(url: URL(string: item.productImageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.productName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text("Quantity: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(item.formattedTotalPrice)
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text(String(format: "$%.2f", cartService.getTotalPrice()))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Customer Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Shipping Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            TextField("Full Name", text: $customerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Email Address", text: $customerEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                            
                            TextField("Phone Number", text: $customerPhone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            TextField("WhatsApp Number (Optional, for custom items communication)", text: $whatsappNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            // US Standard Address Format
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Shipping Address")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("Street Address", text: $streetAddress)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                HStack(spacing: 12) {
                                    TextField("City", text: $city)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    TextField("State", text: $state)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: 80)
                                }
                                
                                HStack(spacing: 12) {
                                    TextField("ZIP Code", text: $zipCode)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .frame(maxWidth: 120)
                                    
                                    TextField("Country", text: $country)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Checkout Button
                    Button(action: processCheckout) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isProcessing ? "Processing..." : "Place Order")
                                .font(.headline)
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
                    .disabled(isProcessing || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("Order Result", isPresented: $showingResult) {
            Button("OK") {
                if checkoutResult?.success == true {
                    isPresented = false
                }
            }
        } message: {
            Text(checkoutResult?.message ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !customerName.isEmpty &&
        !customerEmail.isEmpty &&
        !customerPhone.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty &&
        !country.isEmpty
    }
    
    private func processCheckout() {
        guard isFormValid else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Build complete shipping address
                let fullAddress = "\(streetAddress), \(city), \(state) \(zipCode), \(country)"
                
                let result = try await cartService.checkout(
                    customerName: customerName,
                    customerEmail: customerEmail,
                    customerPhone: customerPhone,
                    shippingAddress: fullAddress
                )
                
                await MainActor.run {
                    checkoutResult = result
                    showingResult = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    checkoutResult = CheckoutResult(
                        success: false,
                        orderNumber: "",
                        totalAmount: 0,
                        message: "Order failed: \(error.localizedDescription)"
                    )
                    showingResult = true
                    isProcessing = false
                }
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 商品图片
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                if let imageURLString = item.productImageURL,
                   let imageURL = URL(string: imageURLString) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            
            // 商品信息
            VStack(alignment: .leading, spacing: 8) {
                Text(item.productName)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                Text(item.formattedPrice)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // 定制选项
                if let customizations = item.customizationOptions, !customizations.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(customizations.keys.sorted()), id: \.self) { key in
                            if let value = customizations[key], !value.isEmpty {
                                Text("\(key): \(value)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // 数量控制和删除
            VStack(spacing: 12) {
                // 删除按钮
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // 数量控制
                HStack(spacing: 8) {
                    Button(action: {
                        if item.quantity > 1 {
                            onQuantityChange(item.quantity - 1)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(item.quantity > 1 ? .primary : .secondary)
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(minWidth: 24)
                    
                    Button(action: {
                        onQuantityChange(item.quantity + 1)
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
                
                // 小计
                Text(item.formattedTotalPrice)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CartView(cartService: CartService.shared)
}