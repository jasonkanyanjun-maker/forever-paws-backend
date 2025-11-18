import Foundation

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

// MARK: - API Configuration
class APIConfig {
    static let shared = APIConfig()
    
    private init() {}
    
    // MARK: - Environment Detection
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Production URLs
    // 原始基础 URL（在返回前进行标准化与清理）
    private let productionBaseURLRaw = "https://forever-paws-api-production.up.railway.app"
    private let stagingBaseURLRaw = "https://forever-paws-api-staging.up.railway.app"

    // MARK: - URL Sanitization
    /// 规范化 URL：去除首尾空格、尾随逗号，允许本地开发使用 HTTP，移除尾部斜杠
    private func sanitizeURL(_ url: String) -> String {
        var sanitized = url.trimmingCharacters(in: .whitespacesAndNewlines)
        while sanitized.hasSuffix(",") { sanitized.removeLast() }
        // 允许本地开发使用 HTTP (localhost, 127.0.0.1, 192.168.x.x)
        if sanitized.hasPrefix("http://") {
            let isLocalhost = sanitized.contains("localhost") || 
                             sanitized.contains("127.0.0.1") || 
                             sanitized.contains("192.168.") ||
                             sanitized.contains("10.0.") ||
                             sanitized.contains("172.16.")
            
            if !isLocalhost {
                // 只有非本地地址才强制转换为 HTTPS
                sanitized = sanitized.replacingOccurrences(of: "http://", with: "https://")
            }
        }
        // 去除末尾斜杠，统一格式
        while sanitized.hasSuffix("/") { sanitized.removeLast() }
        return sanitized
    }
    
    // MARK: - Base URL Configuration
    var baseURL: String {
        // 开发者开关：优先使用生产后端（仅开发环境可控）
        let preferProduction = UserDefaults.standard.bool(forKey: "prefer_production_backend")
        // 检查是否有用户自定义的 API URL (仅在开发环境)
        if AppEnvironment.current == .development,
           let customURL = UserDefaults.standard.string(forKey: "custom_api_url"),
           !customURL.isEmpty {
            return sanitizeURL(customURL)
        }

        // 根据环境选择 URL，并进行标准化
        switch AppEnvironment.current {
        case .production:
            return sanitizeURL(productionBaseURLRaw)
        case .staging:
            // 若开启了生产优先，则在调试/预备环境下仍指向生产
            return sanitizeURL(preferProduction ? productionBaseURLRaw : stagingBaseURLRaw)
        case .development:
            // 为避免本地未运行导致的连接拒绝/超时，默认使用 staging；如开启生产优先则使用生产
            return sanitizeURL(preferProduction ? productionBaseURLRaw : stagingBaseURLRaw)
        }
    }
    
    // MARK: - API Endpoints
    var authBaseURL: String {
        return "\(baseURL)/api/auth"
    }
    
    var uploadBaseURL: String {
        return "\(baseURL)/api/upload"
    }
    
    var userBaseURL: String {
        return "\(baseURL)/api/user"
    }
    
    // MARK: - Configuration Methods
    func setCustomAPIURL(_ url: String) {
        let sanitized = sanitizeURL(url)
        UserDefaults.standard.set(sanitized, forKey: "custom_api_url")
        print("🔧 [APIConfig] Custom API URL set to: \(sanitized)")
    }
    
    func clearCustomAPIURL() {
        UserDefaults.standard.removeObject(forKey: "custom_api_url")
        print("🔧 [APIConfig] Custom API URL cleared, using default: \(baseURL)")
    }
    
    func getCurrentConfiguration() -> [String: String] {
        return [
            "environment": String(describing: AppEnvironment.current),
            "baseURL": baseURL,
            "authBaseURL": authBaseURL,
            "uploadBaseURL": uploadBaseURL,
            "userBaseURL": userBaseURL,
            "isSimulator": String(isSimulator),
            "customURL": UserDefaults.standard.string(forKey: "custom_api_url") ?? "None",
            "preferProduction": String(UserDefaults.standard.bool(forKey: "prefer_production_backend"))
        ]
    }
    
    // MARK: - Network Connectivity Test
    func testConnectivity() async -> Bool {
        func check(_ urlString: String) async -> Bool {
            guard let u = URL(string: urlString) else { return false }
            var req = URLRequest(url: u)
            req.httpMethod = "GET"
            let cfg = URLSessionConfiguration.ephemeral
            cfg.timeoutIntervalForRequest = 5.0
            cfg.timeoutIntervalForResource = 10.0
            cfg.connectionProxyDictionary = [:]
            cfg.tlsMinimumSupportedProtocolVersion = .TLSv12
            cfg.tlsMaximumSupportedProtocolVersion = .TLSv13
            let session = URLSession(configuration: cfg)
            do {
                let (_, resp) = try await session.data(for: req)
                if let http = resp as? HTTPURLResponse { return http.statusCode == 200 }
            } catch {
                print("❌ [APIConfig] Connectivity test failed: \(error)")
            }
            return false
        }
        let baseOk = await check("\(baseURL)/api/health")
        if baseOk { return true }
        let prodOk = await check("\(sanitizeURL(productionBaseURLRaw))/api/health")
        return prodOk
    }
}

// MARK: - Development Helper
#if DEBUG
extension APIConfig {
    func getAvailableConfigurations() -> [String: String] {
        return [
            "staging": sanitizeURL(stagingBaseURLRaw),
            "production": sanitizeURL(productionBaseURLRaw),
            "localhost": "http://localhost:3001",
            "local_ip": "http://192.168.0.105:3001"
        ]
    }
}
#endif
