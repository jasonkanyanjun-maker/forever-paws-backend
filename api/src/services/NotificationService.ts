import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';

export interface CreateNotificationData {
  user_id: string;
  title: string;
  message: string;
  type?: 'info' | 'warning' | 'error' | 'success';
  metadata?: any;
}

export interface NotificationQueryOptions {
  page?: number;
  limit?: number;
  type?: string;
  read?: boolean;
  start_date?: string;
  end_date?: string;
}

export interface NotificationStats {
  total: number;
  unread: number;
  by_type: Record<string, number>;
}

export class NotificationService {
  /**
   * 创建通知
   */
  static async createNotification(data: CreateNotificationData) {
    try {
      const { data: notification, error } = await supabase
        .from('notifications')
        .insert({
          user_id: data.user_id,
          title: data.title,
          message: data.message,
          type: data.type || 'info',
          metadata: data.metadata,
          read: false,
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`创建通知失败: ${error.message}`);
      }

      return notification;
    } catch (error) {
      if (error instanceof Error && error.message.includes('创建通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`创建通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 批量创建通知
   */
  static async createBulkNotifications(notifications: CreateNotificationData[]) {
    try {
      const notificationData = notifications.map(data => ({
        user_id: data.user_id,
        title: data.title,
        message: data.message,
        type: data.type || 'info',
        metadata: data.metadata,
        read: false,
        created_at: new Date().toISOString()
      }));

      const { data, error } = await supabase
        .from('notifications')
        .insert(notificationData)
        .select();

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`批量创建通知失败: ${error.message}`);
      }

      return data;
    } catch (error) {
      if (error instanceof Error && error.message.includes('批量创建通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`批量创建通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 获取用户通知列表
   */
  static async getUserNotifications(userId: string, options: NotificationQueryOptions = {}) {
    try {
      const { 
        page = 1, 
        limit = 10, 
        type, 
        read,
        start_date, 
        end_date 
      } = options;

      let query = supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      // 应用过滤条件
      if (type) {
        query = query.eq('type', type);
      }

      if (read !== undefined) {
        query = query.eq('read', read);
      }

      if (start_date) {
        query = query.gte('created_at', start_date);
      }

      if (end_date) {
        query = query.lte('created_at', end_date);
      }

      // 分页
      const from = (page - 1) * limit;
      const to = from + limit - 1;
      query = query.range(from, to);

      const { data: notifications, error } = await query;

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`获取通知列表失败: ${error.message}`);
      }

      // 获取总数
      let countQuery = supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (type) {
        countQuery = countQuery.eq('type', type);
      }

      if (read !== undefined) {
          countQuery = countQuery.eq('read', read);
        }

      if (start_date) {
        countQuery = countQuery.gte('created_at', start_date);
      }

      if (end_date) {
        countQuery = countQuery.lte('created_at', end_date);
      }

      const { count, error: allCountError } = await countQuery;

      if (allCountError) {
        throw ErrorTypes.INTERNAL_ERROR(`获取通知总数失败: ${allCountError.message}`);
      }

      return {
        notifications,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      };
    } catch (error) {
      if (error instanceof Error && error.message.includes('获取通知')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`获取通知列表失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 获取通知详情
   */
  static async getNotificationById(notificationId: string, userId: string) {
    try {
      const { data: notification, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('id', notificationId)
        .eq('user_id', userId)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          throw ErrorTypes.NOT_FOUND('通知不存在');
        }
        throw ErrorTypes.INTERNAL_ERROR(`获取通知详情失败: ${error.message}`);
      }

      return notification;
    } catch (error) {
      if (error instanceof Error && (error.message.includes('通知不存在') || error.message.includes('获取通知详情失败'))) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`获取通知详情失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 标记通知为已读
   */
  static async markAsRead(notificationId: string, userId: string) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .update({ read: true, updated_at: new Date().toISOString() })
        .eq('id', notificationId)
        .eq('user_id', userId)
        .select()
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          throw ErrorTypes.NOT_FOUND('通知不存在');
        }
        throw ErrorTypes.INTERNAL_ERROR(`标记通知已读失败: ${error.message}`);
      }

      return data;
    } catch (error) {
      if (error instanceof Error && (error.message.includes('通知不存在') || error.message.includes('标记通知已读失败'))) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`标记通知已读失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 批量标记通知为已读
   */
  static async markMultipleAsRead(notificationIds: string[], userId: string) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .update({ read: true, updated_at: new Date().toISOString() })
        .in('id', notificationIds)
        .eq('user_id', userId)
        .select();

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`批量标记通知已读失败: ${error.message}`);
      }

      return data;
    } catch (error) {
      if (error instanceof Error && error.message.includes('批量标记通知已读失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`批量标记通知已读失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 标记所有通知为已读
   */
  static async markAllAsRead(userId: string) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .update({ read: true, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
        .eq('read', false)
        .select();

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`标记所有通知已读失败: ${error.message}`);
      }

      return data;
    } catch (error) {
      if (error instanceof Error && error.message.includes('标记所有通知已读失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`标记所有通知已读失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 删除通知
   */
  static async deleteNotification(notificationId: string, userId: string) {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`删除通知失败: ${error.message}`);
      }

      return { success: true };
    } catch (error) {
      if (error instanceof Error && error.message.includes('删除通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`删除通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 批量删除通知
   */
  static async deleteMultipleNotifications(notificationIds: string[], userId: string) {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .in('id', notificationIds)
        .eq('user_id', userId);

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`批量删除通知失败: ${error.message}`);
      }

      return { success: true };
    } catch (error) {
      if (error instanceof Error && error.message.includes('批量删除通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`批量删除通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 清空用户所有通知
   */
  static async clearAllNotifications(userId: string) {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId);

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`清空通知失败: ${error.message}`);
      }

      return { success: true };
    } catch (error) {
      if (error instanceof Error && error.message.includes('清空通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`清空通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 获取未读通知数量
   */
  static async getUnreadCount(userId: string) {
    try {
      const { count, error } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('read', false);

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`获取未读通知数量失败: ${error.message}`);
      }

      return count || 0;
    } catch (error) {
      if (error instanceof Error && error.message.includes('获取未读通知数量失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`获取未读通知数量失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 获取通知统计
   */
  static async getNotificationStats(userId: string): Promise<NotificationStats> {
    try {
      // 获取总数
      const { count: total, error: totalError } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (totalError) {
        throw ErrorTypes.INTERNAL_ERROR(`获取通知统计失败: ${totalError.message}`);
      }

      // 获取未读数量
      const { count: unread, error: unreadError } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('read', false);

      if (unreadError) {
        throw ErrorTypes.INTERNAL_ERROR(`获取未读通知统计失败: ${unreadError.message}`);
      }

      // 获取按类型统计
      const { data: typeStats, error: typeError } = await supabase
        .from('notifications')
        .select('type')
        .eq('user_id', userId);

      if (typeError) {
        throw ErrorTypes.INTERNAL_ERROR(`获取通知类型统计失败: ${typeError.message}`);
      }

      const by_type: Record<string, number> = {};
      typeStats?.forEach(item => {
        by_type[item.type] = (by_type[item.type] || 0) + 1;
      });

      return {
        total: total || 0,
        unread: unread || 0,
        by_type
      };
    } catch (error) {
      if (error instanceof Error && error.message.includes('获取')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`获取通知统计失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 发送系统通知给所有用户
   */
  static async sendSystemNotification(title: string, message: string, type: 'info' | 'warning' | 'error' | 'success' = 'info', metadata?: any) {
    try {
      // 获取所有用户
      const { data: users, error: usersError } = await supabase
        .from('users')
        .select('id');

      if (usersError) {
        throw ErrorTypes.INTERNAL_ERROR(`获取用户列表失败: ${usersError.message}`);
      }

      if (!users || users.length === 0) {
        return { success: true, count: 0 };
      }

      // 为每个用户创建通知
      const notifications = users.map(user => ({
        user_id: user.id,
        title,
        message,
        type,
        metadata,
        read: false,
        created_at: new Date().toISOString()
      }));

      const { data, error } = await supabase
        .from('notifications')
        .insert(notifications)
        .select();

      if (error) {
        throw ErrorTypes.INTERNAL_ERROR(`发送系统通知失败: ${error.message}`);
      }

      return { success: true, count: data?.length || 0 };
    } catch (error) {
      if (error instanceof Error && error.message.includes('发送系统通知失败')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(`发送系统通知失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }


}