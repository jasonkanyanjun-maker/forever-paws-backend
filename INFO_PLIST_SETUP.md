// Info.plist 配置模板
// 由于 Xcode 自动生成 Info.plist 与 Swift Package 资源处理冲突，
// 请手动在 Xcode 项目中添加以下配置：

/*
在 Xcode 中执行以下步骤：

1. 选择项目导航器中的 test 项目
2. 选择 test target
3. 切换到 "Info" 标签页
4. 添加以下自定义配置：

对于 HTTP 支持，添加：
- Key: NSAppTransportSecurity
  Type: Dictionary
  Value: 
    - NSAllowsArbitraryLoads: YES (Boolean)
    - NSAllowsArbitraryLoadsInWebContent: YES (Boolean)  
    - NSAllowsLocalNetworking: YES (Boolean)
    - NSExceptionDomains: Dictionary
      - localhost: Dictionary
        - NSExceptionAllowsInsecureHTTPLoads: YES (Boolean)
        - NSExceptionMinimumTLSVersion: "TLSv1.0" (String)
        - NSExceptionRequiresForwardSecrecy: NO (Boolean)
      - 127.0.0.1: Dictionary (同上)
      - 192.168.0.105: Dictionary (同上)

对于照片权限，添加：
- Key: NSPhotoLibraryUsageDescription  
  Type: String
  Value: "Forever Paws 需要访问您的照片库来上传宠物照片"

- Key: NSPhotoLibraryAddUsageDescription
  Type: String  
  Value: "Forever Paws 需要保存照片到您的相册"

5. 确保在 "Build Settings" 中：
   - Generate Info.plist File: YES
   - 不要手动指定 Info.plist File 路径
*/

// 或者，作为替代方案，考虑使用 Swift Package 的构建系统
// 完全移除 .xcodeproj 文件，只使用 swift build 命令