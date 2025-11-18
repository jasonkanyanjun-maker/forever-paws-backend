import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

interface AdminPayload {
  adminId: string;
  username: string;
  role: string;
}

declare global {
  namespace Express {
    interface Request {
      admin?: AdminPayload;
    }
  }
}

export const authenticateAdmin = (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: '未提供认证令牌' });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    const decoded = jwt.verify(
      token, 
      process.env.JWT_SECRET || 'your-secret-key'
    ) as AdminPayload;

    req.admin = decoded;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({ error: '无效的认证令牌' });
    }
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({ error: '认证令牌已过期' });
    }
    
    console.error('Admin authentication error:', error);
    return res.status(500).json({ error: '认证失败' });
  }
};