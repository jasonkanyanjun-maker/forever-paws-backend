import SwiftUI

struct QuickBuyView: View {
    let product: Product
    @ObservedObject var cartService: CartService
    @Binding var isPresented: Bool
    
    @State private var quantity = 1
    @State private var customizationOptions: [String: String] = [:]
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
    @State private var purchaseResult: CheckoutResult?
    
    var totalPrice: Double {
        product.price * Double(quantity)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Product Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Product Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            AsyncImage(url: product.imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(product.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(product.productDescription ?? "")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Text(String(format: "$%.2f", product.price))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Quantity and Customization
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Purchase Options")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Quantity Selector
                        HStack {
                            Text("Quantity")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(quantity > 1 ? .blue : .gray)
                                }
                                .disabled(quantity <= 1)
                                
                                Text("\(quantity)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 30)
                                
                                Button(action: { quantity += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // Customization Options (if available)
                        if let customizationData = product.customizationOptions,
                           let decodedOptions = try? JSONDecoder().decode([String].self, from: customizationData),
                           !decodedOptions.isEmpty {
                            Divider()
                            
                            Text("Customization Options")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            ForEach(decodedOptions.sorted(), id: \.self) { option in
                                HStack {
                                    Text(option)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    TextField("Enter \(option)", text: Binding(
                                        get: { customizationOptions[option] ?? "" },
                                        set: { customizationOptions[option] = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 150)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Total Price
                        HStack {
                            Text("Subtotal")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text(String(format: "$%.2f", totalPrice))
                                .font(.title2)
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
                    
                    // Purchase Button
                    Button(action: processPurchase) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isProcessing ? "Processing..." : "Buy Now")
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
            .navigationTitle("Quick Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("Purchase Result", isPresented: $showingResult) {
            Button("OK") {
                if purchaseResult?.success == true {
                    isPresented = false
                }
            }
        } message: {
            Text(purchaseResult?.message ?? "")
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
    
    private func processPurchase() {
        guard isFormValid else { return }
        
        isProcessing = true
        
        // Build complete shipping address
        let fullAddress = "\(streetAddress), \(city), \(state) \(zipCode), \(country)"
        
        Task {
            do {
                print("🛒 QuickBuy: Starting purchase process")
                print("🛒 QuickBuy: Product: \(product.name), Quantity: \(quantity)")
                
                // First add to cart
                try await cartService.addToCart(
                    product: product,
                    quantity: quantity,
                    customizationOptions: customizationOptions.isEmpty ? nil : customizationOptions
                )
                
                print("🛒 QuickBuy: Item added to cart successfully")
                
                // Wait a moment to ensure the cart is updated
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                print("🛒 QuickBuy: Starting checkout process")
                
                // Then checkout immediately
                let result = try await cartService.checkout(
                    customerName: customerName,
                    customerEmail: customerEmail,
                    customerPhone: customerPhone,
                    shippingAddress: fullAddress
                )
                
                print("🛒 QuickBuy: Checkout completed successfully")
                
                await MainActor.run {
                    purchaseResult = result
                    showingResult = true
                    isProcessing = false
                }
            } catch {
                print("❌ QuickBuy: Purchase failed with error: \(error)")
                await MainActor.run {
                    purchaseResult = CheckoutResult(
                        success: false,
                        orderNumber: "",
                        totalAmount: 0,
                        message: "Purchase failed: \(error.localizedDescription)"
                    )
                    showingResult = true
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    QuickBuyView(
        product: Product(
            name: "Custom Pet Frame",
            description: "Beautiful pet memorial frame, customizable with text and images",
            price: 199.0,
            category: .frames,
            imageURL: URL(string: "https://example.com/frame.jpg"),
            customizationOptions: try? JSONEncoder().encode(["Text": "Enter memorial text", "Size": "Select size"])
        ),
        cartService: CartService.shared,
        isPresented: .constant(true)
    )
}