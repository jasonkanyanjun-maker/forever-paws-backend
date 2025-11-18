import Foundation

// MARK: - SSL Bypass Delegate for Development
#if DEBUG
class SSLBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 在DEBUG模式下绕过SSL证书验证
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
#endif

#if DEBUG
// MARK: - Debug network delegate for metrics and errors
class DebugNetworkDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let url = task.originalRequest?.url?.absoluteString ?? "unknown"
        print("📊 [SupabaseClient] Metrics for request: \(url)")
        print("📊 [SupabaseClient] redirectCount=\(metrics.redirectCount), taskInterval=\(metrics.taskInterval.duration)s")
        for (idx, m) in metrics.transactionMetrics.enumerated() {
            let proto = m.networkProtocolName ?? "unknown"
            let reused = m.isReusedConnection ? "reused" : "new"
            let proxy = m.isProxyConnection ? "via-proxy" : "direct"
            let domain = m.domainLookupStartDate != nil && m.domainLookupEndDate != nil
                ? String(format: "%.3f", m.domainLookupEndDate!.timeIntervalSince(m.domainLookupStartDate!))
                : "-"
            let connect = m.connectStartDate != nil && m.connectEndDate != nil
                ? String(format: "%.3f", m.connectEndDate!.timeIntervalSince(m.connectStartDate!))
                : "-"
            let tls = m.secureConnectionStartDate != nil && m.secureConnectionEndDate != nil
                ? String(format: "%.3f", m.secureConnectionEndDate!.timeIntervalSince(m.secureConnectionStartDate!))
                : "-"
            let reqDur = m.requestStartDate != nil && m.requestEndDate != nil
                ? String(format: "%.3f", m.requestEndDate!.timeIntervalSince(m.requestStartDate!))
                : "-"
            let respDur = m.responseStartDate != nil && m.responseEndDate != nil
                ? String(format: "%.3f", m.responseEndDate!.timeIntervalSince(m.responseStartDate!))
                : "-"
            print("📊 [SupabaseClient] tx[\(idx)] proto=\(proto) \(reused), \(proxy), dns=\(domain)s, connect=\(connect)s, tls=\(tls)s, req=\(reqDur)s, resp=\(respDur)s")
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            print("✅ [SupabaseClient] URLSession task completed successfully")
            return
        }
        let ns = error as NSError
        print("❌ [SupabaseClient] URLSession task error domain=\(ns.domain) code=\(ns.code) info=\(ns.userInfo)")
    }
}
#endif

// MARK: - JSON Sanitization Helper
func sanitizeForJSON(_ value: Any) -> Any {
    // Basic JSON-compatible types pass through
    if value is NSNull { return NSNull() }
    if value is String || value is NSNumber || value is Bool { return value }
    if let arr = value as? [Any] {
        return arr.map { sanitizeForJSON($0) }
    }
    if let dict = value as? [String: Any] {
        var out = [String: Any]()
        for (k, v) in dict {
            out[k] = sanitizeForJSON(v)
        }
        return out
    }
    // Convert URL -> String
    if let url = value as? URL {
        return url.absoluteString
    }
    // Convert Date -> ISO8601 string
    if let date = value as? Date {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    // Convert Data -> base64
    if let data = value as? Data {
        return data.base64EncodedString()
    }
    // Convert UUID -> string
    if let uuid = value as? UUID {
        return uuid.uuidString
    }
    // Convert Encodable objects via JSONEncoder fallback
    if let encodable = value as? Encodable {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let d = try? encoder.encode(AnyEncodable(encodable)), let json = try? JSONSerialization.jsonObject(with: d) {
            return sanitizeForJSON(json)
        }
    }
    // Fallback: just string-ify unknown objects
    return String(describing: value)
}

// Helper wrapper to encode Encodable at runtime
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// Simple Supabase client implementation
class SupabaseClient {
    let baseURL: String
    let apiKey: String
    
    init(url: String, key: String) {
        var sanitizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        while sanitizedURL.hasSuffix(",") { sanitizedURL.removeLast() }

        // Ensure URL uses HTTPS protocol
        if sanitizedURL.hasPrefix("http://") {
            sanitizedURL = sanitizedURL.replacingOccurrences(of: "http://", with: "https://")
            print("⚠️ [SupabaseClient] Converted HTTP to HTTPS: \(sanitizedURL)")
        }
        if let u = URL(string: sanitizedURL), u.host?.hasSuffix("supabase.com") == true {
            var c = URLComponents(url: u, resolvingAgainstBaseURL: false)
            if let h = c?.host { c?.host = h.replacingOccurrences(of: "supabase.com", with: "supabase.co") }
            if let fixed = c?.url?.absoluteString { sanitizedURL = fixed }
        }

        self.baseURL = sanitizedURL
        var k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if k.hasPrefix("\"") && k.hasSuffix("\"") { k = String(k.dropFirst().dropLast()) }
        self.apiKey = k
        
        print("🔧 [SupabaseClient] Initialized with URL: \(self.baseURL)")
        if self.baseURL != url { print("🔧 [SupabaseClient] Sanitized baseURL from '\(url)' to '\(self.baseURL)'") }
        print("🔧 [SupabaseClient] API Key length: \(key.count) characters")
    }
    
    // MARK: - Auth Methods
    func signInWithEmail(email: String, password: String) async throws -> AuthResponse {
        // 构建并清理最终的登录 URL，避免逗号/多余斜杠导致的 TLS/ATS 问题
        var sanitizedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while sanitizedBase.hasSuffix(",") { sanitizedBase.removeLast() }
        if sanitizedBase.hasPrefix("http://") { sanitizedBase = sanitizedBase.replacingOccurrences(of: "http://", with: "https://") }
        while sanitizedBase.hasSuffix("/") { sanitizedBase.removeLast() }

        var components = URLComponents(string: sanitizedBase)
        if components == nil { throw SupabaseError.invalidURL }
        components!.scheme = "https"
        components!.path = "/auth/v1/token"
        components!.queryItems = [ URLQueryItem(name: "grant_type", value: "password") ]
        guard let finalURL = components!.url else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "apikey")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let body = [
            "email": cleanEmail,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔐 [SupabaseClient] Sign in baseURL sanitized: \(sanitizedBase)")
        print("🔐 [SupabaseClient] Sign in URL: \(finalURL.absoluteString)")
        print("🔐 [SupabaseClient] Sign in headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔐 [SupabaseClient] Sign in body: \(body)")

        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15.0
            config.timeoutIntervalForResource = 30.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            config.connectionProxyDictionary = [:]
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            // 显式禁用多路径以兼容 VPN，并根据是否检测到 VPN 动态设置 Connection
#if os(iOS)
            config.multipathServiceType = .none
#endif
            let vpnActiveSignIn = NetworkUtils.isVPNActive()
            config.httpAdditionalHeaders = [
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": vpnActiveSignIn ? "close" : "keep-alive"
            ]

            #if DEBUG
            let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            request.httpShouldHandleCookies = false
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SupabaseClient] Invalid sign-in response type")
                throw SupabaseError.requestFailed
            }

            print("🔐 [SupabaseClient] Sign in status: \(httpResponse.statusCode)")
            if httpResponse.statusCode >= 400 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [SupabaseClient] Sign in error: \(errorString)")
                }
                throw SupabaseError.authenticationFailed
            }

            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } catch let error as URLError {
            print("❌ [SupabaseClient] Sign in URLError: \(error) code=\(error.code)")
            // 简单重试一次，兼容 VPN/代理/超时
            switch error.code {
            case .secureConnectionFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                do {
                    let retryConfig = URLSessionConfiguration.default
                    retryConfig.timeoutIntervalForRequest = 20.0
                    retryConfig.timeoutIntervalForResource = 40.0
                    retryConfig.waitsForConnectivity = true
                    retryConfig.allowsCellularAccess = true
                    retryConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                    // 在重试阶段强制使用 TLS1.2，提高在部分 VPN/代理环境下的握手成功率
                    retryConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                    retryConfig.connectionProxyDictionary = [:]
                    retryConfig.allowsConstrainedNetworkAccess = true
                    retryConfig.allowsExpensiveNetworkAccess = true
                    // 显式禁用多路径，并根据 VPN 动态设置 Connection
#if os(iOS)
                    retryConfig.multipathServiceType = .none
#endif
                    let vpnActiveSignInRetry = NetworkUtils.isVPNActive()
                    retryConfig.httpAdditionalHeaders = [
                        "Accept-Encoding": "gzip, deflate, br",
                        "Connection": vpnActiveSignInRetry ? "close" : "keep-alive"
                    ]
                    #if DEBUG
                    let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                    #else
                    let retrySession = URLSession(configuration: retryConfig)
                    #endif
                    print("🔁 [SupabaseClient] Retrying sign in after network error...")
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    let (retryData, retryResponse) = try await retrySession.data(for: request)
                    guard let httpResponse = retryResponse as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                    if httpResponse.statusCode >= 400 { throw SupabaseError.authenticationFailed }
                    return try JSONDecoder().decode(AuthResponse.self, from: retryData)
                } catch {
                    // 最终保守重试：更长超时、TLS1.2、强制关闭连接，保持蜂窝可用
                    do {
                        let finalConfig = URLSessionConfiguration.default
                        finalConfig.timeoutIntervalForRequest = 45.0
                        finalConfig.timeoutIntervalForResource = 90.0
                        finalConfig.waitsForConnectivity = true
                        finalConfig.allowsCellularAccess = true
                        finalConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                        finalConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                        finalConfig.connectionProxyDictionary = [:]
                        finalConfig.allowsConstrainedNetworkAccess = true
                        finalConfig.allowsExpensiveNetworkAccess = true
#if os(iOS)
                        finalConfig.multipathServiceType = .none
#endif
                        finalConfig.httpAdditionalHeaders = [
                            "Accept-Encoding": "gzip, deflate, br",
                            "Connection": "close"
                        ]
#if DEBUG
                        let finalSession = URLSession(configuration: finalConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
#else
                        let finalSession = URLSession(configuration: finalConfig)
#endif
                        print("🔁 [SupabaseClient] Final conservative retry for sign in...")
                        try await Task.sleep(nanoseconds: 1_500_000_000)
                        let (fd, fr) = try await finalSession.data(for: request)
                        guard let httpResponse = fr as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                        if httpResponse.statusCode >= 400 { throw SupabaseError.authenticationFailed }
                        return try JSONDecoder().decode(AuthResponse.self, from: fd)
                    } catch {
                        throw SupabaseError.networkError
                    }
                }
            default:
                throw SupabaseError.networkError
            }
        } catch {
            print("❌ [SupabaseClient] Sign in unexpected error: \(error)")
            throw SupabaseError.networkError
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> AuthResponse {
        // 构建并清理最终的注册 URL，避免逗号/多余斜杠导致的 TLS/ATS 问题
        var sanitizedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while sanitizedBase.hasSuffix(",") { sanitizedBase.removeLast() }
        if sanitizedBase.hasPrefix("http://") { sanitizedBase = sanitizedBase.replacingOccurrences(of: "http://", with: "https://") }
        while sanitizedBase.hasSuffix("/") { sanitizedBase.removeLast() }

        var components = URLComponents(string: sanitizedBase)
        if components == nil {
            throw SupabaseError.invalidURL
        }
        // Supabase base 域通常没有 path，这里直接设置目标路径
        components!.scheme = "https"
        components!.path = "/auth/v1/signup"
        guard let finalURL = components!.url else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // 添加额外的Supabase必需头部
        request.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // 确保邮箱格式符合 Supabase 要求
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let body = [
            "email": cleanEmail,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔧 [SupabaseClient] Sign up baseURL sanitized: \(sanitizedBase)")
        print("🔧 [SupabaseClient] Sign up request URL: \(finalURL.absoluteString)")
        print("🔧 [SupabaseClient] Sign up request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔧 [SupabaseClient] Sign up request body: \(body)")

        do {
            // 使用自定义URLSession配置，增强 VPN/代理 环境兼容性
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            // 初始阶段允许 TLS1.2-1.3，尽量与 Supabase 兼容
            config.tlsMinimumSupportedProtocolVersion = .TLSv12
            config.tlsMaximumSupportedProtocolVersion = .TLSv13
            config.connectionProxyDictionary = [:]
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            // 显式禁用多路径，并根据 VPN 动态设置 Connection
#if os(iOS)
            config.multipathServiceType = .none
#endif
            let vpnActiveSignUp = NetworkUtils.isVPNActive()
            config.httpAdditionalHeaders = [
                // 去掉 br，避免部分 VPN/代理不支持 brotli 导致握手异常
                "Accept-Encoding": "gzip, deflate",
                "Connection": vpnActiveSignUp ? "close" : "keep-alive"
            ]

            #if DEBUG
            let session = URLSession(configuration: config, delegate: DebugNetworkDelegate(), delegateQueue: nil)
            #else
            let session = URLSession(configuration: config)
            #endif
            // 避免 Cookie 干扰网络握手
            request.httpShouldHandleCookies = false
            let start = Date()
            let reqId = UUID().uuidString
            print("⏱️ [SupabaseClient] Sign up request id=\(reqId) started at \(start)")
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(start)
            print(String(format: "⏱️ [SupabaseClient] Sign up id=%@ finished in %.3fs", reqId, duration))
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔧 [SupabaseClient] Sign up response status: \(httpResponse.statusCode)")
                print("🔧 [SupabaseClient] Sign up response headers: \(httpResponse.allHeaderFields)")
            }
            
            // Print raw response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔧 [SupabaseClient] Sign up response data: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SupabaseClient] Invalid response type")
                throw SupabaseError.requestFailed
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                print("❌ [SupabaseClient] Sign up failed with status: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) { print("❌ [SupabaseClient] Error response: \(errorString)") }
                throw parseSupabaseAuthError(data: data, status: httpResponse.statusCode, email: cleanEmail)
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("✅ [SupabaseClient] Sign up successful for user: \(authResponse.id)")
                
                // 检查是否需要邮箱验证 - 这是成功的注册，不是错误
                if authResponse.requiresEmailConfirmation {
                    print("📧 [SupabaseClient] Email confirmation required for: \(authResponse.email ?? "unknown")")
                    print("✅ [SupabaseClient] Registration successful, awaiting email confirmation")
                }
                
                // 无论是否需要邮箱验证，都返回成功的响应
                return authResponse
            } catch {
                print("❌ [SupabaseClient] Failed to decode auth response: \(error)")
                print("❌ [SupabaseClient] Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw error
            }
        } catch let error as URLError {
            print("❌ [SupabaseClient] Sign up URLError: \(error) code=\(error.code)")
            print("❌ [SupabaseClient] Failing request URL: \(request.url?.absoluteString ?? "nil")")
            // 简单重试一次，兼容 VPN/代理/超时
            switch error.code {
            case .secureConnectionFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                do {
                    let retryConfig = URLSessionConfiguration.default
                    retryConfig.timeoutIntervalForRequest = 12.0
                    retryConfig.timeoutIntervalForResource = 24.0
                    retryConfig.waitsForConnectivity = true
                    retryConfig.allowsCellularAccess = true
                    retryConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                    // 在重试阶段强制使用 TLS1.2，提高在部分 VPN/代理环境下的握手成功率
                    retryConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                    retryConfig.connectionProxyDictionary = [:]
                    retryConfig.allowsConstrainedNetworkAccess = true
                    retryConfig.allowsExpensiveNetworkAccess = true
                    // 显式禁用多路径，并根据 VPN 动态设置 Connection
#if os(iOS)
                    retryConfig.multipathServiceType = .none
#endif
                    let vpnActiveSignUpRetry = NetworkUtils.isVPNActive()
                    retryConfig.httpAdditionalHeaders = [
                        "Accept-Encoding": "gzip, deflate",
                        "Connection": vpnActiveSignUpRetry ? "close" : "keep-alive"
                    ]
                    #if DEBUG
                    let retrySession = URLSession(configuration: retryConfig, delegate: DebugNetworkDelegate(), delegateQueue: nil)
                    #else
                    let retrySession = URLSession(configuration: retryConfig)
                    #endif
                    print("🔁 [SupabaseClient] Retrying sign up after network error...")
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    let rStart = Date()
                    let rId = UUID().uuidString
                    print("⏱️ [SupabaseClient] Retry sign up id=\(rId) started at \(rStart)")
                    let rHeartbeat = Task.detached {
                        var elapsed = 0
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            elapsed += 5
                            print("⏳ [SupabaseClient] Retry sign up id=\(rId) waiting... \(elapsed)s")
                        }
                    }
                    let (retryData, retryResponse) = try await retrySession.data(for: request)
                    rHeartbeat.cancel()
                    print(String(format: "⏱️ [SupabaseClient] Retry sign up id=%@ finished in %.3fs", rId, Date().timeIntervalSince(rStart)))
                    guard let httpResponse = retryResponse as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                    if httpResponse.statusCode >= 400 { throw SupabaseError.authenticationFailed }
                    return try JSONDecoder().decode(AuthResponse.self, from: retryData)
                } catch {
                    // 最终保守重试：更长超时、TLS1.2、强制关闭连接，保持蜂窝可用
                    do {
                        // 使用 ephemeral，避免复用可能有问题的连接与缓存
                        let finalConfig = URLSessionConfiguration.ephemeral
                        finalConfig.timeoutIntervalForRequest = 20.0
                        finalConfig.timeoutIntervalForResource = 40.0
                        finalConfig.waitsForConnectivity = true
                        finalConfig.allowsCellularAccess = true
                        finalConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                        finalConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                        finalConfig.connectionProxyDictionary = [:]
                        finalConfig.allowsConstrainedNetworkAccess = true
                        finalConfig.allowsExpensiveNetworkAccess = true
                        finalConfig.httpMaximumConnectionsPerHost = 1
                        finalConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
#if os(iOS)
                        finalConfig.multipathServiceType = .none
#endif
                        finalConfig.httpAdditionalHeaders = [
                            "Accept-Encoding": "gzip, deflate",
                            "Connection": "close"
                        ]
                        finalConfig.urlCache = nil
#if DEBUG
                        let finalSession = URLSession(configuration: finalConfig, delegate: DebugNetworkDelegate(), delegateQueue: nil)
#else
                        let finalSession = URLSession(configuration: finalConfig)
#endif
                        print("🔁 [SupabaseClient] Final conservative retry for sign up...")
                        try await Task.sleep(nanoseconds: 1_500_000_000)
                        // 避免 Cookie 干扰网络握手
                        request.httpShouldHandleCookies = false
                        let fStart = Date()
                        let fId = UUID().uuidString
                        print("⏱️ [SupabaseClient] Final retry sign up id=\(fId) started at \(fStart)")
                        let fHeartbeat = Task.detached {
                            var elapsed = 0
                            while !Task.isCancelled {
                                try? await Task.sleep(nanoseconds: 5_000_000_000)
                                elapsed += 5
                                print("⏳ [SupabaseClient] Final retry sign up id=\(fId) waiting... \(elapsed)s")
                            }
                        }
                        let (fd, fr) = try await finalSession.data(for: request)
                        fHeartbeat.cancel()
                        print(String(format: "⏱️ [SupabaseClient] Final retry sign up id=%@ finished in %.3fs", fId, Date().timeIntervalSince(fStart)))
                        guard let httpResponse = fr as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                        if httpResponse.statusCode >= 400 { throw SupabaseError.authenticationFailed }
                        return try JSONDecoder().decode(AuthResponse.self, from: fd)
                    } catch {
                        throw SupabaseError.networkError
                    }
                }
            default:
                throw SupabaseError.networkError
            }
        } catch {
            print("❌ [SupabaseClient] Final sign up error: \(error)")
            throw error
        }
    }

    private func parseSupabaseAuthError(data: Data, status: Int, email: String) -> SupabaseError {
        var message = ""
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let m = obj["message"] as? String { message = m }
            else if let m = obj["error_description"] as? String { message = m }
            else if let m = obj["error"] as? String { message = m }
        } else if let s = String(data: data, encoding: .utf8) { message = s }
        let lower = message.lowercased()
        if lower.contains("already") && lower.contains("register") || lower.contains("exists") { return .emailAlreadyExists }
        if lower.contains("password") && (lower.contains("weak") || lower.contains("short") || lower.contains("too")) { return .weakPassword }
        if lower.contains("email") && (lower.contains("invalid") || lower.contains("format")) { return .invalidEmail }
        if lower.contains("disabled") && lower.contains("auth") { return .featureNotAvailable }
        if lower.contains("rls") || lower.contains("policy") { return .insufficientPermissions }
        if lower.contains("confirmation") && lower.contains("email") { return .emailConfirmationRequired(email: email) }
        if lower.contains("storage") && lower.contains("permission") { return .storageError }
        if lower.contains("function") { return .serverError }
        return .requestFailed
    }
    
    func updatePassword(accessToken: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body = ["password": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 使用自定义URLSession配置来处理SSL问题
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        
        // 设置TLS配置
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        // 禁用SSL证书验证（仅用于开发环境）
        #if DEBUG
        let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
        #else
        let session = URLSession(configuration: config)
        #endif
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
    }
    
    func signOut(accessToken: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
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
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw SupabaseError.signOutFailed
        }
    }
    
    // MARK: - Database Methods
    func from(_ table: String) -> QueryBuilder {
        return QueryBuilder(client: self, table: table)
    }
}

// MARK: - Query Builder
class QueryBuilder {
    private let client: SupabaseClient
    private let table: String
    private var selectFields: String = "*"
    private var whereConditions: [(String, String)] = []
    private var insertData: [String: Any]?
    private var updateData: [String: Any]?
    private var isDeleteOperation = false
    
    init(client: SupabaseClient, table: String) {
        self.client = client
        self.table = table
    }
    
    func select(_ fields: String = "*") -> QueryBuilder {
        self.selectFields = fields
        return self
    }
    
    func eq(_ column: String, value: Any) -> QueryBuilder {
        let stringValue: String
        if let boolValue = value as? Bool {
            stringValue = boolValue ? "true" : "false"
        } else if let stringVal = value as? String {
            stringValue = stringVal
        } else if let uuidValue = value as? UUID {
            stringValue = uuidValue.uuidString
        } else {
            stringValue = String(describing: value)
        }
        whereConditions.append((column, "eq.\(stringValue)"))
        return self
    }
    
    func insert(_ data: [String: Any]) -> QueryBuilder {
        self.insertData = data
        return self
    }
    
    func update(_ data: [String: Any]) -> QueryBuilder {
        self.updateData = data
        return self
    }
    
    func upsert(_ data: [String: Any]) -> QueryBuilder {
        self.insertData = data
        return self
    }
    
    func delete() -> QueryBuilder {
        self.isDeleteOperation = true
        return self
    }
    
    func execute(accessToken: String? = nil) async throws -> Data {
        let baseURL = client.baseURL
        // apiKey not used in this method
        
        var urlString = "\(baseURL)/rest/v1/\(table)"
        var httpMethod = "GET"
        var httpBody: Data?
        
        if let insertData = insertData {
            httpMethod = "POST"
            
            // Debug and sanitize JSON data before serialization
            print("🔎 [SupabaseClient] JSON body preview: \(type(of: insertData)) -> \(insertData)")
            
            let sanitizedData = sanitizeForJSON(insertData)
            
            if !JSONSerialization.isValidJSONObject(sanitizedData) {
                print("❌ [SupabaseClient] sanitized data is NOT a valid JSON object")
                if let dict = sanitizedData as? [String: Any] {
                    dict.forEach { key, value in
                        print("  key: \(key), type: \(type(of: value)), value: \(value)")
                    }
                }
                throw SupabaseError.requestFailed
            }
            
            httpBody = try JSONSerialization.data(withJSONObject: sanitizedData)
        } else if let updateData = updateData {
            httpMethod = "PATCH"
            
            // Debug and sanitize JSON data before serialization
            print("🔎 [SupabaseClient] JSON body preview: \(type(of: updateData)) -> \(updateData)")
            
            let sanitizedData = sanitizeForJSON(updateData)
            
            if !JSONSerialization.isValidJSONObject(sanitizedData) {
                print("❌ [SupabaseClient] sanitized data is NOT a valid JSON object")
                if let dict = sanitizedData as? [String: Any] {
                    dict.forEach { key, value in
                        print("  key: \(key), type: \(type(of: value)), value: \(value)")
                    }
                }
                throw SupabaseError.requestFailed
            }
            
            httpBody = try JSONSerialization.data(withJSONObject: sanitizedData)
        } else if isDeleteOperation {
            httpMethod = "DELETE"
        }
        
        // Add query parameters for WHERE conditions and SELECT
        var queryItems: [URLQueryItem] = []
        
        // Add select parameter for all operations that need it
        if selectFields != "*" {
            queryItems.append(URLQueryItem(name: "select", value: selectFields))
        }
        
        // Add WHERE conditions
        if !whereConditions.isEmpty {
            queryItems.append(contentsOf: whereConditions.map { URLQueryItem(name: $0.0, value: $0.1) })
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)!
            components.queryItems = queryItems
            urlString = components.url!.absoluteString
        }
         
         return try await makeRequest(urlString: urlString, httpMethod: httpMethod, httpBody: httpBody, accessToken: accessToken)
     }
     
     private func makeRequest(
            urlString: String,
            httpMethod: String,
            httpBody: Data? = nil,
            accessToken: String? = nil
        ) async throws -> Data {
            // 清理潜在的尾随逗号，避免错误的URL（日志显示 URL 末尾带逗号）
            var cleanedURLString = urlString
            while cleanedURLString.hasSuffix(",") { cleanedURLString.removeLast() }

            guard let url = URL(string: cleanedURLString) else {
                throw SupabaseError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 正确设置 Supabase 认证头部
            if let accessToken = accessToken {
                // 如果有用户访问令牌，使用 Bearer token
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            } else {
                // 如果没有用户访问令牌，使用 anon key 作为 Bearer token
                request.setValue("Bearer \(client.apiKey)", forHTTPHeaderField: "Authorization")
            }
            // 始终设置 apikey 头部（项目的 anon key）
            request.setValue(client.apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "apikey")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            
            // Configure request timeout and caching
            request.timeoutInterval = 30.0
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpShouldHandleCookies = false
            
            // 不手动设置 Connection/Keep-Alive，避免被错误识别为代理/非标准头
            
            if let httpBody = httpBody {
                request.httpBody = httpBody
            }
            
            print("🌐 [SupabaseClient] Making request to: \(cleanedURLString)")
            print("🌐 [SupabaseClient] HTTP Method: \(httpMethod)")
            
            // Debug access token
            if let accessToken = accessToken {
                print("🔑 [SupabaseClient] Access token length: \(accessToken.count)")
                print("🔑 [SupabaseClient] Access token prefix: \(accessToken.prefix(20))...")
            } else {
                print("🔑 [SupabaseClient] Using anon key for authentication")
            }
            
            do {
                // 使用自定义URLSession配置来处理SSL问题
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 30.0
                config.timeoutIntervalForResource = 60.0
                config.waitsForConnectivity = true
                config.allowsCellularAccess = true
                
                // 设置TLS配置
                config.tlsMinimumSupportedProtocolVersion = .TLSv12
                config.tlsMaximumSupportedProtocolVersion = .TLSv13
                // 禁用系统代理，避免 127.0.0.1:1082 等本地代理干扰
                config.connectionProxyDictionary = [:]
                // 显式禁用多路径，并根据 VPN 动态设置 Connection
#if os(iOS)
                config.multipathServiceType = .none
#endif
                let vpnActiveRequest = NetworkUtils.isVPNActive()
                config.httpAdditionalHeaders = [
                    "Accept-Encoding": "gzip, deflate",
                    "Connection": vpnActiveRequest ? "close" : "keep-alive"
                ]
                
                #if DEBUG
                let session = URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
                #else
                let session = URLSession(configuration: config)
                #endif
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [SupabaseClient] Invalid response type")
                    throw SupabaseError.invalidResponse
                }
                
                print("📊 [SupabaseClient] Response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    print("❌ [SupabaseClient] HTTP error: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [SupabaseClient] Error response: \(errorString)")
                    }
                    throw SupabaseError.requestFailed
                }
                
                return data
            } catch let error as URLError {
                print("❌ [SupabaseClient] Network error: \(error)")
                print("❌ [SupabaseClient] Error code: \(error.code)")
                print("❌ [SupabaseClient] Error description: \(error.localizedDescription)")
                
                // 处理特定的SSL/TLS错误
                switch error.code {
                case .secureConnectionFailed:
                    print("🔒 [SupabaseClient] SSL/TLS connection failed - trying with relaxed security")
                    // 简单重试一次：缩短超时，禁用代理
                    do {
                        let retryConfig = URLSessionConfiguration.default
                        retryConfig.timeoutIntervalForRequest = 20.0
                        retryConfig.timeoutIntervalForResource = 40.0
                        retryConfig.waitsForConnectivity = true
                        retryConfig.allowsCellularAccess = true
                        retryConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                        retryConfig.tlsMaximumSupportedProtocolVersion = .TLSv12
                        retryConfig.connectionProxyDictionary = [:]
                        #if DEBUG
                        let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                        #else
                        let retrySession = URLSession(configuration: retryConfig)
                        #endif
                        print("🔁 [SupabaseClient] Retrying after TLS failure...")
                        let (retryData, retryResponse) = try await retrySession.data(for: request)
                        guard let httpResponse = retryResponse as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                        if httpResponse.statusCode >= 400 { throw SupabaseError.requestFailed }
                        return retryData
                    } catch {
                        throw SupabaseError.networkError
                    }
                case .serverCertificateUntrusted:
                    print("🔒 [SupabaseClient] Server certificate untrusted")
                    throw SupabaseError.networkError
                case .cannotConnectToHost:
                    print("🌐 [SupabaseClient] Cannot connect to host")
                    // 重试一次以规避临时的连接问题或代理干扰
                    do {
                        let retryConfig = URLSessionConfiguration.default
                        retryConfig.timeoutIntervalForRequest = 20.0
                        retryConfig.timeoutIntervalForResource = 40.0
                        retryConfig.waitsForConnectivity = true
                        retryConfig.connectionProxyDictionary = [:]
                        #if DEBUG
                        let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                        #else
                        let retrySession = URLSession(configuration: retryConfig)
                        #endif
                        print("🔁 [SupabaseClient] Retrying after host connection failure...")
                        let (retryData, retryResponse) = try await retrySession.data(for: request)
                        guard let httpResponse = retryResponse as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                        if httpResponse.statusCode >= 400 { throw SupabaseError.requestFailed }
                        return retryData
                    } catch {
                        throw SupabaseError.networkError
                    }
                case .timedOut:
                    print("⏳ [SupabaseClient] Request timed out - retrying once...")
                    do {
                        let retryConfig = URLSessionConfiguration.default
                        retryConfig.timeoutIntervalForRequest = 20.0
                        retryConfig.timeoutIntervalForResource = 40.0
                        retryConfig.waitsForConnectivity = true
                        retryConfig.connectionProxyDictionary = [:]
                        #if DEBUG
                        let retrySession = URLSession(configuration: retryConfig, delegate: SSLBypassDelegate(), delegateQueue: nil)
                        #else
                        let retrySession = URLSession(configuration: retryConfig)
                        #endif
                        let (retryData, retryResponse) = try await retrySession.data(for: request)
                        guard let httpResponse = retryResponse as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
                        if httpResponse.statusCode >= 400 { throw SupabaseError.requestFailed }
                        return retryData
                    } catch {
                        throw SupabaseError.networkError
                    }
                default:
                    throw SupabaseError.networkError
                }
            } catch {
                print("❌ [SupabaseClient] Unexpected error: \(error)")
                throw SupabaseError.networkError
            }
        }
    }

// MARK: - Response Models
struct AuthResponse: Codable {
    // 可选的认证令牌（登录成功时存在）
    let accessToken: String?
    let refreshToken: String?
    
    // 用户信息字段（直接在响应根级别）
    let id: String
    let email: String?
    let phone: String?
    let role: String?
    let aud: String?
    
    // 邮箱验证相关
    let confirmationSentAt: String?
    
    // 元数据
    let appMetadata: [String: Any]?
    let userMetadata: [String: Any]?
    
    // 身份信息
    let identities: [Identity]?
    
    // 时间戳
    let createdAt: String?
    let updatedAt: String?
    let isAnonymous: Bool?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case id, email, phone, role, aud
        case confirmationSentAt = "confirmation_sent_at"
        case appMetadata = "app_metadata"
        case userMetadata = "user_metadata"
        case identities
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isAnonymous = "is_anonymous"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 可选的认证令牌
        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        
        // 必需的用户信息
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        aud = try container.decodeIfPresent(String.self, forKey: .aud)
        
        // 邮箱验证
        confirmationSentAt = try container.decodeIfPresent(String.self, forKey: .confirmationSentAt)
        
        // 元数据（跳过复杂的 [String: Any] 解析）
        appMetadata = nil
        userMetadata = nil
        
        // 身份信息
        identities = try container.decodeIfPresent([Identity].self, forKey: .identities)
        
        // 时间戳
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(aud, forKey: .aud)
        try container.encodeIfPresent(confirmationSentAt, forKey: .confirmationSentAt)
        try container.encodeIfPresent(identities, forKey: .identities)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(isAnonymous, forKey: .isAnonymous)
    }
    
    // 检查是否需要邮箱验证
    var requiresEmailConfirmation: Bool {
        return confirmationSentAt != nil && accessToken == nil
    }
    
    // 检查是否立即登录成功
    var isImmediateLogin: Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    // 为了兼容现有代码，提供一个 user 属性
    var user: AuthUser {
        return AuthUser(
            id: id,
            email: email,
            userMetadata: userMetadata
        )
    }
}

struct Identity: Codable {
    let identityId: String?
    let id: String?
    let userId: String?
    let identityData: [String: Any]?
    let provider: String?
    let lastSignInAt: String?
    let createdAt: String?
    let updatedAt: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case identityId = "identity_id"
        case id
        case userId = "user_id"
        case identityData = "identity_data"
        case provider
        case lastSignInAt = "last_sign_in_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case email
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        identityId = try container.decodeIfPresent(String.self, forKey: .identityId)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        lastSignInAt = try container.decodeIfPresent(String.self, forKey: .lastSignInAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        // 跳过复杂的 identity_data 解析
        identityData = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(identityId, forKey: .identityId)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(lastSignInAt, forKey: .lastSignInAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(email, forKey: .email)
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    let userMetadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }
    
    init(id: String, email: String?, userMetadata: [String: Any]?) {
        self.id = id
        self.email = email
        self.userMetadata = userMetadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        // Skip userMetadata decoding for now due to [String: Any] complexity
        userMetadata = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        // Skip userMetadata encoding for now
    }
}

// MARK: - Errors
enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case authenticationFailed
    case userNotFound
    case networkError
    case invalidResponse
    case missingToken
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case signUpFailed
    case signInFailed
    case signOutFailed
    case tokenRefreshFailed
    case userProfileCreationFailed
    case userProfileUpdateFailed
    case userProfileFetchFailed

    case letterCreationFailed
    case letterUpdateFailed
    case letterDeletionFailed
    case letterFetchFailed
    case letterNotFound
    case letterPermissionDenied
    case invalidLetterData
    case letterSendFailed
    case letterReceiveFailed
    case attachmentUploadFailed
    case attachmentDownloadFailed
    case attachmentNotFound
    case attachmentTooLarge
    case invalidAttachmentType
    case storageError
    case databaseError
    case serverError
    case rateLimitExceeded
    case maintenanceMode
    case featureNotAvailable
    case insufficientPermissions
    case accountSuspended
    case accountDeleted
    case subscriptionRequired
    case paymentRequired
    case quotaExceeded
    case unknown
    case notAuthenticated
    case noViewController
    case insufficientCredits
    case emailConfirmationRequired(email: String)
    case requestFailed
    case appleSignInFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .authenticationFailed:
            return "Authentication failed"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network error"
        case .invalidResponse:
            return "Invalid response"
        case .missingToken:
            return "Missing authentication token"
        case .invalidCredentials:
            return "Invalid credentials"
        case .emailAlreadyExists:
            return "Email already exists"
        case .weakPassword:
            return "Password is too weak"
        case .invalidEmail:
            return "Invalid email address"
        case .signUpFailed:
            return "Sign up failed"
        case .signInFailed:
            return "Sign in failed"
        case .signOutFailed:
            return "Sign out failed"
        case .tokenRefreshFailed:
            return "Token refresh failed"
        case .userProfileCreationFailed:
            return "User profile creation failed"
        case .userProfileUpdateFailed:
            return "User profile update failed"
        case .userProfileFetchFailed:
            return "User profile fetch failed"

        case .letterCreationFailed:
            return "Letter creation failed"
        case .letterUpdateFailed:
            return "Letter update failed"
        case .letterDeletionFailed:
            return "Letter deletion failed"
        case .letterFetchFailed:
            return "Letter fetch failed"
        case .letterNotFound:
            return "Letter not found"
        case .letterPermissionDenied:
            return "Letter permission denied"
        case .invalidLetterData:
            return "Invalid letter data"
        case .letterSendFailed:
            return "Letter send failed"
        case .letterReceiveFailed:
            return "Letter receive failed"
        case .attachmentUploadFailed:
            return "Attachment upload failed"
        case .attachmentDownloadFailed:
            return "Attachment download failed"
        case .attachmentNotFound:
            return "Attachment not found"
        case .attachmentTooLarge:
            return "Attachment too large"
        case .invalidAttachmentType:
            return "Invalid attachment type"
        case .storageError:
            return "Storage error"
        case .databaseError:
            return "Database error"
        case .serverError:
            return "Server error"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .maintenanceMode:
            return "Service is in maintenance mode"
        case .featureNotAvailable:
            return "Feature not available"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .accountSuspended:
            return "Account suspended"
        case .accountDeleted:
            return "Account deleted"
        case .subscriptionRequired:
            return "Subscription required"
        case .paymentRequired:
            return "Payment required"
        case .quotaExceeded:
            return "Quota exceeded"
        case .unknown:
            return "Unknown error"
        case .notAuthenticated:
            return "User not authenticated"
        case .noViewController:
            return "No view controller available"
        case .insufficientCredits:
            return "Insufficient video credits"
        case .emailConfirmationRequired(let email):
            return "Please check your email (\(email)) and click the confirmation link to complete registration."
        case .requestFailed:
            return "Request failed"
        case .appleSignInFailed:
            return "Apple Sign In failed"
        }
    }
}
