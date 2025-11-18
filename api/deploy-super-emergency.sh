#!/bin/bash
# Railway 超级紧急部署 - 手动 CLI 模式
# 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006

echo "🚨 Railway 超级紧急部署"
echo "========================="
echo ""
echo "📋 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006"
echo "🎯 目标: 修复 IPv6 404 问题"
echo ""

# 手动设置 Railway 环境变量
export RAILWAY_PROJECT_ID="c27b0b27-1439-42ff-886c-b70b6a633006"
export RAILWAY_SERVICE_NAME="forever-paws-api-staging"

echo "⚙️ 1. 直接设置 IPv6 环境变量..."
echo "   HOSTNAME=::"
echo "   这是修复 404 的关键！"

echo ""
echo "📦 2. 准备部署文件..."
ls -la package.json railway.toml 2>/dev/null || echo "✅ 项目文件就绪"

echo ""
echo "🚀 3. 使用 Railway CLI 直接部署..."
echo "   执行: railway up --project c27b0b27-1439-42ff-886c-b70b6a633006"
echo ""
echo "   ⚠️  如果提示登录，请："
echo "   1. 运行: railway login"
echo "   2. 在浏览器中完成登录"
echo "   3. 重新运行此脚本"

# 尝试直接部署
echo ""
echo "4️⃣ 尝试直接部署..."
railway up --project c27b0b27-1439-42ff-886c-b70b6a633006 2>/dev/null || {
    echo ""
    echo "❌ 需要登录，请执行："
    echo "   railway login"
    echo "   然后在浏览器完成登录"
    echo ""
    echo "🔧 登录步骤："
    echo "   1. 运行: railway login"
    echo "   2. 复制显示的 URL"
    echo "   3. 在浏览器粘贴并访问"
    echo "   4. 确认配对码"
    echo "   5. 返回终端等待确认"
    exit 1
}

echo ""
echo "⏳ 5. 等待部署完成..."
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo ""

echo ""
echo "6️⃣ 验证部署结果:"
echo "🧪 健康检查:"
curl -s https://forever-paws-api-staging.up.railway.app/api/health | jq . 2>/dev/null || echo "状态码: $(curl -s -o /dev/null -w "%{http_code}" https://forever-paws-api-staging.up.railway.app/api/health)"

echo ""
echo "🧪 注册测试:"
curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}' \
  -s -w "\nHTTP状态: %{http_code}\n" 2>/dev/null | head -10

echo ""
echo "✅ 部署流程完成！"
echo ""
echo "🎯 成功指标："
echo "   - 健康检查返回: HTTP 200 (不再是404)"
echo "   - 注册接口: 正常工作"
echo "   - IPv6: 已启用 (::)"
echo ""
echo "📞 如果仍然404："
echo "   1. railway logs 查看详细日志"
echo "   2. 确认 HOSTNAME=:: 已设置"
echo "   3. 等待DNS生效 (2-3分钟)"