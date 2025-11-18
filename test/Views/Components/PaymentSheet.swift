//
//  PaymentSheet.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import StoreKit

struct PaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared
    @StateObject private var supabaseService = SupabaseService.shared
    
    let onPurchaseComplete: () -> Void
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemPurple).opacity(0.05),
                        Color(.systemBlue).opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题区域
                        VStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("购买视频积分")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("解锁AI视频生成功能")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // 产品卡片
                        if paymentService.isLoading {
                            ProgressView("加载中...")
                                .frame(height: 200)
                        } else if paymentService.products.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                
                                Text("暂无可购买的产品")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("请稍后再试或联系客服")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button("重新加载") {
                                    Task {
                                        await paymentService.loadProducts()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(height: 200)
                        } else {
                            ForEach(paymentService.products, id: \.id) { product in
                                ProductCard(
                                    product: product,
                                    onPurchase: {
                                        purchaseProduct(product)
                                    }
                                )
                            }
                        }
                        
                        // 功能说明
                        VStack(alignment: .leading, spacing: 16) {
                            Text("购买说明")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                InfoRow(
                                    icon: "checkmark.circle.fill",
                                    title: "即时到账",
                                    description: "购买成功后积分立即到账"
                                )
                                
                                InfoRow(
                                    icon: "shield.checkered",
                                    title: "安全支付",
                                    description: "通过Apple Pay安全支付"
                                )
                                
                                InfoRow(
                                    icon: "arrow.clockwise.circle",
                                    title: "可恢复购买",
                                    description: "支持恢复之前的购买记录"
                                )
                                
                                InfoRow(
                                    icon: "sparkles",
                                    title: "高质量生成",
                                    description: "使用先进AI技术生成精美视频"
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        
                        // 恢复购买按钮
                        Button("恢复购买") {
                            restorePurchases()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("购买积分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await paymentService.loadProducts()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                let success = try await paymentService.purchaseVideoGeneration()
                
                if success {
                    await MainActor.run {
                        alertTitle = "购买成功"
                        alertMessage = "视频积分已添加到您的账户"
                        showAlert = true
                        
                        // 延迟关闭并回调
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onPurchaseComplete()
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertTitle = "购买失败"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await paymentService.restorePurchases()
            
            await MainActor.run {
                alertTitle = "恢复完成"
                alertMessage = "已恢复之前的购买记录"
                showAlert = true
                
                onPurchaseComplete()
            }
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("视频生成积分")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("1次AI视频生成机会")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$2.99")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("约 ¥19.6")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: onPurchase) {
                HStack {
                    Image(systemName: "creditcard")
                        .font(.headline)
                    
                    Text("立即购买")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PaymentSheet(onPurchaseComplete: {})
}