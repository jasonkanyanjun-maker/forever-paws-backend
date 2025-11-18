/**
 * Common types and interfaces used throughout the application
 */

import { Request } from 'express';

// Standard API Response format
export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data: T | null;
}

// Pagination parameters
export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// Pagination response
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// File upload types
export interface FileUpload {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

// Error types
export interface ApiError extends Error {
  statusCode?: number;
  code?: string;
  details?: any;
}

// JWT Payload
export interface JwtPayload {
  userId: string;
  email: string;
  provider?: string;
  iat?: number;
  exp?: number;
}

// Request with authenticated user
export interface AuthenticatedRequest extends Request {
  user?: JwtPayload;
  query: any;
}

// Common status enums
export enum Status {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

// Provider types for authentication
export enum AuthProvider {
  EMAIL = 'email',
  APPLE = 'apple',
  GOOGLE = 'google'
}

// Pet types
export enum PetType {
  DOG = 'dog',
  CAT = 'cat',
  BIRD = 'bird',
  FISH = 'fish',
  RABBIT = 'rabbit',
  HAMSTER = 'hamster',
  OTHER = 'other'
}

// Video generation status
export enum VideoGenerationStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

// Order status
export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  PROCESSING = 'processing',
  SHIPPED = 'shipped',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded'
}

// 移除了 FamilyRole 枚举

// Notification types
export enum NotificationType {
  VIDEO_COMPLETED = 'video_completed',
  VIDEO_FAILED = 'video_failed',
  ORDER_CONFIRMED = 'order_confirmed',
  ORDER_SHIPPED = 'order_shipped',
  ORDER_DELIVERED = 'order_delivered',

  LETTER_REPLY = 'letter_reply',
  SYSTEM_ANNOUNCEMENT = 'system_announcement'
}