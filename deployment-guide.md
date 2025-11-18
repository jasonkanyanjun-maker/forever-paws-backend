# Forever Paws 生产环境部署指南

## 🎉 部署状态

✅ **已完成的步骤：**
- 后端API构建完成
- 所有安全检查通过
- 数据库迁移验证完成
- Railway项目创建成功
- iOS配置文件已更新

## 📋 当前状态

### Railway 项目信息
- **项目名称**: forever-paws-api
- **项目URL**: https://railway.com/project/c27b0b27-1439-42ff-886c-b70b6a633006
- **状态**: 项目已创建，需要升级账户计划

### iOS 配置更新
- **APIConfig.swift**: 已更新生产环境URL
- **生产环境URL**: `https://forever-paws-api-production.up.railway.app`
- **预备环境URL**: `https://forever-paws-api-staging.up.railway.app`

## ⚠️ 需要处理的问题

### Railway 账户限制
当前Railway账户处于限制计划，无法完成部署。需要：

1. **访问 Railway 账户设置**
   - 打开: https://railway.com/account/plans
   - 升级到付费计划以支持部署

2. **完成部署**
   ```bash
   cd /Users/junlish/Desktop/test/api
   railway up
   ```

## 🚀 部署完成后的步骤

### 1. 验证部署
```bash
# 检查部署状态
railway status

# 获取实际部署URL
railway domain

# 测试健康检查
curl https://your-actual-domain.railway.app/api/health
```

### 2. 更新iOS配置
如果实际部署URL与预设不同，需要更新 `APIConfig.swift`:
```swift
private let productionBaseURL = "https://your-actual-domain.railway.app"
```

### 3. 环境变量配置
确保在Railway项目中配置以下环境变量：
- `NODE_ENV=production`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- 其他必要的环境变量

### 4. 数据库迁移
部署完成后，运行数据库迁移：
```bash
railway run npm run migrate
```

## 📱 iOS 应用配置

### 当前配置
iOS应用已配置为根据环境自动选择API端点：
- **开发环境**: `http://localhost:3001` (模拟器) / `http://192.168.0.105:3001` (真机)
- **预备环境**: `https://forever-paws-api-staging.up.railway.app`
- **生产环境**: `https://forever-paws-api-production.up.railway.app`

### 环境切换
应用会根据编译配置自动选择环境：
- `DEBUG` 模式 → 开发环境
- `STAGING` 模式 → 预备环境
- `RELEASE` 模式 → 生产环境

## 🔧 故障排除

### 常见问题
1. **Railway部署失败**
   - 检查账户计划限制
   - 验证项目配置文件
   - 查看部署日志

2. **API连接失败**
   - 验证URL配置
   - 检查网络连接
   - 确认健康检查端点

3. **环境变量问题**
   - 在Railway控制台检查变量配置
   - 确保敏感信息正确设置

## 📞 支持

如需帮助，请：
1. 检查Railway项目控制台
2. 查看部署日志
3. 验证环境变量配置
4. 测试API端点可访问性

---

**下一步**: 升级Railway账户计划并完成部署