import Foundation
import SwiftData
import Combine

@MainActor
class CartService: ObservableObject {
    static let shared = CartService()
    
    private var modelContext: ModelContext?
    
    @Published var cartItems: [CartItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("🔧 [CartService] ModelContext set, loading cart items...")
        loadCartItems()
    }
    
    // MARK: - Cart Management
    
    func loadCartItems() {
        guard let context = modelContext else { 
            print("❌ loadCartItems: ModelContext is nil")
            return 
        }
        
        // 获取当前用户ID
        guard let currentUser = SupabaseService.shared.currentUser else {
            print("❌ loadCartItems: No authenticated user")
            cartItems = []
            return
        }
        
        let currentUserId = currentUser.id.uuidString
        print("🔍 loadCartItems: Starting to fetch cart items for user: \(currentUserId)")
        print("🔍 ModelContext info: \(context)")
        
        // 添加用户ID过滤条件
        let descriptor = FetchDescriptor<CartItem>(
            predicate: #Predicate<CartItem> { item in
                item.userId == currentUserId
            },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        
        do {
            let fetchedItems = try context.fetch(descriptor)
            print("📦 loadCartItems: Fetched \(fetchedItems.count) items from database for user: \(currentUserId)")
            
            // 验证每个获取的项目
            for (index, item) in fetchedItems.enumerated() {
                print("   Item \(index + 1): \(item.productName) x\(item.quantity) (ID: \(item.id), UserID: \(item.userId), Added: \(item.addedAt))")
            }
            
            // 直接更新UI（已经在MainActor上下文中）
            cartItems = fetchedItems
            print("📦 loadCartItems: Updated cartItems array with \(fetchedItems.count) items")
            
            // 验证数据库中的所有CartItem（用于调试）
            let allItemsDescriptor = FetchDescriptor<CartItem>()
            let allItems = try context.fetch(allItemsDescriptor)
            print("🔍 Total CartItems in database: \(allItems.count)")
            print("🔍 Current user's CartItems: \(fetchedItems.count)")
            
            objectWillChange.send()
        } catch {
            errorMessage = "Failed to load cart items: \(error.localizedDescription)"
            print("❌ loadCartItems error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func getCartItems() -> [CartItem] {
        return cartItems
    }
    
    func addToCart(product: Product, quantity: Int, customizationOptions: [String: String]?) async throws {
        guard let context = modelContext else {
            throw CartError.contextNotSet
        }
        
        guard quantity > 0 else {
            throw CartError.invalidQuantity
        }
        
        isLoading = true
        defer { isLoading = false }
        
        print("🛒 Adding to cart: \(product.name), quantity: \(quantity)")
        print("🔍 Current cart items count before adding: \(cartItems.count)")
        
        // 先重新加载最新数据以确保同步
        loadCartItems()
        
        // Check if item already exists in cart
        if let existingItem = cartItems.first(where: { $0.productId == product.id }) {
            print("🔄 Updating existing item quantity from \(existingItem.quantity) to \(existingItem.quantity + quantity)")
            existingItem.quantity += quantity
            if let options = customizationOptions {
                existingItem.customizationOptions = options
            }
            
            // Save the updated item
            do {
                try context.save()
                print("✅ Updated existing item saved successfully")
                print("💾 Context save completed for existing item")
            } catch {
                print("❌ Failed to save updated item: \(error)")
                throw CartError.saveFailed(error.localizedDescription)
            }
        } else {
            // 获取当前用户ID
            guard let currentUser = SupabaseService.shared.currentUser else {
                throw CartError.saveFailed("No authenticated user")
            }
            
            print("➕ Creating new cart item for user: \(currentUser.id.uuidString)")
            let cartItem = CartItem(
                userId: currentUser.id.uuidString,
                productId: product.id,
                productName: product.name,
                productPrice: product.price,
                productImageURL: product.imageURL?.absoluteString,
                quantity: quantity,
                customizationOptions: customizationOptions
            )
            
            print("📝 Inserting new item into context: \(cartItem.id)")
            context.insert(cartItem)
            
            // 立即添加到本地数组以确保UI更新
            cartItems.append(cartItem)
            
            // Save the new item immediately
            do {
                print("💾 Attempting to save context...")
                print("🔍 Context has changes: \(context.hasChanges)")
                
                try context.save()
                print("✅ New cart item saved successfully to persistent storage")
                print("💾 Context save completed for new item")
                
                // 验证保存是否成功
                let verifyDescriptor = FetchDescriptor<CartItem>()
                let allItems = try context.fetch(verifyDescriptor)
                let savedItem = allItems.first { $0.id == cartItem.id }
                if let savedItem = savedItem {
                    print("🔍 Verification: Successfully found saved item with ID \(savedItem.id)")
                    print("🔍 Saved item details: \(savedItem.productName) x\(savedItem.quantity) at \(savedItem.addedAt)")
                } else {
                    print("⚠️ Verification: Could not find saved item with ID \(cartItem.id)")
                    print("⚠️ Available items in database:")
                    for (index, item) in allItems.enumerated() {
                        print("   \(index + 1). \(item.productName) (ID: \(item.id))")
                    }
                }
                print("🔍 Total items in database: \(allItems.count)")
                
            } catch {
                print("❌ Failed to save new cart item: \(error)")
                print("🔍 Save error details: \(error.localizedDescription)")
                print("🔍 Error type: \(type(of: error))")
                // 如果保存失败，从本地数组中移除
                if let index = cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    cartItems.remove(at: index)
                }
                throw CartError.saveFailed(error.localizedDescription)
            }
        }
        
        // Reload to ensure UI is updated with fresh data from database
        print("🔄 Reloading cart items from database...")
        loadCartItems()
        
        print("📊 Final cart items count: \(cartItems.count)")
        print("🛒 Current cart contents:")
        for (index, item) in cartItems.enumerated() {
            print("   \(index + 1). \(item.productName) x\(item.quantity) = $\(item.totalPrice) (ID: \(item.id))")
        }
        
        // Force UI update by triggering objectWillChange
        objectWillChange.send()
    }
    
    func removeFromCart(item: CartItem) async throws {
        guard let context = modelContext else {
            throw CartError.contextNotSet
        }
        
        context.delete(item)
        
        do {
            try context.save()
            loadCartItems()
        } catch {
            throw CartError.deleteFailed(error.localizedDescription)
        }
    }
    
    func updateQuantity(for item: CartItem, quantity: Int) async throws {
        guard let context = modelContext else {
            throw CartError.contextNotSet
        }
        
        guard quantity > 0 else {
            try await removeFromCart(item: item)
            return
        }
        
        item.quantity = quantity
        
        do {
            try context.save()
            loadCartItems()
        } catch {
            throw CartError.updateFailed(error.localizedDescription)
        }
    }
    
    func clearCart() async throws {
        guard let context = modelContext else {
            throw CartError.contextNotSet
        }
        
        // 获取当前用户ID
        guard let currentUser = SupabaseService.shared.currentUser else {
            throw CartError.clearFailed("No authenticated user")
        }
        
        let currentUserId = currentUser.id.uuidString
        print("🗑️ Clearing cart for user: \(currentUserId)")
        
        // 只删除当前用户的购物车项目
        let descriptor = FetchDescriptor<CartItem>(
            predicate: #Predicate<CartItem> { item in
                item.userId == currentUserId
            }
        )
        
        do {
            let userCartItems = try context.fetch(descriptor)
            for item in userCartItems {
                context.delete(item)
            }
            
            try context.save()
            loadCartItems()
            print("✅ Cart cleared successfully for user: \(currentUserId)")
        } catch {
            throw CartError.clearFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Cart Information
    
    func getTotalItemCount() -> Int {
        return cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    func getTotalPrice() -> Double {
        return cartItems.reduce(0) { $0 + ($1.productPrice * Double($1.quantity)) }
    }
    
    func isEmpty() -> Bool {
        return cartItems.isEmpty
    }
    
    func getFormattedTotalPrice() -> String {
        return String(format: "$%.2f", getTotalPrice())
    }
    
    // MARK: - Checkout
    
    func checkout(
        customerName: String,
        customerEmail: String,
        customerPhone: String,
        shippingAddress: String
    ) async throws -> CheckoutResult {
        guard let context = modelContext else {
            throw CartError.contextNotSet
        }
        
        // 确保在主线程上重新加载购物车数据
        await MainActor.run {
            loadCartItems()
        }
        
        // 等待一小段时间确保数据加载完成
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        print("🛒 Checkout: Cart items count: \(cartItems.count)")
        print("🛒 Checkout: Cart contents:")
        for (index, item) in cartItems.enumerated() {
            print("   \(index + 1). \(item.productName) x\(item.quantity) = $\(item.totalPrice)")
        }
        
        // 再次检查购物车是否为空，如果为空则重新加载一次
        if cartItems.isEmpty {
            print("⚠️ Cart appears empty, attempting to reload...")
            await MainActor.run {
                loadCartItems()
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            print("🛒 After reload: Cart items count: \(cartItems.count)")
        }
        
        guard !cartItems.isEmpty else {
            print("❌ Checkout failed: Cart is empty after reload")
            throw CartError.emptyCart
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create order using OrderService
        let orderService = OrderService()
        orderService.setModelContext(context)
        
        do {
            let order = try await orderService.createOrder(
                customerName: customerName,
                customerEmail: customerEmail,
                customerPhone: customerPhone,
                shippingAddress: shippingAddress,
                cartItems: cartItems
            )
            
            // Clear cart after successful order creation
            try await clearCart()
            
            return CheckoutResult(
                success: true,
                orderNumber: order.orderNumber,
                totalAmount: order.totalAmount,
                message: "Order created successfully! Order number: \(order.orderNumber)"
            )
        } catch {
            throw CartError.checkoutFailed(error.localizedDescription)
        }
    }
}

@Model
class CartItem {
    var id: UUID
    var userId: String // 添加用户ID字段，确保购物车数据隔离
    var productId: UUID
    var productName: String
    var productPrice: Double
    var productImageURL: String?
    var quantity: Int
    var customizationOptions: [String: String]?
    var addedAt: Date
    
    init(
        userId: String,
        productId: UUID,
        productName: String,
        productPrice: Double,
        productImageURL: String? = nil,
        quantity: Int = 1,
        customizationOptions: [String: String]? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.productId = productId
        self.productName = productName
        self.productPrice = productPrice
        self.productImageURL = productImageURL
        self.quantity = quantity
        self.customizationOptions = customizationOptions
        self.addedAt = Date()
    }
    
    var totalPrice: Double {
        return productPrice * Double(quantity)
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", productPrice)
    }
    
    var formattedTotalPrice: String {
        return String(format: "$%.2f", totalPrice)
    }
}

// MARK: - Checkout Result
struct CheckoutResult {
    let success: Bool
    let orderNumber: String
    let totalAmount: Double
    let message: String
}

// MARK: - Cart Errors
enum CartError: LocalizedError {
    case contextNotSet
    case invalidQuantity
    case emptyCart
    case saveFailed(String)
    case deleteFailed(String)
    case updateFailed(String)
    case clearFailed(String)
    case checkoutFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .contextNotSet:
            return "Database context not set"
        case .invalidQuantity:
            return "Invalid product quantity"
        case .emptyCart:
            return "Cart is empty"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .clearFailed(let message):
            return "Clear cart failed: \(message)"
        case .checkoutFailed(let message):
            return "Checkout failed: \(message)"
        }
    }
}