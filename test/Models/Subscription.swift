//
//  Subscription.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class Subscription {
    var id: UUID
    var userId: String // Supabase user ID
    var planType: PlanType
    var amount: Double?
    var startDate: Date
    var endDate: Date?
    var status: SubscriptionStatus
    var createdAt: Date
    
    // Note: UserProfile relationship removed as it's not a SwiftData model
    
    init(planType: PlanType, amount: Double? = nil, startDate: Date = Date(), endDate: Date? = nil, status: SubscriptionStatus = .active) {
        self.id = UUID()
        self.userId = "" // Will be set when user is authenticated
        self.planType = planType
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.createdAt = Date()
    }
    
    var isActive: Bool {
        return status == .active && (endDate == nil || endDate! > Date())
    }
    
    var formattedAmount: String {
        guard let amount = amount else { return "Free" }
        return String(format: "%.2f", amount)
    }
    
    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day
    }
}

enum PlanType: String, CaseIterable, Codable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free Plan"
        case .premium:
            return "Premium Plan"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["Basic video generation", "Up to 3 pet profiles", "Basic memorial items"]
        case .premium:
            return ["Unlimited video generation", "Unlimited pet profiles", "Premium memorial items", "Priority customer support", "Cloud backup"]
        }
    }
}

enum SubscriptionStatus: String, CaseIterable, Codable {
    case active = "active"
    case cancelled = "cancelled"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .cancelled:
            return "Cancelled"
        case .expired:
            return "Expired"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "green"
        case .cancelled:
            return "orange"
        case .expired:
            return "red"
        }
    }
}