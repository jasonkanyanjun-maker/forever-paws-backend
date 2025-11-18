import { createLogger, format, transports } from 'winston';
import { Request, Response, NextFunction } from 'express';

// 创建 Winston 日志器
const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    format.errors({ stack: true }),
    format.json()
  ),
  defaultMeta: { service: 'forever-paws-api' },
  transports: [
    // 控制台输出
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.simple(),
        format.printf(({ timestamp, level, message, ...meta }: any) => {
          return `${timestamp} [${level}]: ${message} ${
            Object.keys(meta).length ? JSON.stringify(meta, null, 2) : ''
          }`;
        })
      )
    })
  ]
});

// 生产环境添加文件日志
if (process.env.NODE_ENV === 'production') {
  logger.add(new transports.File({
    filename: 'logs/error.log',
    level: 'error',
    format: format.combine(
      format.timestamp(),
      format.json()
    )
  }));

  logger.add(new transports.File({
    filename: 'logs/combined.log',
    format: format.combine(
      format.timestamp(),
      format.json()
    )
  }));

  logger.add(new transports.File({
    filename: 'logs/access.log',
    level: 'info',
    format: format.combine(
      format.timestamp(),
      format.json()
    )
  }));
}

// 开发环境添加调试日志
if (process.env.NODE_ENV === 'development') {
  logger.add(new transports.File({
    filename: 'logs/debug.log',
    level: 'debug',
    format: format.combine(
      format.timestamp(),
      format.json()
    )
  }));
}

// 请求日志中间件
export const logRequest = (req: Request, res: Response, next: NextFunction): void => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
  });
  
  next();
};

// 错误日志
export const logError = (error: Error, context?: string): void => {
  logger.error('Application Error', {
    message: error.message,
    stack: error.stack,
    context: context || 'Unknown'
  });
};

// 数据库查询日志
export const logDatabaseQuery = (query: string, duration: number): void => {
  logger.debug('Database Query', {
    query,
    duration: `${duration}ms`
  });
};

// 认证日志
export const logAuth = (action: string, userId?: string, details?: any): void => {
  logger.info('Authentication', {
    action,
    userId,
    ...details
  });
};

// 安全日志
export const logSecurity = (event: string, details: any): void => {
  logger.warn('Security Event', {
    event,
    ...details
  });
};

export default logger;