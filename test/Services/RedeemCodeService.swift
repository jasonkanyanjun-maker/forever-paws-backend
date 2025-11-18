import Foundation
import Combine

// MARK: - Redeem Code Models
struct RedeemCode: Codable, Identifiable {
    let id: UUID
    let code: String
    let description: String
    let videoCredits: Int
    let maxUses: Int
    let currentUses: Int
    let isActive: Bool
    let expiresAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, code, description, isActive
        case videoCredits = "video_credits"
        case maxUses = "max_uses"
        case currentUses = "current_uses"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
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
}

struct RedeemCodeUsage: Codable {
    let id: UUID
    let redeemCodeId: UUID
    let userId: String
    let usedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case redeemCodeId = "redeem_code_id"
        case userId = "user_id"
        case usedAt = "used_at"
    }
}

// MARK: - Redeem Code Service
@MainActor
class RedeemCodeService: ObservableObject {
    static let shared = RedeemCodeService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Redeem Code Validation
    func validateAndRedeemCode(_ code: String) async throws -> Bool {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RedeemCodeError.invalidCode
        }
        
        guard let user = supabaseService.currentUser else {
            throw RedeemCodeError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // 1. 查找兑换码
            let redeemCode = try await fetchRedeemCode(code.uppercased())
            
            // 2. 验证兑换码
            try validateRedeemCode(redeemCode)
            
            // 3. 检查用户是否已使用过此兑换码
            let hasUsed = try await checkIfUserHasUsedCode(redeemCode.id, userId: user.id.uuidString)
            if hasUsed {
                throw RedeemCodeError.alreadyUsed
            }
            
            // 4. 记录使用
            try await recordCodeUsage(redeemCode.id, userId: user.id.uuidString)
            
            // 5. 给用户添加视频额度
            try await supabaseService.addVideoCredits(redeemCode.videoCredits)
            
            // 6. 更新兑换码使用次数
            try await updateCodeUsageCount(redeemCode.id)
            
            successMessage = "兑换成功！获得 \(redeemCode.videoCredits) 个视频生成额度"
            isLoading = false
            return true
            
        } catch {
            isLoading = false
            if let redeemError = error as? RedeemCodeError {
                errorMessage = redeemError.localizedDescription
            } else {
                errorMessage = "兑换失败: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func fetchRedeemCode(_ code: String) async throws -> RedeemCode {
        // 模拟兑换码查找
        throw RedeemCodeError.codeNotFound
    }
    
    private func validateRedeemCode(_ redeemCode: RedeemCode) throws {
        if !redeemCode.isActive {
            throw RedeemCodeError.codeInactive
        }
        
        if redeemCode.isExpired {
            throw RedeemCodeError.codeExpired
        }
        
        if redeemCode.currentUses >= redeemCode.maxUses {
            throw RedeemCodeError.codeExhausted
        }
    }
    
    private func checkIfUserHasUsedCode(_ codeId: UUID, userId: String) async throws -> Bool {
        // 模拟检查用户是否已使用过兑换码
        return false
    }
    
    private func recordCodeUsage(_ codeId: UUID, userId: String) async throws {
        // 模拟记录兑换码使用
    }
    
    private func updateCodeUsageCount(_ codeId: UUID) async throws {
        // 模拟更新兑换码使用次数
    }
    
    // MARK: - Public Methods
    func redeemCode(_ code: String) async throws -> Bool {
        return try await validateAndRedeemCode(code)
    }
    
    // MARK: - Public Helper Methods
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func getAvailableCodes() async throws -> [RedeemCode] {
        // 模拟获取可用兑换码
        return []
    }
    
    func getUserRedeemHistory() async throws -> [RedeemCodeUsage] {
        guard supabaseService.currentUser != nil else {
            throw RedeemCodeError.notAuthenticated
        }
        
        // 模拟获取用户兑换历史
        return []
    }
}

// MARK: - Redeem Code Errors
enum RedeemCodeError: LocalizedError {
    case invalidCode
    case codeNotFound
    case codeInactive
    case codeExpired
    case codeExhausted
    case alreadyUsed
    case notAuthenticated
    case recordingFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "兑换码格式无效"
        case .codeNotFound:
            return "兑换码不存在"
        case .codeInactive:
            return "兑换码已停用"
        case .codeExpired:
            return "兑换码已过期"
        case .codeExhausted:
            return "兑换码使用次数已达上限"
        case .alreadyUsed:
            return "您已使用过此兑换码"
        case .notAuthenticated:
            return "请先登录"
        case .recordingFailed:
            return "记录兑换失败"
        case .updateFailed:
            return "更新兑换码状态失败"
        }
    }
}

// MARK: - Redeem Code Extensions
extension RedeemCode {
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
    
    var statusColor: String {
        if !isActive || isExpired || currentUses >= maxUses {
            return "red"
        } else {
            return "green"
        }
    }
}