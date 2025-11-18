//
//  Pet.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

enum PetType: String, CaseIterable, Codable {
    case dog = "dog"
    case cat = "cat"
    case bird = "bird"
    case rabbit = "rabbit"
    case hamster = "hamster"
    case fish = "fish"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .dog:
            return "Dog"
        case .cat:
            return "Cat"
        case .bird:
            return "Bird"
        case .rabbit:
            return "Rabbit"
        case .hamster:
            return "Hamster"
        case .fish:
            return "Fish"
        case .other:
            return "Other"
        }
    }
}

@Model
final class Pet {
    var id: UUID
    var userId: String // Supabase user ID
    var name: String
    var type: PetType
    var breed: String?
    var age: String?
    var petDescription: String?
    var photoURL: URL?
    var birthDate: Date?
    var memorialDate: Date?
    var createdAt: Date
    
    // Enhanced fields for AI context
    var personalityTraits: [String: String] = [:]
    var detailedDescription: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var videos: [VideoGeneration] = []
    @Relationship(deleteRule: .cascade) var letters: [Letter] = []
    @Relationship(deleteRule: .cascade) var chatSessions: [ChatSession] = []
    
    init(name: String, type: PetType, breed: String? = nil, age: String? = nil, petDescription: String? = nil, photoURL: URL? = nil, birthDate: Date? = nil, memorialDate: Date? = nil) {
        self.id = UUID()
        self.userId = "" // Will be set when user is authenticated
        self.name = name
        self.type = type
        self.breed = breed
        self.age = age
        self.petDescription = petDescription
        self.photoURL = photoURL
        self.birthDate = birthDate
        self.memorialDate = memorialDate
        self.createdAt = Date()
    }
    
    var isMemorialized: Bool {
        return memorialDate != nil
    }
    
    var ageString: String {
        guard let birthDate = birthDate else { return "未知年龄" }
        
        let endDate = memorialDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: birthDate, to: endDate)
        
        if let years = components.year, years > 0 {
            if let months = components.month, months > 0 {
                return "\(years)岁\(months)个月"
            } else {
                return "\(years)岁"
            }
        } else if let months = components.month, months > 0 {
            return "\(months)个月"
        } else {
            return "不到1个月"
        }
    }
}