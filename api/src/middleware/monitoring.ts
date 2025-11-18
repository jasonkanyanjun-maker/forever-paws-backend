import { Request, Response, NextFunction } from 'express';

/**
 * 性能监控中间件
 */
export const performanceMonitoring = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  
  // 记录请求开始时间
  req.startTime = start;
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const { method, originalUrl, ip } = req;
    const { statusCode } = res;
    
    // 基础日志
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`${method} ${originalUrl} - ${statusCode} - ${duration}ms - ${ip}`);
    
    // 生产环境发送到监控服务
    if (process.env.NODE_ENV === 'production') {
      // 这里可以集成第三方监控服务
      // 如 DataDog, New Relic, Sentry 等
      sendMetricsToMonitoringService({
        method,
        url: originalUrl,
        statusCode,
        duration,
        timestamp: new Date().toISOString(),
        userAgent: req.get('User-Agent'),
        ip
      });
    }
    
    // 慢请求警告
    if (duration > 1000) {
      console.warn(`⚠️ Slow request detected: ${method} ${originalUrl} took ${duration}ms`);
    }
    
    // 错误状态码记录
    if (statusCode >= 400) {
      console.error(`❌ Error response: ${method} ${originalUrl} - ${statusCode}`);
    }
  });
  
  next();
};

/**
 * 内存使用监控中间件
 */
export const memoryMonitoring = (req: Request, res: Response, next: NextFunction) => {
  const memUsage = process.memoryUsage();
  const memUsageMB = {
    rss: Math.round(memUsage.rss / 1024 / 1024 * 100) / 100,
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024 * 100) / 100,
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024 * 100) / 100,
    external: Math.round(memUsage.external / 1024 / 1024 * 100) / 100
  };
  
  // 内存使用过高警告
  if (memUsageMB.heapUsed > 500) {
    console.warn(`⚠️ High memory usage: ${memUsageMB.heapUsed}MB`);
  }
  
  // 添加内存信息到响应头（仅开发环境）
  if (process.env.NODE_ENV === 'development') {
    res.set('X-Memory-Usage', JSON.stringify(memUsageMB));
  }
  
  next();
};

/**
 * 请求计数器中间件
 */
let requestCount = 0;
export const requestCounter = (req: Request, res: Response, next: NextFunction) => {
  requestCount++;
  
  // 每1000个请求记录一次
  if (requestCount % 1000 === 0) {
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`📊 Total requests processed: ${requestCount}`);
  }
  
  // 添加请求计数到响应头
  res.set('X-Request-Count', requestCount.toString());
  
  next();
};

/**
 * 发送指标到监控服务（示例实现）
 */
function sendMetricsToMonitoringService(metrics: any) {
  // 这里实现发送到监控服务的逻辑
  // 例如：DataDog, New Relic, CloudWatch 等
  
  // 示例：发送到 DataDog
  // dogapi.metric.send('api.request.duration', metrics.duration, {
  //   tags: [`method:${metrics.method}`, `status:${metrics.statusCode}`]
  // });
  
  // 示例：发送到自定义监控端点
  // fetch('https://your-monitoring-service.com/metrics', {
  //   method: 'POST',
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON.stringify(metrics)
  // }).catch(err => console.error('Failed to send metrics:', err));
}

// 扩展 Request 接口
declare global {
  namespace Express {
    interface Request {
      startTime?: number;
    }
  }
}