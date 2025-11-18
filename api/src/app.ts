import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import dotenv from 'dotenv';
import path from 'path';

// 首先加载环境变量
dotenv.config();

import routes from './routes/index';
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import { performanceMonitoring, memoryMonitoring, requestCounter } from './middleware/monitoring';
import { staticCacheMiddleware, apiCacheMiddleware } from './middleware/cache';
import logger from './utils/logger';

process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [App] Environment variables loaded');
process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [App] JWT_SECRET exists:', !!process.env.JWT_SECRET);
process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [App] NODE_ENV:', process.env.NODE_ENV);

const app = express();

// 信任代理（用于部署到云平台）
app.set('trust proxy', 1);

// 性能监控中间件
app.use(performanceMonitoring);
app.use(memoryMonitoring);
app.use(requestCounter);

// 安全中间件 - 增强配置
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://api.supabase.co", "https://dashscope.aliyuncs.com"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  crossOriginEmbedderPolicy: false
}));

// CORS 配置
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? (process.env.ALLOWED_ORIGINS?.split(',') || ['https://your-frontend-domain.com'])
    : ['http://localhost:3000', 'http://localhost:3001', 'http://127.0.0.1:3000', 'http://192.168.0.105:3001'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// 全局请求限制
const globalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15分钟
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'), // 限制每个IP 15分钟内最多100个请求
  message: {
    success: false,
    message: '请求过于频繁，请稍后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // 跳过健康检查和静态资源
    return req.path === '/api/health' || req.path.startsWith('/api-docs');
  }
});

// 认证相关的严格限制
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 5, // 登录/注册限制更严格
  message: {
    success: false,
    message: '认证请求过于频繁，请15分钟后再试'
  },
  skipSuccessfulRequests: true,
  skip: (req) => {
    // 在开发环境中跳过所有认证相关的频率限制
    const isDevelopment = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`[AuthLimiter] NODE_ENV: ${process.env.NODE_ENV}, isDevelopment: ${isDevelopment}, path: ${req.path}`);
    if (isDevelopment) {
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`[AuthLimiter] Skipping rate limit for ${req.path} in development mode`);
      return true;
    }
    // 生产环境中跳过用户检查和清理操作，以及将注册改由 email 计数的专用限流器
    const url = req.originalUrl || req.path;
    if (url.includes('/api/auth/register')) return true;
    return url.includes('/api/auth/check-user') || url.includes('/api/auth/cleanup-user');
  }
});

app.use('/api/', globalLimiter);
app.use('/api/auth/', authLimiter);

// Gzip 压缩
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  level: 6,
  threshold: 1024
}));

// 缓存中间件
app.use(staticCacheMiddleware);
app.use('/api', apiCacheMiddleware);

// 请求日志
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(
    process.env.NODE_ENV === 'production' 
      ? 'combined' 
      : 'dev',
    {
      stream: {
        write: (message: string) => {
          logger.info(message.trim());
        }
      }
    }
  ));
}

// 解析请求体
const maxFileSize = process.env.MAX_FILE_SIZE || '10mb';
app.use(express.json({ 
  limit: maxFileSize,
  verify: (req, res, buf) => {
    // 验证 JSON 格式
    try {
      JSON.parse(buf.toString());
    } catch (e) {
      throw new Error('Invalid JSON format');
    }
  }
}));
app.use(express.urlencoded({ 
  extended: true, 
  limit: maxFileSize 
}));

// Swagger 文档配置
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Forever Paws API',
      version: '1.0.0',
      description: '宠物纪念APP后端API文档',
      contact: {
        name: 'Forever Paws Team',
        email: 'support@foreverpaws.com'
      }
    },
    servers: [
      {
        url: process.env.NODE_ENV === 'production' 
          ? (process.env.API_BASE_URL || 'https://api.foreverpaws.com')
          : `http://localhost:${process.env.PORT || 3000}`,
        description: process.env.NODE_ENV === 'production' ? '生产环境' : '开发环境'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: ['./src/routes/*.ts', './src/controllers/*.ts'], // 扫描路由文件中的注释
};

const specs = swaggerJsdoc(swaggerOptions);

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Forever Paws API Documentation',
  swaggerOptions: {
    persistAuthorization: true,
  }
}));

// API 路由
app.use('/api', routes);

// 根路径
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Forever Paws API',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    documentation: '/api-docs',
    health: '/api/health',
    timestamp: new Date().toISOString()
  });
});

// 404 处理
app.use(notFound);

// 错误处理中间件
app.use(errorHandler);

// Serve static files from public directory
app.use('/auth', express.static(path.join(__dirname, '../public')));

export default app;
