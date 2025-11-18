import { Router } from 'express';
import { OrderController } from '../controllers/OrderController';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validate, validateQuery } from '../middleware/validation';
import { orderSchemas } from '../schemas/orderSchemas';
import { commonSchemas } from '../schemas/commonSchemas';

const router = Router();
const orderController = new OrderController();

/**
 * @swagger
 * components:
 *   schemas:
 *     Order:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         user_id:
 *           type: string
 *           format: uuid
 *         total_amount:
 *           type: number
 *           format: decimal
 *         status:
 *           type: string
 *           enum: [pending, confirmed, shipped, delivered, cancelled]
 *         shipping_address:
 *           type: string
 *         contact_phone:
 *           type: string
 *         notes:
 *           type: string
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 *     OrderItem:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         order_id:
 *           type: string
 *           format: uuid
 *         product_id:
 *           type: string
 *           format: uuid
 *         quantity:
 *           type: integer
 *         unit_price:
 *           type: number
 *           format: decimal
 *         subtotal:
 *           type: number
 *           format: decimal
 */

/**
 * @swagger
 * /api/orders:
 *   post:
 *     summary: 创建订单
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - items
 *               - shipping_address
 *               - contact_phone
 *             properties:
 *               items:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - product_id
 *                     - quantity
 *                   properties:
 *                     product_id:
 *                       type: string
 *                       format: uuid
 *                     quantity:
 *                       type: integer
 *                       minimum: 1
 *               shipping_address:
 *                 type: string
 *                 description: 收货地址
 *               contact_phone:
 *                 type: string
 *                 description: 联系电话
 *               notes:
 *                 type: string
 *                 description: 订单备注
 *     responses:
 *       201:
 *         description: 订单创建成功
 */
router.post('/', 
  authenticateToken, 
  validate(orderSchemas.createOrder), 
  orderController.createOrder
);

/**
 * @swagger
 * /api/orders:
 *   get:
 *     summary: 获取用户订单列表
 *     tags: [Orders]
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
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, shipped, delivered, cancelled]
 *         description: 订单状态
 *       - in: query
 *         name: sort_by
 *         schema:
 *           type: string
 *           enum: [created_at, total_amount, status]
 *         description: 排序字段
 *       - in: query
 *         name: sort_order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: 排序方向
 *     responses:
 *       200:
 *         description: 获取订单列表成功
 */
router.get('/', 
  authenticateToken, 
  validateQuery(orderSchemas.getUserOrders), 
  orderController.getOrders
);

/**
 * @swagger
 * /api/orders/all:
 *   get:
 *     summary: 获取所有订单（管理员功能）
 *     tags: [Orders]
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
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, shipped, delivered, cancelled]
 *         description: 订单状态
 *       - in: query
 *         name: user_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 用户ID
 *       - in: query
 *         name: sort_by
 *         schema:
 *           type: string
 *           enum: [created_at, total_amount, status]
 *         description: 排序字段
 *       - in: query
 *         name: sort_order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: 排序方向
 *     responses:
 *       200:
 *         description: 获取所有订单成功
 */
router.get('/all', 
  authenticateToken, 
  requireRole(['admin']), 
  validateQuery(orderSchemas.getAllOrders), 
  orderController.getAllOrders
);

/**
 * @swagger
 * /api/orders/stats:
 *   get:
 *     summary: 获取订单统计信息（管理员功能）
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取订单统计成功
 */
router.get('/stats', 
  authenticateToken, 
  requireRole(['admin']), 
  orderController.getOrderStats
);

/**
 * @swagger
 * /api/orders/{id}:
 *   get:
 *     summary: 获取订单详情
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 订单ID
 *     responses:
 *       200:
 *         description: 获取订单详情成功
 */
router.get('/:id', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  orderController.getOrderById
);

/**
 * @swagger
 * /api/orders/{id}:
 *   put:
 *     summary: 更新订单信息
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 订单ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               shipping_address:
 *                 type: string
 *               contact_phone:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: 订单信息更新成功
 */
router.put('/:id', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  validate(orderSchemas.updateOrder), 
  orderController.updateOrder
);

/**
 * @swagger
 * /api/orders/{id}/cancel:
 *   put:
 *     summary: 取消订单
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 订单ID
 *     responses:
 *       200:
 *         description: 订单取消成功
 */
router.put('/:id/cancel', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  orderController.cancelOrder
);

/**
 * @swagger
 * /api/orders/{id}/status:
 *   put:
 *     summary: 更新订单状态（管理员功能）
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 订单ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, confirmed, shipped, delivered, cancelled]
 *                 description: 新的订单状态
 *     responses:
 *       200:
 *         description: 订单状态更新成功
 */
router.put('/:id/status', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(commonSchemas.idParam), 
  validate(orderSchemas.updateOrderStatus), 
  orderController.updateOrderStatus
);

/**
 * @swagger
 * /api/orders/{id}:
 *   delete:
 *     summary: 删除订单
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 订单ID
 *     responses:
 *       200:
 *         description: 订单删除成功
 */
router.delete('/:id', 
  authenticateToken, 
  validate(commonSchemas.idParam), 
  orderController.deleteOrder
);

export default router;