import { Router } from 'express';
import { ProductController } from '../controllers/ProductController';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validate, validateQuery } from '../middleware/validation';
import { productSchemas } from '../schemas/productSchemas';
import { commonSchemas } from '../schemas/commonSchemas';

const router = Router();
const productController = new ProductController();

/**
 * @swagger
 * components:
 *   schemas:
 *     Product:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         description:
 *           type: string
 *         price:
 *           type: number
 *           format: decimal
 *         category:
 *           type: string
 *         image_url:
 *           type: string
 *         stock_quantity:
 *           type: integer
 *         is_active:
 *           type: boolean
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/products:
 *   post:
 *     summary: 创建商品（管理员功能）
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - price
 *               - category
 *             properties:
 *               name:
 *                 type: string
 *                 description: 商品名称
 *               description:
 *                 type: string
 *                 description: 商品描述
 *               price:
 *                 type: number
 *                 description: 商品价格
 *               category:
 *                 type: string
 *                 description: 商品分类
 *               image_url:
 *                 type: string
 *                 description: 商品图片URL
 *               stock_quantity:
 *                 type: integer
 *                 description: 库存数量
 *               is_active:
 *                 type: boolean
 *                 description: 是否激活
 *     responses:
 *       201:
 *         description: 商品创建成功
 */
router.post('/', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(productSchemas.createProduct), 
  productController.createProduct
);

/**
 * @swagger
 * /api/products:
 *   get:
 *     summary: 获取商品列表
 *     tags: [Products]
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
 *         name: search
 *         schema:
 *           type: string
 *         description: 搜索关键词
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: 商品分类
 *       - in: query
 *         name: min_price
 *         schema:
 *           type: number
 *         description: 最低价格
 *       - in: query
 *         name: max_price
 *         schema:
 *           type: number
 *         description: 最高价格
 *       - in: query
 *         name: is_active
 *         schema:
 *           type: boolean
 *         description: 是否激活
 *       - in: query
 *         name: sort_by
 *         schema:
 *           type: string
 *           enum: [name, price, created_at]
 *         description: 排序字段
 *       - in: query
 *         name: sort_order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: 排序方向
 *     responses:
 *       200:
 *         description: 获取商品列表成功
 */
router.get('/', 
  validateQuery(productSchemas.getProducts), 
  productController.getProducts
);

/**
 * @swagger
 * /api/products/categories:
 *   get:
 *     summary: 获取商品分类列表
 *     tags: [Products]
 *     responses:
 *       200:
 *         description: 获取商品分类成功
 */
router.get('/categories', productController.getCategories);

/**
 * @swagger
 * /api/products/popular:
 *   get:
 *     summary: 获取热门商品
 *     tags: [Products]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 50
 *         description: 返回数量限制
 *     responses:
 *       200:
 *         description: 获取热门商品成功
 */
router.get('/popular', 
  validateQuery(productSchemas.getPopularProducts), 
  productController.getPopularProducts
);

/**
 * @swagger
 * /api/products/stats:
 *   get:
 *     summary: 获取商品统计信息（管理员功能）
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取商品统计成功
 */
router.get('/stats', 
  authenticateToken, 
  requireRole(['admin']), 
  productController.getProductStats
);

/**
 * @swagger
 * /api/products/{id}:
 *   get:
 *     summary: 获取商品详情
 *     tags: [Products]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 商品ID
 *     responses:
 *       200:
 *         description: 获取商品详情成功
 */
router.get('/:id', 
  validate(commonSchemas.idParam), 
  productController.getProductById
);

/**
 * @swagger
 * /api/products/{id}:
 *   put:
 *     summary: 更新商品信息（管理员功能）
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 商品ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               price:
 *                 type: number
 *               category:
 *                 type: string
 *               image_url:
 *                 type: string
 *               stock_quantity:
 *                 type: integer
 *               is_active:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: 商品信息更新成功
 */
router.put('/:id', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(commonSchemas.idParam), 
  validate(productSchemas.updateProduct), 
  productController.updateProduct
);

/**
 * @swagger
 * /api/products/{id}:
 *   delete:
 *     summary: 删除商品（管理员功能）
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 商品ID
 *     responses:
 *       200:
 *         description: 商品删除成功
 */
router.delete('/:id', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(commonSchemas.idParam), 
  productController.deleteProduct
);

/**
 * @swagger
 * /api/products/{id}/stock:
 *   put:
 *     summary: 更新商品库存（管理员功能）
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 商品ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - quantity
 *               - operation
 *             properties:
 *               quantity:
 *                 type: integer
 *                 minimum: 1
 *                 description: 数量
 *               operation:
 *                 type: string
 *                 enum: [increase, decrease]
 *                 description: 操作类型
 *     responses:
 *       200:
 *         description: 库存更新成功
 */
router.put('/:id/stock', 
  authenticateToken, 
  requireRole(['admin']), 
  validate(commonSchemas.idParam), 
  validate(productSchemas.updateStock), 
  productController.updateStock
);

/**
 * @swagger
 * /api/products/{id}/stock/check:
 *   get:
 *     summary: 检查商品库存
 *     tags: [Products]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: 商品ID
 *       - in: query
 *         name: quantity
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: 需要的数量
 *     responses:
 *       200:
 *         description: 库存检查完成
 */
router.get('/:id/stock/check', 
  validate(commonSchemas.idParam), 
  validateQuery(productSchemas.checkStock), 
  productController.checkStock
);

export default router;