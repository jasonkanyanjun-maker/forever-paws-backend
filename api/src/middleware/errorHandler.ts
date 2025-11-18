import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../types/common';

/**
 * Custom error class for API errors
 */
export class AppError extends Error implements ApiError {
  public statusCode: number;
  public code: string;
  public details?: any;

  constructor(message: string, statusCode: number = 500, code?: string, details?: any) {
    super(message);
    this.statusCode = statusCode;
    this.code = code || 'INTERNAL_ERROR';
    this.details = details;
    this.name = 'AppError';

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Predefined error types
 */
export const ErrorTypes = {
  VALIDATION_ERROR: (message: string, details?: any) => 
    new AppError(message, 400, 'VALIDATION_ERROR', details),
  
  UNAUTHORIZED: (message: string = 'Unauthorized') => 
    new AppError(message, 401, 'UNAUTHORIZED'),
  
  FORBIDDEN: (message: string = 'Forbidden') => 
    new AppError(message, 403, 'FORBIDDEN'),
  
  NOT_FOUND: (message: string = 'Resource not found') => 
    new AppError(message, 404, 'NOT_FOUND'),
  
  CONFLICT: (message: string = 'Resource already exists') => 
    new AppError(message, 409, 'CONFLICT'),
  
  RATE_LIMIT: (message: string = 'Too many requests') => 
    new AppError(message, 429, 'RATE_LIMIT'),
  
  INTERNAL_ERROR: (message: string = 'Internal server error') => 
    new AppError(message, 500, 'INTERNAL_ERROR'),
  
  SERVICE_UNAVAILABLE: (message: string = 'Service temporarily unavailable') => 
    new AppError(message, 503, 'SERVICE_UNAVAILABLE'),

  DATABASE_ERROR: (message: string = 'Database operation failed') => 
    new AppError(message, 500, 'DATABASE_ERROR'),

  // Business logic errors
  INVALID_CREDENTIALS: () => 
    new AppError('Invalid email or password', 401, 'INVALID_CREDENTIALS'),
  
  EMAIL_ALREADY_EXISTS: () => 
    new AppError('Email already registered', 409, 'EMAIL_ALREADY_EXISTS'),
  
  PET_NOT_FOUND: () => 
    new AppError('Pet not found', 404, 'PET_NOT_FOUND'),
  
  VIDEO_GENERATION_FAILED: (details?: any) => 
    new AppError('Video generation failed', 500, 'VIDEO_GENERATION_FAILED', details),
  
  INSUFFICIENT_PERMISSIONS: () => 
    new AppError('Insufficient permissions', 403, 'INSUFFICIENT_PERMISSIONS'),
  

  
  PRODUCT_OUT_OF_STOCK: () => 
    new AppError('Product is out of stock', 409, 'PRODUCT_OUT_OF_STOCK'),
  
  ORDER_NOT_FOUND: () => 
    new AppError('Order not found', 404, 'ORDER_NOT_FOUND'),
  
  PAYMENT_FAILED: (details?: any) => 
    new AppError('Payment processing failed', 400, 'PAYMENT_FAILED', details),
  
  FILE_UPLOAD_ERROR: (message: string) => 
    new AppError(`File upload error: ${message}`, 400, 'FILE_UPLOAD_ERROR'),
  
  EXTERNAL_API_ERROR: (service: string, message?: string) => 
    new AppError(`External API error (${service}): ${message || 'Unknown error'}`, 502, 'EXTERNAL_API_ERROR')
};

/**
 * Global error handling middleware
 */
export const errorHandler = (
  error: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  let statusCode = 500;
  let code = 'INTERNAL_ERROR';
  let message = 'Internal server error';
  let details: any = null;

  // Handle custom AppError
  if (error instanceof AppError) {
    statusCode = error.statusCode;
    code = error.code;
    message = error.message;
    details = error.details;
  }
  // Handle Joi validation errors
  else if (error.name === 'ValidationError') {
    statusCode = 400;
    code = 'VALIDATION_ERROR';
    message = 'Validation failed';
    details = error.message;
  }
  // Handle JWT errors
  else if (error.name === 'JsonWebTokenError') {
    statusCode = 401;
    code = 'INVALID_TOKEN';
    message = 'Invalid token';
  }
  else if (error.name === 'TokenExpiredError') {
    statusCode = 401;
    code = 'TOKEN_EXPIRED';
    message = 'Token expired';
  }
  // Handle Supabase errors
  else if (error.message?.includes('duplicate key value')) {
    statusCode = 409;
    code = 'DUPLICATE_RESOURCE';
    message = 'Resource already exists';
  }
  else if (error.message?.includes('foreign key constraint')) {
    statusCode = 400;
    code = 'INVALID_REFERENCE';
    message = 'Invalid reference to related resource';
  }
  // Handle other known errors
  else {
    // Log unexpected errors
    console.error('Unexpected error:', {
      message: error.message,
      stack: error.stack,
      url: req.url,
      method: req.method,
      body: req.body,
      query: req.query,
      params: req.params,
      user: (req as any).user?.userId
    });
  }

  // Send error response
  res.status(statusCode).json({
    code: statusCode,
    message,
    data: details,
    ...(process.env.NODE_ENV === 'development' && {
      stack: error.stack,
      error: error.name
    })
  });
};

/**
 * 404 handler for unmatched routes
 */
export const notFoundHandler = (req: Request, res: Response): void => {
  res.status(404).json({
    code: 404,
    message: `Route ${req.method} ${req.path} not found`,
    data: null
  });
};

/**
 * Async error wrapper to catch async errors in route handlers
 */
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Validation error formatter
 */
export const formatValidationError = (errors: any[]): any => {
  return {
    message: 'Validation failed',
    errors: errors.map(error => ({
      field: error.path?.join('.') || error.field,
      message: error.message,
      value: error.value
    }))
  };
};

export default {
  AppError,
  ErrorTypes,
  errorHandler,
  notFoundHandler,
  asyncHandler,
  formatValidationError
};