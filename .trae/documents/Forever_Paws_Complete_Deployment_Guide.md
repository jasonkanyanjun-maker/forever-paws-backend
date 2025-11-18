# Forever Paws 完整部署指南

## 1. 项目概述与当前状态

### 1.1 项目架构
Forever Paws 是一个宠物纪念应用，包含以下组件：
- **iOS 应用**: SwiftUI 开发，支持 iOS 15+
- **后端 API**: Node.js + TypeScript + Express + Supabase
- **数据库**: Supabase (PostgreSQL)
- **文件存储**: Supabase Storage
- **AI 服务**: 阿里云 DashScope

### 1.2 当前项目状态分析
```
✅ 后端 API 服务正常运行 (localhost:3001)
✅ Railway 部署配置已就绪 (railway.toml)
✅ iOS 应用开发完成，支持动态 API 配置
✅ Supabase 数据库结构完整
✅ 文件上传和存储功能正常
⚠️ 需要配置生产环境变量
⚠️ 需要 iOS 应用发布准备
```

## 2. 后端 API 部署方案 (Railway)

### 2.1 Railway 平台优势
- ✅ 原生支持 Node.js + TypeScript
- ✅ 自动 HTTPS 和域名分配
- ✅ 简单的环境变量管理
- ✅ GitHub 集成和自动部署
- ✅ 内置监控和日志系统
- ✅ 合理定价 ($5/月起)

### 2.2 部署前准备

#### 检查项目配置
```bash
# 1. 确认 package.json 脚本配置
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/start.js",
    "postinstall": "npm run build",
    "prestart": "npm run build"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}

# 2. 确认 Railway 配置文件 (railway.toml)
[build]
builder = "NIXPACKS"

[deploy]
healthcheckPath = "/api/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

### 2.3 Railway 部署步骤

#### 步骤 1: 准备代码仓库
```bash
# 1. 提交所有更改
git add .
git commit -m "Prepare for production deployment"
git push origin main

# 2. 确保 .gitignore 包含敏感文件
echo ".env" >> .gitignore
echo "logs/" >> .gitignore
echo "dist/" >> .gitignore
```

#### 步骤 2: Railway 部署
1. 访问 [railway.app](https://railway.app)
2. 点击 "New Project" → "Deploy from GitHub repo"
3. 选择 Forever Paws 仓库
4. Railway 会自动检测 Node.js 项目并开始构建

#### 步骤 3: 配置环境变量
在 Railway Dashboard 中设置以下环境变量：

```bash
# 基础配置
NODE_ENV=production
PORT=3000

# Supabase 生产配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_production_service_role_key

# JWT 安全配置
JWT_SECRET=your_super_secure_jwt_secret_256_bits_minimum
JWT_EXPIRES_IN=7d

# 阿里云 DashScope
DASHSCOPE_API_KEY=your_production_dashscope_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com

# 安全和性能配置
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=warn
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,video/mp4
```

#### 步骤 4: 获取生产域名
Railway 会自动分配域名，格式如：
```
https://forever-paws-backend-production.up.railway.app
```

## 3. Supabase 生产环境配置

### 3.1 创建生产项目
1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 创建新项目：`forever-paws-production`
3. 选择合适的地区（建议选择离用户最近的）
4. 记录项目信息：
   - Project URL
   - Anon Key  
   - Service Role Key

### 3.2 数据库迁移
```bash
# 1. 安装 Supabase CLI
npm install -g supabase

# 2. 登录并链接项目
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# 3. 推送所有迁移文件
supabase db push

# 4. 验证表结构
supabase db diff
```

### 3.3 配置 RLS (行级安全策略)
```sql
-- 启用所有表的 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 用户数据访问策略
CREATE POLICY "Users can manage own data" ON users
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can manage own profile" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own pets" ON pets
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own pet photos" ON pet_photos
  FOR ALL USING (auth.uid() = (SELECT user_id FROM pets WHERE pets.id = pet_photos.pet_id));
```

### 3.4 配置存储桶
```sql
-- 创建存储桶
INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true);

-- 配置存储策略
CREATE POLICY "Users can upload own images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view all images" ON storage.objects
  FOR SELECT USING (bucket_id = 'images');
```

## 4. iOS 应用发布准备

### 4.1 生产环境配置

#### 更新 APIConfig.swift
```swift
// 添加生产环境配置
var baseURL: String {
    #if DEBUG
    // 开发环境
    if let customURL = UserDefaults.standard.string(forKey: "custom_api_url"),
       !customURL.isEmpty {
        return customURL
    }
    return isSimulator ? "http://localhost:3001" : "http://192.168.0.105:3001"
    #else
    // 生产环境
    return "https://forever-paws-backend-production.up.railway.app"
    #endif
}
```

### 4.2 App Store 发布流程

#### 步骤 1: 项目配置检查
```bash
# 1. 检查 Bundle Identifier
# 确保在 Xcode 中设置唯一的 Bundle ID，如：
# com.foreverpaws.memorial

# 2. 检查版本号
# Version: 1.0.0
# Build: 1

# 3. 检查部署目标
# iOS Deployment Target: 15.0+
```

#### 步骤 2: 证书和配置文件
1. 登录 [Apple Developer Portal](https://developer.apple.com)
2. 创建 App ID
3. 创建分发证书 (Distribution Certificate)
4. 创建 App Store 配置文件 (Provisioning Profile)
5. 在 Xcode 中配置签名

#### 步骤 3: 应用图标和启动屏幕
```bash
# 应用图标尺寸要求：
- 1024x1024 (App Store)
- 180x180 (iPhone @3x)
- 120x120 (iPhone @2x)
- 167x167 (iPad Pro @2x)
- 152x152 (iPad @2x)
- 76x76 (iPad @1x)

# 启动屏幕：
- 支持所有设备尺寸
- 使用 LaunchScreen.storyboard
```

#### 步骤 4: 构建和上传
```bash
# 1. 在 Xcode 中选择 "Any iOS Device"
# 2. Product → Archive
# 3. 在 Organizer 中选择 "Distribute App"
# 4. 选择 "App Store Connect"
# 5. 上传到 App Store Connect
```

#### 步骤 5: App Store Connect 配置
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 创建新应用
3. 填写应用信息：
   - 应用名称：Forever Paws
   - 副标题：宠物纪念应用
   - 描述：详细的应用功能描述
   - 关键词：宠物,纪念,回忆,照片
   - 分类：生活方式
4. 上传截图（所有设备尺寸）
5. 设置价格和可用性
6. 提交审核

## 5. 生产环境配置清单

### 5.1 后端 API 配置清单
```bash
✅ Railway 部署配置
✅ 环境变量设置
✅ Supabase 生产项目
✅ 数据库迁移完成
✅ RLS 策略配置
✅ 存储桶配置
✅ 域名和 HTTPS
✅ 监控和日志
✅ 错误追踪
✅ 备份策略
```

### 5.2 iOS 应用配置清单
```bash
✅ 生产 API 端点配置
✅ Bundle ID 设置
✅ 版本号配置
✅ 应用图标完整
✅ 启动屏幕适配
✅ 证书和配置文件
✅ 隐私权限描述
✅ App Store 元数据
✅ 截图和预览
✅ 测试设备验证
```

## 6. 部署前检查和测试

### 6.1 后端 API 测试
```bash
# 1. 健康检查
curl https://your-api-domain.com/api/health

# 2. 认证测试
curl -X POST https://your-api-domain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123456"}'

# 3. 文件上传测试
curl -X POST https://your-api-domain.com/api/upload/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "avatar=@test-image.jpg"

# 4. 数据库连接测试
curl https://your-api-domain.com/api/user/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 6.2 iOS 应用测试
```bash
# 1. 网络连接测试
# 在应用中测试所有 API 调用

# 2. 功能测试清单
✅ 用户注册和登录
✅ 头像上传和显示
✅ 宠物资料添加
✅ 照片上传和管理
✅ 信件写作功能
✅ 数据同步
✅ 离线功能
✅ 推送通知
```

### 6.3 性能和安全测试
```bash
# 1. 负载测试
# 使用工具如 Artillery 或 k6 进行 API 负载测试

# 2. 安全扫描
# 检查 API 端点的安全性
# 验证 JWT token 过期机制
# 测试文件上传限制

# 3. 数据备份验证
# 确认 Supabase 自动备份功能
# 测试数据恢复流程
```

## 7. 监控和维护

### 7.1 监控设置
```bash
# 1. Railway 内置监控
- CPU 使用率
- 内存使用率
- 响应时间
- 错误率

# 2. Supabase 监控
- 数据库性能
- 存储使用量
- API 调用次数
- 用户活跃度

# 3. 第三方监控 (可选)
- Sentry (错误追踪)
- DataDog (性能监控)
- Uptime Robot (可用性监控)
```

### 7.2 日志管理
```bash
# 1. 应用日志级别
production: warn, error
development: info, debug

# 2. 日志轮转
# Railway 自动管理日志轮转

# 3. 关键事件日志
- 用户注册/登录
- 文件上传
- API 错误
- 数据库操作异常
```

### 7.3 维护计划
```bash
# 每日检查
✅ 服务可用性
✅ 错误日志
✅ 性能指标

# 每周检查
✅ 数据库性能
✅ 存储使用量
✅ 用户反馈

# 每月检查
✅ 安全更新
✅ 依赖包更新
✅ 备份验证
✅ 成本分析
```

## 8. 故障排除指南

### 8.1 常见问题
```bash
# 1. API 连接失败
- 检查 Railway 服务状态
- 验证环境变量配置
- 检查 Supabase 连接

# 2. 文件上传失败
- 检查存储桶配置
- 验证文件大小限制
- 检查 RLS 策略

# 3. 用户认证问题
- 验证 JWT 配置
- 检查 Supabase Auth 设置
- 确认密码策略
```

### 8.2 紧急响应流程
```bash
# 1. 服务中断
- 检查 Railway 状态页面
- 查看应用日志
- 联系技术支持

# 2. 数据问题
- 停止写入操作
- 从备份恢复
- 通知用户

# 3. 安全事件
- 立即更改敏感密钥
- 分析访问日志
- 通知相关用户
```

## 9. 成本估算

### 9.1 月度成本预估
```bash
# Railway (后端托管)
- Hobby Plan: $5/月
- Pro Plan: $20/月 (推荐)

# Supabase (数据库和存储)
- Free Tier: $0/月 (适合初期)
- Pro Plan: $25/月 (生产环境推荐)

# 阿里云 DashScope (AI 服务)
- 按调用次数计费
- 预估: $10-50/月

# Apple Developer Program
- $99/年

# 总计预估: $40-95/月 + $99/年
```

### 9.2 扩展计划
```bash
# 用户增长阶段
- 升级 Railway Pro Plan
- 升级 Supabase Pro Plan
- 考虑 CDN 服务

# 企业级需求
- 自定义域名
- 高级监控服务
- 专业技术支持
```

## 10. 部署时间线

### 10.1 预计部署时间
```bash
# 后端 API 部署: 2-4 小时
- Railway 配置: 30 分钟
- 环境变量设置: 30 分钟
- Supabase 配置: 1-2 小时
- 测试验证: 1 小时

# iOS 应用发布: 3-7 天
- 应用配置: 2-4 小时
- App Store 提交: 1 小时
- 苹果审核: 1-7 天

# 总计: 1 周内完成部署
```

### 10.2 发布检查清单
```bash
# 发布前最终检查
✅ 所有测试通过
✅ 生产环境配置正确
✅ 监控系统就绪
✅ 备份策略确认
✅ 文档更新完成
✅ 团队培训完成
✅ 用户支持准备就绪
```

---

**部署完成后，Forever Paws 将成为一个完整的生产级宠物纪念应用，为用户提供稳定、安全、高性能的服务体验。**