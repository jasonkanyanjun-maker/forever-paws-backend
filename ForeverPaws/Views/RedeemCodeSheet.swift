import SwiftUI

struct RedeemCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var redeemCodeService = RedeemCodeService.shared
    
    let onRedeemComplete: () -> Void
    
    @State private var redeemCode = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGreen).opacity(0.03),
                        Color(.systemBlue).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // 标题区域
                        VStack(spacing: 16) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 8) {
                                Text("兑换码")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("输入兑换码获取免费视频积分")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // 兑换码输入区域
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("兑换码")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("请输入兑换码", text: $redeemCode)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                    .textCase(.uppercase)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                            }
                            
                            // 兑换按钮
                            Button {
                                Task {
                                    await redeemCode()
                                }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                    }
                                    
                                    Text(isLoading ? "兑换中..." : "立即兑换")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                            }
                            .disabled(redeemCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        
                        // 使用说明
                        VStack(alignment: .leading, spacing: 16) {
                            Text("使用说明")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                InstructionRow(
                                    number: "1",
                                    text: "输入您获得的兑换码"
                                )
                                
                                InstructionRow(
                                    number: "2",
                                    text: "点击"立即兑换"按钮"
                                )
                                
                                InstructionRow(
                                    number: "3",
                                    text: "兑换成功后即可获得免费视频积分"
                                )
                                
                                InstructionRow(
                                    number: "4",
                                    text: "每个兑换码只能使用一次"
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("兑换码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("确定", role: .cancel) {
                    if alertTitle == "兑换成功" {
                        onRedeemComplete()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func redeemCode() async {
        let code = redeemCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        
        isLoading = true
        
        do {
            let success = try await redeemCodeService.redeemCode(code)
            
            await MainActor.run {
                if success {
                    alertTitle = "兑换成功"
                    alertMessage = "恭喜！您已成功兑换视频积分"
                } else {
                    alertTitle = "兑换失败"
                    alertMessage = "兑换码无效或已被使用"
                }
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertTitle = "兑换失败"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 数字圆圈
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    RedeemCodeSheet(onRedeemComplete: {})
}