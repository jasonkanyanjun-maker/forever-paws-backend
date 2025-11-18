//
//  VideoHistoryCard.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct VideoHistoryCard: View {
    let video: MockVideoItem
    let onDelete: () -> Void
    
    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: video.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 缩略图
            thumbnailView
            
            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 状态指示器
                    statusIndicator
                }
                
                HStack {
                    Text(relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 操作按钮
                    actionButtons
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Thumbnail View
    
    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
            
            Image(systemName: video.thumbnailName)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: video.status.iconName)
                .font(.caption)
            
            Text(video.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(colorForStatus(video.status.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(colorForStatus(video.status.color).opacity(0.1))
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if video.status == .completed {
                Button(action: {
                    // Play video
                }) {
                    Label("Play", systemImage: "play.fill")
                }
                
                // Share video
                Button(action: {
                    // Share video
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                // Download video
                Button(action: {
                    // Download video
                }) {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            } else {
                // Retry generation
                Button(action: {
                    // Retry generation
                }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
            }
            
            Button(action: {
                // Delete video
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Context Menu Items
    
    private var contextMenuItems: some View {
        Group {
            if video.status == .completed {
                Button(action: {
                    // Play video
                }) {
                    Label("Play", systemImage: "play.fill")
                }
                
                // Share video
                Button(action: {
                    // Share video
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                // Download video
                Button(action: {
                    // Download video
                }) {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            } else {
                // Retry generation
                Button(action: {
                    // Retry generation
                }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForStatus(_ colorString: String) -> Color {
        switch colorString {
        case "green":
            return .green
        case "blue":
            return .blue
        case "red":
            return .red
        default:
            return .primary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        VideoHistoryCard(
            video: MockVideoItem(
                id: "1",
                title: "Landscape Video 1",
                status: .completed,
                createdAt: Date().addingTimeInterval(-3600),
                thumbnailName: "photo"
            )
        ) {}
        
        VideoHistoryCard(
            video: MockVideoItem(
                id: "2",
                title: "Portrait Video 2",
                status: .processing,
                createdAt: Date().addingTimeInterval(-7200),
                thumbnailName: "person"
            )
        ) {}
        
        VideoHistoryCard(
            video: MockVideoItem(
                id: "3",
                title: "Animal Video 3",
                status: .failed,
                createdAt: Date().addingTimeInterval(-10800),
                thumbnailName: "pawprint"
            )
        ) {}
    }
    .padding()
}