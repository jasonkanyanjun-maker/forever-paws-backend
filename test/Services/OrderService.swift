//
//  OrderService.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData
import Combine

@MainActor
class OrderService: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadOrders()
    }
    
    // MARK: - Order Management
    
    func createOrder(
        customerName: String,
        customerEmail: String,
        customerPhone: String,
        shippingAddress: String,
        cartItems: [CartItem]
    ) async throws -> Order {
        guard let context = modelContext else {
            throw OrderError.contextNotSet
        }
        
        guard !cartItems.isEmpty else {
            throw OrderError.emptyCart
        }
        
        // 获取当前用户ID
        guard let currentUser = SupabaseService.shared.currentUser else {
            throw OrderError.userNotAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Convert cart items to order items
        let orderItems = cartItems.map { cartItem in
            OrderItem(
                productId: cartItem.productId,
                productName: cartItem.productName,
                productPrice: cartItem.productPrice,
                quantity: cartItem.quantity,
                customizationOptions: cartItem.customizationOptions
            )
        }
        
        let totalAmount = cartItems.reduce(0) { $0 + ($1.productPrice * Double($1.quantity)) }
        
        let order = Order(
            userId: currentUser.id.uuidString,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            shippingAddress: shippingAddress,
            items: orderItems,
            totalAmount: totalAmount
        )
        
        // Insert order items first
        for item in orderItems {
            context.insert(item)
        }
        
        // Then insert the order
        context.insert(order)
        
        do {
            try context.save()
            
            // Simulate order processing
            await simulateOrderProcessing(order)
            
            loadOrders()
            return order
        } catch {
            throw OrderError.saveFailed(error.localizedDescription)
        }
    }
    
    func updateOrderStatus(_ order: Order, to status: OrderStatus) async throws {
        guard let context = modelContext else {
            throw OrderError.contextNotSet
        }
        
        order.status = status
        order.updatedAt = Date()
        
        // Add tracking number when shipped
        if status == .shipped && order.trackingNumber == nil {
            order.trackingNumber = generateTrackingNumber()
            order.estimatedDelivery = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        }
        
        do {
            try context.save()
            loadOrders()
        } catch {
            throw OrderError.updateFailed(error.localizedDescription)
        }
    }
    
    func updatePaymentStatus(_ order: Order, to status: OrderPaymentStatus) async throws {
        guard let context = modelContext else {
            throw OrderError.contextNotSet
        }
        
        order.paymentStatus = status
        order.updatedAt = Date()
        
        // Auto-confirm order when payment is successful
        if status == .paid && order.status == .pending {
            order.status = .confirmed
        }
        
        do {
            try context.save()
            loadOrders()
        } catch {
            throw OrderError.updateFailed(error.localizedDescription)
        }
    }
    
    func cancelOrder(_ order: Order) async throws {
        guard order.status == .pending || order.status == .confirmed else {
            throw OrderError.cannotCancel
        }
        
        try await updateOrderStatus(order, to: .cancelled)
    }
    
    func getOrder(by id: UUID) -> Order? {
        return orders.first { $0.id == id }
    }
    
    func getOrderByNumber(_ orderNumber: String) -> Order? {
        return orders.first { $0.orderNumber == orderNumber }
    }
    
    // MARK: - Order Tracking
    
    func trackOrder(_ order: Order) -> OrderTrackingInfo {
        let events = generateTrackingEvents(for: order)
        return OrderTrackingInfo(
            orderNumber: order.orderNumber,
            status: order.status,
            trackingNumber: order.trackingNumber,
            estimatedDelivery: order.estimatedDelivery,
            events: events
        )
    }
    
    // MARK: - Private Methods
    
    private func loadOrders() {
        guard let context = modelContext else { return }
        
        // 获取当前用户ID
        guard let currentUser = SupabaseService.shared.currentUser else {
            orders = []
            return
        }
        
        let currentUserId = currentUser.id.uuidString
        
        // 添加用户ID过滤条件
        let descriptor = FetchDescriptor<Order>(
            predicate: #Predicate<Order> { order in
                order.userId == currentUserId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            orders = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load orders: \(error.localizedDescription)"
        }
    }
    
    private func simulateOrderProcessing(_ order: Order) async {
        // Simulate payment processing
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Update payment status to paid
        try? await updatePaymentStatus(order, to: .paid)
        
        // Simulate order confirmation
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Update order status to processing
        try? await updateOrderStatus(order, to: .processing)
    }
    
    private func generateTrackingNumber() -> String {
        let prefix = "FP"
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "\(prefix)\(timestamp)\(random)"
    }
    
    private func generateTrackingEvents(for order: Order) -> [TrackingEvent] {
        var events: [TrackingEvent] = []
        
        // Order created
        events.append(TrackingEvent(
            status: "订单创建",
            description: "您的订单已成功创建",
            timestamp: order.createdAt,
            isCompleted: true
        ))
        
        // Payment
        if order.paymentStatus == .paid {
            events.append(TrackingEvent(
                status: "支付完成",
                description: "订单支付已完成",
                timestamp: order.updatedAt,
                isCompleted: true
            ))
        }
        
        // Order confirmed
        if order.status.rawValue != "pending" {
            events.append(TrackingEvent(
                status: "订单确认",
                description: "订单已确认，开始制作",
                timestamp: order.updatedAt,
                isCompleted: order.status != .pending
            ))
        }
        
        // Processing
        if order.status == .processing || order.status == .shipped || order.status == .delivered {
            events.append(TrackingEvent(
                status: "制作中",
                description: "商品正在精心制作中",
                timestamp: order.updatedAt,
                isCompleted: order.status != .confirmed
            ))
        }
        
        // Shipped
        if order.status == .shipped || order.status == .delivered {
            events.append(TrackingEvent(
                status: "已发货",
                description: "商品已发货，正在配送中",
                timestamp: order.updatedAt,
                isCompleted: order.status == .shipped || order.status == .delivered
            ))
        }
        
        // Delivered
        if order.status == .delivered {
            events.append(TrackingEvent(
                status: "已送达",
                description: "商品已成功送达",
                timestamp: order.updatedAt,
                isCompleted: true
            ))
        }
        
        return events
    }
}

// MARK: - Supporting Types

struct OrderTrackingInfo {
    let orderNumber: String
    let status: OrderStatus
    let trackingNumber: String?
    let estimatedDelivery: Date?
    let events: [TrackingEvent]
}

struct TrackingEvent {
    let status: String
    let description: String
    let timestamp: Date
    let isCompleted: Bool
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: timestamp)
    }
}

enum OrderError: LocalizedError {
    case contextNotSet
    case emptyCart
    case userNotAuthenticated
    case saveFailed(String)
    case updateFailed(String)
    case cannotCancel
    
    var errorDescription: String? {
        switch self {
        case .contextNotSet:
            return "Database context not set"
        case .emptyCart:
            return "Cart is empty"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .saveFailed(let message):
            return "Save order failed: \(message)"
        case .updateFailed(let message):
            return "Update order failed: \(message)"
        case .cannotCancel:
            return "This order cannot be cancelled"
        }
    }
}