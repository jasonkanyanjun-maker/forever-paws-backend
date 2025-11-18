//
//  SharingCenterView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct SharingCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var videos: [VideoGeneration]
    @Query private var pets: [Pet]
    @Query private var letters: [Letter]
    
    @State private var selectedContent: ShareableContent?
    @State private var showingShareSheet = false
    @State private var selectedPlatform: SocialPlatform?
    @State private var shareText = ""
    @State private var selectedFilter: ContentFilter = .all
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 内容筛选器
                    contentFilter
                    
                    // 可分享内容网格
                    shareableContentGrid
                }
            }
            .navigationTitle("Sharing Center")
            .navigationBarTitleDisplayMode(.large)

        }
        .sheet(isPresented: $showingShareSheet) {
            if let content = selectedContent {
                ShareContentView(content: content, shareText: $shareText)
            }
        }
    }
    

    
    private var contentFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContentFilter.allCases, id: \.self) { filter in
                    SharingFilterChip(
                    filter: filter,
                    isSelected: selectedFilter == filter
                ) {
                    selectedFilter = filter
                }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    private var shareableContentGrid: some View {
        ScrollView {
            if filteredContent.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    VStack(spacing: 12) {
                        Text("No Content to Share")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Create some holographic projections or add pets to start sharing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(filteredContent) { content in
                        ShareableContentCard(content: content) {
                            selectedContent = content
                            showingShareSheet = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var filteredContent: [ShareableContent] {
        var content: [ShareableContent] = []
        
        switch selectedFilter {
        case .all:
            // 添加视频内容
            content.append(contentsOf: videos.compactMap { video -> ShareableContent? in
                guard video.status == .completed else { return nil }
                return ShareableContent(
                    id: video.id.uuidString,
                    type: .video,
                    title: video.title ?? "Holographic Projection",
                    thumbnailURL: video.thumbnailURL ?? video.originalImageURL,
                    videoURL: video.generatedVideoURL,
                    createdAt: video.createdAt,
                    petName: pets.first(where: { $0.id == video.petId })?.name
                )
            })
            
            // 添加宠物照片内容
            content.append(contentsOf: pets.compactMap { pet in
                guard let photoURL = pet.photoURL else { return nil }
                return ShareableContent(
                    id: pet.id.uuidString,
                    type: .photo,
                    title: "\(pet.name)'s Photo",
                    thumbnailURL: photoURL,
                    videoURL: nil,
                    createdAt: pet.createdAt,
                    petName: pet.name
                )
            })
            
            // 添加信件内容
            content.append(contentsOf: letters.compactMap { letter -> ShareableContent? in
                guard !letter.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return ShareableContent(
                    id: letter.id.uuidString,
                    type: .letter,
                    title: String(letter.content.prefix(50)) + (letter.content.count > 50 ? "..." : ""),
                    thumbnailURL: pets.first(where: { $0.id == letter.petId })?.photoURL,
                    videoURL: nil,
                    createdAt: letter.createdAt,
                    petName: pets.first(where: { $0.id == letter.petId })?.name
                )
            })
            
        case .videos:
            content = videos.compactMap { video -> ShareableContent? in
                guard video.status == .completed else { return nil }
                return ShareableContent(
                    id: video.id.uuidString,
                    type: .video,
                    title: video.title ?? "Holographic Projection",
                    thumbnailURL: video.thumbnailURL ?? video.originalImageURL,
                    videoURL: video.generatedVideoURL,
                    createdAt: video.createdAt,
                    petName: pets.first(where: { $0.id == video.petId })?.name
                )
            }
            
        case .photos:
            content = pets.compactMap { pet in
                guard let photoURL = pet.photoURL else { return nil }
                return ShareableContent(
                    id: pet.id.uuidString,
                    type: .photo,
                    title: "\(pet.name)'s Photo",
                    thumbnailURL: photoURL,
                    videoURL: nil,
                    createdAt: pet.createdAt,
                    petName: pet.name
                )
            }
            
        case .letters:
            content = letters.compactMap { letter -> ShareableContent? in
                guard !letter.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return ShareableContent(
                    id: letter.id.uuidString,
                    type: .letter,
                    title: String(letter.content.prefix(50)) + (letter.content.count > 50 ? "..." : ""),
                    thumbnailURL: pets.first(where: { $0.id == letter.petId })?.photoURL,
                    videoURL: nil,
                    createdAt: letter.createdAt,
                    petName: pets.first(where: { $0.id == letter.petId })?.name
                )
            }
        }
        
        return content.sorted { $0.createdAt > $1.createdAt }
    }
}

struct SharingFilterChip: View {
    let filter: ContentFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                
                Text(filter.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.green, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.systemGray5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareableContentCard: View {
    let content: ShareableContent
    let onTap: () -> Void
    
    // 快速分享功能
    private func quickShare(content: ShareableContent) async {
        let shareText = generateQuickShareText(for: content)
        
        await MainActor.run {
            var activityItems: [Any] = [shareText]
            
            // 添加内容URL（如果有的话）
            if let videoURL = content.videoURL {
                activityItems.append(videoURL)
            } else if let thumbnailURL = content.thumbnailURL {
                activityItems.append(thumbnailURL)
            }
            
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            // 配置iPad的popover
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func generateQuickShareText(for content: ShareableContent) -> String {
        switch content.type {
        case .letter:
            if let petName = content.petName {
                return "A heartfelt letter to my beloved \(petName) 💌 Created with Forever Paws 🐾💜 #ForeverPaws #PetMemorial"
            } else {
                return "A heartfelt letter to my beloved pet 💌 Created with Forever Paws 🐾💜 #ForeverPaws #PetMemorial"
            }
        case .video, .photo:
            if let petName = content.petName {
                return "Beautiful memory of \(petName) 🐾💜 Created with Forever Paws #ForeverPaws #PetMemorial"
            } else {
                return "Beautiful pet memory 🐾💜 Created with Forever Paws #ForeverPaws #PetMemorial"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 内容预览
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .aspectRatio(1, contentMode: .fit)
                    
                    if let thumbnailURL = content.thumbnailURL {
                        CachedAsyncImage(url: thumbnailURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: content.type == .video ? "video" : (content.type == .photo ? "photo" : "envelope"))
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                    
                    // 内容类型指示器
                    VStack {
                        HStack {
                            Spacer()
                            
                            Image(systemName: content.type.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(content.type.color.opacity(0.8))
                                )
                        }
                        
                        Spacer()
                        
                        // 快速分享按钮
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await quickShare(content: content)
                                }
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                    )
                            }
                        }
                    }
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let petName = content.petName {
                        Text(petName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(DateFormatter.shortDate.string(from: content.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ShareContentView: View {
    let content: ShareableContent
    @Binding var shareText: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlatforms: Set<SocialPlatform> = []
    @State private var isSharing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 内容预览
                    contentPreview
                    
                    // 分享文本编辑
                    shareTextEditor
                    
                    // 社交平台选择
                    platformSelector
                    
                    // 分享按钮
                    shareButton
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Share Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            shareText = generateDefaultShareText()
        }
    }
    
    private var contentPreview: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let thumbnailURL = content.thumbnailURL {
                    CachedAsyncImage(url: thumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if content.type == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 60, height: 60)
                        )
                }
            }
            
            Text(content.title)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var shareTextEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Message")
                .font(.headline)
            
            TextEditor(text: $shareText)
                .frame(minHeight: 100)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            Text("\(shareText.count)/280")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share to")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(SocialPlatform.allCases, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatforms.contains(platform)
                    ) {
                        if selectedPlatforms.contains(platform) {
                            selectedPlatforms.remove(platform)
                        } else {
                            selectedPlatforms.insert(platform)
                        }
                    }
                }
            }
        }
    }
    
    private var shareButton: some View {
        Button(action: shareContent) {
            HStack {
                if isSharing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                }
                
                Text(isSharing ? "Sharing..." : "Share Now")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedPlatforms.isEmpty ?
                AnyView(Color.gray) :
                AnyView(LinearGradient(
                    colors: [Color.green, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            )
            .cornerRadius(12)
        }
        .disabled(selectedPlatforms.isEmpty || isSharing)
    }
    
    private func generateDefaultShareText() -> String {
        switch content.type {
        case .letter:
            if let petName = content.petName {
                return "A heartfelt letter to my beloved \(petName) 💌 Created with Forever Paws 🐾💜 #ForeverPaws #PetMemorial #LetterToPet"
            } else {
                return "A heartfelt letter to my beloved pet 💌 Created with Forever Paws 🐾💜 #ForeverPaws #PetMemorial #LetterToPet"
            }
        case .video, .photo:
            if let petName = content.petName {
                return "Check out this beautiful memory of \(petName) created with Forever Paws! 🐾💜 #ForeverPaws #PetMemorial #HolographicProjection"
            } else {
                return "Created with Forever Paws - keeping our beloved pets forever in our hearts 🐾💜 #ForeverPaws #PetMemorial"
            }
        }
    }
    
    private func shareContent() {
        isSharing = true
        
        Task {
            for platform in selectedPlatforms {
                await shareToSocialPlatform(platform: platform, content: content, text: shareText)
            }
            
            await MainActor.run {
                isSharing = false
                dismiss()
            }
        }
    }
    
    private func shareToSocialPlatform(platform: SocialPlatform, content: ShareableContent, text: String) async {
        // 首先上传内容到服务器并获取分享链接
        let shareableURL = await uploadContentToServer(content: content)
        
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedURL = shareableURL?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var shareURL: String
        
        switch platform {
        case .whatsapp:
            shareURL = "whatsapp://send?text=\(encodedText)%20\(encodedURL)"
        case .twitter:
            shareURL = "twitter://post?message=\(encodedText)&url=\(encodedURL)"
        case .facebook:
            shareURL = "https://www.facebook.com/sharer/sharer.php?u=\(encodedURL)&quote=\(encodedText)"
        case .instagram:
            // Instagram doesn't support direct URL sharing, use native share sheet
            await shareWithNativeSheet(content: content, text: text)
            return
        case .tiktok:
            // TikTok doesn't support direct URL sharing, use native share sheet
            await shareWithNativeSheet(content: content, text: text)
            return
        case .reddit:
            shareURL = "https://www.reddit.com/submit?url=\(encodedURL)&title=\(encodedText)"
        case .pinterest:
            shareURL = "https://pinterest.com/pin/create/button/?url=\(encodedURL)&description=\(encodedText)"
        }
        
        if let url = URL(string: shareURL) {
            await MainActor.run {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback to native share sheet
                    Task {
                        await shareWithNativeSheet(content: content, text: text)
                    }
                }
            }
        }
    }
    
    private func uploadContentToServer(content: ShareableContent) async -> String? {
        // 构建分享内容的公共URL
        let baseURL = APIConfig.shared.baseURL
        
        switch content.type {
        case .letter:
            // 为信件创建分享页面
            return "\(baseURL)/share/letter/\(content.id)"
        case .photo:
            // 为照片创建分享页面
            return "\(baseURL)/share/photo/\(content.id)"
        case .video:
            // 为视频创建分享页面
            return "\(baseURL)/share/video/\(content.id)"
        }
    }
    
    private func shareWithNativeSheet(content: ShareableContent, text: String) async {
        await MainActor.run {
            var activityItems: [Any] = [text]
            
            // 添加内容URL（如果有的话）
            if let videoURL = content.videoURL {
                activityItems.append(videoURL)
            } else if let thumbnailURL = content.thumbnailURL {
                activityItems.append(thumbnailURL)
            }
            
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            // 配置iPad的popover
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
}

struct PlatformButton: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : platform.color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? platform.color : Color(.systemGray6))
                    )
                
                Text(platform.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? platform.color : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 数据模型
struct ShareableContent: Identifiable {
    let id: String
    let type: ContentType
    let title: String
    let thumbnailURL: URL?
    let videoURL: URL?
    let createdAt: Date
    let petName: String?
}

enum ContentType: String, CaseIterable {
    case video = "video"
    case photo = "photo"
    case letter = "letter"
    
    var displayName: String {
        switch self {
        case .video: return "Video"
        case .photo: return "Photo"
        case .letter: return "Letter"
        }
    }
    
    var icon: String {
        switch self {
        case .video: return "video.fill"
        case .photo: return "photo.fill"
        case .letter: return "envelope.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .video: return .blue
        case .photo: return .green
        case .letter: return .orange
        }
    }
}

enum ContentFilter: String, CaseIterable {
    case all = "all"
    case videos = "videos"
    case photos = "photos"
    case letters = "letters"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .videos: return "Videos"
        case .photos: return "Photos"
        case .letters: return "Letters"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .videos: return "video"
        case .photos: return "photo"
        case .letters: return "envelope"
        }
    }
}

enum SocialPlatform: String, CaseIterable {
    case instagram = "instagram"
    case facebook = "facebook"
    case whatsapp = "whatsapp"
    case twitter = "twitter"
    case tiktok = "tiktok"
    case reddit = "reddit"
    case pinterest = "pinterest"
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .whatsapp: return "WhatsApp"
        case .twitter: return "Twitter"
        case .tiktok: return "TikTok"
        case .reddit: return "Reddit"
        case .pinterest: return "Pinterest"
        }
    }
    
    var icon: String {
        switch self {
        case .instagram: return "camera"
        case .facebook: return "f.circle"
        case .whatsapp: return "message"
        case .twitter: return "bird"
        case .tiktok: return "music.note"
        case .reddit: return "r.circle"
        case .pinterest: return "p.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return .pink
        case .facebook: return .blue
        case .whatsapp: return .green
        case .twitter: return .cyan
        case .tiktok: return .black
        case .reddit: return .orange
        case .pinterest: return .red
        }
    }
    
    var urlScheme: String {
        switch self {
        case .instagram: return "instagram://app"
        case .facebook: return "fb://profile"
        case .whatsapp: return "whatsapp://send"
        case .twitter: return "twitter://post"
        case .tiktok: return "tiktok://app"
        case .reddit: return "reddit://submit"
        case .pinterest: return "pinterest://pin"
        }
    }
    
    var webURL: String {
        switch self {
        case .instagram: return "https://www.instagram.com/"
        case .facebook: return "https://www.facebook.com/sharer/sharer.php"
        case .whatsapp: return "https://wa.me/"
        case .twitter: return "https://twitter.com/intent/tweet"
        case .tiktok: return "https://www.tiktok.com/"
        case .reddit: return "https://www.reddit.com/submit"
        case .pinterest: return "https://pinterest.com/pin/create/button/"
        }
    }
}

#Preview {
    SharingCenterView()
        .modelContainer(for: [VideoGeneration.self, Pet.self], inMemory: true)
}