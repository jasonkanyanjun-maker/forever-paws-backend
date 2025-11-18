//
//  OrderTrackingDetailView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI

struct OrderTrackingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let order: Order
    let orderService: OrderService
    
    @State private var trackingInfo: OrderTrackingInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "E879F9").opacity(0.05),
                        Color(hex: "F472B6").opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 订单基本信息
                        orderInfoSection
                        
                        // 物流追踪信息
                        if let trackingInfo = trackingInfo {
                            trackingSection(trackingInfo)
                        }
                        
                        // 商品详情
                        itemsSection
                        
                        // 收货信息
                        shippingInfoSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("订单详情")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            trackingInfo = orderService.trackOrder(order)
        }
    }
    
    private var orderInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("订单信息")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                OrderInfoRow(label: "订单号", value: order.orderNumber)
                OrderInfoRow(label: "下单时间", value: order.formattedCreatedDate)
                OrderInfoRow(label: "订单状态", value: order.statusDisplayName, valueColor: Color(hex: order.status.color))
                OrderInfoRow(label: "支付状态", value: order.paymentStatusDisplayName)
                OrderInfoRow(label: "订单金额", value: order.formattedTotalAmount)
                
                if let trackingNumber = order.trackingNumber {
                    OrderInfoRow(label: "快递单号", value: trackingNumber)
                }
                
                if let estimatedDelivery = order.estimatedDelivery {
                    OrderInfoRow(label: "预计送达", value: formatDate(estimatedDelivery))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func trackingSection(_ trackingInfo: OrderTrackingInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("物流追踪")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(trackingInfo.events.enumerated()), id: \.offset) { index, event in
                    TrackingEventRow(
                        event: event,
                        isLast: index == trackingInfo.events.count - 1
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("商品详情")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(order.items, id: \.id) { item in
                    OrderItemRow(item: item)
                }
                
                Divider()
                
                HStack {
                    Text("总计")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(order.formattedTotalAmount)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var shippingInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("收货信息")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                OrderInfoRow(label: "收货人", value: order.customerName)
                OrderInfoRow(label: "联系电话", value: order.customerPhone)
                OrderInfoRow(label: "邮箱地址", value: order.customerEmail)
                OrderInfoRow(label: "收货地址", value: order.shippingAddress)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct OrderInfoRow: View {
    let label: String
    let value: String
    let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

struct TrackingEventRow: View {
    let event: TrackingEvent
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线指示器
            VStack(spacing: 0) {
                Circle()
                    .fill(event.isCompleted ? 
                          LinearGradient(
                            colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) : 
                          LinearGradient(
                            colors: [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // 事件内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.status)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(event.isCompleted ? .primary : .secondary)
                    
                    Spacer()
                    
                    Text(event.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }
}

struct OrderItemRow: View {
    let item: OrderItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 商品图片占位符
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                )
            
            // 商品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let options = item.customizationOptions, !options.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(options.keys.sorted()), id: \.self) { key in
                            Text("\(key): \(options[key] ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text(item.formattedPrice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("×\(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.formattedSubtotal)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    let sampleOrder = Order(
        userId: "sample-user-id",
        customerName: "张三",
        customerEmail: "zhangsan@example.com",
        customerPhone: "13800138000",
        shippingAddress: "北京市朝阳区某某街道123号",
        items: [],
        totalAmount: 299.99
    )
    
    OrderTrackingDetailView(
        order: sampleOrder,
        orderService: OrderService()
    )
}