import SwiftUI

struct VideoCreditsCard: View {
    let credits: Int
    let onPurchase: () -> Void
    let onRedeem: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 积分显示区域
            VStack(alignment: .leading, spacing: 4) {
                Text("视频积分")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("\(credits)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // 状态指示器
                HStack(spacing: 4) {
                    Circle()
                        .fill(credits > 0 ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text(credits > 0 ? "可用" : "不足")
                        .font(.caption2)
                        .foregroundColor(credits > 0 ? .green : .red)
                }
            }
            
            Spacer()
            
            // 操作按钮区域
            HStack(spacing: 8) {
                // 购买积分按钮
                Button(action: onPurchase) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                            .font(.caption)
                        Text("购买")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 兑换码按钮
                Button(action: onRedeem) {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket")
                            .font(.caption)
                        Text("兑换")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
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
            credits: 5,
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