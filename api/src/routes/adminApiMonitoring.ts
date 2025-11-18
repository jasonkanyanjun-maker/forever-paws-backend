import { Router } from 'express';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 获取API调用统计
router.get('/stats', authenticateAdmin, async (req, res) => {
  try {
    const { startDate, endDate, apiType } = req.query;
    
    let query = supabase
      .from('api_call_logs')
      .select('*');

    // 添加日期过滤
    if (startDate) {
      query = query.gte('created_at', startDate as string);
    }
    if (endDate) {
      query = query.lte('created_at', endDate as string);
    }
    if (apiType && apiType !== 'all') {
      query = query.eq('api_type', apiType as string);
    }

    const { data: apiCalls, error } = await query;

    if (error) {
      throw error;
    }

    // 统计数据
    const stats = {
      totalCalls: apiCalls?.length || 0,
      successfulCalls: apiCalls?.filter(call => call.success).length || 0,
      failedCalls: apiCalls?.filter(call => !call.success).length || 0,
      totalCost: apiCalls?.reduce((sum, call) => sum + (parseFloat(call.cost) || 0), 0) || 0,
      avgResponseTime: apiCalls?.length ? 
        apiCalls.reduce((sum, call) => sum + (call.response_time_ms || 0), 0) / apiCalls.length : 0,
      conversationCalls: apiCalls?.filter(call => call.api_type === 'conversation').length || 0,
      videoCalls: apiCalls?.filter(call => call.api_type === 'video').length || 0
    };

    res.json(stats);
  } catch (error) {
    console.error('Get API stats error:', error);
    res.status(500).json({ error: '获取API统计失败' });
  }
});

// 获取每日API调用统计
router.get('/daily-stats', authenticateAdmin, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const startDate = new Date(Date.now() - parseInt(days as string) * 24 * 60 * 60 * 1000)
      .toISOString().split('T')[0];

    const { data: dailyStats, error } = await supabase
      .from('api_daily_stats')
      .select('*')
      .gte('call_date', startDate)
      .order('call_date', { ascending: true });

    if (error) {
      throw error;
    }

    res.json(dailyStats || []);
  } catch (error) {
    console.error('Get daily API stats error:', error);
    res.status(500).json({ error: '获取每日API统计失败' });
  }
});

// 获取用户API使用排行
router.get('/user-usage', authenticateAdmin, async (req, res) => {
  try {
    const { limit = 20, apiType } = req.query;
    
    let query = supabase
      .from('user_daily_api_usage')
      .select(`
        user_id,
        conversation_calls,
        video_calls,
        total_calls,
        daily_cost,
        users!inner(email)
      `)
      .order('total_calls', { ascending: false })
      .limit(parseInt(limit as string));

    const { data: userUsage, error } = await query;

    if (error) {
      throw error;
    }

    // 按用户聚合数据
    const aggregatedUsage = userUsage?.reduce((acc, record) => {
      const userId = record.user_id;
      if (!acc[userId]) {
        acc[userId] = {
          userId,
          email: record.users.email,
          totalConversationCalls: 0,
          totalVideoCalls: 0,
          totalCalls: 0,
          totalCost: 0
        };
      }
      
      acc[userId].totalConversationCalls += record.conversation_calls || 0;
      acc[userId].totalVideoCalls += record.video_calls || 0;
      acc[userId].totalCalls += record.total_calls || 0;
      acc[userId].totalCost += parseFloat(record.daily_cost) || 0;
      
      return acc;
    }, {} as any) || {};

    const sortedUsers = Object.values(aggregatedUsage)
      .sort((a: any, b: any) => b.totalCalls - a.totalCalls);

    res.json(sortedUsers);
  } catch (error) {
    console.error('Get user usage error:', error);
    res.status(500).json({ error: '获取用户使用统计失败' });
  }
});

// 获取API限额设置
router.get('/limits', authenticateAdmin, async (req, res) => {
  try {
    const { data: limits, error } = await supabase
      .from('user_api_limits')
      .select(`
        *,
        users!inner(email)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    const formattedLimits = limits?.map(limit => ({
      id: limit.id,
      userId: limit.user_id,
      userEmail: limit.users.email,
      dailyConversationLimit: limit.daily_conversation_limit,
      dailyVideoLimit: limit.daily_video_limit,
      monthlyConversationLimit: limit.monthly_conversation_limit,
      monthlyVideoLimit: limit.monthly_video_limit,
      isActive: limit.is_active,
      createdAt: limit.created_at,
      updatedAt: limit.updated_at
    })) || [];

    res.json(formattedLimits);
  } catch (error) {
    console.error('Get API limits error:', error);
    res.status(500).json({ error: '获取API限额失败' });
  }
});

// 更新用户API限额
router.put('/limits/:userId', authenticateAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      dailyConversationLimit,
      dailyVideoLimit,
      monthlyConversationLimit,
      monthlyVideoLimit,
      isActive
    } = req.body;

    const { data: updatedLimit, error } = await supabase
      .from('user_api_limits')
      .update({
        daily_conversation_limit: dailyConversationLimit,
        daily_video_limit: dailyVideoLimit,
        monthly_conversation_limit: monthlyConversationLimit,
        monthly_video_limit: monthlyVideoLimit,
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
        action: 'update_api_limits',
        target_type: 'user_api_limits',
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

    res.json(updatedLimit);
  } catch (error) {
    console.error('Update API limits error:', error);
    res.status(500).json({ error: '更新API限额失败' });
  }
});

// 获取API调用详细日志
router.get('/logs', authenticateAdmin, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 50, 
      userId, 
      apiType, 
      success,
      startDate,
      endDate 
    } = req.query;

    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);

    let query = supabase
      .from('api_call_logs')
      .select(`
        *,
        users!inner(email)
      `, { count: 'exact' });

    // 添加过滤条件
    if (userId) {
      query = query.eq('user_id', userId);
    }
    if (apiType && apiType !== 'all') {
      query = query.eq('api_type', apiType);
    }
    if (success !== undefined) {
      query = query.eq('success', success === 'true');
    }
    if (startDate) {
      query = query.gte('created_at', startDate as string);
    }
    if (endDate) {
      query = query.lte('created_at', endDate as string);
    }

    const { data: logs, error, count } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit as string) - 1);

    if (error) {
      throw error;
    }

    const formattedLogs = logs?.map(log => ({
      id: log.id,
      userId: log.user_id,
      userEmail: log.users.email,
      apiType: log.api_type,
      modelName: log.model_name,
      endpoint: log.endpoint,
      tokensUsed: log.tokens_used,
      cost: log.cost,
      responseTimeMs: log.response_time_ms,
      success: log.success,
      errorMessage: log.error_message,
      createdAt: log.created_at
    })) || [];

    res.json({
      logs: formattedLogs,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total: count || 0,
        totalPages: Math.ceil((count || 0) / parseInt(limit as string))
      }
    });
  } catch (error) {
    console.error('Get API logs error:', error);
    res.status(500).json({ error: '获取API日志失败' });
  }
});

// 获取成本分析
router.get('/cost-analysis', authenticateAdmin, async (req, res) => {
  try {
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

    const { data: costData, error } = await supabase
      .from('api_call_logs')
      .select('api_type, cost, created_at')
      .gte('created_at', startDate)
      .eq('success', true);

    if (error) {
      throw error;
    }

    // 按API类型分组成本
    const costByType = costData?.reduce((acc, record) => {
      const type = record.api_type;
      acc[type] = (acc[type] || 0) + (parseFloat(record.cost) || 0);
      return acc;
    }, {} as Record<string, number>) || {};

    // 计算总成本
    const totalCost = Object.values(costByType).reduce((sum, cost) => sum + cost, 0);

    // 按日期分组成本趋势
    const costTrend = costData?.reduce((acc, record) => {
      const date = record.created_at.split('T')[0];
      acc[date] = (acc[date] || 0) + (parseFloat(record.cost) || 0);
      return acc;
    }, {} as Record<string, number>) || {};

    res.json({
      totalCost,
      costByType,
      costTrend: Object.entries(costTrend).map(([date, cost]) => ({
        date,
        cost
      })).sort((a, b) => a.date.localeCompare(b.date))
    });
  } catch (error) {
    console.error('Get cost analysis error:', error);
    res.status(500).json({ error: '获取成本分析失败' });
  }
});

export default router;