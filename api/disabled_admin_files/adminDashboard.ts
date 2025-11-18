import { Router } from 'express';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 获取仪表板统计数据
router.get('/stats', authenticateAdmin, async (req, res) => {
  try {
    // 获取用户总数
    const { count: userCount } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });

    // 获取今日新增用户数
    const today = new Date().toISOString().split('T')[0];
    const { count: todayUserCount } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', today);

    // 获取订单总数和今日订单数
    const { count: orderCount } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true });

    const { count: todayOrderCount } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', today);

    // 获取商品总数
    const { count: productCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });

    // 获取今日API调用总数
    const { count: todayApiCallCount } = await supabase
      .from('api_call_logs')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', today);

    // 获取今日API调用成本
    const { data: todayApiCost } = await supabase
      .from('api_call_logs')
      .select('cost')
      .gte('created_at', today);

    const totalTodayCost = todayApiCost?.reduce((sum, record) => sum + (parseFloat(record.cost) || 0), 0) || 0;

    // 获取低库存商品数量
    const { count: lowStockCount } = await supabase
      .from('inventory')
      .select('*', { count: 'exact', head: true })
      .lt('stock_quantity', 'low_stock_threshold');

    res.json({
      users: {
        total: userCount || 0,
        todayNew: todayUserCount || 0
      },
      orders: {
        total: orderCount || 0,
        todayNew: todayOrderCount || 0
      },
      products: {
        total: productCount || 0,
        lowStock: lowStockCount || 0
      },
      apiCalls: {
        todayTotal: todayApiCallCount || 0,
        todayCost: totalTodayCost
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: '获取统计数据失败' });
  }
});

// 获取API调用趋势数据（最近7天）
router.get('/api-trends', authenticateAdmin, async (req, res) => {
  try {
    const { data: trends, error } = await supabase
      .from('api_daily_stats')
      .select('call_date, api_type, call_count, total_cost')
      .gte('call_date', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0])
      .order('call_date', { ascending: true });

    if (error) {
      throw error;
    }

    // 按日期和API类型分组数据
    const groupedData = trends?.reduce((acc, record) => {
      const date = record.call_date;
      if (!acc[date]) {
        acc[date] = {
          date,
          conversation: { calls: 0, cost: 0 },
          video: { calls: 0, cost: 0 }
        };
      }
      
      if (record.api_type === 'conversation') {
        acc[date].conversation.calls += record.call_count;
        acc[date].conversation.cost += parseFloat(record.total_cost) || 0;
      } else if (record.api_type === 'video') {
        acc[date].video.calls += record.call_count;
        acc[date].video.cost += parseFloat(record.total_cost) || 0;
      }
      
      return acc;
    }, {} as any) || {};

    const trendData = Object.values(groupedData);

    res.json(trendData);
  } catch (error) {
    console.error('Get API trends error:', error);
    res.status(500).json({ error: '获取API趋势数据失败' });
  }
});

// 获取订单状态分布
router.get('/order-status', authenticateAdmin, async (req, res) => {
  try {
    const { data: orderStatus, error } = await supabase
      .from('orders')
      .select('status')
      .order('status');

    if (error) {
      throw error;
    }

    // 统计各状态的订单数量
    const statusCount = orderStatus?.reduce((acc, order) => {
      acc[order.status] = (acc[order.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>) || {};

    res.json(statusCount);
  } catch (error) {
    console.error('Get order status error:', error);
    res.status(500).json({ error: '获取订单状态分布失败' });
  }
});

// 获取热门商品
router.get('/popular-products', authenticateAdmin, async (req, res) => {
  try {
    const { data: popularProducts, error } = await supabase
      .from('order_items')
      .select(`
        product_id,
        quantity,
        products!inner(name, price)
      `)
      .limit(10);

    if (error) {
      throw error;
    }

    // 按商品ID分组并计算总销量
    const productSales = popularProducts?.reduce((acc, item) => {
      const productId = item.product_id;
      if (!acc[productId]) {
        acc[productId] = {
          id: productId,
          name: item.products.name,
          price: item.products.price,
          totalSold: 0
        };
      }
      acc[productId].totalSold += item.quantity;
      return acc;
    }, {} as any) || {};

    // 转换为数组并按销量排序
    const sortedProducts = Object.values(productSales)
      .sort((a: any, b: any) => b.totalSold - a.totalSold)
      .slice(0, 5);

    res.json(sortedProducts);
  } catch (error) {
    console.error('Get popular products error:', error);
    res.status(500).json({ error: '获取热门商品失败' });
  }
});

// 获取最近活动日志
router.get('/recent-activities', authenticateAdmin, async (req, res) => {
  try {
    const { data: activities, error } = await supabase
      .from('admin_logs')
      .select(`
        id,
        action,
        target_type,
        created_at,
        admin_users!inner(username)
      `)
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) {
      throw error;
    }

    const formattedActivities = activities?.map(activity => ({
      id: activity.id,
      action: activity.action,
      targetType: activity.target_type,
      adminUsername: activity.admin_users.username,
      createdAt: activity.created_at
    })) || [];

    res.json(formattedActivities);
  } catch (error) {
    console.error('Get recent activities error:', error);
    res.status(500).json({ error: '获取最近活动失败' });
  }
});

export default router;