
// security.js - 安全中间件
const helmet = require('helmet');
const cors = require('cors');

// 安全头配置
const securityHeaders = helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.supabase.co"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
        },
    },
    crossOriginEmbedderPolicy: false,
});

// CORS 配置
const corsOptions = {
    origin: function (origin, callback) {
        // 允许的域名列表
        const allowedOrigins = [
            'http://localhost:3000',
            'http://localhost:5173',
            'https://your-production-domain.com'
        ];
        
        // 在开发环境允许所有来源
        if (process.env.NODE_ENV === 'development') {
            return callback(null, true);
        }
        
        // 检查来源是否在允许列表中
        if (!origin || allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
};

// 请求大小限制
const requestSizeLimit = '10mb';

// 安全日志中间件
const securityLogger = (req, res, next) => {
    // 记录可疑请求
    const suspiciousPatterns = [
        /../,  // 路径遍历
        /<script/i,  // XSS 尝试
        /union.*select/i,  // SQL 注入尝试
    ];
    
    const url = req.url;
    const userAgent = req.get('User-Agent') || '';
    
    suspiciousPatterns.forEach(pattern => {
        if (pattern.test(url) || pattern.test(userAgent)) {
            console.warn(`🚨 Suspicious request detected: ${req.method} ${url} from ${req.ip}`);
        }
    });
    
    next();
};

module.exports = {
    securityHeaders,
    corsOptions,
    requestSizeLimit,
    securityLogger
};
