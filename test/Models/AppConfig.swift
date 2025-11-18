//
//  AppConfig.swift
//  test
//
//  Created by AI Assistant
//

import Foundation

struct AppConfig {
    // 阿里云DashScope配置
    static let dashscopeAPIKey = "sk-381082d57c9a49b6becf6843505664d8"
    static let dashscopeUserID = "1817635094148618"
    static let videoGenerationProvider = "dashscope"
    static let videoGenerationModel = "wan2.5-i2v-preview"
    
    // API端点
    static let dashscopeBaseURL = "https://dashscope.aliyuncs.com/api/v1"
    static let videoGenerationEndpoint = "/services/aigc/video-generation/video-synthesis"
    static let taskStatusEndpoint = "/tasks"
    
    // Supabase配置
    static let supabaseURL: String = "https://gjpiwsehobfupdpixnuf.supabase.co"
    static let supabaseAnonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqcGl3c2Vob2JmdXBkcGl4bnVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2MjMyNzksImV4cCI6MjA3NTE5OTI3OX0.TLhHHhJ4g9uOE_Et2M_aiGv8-T30Wl9ARIAQMvhGzmw"
    static let supabaseServiceRoleKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqcGl3c2Vob2JmdXBkcGl4bnVmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTYyMzI3OSwiZXhwIjoyMDc1MTk5Mjc5fQ.Ny0DavHcoGxExCaAqYR4mymF1oQyiPDWdqpNLu-iQ3g"
    
    // Supabase存储配置
    static let supabaseStorageBucket: String = "videos"
    static let supabaseStorageFolder: String = "temp-uploads"
    
    // 应用设置
    static let maxImageFileSize: Int64 = 50 * 1024 * 1024 // 50MB
    static let supportedImageFormats = ["jpg", "jpeg", "png", "heic", "webp"]
    static let generatedVideoDuration: Double = 3.0 // 3秒
    
    // 网络配置
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 120.0
}

// MARK: - 环境变量管理
extension AppConfig {
    static func loadEnvironmentVariables() {
        // 在实际应用中，这些值应该从环境变量或配置文件中读取
        // 这里为了演示直接使用提供的值
        print("Environment variables loaded:")
        print("DASHSCOPE_API_KEY: \(dashscopeAPIKey.prefix(10))...")
        print("DASHSCOPE_USER_ID: \(dashscopeUserID)")
        print("VIDEO_GENERATION_PROVIDER: \(videoGenerationProvider)")
        print("VIDEO_GENERATION_MODEL: \(videoGenerationModel)")
    }
    
    static func validateConfiguration() -> Bool {
        guard !dashscopeAPIKey.isEmpty,
              !dashscopeUserID.isEmpty,
              !videoGenerationProvider.isEmpty,
              !videoGenerationModel.isEmpty else {
            print("❌ DashScope configuration is incomplete")
            return false
        }
        
        guard !supabaseURL.isEmpty,
              !supabaseAnonKey.isEmpty,
              !supabaseServiceRoleKey.isEmpty else {
            print("❌ Supabase configuration is incomplete")
            return false
        }
        
        print("✅ DashScope and Supabase configuration is valid")
        return true
    }
}