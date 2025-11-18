
// cache.js - 缓存配置
const cacheControl = (maxAge = 3600) => {
    return (req, res, next) => {
        // 设置缓存控制头
        res.set('Cache-Control', `public, max-age=${maxAge}`);
        next();
    };
};

// 不同类型资源的缓存策略
const cacheStrategies = {
    // 静态资源 - 长期缓存
    static: cacheControl(31536000), // 1年
    
    // API 响应 - 短期缓存
    api: cacheControl(300), // 5分钟
    
    // 用户数据 - 不缓存
    user: (req, res, next) => {
        res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        next();
    }
};

module.exports = { cacheControl, cacheStrategies };
