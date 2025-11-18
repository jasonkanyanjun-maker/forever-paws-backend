//
//  Letter.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class Letter {
    var id: UUID
    var userId: String // Supabase user ID
    var petId: UUID
    var content: String
    var reply: String? // AI pet reply
    var sentAt: Date
    var createdAt: Date
    
    // Relationship
    @Relationship(inverse: \Pet.letters) var pet: Pet?
    
    init(petId: UUID, content: String, reply: String? = nil, createdAt: Date = Date()) {
        self.id = UUID()
        self.userId = "" // Will be set when user is authenticated
        self.petId = petId
        self.content = content
        self.reply = reply
        self.sentAt = Date()
        self.createdAt = createdAt
    }
    
    var previewText: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        } else {
            let index = content.index(content.startIndex, offsetBy: maxLength)
            return String(content[..<index]) + "..."
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: sentAt)
    }
}