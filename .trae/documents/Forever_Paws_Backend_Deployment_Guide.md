# Forever Paws 后端 API 部署指南

## 1. 项目概述

Forever Paws 是一个宠物纪念应用的后端 API 服务，基于 Node.js + TypeScript + Express + Supabase 技术栈构建。本文档提供完整的生产环境部署方案。

### 技术栈
- **后端框架**: Node.js 18+ + Express + TypeScript
- **数据库**: Supabase (PostgreSQL)
- **认证**: JWT + Supabase Auth
- **文件存储**: Supabase Storage
- **AI 服务**: 阿里云 DashScope
- **API 文档**: Swagger

## 2. 部署平台选择与分析

### 2.1 推荐部署平台对比

| 平台 | 成本 | 易用性 | 性能 | 扩展性 | 适用场景 |
|------|------|--------|------|--------|----------|
| **Vercel** | 免费层慷慨 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 小到中型项目，快速部署 |
| **Railway** | $5/月起 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 中型项目，数据库集成好 |
| **Render** | 免费层有限 | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | 预算有限的项目 |
| **DigitalOcean App Platform** | $12/月起 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 企业级应用 |
| **AWS Elastic Beanstalk** | 按使用付费 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 大型企业应用 |

### 2.2 推荐方案

**首选：Railway** - 最适合 Forever Paws 项目
- ✅ 原生支持 Node.js + TypeScript
- ✅ 简单的环境变量管理
- ✅ 自动 HTTPS 和域名
- ✅ 内置监控和日志
- ✅ 与 GitHub 无缝集成
- ✅ 合理的定价（$5/月起）

## 3. 生产环境配置

### 3.1 Supabase 生产环境设置

#### 创建生产项目
1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 创建新项目：`forever-paws-prod`
3. 选择合适的地区（建议选择离用户最近的）
4. 记录以下信息：
   - Project URL
   - Anon Key
   - Service Role Key

#### 数据库迁移
```bash
# 1. 安装 Supabase CLI
npm install -g supabase

# 2. 登录 Supabase
supabase login

# 3. 链接到生产项目
supabase link --project-ref YOUR_PROJECT_REF

# 4. 推送数据库迁移
supabase db push
```

#### 配置 RLS (Row Level Security)
```sql
-- 启用 RLS 策略
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
CREATE POLICY "Users can view own data" ON users
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can view own pets" ON pets
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own letters" ON letters
  FOR ALL USING (auth.uid() = user_id);
```

### 3.2 环境变量配置

#### 生产环境变量清单
```bash
# 服务器配置
NODE_ENV=production
PORT=3000

# Supabase 生产配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_production_service_role_key

# JWT 配置（使用强密码生成器）
JWT_SECRET=your_super_secure_jwt_secret_256_bits
JWT_EXPIRES_IN=7d

# 阿里云 DashScope API
DASHSCOPE_API_KEY=your_production_dashscope_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com

# 安全配置
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# 日志配置
LOG_LEVEL=warn
LOG_FILE=logs/app.log

# 文件上传限制
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,video/mp4
```

## 4. Railway 部署步骤

### 4.1 准备部署

#### 1. 优化 package.json
确保 `package.json` 包含正确的启动脚本：
```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "postinstall": "npm run build"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

#### 2. 创建 Railway 配置文件
创建 `railway.toml`：
```toml
[build]
builder = "NIXPACKS"

[deploy]
healthcheckPath = "/api/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

### 4.2 部署流程

#### 1. 连接 GitHub 仓库
```bash
# 1. 推送代码到 GitHub
git add .
git commit -m "Prepare for production deployment"
git push origin main

# 2. 在 Railway 中连接仓库
# - 访问 railway.app
# - 点击 "New Project"
# - 选择 "Deploy from GitHub repo"
# - 选择 forever-paws-backend 仓库
```

#### 2. 配置环境变量
在 Railway Dashboard 中设置所有生产环境变量。

#### 3. 配置域名
```bash
# Railway 会自动分配域名，格式如：
# https://forever-paws-backend-production.up.railway.app

# 自定义域名配置：
# 1. 在 Railway Dashboard 中点击 "Settings"
# 2. 在 "Domains" 部分添加自定义域名
# 3. 配置 DNS CNAME 记录指向 Railway 提供的域名
```

## 5. CI/CD 流程设置

### 5.1 GitHub Actions 配置

创建 `.github/workflows/deploy.yml`：
```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: api/package-lock.json
      
      - name: Install dependencies
        run: |
          cd api
          npm ci
      
      - name: Run linter
        run: |
          cd api
          npm run lint
      
      - name: Run tests
        run: |
          cd api
          npm test
      
      - name: Build project
        run: |
          cd api
          npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Railway
        run: |
          echo "Deployment triggered automatically by Railway"
```

### 5.2 部署钩子配置

在 `package.json` 中添加部署后脚本：
```json
{
  "scripts": {
    "postdeploy": "echo 'Deployment completed successfully'"
  }
}
```

## 6. 监控和日志管理

### 6.1 应用监控

#### Railway 内置监控
- CPU 使用率
- 内存使用率
- 网络流量
- 响应时间

#### 集成第三方监控（推荐）
```typescript
// src/middleware/monitoring.ts
import { Request, Response, NextFunction } from 'express';

export const performanceMonitoring = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
    
    // 发送到监控服务（如 DataDog, New Relic）
    if (process.env.NODE_ENV === 'production') {
      // 监控代码
    }
  });
  
  next();
};
```

### 6.2 日志管理

#### 结构化日志配置
```typescript
// src/utils/logger.ts
import { createLogger, format, transports } from 'winston';

const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.json()
  ),
  transports: [
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.simple()
      )
    })
  ]
});

if (process.env.NODE_ENV === 'production') {
  logger.add(new transports.File({
    filename: 'logs/error.log',
    level: 'error'
  }));
  
  logger.add(new transports.File({
    filename: 'logs/combined.log'
  }));
}

export default logger;
```

## 7. 性能优化建议

### 7.1 代码优化

#### 1. 启用 Gzip 压缩
```typescript
// src/server.ts
import compression from 'compression';
app.use(compression());
```

#### 2. 实现缓存策略
```typescript
// src/middleware/cache.ts
import { Request, Response, NextFunction } from 'express';

export const cacheMiddleware = (duration: number) => {
  return (req: Request, res: Response, next: NextFunction) => {
    res.set('Cache-Control', `public, max-age=${duration}`);
    next();
  };
};

// 使用示例
app.get('/api/products', cacheMiddleware(300), getProducts); // 缓存5分钟
```

#### 3. 数据库查询优化
```typescript
// 使用索引和限制查询结果
const getPets = async (userId: string, limit: number = 10) => {
  const { data, error } = await supabase
    .from('pets')
    .select('id, name, breed, photo_url')
    .eq('user_id', userId)
    .limit(limit)
    .order('created_at', { ascending: false });
    
  return { data, error };
};
```

### 7.2 基础设施优化

#### 1. CDN 配置
```typescript
// 配置静态资源 CDN
app.use('/static', express.static('public', {
  maxAge: '1y',
  etag: false
}));
```

#### 2. 连接池优化
```typescript
// Supabase 客户端优化
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  {
    db: {
      schema: 'public',
    },
    auth: {
      autoRefreshToken: true,
      persistSession: true,
    },
    global: {
      headers: { 'x-my-custom-header': 'forever-paws' },
    },
  }
);
```

## 8. 安全配置最佳实践

### 8.1 基础安全配置

#### 1. Helmet 安全头
```typescript
// src/middleware/security.ts
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

#### 2. 速率限制
```typescript
// src/middleware/rateLimiter.ts
import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 100, // 限制每个IP 100个请求
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 登录限制更严格
  skipSuccessfulRequests: true,
});
```

### 8.2 数据保护

#### 1. 输入验证
```typescript
// src/middleware/validation.ts
import Joi from 'joi';

export const validatePetCreation = (req: Request, res: Response, next: NextFunction) => {
  const schema = Joi.object({
    name: Joi.string().min(1).max(50).required(),
    breed: Joi.string().max(50),
    birth_date: Joi.date().max('now'),
    description: Joi.string().max(500)
  });

  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  
  next();
};
```

#### 2. 敏感数据处理
```typescript
// 确保敏感信息不被记录
const sanitizeForLogging = (data: any) => {
  const sanitized = { ...data };
  delete sanitized.password;
  delete sanitized.jwt_secret;
  delete sanitized.api_key;
  return sanitized;
};
```

## 9. 域名和 SSL 配置

### 9.1 自定义域名设置

#### 1. DNS 配置
```bash
# 在域名提供商处添加 CNAME 记录
# 名称: api (或 @)
# 值: your-app.up.railway.app
# TTL: 300
```

#### 2. SSL 证书
Railway 自动提供 Let's Encrypt SSL 证书，无需手动配置。

### 9.2 域名验证
```bash
# 验证域名配置
curl -I https://api.yourdomian.com/api/health

# 检查 SSL 证书
openssl s_client -connect api.yourdomain.com:443 -servername api.yourdomain.com
```

## 10. 部署检查清单

### 10.1 部署前检查
- [ ] 所有环境变量已配置
- [ ] 数据库迁移已完成
- [ ] SSL 证书已配置
- [ ] 监控和日志已设置
- [ ] 安全配置已启用
- [ ] 性能优化已实施

### 10.2 部署后验证
- [ ] API 健康检查通过: `GET /api/health`
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] 文件上传功能正常
- [ ] 数据库连接正常
- [ ] 日志记录正常

### 10.3 监控指标
- [ ] 响应时间 < 500ms
- [ ] 错误率 < 1%
- [ ] CPU 使用率 < 80%
- [ ] 内存使用率 < 80%

## 11. 故障排除

### 11.1 常见问题

#### 1. 数据库连接失败
```bash
# 检查环境变量
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY

# 测试连接
curl -H "apikey: $SUPABASE_ANON_KEY" $SUPABASE_URL/rest/v1/
```

#### 2. 内存不足
```typescript
// 增加 Node.js 内存限制
// package.json
{
  "scripts": {
    "start": "node --max-old-space-size=1024 dist/server.js"
  }
}
```

#### 3. 文件上传失败
```typescript
// 检查文件大小限制
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
```

### 11.2 日志分析
```bash
# Railway CLI 查看日志
railway logs

# 过滤错误日志
railway logs --filter error
```

## 12. 成本优化建议

### 12.1 Railway 定价优化
- **Hobby Plan**: $5/月 - 适合开发和小规模生产
- **Pro Plan**: $20/月 - 适合中等规模应用
- 监控资源使用情况，避免超出限制

### 12.2 Supabase 成本控制
- 使用免费层额度（500MB 数据库，1GB 文件存储）
- 实施数据归档策略
- 优化查询以减少数据传输

### 12.3 第三方服务优化
- 合理使用 DashScope API 调用
- 实施缓存减少重复请求
- 监控 API 使用量

## 13. 扩展计划

### 13.1 水平扩展
- 使用 Railway 的自动扩展功能
- 实施负载均衡
- 数据库读写分离

### 13.2 微服务架构
- 拆分核心服务（用户、宠物、订单）
- 使用消息队列处理异步任务
- 实施服务发现和配置管理

---

## 总结

本部署指南提供了 Forever Paws 后端 API 的完整生产环境部署方案。通过遵循这些最佳实践，你可以确保应用的安全性、性能和可维护性。

建议从 Railway 开始部署，随着业务增长再考虑更复杂的基础设施方案。记住定期备份数据、监控应用性能，并保持依赖项的更新。