#!/bin/bash
# Railway 直接部署脚本 - 使用项目ID
# 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006

set -e

PROJECT_ID="c27b0b27-1439-42ff-886c-b70b6a633006"
echo "🚀 开始 Railway 项目部署..."
echo "📋 项目ID: $PROJECT_ID"

# 检查是否已登录
if ! railway whoami > /dev/null 2>&1; then
    echo "❌ 未登录 Railway，请先运行: railway login"
    exit 1
fi

# 直接使用项目ID设置环境变量
export RAILWAY_PROJECT_ID="$PROJECT_ID"

echo "⚙️ 设置 IPv6 环境变量..."
railway variables set HOSTNAME="::" --project "$PROJECT_ID"

echo "🔍 检查当前环境变量:"
railway variables --project "$PROJECT_ID"

echo ""
echo "🚀 开始部署..."
railway up --project "$PROJECT_ID"

echo ""
echo "⏳ 等待部署完成..."
sleep 15

echo ""
echo "📊 检查部署状态:"
railway status --project "$PROJECT_ID"

echo ""
echo "📝 查看最近日志:"
railway logs --project "$PROJECT_ID" | tail -30

echo ""
echo "✅ 部署完成！测试端点:"
echo "健康检查:"
curl -s https://forever-paws-api-staging.up.railway.app/api/health || echo "等待DNS更新中..."

echo ""
echo "注册测试:"
curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}' || echo "等待DNS更新中..."

echo ""
echo "🎯 部署完成！如果测试失败，请等待2-3分钟让DNS生效"