//
//  VideoTemplateService.swift
//  test
//
//  Created by AI Assistant
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class VideoTemplateService: ObservableObject {
    static let shared = VideoTemplateService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// 获取所有可用的视频模板
    func getAvailableTemplates() -> [VideoTemplate] {
        return [
            VideoTemplate(
                name: "站立摇尾",
                templateDescription: "宠物站立姿态，摇摆尾巴并轻摇头部",
                orientation: .portrait,
                duration: 10,
                petAction: .standingWagTail,
                thumbnailURL: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=cute%20pet%20standing%20wagging%20tail%20portrait&image_size=portrait_4_3",
                previewURL: nil
            ),
            VideoTemplate(
                name: "坐立舔爪",
                templateDescription: "宠物坐立姿态，摇摆尾巴并舔舐爪子",
                orientation: .portrait,
                duration: 10,
                petAction: .sittingLickPaw,
                thumbnailURL: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=cute%20pet%20sitting%20licking%20paw%20portrait&image_size=portrait_4_3",
                previewURL: nil
            ),
            VideoTemplate(
                name: "横屏站立",
                templateDescription: "宠物站立姿态，摇摆尾巴并轻摇头部（横屏版）",
                orientation: .landscape,
                duration: 10,
                petAction: .standingWagTail,
                thumbnailURL: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=cute%20pet%20standing%20wagging%20tail%20landscape&image_size=landscape_16_9",
                previewURL: nil
            ),
            VideoTemplate(
                name: "横屏坐立",
                templateDescription: "宠物坐立姿态，摇摆尾巴并舔舐爪子（横屏版）",
                orientation: .landscape,
                duration: 10,
                petAction: .sittingLickPaw,
                thumbnailURL: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=cute%20pet%20sitting%20licking%20paw%20landscape&image_size=landscape_16_9",
                previewURL: nil
            )
        ]
    }
    
    /// 根据方向筛选模板
    func getTemplates(for orientation: VideoOrientation) -> [VideoTemplate] {
        return getAvailableTemplates().filter { $0.orientation == orientation }
    }
    
    /// 根据动作筛选模板
    func getTemplates(for action: PetAction) -> [VideoTemplate] {
        return getAvailableTemplates().filter { $0.petAction == action }
    }
    
    /// 获取默认模板
    func getDefaultTemplate() -> VideoTemplate {
        return getAvailableTemplates().first!
    }
    
    /// 根据ID获取模板
    func getTemplate(by id: String) -> VideoTemplate? {
        return getAvailableTemplates().first { $0.id.uuidString == id }
    }
}

// 固定模板视频生成服务
class FixedTemplateVideoService: ObservableObject {
    static let shared = FixedTemplateVideoService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private init() {}
    
    /// 使用固定模板生成视频
    func generateVideo(
        with image: UIImage,
        template: VideoTemplate,
        userID: String
    ) async throws -> String {
        print("🎬 [FixedTemplate] 开始使用固定模板生成视频")
        print("📋 [FixedTemplate] 模板信息: \(template.name)")
        print("📐 [FixedTemplate] 视频方向: \(template.orientation.displayName)")
        print("🎭 [FixedTemplate] 宠物动作: \(template.petAction.displayName)")
        print("⏱️ [FixedTemplate] 视频时长: \(template.duration)秒")
        
        // 模拟视频生成过程
        let taskId = UUID().uuidString
        print("🆔 [FixedTemplate] 生成任务ID: \(taskId)")
        
        // 这里可以集成实际的视频生成API
        // 目前返回模拟的任务ID
        return taskId
    }
    
    /// 查询固定模板视频生成状态
    func queryGenerationStatus(taskId: String) async throws -> TemplateVideoStatusResponse {
        print("🔍 [FixedTemplate] 查询任务状态: \(taskId)")
        
        // 模拟查询过程
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
        
        // 模拟成功响应
        let response = TemplateVideoStatusResponse(
            taskId: taskId,
            status: "SUCCEEDED",
            progress: 100,
            resultURL: "https://example.com/generated_video_\(taskId).mp4",
            errorMessage: nil
        )
        
        print("✅ [FixedTemplate] 任务完成，视频URL: \(response.resultURL ?? "无")")
        return response
    }
    
    /// 生成视频提示词
    private func generatePrompt(for template: VideoTemplate, with imageDescription: String = "") -> String {
        let basePrompt = "Generate a \(template.duration)-second video in \(template.orientation.rawValue) orientation"
        let actionPrompt = "Pet action: \(template.petAction.displayName)"
        let keywordsPrompt = "Keywords: \(template.petAction.promptKeywords.joined(separator: ", "))"
        
        var fullPrompt = [basePrompt, actionPrompt, keywordsPrompt]
        
        if !imageDescription.isEmpty {
            fullPrompt.append("Image context: \(imageDescription)")
        }
        
        return fullPrompt.joined(separator: ". ")
    }
}

// 模板视频状态响应
struct TemplateVideoStatusResponse {
    let taskId: String
    let status: String
    let progress: Int
    let resultURL: String?
    let errorMessage: String?
    
    var isCompleted: Bool {
        return status == "SUCCEEDED"
    }
    
    var isFailed: Bool {
        return status == "FAILED"
    }
    
    var isProcessing: Bool {
        return status == "PROCESSING" || status == "PENDING"
    }
}