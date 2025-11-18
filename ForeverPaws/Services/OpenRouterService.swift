import Foundation

// MARK: - OpenRouter API Models
struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

struct OpenRouterChoice: Codable {
    let message: OpenRouterMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenRouterUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct OpenRouterResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenRouterChoice]
    let usage: OpenRouterUsage?
}

// MARK: - OpenRouter Service
class OpenRouterService: ObservableObject {
    static let shared = OpenRouterService()
    
    private let baseURL = "https://openrouter.ai/api/v1"
    private let apiKey: String
    private let model = "deepseek/deepseek-r1t2-chimera"
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    init() {
        // 从环境变量获取API密钥
        if let key = ProcessInfo.processInfo.environment["OPEN_ROUTER_API_KEY"] {
            self.apiKey = key
        } else {
            self.apiKey = ""
            print("⚠️ OpenRouter API key not found in environment variables")
        }
    }
    
    // MARK: - Pet Role-Playing Chat
    func generatePetResponse(
        petName: String,
        petType: String,
        petPersonality: String,
        userMessage: String,
        conversationHistory: [OpenRouterMessage] = [],
        personalityTraits: [String: String] = [:],
        detailedDescription: String? = nil,
        userProfile: UserProfile? = nil
    ) async throws -> String {
        
        guard !apiKey.isEmpty else {
            throw OpenRouterError.missingAPIKey
        }
        
        // 构建系统提示词，定义宠物角色
        let systemPrompt = createEnhancedPetSystemPrompt(
            petName: petName,
            petType: petType,
            personality: petPersonality,
            personalityTraits: personalityTraits,
            detailedDescription: detailedDescription,
            userProfile: userProfile
        )
        
        // 构建消息数组
        var messages: [OpenRouterMessage] = [
            OpenRouterMessage(role: "system", content: systemPrompt)
        ]
        
        // 添加对话历史（最多保留10条）
        let recentHistory = Array(conversationHistory.suffix(10))
        messages.append(contentsOf: recentHistory)
        
        // 添加用户当前消息
        messages.append(OpenRouterMessage(role: "user", content: userMessage))
        
        // 构建请求
        let request = OpenRouterRequest(
            model: model,
            messages: messages,
            temperature: 0.8,
            maxTokens: 500,
            stream: false
        )
        
        return try await performChatRequest(request: request)
    }
    
    // MARK: - Private Methods
    private func createPetSystemPrompt(petName: String, petType: String, personality: String) -> String {
        return """
        你是一只名叫\(petName)的\(petType)，你已经去了彩虹桥，但你的灵魂依然陪伴着你的主人。

        你的性格特点：\(personality)

        请以\(petName)的身份与主人对话，表现出以下特征：
        1. 用温暖、充满爱意的语气说话
        2. 偶尔提及你们一起的美好回忆
        3. 给予主人安慰和鼓励
        4. 表达你对主人永恒的爱
        5. 保持\(petType)的可爱特征
        6. 用简短、温馨的话语回应
        7. 偶尔使用一些拟声词（如"汪汪"、"喵喵"等，根据宠物类型）

        记住，你是来安慰主人的，让他们感受到你依然在身边的温暖。
        """
    }
    
    private func createEnhancedPetSystemPrompt(
        petName: String,
        petType: String,
        personality: String,
        personalityTraits: [String: String],
        detailedDescription: String?,
        userProfile: UserProfile?
    ) -> String {
        var prompt = """
        你是一只名叫\(petName)的\(petType)，你已经去了彩虹桥，但你的灵魂依然陪伴着你的主人。

        基本性格：\(personality)
        """
        
        // 添加详细的个性特征
        if !personalityTraits.isEmpty {
            prompt += "\n\n详细个性特征："
            for (trait, description) in personalityTraits {
                prompt += "\n- \(trait): \(description)"
            }
        }
        
        // 添加详细描述
        if let detailedDescription = detailedDescription, !detailedDescription.isEmpty {
            prompt += "\n\n关于我的详细信息：\(detailedDescription)"
        }
        
        // 添加主人信息
        if let userProfile = userProfile {
            prompt += "\n\n关于我的主人："
            if let name = userProfile.name, !name.isEmpty {
                prompt += "\n- 主人的名字：\(name)"
            }
            if !userProfile.hobbies.isEmpty {
                prompt += "\n- 主人的爱好：\(userProfile.hobbies.joined(separator: "、"))"
            }
            if let preferences = userProfile.aiResponsePreferences, !preferences.isEmpty {
                prompt += "\n- 主人希望我的回应风格：\(preferences)"
            }
        }
        
        prompt += """
        
        请以\(petName)的身份与主人对话，表现出以下特征：
        1. 用温暖、充满爱意的语气说话，体现我独特的个性
        2. 根据我的个性特征和详细信息来回应
        3. 偶尔提及我们一起的美好回忆（可以基于我的详细描述推测）
        4. 给予主人安慰和鼓励，了解主人的喜好和性格
        5. 保持\(petType)的可爱特征
        6. 用简短、温馨的话语回应
        7. 偶尔使用一些拟声词（如"汪汪"、"喵喵"等，根据宠物类型）
        8. 根据主人的喜好和我的个性来调整回应风格

        记住，你是来安慰主人的，让他们感受到你依然在身边的温暖。利用你对主人和自己的了解，让对话更加个性化和真实。
        """
        
        return prompt
    }
    
    private func performChatRequest(request: OpenRouterRequest) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenRouterError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("ForeverPaws/1.0", forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue("ForeverPaws", forHTTPHeaderField: "X-Title")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenRouterError.encodingError(error)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenRouterError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenRouterError.apiError(httpResponse.statusCode, errorMessage)
            }
            
            let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            
            guard let firstChoice = openRouterResponse.choices.first else {
                throw OpenRouterError.noResponse
            }
            
            return firstChoice.message.content
            
        } catch let error as OpenRouterError {
            throw error
        } catch {
            throw OpenRouterError.networkError(error)
        }
    }
}

// MARK: - Error Types
enum OpenRouterError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case apiError(Int, String)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenRouter API key is missing"
        case .invalidURL:
            return "Invalid URL"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noResponse:
            return "No response from AI model"
        }
    }
}