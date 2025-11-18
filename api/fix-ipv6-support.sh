#!/bin/bash

# Railway IPv6 支持修复脚本
# 解决 Railway 部署的网络连接问题

echo "🔧 修复 Railway IPv6 支持"
echo "================================="

# 1. 检查当前服务器配置
echo "📍 步骤1: 检查当前服务器绑定配置"
echo "当前服务器绑定配置:"
grep -n "listen\|server.listen" /Users/jason/Desktop/test\ 2/test/test/api/src/server.ts

# 2. 检查 Express 应用配置  
echo -e "\n📍 步骤2: 检查 Express 应用配置"
echo "Express 信任代理设置:"
grep -n "trust proxy" /Users/jason/Desktop/test\ 2/test/test/api/src/app.ts

# 3. 检查环境变量配置
echo -e "\n📍 步骤3: 检查 Railway 环境变量"
echo "需要检查的环境变量:"
echo "- PORT (Railway 自动分配)"
echo "- HOSTNAME (建议设置为 ::)"
echo "- NODE_ENV"

# 4. 测试当前部署状态
echo -e "\n📍 步骤4: 测试当前部署状态"
echo "生产环境:"
curl -s -o /dev/null -w "%{http_code}" https://forever-paws-api-production.up.railway.app/api/health || echo "连接失败"

echo "Staging 环境:"
curl -s -o /dev/null -w "%{http_code}" https://forever-paws-api-staging.up.railway.app/api/health || echo "连接失败"

# 5. 提供修复建议
echo -e "\n🔧 修复建议:"
echo "1. 服务器绑定地址已从 '0.0.0.0' 改为 '::'"
echo "2. 在 Railway 环境变量中添加: HOSTNAME=::"
echo "3. 确保 Express 应用设置: app.set('trust proxy', 1)"
echo "4. 重新部署应用到 Railway"

echo -e "\n📚 Railway IPv6 配置要点:"
echo "- Railway 内部网络使用 IPv6"
echo "- 公共服务需要绑定到 :: 以支持 IPv4/IPv6 双栈"
echo "- 私有网络通信必须使用 IPv6"
echo "- 某些库需要显式配置 family=0 参数"

echo -e "\n✅ 修复脚本完成！"
echo "下一步: 重新构建并部署到 Railway"