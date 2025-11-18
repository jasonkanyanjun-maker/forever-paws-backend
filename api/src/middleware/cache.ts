import { Request, Response, NextFunction } from 'express';

/**
 * 缓存中间件
 * @param duration 缓存持续时间（秒）
 */
export const cacheMiddleware = (duration: number) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    // 设置缓存控制头
    res.set('Cache-Control', `public, max-age=${duration}`);
    
    // 设置 ETag 支持
    res.set('ETag', `"${Date.now()}"`);
    
    // 检查 If-None-Match 头
    const ifNoneMatch = req.get('If-None-Match');
    if (ifNoneMatch && ifNoneMatch === res.get('ETag')) {
      res.status(304).end();
      return;
    }
    
    next();
  };
};

/**
 * 静态资源缓存中间件
 */
export const staticCacheMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  // 静态资源缓存1年
  if (req.url.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
    res.set('Cache-Control', 'public, max-age=31536000, immutable');
  }
  next();
};

/**
 * API 响应缓存中间件
 */
export const apiCacheMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  // GET 请求缓存5分钟
  if (req.method === 'GET') {
    res.set('Cache-Control', 'public, max-age=300');
  } else {
    // 其他请求不缓存
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
  }
  next();
};