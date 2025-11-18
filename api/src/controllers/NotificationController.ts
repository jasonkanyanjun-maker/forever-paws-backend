import { Request, Response } from 'express';
import { NotificationService } from '../services/NotificationService';
import { AuthenticatedRequest } from '../types/common';
import { asyncHandler } from '../utils/asyncHandler';

export class NotificationController {
  private notificationService: NotificationService;

  constructor() {
    this.notificationService = new NotificationService();
  }

  /**
   * 创建通知
   */
  createNotification = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const notification = await NotificationService.createNotification(req.body);

    res.status(201).json({
      success: true,
      message: '通知创建成功',
      data: notification
    });
  });

  /**
   * 获取用户通知列表
   */
  getUserNotifications = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user!.userId;
    const filters = {
      type: req.query.type as string,
      status: req.query.status as 'unread' | 'read',
      page: parseInt(req.query.page as string) || 1,
      limit: parseInt(req.query.limit as string) || 20,
      sort_by: req.query.sort_by as 'created_at' | 'type' | 'status' || 'created_at',
      sort_order: req.query.sort_order as 'asc' | 'desc' || 'desc'
    };

    const result = await NotificationService.getUserNotifications(userId, filters);

    res.json({
      success: true,
      message: '获取通知列表成功',
      data: result.notifications,
      pagination: result.pagination
    });
  });

  /**
   * 根据ID获取通知详情
   */
  getNotificationById = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const userId = req.user!.userId;
    const notification = await NotificationService.getNotificationById(id, userId);

    res.json({
      success: true,
      message: '获取通知详情成功',
      data: notification
    });
  });

  /**
   * 标记通知为已读
   */
  markAsRead = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const userId = req.user!.userId;
    const notification = await NotificationService.markAsRead(id, userId);

    res.json({
      success: true,
      message: '标记已读成功',
      data: notification
    });
  });

  /**
   * 批量标记通知为已读
   */
  markMultipleAsRead = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { notification_ids } = req.body;
    const userId = req.user!.userId;
    await NotificationService.markMultipleAsRead(notification_ids, userId);

    res.json({
      success: true,
      message: '批量标记已读成功'
    });
  });

  /**
   * 标记所有通知为已读
   */
  markAllAsRead = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user!.userId;
    await NotificationService.markAllAsRead(userId);

    res.json({
      success: true,
      message: '标记所有通知已读成功'
    });
  });

  /**
   * 删除通知
   */
  deleteNotification = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const userId = req.user!.userId;
    await NotificationService.deleteNotification(id, userId);

    res.json({
      success: true,
      message: '删除通知成功'
    });
  });

  /**
   * 批量删除通知
   */
  deleteMultipleNotifications = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { notification_ids } = req.body;
    const userId = req.user!.userId;
    await NotificationService.deleteMultipleNotifications(notification_ids, userId);

    res.json({
      success: true,
      message: '批量删除通知成功'
    });
  });

  /**
   * 清空所有通知
   */
  clearAllNotifications = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user!.userId;
    await NotificationService.clearAllNotifications(userId);

    res.json({
      success: true,
      message: '清空所有通知成功'
    });
  });

  /**
   * 获取未读通知数量
   */
  getUnreadCount = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user!.userId;
    const count = await NotificationService.getUnreadCount(userId);

    res.json({
      success: true,
      message: '获取未读通知数量成功',
      data: { count }
    });
  });

  /**
   * 获取通知统计信息
   */
  getNotificationStats = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user!.userId;
    const stats = await NotificationService.getNotificationStats(userId);

    res.json({
      success: true,
      message: '获取通知统计成功',
      data: stats
    });
  });

  /**
   * 发送系统通知给所有用户
   */
  sendSystemNotificationToAll = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { title, content, data } = req.body;
    const result = await NotificationService.sendSystemNotification(title, content, 'info', data);

    res.json({
      success: true,
      message: '系统通知发送成功',
      data: result
    });
  });


}