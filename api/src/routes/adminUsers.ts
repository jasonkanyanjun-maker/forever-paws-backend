import { Router } from 'express';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 获取用户列表
router.get('/', authenticateAdmin, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search,
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);

    let query = supabase
      .from('users')
      .select(`
        id,
        email,
        created_at,
        updated_at,
        user_api_limits(
          daily_conversation_limit,
          daily_video_limit,
          monthly_conversation_limit,
          monthly_video_limit,
          is_active
        )
      `, { count: 'exact' });

    // 添加搜索条件
    if (search) {
      query = query.ilike('email', `%${search}%`);
    }

    // 添加排序
    query = query.order(sortBy as string, { 
      ascending: sortOrder === 'asc' 
    });

    const { data: users, error, count } = await query
      .range(offset, offset + parseInt(limit as string) - 1);

    if (error) {
      throw error;
    }

    // 获取每个用户的API使用统计
    const userIds = users?.map(user => user.id) || [];
    
    const { data: apiUsage } = await supabase
      .from('user_daily_api_usage')
      .select('user_id, conversation_calls, video_calls, total_calls, daily_cost')
      .in('user_id', userIds);

    // 合并用户数据和API使用数据
    const usersWithStats = users?.map(user => {
      const usage = apiUsage?.filter(u => u.user_id === user.id) || [];
      const totalConversationCalls = usage.reduce((sum, u) => sum + (u.conversation_calls || 0), 0);
      const totalVideoCalls = usage.reduce((sum, u) => sum + (u.video_calls || 0), 0);
      const totalCalls = usage.reduce((sum, u) => sum + (u.total_calls || 0), 0);
      const totalCost = usage.reduce((sum, u) => sum + (parseFloat(u.daily_cost) || 0), 0);

      return {
        ...user,
        apiUsage: {
          totalConversationCalls,
          totalVideoCalls,
          totalCalls,
          totalCost
        }
      };
    }) || [];

    res.json({
      users: usersWithStats,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total: count || 0,
        totalPages: Math.ceil((count || 0) / parseInt(limit as string))
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: '获取用户列表失败' });
  }
});

// 获取单个用户详情
router.get('/:userId', authenticateAdmin, async (req, res) => {
  try {
    const { userId } = req.params;

    // 获取用户基本信息
    const { data: user, error: userError } = await supabase
      .from('users')
      .select(`
        *,
        user_api_limits(*)
      `)
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 获取用户API使用历史
    const { data: apiUsageHistory } = await supabase
      .from('user_daily_api_usage')
      .select('*')
      .eq('user_id', userId)
      .order('usage_date', { ascending: false })
      .limit(30);

    // 获取用户最近的API调用日志
    const { data: recentApiCalls } = await supabase
      .from('api_call_logs')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(20);

    // 获取用户订单信息
    const { data: orders } = await supabase
      .from('orders')
      .select(`
        id,
        status,
        total_amount,
        created_at,
        order_items(
          quantity,
          unit_price,
          products(name)
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    res.json({
      user,
      apiUsageHistory: apiUsageHistory || [],
      recentApiCalls: recentApiCalls || [],
      orders: orders || []
    });
  } catch (error) {
    console.error('Get user details error:', error);
    res.status(500).json({ error: '获取用户详情失败' });
  }
});

// 更新用户API限额
router.put('/:userId/api-limits', authenticateAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      dailyConversationLimit,
      dailyVideoLimit,
      monthlyConversationLimit,
      monthlyVideoLimit,
      isActive
    } = req.body;

    // 检查用户是否存在
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 更新或创建API限额
    const { data: updatedLimits, error } = await supabase
      .from('user_api_limits')
      .upsert({
        user_id: userId,
        daily_conversation_limit: dailyConversationLimit,
        daily_video_limit: dailyVideoLimit,
        monthly_conversation_limit: monthlyConversationLimit,
        monthly_video_limit: monthlyVideoLimit,
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
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
        action: 'update_user_api_limits',
        target_type: 'user',
        target_id: userId,
        details: {
          dailyConversationLimit,
          dailyVideoLimit,
          monthlyConversationLimit,
          monthlyVideoLimit,
          isActive
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json(updatedLimits);
  } catch (error) {
    console.error('Update user API limits error:', error);
    res.status(500).json({ error: '更新用户API限额失败' });
  }
});

// 禁用/启用用户
router.put('/:userId/status', authenticateAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;

    // 更新用户API限额状态
    const { data: updatedLimits, error } = await supabase
      .from('user_api_limits')
      .update({
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('user_id', userId)
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
        action: isActive ? 'enable_user' : 'disable_user',
        target_type: 'user',
        target_id: userId,
        details: { isActive },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({ 
      message: `用户已${isActive ? '启用' : '禁用'}`,
      limits: updatedLimits 
    });
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ error: '更新用户状态失败' });
  }
});

// 获取用户API使用统计
router.get('/:userId/api-stats', authenticateAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { period = 'month' } = req.query;

    let startDate: string;
    const now = new Date();
    
    switch (period) {
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
        break;
      case 'month':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
        break;
      case 'year':
        startDate = new Date(now.getFullYear(), 0, 1).toISOString();
        break;
      default:
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();
    }

    // 获取API调用统计
    const { data: apiCalls, error } = await supabase
      .from('api_call_logs')
      .select('*')
      .eq('user_id', userId)
      .gte('created_at', startDate);

    if (error) {
      throw error;
    }

    // 统计数据
    const stats = {
      totalCalls: apiCalls?.length || 0,
      successfulCalls: apiCalls?.filter(call => call.success).length || 0,
      failedCalls: apiCalls?.filter(call => !call.success).length || 0,
      totalCost: apiCalls?.reduce((sum, call) => sum + (parseFloat(call.cost) || 0), 0) || 0,
      conversationCalls: apiCalls?.filter(call => call.api_type === 'conversation').length || 0,
      videoCalls: apiCalls?.filter(call => call.api_type === 'video').length || 0,
      avgResponseTime: apiCalls?.length ? 
        apiCalls.reduce((sum, call) => sum + (call.response_time_ms || 0), 0) / apiCalls.length : 0
    };

    // 按日期分组调用次数
    const dailyUsage = apiCalls?.reduce((acc, call) => {
      const date = call.created_at.split('T')[0];
      if (!acc[date]) {
        acc[date] = {
          date,
          conversation: 0,
          video: 0,
          total: 0,
          cost: 0
        };
      }
      
      acc[date].total += 1;
      acc[date].cost += parseFloat(call.cost) || 0;
      
      if (call.api_type === 'conversation') {
        acc[date].conversation += 1;
      } else if (call.api_type === 'video') {
        acc[date].video += 1;
      }
      
      return acc;
    }, {} as any) || {};

    const dailyUsageArray = Object.values(dailyUsage)
      .sort((a: any, b: any) => a.date.localeCompare(b.date));

    res.json({
      stats,
      dailyUsage: dailyUsageArray
    });
  } catch (error) {
    console.error('Get user API stats error:', error);
    res.status(500).json({ error: '获取用户API统计失败' });
  }
});

export default router;