#!/bin/bash

# Forever Paws API 部署脚本
echo "🚀 开始部署 Forever Paws API 到 Railway..."

# 检查是否已登录
echo "📋 检查 Railway 登录状态..."
if ! railway whoami > /dev/null 2>&1; then
    echo "❌ 未登录 Railway，请先运行: railway login"
    exit 1
fi

# 检查构建文件
echo "📦 检查构建文件..."
if [ ! -d "dist" ]; then
    echo "🔨 构建项目..."
    npm run build
fi

# 部署到 Railway
echo "🚀 部署到 Railway..."
railway up

# 获取部署 URL
echo "🔗 获取部署 URL..."
DEPLOY_URL=$(railway status --json | jq -r '.deployments[0].url' 2>/dev/null)

if [ "$DEPLOY_URL" != "null" ] && [ -n "$DEPLOY_URL" ]; then
    echo "✅ 部署成功！"
    echo "🌐 生产环境 URL: $DEPLOY_URL"
    
    # 保存 URL 到文件
    echo "$DEPLOY_URL" > deployment-url.txt
    echo "📄 URL 已保存到 deployment-url.txt"
    
    # 测试健康检查
    echo "🏥 测试健康检查..."
    if curl -f "$DEPLOY_URL/api/health" > /dev/null 2>&1; then
        echo "✅ 健康检查通过"
    else
        echo "⚠️ 健康检查失败，请检查部署状态"
    fi
else
    echo "❌ 无法获取部署 URL，请检查部署状态"
    railway status
fi

echo "🎉 部署脚本执行完成"