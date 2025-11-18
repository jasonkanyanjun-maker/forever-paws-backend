//
//  VideoCreditsCard.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct VideoCreditsCard: View {
    let credits: Int
    let onPurchase: () -> Void
    let onRedeem: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 积分显示区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("视频积分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.title2)
                        
                        Text("\(credits)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 状态指示器
                ZStack {
                    Circle()
                        .fill(credits > 0 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: credits > 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(credits > 0 ? .green : .orange)
                        .font(.title3)
                }
            }
            
            // 操作按钮区域
            HStack(spacing: 12) {
                // 购买积分按钮
                Button(action: onPurchase) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .font(.caption)
                        Text("购买积分")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                
                // 兑换码按钮
                Button(action: onRedeem) {
                    HStack(spacing: 8) {
                        Image(systemName: "ticket")
                            .font(.caption)
                        Text("兑换码")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                }
            }
            
            // 提示信息
            if credits <= 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("积分不足，请购买积分或使用兑换码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        VideoCreditsCard(
            credits: 3,
            onPurchase: {},
            onRedeem: {}
        )
        
        VideoCreditsCard(
            credits: 0,
            onPurchase: {},
            onRedeem: {}
        )
    }
    .padding()
}