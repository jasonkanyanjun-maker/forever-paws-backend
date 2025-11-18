import SwiftUI

struct DeveloperSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var customAPIURL = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTestingConnection = false
    @State private var connectionStatus = "未测试"
    @State private var preferProduction = UserDefaults.standard.bool(forKey: "prefer_production_backend")
    
    private let apiConfig = APIConfig.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Supabase 配置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前 Supabase URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(SupabaseConfig.url)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义 Supabase URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入 Supabase 项目域名 https://xxxx.supabase.co", text: $customAPIURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Button("设置 Supabase URL") {
                            SupabaseConfig.setURL(customAPIURL)
                            alertMessage = "Supabase URL 已更新为: \(SupabaseConfig.url)"
                            showingAlert = true
                        }
                        .disabled(customAPIURL.isEmpty)

                        Spacer()

                        Button("重置 Supabase URL") {
                            SupabaseConfig.setURL("")
                            alertMessage = "已重置 Supabase URL: \(SupabaseConfig.url)"
                            showingAlert = true
                        }
                        .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义 Supabase 匿名密钥")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入 Supabase 匿名密钥", text: $customAPIURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Button("设置 Anon Key") {
                            SupabaseConfig.setAnonKey(customAPIURL)
                            alertMessage = "Anon Key 已更新（前20位）: \(SupabaseConfig.anonKey.prefix(20))..."
                            showingAlert = true
                        }
                        .disabled(customAPIURL.isEmpty)

                        Spacer()

                        Button("重置 Anon Key") {
                            SupabaseConfig.setAnonKey("")
                            alertMessage = "Anon Key 已重置"
                            showingAlert = true
                        }
                        .foregroundColor(.orange)
                    }
                }
                Section("API 配置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前 API URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(apiConfig.baseURL)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义 API URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入自定义 API URL", text: $customAPIURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Button("设置自定义 URL") {
                            setCustomURL()
                        }
                        .disabled(customAPIURL.isEmpty)
                        
                        Spacer()
                        
                        Button("重置为默认") {
                            resetToDefault()
                        }
                        .foregroundColor(.orange)
                    }

                    Toggle(isOn: $preferProduction) {
                        VStack(alignment: .leading) {
                            Text("优先使用生产后端")
                            Text("在开发/预备环境下仍指向生产 API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: preferProduction) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "prefer_production_backend")
                        alertMessage = "已更新：优先使用生产后端 = \(newValue ? "是" : "否")\n当前 API: \(apiConfig.baseURL)"
                        showingAlert = true
                    }
                }
                
                Section("连接测试") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("连接状态")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(connectionStatus)
                                .foregroundColor(connectionStatusColor)
                        }
                        
                        Spacer()
                        
                        Button("测试连接") {
                            testConnection()
                        }
                        .disabled(isTestingConnection)
                    }
                    
                    if isTestingConnection {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在测试连接...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("环境信息") {
                    ForEach(Array(apiConfig.getCurrentConfiguration().sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(value)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                #if DEBUG
                Section("开发选项") {
                    ForEach(Array(apiConfig.getAvailableConfigurations().sorted(by: { $0.key < $1.key })), id: \.key) { name, url in
                        Button("使用 \(name)") {
                            customAPIURL = url
                            setCustomURL()
                        }
                    }
                }
                #endif
            }
            .navigationTitle("开发者设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentSettings()
                preferProduction = UserDefaults.standard.bool(forKey: "prefer_production_backend")
            }
        }
    }
    
    private var connectionStatusColor: Color {
        switch connectionStatus {
        case "连接成功":
            return .green
        case "连接失败":
            return .red
        default:
            return .secondary
        }
    }
    
    private func loadCurrentSettings() {
        if let customURL = UserDefaults.standard.string(forKey: "custom_api_url") {
            customAPIURL = customURL
        }
    }
    
    private func setCustomURL() {
        guard !customAPIURL.isEmpty else { return }
        
        // 验证 URL 格式
        guard URL(string: customAPIURL) != nil else {
            alertMessage = "无效的 URL 格式"
            showingAlert = true
            return
        }
        
        apiConfig.setCustomAPIURL(customAPIURL)
        alertMessage = "API URL 已更新为: \(customAPIURL)"
        showingAlert = true
    }
    
    private func resetToDefault() {
        apiConfig.clearCustomAPIURL()
        customAPIURL = ""
        alertMessage = "已重置为默认 API URL: \(apiConfig.baseURL)"
        showingAlert = true
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = "测试中..."
        
        Task {
            let isConnected = await apiConfig.testConnectivity()
            
            await MainActor.run {
                isTestingConnection = false
                connectionStatus = isConnected ? "连接成功" : "连接失败"
            }
        }
    }
}

#Preview {
    DeveloperSettingsView()
}
