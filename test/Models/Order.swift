//
//  Order.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
class Order {
    var id: UUID
    var userId: String // 添加用户ID字段，确保订单数据隔离
    var orderNumber: String
    var customerName: String
    var customerEmail: String
    var customerPhone: String
    var shippingAddress: String
    var items: [OrderItem]
    var totalAmount: Double
    var status: OrderStatus
    var paymentStatus: OrderPaymentStatus
    var trackingNumber: String?
    var estimatedDelivery: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        userId: String,
        customerName: String,
        customerEmail: String,
        customerPhone: String,
        shippingAddress: String,
        items: [OrderItem],
        totalAmount: Double
    ) {
        self.id = UUID()
        self.userId = userId
        self.orderNumber = "FP\(Int(Date().timeIntervalSince1970))"
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.shippingAddress = shippingAddress
        self.items = items
        self.totalAmount = totalAmount
        self.status = .pending
        self.paymentStatus = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var formattedTotalAmount: String {
        return String(format: "¥%.2f", totalAmount)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: createdAt)
    }
    
    var statusDisplayName: String {
        return status.displayName
    }
    
    var paymentStatusDisplayName: String {
        return paymentStatus.displayName
    }
}

@Model
class OrderItem {
    var id: UUID
    var productId: UUID
    var productName: String
    var productPrice: Double
    var quantity: Int
    var customizationOptions: [String: String]?
    var subtotal: Double
    
    init(
        productId: UUID,
        productName: String,
        productPrice: Double,
        quantity: Int,
        customizationOptions: [String: String]? = nil
    ) {
        self.id = UUID()
        self.productId = productId
        self.productName = productName
        self.productPrice = productPrice
        self.quantity = quantity
        self.customizationOptions = customizationOptions
        self.subtotal = productPrice * Double(quantity)
    }
    
    var formattedPrice: String {
        return String(format: "¥%.2f", productPrice)
    }
    
    var formattedSubtotal: String {
        return String(format: "¥%.2f", subtotal)
    }
}

enum OrderStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case processing = "processing"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "待确认"
        case .confirmed:
            return "已确认"
        case .processing:
            return "制作中"
        case .shipped:
            return "已发货"
        case .delivered:
            return "已送达"
        case .cancelled:
            return "已取消"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "FFA500" // Orange
        case .confirmed:
            return "4169E1" // Royal Blue
        case .processing:
            return "9932CC" // Dark Orchid
        case .shipped:
            return "32CD32" // Lime Green
        case .delivered:
            return "228B22" // Forest Green
        case .cancelled:
            return "DC143C" // Crimson
        }
    }
}

enum OrderPaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case paid = "paid"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "待支付"
        case .paid:
            return "已支付"
        case .failed:
            return "支付失败"
        case .refunded:
            return "已退款"
        }
    }
}