//
//  VideoTemplate.swift
//  test
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
class VideoTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    var orientation: VideoOrientation
    var duration: Int // 秒数
    var petAction: PetAction
    var thumbnailURL: String?
    var previewURL: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        templateDescription: String,
        orientation: VideoOrientation,
        duration: Int = 10,
        petAction: PetAction,
        thumbnailURL: String? = nil,
        previewURL: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.templateDescription = templateDescription
        self.orientation = orientation
        self.duration = duration
        self.petAction = petAction
        self.thumbnailURL = thumbnailURL
        self.previewURL = previewURL
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum VideoOrientation: String, CaseIterable, Codable {
    case portrait = "portrait"
    case landscape = "landscape"
    
    var displayName: String {
        switch self {
        case .portrait:
            return "竖屏"
        case .landscape:
            return "横屏"
        }
    }
    
    var aspectRatio: Double {
        switch self {
        case .portrait:
            return 9.0 / 16.0
        case .landscape:
            return 16.0 / 9.0
        }
    }
}

enum PetAction: String, CaseIterable, Codable {
    case standingWagTail = "standing_wag_tail"
    case sittingLickPaw = "sitting_lick_paw"
    
    var displayName: String {
        switch self {
        case .standingWagTail:
            return "站立（摇尾巴摇头）"
        case .sittingLickPaw:
            return "坐立（摇尾巴舔爪子）"
        }
    }
    
    var description: String {
        switch self {
        case .standingWagTail:
            return "宠物站立姿态，摇摆尾巴并轻摇头部，展现活泼可爱的一面"
        case .sittingLickPaw:
            return "宠物坐立姿态，摇摆尾巴并舔舐爪子，展现温顺乖巧的一面"
        }
    }
    
    var promptKeywords: [String] {
        switch self {
        case .standingWagTail:
            return ["standing", "wagging tail", "head movement", "playful", "energetic"]
        case .sittingLickPaw:
            return ["sitting", "wagging tail", "licking paw", "gentle", "calm"]
        }
    }
}

// 扩展VideoGeneration模型以支持模板
extension VideoGeneration {
    var selectedTemplate: VideoTemplate? {
        get {
            // 这里可以通过templateId从数据库获取模板
            return nil
        }
        set {
            // 设置模板ID
            if let template = newValue {
                self.templateId = template.id.uuidString
            } else {
                self.templateId = nil
            }
        }
    }
    
    var templateId: String? {
        get {
            guard let metadata = self.metadata,
                  let data = try? JSONSerialization.data(withJSONObject: metadata),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return dict["templateId"] as? String
        }
        set {
            var dict: [String: Any] = [:]
            if let metadata = self.metadata,
               let data = try? JSONSerialization.data(withJSONObject: metadata),
               let existingDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                dict = existingDict
            }
            dict["templateId"] = newValue
            if let data = try? JSONSerialization.data(withJSONObject: dict) {
                self.metadata = data
            }
        }
    }
}