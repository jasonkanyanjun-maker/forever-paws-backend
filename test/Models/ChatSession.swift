//
//  ChatSession.swift
//  test
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var userId: String
    var petId: UUID
    var sessionName: String
    var createdAt: Date
    var lastMessageAt: Date
    
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []
    @Relationship(inverse: \Pet.chatSessions) var pet: Pet?
    
    init(userId: String, petId: UUID, sessionName: String) {
        self.id = UUID()
        self.userId = userId
        self.petId = petId
        self.sessionName = sessionName
        self.createdAt = Date()
        self.lastMessageAt = Date()
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var role: String // "user" or "assistant"
    var content: String
    var createdAt: Date
    
    init(sessionId: UUID, role: String, content: String) {
        self.id = UUID()
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}