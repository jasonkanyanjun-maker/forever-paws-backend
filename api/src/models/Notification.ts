import { NotificationType } from '../types/common';

/**
 * Notification model interface matching the database schema
 */
export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data: NotificationData;
  is_read: boolean;
  sent_at?: string;
  read_at?: string;
  created_at: string;
  updated_at: string;
}

/**
 * Notification data interface for additional context
 */
export interface NotificationData {
  target_id?: string;
  target_type?: 'pet' | 'video' | 'order' | 'letter';
  action_url?: string;
  image_url?: string;
  metadata?: Record<string, any>;
}

/**
 * Notification creation input
 */
export interface CreateNotificationInput {
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data?: NotificationData;
}

/**
 * Notification update input
 */
export interface UpdateNotificationInput {
  is_read?: boolean;
  read_at?: string;
}

/**
 * Bulk notification creation input
 */
export interface CreateBulkNotificationInput {
  user_ids: string[];
  type: NotificationType;
  title: string;
  message: string;
  data?: NotificationData;
}

/**
 * Push notification payload
 */
export interface PushNotificationPayload {
  title: string;
  body: string;
  data?: Record<string, any>;
  badge?: number;
  sound?: string;
  image?: string;
}

/**
 * Email notification template
 */
export interface EmailNotificationTemplate {
  template_id: string;
  subject: string;
  html_content: string;
  text_content: string;
  variables: Record<string, any>;
}

/**
 * Notification preferences
 */
export interface NotificationPreferences {
  user_id: string;
  email_enabled: boolean;
  push_enabled: boolean;
  types: Record<NotificationType, {
    email: boolean;
    push: boolean;
  }>;
  quiet_hours?: {
    start: string; // HH:mm format
    end: string;   // HH:mm format
    timezone: string;
  };
}

/**
 * Notification statistics
 */
export interface NotificationStats {
  total_sent: number;
  total_read: number;
  read_rate: number;
  type_distribution: Record<NotificationType, number>;
  recent_activity: Array<{
    date: string;
    sent: number;
    read: number;
  }>;
}

/**
 * Notification search filters
 */
export interface NotificationFilters {
  type?: NotificationType;
  is_read?: boolean;
  date_from?: string;
  date_to?: string;
  target_type?: string;
  target_id?: string;
}

/**
 * Device token for push notifications
 */
export interface DeviceToken {
  id: string;
  user_id: string;
  token: string;
  platform: 'ios' | 'android' | 'web';
  is_active: boolean;
  last_used: string;
  created_at: string;
}

/**
 * Notification delivery status
 */
export interface NotificationDelivery {
  id: string;
  notification_id: string;
  channel: 'push' | 'email' | 'sms';
  status: 'pending' | 'sent' | 'delivered' | 'failed';
  external_id?: string;
  error_message?: string;
  delivered_at?: string;
  created_at: string;
}

// Export all types for use in other modules