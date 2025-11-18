import { Router } from 'express';
import authRoutes from './auth';
import petRoutes from './pets';
import letterRoutes from './letters';
import videoRoutes from './videos';
import uploadRoutes from './upload';
import productRoutes from './products';
import orderRoutes from './orders';
import notificationRoutes from './notifications';
import healthRoutes from './health';

const router = Router();

// 健康检查路由 (优先级最高)
router.use('/health', healthRoutes);

// API 路由
router.use('/auth', authRoutes);
router.use('/pets', petRoutes);
router.use('/letters', letterRoutes);
router.use('/videos', videoRoutes);
router.use('/upload', uploadRoutes);
router.use('/products', productRoutes);
router.use('/orders', orderRoutes);
router.use('/notifications', notificationRoutes);

// 备用健康检查路由 (已移至 /health 路由)
// router.get('/health', (req, res) => {
//   res.json({
//     success: true,
//     message: 'Forever Paws API is running',
//     timestamp: new Date().toISOString(),
//     version: '1.0.0'
//   });
// });

// API 信息路由
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Forever Paws API',
    version: '1.0.0',
    documentation: '/api-docs',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      pets: '/api/pets',
      letters: '/api/letters',
      videos: '/api/videos',
      upload: '/api/upload',
      families: '/api/families',
      products: '/api/products',
      orders: '/api/orders',
      notifications: '/api/notifications',
      health: '/api/health'
    }
  });
});

export default router;