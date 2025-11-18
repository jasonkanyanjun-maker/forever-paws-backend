import Foundation
import SwiftData

// MARK: - Chat Service
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    private let openRouterService = OpenRouterService.shared
    private let supabaseService = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Session Management
    func createChatSession(
        for pet: Pet,
        sessionName: String? = nil,
        modelContext: ModelContext
    ) -> ChatSession {
        let name = sessionName ?? "与\(pet.name)的对话"
        let session = ChatSession(
            userId: supabaseService.currentUser?.id.uuidString ?? "",
            petId: pet.id,
            sessionName: name
        )
        
        modelContext.insert(session)
        
        // 同步到Supabase
        Task {
            await syncSessionToSupabase(session)
        }
        
        return session
    }
    
    func getChatSessions(for pet: Pet, modelContext: ModelContext) -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { session in
                session.petId == pet.id
            },
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching chat sessions: \(error)")
            return []
        }
    }
    
    // MARK: - Message Management
    func sendMessage(
        to session: ChatSession,
        content: String,
        pet: Pet,
        modelContext: ModelContext
    ) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 创建用户消息
        let userMessage = ChatMessage(
            sessionId: session.id,
            role: "user",
            content: content
        )
        
        await MainActor.run {
            modelContext.insert(userMessage)
            session.messages.append(userMessage)
            session.lastMessageAt = Date()
        }
        
        // 同步用户消息到Supabase
        await syncMessageToSupabase(userMessage)
        
        do {
            // 获取对话历史
            let conversationHistory = getConversationHistory(for: session)
            
            // 获取用户资料以增强AI上下文
            let userProfileService = UserProfileService()
            let userProfile = await userProfileService.getOrCreateUserProfile()
            
            // 调用OpenRouter API生成回复
            let aiResponse = try await openRouterService.generatePetResponse(
                petName: pet.name,
                petType: pet.type,
                petPersonality: pet.personality ?? "温柔可爱",
                userMessage: content,
                conversationHistory: conversationHistory,
                personalityTraits: pet.personalityTraits,
                detailedDescription: pet.detailedDescription,
                userProfile: userProfile
            )
            
            // 创建AI回复消息
            let assistantMessage = ChatMessage(
                sessionId: session.id,
                role: "assistant",
                content: aiResponse
            )
            
            await MainActor.run {
                modelContext.insert(assistantMessage)
                session.messages.append(assistantMessage)
                session.lastMessageAt = Date()
                isLoading = false
            }
            
            // 同步AI消息到Supabase
            await syncMessageToSupabase(assistantMessage)
            
        } catch {
            await MainActor.run {
                errorMessage = "发送消息失败: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func getConversationHistory(for session: ChatSession) -> [OpenRouterMessage] {
        let sortedMessages = session.messages.sorted { $0.createdAt < $1.createdAt }
        return sortedMessages.map { message in
            OpenRouterMessage(role: message.role, content: message.content)
        }
    }
    
    // MARK: - Supabase Sync
    private func syncSessionToSupabase(_ session: ChatSession) async {
        guard let user = supabaseService.currentUser else { return }
        
        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "user_id": user.id.uuidString,
            "pet_id": session.petId.uuidString,
            "session_name": session.sessionName,
            "created_at": ISO8601DateFormatter().string(from: session.createdAt),
            "last_message_at": ISO8601DateFormatter().string(from: session.lastMessageAt)
        ]
        
        do {
            try await supabaseService.client
                .from("chat_sessions")
                .insert(sessionData)
                .execute()
        } catch {
            print("Error syncing session to Supabase: \(error)")
        }
    }
    
    private func syncMessageToSupabase(_ message: ChatMessage) async {
        guard supabaseService.currentUser != nil else { return }
        
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "session_id": message.sessionId.uuidString,
            "role": message.role,
            "content": message.content,
            "created_at": ISO8601DateFormatter().string(from: message.createdAt)
        ]
        
        do {
            try await supabaseService.client
                .from("chat_messages")
                .insert(messageData)
                .execute()
        } catch {
            print("Error syncing message to Supabase: \(error)")
        }
    }
    
    // MARK: - Load from Supabase
    func loadChatSessionsFromSupabase(for pet: Pet, modelContext: ModelContext) async {
        guard let user = supabaseService.currentUser else { return }
        
        do {
            let response = try await supabaseService.client
                .from("chat_sessions")
                .select("*")
                .eq("user_id", value: user.id.uuidString)
                .eq("pet_id", value: pet.id.uuidString)
                .order("last_message_at", ascending: false)
                .execute()
            
            // 解析并创建本地会话
            // 这里需要根据实际的Supabase响应格式来实现
            
        } catch {
            print("Error loading chat sessions from Supabase: \(error)")
        }
    }
}