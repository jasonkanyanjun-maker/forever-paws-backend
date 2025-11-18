//
//  MockVideoItem.swift
//  test
//
//  Created by AI Assistant
//

import Foundation

struct MockVideoItem: Identifiable {
    let id: String
    let title: String
    let status: MockVideoStatus
    let createdAt: Date
    let thumbnailName: String
}

enum MockVideoStatus {
    case completed
    case processing
    case failed
    
    var displayName: String {
        switch self {
        case .completed:
            return "Completed"
        case .processing:
            return "Processing"
        case .failed:
            return "Failed"
        }
    }
    
    var iconName: String {
        switch self {
        case .completed:
            return "checkmark.circle.fill"
        case .processing:
            return "clock.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .completed:
            return "green"
        case .processing:
            return "blue"
        case .failed:
            return "red"
        }
    }
}