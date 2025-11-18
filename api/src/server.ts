import app from './app';
import { createServer } from 'http';

const PORT = process.env.PORT || 3000;

// 创建 HTTP 服务器
const server = createServer(app);

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

// 启动服务器 - 修复：绑定到 IPv6 以支持 Railway 网络
server.listen(Number(PORT), '::', () => {
  process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`
🚀 Forever Paws API 服务器已启动
📍 端口: ${PORT}
🌍 环境: ${process.env.NODE_ENV || 'development'}
📚 API 文档: http://localhost:${PORT}/api-docs
🔍 健康检查: http://localhost:${PORT}/api/health
⏰ 启动时间: ${new Date().toLocaleString('zh-CN')}
  `);
});

export default server;