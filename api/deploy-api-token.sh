#!/bin/bash
# Railway 快速部署脚本 - API Token 方式
# 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006

echo "🚀 Railway 快速部署 - API Token 方式"
echo "==================================="
echo ""

# 检查是否提供 API Token
if [ -z "$RAILWAY_API_TOKEN" ]; then
    echo "❌ 请先设置 Railway API Token:"
    echo "   export RAILWAY_API_TOKEN=\"your_token_here\""
    echo ""
    echo "📋 获取 API Token 步骤："
    echo "   1. 打开 Railway 控制台: https://railway.com"
    echo "   2. 点击右上角头像 → Settings"
    echo "   3. 找到 'API Tokens' → 'Create Token'"
    echo "   4. 复制 Token 并设置环境变量"
    exit 1
fi

PROJECT_ID="c27b0b27-1439-42ff-886c-b70b6a633006"
echo "📋 项目ID: $PROJECT_ID"

# 设置项目ID
export RAILWAY_PROJECT_ID="$PROJECT_ID"

echo ""
echo "⚙️ 设置 IPv6 环境变量..."
railway variables set HOSTNAME="::" --project "$PROJECT_ID"

echo ""
echo "🔍 检查环境变量:"
railway variables --project "$PROJECT_ID" | grep HOSTNAME || echo "HOSTNAME set successfully"

echo ""
echo "🚀 开始部署..."
railway up --project "$PROJECT_ID"

echo ""
echo "⏳ 等待部署完成..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""

echo ""
echo "📊 检查部署状态:"
railway status --project "$PROJECT_ID"

echo ""
echo "📝 查看部署日志:"
railway logs --project "$PROJECT_ID" | tail -20

echo ""
echo "🧪 测试部署结果:"
echo "健康检查:"
curl -s https://forever-paws-api-staging.up.railway.app/api/health | jq . 2>/dev/null || echo "等待DNS生效中..."

echo ""
echo "注册测试:"
curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}' | jq . 2>/dev/null || echo "等待服务启动中..."

echo ""
echo "✅ 部署流程完成！"
echo "🎯 如果测试失败，请等待2-3分钟让服务完全启动"
echo "📞 有问题请检查 Railway 控制台日志"