
// performance.js - 性能监控中间件
const performanceMonitor = (req, res, next) => {
    const startTime = Date.now();
    
    // 监听响应完成
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const { method, url } = req;
        const { statusCode } = res;
        
        // 记录性能数据
        console.log(`[${new Date().toISOString()}] ${method} ${url} - ${statusCode} - ${duration}ms`);
        
        // 如果响应时间过长，记录警告
        if (duration > 1000) {
            console.warn(`⚠️  Slow response: ${method} ${url} took ${duration}ms`);
        }
    });
    
    next();
};

module.exports = performanceMonitor;
