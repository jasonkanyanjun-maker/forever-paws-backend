
// rate-limit.js - API 速率限制配置
const rateLimit = require('express-rate-limit');

// 通用 API 速率限制
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 分钟
    max: 100, // 每个 IP 最多 100 次请求
    message: {
        error: 'Too many requests from this IP, please try again later.',
        retryAfter: '15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// 认证相关的严格限制
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 分钟
    max: 5, // 每个 IP 最多 5 次认证请求
    message: {
        error: 'Too many authentication attempts, please try again later.',
        retryAfter: '15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// 上传文件的限制
const uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 小时
    max: 10, // 每个 IP 最多 10 次上传
    message: {
        error: 'Too many upload requests, please try again later.',
        retryAfter: '1 hour'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

module.exports = {
    apiLimiter,
    authLimiter,
    uploadLimiter
};
