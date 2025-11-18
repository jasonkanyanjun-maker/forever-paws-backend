import { Router } from 'express';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 获取订单列表
router.get('/', authenticateAdmin, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search,
      status,
      dateFrom,
      dateTo,
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);

    let query = supabase
      .from('orders')
      .select(`
        *,
        order_items(
          id,
          product_id,
          quantity,
          unit_price,
          products(name, image_url)
        )
      `, { count: 'exact' });

    // 添加搜索条件
    if (search) {
      query = query.or(`id.ilike.%${search}%,user_id.ilike.%${search}%,payment_intent_id.ilike.%${search}%`);
    }
    if (status) {
      query = query.eq('status', status);
    }
    if (dateFrom) {
      query = query.gte('created_at', dateFrom);
    }
    if (dateTo) {
      query = query.lte('created_at', dateTo);
    }

    // 添加排序
    query = query.order(sortBy as string, { 
      ascending: sortOrder === 'asc' 
    });

    const { data: orders, error, count } = await query
      .range(offset, offset + parseInt(limit as string) - 1);

    if (error) {
      throw error;
    }

    res.json({
      orders: orders || [],
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total: count || 0,
        totalPages: Math.ceil((count || 0) / parseInt(limit as string))
      }
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: '获取订单列表失败' });
  }
});

// 获取订单统计
router.get('/stats', authenticateAdmin, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    
    let dateFilter = '';
    const now = new Date();
    
    switch (period) {
      case '24h':
        dateFilter = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
        break;
      case '7d':
        dateFilter = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
        break;
      case '30d':
        dateFilter = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();
        break;
      default:
        dateFilter = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
    }

    // 获取订单统计
    const { data: orderStats } = await supabase
      .from('orders')
      .select('status, total_amount, created_at')
      .gte('created_at', dateFilter);

    // 按状态统计
    const statusStats = orderStats?.reduce((acc, order) => {
      acc[order.status] = (acc[order.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>) || {};

    // 计算总收入
    const totalRevenue = orderStats?.reduce((sum, order) => 
      sum + parseFloat(order.total_amount), 0) || 0;

    // 按日期统计（最近7天）
    const dailyStats = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      
      const dayOrders = orderStats?.filter(order => 
        order.created_at.startsWith(dateStr)
      ) || [];
      
      dailyStats.push({
        date: dateStr,
        orderCount: dayOrders.length,
        revenue: dayOrders.reduce((sum, order) => 
          sum + parseFloat(order.total_amount), 0)
      });
    }

    res.json({
      statusStats,
      totalRevenue,
      totalOrders: orderStats?.length || 0,
      dailyStats
    });
  } catch (error) {
    console.error('Get order stats error:', error);
    res.status(500).json({ error: '获取订单统计失败' });
  }
});

// 获取单个订单详情
router.get('/:orderId', authenticateAdmin, async (req, res) => {
  try {
    const { orderId } = req.params;

    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        *,
        order_items(
          *,
          products(name, image_url, category)
        )
      `)
      .eq('id', orderId)
      .single();

    if (error || !order) {
      return res.status(404).json({ error: '订单不存在' });
    }

    res.json(order);
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({ error: '获取订单详情失败' });
  }
});

// 更新订单状态
router.put('/:orderId/status', authenticateAdmin, async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, trackingNumber, notes } = req.body;

    if (!status) {
      return res.status(400).json({ error: '订单状态不能为空' });
    }

    const updateData: any = {
      status,
      updated_at: new Date().toISOString()
    };

    if (trackingNumber) {
      updateData.tracking_number = trackingNumber;
    }
    if (notes) {
      updateData.notes = notes;
    }

    const { data: order, error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', orderId)
      .select()
      .single();

    if (error) {
      throw error;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'update_order_status',
        target_type: 'order',
        target_id: orderId,
        details: { status, trackingNumber, notes },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json(order);
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: '更新订单状态失败' });
  }
});

// 批量更新订单状态
router.put('/batch/status', authenticateAdmin, async (req, res) => {
  try {
    const { orderIds, status } = req.body;

    if (!Array.isArray(orderIds) || orderIds.length === 0) {
      return res.status(400).json({ error: '订单ID列表不能为空' });
    }

    if (!status) {
      return res.status(400).json({ error: '订单状态不能为空' });
    }

    const { data: orders, error } = await supabase
      .from('orders')
      .update({
        status,
        updated_at: new Date().toISOString()
      })
      .in('id', orderIds)
      .select();

    if (error) {
      throw error;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'batch_update_order_status',
        target_type: 'order',
        details: { orderIds, status },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({
      message: `成功更新${orders?.length || 0}个订单状态为${status}`,
      orders
    });
  } catch (error) {
    console.error('Batch update order status error:', error);
    res.status(500).json({ error: '批量更新订单状态失败' });
  }
});

// 导出订单数据
router.get('/export/csv', authenticateAdmin, async (req, res) => {
  try {
    const { 
      dateFrom,
      dateTo,
      status
    } = req.query;

    let query = supabase
      .from('orders')
      .select(`
        *,
        order_items(
          quantity,
          unit_price,
          products(name)
        )
      `);

    if (dateFrom) {
      query = query.gte('created_at', dateFrom);
    }
    if (dateTo) {
      query = query.lte('created_at', dateTo);
    }
    if (status) {
      query = query.eq('status', status);
    }

    const { data: orders, error } = await query.order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    // 生成CSV内容
    const csvHeaders = [
      '订单ID',
      '用户ID',
      '订单状态',
      '订单金额',
      '货币',
      '商品信息',
      '创建时间',
      '更新时间'
    ];

    const csvRows = orders?.map(order => {
      const products = order.order_items?.map((item: any) => 
        `${item.products?.name || '未知商品'} x${item.quantity}`
      ).join('; ') || '';

      return [
        order.id,
        order.user_id,
        order.status,
        order.total_amount,
        order.currency,
        products,
        order.created_at,
        order.updated_at
      ];
    }) || [];

    const csvContent = [csvHeaders, ...csvRows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n');

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'export_orders',
        target_type: 'order',
        details: { dateFrom, dateTo, status, count: orders?.length || 0 },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=orders_${new Date().toISOString().split('T')[0]}.csv`);
    res.send('\uFEFF' + csvContent); // 添加BOM以支持中文
  } catch (error) {
    console.error('Export orders error:', error);
    res.status(500).json({ error: '导出订单数据失败' });
  }
});

// 获取订单收入趋势
router.get('/analytics/revenue-trend', authenticateAdmin, async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    let days = 30;
    switch (period) {
      case '7d':
        days = 7;
        break;
      case '30d':
        days = 30;
        break;
      case '90d':
        days = 90;
        break;
    }

    const dateFrom = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    const { data: orders } = await supabase
      .from('orders')
      .select('total_amount, created_at, status')
      .gte('created_at', dateFrom)
      .eq('status', 'completed');

    // 按日期分组统计
    const dailyRevenue = new Map();
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      dailyRevenue.set(dateStr, 0);
    }

    orders?.forEach(order => {
      const dateStr = order.created_at.split('T')[0];
      if (dailyRevenue.has(dateStr)) {
        dailyRevenue.set(dateStr, dailyRevenue.get(dateStr) + parseFloat(order.total_amount));
      }
    });

    const trendData = Array.from(dailyRevenue.entries()).map(([date, revenue]) => ({
      date,
      revenue
    }));

    res.json(trendData);
  } catch (error) {
    console.error('Get revenue trend error:', error);
    res.status(500).json({ error: '获取收入趋势失败' });
  }
});

export default router;