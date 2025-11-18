# Railway IPv6 部署步骤指南

## 🎯 目标
解决 Railway 部署的 404 错误问题，通过配置 IPv6 支持使应用正常访问。

## 📋 前提条件
- 已安装 Railway CLI: `npm install -g @railway/cli`
- 已有 Railway 账号和项目

## 🔧 步骤 1: 登录 Railway
```bash
railway login
```
在浏览器中完成登录授权。

## 🔗 步骤 2: 链接到现有项目
```bash
railway link
```
选择你的 Forever Paws 项目。

## ⚙️ 步骤 3: 配置 IPv6 环境变量
设置关键的环境变量：
```bash
railway variables set HOSTNAME="::"
```

## 🚀 步骤 4: 部署应用
```bash
railway up
```

## ✅ 步骤 5: 验证部署
部署完成后检查：
```bash
railway logs
```

测试端点：
```bash
# 健康检查
curl https://your-app.railway.app/api/health

# 注册测试
curl -X POST https://your-app.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456","name":"Test User"}'
```

## 🔍 故障排除

### 如果仍然 404
1. 检查环境变量是否设置成功：
   ```bash
   railway variables
   ```

2. 确认服务器监听配置：
   ```bash
   railway logs | grep "listening on"
   ```

3. 检查端口配置：
   ```bash
   railway variables set PORT="3000"
   ```

### IPv6 验证
使用命令检查 IPv6 监听：
```bash
railway ssh
netstat -tlnp | grep :::3000
```

## 📊 预期结果
- ✅ Health check 返回 200 状态码
- ✅ 注册接口返回正确响应
- ✅ 不再出现 "Application not found" 404 错误

## 🔄 回滚方案
如果部署失败，可以回滚到之前的版本：
```bash
railway deployments
railway deployment rollback [previous-deployment-id]
```

## 📞 支持
如果仍有问题，可以：
1. 查看 Railway 官方文档：https://docs.railway.com/guides/private-networking
2. 联系 Railway 支持团队
3. 检查应用日志获取详细错误信息