#!/bin/bash
# Railway 紧急部署脚本 - 手动操作模式
# 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006

set -e

echo "🚀 Railway 紧急部署 - 手动操作模式"
echo "======================================="
echo ""

PROJECT_ID="c27b0b27-1439-42ff-886c-b70b6a633006"
echo "📋 项目ID: $PROJECT_ID"

# 检查是否已登录
echo ""
echo "1️⃣ 检查登录状态..."
if railway whoami > /dev/null 2>&1; then
    echo "✅ 已登录: $(railway whoami)"
else
    echo "❌ 未登录 Railway"
    echo ""
    echo "🔧 手动登录步骤："
    echo "   1. 在浏览器中访问: https://railway.com/login"
    echo "   2. 登录成功后，回到终端运行: railway login"
    echo "   3. 或者使用: railway login --browserless"
    exit 1
fi

echo ""
echo "2️⃣ 链接到项目..."
railway link --project "$PROJECT_ID"

echo ""
echo "3️⃣ 设置 IPv6 环境变量（关键修复）..."
railway variables set HOSTNAME="::"

echo ""
echo "4️⃣ 验证环境变量:"
echo "HOSTNAME: $(railway variables get HOSTNAME)"
echo "PORT: $(railway variables get PORT 2>/dev/null || echo '3000 (默认)')"

echo ""
echo "5️⃣ 开始部署..."
railway up

echo ""
echo "⏳ 等待部署完成（约30秒）..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""

echo ""
echo "6️⃣ 检查部署状态:"
railway status

echo ""
echo "7️⃣ 查看最近日志:"
railway logs | tail -20

echo ""
echo "8️⃣ 测试部署结果:"
echo "🧪 健康检查测试:"
curl -s https://forever-paws-api-staging.up.railway.app/api/health | jq . 2>/dev/null || echo "状态: $(curl -s -o /dev/null -w "%{http_code}" https://forever-paws-api-staging.up.railway.app/api/health)"

echo ""
echo "🧪 注册功能测试:"
curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}' \
  -s | jq . 2>/dev/null || echo "等待服务启动中..."

echo ""
echo "✅ 部署完成！"
echo ""
echo "🎯 预期结果："
echo "   - 健康检查: HTTP 200 (不再是404)"
echo "   - 注册接口: 正常工作"
echo "   - IPv6 支持: 已启用"
echo ""
echo "📞 如果仍然404，请检查："
echo "   1. railway logs 查看详细错误"
echo "   2. 确认 HOSTNAME=:: 已设置"
echo "   3. 等待2-3分钟让DNS生效"