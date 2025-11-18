#!/bin/bash
# Railway 手动部署指南 - 使用浏览器登录方式

echo "🚀 Railway 部署指南"
echo "=================="
echo ""
echo "📋 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006"
echo ""

# 检查是否已登录
echo "1️⃣ 检查登录状态..."
if railway whoami > /dev/null 2>&1; then
    echo "✅ 已登录 Railway: $(railway whoami)"
else
    echo "❌ 未登录 Railway"
    echo ""
    echo "2️⃣ 请使用浏览器登录..."
    echo "请在浏览器中访问: https://railway.com"
    echo "登录后，点击右上角头像 → Settings → API Tokens"
    echo "创建新的 API Token，然后运行:"
    echo "   railway login --token YOUR_API_TOKEN"
    exit 1
fi

echo ""
echo "3️⃣ 链接到项目..."
railway link --project c27b0b27-1439-42ff-886c-b70b6a633006

echo ""
echo "4️⃣ 设置 IPv6 环境变量..."
railway variables set HOSTNAME="::"

echo ""
echo "5️⃣ 检查环境变量:"
railway variables | grep -E "(HOSTNAME|PORT)" || echo "HOSTNAME: $(railway variables get HOSTNAME)"

echo ""
echo "6️⃣ 开始部署..."
railway up

echo ""
echo "⏳ 等待部署完成（约30秒）..."
sleep 30

echo ""
echo "7️⃣ 检查部署状态:"
railway status

echo ""
echo "8️⃣ 查看日志:"
railway logs | tail -20

echo ""
echo "9️⃣ 测试部署结果:"
echo "健康检查测试:"
curl -s https://forever-paws-api-staging.up.railway.app/api/health || echo "等待DNS生效中..."

echo ""
echo "🔚 部署完成！"
echo "如果测试失败，请等待2-3分钟让DNS生效"
echo "可以手动测试:"
echo "curl https://forever-paws-api-staging.up.railway.app/api/health"