import SwiftUI
import StoreKit

struct PaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared
    @StateObject private var supabaseService = SupabaseService.shared
    
    let onPurchaseComplete: () -> Void
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBlue).opacity(0.03),
                        Color(.systemPurple).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题区域
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("购买视频积分")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("使用积分生成精彩的AI视频")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // 产品卡片
                        if paymentService.products.isEmpty {
                            if isLoading {
                                ProgressView("加载产品中...")
                                    .frame(height: 100)
                            } else {
                                Text("暂无可用产品")
                                    .foregroundColor(.secondary)
                                    .frame(height: 100)
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(paymentService.products, id: \.id) { product in
                                    ProductCard(
                                        product: product,
                                        isLoading: isLoading
                                    ) {
                                        Task {
                                            await purchaseProduct(product)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 信息说明
                        VStack(spacing: 12) {
                            InfoRow(
                                icon: "checkmark.circle.fill",
                                title: "安全支付",
                                description: "通过Apple Pay安全支付"
                            )
                            
                            InfoRow(
                                icon: "arrow.clockwise.circle.fill",
                                title: "永不过期",
                                description: "积分永久有效，随时使用"
                            )
                            
                            InfoRow(
                                icon: "star.circle.fill",
                                title: "高质量视频",
                                description: "AI生成高质量2.5D视频"
                            )
                        }
                        .padding(.top, 20)
                        
                        // 恢复购买按钮
                        Button("恢复购买") {
                            Task {
                                await restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("购买积分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                Task {
                    await loadProducts()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadProducts() async {
        isLoading = true
        do {
            try await paymentService.loadProducts()
        } catch {
            alertMessage = "加载产品失败: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }
    
    private func purchaseProduct(_ product: Product) async {
        isLoading = true
        do {
            let success = try await paymentService.purchase(product)
            if success {
                onPurchaseComplete()
                dismiss()
            }
        } catch {
            alertMessage = "购买失败: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }
    
    private func restorePurchases() async {
        isLoading = true
        do {
            try await paymentService.restorePurchases()
            alertMessage = "恢复购买成功"
            showAlert = true
            onPurchaseComplete()
        } catch {
            alertMessage = "恢复购买失败: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }
}

// MARK: - Supporting Views

struct ProductCard: View {
    let product: Product
    let isLoading: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(product.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("$2.99")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            Button(action: onPurchase) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("购买")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 36)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .disabled(isLoading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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