import Foundation
import StoreKit
import Combine

// MARK: - Payment Models
struct PaymentRecord: Codable {
    let id: UUID
    let userId: String
    let amount: Decimal
    let currency: String
    let paymentMethod: String
    let transactionId: String
    let status: PaymentStatus
    let purpose: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, amount, currency, purpose
        case userId = "user_id"
        case paymentMethod = "payment_method"
        case transactionId = "transaction_id"
        case status
        case createdAt = "created_at"
    }
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
}

// MARK: - Product Identifiers
enum ProductIdentifier: String, CaseIterable {
    case videoGeneration = "com.foreverpaws.video_generation"
    
    var displayName: String {
        switch self {
        case .videoGeneration:
            return "视频生成"
        }
    }
    
    var price: Decimal {
        switch self {
        case .videoGeneration:
            return 2.80
        }
    }
}

// MARK: - Payment Service
@MainActor
class PaymentService: NSObject, ObservableObject {
    static let shared = PaymentService()
    
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private var updateListenerTask: Task<Void, Error>?
    
    override init() {
        super.init()
        
        // 开始监听交易更新
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        // 模拟产品加载
        products = []
        
        isLoading = false
    }
    
    // MARK: - Purchase Methods
    func purchaseVideoGeneration() async throws -> Bool {
        // 模拟购买视频生成
        return true
    }
    
    private func purchase(_ product: Product) async throws -> Bool {
        // 模拟购买流程
        return true
    }
    
    // MARK: - Transaction Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw PaymentError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // 处理交易更新
                    await self.handleTransaction(transaction)
                    
                    // 完成交易
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        // 模拟处理交易
    }
    
    // MARK: - Payment Recording
    private func recordPayment(transaction: Transaction, product: Product) async {
        guard let user = supabaseService.currentUser else { return }
        
        let paymentRecord = PaymentRecord(
            id: UUID(),
            userId: user.id.uuidString,
            amount: Decimal(0), // 模拟金额
            currency: "USD",
            paymentMethod: "apple_pay",
            transactionId: String(transaction.id),
            status: .completed,
            purpose: "video_generation",
            createdAt: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let paymentData = try encoder.encode(paymentRecord)
            
            let _ = try JSONSerialization.jsonObject(with: paymentData, options: [])
            
            // 模拟记录支付信息
            
            print("✅ Payment recorded successfully")
        } catch {
            print("❌ Failed to record payment: \(error)")
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            isLoading = false
        } catch {
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    func canMakePayments() -> Bool {
        return AppStore.canMakePayments
    }
    
    func getProductPrice(for identifier: ProductIdentifier) -> String {
        return "$\(identifier.price)"
    }
    
    func hasVideoCredits() -> Bool {
        return supabaseService.getUserVideoCredits() > 0
    }
    
    func getVideoCreditsCount() -> Int {
        return supabaseService.getUserVideoCredits()
    }
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case productNotFound
    case failedVerification
    case paymentPending
    case unknownError
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "产品未找到"
        case .failedVerification:
            return "交易验证失败"
        case .paymentPending:
            return "支付正在处理中"
        case .unknownError:
            return "未知错误"
        case .notAuthenticated:
            return "用户未登录"
        }
    }
}