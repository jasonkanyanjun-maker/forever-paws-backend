
// compression.js - Gzip 压缩中间件配置
const compression = require('compression');

const compressionOptions = {
    // 压缩级别 (1-9, 9 为最高压缩)
    level: 6,
    // 最小压缩大小 (字节)
    threshold: 1024,
    // 压缩过滤器
    filter: (req, res) => {
        // 不压缩已经压缩的内容
        if (req.headers['x-no-compression']) {
            return false;
        }
        // 使用默认过滤器
        return compression.filter(req, res);
    }
};

module.exports = compression(compressionOptions);
