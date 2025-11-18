import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase';
import { JwtPayload, AuthenticatedRequest } from '../types/common';

/**
 * JWT Authentication middleware
 */
export const authenticateToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [Auth Middleware] Authorization header:', authHeader ? `Bearer ${authHeader.split(' ')[1]?.substring(0, 20)}...` : 'None');

    if (!token) {
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('❌ [Auth Middleware] No token provided');
      res.status(401).json({
        code: 401,
        message: 'Access token required',
        data: null
      });
      return;
    }

    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [Auth Middleware] Verifying token with secret...');
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [Auth Middleware] JWT_SECRET exists:', !!process.env.JWT_SECRET);
    
    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [Auth Middleware] Token decoded successfully:', { userId: decoded.userId, email: decoded.email });
    
    // Verify user exists in database
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [Auth Middleware] Checking user in database:', decoded.userId);
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, provider')
      .eq('id', decoded.userId)
      .single() as { data: any; error: any };

    if (error) {
      console.error('❌ [Auth Middleware] Database error:', error);
      res.status(401).json({
        code: 401,
        message: 'Invalid or expired token',
        data: null
      });
      return;
    }

    if (!user) {
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('❌ [Auth Middleware] User not found in database');
      res.status(401).json({
        code: 401,
        message: 'Invalid or expired token',
        data: null
      });
      return;
    }

    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [Auth Middleware] User found:', { id: user.id, email: user.email });

    // Attach user info to request
    req.user = {
      userId: user.id as string,
      email: user.email as string,
      provider: user.provider as string
    };

    next();
  } catch (error) {
    console.error('❌ [Auth Middleware] Authentication error:', error);
    
    if (error instanceof jwt.JsonWebTokenError) {
      console.error('❌ [Auth Middleware] JWT Error type:', error.name);
      console.error('❌ [Auth Middleware] JWT Error message:', error.message);
    }
    
    res.status(401).json({
      code: 401,
      message: 'Invalid or expired token',
      data: null
    });
  }
};

/**
 * Optional authentication middleware (doesn't fail if no token)
 */
export const optionalAuth = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
      
      const { data: user } = await supabase
        .from('users')
        .select('id, email, provider')
        .eq('id', decoded.userId)
        .single() as { data: any; error: any };

      if (user) {
        req.user = {
          userId: user.id as string,
          email: user.email as string,
          provider: user.provider as string
        };
      }
    }

    next();
  } catch (error) {
    // Continue without authentication
    next();
  }
};

/**
 * Role-based authorization middleware
 */
export const requireRole = (roles: string[]) => {
  return async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    if (!req.user) {
      res.status(401).json({
        code: 401,
        message: 'Authentication required',
        data: null
      });
      return;
    }

    // For now, we'll implement basic role checking
    // In the future, this can be extended with more complex role systems
    next();
  };
};

/**
 * Rate limiting middleware
 */
export const createRateLimit = (windowMs: number, max: number) => {
  const requests = new Map<string, { count: number; resetTime: number }>();

  return (req: Request, res: Response, next: NextFunction): void => {
    const key = req.ip || 'unknown';
    const now = Date.now();
    const windowStart = now - windowMs;

    // Clean up old entries
    for (const [ip, data] of requests.entries()) {
      if (data.resetTime < windowStart) {
        requests.delete(ip);
      }
    }

    const current = requests.get(key);
    
    if (!current) {
      requests.set(key, { count: 1, resetTime: now + windowMs });
      next();
      return;
    }

    if (current.count >= max) {
      res.status(429).json({
        code: 429,
        message: 'Too many requests, please try again later',
        data: null
      });
      return;
    }

    current.count++;
    next();
  };
};

export default {
  authenticateToken,
  optionalAuth,
  requireRole,
  createRateLimit
};