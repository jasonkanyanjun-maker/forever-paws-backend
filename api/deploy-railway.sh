#!/bin/bash
# Railway 一键部署脚本 - 解决 IPv6 和 404 问题

echo "🚀 开始 Railway 部署流程..."

# 检查是否已登录
if ! railway whoami > /dev/null 2>&1; then
    echo "❌ 请先登录 Railway:"
    echo "railway login"
    exit 1
fi

# 检查是否在项目目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在 API 项目目录中运行此脚本"
    exit 1
fi

echo "📋 当前 Railway 状态:"
railway status

echo ""
echo "⚙️ 设置 IPv6 环境变量..."
railway variables set HOSTNAME="::"

echo ""
echo "🔍 检查环境变量:"
railway variables | grep -E "(HOSTNAME|PORT)"

echo ""
echo "🚀 开始部署..."
railway up

echo ""
echo "⏳ 等待部署完成..."
sleep 10

echo ""
echo "📊 检查部署状态:"
railway deployments

echo ""
echo "📝 查看日志:"
railway logs | tail -20

echo ""
echo "✅ 部署完成！测试端点:"
echo "健康检查: curl https://forever-paws-api-staging.up.railway.app/api/health"
echo "注册测试: curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register ..."