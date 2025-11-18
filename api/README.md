# Forever Paws API

宠物纪念APP后端系统 - 基于 Node.js + Express + TypeScript + Supabase

## 项目简介

Forever Paws 是一个宠物纪念应用的后端API系统，提供完整的宠物管理、AI视频生成、家庭共享、商城订单等功能。

## 技术栈

- **运行时**: Node.js 18+
- **框架**: Express.js
- **语言**: TypeScript
- **数据库**: Supabase (PostgreSQL)
- **认证**: JWT + Supabase Auth
- **文档**: Swagger/OpenAPI
- **AI服务**: 阿里云 DashScope

## 功能模块

### 🔐 用户认证
- 邮箱注册/登录
- 第三方登录 (Google, Apple)
- JWT Token 管理
- 密码重置

### 🐾 宠物管理
- 宠物信息 CRUD
- 宠物照片上传
- 宠物状态管理

### 💌 写信对话
- AI 智能回复
- 信件历史记录
- 情感分析

### 🎬 视频生成
- AI 视频生成
- 生成状态跟踪
- 视频文件管理

### 👨‍👩‍👧‍👦 家庭共享
- 家庭群组管理
- 成员权限控制
- 宠物共享

### 🛒 商品商城
- 商品管理
- 订单处理
- 库存管理

### 🔔 通知系统
- 系统通知
- 实时推送
- 通知历史

## 快速开始

### 环境要求

- Node.js 18.0.0+
- npm 或 pnpm
- Supabase 项目

### 安装依赖

```bash
cd api
npm install
# 或
pnpm install
```

### 环境配置

1. 复制环境变量模板：
```bash
cp .env.example .env
```

2. 配置 `.env` 文件：
```env
# 服务器配置
PORT=3000
NODE_ENV=development

# Supabase 配置
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# JWT 配置
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

# 阿里云 DashScope API 配置
DASHSCOPE_API_KEY=your_dashscope_api_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com
```

### 数据库迁移

```bash
# 应用数据库迁移
npm run migrate
```

### 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm run build
npm start
```

## API 文档

启动服务后，访问 [http://localhost:3000/api-docs](http://localhost:3000/api-docs) 查看完整的 API 文档。

## 项目结构

```
api/
├── src/
│   ├── config/           # 配置文件
│   │   ├── supabase.ts   # Supabase 配置
│   │   └── swagger.ts    # Swagger 配置
│   ├── controllers/      # 控制器
│   │   ├── AuthController.ts
│   │   ├── UserController.ts
│   │   ├── PetController.ts
│   │   ├── LetterController.ts
│   │   ├── VideoController.ts
│   │   ├── FamilyController.ts
│   │   ├── ProductController.ts
│   │   ├── OrderController.ts
│   │   └── NotificationController.ts
│   ├── services/         # 业务逻辑层
│   │   ├── AuthService.ts
│   │   ├── UserService.ts
│   │   ├── PetService.ts
│   │   ├── LetterService.ts
│   │   ├── VideoService.ts
│   │   ├── FamilyService.ts
│   │   ├── ProductService.ts
│   │   ├── OrderService.ts
│   │   └── NotificationService.ts
│   ├── routes/           # 路由定义
│   │   ├── index.ts
│   │   ├── auth.ts
│   │   ├── users.ts
│   │   ├── pets.ts
│   │   ├── letters.ts
│   │   ├── videos.ts
│   │   ├── families.ts
│   │   ├── products.ts
│   │   ├── orders.ts
│   │   └── notifications.ts
│   ├── middleware/       # 中间件
│   │   ├── auth.ts       # 认证中间件
│   │   ├── validation.ts # 数据验证
│   │   ├── errorHandler.ts
│   │   └── notFound.ts
│   ├── schemas/          # 数据验证模式
│   │   ├── authSchemas.ts
│   │   ├── userSchemas.ts
│   │   ├── petSchemas.ts
│   │   ├── letterSchemas.ts
│   │   ├── videoSchemas.ts
│   │   ├── familySchemas.ts
│   │   ├── productSchemas.ts
│   │   ├── orderSchemas.ts
│   │   ├── notificationSchemas.ts
│   │   └── commonSchemas.ts
│   ├── utils/            # 工具函数
│   │   ├── AppError.ts   # 错误处理
│   │   ├── asyncHandler.ts
│   │   ├── logger.ts
│   │   └── helpers.ts
│   ├── types/            # TypeScript 类型定义
│   │   ├── auth.ts
│   │   ├── user.ts
│   │   └── common.ts
│   ├── app.ts            # Express 应用配置
│   └── server.ts         # 服务器启动文件
├── supabase/
│   └── migrations/       # 数据库迁移文件
├── .env.example          # 环境变量模板
├── .env                  # 环境变量配置
├── package.json
├── tsconfig.json
└── README.md
```

## 主要 API 端点

### 认证相关
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/logout` - 用户登出
- `POST /api/auth/refresh` - 刷新 Token
- `POST /api/auth/forgot-password` - 忘记密码

### 用户管理
- `GET /api/users/profile` - 获取用户信息
- `PUT /api/users/profile` - 更新用户信息
- `POST /api/users/avatar` - 上传头像

### 宠物管理
- `GET /api/pets` - 获取宠物列表
- `POST /api/pets` - 创建宠物
- `GET /api/pets/:id` - 获取宠物详情
- `PUT /api/pets/:id` - 更新宠物信息
- `DELETE /api/pets/:id` - 删除宠物

### 写信对话
- `GET /api/letters` - 获取信件列表
- `POST /api/letters` - 发送信件
- `GET /api/letters/:id` - 获取信件详情

### 视频生成
- `POST /api/videos/generate` - 生成视频
- `GET /api/videos` - 获取视频列表
- `GET /api/videos/:id` - 获取视频详情

### 家庭共享
- `GET /api/families` - 获取家庭列表
- `POST /api/families` - 创建家庭
- `POST /api/families/:id/members` - 添加家庭成员
- `GET /api/families/:id/pets` - 获取家庭宠物

### 商品商城
- `GET /api/products` - 获取商品列表
- `GET /api/products/:id` - 获取商品详情
- `POST /api/orders` - 创建订单
- `GET /api/orders` - 获取订单列表

### 通知系统
- `GET /api/notifications` - 获取通知列表
- `PUT /api/notifications/:id/read` - 标记已读
- `GET /api/notifications/unread-count` - 获取未读数量

## 开发指南

### 代码规范

- 使用 TypeScript 严格模式
- 遵循 ESLint 规则
- 使用 Prettier 格式化代码
- 编写单元测试

### 错误处理

所有 API 响应遵循统一格式：

```json
{
  "success": true,
  "message": "操作成功",
  "data": {},
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```

错误响应：

```json
{
  "success": false,
  "message": "错误信息",
  "error": "详细错误描述"
}
```

### 数据验证

使用 Joi 进行请求数据验证，所有输入都会经过严格验证。

### 安全措施

- JWT Token 认证
- 请求频率限制
- CORS 配置
- Helmet 安全头
- 输入数据验证和清理

## 部署

### 环境变量

确保生产环境配置了所有必要的环境变量。

### 构建

```bash
npm run build
```

### 启动

```bash
npm start
```

## 监控和日志

- 使用 Morgan 记录 HTTP 请求日志
- 错误日志自动记录
- 支持日志文件输出

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

- 项目维护者: Forever Paws Team
- 邮箱: support@foreverpaws.com

---

**Forever Paws** - 让爱永远陪伴 🐾