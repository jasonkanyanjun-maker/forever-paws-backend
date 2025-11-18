//
//  RedeemCodeSheet.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct RedeemCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var redeemCodeService = RedeemCodeService.shared
    
    let onRedeemComplete: () -> Void
    
    @State private var redeemCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isLoading = false
    @State private var isSuccess = false
    @State private var showingAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Redeem Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your redemption code to unlock premium features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Code Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Redemption Code")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter code", text: $redeemCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                }
                
                // Redeem Button
                Button(action: performRedeem) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "gift")
                            Text("Redeem")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(redeemCode.isEmpty ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(redeemCode.isEmpty || isLoading)
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Codes are case-sensitive")
                        Text("• Each code can only be used once")
                        Text("• Contact support if you have issues")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Redeem")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Result", isPresented: $showingAlert) {
                Button("OK") {
                    if isSuccess {
                        onRedeemComplete()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func performRedeem() {
        guard !redeemCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let success = try await RedeemCodeService.shared.redeemCode(redeemCode)
                
                await MainActor.run {
                    isLoading = false
                    isSuccess = success
                    alertMessage = success ? "Redemption successful!" : "Redemption failed"
                    showingAlert = true
                    
                    if success {
                        self.redeemCode = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isSuccess = false
                    alertMessage = "Redemption failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func redeemCodeAction() {
        let trimmedCode = redeemCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedCode.isEmpty else {
            alertTitle = "输入错误"
            alertMessage = "请输入有效的兑换码"
            showAlert = true
            return
        }
        
        Task {
            do {
                let success = try await redeemCodeService.validateAndRedeemCode(trimmedCode)
                
                await MainActor.run {
                    if success {
                        alertTitle = "兑换成功"
                        alertMessage = "恭喜！视频积分已添加到您的账户"
                        showAlert = true
                        redeemCode = ""
                    }
                }
            } catch {
                await MainActor.run {
                    alertTitle = "兑换失败"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Redeem Info Row
struct RedeemInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
    RedeemCodeSheet(onRedeemComplete: {})
}