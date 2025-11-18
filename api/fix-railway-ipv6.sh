#!/bin/bash

# Railway 部署 IPv6 支持完整修复脚本
# 解决 Railway 平台上的网络连接问题

echo "🚀 Railway IPv6 支持完整修复"
echo "================================="

# 1. 检查当前应用配置
echo "📍 步骤1: 检查当前应用配置"
echo "服务器绑定配置:"
grep -A 5 -B 5 "server.listen" /Users/jason/Desktop/test\ 2/test/test/api/src/server.ts

# 2. 创建 Railway 环境变量配置
echo -e "\n📍 步骤2: 创建 Railway 环境变量配置"
cat > /Users/jason/Desktop/test\ 2/test/test/api/railway-env-fix.md << 'EOF'
# Railway 环境变量配置

## 必需的环境变量：

### 基础配置
NODE_ENV=staging
PORT=3000
HOSTNAME=::  # 关键：绑定到 IPv6

### Supabase 配置（修复版）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

### JWT 配置
JWT_SECRET=your_super_secure_jwt_secret_256_bits_minimum
JWT_EXPIRES_IN=7d

### 安全配置
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

### 日志配置
LOG_LEVEL=info

## 修复说明：

1. **HOSTNAME=::** - 这是关键修复，使应用监听 IPv6
2. **绑定地址** - 服务器代码已更新为监听 '::' 而不是 '0.0.0.0'
3. **双栈支持** - 现在支持 IPv4 和 IPv6 连接

## Railway 网络特点：
- 内部网络使用 IPv6
- 公共服务需要绑定到 :: 以支持双栈
- 某些库需要显式配置 family=0
- 私有网络只能使用 IPv6 地址
EOF

echo "✅ Railway 环境变量配置已创建"

# 3. 检查服务器代码修复
echo -e "\n📍 步骤3: 验证服务器代码修复"
if grep -q "'::'" /Users/jason/Desktop/test\ 2/test/test/api/src/server.ts; then
    echo "✅ 服务器已配置为监听 IPv6 (::)"
else
    echo "❌ 服务器未正确配置 IPv6 监听"
fi

# 4. 测试当前部署状态
echo -e "\n📍 步骤4: 测试当前部署状态"
echo "生产环境测试:"
curl -s -o /dev/null -w "HTTP 状态: %{http_code}, 响应时间: %{time_total}s\n" \
     https://forever-paws-api-production.up.railway.app/api/health || echo "❌ 生产环境连接失败"

echo -e "Staging 环境测试:"
curl -s -o /dev/null -w "HTTP 状态: %{http_code}, 响应时间: %{time_total}s\n" \
     https://forever-paws-api-staging.up.railway.app/api/health || echo "❌ Staging 环境连接失败"

# 5. 检查 DNS 和 IP 配置
echo -e "\n📍 步骤5: DNS 和 IP 配置检查"
echo "生产环境 DNS 解析:"
nslookup forever-paws-api-production.up.railway.app 2>/dev/null | grep -A 5 "Name:" || echo "DNS 查询失败"

echo -e "\nStaging 环境 DNS 解析:"
nslookup forever-paws-api-staging.up.railway.app 2>/dev/null | grep -A 5 "Name:" || echo "DNS 查询失败"

# 6. 提供部署建议
echo -e "\n🚀 部署建议:"
echo "1. 在 Railway 控制台中添加 HOSTNAME=:: 环境变量"
echo "2. 重新部署应用到 Railway"
echo "3. 检查应用是否正确监听 IPv6 地址"
echo "4. 验证健康检查端点是否正常工作"

echo -e "\n📚 Railway IPv6 关键信息:"
echo "- Railway 内部网络使用 IPv6 地址"
echo "- 公共服务需要绑定到 :: 以支持 IPv4/IPv6 双栈"
echo "- 某些数据库客户端需要 family=0 配置"
echo "- 私有网络通信必须使用 IPv6 地址"

echo -e "\n✅ 修复脚本完成！"
echo "下一步: 在 Railway 控制台配置环境变量并重新部署"