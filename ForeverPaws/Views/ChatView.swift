import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    
    @StateObject private var chatService = ChatService.shared
    @StateObject private var openRouterService = OpenRouterService.shared
    
    @State private var selectedPet: Pet?
    @State private var currentSession: ChatSession?
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingPetSelection = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let pet = selectedPet, let session = currentSession {
                    // Chat interface
                    chatInterface(for: pet, session: session)
                } else {
                    // Pet selection or empty state
                    petSelectionView
                }
            }
            .navigationTitle("AI对话")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("选择宠物") {
                        showingPetSelection = true
                    }
                    .disabled(pets.isEmpty)
                }
            }
            .sheet(isPresented: $showingPetSelection) {
                PetSelectionSheet(pets: pets, selectedPet: $selectedPet) {
                    Task {
                        await loadOrCreateSession()
                    }
                }
            }
        }
        .onAppear {
            if let firstPet = pets.first, selectedPet == nil {
                selectedPet = firstPet
                Task {
                    await loadOrCreateSession()
                }
            }
        }
    }
    
    // MARK: - Pet Selection View
    private var petSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("与您的宠物对话")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("选择一个宠物开始AI角色扮演对话")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if pets.isEmpty {
                Button("添加宠物") {
                    // Navigate to add pet view
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("选择宠物") {
                    showingPetSelection = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Chat Interface
    private func chatInterface(for pet: Pet, session: ChatSession) -> some View {
        VStack(spacing: 0) {
            // Pet header
            petHeader(for: pet)
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(session.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                            MessageBubble(message: message, pet: pet)
                        }
                    }
                    .padding()
                }
                .onChange(of: session.messages.count) { _ in
                    if let lastMessage = session.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input
            messageInputView
        }
    }
    
    // MARK: - Pet Header
    private func petHeader(for pet: Pet) -> some View {
        HStack {
            // Pet avatar
            AsyncImage(url: pet.photoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "pawprint.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("AI角色扮演")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("新对话") {
                Task {
                    await createNewSession()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Message Input
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator))
            
            HStack(spacing: 12) {
                TextField("输入消息...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(
                                colors: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [.gray] : [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Methods
    private func loadOrCreateSession() async {
        guard let pet = selectedPet else { return }
        
        do {
            // Try to load existing session
            let sessions = try await chatService.loadChatSessions(for: pet.id)
            if let existingSession = sessions.first {
                currentSession = existingSession
            } else {
                // Create new session
                let newSession = try await chatService.createChatSession(
                    petId: pet.id,
                    sessionName: "与\(pet.name)的对话"
                )
                currentSession = newSession
            }
        } catch {
            print("Failed to load or create session: \(error)")
        }
    }
    
    private func createNewSession() async {
        guard let pet = selectedPet else { return }
        
        do {
            let newSession = try await chatService.createChatSession(
                petId: pet.id,
                sessionName: "与\(pet.name)的对话 - \(Date().formatted(date: .abbreviated, time: .shortened))"
            )
            currentSession = newSession
        } catch {
            print("Failed to create new session: \(error)")
        }
    }
    
    private func sendMessage() async {
        guard let session = currentSession,
              let pet = selectedPet,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        isLoading = true
        
        do {
            // Send user message
            try await chatService.sendMessage(
                sessionId: session.id,
                content: userMessage,
                isFromUser: true
            )
            
            // Get AI response
            let aiResponse = try await openRouterService.generatePetResponse(
                petName: pet.name,
                petBreed: pet.breed,
                userMessage: userMessage,
                conversationHistory: session.messages.sorted(by: { $0.timestamp < $1.timestamp })
            )
            
            // Send AI response
            try await chatService.sendMessage(
                sessionId: session.id,
                content: aiResponse,
                isFromUser: false
            )
            
        } catch {
            print("Failed to send message: \(error)")
            // TODO: Show error alert
        }
        
        isLoading = false
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let pet: Pet
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    // Pet avatar
                    AsyncImage(url: pet.photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)
                    .background(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Pet Selection Sheet
struct PetSelectionSheet: View {
    let pets: [Pet]
    @Binding var selectedPet: Pet?
    let onSelection: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(pets, id: \.id) { pet in
                HStack {
                    AsyncImage(url: pet.photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pet.name)
                            .font(.headline)
                        
                        if let breed = pet.breed {
                            Text(breed)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if selectedPet?.id == pet.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPet = pet
                    onSelection()
                    dismiss()
                }
            }
            .navigationTitle("选择宠物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [Pet.self, ChatSession.self, ChatMessage.self])
}