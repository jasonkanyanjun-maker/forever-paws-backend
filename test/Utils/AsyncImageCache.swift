//
//  AsyncImageCache.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import Foundation

// MARK: - 图片缓存管理器
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let urlSession: URLSession
    
    private init() {
        // 配置缓存
        cache.countLimit = 100 // 最多缓存100张图片
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB内存限制
        
        // 配置URLSession
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20MB内存缓存
            diskCapacity: 100 * 1024 * 1024,  // 100MB磁盘缓存
            diskPath: "image_cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        urlSession = URLSession(configuration: config)
    }
    
    func getImage(from url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func clearImageCache(for url: URL) {
        cache.removeObject(forKey: url.absoluteString as NSString)
        // Also clear URLSession cache for this specific URL
        urlSession.configuration.urlCache?.removeCachedResponse(for: URLRequest(url: url))
    }
}

// MARK: - 增强的AsyncImage组件
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    private let cacheManager = ImageCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else if loadError != nil {
                // 显示错误状态
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    Text("Load Failed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, newURL in
            if newURL != url {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        // 检查缓存
        if let cachedImage = cacheManager.getImage(from: url) {
            self.image = cachedImage
            return
        }
        
        // 开始加载
        isLoading = true
        loadError = nil
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        // 缓存图片
                        cacheManager.setImage(uiImage, for: url)
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.loadError = URLError(.badServerResponse)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadError = error
                    self.isLoading = false
                    print("❌ Failed to load image from \(url): \(error)")
                }
            }
        }
    }
}

// MARK: - 便利初始化器
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}