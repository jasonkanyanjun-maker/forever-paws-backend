import { Router } from 'express';
import { NotificationController } from '../controllers/NotificationController';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validate, validateQuery, commonSchemas, notificationSchemas } from '../middleware/validation';

const router = Router();
const notificationController = new NotificationController();

/**
 * @swagger
 * components:
 *   schemas:
 *     Notification:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         user_id:
 *           type: string
 *           format: uuid
 *         type:
 *           type: string
 *           enum: [system, order, pet, video, letter]
 *         title:
 *           type: string
 *         content:
 *           type: string
 *         data:
 *           type: object
 *         status:
 *           type: string
 *           enum: [unread, read]
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/notifications:
 *   post:
 *     summary: 创建通知（管理员功能）
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - user_id
 *               - type
 *               - title
 *               - content
 *             properties:
 *               user_id:
 *                 type: string
 *                 format: uuid
 *                 description: 用户ID
 *               type:
 *                 type: string
 *                 enum: [system, order, pet, video, letter]
 *                 description: 通知类型
 *               title:
 *                 type: string
 *                 description: 通知标题
 *               content:
 *                 type: string
 *                 description: 通知内容
 *               data:
 *                 type: object
 *                 description: 附加数据
 *     responses:
 *       201:
 *         description: 通知创建成功
 */
router.post('/', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(notificationSchemas.createNotification), 
  notificationController.createNotification
);

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: 获取用户通知列表
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: 页码
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: 每页数量
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [system, order, pet, video, letter]
 *         description: 通知类型
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [unread, read]
 *         description: 通知状态
 *       - in: query
 *         name: sort_by
 *         schema:
 *           type: string
 *           enum: [created_at, type, status]
 *         description: 排序字段
 *       - in: query
 *         name: sort_order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: 排序方向
 *     responses:
 *       200:
 *         description: 获取通知列表成功
 */
router.get('/', 
  authenticateToken, 
  validateQuery(notificationSchemas.getUserNotifications), 
  notificationController.getUserNotifications
);

/**
 * @swagger
 * /api/notifications/unread-count:
 *   get:
 *     summary: 获取未读通知数量
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取未读通知数量成功
 */
router.get('/unread-count', 
  authenticateToken, 
  notificationController.getUnreadCount
);

/**
 * @swagger
 * /api/notifications/stats:
 *   get:
 *     summary: 获取通知统计信息
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取通知统计成功
 */
router.get('/stats', 
  authenticateToken, 
  notificationController.getNotificationStats
);

/**
 * @swagger
 * /api/notifications/mark-all-read:
 *   put:
 *     summary: 标记所有通知为已读
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 所有通知已标记为已读
 */
router.put('/mark-all-read', 
  authenticateToken, 
  notificationController.markAllAsRead
);

/**
 * @swagger
 * /api/notifications/mark-multiple-read:
 *   put:
 *     summary: 批量标记通知为已读
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ids
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: uuid
 *                 description: 通知ID列表
 *     responses:
 *       200:
 *         description: 通知批量标记为已读成功
 */
router.put('/mark-multiple-read', 
  authenticateToken, 
  validate(notificationSchemas.markMultipleAsRead), 
  notificationController.markMultipleAsRead
);

/**
 * @swagger
 * /api/notifications/delete-multiple:
 *   delete:
 *     summary: 批量删除通知
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ids
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: uuid
 *                 description: 通知ID列表
 *     responses:
 *       200:
 *         description: 通知批量删除成功
 */
router.delete('/delete-multiple', 
  authenticateToken, 
  validate(notificationSchemas.deleteMultipleNotifications), 
  notificationController.deleteMultipleNotifications
);

/**
 * @swagger
 * /api/notifications/clear-all:
 *   delete:
 *     summary: 清空所有通知
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 所有通知已清空
 */
router.delete('/clear-all', 
  authenticateToken, 
  notificationController.clearAllNotifications
);

/**
 * @swagger
 * /api/notifications/send-system:
 *   post:
 *     summary: 发送系统通知给所有用户（管理员功能）
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - content
 *             properties:
 *               title:
 *                 type: string
 *                 description: 通知标题
 *               content:
 *                 type: string
 *                 description: 通知内容
 *               data:
 *                 type: object
 *                 description: 附加数据
 *     responses:
 *       200:
 *         description: 系统通知发送成功
 */
router.post('/send-system', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(notificationSchemas.sendSystemNotification), 
  notificationController.sendSystemNotificationToAll
);



/**
 * @swagger
 * /api/notifications/{id}:
 *   get:
 *     summary: 获取通知详情
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 通知ID
 *     responses:
 *       200:
 *         description: 获取通知详情成功
 */
router.get('/:id', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  notificationController.getNotificationById
);

/**
 * @swagger
 * /api/notifications/{id}/read:
 *   put:
 *     summary: 标记通知为已读
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 通知ID
 *     responses:
 *       200:
 *         description: 通知已标记为已读
 */
router.put('/:id/read', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  notificationController.markAsRead
);

/**
 * @swagger
 * /api/notifications/{id}:
 *   delete:
 *     summary: 删除通知
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 通知ID
 *     responses:
 *       200:
 *         description: 通知删除成功
 */
router.delete('/:id', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  notificationController.deleteNotification
);

export default router;