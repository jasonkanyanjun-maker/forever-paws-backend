//
//  VideoGeneration.swift
//  test
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class VideoGeneration {
    var id: UUID
    var userId: String // Supabase user ID
    var petId: UUID? // Associated pet
    var originalImageURL: URL?
    var generatedVideoURL: URL?
    var thumbnailURL: URL?
    var status: GenerationStatus
    var taskId: String?
    var progress: Double
    var createdAt: Date
    var completedAt: Date?
    var errorMessage: String?
    var metadata: Data? // JSON metadata
    var title: String?
    
    // Relationship
    @Relationship(inverse: \Pet.videos) var pet: Pet?
    
    init(originalImageURL: URL? = nil, petId: UUID? = nil, title: String? = nil, userId: String = "default") {
        self.id = UUID()
        self.userId = userId // Provide default value to avoid migration issues
        self.petId = petId
        self.originalImageURL = originalImageURL
        self.generatedVideoURL = nil
        self.thumbnailURL = nil
        self.status = .pending
        self.taskId = nil
        self.progress = 0.0
        self.createdAt = Date()
        self.completedAt = nil
        self.errorMessage = nil
        self.metadata = nil
        self.title = title
    }
}

enum GenerationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case uploading = "uploading"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Waiting"
        case .uploading:
            return "Uploading"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "gray"
        case .uploading:
            return "blue"
        case .processing:
            return "orange"
        case .completed:
            return "green"
        case .failed:
            return "red"
        }
    }
}