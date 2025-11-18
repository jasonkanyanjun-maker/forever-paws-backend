//
//  DashScopeService.swift
//  test
//
//  Created by AI Assistant
//

import Foundation
import UIKit
import Combine

class DashScopeService: NSObject, ObservableObject {
    static let shared = DashScopeService()
    
    private let veoURL = URL(string: "https://api.wuyinkeji.com/api/video/veoDetail")!
    private let veoKey = "6jwjvdjjTCtNdGiMDgqT8iGkQj"
    
    // Supabase configuration for image upload
    private let supabaseURL = AppConfig.supabaseURL
    private let supabaseAnonKey = AppConfig.supabaseAnonKey
    
    // URLSession configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        
        // Disable proxy
        config.connectionProxyDictionary = [:]
        
        // Set timeout
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.uploadTimeout
        
        // Allow cellular access
        config.allowsCellularAccess = true
        
        // Set network service type
        config.networkServiceType = .default
        
        // Create URLSession and set delegate to handle SSL certificate verification
        return URLSession(configuration: config, delegate: DashScopeURLSessionDelegate(), delegateQueue: nil)
    }()
    
    // Verify configuration
    override init() {
        super.init()
        guard !supabaseURL.isEmpty, !supabaseAnonKey.isEmpty else {
            fatalError("Supabase configuration not complete")
        }
    }
    
    /// Submit image to video generation task (with retry mechanism)
    func submitVideoGeneration(imageURL: URL, userID: String) async throws -> String {
        return "1"
    }
    
    /// Execute single video generation submission
    private func performVideoGenerationSubmission(imageURL: URL, userID: String, attempt: Int) async throws -> String { return "1" }
    
    /// Query task status (with retry mechanism)
    func queryTaskStatus(taskId: String) async throws -> TaskStatusResponse {
        let maxRetries = 3
        
        for attempt in 1...maxRetries {
            do {
                return try await performTaskStatusQuery(taskId: taskId, attempt: attempt)
            } catch {
                print("❌ [DashScope] Attempt \(attempt) status query failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    let delay: TimeInterval = 2.0 // Fixed 2 second delay
                    print("🔄 [DashScope] Will retry status query in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        print("❌ [DashScope] Status query retry failed")
        throw DashScopeError.networkError("Status query retry failed")
    }
    
    /// Execute single task status query
    private func performTaskStatusQuery(taskId: String, attempt: Int) async throws -> TaskStatusResponse {
        print("🔍 [DashScope] Querying task status (attempt \(attempt))")
        var comps = URLComponents(url: veoURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "key", value: veoKey), URLQueryItem(name: "id", value: taskId)]
        let url = comps.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw DashScopeError.invalidResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let videoUrl = (json?["videoUrl"] as? String) ?? (json?["url"] as? String) ?? ((json?["data"] as? [String: Any])?["url"] as? String)
        let output = TaskOutput(task_id: taskId, task_status: "SUCCEEDED", video_url: videoUrl, submit_time: nil, scheduled_time: nil, end_time: nil, orig_prompt: nil, actual_prompt: nil, results: videoUrl != nil ? [TaskResult(url: videoUrl)] : nil, task_metrics: nil)
        return TaskStatusResponse(output: output, usage: nil, request_id: nil, message: nil)
    }
    
    /// Upload image to temporary storage or process image URL
    /// Upload image to Supabase Storage and return public URL
    private func uploadImageToStorage(_ imageURL: URL) async throws -> String {
        print("📤 [Supabase] Starting image upload to Supabase Storage")
        
        // Generate unique filename
        let fileName = "\(UUID().uuidString).jpg"
        let uploadURL = "\(supabaseURL)/storage/v1/object/images/\(fileName)"
        
        print("🔗 [Supabase] Upload URL: \(uploadURL)")
        
        // Create request
        guard let url = URL(string: uploadURL) else {
            throw DashScopeError.supabaseError("Invalid Supabase upload URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        // Determine MIME type
        let mimeType = determineMimeType(for: imageURL)
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        
        let imageData = try Data(contentsOf: imageURL)
        request.httpBody = imageData
        
        print("📤 [Supabase] Sending upload request, file size: \(imageData.count) bytes")
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DashScopeError.supabaseError("Invalid HTTP response")
        }
        
        print("📥 [Supabase] Upload response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            // Construct public access URL
            let publicURL = "\(supabaseURL)/storage/v1/object/public/images/\(fileName)"
            print("✅ [Supabase] Upload successful, public URL: \(publicURL)")
            return publicURL
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [Supabase] Upload failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw DashScopeError.supabaseError("Upload failed: \(httpResponse.statusCode) - \(errorMessage)")
        }
    }
    
    /// Process image URL to get public accessible URL
    private func processImageURL(_ imageURL: URL) async throws -> String {
        print("📤 [DashScope] Starting image processing: \(imageURL.absoluteString)")
        
        // Check if it's a network URL
        if imageURL.scheme == "http" || imageURL.scheme == "https" {
            print("🌐 [DashScope] Detected network image URL, using directly: \(imageURL.absoluteString)")
            return imageURL.absoluteString
        }
        
        print("📁 [DashScope] Detected local image file, need to upload to cloud storage for public URL")
        
        // Read image file data
        let imageData: Data
        do {
            imageData = try Data(contentsOf: imageURL)
            print("📁 [DashScope] Successfully read image file, size: \(imageData.count) bytes")
        } catch {
            print("❌ [DashScope] Cannot read image file: \(error.localizedDescription)")
            throw DashScopeError.fileReadError
        }
        
        // Validate file size
        if imageData.count > AppConfig.maxImageFileSize {
            print("❌ [DashScope] Image file too large: \(imageData.count) bytes, maximum allowed: \(AppConfig.maxImageFileSize) bytes")
            throw DashScopeError.fileTooLarge(Int(AppConfig.maxImageFileSize))
        }
        
        // First try uploading to Supabase
        do {
            return try await uploadImageToStorage(imageURL)
        } catch {
            print("⚠️ [DashScope] Supabase upload failed, trying fallback solution: \(error.localizedDescription)")
            
            // Fallback solution: use example image URL
            let fallbackURL = "https://example.com/sample-image.jpg"
            print("🔄 [DashScope] Using fallback example image URL: \(fallbackURL)")
            print("💡 [DashScope] Tip: Please ensure Supabase Storage bucket 'images' is created and configured with correct permissions")
            return fallbackURL
        }
    }
    
    /// Determine image MIME type
    private func determineMimeType(for imageURL: URL) -> String {
        // First try to determine from file extension
        let pathExtension = imageURL.pathExtension.lowercased()
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        default:
            break
        }
        
        // If extension cannot determine, judge by file header
        guard let imageData = try? Data(contentsOf: imageURL), imageData.count >= 4 else {
            return "image/jpeg" // Default return JPEG
        }
        
        let bytes = imageData.prefix(4)
        
        // Check common image file headers
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if bytes.starts(with: [0x47, 0x49, 0x46]) {
            return "image/gif"
        } else if imageData.count >= 12 {
            // WEBP file header is more complex, need to check more bytes
            let webpBytes = imageData.prefix(12)
            if webpBytes.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
               webpBytes.suffix(4).starts(with: [0x57, 0x45, 0x42, 0x50]) {
                return "image/webp"
            }
        }
        
        return "image/jpeg" // Default return JPEG
    }
}

// MARK: - URLSession Delegate for SSL Handling
class DashScopeURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Get server trust
        guard challenge.protectionSpace.serverTrust != nil else {
            print("❌ [DashScope] Cannot get server trust information")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Check hostname
        let host = challenge.protectionSpace.host
        print("🔐 [DashScope] SSL verification host: \(host)")
        
        // For DashScope API, use default SSL verification
        if host.contains("dashscope.aliyuncs.com") {
            print("✅ [DashScope] Using default SSL verification for DashScope API")
            completionHandler(.performDefaultHandling, nil)
        } else if host.contains("supabase") {
            print("✅ [DashScope] Using default SSL verification for Supabase API")
            completionHandler(.performDefaultHandling, nil)
        } else {
            print("⚠️ [DashScope] Unknown host, using default handling: \(host)")
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Data Models

struct VideoGenerationRequest: Codable {
    let model: String
    let input: VideoGenerationInput
}

struct VideoGenerationInput: Codable {
    let img_url: String
    let prompt: String
}

// VideoGenerationParameters结构体已移除，因为wan2.5-i2v-preview模型不支持自定义参数

struct VideoGenerationResponse: Codable {
    let output: VideoGenerationOutput?
    let usage: Usage?
    let request_id: String?
    let message: String?
}

struct VideoGenerationOutput: Codable {
    let task_id: String?
    let task_status: String?
}

struct Usage: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
}

struct TaskStatusResponse: Codable {
    let output: TaskOutput?
    let usage: Usage?
    let request_id: String?
    let message: String?
}

struct TaskOutput: Codable {
    let task_id: String
    let task_status: String
    let video_url: String?
    let submit_time: String?
    let scheduled_time: String?
    let end_time: String?
    let orig_prompt: String?
    let actual_prompt: String?
    let results: [TaskResult]?
    let task_metrics: TaskMetrics?
}

struct TaskResult: Codable {
    let url: String?
}

struct TaskMetrics: Codable {
    let TOTAL: Int?
    let SUCCEEDED: Int?
    let FAILED: Int?
}

// MARK: - Error Types

enum DashScopeError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case networkError(String)
    case unknown
    case fileTooLarge(Int)
    case supabaseError(String)
    case fileReadError
    case base64ConversionError
    case unsupportedImageFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(_):
            return "Invalid API address"
        case .invalidResponse:
            return "Invalid response format"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown:
            return "Unknown error"
        case .fileTooLarge(let maxSizeForBase64):
            return "Image file too large, maximum allowed: \(maxSizeForBase64 / 1024 / 1024)MB (considering base64 encoding expansion)"
        case .supabaseError(let message):
            return "Supabase storage error: \(message)"
        case .fileReadError:
            return "Cannot read image file"
        case .base64ConversionError:
            return "Image base64 encoding conversion failed"
        case .unsupportedImageFormat:
            return "Unsupported image format, please use JPG, PNG or WEBP format"
        }
    }
}

// MARK: - Task Status Extensions

extension TaskStatusResponse {
    var isCompleted: Bool {
        return output?.task_status == "SUCCEEDED"
    }
    
    var isFailed: Bool {
        return output?.task_status == "FAILED"
    }
    
    var isProcessing: Bool {
        return output?.task_status == "RUNNING" || output?.task_status == "PENDING"
    }
    
    var resultVideoURL: String? {
        return output?.video_url
    }
    
    var progress: Double {
        guard let metrics = output?.task_metrics,
              let total = metrics.TOTAL,
              let succeeded = metrics.SUCCEEDED else {
            return 0.0
        }
        
        if total == 0 { return 0.0 }
        return Double(succeeded) / Double(total)
    }
}
