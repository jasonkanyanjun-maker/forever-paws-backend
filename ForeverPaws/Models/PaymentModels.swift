import Foundation
import SwiftData

// MARK: - Payment Record Model
@Model
final class PaymentRecord {
    @Attribute(.unique) var id: UUID
    var userId: String
    var amount: Double
    var currency: String
    var paymentMethod: String
    var transactionId: String
    var status: PaymentStatus
    var purpose: String
    var createdAt: Date
    
    init(userId: String, amount: Double, currency: String = "USD", paymentMethod: String, transactionId: String, status: PaymentStatus = .pending, purpose: String) {
        self.id = UUID()
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.transactionId = transactionId
        self.status = status
        self.purpose = purpose
        self.createdAt = Date()
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: createdAt)
    }
}

// MARK: - Redeem Code Model
@Model
final class RedeemCode {
    @Attribute(.unique) var id: UUID
    var code: String
    var description: String
    var videoCredits: Int
    var maxUses: Int
    var currentUses: Int
    var isActive: Bool
    var expiresAt: Date?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var usages: [RedeemCodeUsage] = []
    
    init(code: String, description: String, videoCredits: Int, maxUses: Int, isActive: Bool = true, expiresAt: Date? = nil) {
        self.id = UUID()
        self.code = code.uppercased()
        self.description = description
        self.videoCredits = videoCredits
        self.maxUses = maxUses
        self.currentUses = 0
        self.isActive = isActive
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var isAvailable: Bool {
        return isActive && !isExpired && currentUses < maxUses
    }
    
    var remainingUses: Int {
        return max(0, maxUses - currentUses)
    }
    
    var formattedExpiryDate: String {
        guard let expiresAt = expiresAt else { return "永不过期" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        
        return formatter.string(from: expiresAt)
    }
    
    var statusText: String {
        if !isActive {
            return "已停用"
        } else if isExpired {
            return "已过期"
        } else if currentUses >= maxUses {
            return "已用完"
        } else {
            return "可用"
        }
    }
}

// MARK: - Redeem Code Usage Model
@Model
final class RedeemCodeUsage {
    @Attribute(.unique) var id: UUID
    var redeemCodeId: UUID
    var userId: String
    var usedAt: Date
    
    @Relationship(inverse: \RedeemCode.usages) var redeemCode: RedeemCode?
    
    init(redeemCodeId: UUID, userId: String) {
        self.id = UUID()
        self.redeemCodeId = redeemCodeId
        self.userId = userId
        self.usedAt = Date()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: usedAt)
    }
}

// MARK: - Payment Status Enum
enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "待处理"
        case .completed:
            return "已完成"
        case .failed:
            return "失败"
        case .refunded:
            return "已退款"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .completed:
            return "green"
        case .failed:
            return "red"
        case .refunded:
            return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        case .refunded:
            return "arrow.counterclockwise.circle"
        }
    }
}