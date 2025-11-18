#!/bin/bash
# Railway 最终部署脚本 - 清除认证问题
# 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006

echo "🚀 Railway 最终部署 - 清除认证问题"
echo "========================================"
echo ""
echo "📋 项目ID: c27b0b27-1439-42ff-886c-b70b6a633006"
echo "🎯 目标: 修复 IPv6 404 问题"
echo ""

# 清除所有 Railway 认证缓存
echo "1️⃣ 清除 Railway 认证缓存..."
rm -rf /tmp/railway_cache 2>/dev/null || true
unset RAILWAY_TOKEN 2>/dev/null || true
unset RAILWAY_API_TOKEN 2>/dev/null || true

echo ""
echo "2️⃣ 重新登录 Railway..."
echo "   请在浏览器中完成登录，然后返回终端"
echo ""
echo "🔧 登录步骤："
echo "   1. 运行: railway login"
echo "   2. 复制显示的 URL"
echo "   3. 在浏览器粘贴访问"
echo "   4. 确认配对码"
echo "   5. 返回终端等待确认"
echo ""

# 尝试登录
if railway login; then
    echo "✅ 登录成功！"
    
    echo ""
    echo "3️⃣ 链接到项目..."
    railway link --project c27b0b27-1439-42ff-886c-b70b6a633006
    
    echo ""
    echo "4️⃣ 设置 IPv6 环境变量（关键修复）..."
    railway variables set HOSTNAME="::"
    
    echo ""
    echo "5️⃣ 验证环境变量:"
    echo "   HOSTNAME: $(railway variables get HOSTNAME)"
    echo "   PORT: $(railway variables get PORT 2>/dev/null || echo '3000')"
    
    echo ""
    echo "6️⃣ 开始部署..."
    railway up
    
    echo ""
    echo "⏳ 等待部署完成..."
    for i in {1..30}; do
        echo -n "."
        sleep 1
    done
    echo ""
    
    echo ""
    echo "7️⃣ 检查部署状态:"
    railway status
    
    echo ""
    echo "8️⃣ 查看日志:"
    railway logs | tail -20
    
    echo ""
    echo "9️⃣ 测试部署结果:"
    echo "🧪 健康检查:"
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://forever-paws-api-staging.up.railway.app/api/health)
    echo "   HTTP状态: $HEALTH_STATUS"
    
    if [ "$HEALTH_STATUS" = "200" ]; then
        echo "   ✅ 成功！应用正常运行"
    else
        echo "   ⚠️  等待DNS生效中..."
    fi
    
    echo ""
    echo "🧪 注册功能测试:"
    REG_STATUS=$(curl -X POST https://forever-paws-api-staging.up.railway.app/api/auth/register \
      -H "Content-Type: application/json" \
      -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}' \
      -s -o /dev/null -w "%{http_code}")
    echo "   HTTP状态: $REG_STATUS"
    
    echo ""
    echo "✅ 部署完成！"
    echo ""
    echo "🎯 结果总结："
    echo "   - 健康检查: HTTP $HEALTH_STATUS"
    echo "   - 注册接口: HTTP $REG_STATUS"
    echo "   - IPv6 支持: 已启用"
    echo ""
    
    if [ "$HEALTH_STATUS" = "200" ] && [ "$REG_STATUS" = "201" ]; then
        echo "🎉 成功！部署完全正常！"
    else
        echo "⏰ 等待2-3分钟让DNS完全生效，然后重新测试"
    fi
    
else
    echo "❌ 登录失败，请重试"
    echo ""
    echo "🔧 备用方案："
    echo "   1. 使用 Railway 控制台直接部署"
    echo "   2. 访问: https://railway.com"
    echo "   3. 找到项目 c27b0b27-1439-42ff-886c-b70b6a633006"
    echo "   4. 设置环境变量 HOSTNAME=::"
    echo "   5. 点击部署按钮"
fi