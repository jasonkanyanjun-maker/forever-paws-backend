import Foundation
import SwiftUI
import SwiftData
import AuthenticationServices
import Combine
import ObjectiveC

// MARK: - Backend Response Models
struct BackendAuthResponse: Codable {
    let code: Int
    let message: String
    let data: BackendAuthData
}

struct BackendAuthData: Codable {
    let user: BackendUser
    let access_token: String
    let expires_in: Int
}

struct BackendUser: Codable {
    let id: String
    let email: String
    let display_name: String?
    let avatar_url: String?
    let provider: String
    let created_at: String
    let updated_at: String
}

// MARK: - User Profile Model
struct SupabaseUser: Codable {
    let id: UUID
    let email: String?
    let displayName: String?
    let avatarUrl: String?
    let provider: String?
    let providerId: String?
    let videoCredits: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, provider, videoCredits = "video_credits"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case providerId = "provider_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Supabase Service
struct EmailValidationResult {
    let isValid: Bool
    let message: String
}

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    @Published var currentUser: SupabaseUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let client: SupabaseClient
    var currentAccessToken: String?
    // 防止重复触发自动登录检查的节流与状态标记
    private var lastAutoLoginCheckTime: Date?
    private var isCheckingAutoLogin: Bool = false
    
    // 使用 APIConfig 获取动态 URL
    private let apiConfig = APIConfig.shared
    
    private init() {
        self.client = SupabaseClient(url: SupabaseConfig.url, key: SupabaseConfig.anonKey)
    }
    
    // MARK: - Simulator Detection
    var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Auto Login Check
    func checkAutoLogin() async {
        print("🔍 [SupabaseService] Checking auto login...")
        
        // 节流：避免短时间内重复触发或并发执行
        var shouldSkip = false
        await MainActor.run {
            if isCheckingAutoLogin { shouldSkip = true }
            if let last = lastAutoLoginCheckTime, Date().timeIntervalSince(last) < 2 {
                shouldSkip = true
            }
            if !shouldSkip {
                isCheckingAutoLogin = true
                lastAutoLoginCheckTime = Date()
            }
        }
        if shouldSkip {
            print("⏱️ [SupabaseService] Auto login check throttled or already running")
            return
        }
        
        // Check if auto login is enabled
        guard UserDefaults.standard.bool(forKey: "autoLogin") else {
            print("🔍 Auto login not enabled")
            
            // 即使autoLogin未启用，也检查是否有记住的凭据
            if UserDefaults.standard.bool(forKey: "rememberCredentials") {
                print("🔍 Remember credentials is enabled, attempting credential-based login")
                await attemptCredentialBasedLogin()
            }
            await MainActor.run { isCheckingAutoLogin = false }
            return
        }
        
        // Check if we have a stored token
        guard let token = KeychainService.shared.loadAccessToken() else {
            print("🔍 No stored access token found")
            UserDefaults.standard.removeObject(forKey: "autoLogin")
            
            // 如果没有token但有记住的凭据，尝试使用凭据登录
            if UserDefaults.standard.bool(forKey: "rememberCredentials") {
                print("🔍 No token but remember credentials enabled, attempting credential-based login")
                await attemptCredentialBasedLogin()
            }
            await MainActor.run { isCheckingAutoLogin = false }
            return
        }
        
        print("🔍 Found stored access token, attempting auto login")
        
        await MainActor.run {
            isLoading = true
        }
        
        // Validate token with backend
        do {
            let url = URL(string: "\(apiConfig.authBaseURL)/validate")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("🔧 [SupabaseService] Validating token with backend...")
            
            // 使用自定义URLSession配置来处理SSL问题，并兼容 VPN
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            // 禁用系统代理，避免 VPN/代理环境对 TLS 的干扰
            config.connectionProxyDictionary = [:]
            // 明确禁用多路径，避免与 VPN 的冲突
#if os(iOS)
            config.multipathServiceType = .none
#endif

            // 设置TLS配置
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            // 根据 VPN 状态调整连接头：VPN 下使用 Connection: close 避免持久连接导致握手失败
            let vpnActive = NetworkUtils.isVPNActive()
            config.httpAdditionalHeaders = [
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": vpnActive ? "close" : "keep-alive"
            ]
            // 适配 VPN/受限网络，提高握手成功率
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            
            // 在DEBUG模式下使用自定义delegate绕过SSL证书验证
            #if DEBUG
            let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            // 首次请求，若遇到 TLS/连接错误，进行一次短超时重试
            var data: Data
            var response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let urlError as URLError {
                switch urlError.code {
                case .secureConnectionFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                    print("⚠️ [SupabaseService] Login request encountered TLS/connection error: \(urlError). Retrying with shorter timeout...")
                    let retryConfig = URLSessionConfiguration.default
                    retryConfig.timeoutIntervalForRequest = 15.0
                    retryConfig.timeoutIntervalForResource = 30.0
                    retryConfig.waitsForConnectivity = true
                    retryConfig.allowsCellularAccess = true
                    retryConfig.connectionProxyDictionary = [:]
                    retryConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                    // 在重试阶段只使用 TLS1.2，提高在 VPN/代理环境下的握手成功率
                    retryConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                    #if DEBUG
                    let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                    #else
                    let retrySession = URLSession(configuration: retryConfig)
                    #endif
                    (data, response) = try await retrySession.data(for: request)
                default:
                    throw urlError
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            print("🔧 [SupabaseService] Token validation response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(BackendAuthResponse.self, from: data)
                
                await MainActor.run {
                    // 设置token和用户信息
                    currentAccessToken = token
                    currentUser = SupabaseUser(
                        id: UUID(uuidString: authResponse.data.user.id) ?? UUID(),
                        email: authResponse.data.user.email,
                        displayName: authResponse.data.user.display_name,
                        avatarUrl: authResponse.data.user.avatar_url,
                        provider: authResponse.data.user.provider,
                        providerId: nil,
                        videoCredits: 0,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    isAuthenticated = true
                    isLoading = false
                    errorMessage = nil
                }
                
                print("✅ Auto login successful for user: \(authResponse.data.user.email)")
                
                // 自动登录成功后，先清理本地数据，然后触发数据同步
                Task {
                    // 清理之前用户的本地数据
                    await clearLocalUserDataOnLogin()
                    // 同步当前用户的数据
                    await DataSyncService.shared.syncUserData()
                }
                await MainActor.run { isCheckingAutoLogin = false }
            } else {
                // Token invalid, try credential-based login if remember credentials is enabled
                print("❌ Token validation failed with status: \(httpResponse.statusCode)")
                _ = KeychainService.shared.deleteAccessToken()
                UserDefaults.standard.removeObject(forKey: "autoLogin")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "自动登录失败：登录凭证无效或已过期，请重新登录"
                }
                
                // 如果token失效但用户选择了记住凭据，尝试使用凭据重新登录
                if UserDefaults.standard.bool(forKey: "rememberCredentials") {
                    print("🔍 Token invalid but remember credentials enabled, attempting credential-based login")
                    await attemptCredentialBasedLogin()
                } else {
                    await MainActor.run {
                        isAuthenticated = false
                        currentUser = nil
                        currentAccessToken = nil
                    }
                    print("❌ Auto login failed - token invalid, no remembered credentials")
                }
                await MainActor.run { isCheckingAutoLogin = false }
            }
        } catch {
            print("❌ Auto login error: \(error)")
            
            // Clear stored token on error
            _ = KeychainService.shared.deleteAccessToken()
            UserDefaults.standard.removeObject(forKey: "autoLogin")
            
            await MainActor.run {
                isLoading = false
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "自动登录失败：网络不可用"
                    case .timedOut:
                        errorMessage = "自动登录失败：请求超时"
                    case .cannotConnectToHost:
                        errorMessage = "自动登录失败：无法连接服务器"
                    case .networkConnectionLost:
                        errorMessage = "自动登录失败：网络连接中断"
                    default:
                        errorMessage = "自动登录网络错误：\(urlError.localizedDescription)"
                    }
                } else {
                    errorMessage = "自动登录失败：\(error.localizedDescription)"
                }
            }
            
            // 如果token验证出错但用户选择了记住凭据，尝试使用凭据重新登录
            if UserDefaults.standard.bool(forKey: "rememberCredentials") {
                print("🔍 Token validation error but remember credentials enabled, attempting credential-based login")
                await attemptCredentialBasedLogin()
            } else {
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                    currentAccessToken = nil
                }
            }
            await MainActor.run { isCheckingAutoLogin = false }
        }
    }
    
    // MARK: - Attempt Credential Based Login
    private func attemptCredentialBasedLogin() async {
        print("🔧 [SupabaseService] Attempting credential-based login...")
        
        let credentials = KeychainService.shared.loadCredentials()
        guard let email = credentials.email, let password = credentials.password else {
            print("❌ No saved credentials found, clearing remember credentials flag")
            UserDefaults.standard.removeObject(forKey: "rememberCredentials")
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                currentAccessToken = nil
                errorMessage = "未找到已保存的账号密码"
            }
            return
        }
        
        print("🔧 [SupabaseService] Found saved credentials for: \(email)")
        
        do {
            // 使用保存的凭据静默登录
            try await signInWithEmail(email, password: password, rememberCredentials: true)
            print("✅ Credential-based login successful")
        } catch {
            print("❌ Credential-based login failed: \(error)")
            // 凭据登录失败，清除保存的凭据
            _ = KeychainService.shared.deleteCredentials()
            UserDefaults.standard.removeObject(forKey: "rememberCredentials")
            
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                currentAccessToken = nil
                isLoading = false
                errorMessage = "凭据登录失败：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Skip Login for Simulator
    func skipLoginForSimulator() async {
        guard isRunningInSimulator else {
            print("Skip login is only available in simulator")
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Create mock user data
        let mockUser = SupabaseUser(
            id: UUID(),
            email: "simulator@test.com",
            displayName: "Simulator User",
            avatarUrl: nil,
            provider: "simulator",
            providerId: "simulator_user",
            videoCredits: 10,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await MainActor.run {
            self.currentUser = mockUser
            self.isAuthenticated = true
            self.isLoading = false
        }
        
        print("✅ Simulator login successful - User: \(mockUser.displayName ?? "Unknown")")
    }
    
    // MARK: - Email Authentication
    func signInWithEmail(_ email: String, password: String, rememberCredentials: Bool = false) async throws {
        print("🔧 [SupabaseService] Starting sign in process for email: \(email)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 验证邮箱格式
        let validationResult = validateEmailFormat(email)
        if !validationResult.isValid {
            print("❌ [SupabaseService] Email validation failed: \(validationResult.message)")
            await MainActor.run {
                isLoading = false
                errorMessage = validationResult.message
            }
            throw SupabaseError.invalidEmail
        }
        
        print("✅ [SupabaseService] Input validation passed")
        
        do {
            print("🔧 [SupabaseService] Calling backend API for login...")
            
            // 使用 APIConfig 获取动态 URL
            let url = URL(string: "\(apiConfig.authBaseURL)/login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = [
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🔧 [SupabaseService] Login request URL: \(url)")
            print("🔧 [SupabaseService] Login request body: \(requestBody)")
            
            // 使用自定义URLSession配置来处理SSL问题
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            
            // 设置TLS配置
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            
            // 在DEBUG模式下使用自定义delegate绕过SSL证书验证
            #if DEBUG
            let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            print("🔧 [SupabaseService] Login response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                // 解析响应
                let authResponse = try JSONDecoder().decode(BackendAuthResponse.self, from: data)
                print("✅ [SupabaseService] Backend login successful")
                print("✅ [SupabaseService] User ID: \(authResponse.data.user.id)")
                print("✅ [SupabaseService] Access token received: \(authResponse.data.access_token.prefix(20))...")
                
                // 设置认证状态
                currentAccessToken = authResponse.data.access_token
                
                // 确保token同步到Keychain
                let tokenSaved = KeychainService.shared.saveAccessToken(authResponse.data.access_token)
                print("✅ [SupabaseService] Token synced to Keychain: \(tokenSaved)")
                
                // Save credentials if remember option is selected
                if rememberCredentials {
                    let _ = KeychainService.shared.saveCredentials(email: email, password: password)
                    UserDefaults.standard.set(true, forKey: "rememberCredentials")
                    print("✅ [SupabaseService] Credentials saved for auto-login")
                }
                
                await MainActor.run {
                    currentUser = SupabaseUser(
                        id: UUID(uuidString: authResponse.data.user.id) ?? UUID(),
                        email: authResponse.data.user.email,
                        displayName: authResponse.data.user.display_name,
                        avatarUrl: authResponse.data.user.avatar_url,
                        provider: authResponse.data.user.provider,
                        providerId: nil,
                        videoCredits: 0,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    isAuthenticated = true
                    isLoading = false
                    errorMessage = nil
                }
                
                print("✅ [SupabaseService] Login completed successfully")
                
                // 登录成功后，先清理本地数据，然后触发数据同步
                Task {
                    // 清理之前用户的本地数据
                    await clearLocalUserDataOnLogin()
                    // 同步当前用户的数据
                    await DataSyncService.shared.syncUserData()
                }
            } else if [404, 500, 502, 503].contains(httpResponse.statusCode) {
                // 后端不可用或错误，尝试回退为直接 Supabase 登录
                print("⚠️ [SupabaseService] Backend login status=\(httpResponse.statusCode). Falling back to direct Supabase login...")
                let supaAuth = try await client.signInWithEmail(email: email, password: password)
                guard let accessToken = supaAuth.accessToken else {
                    print("❌ [SupabaseService] Supabase fallback login did not return access token")
                    throw SupabaseError.signInFailed
                }
                currentAccessToken = accessToken
                let tokenSaved = KeychainService.shared.saveAccessToken(accessToken)
                print("✅ [SupabaseService] Supabase token saved: \(tokenSaved)")
                if rememberCredentials {
                    let _ = KeychainService.shared.saveCredentials(email: email, password: password)
                    UserDefaults.standard.set(true, forKey: "rememberCredentials")
                }
                await MainActor.run {
                    currentUser = SupabaseUser(
                        id: UUID(uuidString: supaAuth.user.id) ?? UUID(),
                        email: supaAuth.user.email,
                        displayName: supaAuth.user.email?.components(separatedBy: "@").first,
                        avatarUrl: nil,
                        provider: "email",
                        providerId: nil,
                        videoCredits: 0,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    isAuthenticated = true
                    isLoading = false
                    errorMessage = nil
                }
                print("✅ [SupabaseService] Fallback login via Supabase completed")
                Task {
                    await clearLocalUserDataOnLogin()
                    await DataSyncService.shared.syncUserData()
                }
            } else {
                // 处理错误响应
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Login failed"
                print("❌ [SupabaseService] Login failed: \(errorMessage)")
                
                await MainActor.run {
                    isLoading = false
                    self.errorMessage = errorMessage
                }
                throw SupabaseError.signInFailed
            }
        } catch {
            print("❌ [SupabaseService] Network error during login: \(error)")
            // 当出现 TLS/连接错误时，尝试直接调用 Supabase 登录作为回退
            if let urlError = error as? URLError, [.secureConnectionFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost].contains(urlError.code) {
                print("⚠️ [SupabaseService] Login caught URLError=\(urlError.code). Falling back to direct Supabase login...")
                do {
                    let supaAuth = try await client.signInWithEmail(email: email, password: password)
                    guard let accessToken = supaAuth.accessToken else { throw SupabaseError.signInFailed }
                    currentAccessToken = accessToken
                    let tokenSaved = KeychainService.shared.saveAccessToken(accessToken)
                    print("✅ [SupabaseService] Supabase token saved: \(tokenSaved)")
                    await MainActor.run {
                        currentUser = SupabaseUser(
                            id: UUID(uuidString: supaAuth.user.id) ?? UUID(),
                            email: supaAuth.user.email,
                            displayName: supaAuth.user.email?.components(separatedBy: "@").first,
                            avatarUrl: nil,
                            provider: "email",
                            providerId: nil,
                            videoCredits: 0,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        isAuthenticated = true
                        isLoading = false
                        errorMessage = nil
                    }
                    Task {
                        await clearLocalUserDataOnLogin()
                        await DataSyncService.shared.syncUserData()
                    }
                    return
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "登录失败：\(error.localizedDescription)"
                    }
                    throw error
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    // 提供更友好的错误信息
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "网络连接不可用，请检查网络设置"
                        case .timedOut:
                            errorMessage = "连接超时，请稍后重试"
                        case .cannotConnectToHost:
                            errorMessage = "无法连接到服务器，请稍后重试"
                        case .networkConnectionLost:
                            errorMessage = "网络连接中断，请重新连接"
                        case .secureConnectionFailed:
                            errorMessage = "TLS 安全连接失败，请检查网络或尝试关闭代理/VPN"
                        default:
                            errorMessage = "网络错误：\(urlError.localizedDescription)"
                        }
                    } else {
                        errorMessage = "登录失败：\(error.localizedDescription)"
                    }
                }
                throw error
            }
        }
    }

    func signUpWithEmail(_ email: String, password: String, displayName: String? = nil) async throws -> (email: String, password: String) {
        print("🔧 [SupabaseService] Starting sign up process for email: \(email)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 验证邮箱格式
        let validationResult = validateEmailFormat(email)
        if !validationResult.isValid {
            print("❌ [SupabaseService] Email validation failed: \(validationResult.message)")
            await MainActor.run {
                isLoading = false
                errorMessage = validationResult.message
            }
            throw SupabaseError.invalidEmail
        }
        
        print("✅ [SupabaseService] Input validation passed")
        
        do {
            print("🔧 [SupabaseService] Calling backend API for registration...")
            // 调试当前 API 配置
            let configDump = APIConfig.shared.getCurrentConfiguration()
            print("🔎 [SupabaseService] APIConfig: \(configDump)")
            // 尝试健康检查，便于定位网络问题
            Task {
                let ok = await APIConfig.shared.testConnectivity()
                print("🔎 [SupabaseService] Health check: \(ok ? "OK" : "FAILED")")
            }
            
            // 在检测到 VPN/代理环境时优先使用生产后端
            // 保持环境选择由 APIConfig 与设置页控制，不在运行时强制切换生产环境

            // 使用 APIConfig 获取动态 URL，并进行清理以避免尾随逗号/协议问题
            var baseAuthURL = apiConfig.authBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            while baseAuthURL.hasSuffix(",") { baseAuthURL.removeLast() }
            if baseAuthURL.hasPrefix("http://") { baseAuthURL = baseAuthURL.replacingOccurrences(of: "http://", with: "https://") }
            if baseAuthURL.hasSuffix("/") { baseAuthURL.removeLast() }

            // 使用 URLComponents 安全构建注册 URL，避免字符串拼接导致的非法字符
            guard var components = URLComponents(string: baseAuthURL) else {
                throw SupabaseError.invalidURL
            }
            components.path = components.path.hasSuffix("/register") ? components.path : components.path + "/register"
            guard let url = components.url else {
                throw SupabaseError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = [
                "email": email,
                "password": password,
                "display_name": displayName ?? email.components(separatedBy: "@").first ?? "User"
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🔧 [SupabaseService] Registration request URL: \(url)")
            print("🔧 [SupabaseService] Registration request body: \(requestBody)")
            
            // 使用自定义URLSession配置来处理SSL问题，并兼容 VPN
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            // 禁用系统代理，避免 VPN/代理环境对 TLS 的干扰
            config.connectionProxyDictionary = [:]
#if os(iOS)
            config.multipathServiceType = .none
#endif
            
            // 设置TLS配置
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            // 支持到 TLS1.3，避免服务器仅开启 1.3 时握手失败
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            // 允许在受限/昂贵网络（如蜂窝/低速网络）下连接
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            // 根据 VPN 状态调整连接头：VPN 下使用 Connection: close 避免持久连接导致握手失败
            let vpnActiveReg = NetworkUtils.isVPNActive()
            config.httpAdditionalHeaders = [
                // 去掉 br，避免部分 VPN/代理不支持 brotli 导致握手异常
                "Accept-Encoding": "gzip, deflate",
                "Connection": vpnActiveReg ? "close" : "keep-alive"
            ]
            
            // 在DEBUG模式下使用自定义delegate绕过SSL证书验证
            #if DEBUG
            let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            // 首次请求，若遇到 TLS/连接错误，进行一次短超时重试
            var data: Data
            var response: URLResponse
            do {
                // 避免 Cookie 干扰网络握手
                request.httpShouldHandleCookies = false
                (data, response) = try await session.data(for: request)
            } catch let urlError as URLError {
                switch urlError.code {
                case .secureConnectionFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                    print("⚠️ [SupabaseService] Registration request encountered TLS/connection error: \(urlError). Retrying with shorter timeout...")
                    let retryConfig = URLSessionConfiguration.default
                    retryConfig.timeoutIntervalForRequest = 20.0
                    retryConfig.timeoutIntervalForResource = 40.0
                    retryConfig.waitsForConnectivity = true
                    retryConfig.allowsCellularAccess = true
                    retryConfig.connectionProxyDictionary = [:]
                    retryConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                    // 重试阶段支持到 TLS1.3，提升握手兼容性
                    retryConfig.tlsMaximumSupportedProtocolVersion = .TLSv13
                    retryConfig.allowsConstrainedNetworkAccess = true
                    retryConfig.allowsExpensiveNetworkAccess = true
#if os(iOS)
                    retryConfig.multipathServiceType = .none
#endif
                    let vpnRetry = NetworkUtils.isVPNActive()
                    retryConfig.httpAdditionalHeaders = [
                        "Accept-Encoding": "gzip, deflate",
                        "Connection": vpnRetry ? "close" : "keep-alive"
                    ]
                    #if DEBUG
                    let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                    #else
                    let retrySession = URLSession(configuration: retryConfig)
                    #endif
                    request.httpShouldHandleCookies = false
                    (data, response) = try await retrySession.data(for: request)
                default:
                    throw urlError
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            print("🔧 [SupabaseService] Registration response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 201 {
                // 解析响应
                let authResponse = try JSONDecoder().decode(BackendAuthResponse.self, from: data)
                print("✅ [SupabaseService] Backend registration successful")
                print("✅ [SupabaseService] User ID: \(authResponse.data.user.id)")
                print("✅ [SupabaseService] Access token received: \(authResponse.data.access_token.prefix(20))...")
                
                // 设置认证状态
                currentAccessToken = authResponse.data.access_token
                
                // 注册成功后自动保存token和设置自动登录
                let tokenSaved = KeychainService.shared.saveAccessToken(authResponse.data.access_token)
                UserDefaults.standard.set(true, forKey: "autoLogin")
                print("✅ Token saved for auto login after registration: \(tokenSaved)")
                
                await MainActor.run {
                    currentUser = SupabaseUser(
                        id: UUID(uuidString: authResponse.data.user.id) ?? UUID(),
                        email: authResponse.data.user.email,
                        displayName: authResponse.data.user.display_name,
                        avatarUrl: authResponse.data.user.avatar_url,
                        provider: authResponse.data.user.provider,
                        providerId: nil,
                        videoCredits: 0,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    isAuthenticated = true
                    isLoading = false
                    errorMessage = nil
                }
                
                print("✅ [SupabaseService] Registration completed successfully")
                
                // 注册成功后，触发数据同步
                Task {
                    await DataSyncService.shared.syncUserData()
                }
                
                return (email, password)
            } else if [404, 500, 502, 503].contains(httpResponse.statusCode) {
                print("⚠️ [SupabaseService] Backend registration status=\(httpResponse.statusCode). Trying production backend...")
                let prodURL = URL(string: "https://forever-paws-api-production.up.railway.app/api/auth/register")!
                var prodRequest = URLRequest(url: prodURL)
                prodRequest.httpMethod = "POST"
                prodRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let prodBody = [
                    "email": email,
                    "password": password,
                    "display_name": displayName ?? email.components(separatedBy: "@").first ?? "User"
                ]
                prodRequest.httpBody = try JSONSerialization.data(withJSONObject: prodBody)
                let prodConfig = URLSessionConfiguration.ephemeral
                prodConfig.timeoutIntervalForRequest = 35.0
                prodConfig.timeoutIntervalForResource = 70.0
                prodConfig.waitsForConnectivity = true
                prodConfig.allowsCellularAccess = true
                prodConfig.connectionProxyDictionary = [:]
                prodConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                        prodConfig.tlsMaximumSupportedProtocolVersion = .TLSv13
                prodConfig.allowsConstrainedNetworkAccess = true
                prodConfig.allowsExpensiveNetworkAccess = true
                prodConfig.httpMaximumConnectionsPerHost = 1
                prodConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
#if os(iOS)
                prodConfig.multipathServiceType = .none
#endif
                prodConfig.httpAdditionalHeaders = [
                    "Accept-Encoding": "gzip, deflate",
                    "Connection": "close"
                ]
                prodConfig.urlCache = nil
#if DEBUG
                let prodSession = URLSession(configuration: prodConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
#else
                let prodSession = URLSession(configuration: prodConfig)
#endif
                prodRequest.httpShouldHandleCookies = false
                let (prodData, prodResp) = try await prodSession.data(for: prodRequest)
                guard let prodHTTP = prodResp as? HTTPURLResponse else { throw SupabaseError.networkError }
                print("🔧 [SupabaseService] Production registration response status: \(prodHTTP.statusCode)")
                if prodHTTP.statusCode == 201 {
                    let authResponse = try JSONDecoder().decode(BackendAuthResponse.self, from: prodData)
                    currentAccessToken = authResponse.data.access_token
                    let tokenSaved = KeychainService.shared.saveAccessToken(authResponse.data.access_token)
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    print("✅ [SupabaseService] Production signup success, token saved: \(tokenSaved)")
                    await MainActor.run {
                        currentUser = SupabaseUser(
                            id: UUID(uuidString: authResponse.data.user.id) ?? UUID(),
                            email: authResponse.data.user.email,
                            displayName: authResponse.data.user.display_name,
                            avatarUrl: authResponse.data.user.avatar_url,
                            provider: authResponse.data.user.provider,
                            providerId: nil,
                            videoCredits: 0,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        isAuthenticated = true
                        isLoading = false
                        errorMessage = nil
                    }
                    Task { await DataSyncService.shared.syncUserData() }
                    return (email, password)
                }
                print("⚠️ [SupabaseService] Production backend unavailable, falling back to direct Supabase signup...")
                if let host = URL(string: SupabaseConfig.url)?.host {
                    let reachable = await NetworkUtils.pingHTTPS(host: host, path: "/auth/v1/signup", timeout: 3.0)
                    if !reachable {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "注册失败：Supabase 服务当前不可达，请稍后重试或检查网络/VPN设置"
                        }
                        throw SupabaseError.networkError
                    }
                }
                let supaAuth = try await client.signUpWithEmail(email: email, password: password)
                if supaAuth.requiresEmailConfirmation {
                    await MainActor.run {
                        isAuthenticated = false
                        isLoading = false
                        errorMessage = SupabaseError.emailConfirmationRequired(email: email).localizedDescription
                    }
                    return (email, password)
                } else if supaAuth.isImmediateLogin, let accessToken = supaAuth.accessToken {
                    currentAccessToken = accessToken
                    let tokenSaved = KeychainService.shared.saveAccessToken(accessToken)
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    print("✅ [SupabaseService] Supabase signup immediate login, token saved: \(tokenSaved)")
                    await MainActor.run {
                        currentUser = SupabaseUser(
                            id: UUID(uuidString: supaAuth.user.id) ?? UUID(),
                            email: supaAuth.user.email,
                            displayName: displayName ?? supaAuth.user.email?.components(separatedBy: "@").first,
                            avatarUrl: nil,
                            provider: "email",
                            providerId: nil,
                            videoCredits: 0,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        isAuthenticated = true
                        isLoading = false
                        errorMessage = nil
                    }
                    Task { await DataSyncService.shared.syncUserData() }
                    return (email, password)
                }
                throw SupabaseError.signUpFailed
            } else {
                // 处理错误响应
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Registration failed"
                print("❌ [SupabaseService] Registration failed: \(errorMessage)")
                
                await MainActor.run {
                    isLoading = false
                    self.errorMessage = errorMessage
                }
                throw SupabaseError.signUpFailed
            }
        } catch {
            print("❌ [SupabaseService] Network error during registration: \(error)")
            let prodURL = URL(string: "https://forever-paws-api-production.up.railway.app/api/auth/register")!
            var prodRequest = URLRequest(url: prodURL)
            prodRequest.httpMethod = "POST"
            prodRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let prodBody = [
                "email": email,
                "password": password,
                "display_name": displayName ?? email.components(separatedBy: "@").first ?? "User"
            ]
            prodRequest.httpBody = try JSONSerialization.data(withJSONObject: prodBody)
            let prodConfig = URLSessionConfiguration.ephemeral
            prodConfig.timeoutIntervalForRequest = 35.0
            prodConfig.timeoutIntervalForResource = 70.0
            prodConfig.waitsForConnectivity = true
            prodConfig.allowsCellularAccess = true
            prodConfig.connectionProxyDictionary = [:]
            prodConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
            prodConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
            prodConfig.allowsConstrainedNetworkAccess = true
            prodConfig.allowsExpensiveNetworkAccess = true
            prodConfig.httpMaximumConnectionsPerHost = 1
            prodConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
#if os(iOS)
            prodConfig.multipathServiceType = .none
#endif
            prodConfig.httpAdditionalHeaders = [
                "Accept-Encoding": "gzip, deflate",
                "Connection": "close"
            ]
            prodConfig.urlCache = nil
#if DEBUG
            let prodSession = URLSession(configuration: prodConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
#else
            let prodSession = URLSession(configuration: prodConfig)
#endif
            do {
                prodRequest.httpShouldHandleCookies = false
                let (prodData, prodResp) = try await prodSession.data(for: prodRequest)
                guard let prodHTTP = prodResp as? HTTPURLResponse else { throw SupabaseError.networkError }
                print("🔧 [SupabaseService] Production registration response status: \(prodHTTP.statusCode)")
                if prodHTTP.statusCode == 201 {
                    let authResponse = try JSONDecoder().decode(BackendAuthResponse.self, from: prodData)
                    currentAccessToken = authResponse.data.access_token
                    let tokenSaved = KeychainService.shared.saveAccessToken(authResponse.data.access_token)
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    print("✅ [SupabaseService] Production signup success, token saved: \(tokenSaved)")
                    await MainActor.run {
                        currentUser = SupabaseUser(
                            id: UUID(uuidString: authResponse.data.user.id) ?? UUID(),
                            email: authResponse.data.user.email,
                            displayName: authResponse.data.user.display_name,
                            avatarUrl: authResponse.data.user.avatar_url,
                            provider: authResponse.data.user.provider,
                            providerId: nil,
                            videoCredits: 0,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        isAuthenticated = true
                        isLoading = false
                        errorMessage = nil
                    }
                    Task { await DataSyncService.shared.syncUserData() }
                    return (email, password)
                }
                print("⚠️ [SupabaseService] Production backend unavailable, falling back to direct Supabase signup...")
                if let host = URL(string: SupabaseConfig.url)?.host {
                    let reachable = await NetworkUtils.pingHTTPS(host: host, path: "/auth/v1/signup", timeout: 3.0)
                    if !reachable {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "注册失败：Supabase 服务当前不可达，请稍后重试或检查网络/VPN设置"
                        }
                        throw SupabaseError.networkError
                    }
                }
                let supaAuth = try await client.signUpWithEmail(email: email, password: password)
                if supaAuth.requiresEmailConfirmation {
                    await MainActor.run {
                        isAuthenticated = false
                        isLoading = false
                        errorMessage = SupabaseError.emailConfirmationRequired(email: email).localizedDescription
                    }
                    return (email, password)
                } else if supaAuth.isImmediateLogin, let accessToken = supaAuth.accessToken {
                    currentAccessToken = accessToken
                    let tokenSaved = KeychainService.shared.saveAccessToken(accessToken)
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    print("✅ [SupabaseService] Supabase signup immediate login, token saved: \(tokenSaved)")
                    await MainActor.run {
                        currentUser = SupabaseUser(
                            id: UUID(uuidString: supaAuth.user.id) ?? UUID(),
                            email: supaAuth.user.email,
                            displayName: displayName ?? supaAuth.user.email?.components(separatedBy: "@").first,
                            avatarUrl: nil,
                            provider: "email",
                            providerId: nil,
                            videoCredits: 0,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        isAuthenticated = true
                        isLoading = false
                        errorMessage = nil
                    }
                    Task { await DataSyncService.shared.syncUserData() }
                    return (email, password)
                }
                throw SupabaseError.signUpFailed
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "网络连接不可用，请检查网络设置"
                        case .timedOut:
                            errorMessage = "连接超时，请稍后重试"
                        case .cannotConnectToHost:
                            errorMessage = "无法连接到服务器，请稍后重试"
                        case .networkConnectionLost:
                            errorMessage = "网络连接中断，请重新连接"
                        case .secureConnectionFailed:
                            errorMessage = "TLS 安全连接失败，请检查网络或尝试关闭代理/VPN"
                        default:
                            errorMessage = "网络错误：\(urlError.localizedDescription)"
                        }
                    } else {
                        errorMessage = "注册失败：\(error.localizedDescription)"
                    }
                }
                throw error
            }
        }
    }

    // 检测连续字符模式的辅助函数
    private func hasConsecutiveCharacterPattern(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // 检查连续相同字符（如 "aaa", "111"）
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let endIndex = lowercased.index(startIndex, offsetBy: 3)
            let substring = String(lowercased[startIndex..<endIndex])
            
            if substring.allSatisfy({ $0 == substring.first }) {
                return true
            }
        }
        
        // 检查连续字母序列（如 "abc", "def", "xyz"）
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let char1 = lowercased[startIndex]
            let char2 = lowercased[lowercased.index(after: startIndex)]
            let char3 = lowercased[lowercased.index(startIndex, offsetBy: 2)]
            
            if char1.isLetter && char2.isLetter && char3.isLetter {
                let ascii1 = char1.asciiValue ?? 0
                let ascii2 = char2.asciiValue ?? 0
                let ascii3 = char3.asciiValue ?? 0
                
                if ascii2 == ascii1 + 1 && ascii3 == ascii2 + 1 {
                    return true
                }
            }
        }
        
        // 检查连续数字序列（如 "123", "456", "789"）
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let char1 = lowercased[startIndex]
            let char2 = lowercased[lowercased.index(after: startIndex)]
            let char3 = lowercased[lowercased.index(startIndex, offsetBy: 2)]
            
            if char1.isNumber && char2.isNumber && char3.isNumber {
                let num1 = Int(String(char1)) ?? 0
                let num2 = Int(String(char2)) ?? 0
                let num3 = Int(String(char3)) ?? 0
                
                if num2 == num1 + 1 && num3 == num2 + 1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // 使用更严格的邮箱验证，符合 Supabase 要求
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // 基本格式验证
        let basicFormatValid = emailPredicate.evaluate(with: email)
        
        // 检查@符号前后的部分
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return false }
        
        let localPart = components[0]
        let domainPart = components[1]
        
        // 本地部分不能为空，不能超过64个字符
        guard !localPart.isEmpty, localPart.count <= 64 else { return false }
        
        // 域名部分不能为空，不能超过253个字符，必须包含至少一个点
        guard !domainPart.isEmpty, domainPart.count <= 253, domainPart.contains(".") else { return false }
        
        // 简化验证：不包含连续的点，不以点开头或结尾
        let hasValidDots = !email.contains("..") && !email.hasPrefix(".") && !email.hasSuffix(".")
        
        // 检查是否为测试或示例邮箱地址（Supabase 不支持）
        let testDomains = ["test.com", "example.com", "example.org", "example.net", "localhost"]
        let isTestEmail = testDomains.contains { domainPart.lowercased().hasSuffix($0) }
        
        // 检查是否为明显的测试邮箱格式或连续字符模式
        let testPatterns = ["test", "asdf", "qwerty", "123", "abc", "demo", "sample", "fake", "temp"]
        let isTestPattern = testPatterns.contains { localPart.lowercased().contains($0) && localPart.count <= 8 }
        
        // 检查连续字符模式（如 "ddsf", "aaaa", "1234", "abcd" 等）
        let hasConsecutiveChars = hasConsecutiveCharacterPattern(localPart)
        
        // 检查是否为过于简单的邮箱格式
        let isTooSimple = localPart.count <= 4 && (localPart.allSatisfy { $0.isLetter } || localPart.allSatisfy { $0.isNumber })
        
        // 检查是否为真实的邮箱域名（常见的邮箱服务提供商）
        let realDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "icloud.com", 
                          "qq.com", "163.com", "126.com", "sina.com", "sohu.com", "foxmail.com"]
        let isRealDomain = realDomains.contains { domainPart.lowercased() == $0 }
        
        print("🔧 [SupabaseService] Email validation for '\(email)':")
        print("   - basicFormat: \(basicFormatValid)")
        print("   - validDots: \(hasValidDots)")
        print("   - isTestEmail: \(isTestEmail)")
        print("   - isTestPattern: \(isTestPattern)")
        print("   - hasConsecutiveChars: \(hasConsecutiveChars)")
        print("   - isTooSimple: \(isTooSimple)")
        print("   - isRealDomain: \(isRealDomain)")
        
        // 如果是测试邮箱或明显的测试模式，给出警告
        if isTestEmail || isTestPattern || hasConsecutiveChars || isTooSimple {
            print("⚠️ [SupabaseService] Detected problematic email pattern - may be rejected by Supabase")
        }
        
        return basicFormatValid && hasValidDots && !isTestEmail && !isTestPattern && !hasConsecutiveChars && !isTooSimple
    }
    
    // 移除了 Apple 和 Google 登录功能
    
    // MARK: - User Profile Management
    private func loadUserProfile(userId: String) async {
        do {
            let data = try await client.from("user_profiles")
                .select()
                .eq("user_id", value: userId)
                .execute(accessToken: currentAccessToken)
            
            let users = try JSONDecoder().decode([SupabaseUser].self, from: data)
            if let user = users.first {
                await MainActor.run {
                    currentUser = user
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load user profile: \(error.localizedDescription)"
            }
        }
    }
    
    private func createUserProfile(
        userId: UUID,
        email: String?,
        displayName: String?,
        provider: String,
        providerId: String? = nil,
        avatarUrl: String? = nil
    ) async throws {
        let nameAny: Any = (displayName ?? email) ?? NSNull()
        let avatarAny: Any = avatarUrl ?? NSNull()
        let profileData: [String: Any] = [
            "user_id": userId.uuidString,
            "name": nameAny,
            "avatar_url": avatarAny
        ]
        
        _ = try await client.from("user_profiles").insert(profileData).execute(accessToken: currentAccessToken)
    }
    
    private func createOrUpdateUserProfile(
        userId: UUID,
        email: String?,
        displayName: String?,
        avatarUrl: String? = nil,
        provider: String,
        providerId: String?
    ) async throws {
        let nameAny: Any = (displayName ?? email) ?? NSNull()
        let avatarAny: Any = avatarUrl ?? NSNull()
        let profileData: [String: Any] = [
            "user_id": userId.uuidString,
            "name": nameAny,
            "avatar_url": avatarAny
        ]
        
        _ = try await client.from("user_profiles").upsert(profileData).execute(accessToken: currentAccessToken)
        
        // Load the created/updated profile
        await loadUserProfile(userId: userId.uuidString)
    }
    
    // MARK: - Video Credits Management
    func getUserVideoCredits() -> Int {
        return currentUser?.videoCredits ?? 0
    }
    
    func updateVideoCredits(_ credits: Int) async throws {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let updateData: [String: Any] = [
            "video_credits": credits,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        _ = try await client.from("user_profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Reload user profile to get updated credits
        await loadUserProfile(userId: userId.uuidString)
    }
    
    func deductVideoCredit() async throws -> Bool {
        return try await deductVideoCredits(1) > 0
    }
    
    func deductVideoCredits(_ amount: Int) async throws -> Int {
        let currentCredits = getUserVideoCredits()
        let newCredits = max(0, currentCredits - amount)
        try await updateVideoCredits(newCredits)
        return newCredits
    }
    
    func addVideoCredits(_ amount: Int) async throws {
        let currentCredits = getUserVideoCredits()
        try await updateVideoCredits(currentCredits + amount)
    }
    
    func updatePassword(newPassword: String) async throws {
        guard let accessToken = currentAccessToken else {
            throw SupabaseError.notAuthenticated
        }
        
        try await client.updatePassword(accessToken: accessToken, newPassword: newPassword)
    }
    
    func resetPassword(email: String) async throws {
        print("🔧 [SupabaseService] Starting password reset for email: \(email)")
        
        // 验证邮箱格式
        let validationResult = validateEmailFormat(email)
        if !validationResult.isValid {
            print("❌ [SupabaseService] Email validation failed: \(validationResult.message)")
            throw SupabaseError.invalidEmail
        }
        
        do {
            // 使用 APIConfig 获取动态 URL
            let url = URL(string: "\(apiConfig.authBaseURL)/reset-password")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("🔧 [SupabaseService] Password reset request URL: \(url)")
            print("🔧 [SupabaseService] Password reset request body: \(body)")
            
            // 使用自定义URLSession配置来处理SSL问题
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            
            // 设置TLS配置
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            
            // 在DEBUG模式下使用自定义delegate绕过SSL证书验证
            #if DEBUG
            let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            print("🔧 [SupabaseService] Password reset response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                print("✅ [SupabaseService] Password reset email sent successfully")
            } else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["message"] as? String ?? "Password reset failed"
                print("❌ [SupabaseService] Password reset failed: \(errorMessage)")
                throw SupabaseError.requestFailed
            }
        } catch {
            print("❌ [SupabaseService] Network error during password reset: \(error)")
            throw error
        }
    }
    
    func signOut() async throws {
        print("🔧 [SupabaseService] Starting sign out process...")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Try to sign out from backend if we have a token
        if let token = currentAccessToken {
            print("🔧 [SupabaseService] Attempting to sign out from backend with token")
            do {
                try await client.signOut(accessToken: token)
                print("✅ [SupabaseService] Backend sign out successful")
            } catch {
                print("⚠️ [SupabaseService] Backend sign out failed, but continuing with local cleanup: \(error)")
                // Continue with local cleanup even if backend sign out fails
            }
        } else {
            print("🔧 [SupabaseService] No access token found, skipping backend sign out")
        }
        
        // Always clear stored credentials and tokens locally
        print("🔧 [SupabaseService] Clearing local credentials and tokens...")
        let credentialsDeleted = KeychainService.shared.deleteCredentials()
        let tokenDeleted = KeychainService.shared.deleteAccessToken()
        
        print("🔧 [SupabaseService] Credentials deleted: \(credentialsDeleted), Token deleted: \(tokenDeleted)")
        
        UserDefaults.standard.removeObject(forKey: "rememberCredentials")
        UserDefaults.standard.removeObject(forKey: "autoLogin")
        
        print("🔧 [SupabaseService] UserDefaults cleared")
        
        // 清理本地数据 - 清空购物车和其他用户相关数据
        print("🔧 [SupabaseService] Clearing local user data...")
        await clearLocalUserData()
        
        // Update UI state on main thread
        await MainActor.run {
            print("🔧 [SupabaseService] Updating UI state...")
            currentUser = nil
            isAuthenticated = false
            currentAccessToken = nil
            isLoading = false
            errorMessage = nil
            print("🔧 [SupabaseService] UI state updated - isAuthenticated: \(isAuthenticated)")
        }
        
        print("✅ [SupabaseService] Sign out completed successfully")
    }

    func createServerLetter(petId: UUID, content: String) async throws -> String {
        guard let rawToken = currentAccessToken ?? KeychainService.shared.loadAccessToken() else {
            throw SupabaseError.notAuthenticated
        }
        let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "\(APIConfig.shared.baseURL)/api/letters")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["pet_id": petId.uuidString, "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else { throw SupabaseError.requestFailed }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataObj = json?["data"] as? [String: Any]
        let id = dataObj?["id"] as? String ?? ""
        if id.isEmpty { throw SupabaseError.requestFailed }
        return id
    }

    func requestAIReply(letterId: String) async throws -> String {
        guard let rawToken = currentAccessToken ?? KeychainService.shared.loadAccessToken() else {
            throw SupabaseError.notAuthenticated
        }
        let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: "\(APIConfig.shared.baseURL)/api/letters/\(letterId)/ai-reply")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw SupabaseError.requestFailed }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataObj = json?["data"] as? [String: Any]
        let reply = dataObj?["reply"] as? String ?? ""
        if reply.isEmpty { throw SupabaseError.requestFailed }
        return reply
    }
    
    // MARK: - Local Data Cleanup
    private func clearLocalUserData() async {
        print("🗑️ [SupabaseService] Starting local data cleanup...")
        
        // 清空购物车数据
        do {
            try await CartService.shared.clearCart()
            print("✅ [SupabaseService] Cart data cleared")
        } catch {
            print("❌ [SupabaseService] Failed to clear cart data: \(error)")
        }
        
        // 清理所有本地 SwiftData 数据
        await clearAllLocalSwiftData()
        
        // 通知其他服务清理数据
        await MainActor.run {
            // 发送通知，让其他服务清理本地数据
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
            print("✅ [SupabaseService] User signed out notification sent")
        }
        
        print("✅ [SupabaseService] Local data cleanup completed")
    }
    
    // MARK: - Login Data Cleanup
    private func clearLocalUserDataOnLogin() async {
        print("🗑️ [SupabaseService] Clearing previous user data on login...")
        
        // 清空购物车数据（不需要用户认证检查，因为我们要清理所有数据）
        await MainActor.run {
            CartService.shared.cartItems = []
            CartService.shared.objectWillChange.send()
            print("✅ [SupabaseService] Cart data cleared on login")
        }
        
        // 清理所有本地 SwiftData 数据
        await clearAllLocalSwiftData()
        
        // 通知其他服务清理数据
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("UserSwitched"), object: nil)
            print("✅ [SupabaseService] User switched notification sent")
        }
        
        print("✅ [SupabaseService] Previous user data cleanup completed")
    }
    
    // MARK: - Clear All Local SwiftData
    private func clearAllLocalSwiftData() async {
        print("🗑️ [SupabaseService] Clearing all local SwiftData...")
        
        // 获取 DataSyncService 的 ModelContext
        guard let context = DataSyncService.shared.modelContext else {
            print("❌ [SupabaseService] No ModelContext available for data cleanup")
            return
        }
        
        await MainActor.run {
            do {
                // 清理所有 Pet 数据
                let petDescriptor = FetchDescriptor<Pet>()
                let allPets = try context.fetch(petDescriptor)
                for pet in allPets {
                    context.delete(pet)
                }
                print("🗑️ [SupabaseService] Deleted \(allPets.count) pets")
                
                // 清理所有 VideoGeneration 数据
                let videoDescriptor = FetchDescriptor<VideoGeneration>()
                let allVideos = try context.fetch(videoDescriptor)
                for video in allVideos {
                    context.delete(video)
                }
                print("🗑️ [SupabaseService] Deleted \(allVideos.count) videos")
                
                // 清理所有 Letter 数据
                let letterDescriptor = FetchDescriptor<Letter>()
                let allLetters = try context.fetch(letterDescriptor)
                for letter in allLetters {
                    context.delete(letter)
                }
                print("🗑️ [SupabaseService] Deleted \(allLetters.count) letters")
                
                // 清理所有 CartItem 数据
                let cartDescriptor = FetchDescriptor<CartItem>()
                let allCartItems = try context.fetch(cartDescriptor)
                for cartItem in allCartItems {
                    context.delete(cartItem)
                }
                print("🗑️ [SupabaseService] Deleted \(allCartItems.count) cart items")
                
                // 清理所有 Order 数据
                let orderDescriptor = FetchDescriptor<Order>()
                let allOrders = try context.fetch(orderDescriptor)
                for order in allOrders {
                    context.delete(order)
                }
                print("🗑️ [SupabaseService] Deleted \(allOrders.count) orders")
                
                // 保存更改
                try context.save()
                print("✅ [SupabaseService] All local SwiftData cleared successfully")
                
            } catch {
                print("❌ [SupabaseService] Failed to clear local SwiftData: \(error)")
            }
        }
    }
    
    private func validateEmailFormat(_ email: String) -> EmailValidationResult {
        // 使用现有的 isValidEmail 函数进行验证
        let isValid = isValidEmail(email)
        
        if isValid {
            return EmailValidationResult(isValid: true, message: "邮箱格式正确")
        } else {
            // 提供更详细的错误信息
            let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            
            if !emailPredicate.evaluate(with: email) {
                return EmailValidationResult(isValid: false, message: "邮箱格式不正确")
            }
            
            let components = email.components(separatedBy: "@")
            if components.count != 2 {
                return EmailValidationResult(isValid: false, message: "邮箱格式不正确")
            }
            
            let localPart = components[0]
            let domainPart = components[1]
            
            // 检查测试域名
            let testDomains = ["test.com", "example.com", "example.org", "example.net", "localhost"]
            if testDomains.contains(where: { domainPart.lowercased().hasSuffix($0) }) {
                return EmailValidationResult(isValid: false, message: "不支持测试邮箱域名，请使用真实邮箱")
            }
            
            // 检查测试模式
            let testPatterns = ["test", "asdf", "qwerty", "123", "abc", "demo", "sample", "fake", "temp"]
            if testPatterns.contains(where: { localPart.lowercased().contains($0) && localPart.count <= 8 }) {
                return EmailValidationResult(isValid: false, message: "请使用真实的邮箱地址")
            }
            
            // 检查连续字符
            if hasConsecutiveCharacterPattern(localPart) {
                return EmailValidationResult(isValid: false, message: "邮箱地址不能包含连续的字符模式")
            }
            
            // 检查过于简单的格式
            if localPart.count <= 4 && (localPart.allSatisfy { $0.isLetter } || localPart.allSatisfy { $0.isNumber }) {
                return EmailValidationResult(isValid: false, message: "邮箱地址过于简单，请使用更复杂的格式")
            }
            
            return EmailValidationResult(isValid: false, message: "邮箱格式验证失败")
        }
    }
}

// MARK: - Apple Sign In Delegate
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        } else {
            completion(.failure(SupabaseError.appleSignInFailed))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let scene = scenes.first {
            return scene.windows.first ?? UIWindow(windowScene: scene)
        }
        // If no scenes are available, crash is preferable to returning deprecated initializer,
        // as this situation should not occur in a running app with UI.
        preconditionFailure("No active UIWindowScene available for authorization presentation.")
    }
}

// Note: SupabaseError is defined in SupabaseClient.swift
