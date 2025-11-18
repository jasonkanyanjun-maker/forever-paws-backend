#!/bin/bash

# Swift Package Info.plist 配置脚本
# 用于解决 Swift Package 与 Xcode 项目的 Info.plist 冲突

echo "🔧 配置 Swift Package Info.plist"
echo "================================="

# 创建配置目录
mkdir -p Configuration

# 创建 Info.plist 文件
cat > Configuration/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- 关键配置：允许 HTTP 连接用于开发 -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsArbitraryLoadsInWebContent</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.0</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
            <key>127.0.0.1</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.0</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
            <key>192.168.0.105</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.0</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
        </dict>
    </dict>
    
    <!-- 照片库权限 -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Forever Paws 需要访问您的照片库来上传宠物照片</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Forever Paws 需要保存照片到您的相册</string>
</dict>
</plist>
EOF

echo "✅ Info.plist 已创建在 Configuration 目录"
echo "📍 文件位置: Configuration/Info.plist"
echo ""
echo "🔧 下一步操作："
echo "1. 清理构建缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/"
echo "2. 使用 swift build 构建项目"
echo "3. 或者在 Xcode 中打开 Package.swift 文件"
echo ""
echo "⚠️  注意：如果仍然遇到构建问题，考虑："
echo "   - 完全删除 .xcodeproj 文件"
echo "   - 只使用 Swift Package 构建系统"
echo "   - 使用 xcodebuild -scheme test 命令构建"