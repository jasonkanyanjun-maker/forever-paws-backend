import app from './app';
import logger from './utils/logger';

const PORT = parseInt(process.env.PORT || '3001', 10);

// 启动服务器 - 使用IPv6双栈绑定以支持Render平台
const server = app.listen(PORT, '::', () => {
  // 获取本机 IP 地址
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  let localIP = 'localhost';
  
  // 查找本机 IP 地址
  for (const interfaceName in networkInterfaces) {
    const interfaces = networkInterfaces[interfaceName];
    for (const iface of interfaces || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        localIP = iface.address;
        break;
      }
    }
    if (localIP !== 'localhost') break;
  }
  
  process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`
🚀 Forever Paws API 服务器已启动
📍 端口: ${PORT}
🌍 环境: ${process.env.NODE_ENV || 'development'}
📚 API 文档: http://localhost:${PORT}/api-docs
🔍 健康检查: http://localhost:${PORT}/api/health
📱 iOS 模拟器访问: http://${localIP}:${PORT}/api/health
⏰ 启动时间: ${new Date().toISOString()}

🔧 网络访问地址:
   - 本地访问: http://localhost:${PORT}
   - 局域网访问: http://${localIP}:${PORT}
   - iOS 模拟器: http://${localIP}:${PORT}
  `);
  
  logger.info(`Server started on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
  logger.info(`Server accessible at: localhost:${PORT} and ${localIP}:${PORT}`);
});

// 优雅关闭处理
const gracefulShutdown = (signal: string) => {
  process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`\n收到 ${signal} 信号，开始优雅关闭服务器...`);
  
  server.close((err) => {
    if (err) {
      console.error('服务器关闭时发生错误:', err);
      process.exit(1);
    }
    
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('服务器已优雅关闭');
    process.exit(0);
  });
  
  // 强制关闭超时
  setTimeout(() => {
    console.error('强制关闭服务器');
    process.exit(1);
  }, 10000);
};

// 监听关闭信号
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// 处理未捕获的异常
process.on('uncaughtException', (err) => {
  console.error('未捕获的异常:', err);
  gracefulShutdown('uncaughtException');
});

// 处理未处理的 Promise 拒绝
process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的 Promise 拒绝:', reason);
  console.error('Promise:', promise);
  gracefulShutdown('unhandledRejection');
});

export default server;