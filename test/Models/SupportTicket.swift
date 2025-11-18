import Foundation
import SwiftUI

struct SupportTicket: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var category: TicketCategory
    var subject: String
    var description: String
    var status: TicketStatus
    var attachments: [String]
    var adminResponse: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case subject
        case description
        case status
        case attachments
        case adminResponse = "admin_response"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum TicketCategory: String, Codable, CaseIterable {
        case technical = "technical"
        case billing = "billing"
        case feature = "feature"
        case bug = "bug"
        case general = "general"
        
        var displayName: String {
            switch self {
            case .technical:
                return "Technical Issue"
            case .billing:
                return "Billing"
            case .feature:
                return "Feature Request"
            case .bug:
                return "Bug Report"
            case .general:
                return "General Inquiry"
            }
        }
        
        var icon: String {
            switch self {
            case .technical:
                return "wrench.and.screwdriver"
            case .billing:
                return "creditcard"
            case .feature:
                return "lightbulb"
            case .bug:
                return "ant"
            case .general:
                return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .technical:
                return .red
            case .billing:
                return .green
            case .feature:
                return .blue
            case .bug:
                return .orange
            case .general:
                return .purple
            }
        }
    }
    
    enum TicketStatus: String, Codable, CaseIterable {
        case open = "open"
        case inProgress = "in_progress"
        case resolved = "resolved"
        case closed = "closed"
        
        var displayName: String {
            switch self {
            case .open:
                return "Open"
            case .inProgress:
                return "In Progress"
            case .resolved:
                return "Resolved"
            case .closed:
                return "Closed"
            }
        }
        
        var color: Color {
            switch self {
            case .open:
                return .blue
            case .inProgress:
                return .orange
            case .resolved:
                return .green
            case .closed:
                return .gray
            }
        }
    }
    
    init(id: UUID = UUID(), userId: UUID, category: TicketCategory, subject: String, description: String, status: TicketStatus = .open, attachments: [String] = [], adminResponse: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.category = category
        self.subject = subject
        self.description = description
        self.status = status
        self.attachments = attachments
        self.adminResponse = adminResponse
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}