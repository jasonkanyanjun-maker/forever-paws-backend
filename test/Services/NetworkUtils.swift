import Foundation

struct NetworkUtils {
    /// 粗略检测是否存在活跃的 VPN 接口（utun/ppp/ipsec/tun/tap/wg 等）
    static func isVPNActive() -> Bool {
        var addresses: [String] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr {
            var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
            while let current = ptr?.pointee {
                if let nameC = current.ifa_name {
                    let name = String(cString: nameC)
                    addresses.append(name)
                }
                ptr = current.ifa_next
            }
        }
        freeifaddrs(ifaddrPtr)

        // 常见的 VPN/隧道接口名前缀
        let vpnPrefixes = ["utun", "ppp", "ipsec", "tun", "tap", "wg", "vpn"]
        return addresses.contains { iface in
            vpnPrefixes.contains { prefix in iface.lowercased().hasPrefix(prefix) }
        }
    }

    static func pingHTTPS(host: String, path: String = "/", timeout: TimeInterval = 3.0) async -> Bool {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = host
        comps.path = path
        guard let url = comps.url else { return false }
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = timeout
        cfg.timeoutIntervalForResource = timeout
        cfg.connectionProxyDictionary = [:]
        let session = URLSession(configuration: cfg)
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.httpShouldHandleCookies = false
        do {
            let (_, resp) = try await session.data(for: req)
            if let http = resp as? HTTPURLResponse { return (200...399).contains(http.statusCode) }
        } catch {
            // 部分服务不支持 HEAD，退回 GET
            do {
                req.httpMethod = "GET"
                let (_, resp2) = try await session.data(for: req)
                if let http2 = resp2 as? HTTPURLResponse { return (200...399).contains(http2.statusCode) }
            } catch {
                return false
            }
        }
        return false
    }
}
