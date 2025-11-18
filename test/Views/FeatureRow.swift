//
//  FeatureRow.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标区域
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 文本区域
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FeatureRow(
            icon: "photo.on.rectangle.angled",
            title: "智能图片识别",
            description: "自动识别图片内容并生成相应视频"
        )
        
        FeatureRow(
            icon: "sparkles",
            title: "AI驱动生成",
            description: "使用先进的AI技术创造流畅视频"
        )
        
        FeatureRow(
            icon: "clock.arrow.circlepath",
            title: "实时进度跟踪",
            description: "随时查看生成进度和历史记录"
        )
    }
    .padding()
    .background(.ultraThinMaterial)
}