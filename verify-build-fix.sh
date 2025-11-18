#!/bin/bash

# Xcode 构建错误修复验证脚本

echo "🔍 验证 Xcode 构建配置修复"
echo "================================="

# 检查 Info.plist 文件位置
echo "📍 检查 Info.plist 文件位置："
if [ -f "/Users/jason/Desktop/test 2/test/test/test/Info.plist" ]; then
    echo "✅ Info.plist 存在于正确位置"
else
    echo "❌ Info.plist 不存在"
fi

# 检查 HTTP 配置
echo -e "\n🔍 检查 HTTP 配置："
if grep -q "NSAllowsArbitraryLoads" /Users/jason/Desktop/test 2/test/test/test/Info.plist; then
    echo "✅ 包含 HTTP 安全配置"
else
    echo "❌ 缺少 HTTP 安全配置"
fi

# 检查 Xcode 项目配置
echo -e "\n🔍 检查 Xcode 项目配置："
GENERATE_COUNT=$(grep -c "GENERATE_INFOPLIST_FILE = NO" /Users/jason/Desktop/test 2/test/test/test.xcodeproj/project.pbxproj)
echo "找到 $GENERATE_COUNT 个 GENERATE_INFOPLIST_FILE = NO 配置"

INFO_COUNT=$(grep -c "INFOPLIST_FILE = test/Info.plist" /Users/jason/Desktop/test 2/test/test/test.xcodeproj/project.pbxproj)
echo "找到 $INFO_COUNT 个 INFOPLIST_FILE = test/Info.plist 配置"

# 检查本地服务器
echo -e "\n🌐 检查本地服务器状态："
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ 本地服务器运行正常"
else
    echo "❌ 本地服务器未响应"
fi

echo -e "\n✅ 修复验证完成！"
echo "📱 现在可以尝试重新构建 Xcode 项目"
echo "🔧 如果还有问题，请清理 DerivedData 并重新构建"