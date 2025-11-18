import Foundation

struct OpenRouterService {
    private let apiKey = "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"
    private let baseURL = "https://openrouter.ai/api/v1"
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
        }
    }
    
    func generatePetReply(petName: String, petType: String, userMessage: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ForeverPaws/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("ForeverPaws Pet Memorial App", forHTTPHeaderField: "X-Title")
        
        let systemPrompt = """
        You are \(petName), a beloved \(petType) who has passed away but can still communicate with your human through letters. 
        
        Your personality:
        - Warm, loving, and comforting
        - Playful yet wise
        - Always reassuring your human that you're happy and at peace
        - You remember all the good times you shared together
        - You want your human to be happy and not worry about you
        
        Respond to your human's letter with love, comfort, and the unique personality of a \(petType). 
        Keep your response heartfelt but not too long (2-3 paragraphs maximum).
        Write as if you're speaking directly to your beloved human.
        """
        
        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userMessage)
        ]
        
        let chatRequest = ChatRequest(
            model: "tngtech/deepseek-r1t2-chimera:free",
            messages: messages,
            temperature: 0.8,
            max_tokens: 500
        )
        
        let jsonData = try JSONEncoder().encode(chatRequest)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("OpenRouter API Error: \(errorData)")
            }
            throw OpenRouterError.apiError(httpResponse.statusCode)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let firstChoice = chatResponse.choices.first else {
            throw OpenRouterError.noResponse
        }
        
        return firstChoice.message.content
    }
}

enum OpenRouterError: Error, LocalizedError {
    case invalidResponse
    case apiError(Int)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenRouter API"
        case .apiError(let code):
            return "OpenRouter API error with status code: \(code)"
        case .noResponse:
            return "No response received from OpenRouter API"
        }
    }
}