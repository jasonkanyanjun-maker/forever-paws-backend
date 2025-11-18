import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String?
    var avatarUrl: String?
    var hobbies: [String]
    var preferences: [String: String]
    var aiResponsePreferences: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case avatarUrl = "avatar_url"
        case hobbies
        case preferences
        case aiResponsePreferences = "ai_response_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, name: String? = nil, avatarUrl: String? = nil, hobbies: [String] = [], preferences: [String: String] = [:], aiResponsePreferences: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.avatarUrl = avatarUrl
        self.hobbies = hobbies
        self.preferences = preferences
        self.aiResponsePreferences = aiResponsePreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}