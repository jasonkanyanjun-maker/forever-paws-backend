#!/bin/bash

# 测试注册流程脚本
# 用于验证本地服务器和iOS应用配置

echo "🧪 测试 Forever Paws 注册流程"
echo "================================="

# 测试1: 检查本地服务器健康状态
echo "📍 步骤1: 检查本地服务器健康状态"
curl -s http://localhost:3001/api/health | jq .

# 测试2: 测试注册端点
echo -e "\n📍 步骤2: 测试注册端点"
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "Test123456",
    "name": "测试用户"
  }')

echo "注册响应: $REGISTER_RESPONSE"

# 测试3: 测试登录端点
echo -e "\n📍 步骤3: 测试登录端点"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "Test123456"
  }')

echo "登录响应: $LOGIN_RESPONSE"

# 测试4: 检查服务器日志
echo -e "\n📍 步骤4: 检查服务器状态"
echo "服务器进程:"
ps aux | grep -v grep | grep emergency-server || echo "❌ 服务器未运行"

echo -e "\n✅ 测试完成！"
echo "📱 现在可以在iOS应用中设置API URL为: http://localhost:3001"
echo "🔧 在开发者设置中配置自定义API URL"