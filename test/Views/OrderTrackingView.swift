//
//  OrderTrackingView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct OrderTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var orderService = OrderService()
    
    @State private var searchText = ""
    @State private var selectedOrder: Order?
    @State private var showingTrackingDetail = false
    
    var filteredOrders: [Order] {
        if searchText.isEmpty {
            return orderService.orders
        } else {
            return orderService.orders.filter { order in
                order.orderNumber.localizedCaseInsensitiveContains(searchText) ||
                order.customerName.localizedCaseInsensitiveContains(searchText) ||
                order.trackingNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
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
                
                VStack(spacing: 0) {
                    if orderService.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("加载订单中...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredOrders.isEmpty {
                        emptyStateView
                    } else {
                        ordersList
                    }
                }
            }
            .navigationTitle("订单追踪")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索订单号、姓名或快递单号")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTrackingDetail) {
            if let order = selectedOrder {
                OrderTrackingDetailView(order: order, orderService: orderService)
            }
        }
        .onAppear {
            orderService.setModelContext(modelContext)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("暂无订单")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("您还没有任何订单\n快去纪念品商店看看吧")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: MemorialProductsView()) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 16))
                    
                    Text("去购物")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color(hex: "E879F9").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var ordersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredOrders) { order in
                    OrderTrackingCard(
                        order: order,
                        onTrackTapped: {
                            selectedOrder = order
                            showingTrackingDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct OrderTrackingCard: View {
    let order: Order
    let onTrackTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 订单头部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("订单号：\(order.orderNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(order.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.statusDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: order.status.color))
                        .cornerRadius(8)
                    
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
            
            // 商品信息
            VStack(alignment: .leading, spacing: 8) {
                Text("商品信息")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(order.items.prefix(2), id: \.id) { item in
                    HStack {
                        Text(item.productName)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("×\(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if order.items.count > 2 {
                    Text("等\(order.items.count)件商品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 物流信息
            if let trackingNumber = order.trackingNumber {
                VStack(alignment: .leading, spacing: 8) {
                    Text("物流信息")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("快递单号：\(trackingNumber)")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let estimatedDelivery = order.estimatedDelivery {
                            Text("预计送达：\(DateFormatter.orderShortDate.string(from: estimatedDelivery))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // 操作按钮
            HStack {
                if order.status == .pending {
                    Button("取消订单") {
                        // TODO: Implement cancel order
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Button("查看详情") {
                    onTrackTapped()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension DateFormatter {
    static let orderShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

#Preview {
    OrderTrackingView()
        .modelContainer(for: [Order.self, OrderItem.self], inMemory: true)
}