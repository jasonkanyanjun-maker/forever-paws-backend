//
//  VideoUploadView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import CoreHaptics
import PhotosUI
import UniformTypeIdentifiers

struct VideoUploadView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isValidating = false
    @State private var dragOver = false
    
    let onImagesSelected: ([UIImage]) -> Void
    
    // 定义主要渐变色
    private let primaryGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题区域
            titleSection
            
            // 上传区域
            uploadSection
            
            // 已选择的图片
            if !selectedImages.isEmpty {
                selectedImagesSection
            }
            
            // 开始生成按钮
            if !selectedImages.isEmpty {
                generateButton
            }
            
            // 使用说明
            instructionsSection
        }
        .padding(.horizontal, 20)
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            HStack {
                // 渐变图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("选择图片")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("上传图片开始AI视频生成")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Divider()
                .opacity(0.3)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Upload Section
    
    private var uploadSection: some View {
        VStack(spacing: 20) {
            // 拖拽上传区域
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                VStack(spacing: 20) {
                    // 图标区域
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: dragOver ? [.blue.opacity(0.3), .purple.opacity(0.3)] : [.blue.opacity(0.1), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: selectedImages.isEmpty ? "plus.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: selectedImages.isEmpty ? [.blue, .purple] : [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(selectedImages.isEmpty ? "点击选择图片" : "已选择 \(selectedImages.count) 张图片")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("支持 JPG、PNG 格式，最多选择5张")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 状态指示器
                    if isValidating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("验证中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .stroke(
                        selectedImages.isEmpty ? 
                        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.green.opacity(0.5), .mint.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, dash: selectedImages.isEmpty ? [8, 4] : [])
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(dragOver ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: dragOver)
            
            // 快捷操作按钮
            if !selectedImages.isEmpty {
                HStack(spacing: 12) {
                    Button(action: clearSelection) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("清空")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.1))
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        Button(action: {
            onImagesSelected(selectedImages)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("选择模板")
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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: selectedImages.count)
    }

// MARK: - Selected Images Section
    
    private var selectedImagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("已选择的图片")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedImages.count)/5")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.secondary.opacity(0.1))
                    )
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                        
                        // 删除按钮
                        Button(action: { removeImage(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 24, height: 24)
                                )
                        }
                        .offset(x: 8, y: -8)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
                
                Text("使用说明")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    icon: "photo",
                    title: "图片格式",
                    description: "支持 JPG、PNG 格式，建议分辨率不低于 512x512"
                )
                
                InstructionRow(
                    icon: "square.stack.3d.up",
                    title: "数量限制",
                    description: "单次最多可选择 5 张图片进行批量处理"
                )
                
                InstructionRow(
                    icon: "doc.text.magnifyingglass",
                    title: "文件大小",
                    description: "单张图片大小不超过 10MB，确保上传速度"
                )
                
                InstructionRow(
                    icon: "sparkles",
                    title: "AI生成",
                    description: "基于您的图片，AI将生成高质量的动态视频"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        isValidating = true
        var newImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                // 验证图片
                if validateImage(data: data, image: image) {
                    newImages.append(image)
                }
            }
        }
        
        await MainActor.run {
            selectedImages = newImages
            isValidating = false
            
            if !newImages.isEmpty {
                // 添加成功反馈 - 安全处理触觉反馈
                performHapticFeedback(style: .medium)
            }
        }
    }
    
    private func validateImage(data: Data, image: UIImage) -> Bool {
        // 检查文件大小 (10MB)
        if data.count > 10 * 1024 * 1024 {
            alertMessage = "图片文件过大，请选择小于10MB的图片"
            showingAlert = true
            return false
        }
        
        // 检查图片尺寸
        if image.size.width < 256 || image.size.height < 256 {
            alertMessage = "图片分辨率过低，请选择至少256x256像素的图片"
            showingAlert = true
            return false
        }
        
        return true
    }
    
    private func removeImage(at index: Int) {
        // 使用显式的 withAnimation 来执行删除动画，忽略返回值
        _ = withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedImages.remove(at: index)
        }
        
        // 添加删除反馈 - 安全处理触觉反馈
        performHapticFeedback(style: .light)
    }
    
    // MARK: - 安全的触觉反馈处理
    private func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if #available(iOS 13.0, *) {
            if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func clearSelection() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedImages.removeAll()
            selectedItems.removeAll()
        }
    }
}

// MARK: - Instruction Row Component

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    VideoUploadView { images in
        print("Selected \(images.count) images")
    }
}
