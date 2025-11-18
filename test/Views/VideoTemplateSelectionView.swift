//
//  VideoTemplateSelectionView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct VideoTemplateSelectionView: View {
    @StateObject private var templateService = VideoTemplateService.shared
    @State private var selectedOrientation: VideoOrientation = .portrait
    @State private var selectedTemplate: VideoTemplate?
    
    let onTemplateSelected: (VideoTemplate) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题区域
            VStack(spacing: 8) {
                Text("选择视频模板")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("选择您喜欢的视频方向和宠物动作")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 方向选择器
            orientationSelector
            
            // 模板网格
            templateGrid
            
            // 确认按钮
            if let selectedTemplate = selectedTemplate {
                confirmButton(for: selectedTemplate)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            // 默认选择第一个模板
            selectedTemplate = templateService.getTemplates(for: selectedOrientation).first
        }
    }
    
    private var orientationSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("视频方向")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(VideoOrientation.allCases, id: \.self) { orientation in
                    Button(action: {
                        selectedOrientation = orientation
                        // 切换方向时，选择该方向的第一个模板
                        selectedTemplate = templateService.getTemplates(for: orientation).first
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: orientation == .portrait ? "rectangle.portrait" : "rectangle")
                                .font(.title3)
                            
                            Text(orientation.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedOrientation == orientation ? 
                                      Color.blue.opacity(0.1) : Color.clear)
                                .stroke(selectedOrientation == orientation ? 
                                       Color.blue : Color.gray.opacity(0.3), 
                                       lineWidth: 1.5)
                        )
                        .foregroundColor(selectedOrientation == orientation ? .blue : .primary)
                    }
                }
            }
        }
    }
    
    private var templateGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("宠物动作")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(templateService.getTemplates(for: selectedOrientation), id: \.id) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate?.id == template.id,
                        onTap: {
                            selectedTemplate = template
                        }
                    )
                }
            }
        }
    }
    
    private func confirmButton(for template: VideoTemplate) -> some View {
        Button(action: {
            onTemplateSelected(template)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                
                Text("使用此模板")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

struct TemplateCard: View {
    let template: VideoTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 预览区域
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(template.orientation.aspectRatio, contentMode: .fit)
                    
                    VStack(spacing: 8) {
                        Image(systemName: actionIcon(for: template.petAction))
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(template.duration)s")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 模板信息
                VStack(spacing: 4) {
                    Text(template.petAction.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(template.templateDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func actionIcon(for action: PetAction) -> String {
        switch action {
        case .standingWagTail:
            return "figure.stand"
        case .sittingLickPaw:
            return "figure.seated.side"
        }
    }
}

#Preview {
    VideoTemplateSelectionView { template in
        print("Selected template: \(template.name)")
    }
    .padding()
}