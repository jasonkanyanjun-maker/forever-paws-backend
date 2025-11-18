//
//  VideoGenerationView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import AVKit

struct VideoGenerationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var generations: [VideoGeneration]
    
    @StateObject private var paymentService = PaymentService.shared
    @StateObject private var redeemCodeService = RedeemCodeService.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var dashScopeService = DashScopeService.shared
    @StateObject private var templateService = VideoTemplateService.shared
    
    @State private var currentGeneration: VideoGeneration?
    @State private var showingUpload = true
    @State private var showingTemplateSelection = false
    @State private var selectedTemplate: VideoTemplate?
    @State private var selectedImages: [UIImage] = []
    @State private var generationProgress: Double = 0.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPaymentSheet = false
    @State private var showRedeemCodeSheet = false
    @State private var redeemCode = ""
    @State private var videoCredits = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBlue).opacity(0.03),
                        Color(.systemPurple).opacity(0.05),
                        Color(.systemPink).opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title card
                        VStack(spacing: 16) {
                            // Main title area
                            VStack(spacing: 8) {
                                Text("AI Video Generation")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Transform your images into amazing AI videos")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Decorative icons
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "wand.and.stars.inverse")
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        
                        // Video credits display
                        VideoCreditsCard(
                            credits: videoCredits,
                            onPurchase: { showPaymentSheet = true },
                            onRedeem: { showRedeemCodeSheet = true }
                        )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Main content area
                    if showingUpload {
                        // Image upload interface card
                        VideoUploadView { images in
                            selectedImages = images
                            showingTemplateSelection = true
                        }
                    } else if showingTemplateSelection {
                        // Template selection interface
                        VideoTemplateSelectionView { template in
                            selectedTemplate = template
                            startVideoGeneration(with: selectedImages, template: template)
                        }
                    } else if let generation = currentGeneration {
                        // Generation progress interface card
                        VideoGenerationProgressView(
                            generation: generation,
                            onComplete: {
                                showingUpload = true
                                showingTemplateSelection = false
                                currentGeneration = nil
                                selectedImages = []
                                selectedTemplate = nil
                            },
                            onRetry: {
                                retryGeneration(generation)
                            }
                        )
                    }
                    
                    // Feature description card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "photo.on.rectangle.angled",
                                title: "Smart Image Recognition",
                                description: "Automatically recognizes image content and generates corresponding videos"
                            )
                            
                            FeatureRow(
                                icon: "sparkles",
                                title: "AI-Driven Generation",
                                description: "Uses advanced AI technology to create smooth videos"
                            )
                            
                            FeatureRow(
                                icon: "rectangle.portrait.and.arrow.right.rectangle.landscape",
                                title: "Multiple Orientations",
                                description: "Support both portrait and landscape video generation"
                            )
                            
                            FeatureRow(
                                icon: "figure.stand",
                                title: "Pet Action Templates",
                                description: "Choose from various pet actions like standing, sitting with different movements"
                            )
                            
                            FeatureRow(
                                icon: "clock.arrow.circlepath",
                                title: "Real-time Progress Tracking",
                                description: "View generation progress and history anytime"
                            )
                            
                            FeatureRow(
                                icon: "creditcard.and.123",
                                title: "Flexible Payment Options",
                                description: "Support Apple Pay payment or free generation with redemption codes"
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPaymentSheet) {
            PaymentSheet(
                onPurchaseComplete: {
                    loadVideoCredits()
                }
            )
        }
        .sheet(isPresented: $showRedeemCodeSheet) {
            RedeemCodeSheet(
                onRedeemComplete: {
                    loadVideoCredits()
                }
            )
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadVideoCredits()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadVideoCredits() {
        Task {
            let credits = supabaseService.getUserVideoCredits()
            await MainActor.run {
                videoCredits = credits
            }
        }
    }
    
    private func startVideoGeneration(with images: [UIImage], template: VideoTemplate) {
        guard let firstImage = images.first else {
            alertMessage = "Please select at least one image"
            showAlert = true
            return
        }
        
        // Check video credits
        if videoCredits <= 0 {
            alertMessage = "Insufficient video credits, please purchase credits or use a redemption code"
            showAlert = true
            return
        }
        
        // Save UIImage as temporary file
        guard let imageData = images.first?.jpegData(compressionQuality: 0.8) else {
            alertMessage = "Image processing failed"
            showAlert = true
            return
        }
        
        let tempURL = saveImageToTempFile(imageData)
        
        do {
            // Create new generation task with template
            let generation = VideoGeneration(
                originalImageURL: tempURL
            )
            
            // Set user ID for data isolation
            generation.userId = SupabaseService.shared.currentUser?.id.uuidString ?? ""
            
            // Set template information
            generation.selectedTemplate = template
            
            // Start generation process
            modelContext.insert(generation)
            try modelContext.save()
            
            // Deduct video credits
            Task {
                do {
                    _ = try await supabaseService.deductVideoCredits(1)
                } catch {
                    await MainActor.run {
                        generation.status = .failed
                        generation.errorMessage = "Failed to deduct credits: \(error.localizedDescription)"
                    }
                }
            }
            
            // Update status to uploading
            generation.status = .uploading
            generation.progress = 0.1
            try modelContext.save()
            
            // Use fixed template video generation service
            Task {
                await generateVideoWithTemplate(for: generation, template: template, image: firstImage)
                
                // Poll to check generation status
                await pollTemplateGenerationStatus(for: generation)
            }
            
            // Set current generation
            currentGeneration = generation
            showingUpload = false
            showingTemplateSelection = false
            
        } catch {
            alertMessage = "Failed to save generation task: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func saveImageToTempFile(_ imageData: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save image to temp file: \(error)")
            return tempURL
        }
    }
    
    private func generateVideo(for generation: VideoGeneration) async {
        do {
            // Check if original image file exists
            guard let originalImageURL = generation.originalImageURL,
                  FileManager.default.fileExists(atPath: originalImageURL.path) else {
                await MainActor.run {
                    generation.status = .failed
                    generation.errorMessage = "Cannot find original image file"
                }
                return
            }
            
            // Actually call DashScope API to submit video generation task
            let taskId = try await dashScopeService.submitVideoGeneration(
                imageURL: originalImageURL,
                userID: "user123" // In actual app, use real user ID
            )
            
            await MainActor.run {
                generation.taskId = taskId
                generation.status = .processing
                generation.progress = 0.2
            }
            
            // Start polling generation status
        } catch {
            await MainActor.run {
                generation.status = .failed
                generation.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func pollGenerationStatus(for generation: VideoGeneration) async {
        let maxAttempts = 30 // Maximum 30 polls (about 5 minutes)
        var attempts = 0
        
        print("🔄 [VideoGeneration] Starting status polling")
        
        guard let taskId = generation.taskId, !taskId.isEmpty else {
            print("❌ [VideoGeneration] Task ID is empty or doesn't exist")
            await MainActor.run {
                generation.status = .failed
                generation.errorMessage = "Task ID doesn't exist or is empty, please resubmit task"
            }
            return
        }
        
        print("🆔 [VideoGeneration] Starting to poll task ID: \(taskId)")
        
        while attempts < maxAttempts {
            attempts += 1
            print("🔄 [VideoGeneration] Attempt \(attempts)/\(maxAttempts) to query task status")
            
            do {
                // Call actual DashScope status query API
                let statusResponse = try await dashScopeService.queryTaskStatus(taskId: taskId)
                
                // Verify task ID in response matches
                if let responseTaskId = statusResponse.output?.task_id, responseTaskId != taskId {
                    print("⚠️ [VideoGeneration] Task ID mismatch in response: expected=\(taskId), actual=\(responseTaskId)")
                }
                
                // Calculate progress
                let baseProgress: Double = 0.2 // Starting progress
                let maxProgress: Double = 0.9   // Maximum progress before completion
                let progressRange = maxProgress - baseProgress
                
                // Estimate progress based on attempt count
                let attemptProgress = min(Double(attempts) / Double(maxAttempts), 1.0)
                let statusProgress = baseProgress + (progressRange * attemptProgress)
                
                await MainActor.run {
                    // Update progress but don't exceed 90% until actually completed
                    if generation.status == .processing {
                        generation.progress = min(statusProgress, 0.9)
                    }
                }
                
                print("📊 [VideoGeneration] Task status: \(statusResponse.output?.task_status ?? "unknown"), progress: \(Int(statusProgress * 100))%")
                
                // Check if task completed successfully
                if statusResponse.output?.task_status == "SUCCEEDED" {
                    print("✅ [VideoGeneration] Task completed successfully")
                    
                    if let resultURL = statusResponse.output?.results?.first?.url {
                        print("🎥 [VideoGeneration] Generated video URL: \(resultURL)")
                        
                        await MainActor.run {
                            generation.status = .completed
                            generation.progress = 1.0
                            generation.generatedVideoURL = URL(string: resultURL)
                        }
                        return
                    } else {
                        print("❌ [VideoGeneration] Task completed but missing video URL")
                        await MainActor.run {
                            generation.status = .failed
                            generation.errorMessage = "Video generation completed but cannot get result URL"
                        }
                        return
                    }
                }
                
                // Check if task failed
                if statusResponse.output?.task_status == "FAILED" {
                    print("❌ [VideoGeneration] Task failed")
                    let apiMessage = statusResponse.output?.results?.first?.url ?? "Unknown error"
                    await MainActor.run {
                        generation.status = .failed
                        let errorMessage = !apiMessage.isEmpty ? "Video generation failed: \(apiMessage)" : "Video generation failed, please check image format and network connection then retry"
                        generation.errorMessage = errorMessage
                    }
                    return
                }
                
                // If still processing, continue polling
                if statusResponse.output?.task_status == "RUNNING" || 
                   statusResponse.output?.task_status == "PENDING" {
                    print("⏳ [VideoGeneration] Task processing, waiting 10 seconds before next query...")
                    
                    // Wait 10 seconds before next query
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                }
                
            } catch {
                print("❌ [VideoGeneration] Error occurred while querying task status: \(error.localizedDescription)")
                
                // If network error and still have retry chances, continue trying
                if attempts < maxAttempts - 5 { // Reserve last 5 chances
                    print("🔄 [VideoGeneration] Network error, will retry in 5 seconds...")
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    continue
                } else {
                    await MainActor.run {
                        generation.status = .failed
                        generation.errorMessage = "Failed to query task status: \(error.localizedDescription)"
                    }
                    return
                }
            }
        }
        
        // If exceeded maximum attempts and still not completed, mark as failed
        if attempts >= maxAttempts {
            print("⏰ [VideoGeneration] Polling timeout, attempted \(maxAttempts) times")
            await MainActor.run {
                generation.status = .failed
                generation.errorMessage = "Video generation timeout (waited about \(maxAttempts * 10 / 60) minutes), please retry"
            }
        }
        
        print("🏁 [VideoGeneration] Polling ended, final status: \(generation.status)")
    }
    
    private func retryGeneration(_ generation: VideoGeneration) {
        generation.status = .pending
        generation.progress = 0.0
        generation.errorMessage = nil
        generation.taskId = nil
        
        try? modelContext.save()
        
        Task {
            await generateVideo(for: generation)
            await pollGenerationStatus(for: generation)
        }
    }
}

// MARK: - Video Generation Progress View
struct VideoGenerationProgressView: View {
    @Bindable var generation: VideoGeneration
    let onComplete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 进度圆环区域
                VStack(spacing: 20) {
                    ZStack {
                        // 背景圆环
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                            .frame(width: 180, height: 180)
                        
                        // 进度圆环
                        Circle()
                            .trim(from: 0, to: generation.progress)
                            .stroke(
                                LinearGradient(
                                    colors: progressGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: generation.progress)
                        
                        // 中心内容
                        VStack(spacing: 8) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: progressGradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(generation.status == .processing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: generation.status == .processing)
                            
                            Text("\(Int(generation.progress * 100))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: progressGradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    // 状态信息卡片
                    VStack(spacing: 16) {
                        Text(generation.status.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: progressGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(statusDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                }
                
                // 原始图片预览卡片
                if let originalURL = generation.originalImageURL {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "photo.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.title2)
                            Text("原始图片")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        CachedAsyncImage(url: originalURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )
                }
                
                // 生成的视频预览卡片
                if generation.status == .completed,
                   let generatedURL = generation.generatedVideoURL {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.title2)
                            Text("AI生成视频")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VideoPlayer(player: AVPlayer(url: generatedURL))
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )
                }
                
                // 错误信息卡片
                if generation.status == .failed,
                   let errorMessage = generation.errorMessage {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            Text("生成失败")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.red.opacity(0.05))
                            .stroke(.red.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // 操作按钮区域
                VStack(spacing: 16) {
                    if generation.status == .completed {
                        Button(action: onComplete) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("生成新视频")
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
                    } else if generation.status == .failed {
                        HStack(spacing: 12) {
                            Button(action: onRetry) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title3)
                                    Text("重试")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button(action: onComplete) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .font(.title3)
                                    Text("新建")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.blue, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBlue).opacity(0.03),
                    Color(.systemPurple).opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Computed Properties
    
    private var progressGradientColors: [Color] {
        switch generation.status {
        case .pending, .uploading:
            return [.blue, .cyan]
        case .processing:
            return [.orange, .yellow]
        case .completed:
            return [.green, .mint]
        case .failed:
            return [.red, .pink]
        }
    }
    
    private var statusIcon: String {
        switch generation.status {
        case .pending:
            return "clock.fill"
        case .uploading:
            return "icloud.and.arrow.up.fill"
        case .processing:
            return "gearshape.2.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var statusDescription: String {
        switch generation.status {
        case .pending:
            return "准备开始生成视频..."
        case .uploading:
            return "正在上传图片到云端..."
        case .processing:
            return "AI正在为您生成精彩的视频，请稍候..."
        case .completed:
            return "视频生成完成！您可以预览或分享您的作品。"
        case .failed:
            return "视频生成遇到问题，请检查网络连接后重试。"
        }
    }
}

#Preview {
    VideoGenerationView()
        .modelContainer(for: VideoGeneration.self, inMemory: true)
}

private func generateVideoWithTemplate(for generation: VideoGeneration, template: VideoTemplate, image: UIImage) async {
    do {
        print("🎬 [VideoGeneration] Starting template-based video generation")
        print("📋 [VideoGeneration] Template: \(template.name)")
        print("📐 [VideoGeneration] Orientation: \(template.orientation.displayName)")
        print("🎭 [VideoGeneration] Pet Action: \(template.petAction.displayName)")
        
        // Use fixed template service to generate video
        let taskId = try await FixedTemplateVideoService.shared.generateVideo(
            with: image,
            template: template,
            userID: "user123" // In actual app, use real user ID
        )
        
        await MainActor.run {
            generation.taskId = taskId
            generation.status = .processing
            generation.progress = 0.2
        }
        
        print("✅ [VideoGeneration] Template video generation task submitted: \(taskId)")
        
    } catch {
        await MainActor.run {
            generation.status = .failed
            generation.errorMessage = error.localizedDescription
        }
        print("❌ [VideoGeneration] Template video generation failed: \(error)")
    }
}

private func pollTemplateGenerationStatus(for generation: VideoGeneration) async {
    let maxAttempts = 30 // Maximum 30 polls (about 5 minutes)
    var attempts = 0
    
    print("🔄 [VideoGeneration] Starting template video status polling")
    
    guard let taskId = generation.taskId, !taskId.isEmpty else {
        print("❌ [VideoGeneration] Task ID is empty or doesn't exist")
        await MainActor.run {
            generation.status = .failed
            generation.errorMessage = "Task ID doesn't exist or is empty, please resubmit task"
        }
        return
    }
    
    print("🆔 [VideoGeneration] Starting to poll template task ID: \(taskId)")
    
    while attempts < maxAttempts {
        attempts += 1
        print("🔄 [VideoGeneration] Attempt \(attempts)/\(maxAttempts) to query template task status")
        
        do {
            // Call fixed template video status query
            let statusResponse = try await FixedTemplateVideoService.shared.queryGenerationStatus(taskId: taskId)
            
            // Calculate progress
            let baseProgress: Double = 0.2 // Starting progress
            let maxProgress: Double = 0.9   // Maximum progress before completion
            let progressRange = maxProgress - baseProgress
            
            // Estimate progress based on attempt count and response
            let attemptProgress = min(Double(attempts) / Double(maxAttempts), 1.0)
            let statusProgress = baseProgress + (progressRange * attemptProgress)
            
            await MainActor.run {
                // Update progress but don't exceed 90% until actually completed
                if generation.status == .processing {
                    generation.progress = min(statusProgress, 0.9)
                }
            }
            
            print("📊 [VideoGeneration] Template task status: \(statusResponse.status), progress: \(Int(statusProgress * 100))%")
            
            // Check if task completed successfully
            if statusResponse.isCompleted {
                print("✅ [VideoGeneration] Template task completed successfully")
                
                if let resultURL = statusResponse.resultURL {
                    print("🎥 [VideoGeneration] Generated template video URL: \(resultURL)")
                    
                    await MainActor.run {
                        generation.status = .completed
                        generation.progress = 1.0
                        generation.generatedVideoURL = URL(string: resultURL)
                    }
                    return
                } else {
                    print("❌ [VideoGeneration] Template task completed but missing video URL")
                    await MainActor.run {
                        generation.status = .failed
                        generation.errorMessage = "Template video generation completed but cannot get result URL"
                    }
                    return
                }
            }
            
            // Check if task failed
            if statusResponse.isFailed {
                print("❌ [VideoGeneration] Template task failed")
                let errorMessage = statusResponse.errorMessage ?? "Template video generation failed"
                await MainActor.run {
                    generation.status = .failed
                    generation.errorMessage = errorMessage
                }
                return
            }
            
            // Continue polling if still processing
            if statusResponse.isProcessing {
                print("⏳ [VideoGeneration] Template task still processing, waiting...")
                try await Task.sleep(nanoseconds: 10_000_000_000) // Wait 10 seconds
                continue
            }
            
        } catch {
            print("❌ [VideoGeneration] Template status query failed: \(error)")
            
            if attempts >= maxAttempts {
                await MainActor.run {
                    generation.status = .failed
                    generation.errorMessage = "Template video generation timeout: \(error.localizedDescription)"
                }
                return
            }
            
            // Wait before retry
            try? await Task.sleep(nanoseconds: 5_000_000_000) // Wait 5 seconds
        }
    }
    
    // Timeout
    print("⏰ [VideoGeneration] Template video generation timeout")
    await MainActor.run {
        generation.status = .failed
        generation.errorMessage = "Template video generation timeout, please try again"
    }
}