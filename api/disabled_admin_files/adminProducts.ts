import { Router } from 'express';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 获取商品列表
router.get('/', authenticateAdmin, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search,
      category,
      isActive,
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);

    let query = supabase
      .from('products')
      .select(`
        *,
        inventory(
          stock_quantity,
          reserved_quantity,
          low_stock_threshold
        )
      `, { count: 'exact' });

    // 添加搜索条件
    if (search) {
      query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
    }
    if (category) {
      query = query.eq('category', category);
    }
    if (isActive !== undefined) {
      query = query.eq('is_active', isActive === 'true');
    }

    // 添加排序
    query = query.order(sortBy as string, { 
      ascending: sortOrder === 'asc' 
    });

    const { data: products, error, count } = await query
      .range(offset, offset + parseInt(limit as string) - 1);

    if (error) {
      throw error;
    }

    res.json({
      products: products || [],
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total: count || 0,
        totalPages: Math.ceil((count || 0) / parseInt(limit as string))
      }
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: '获取商品列表失败' });
  }
});

// 获取商品分类列表
router.get('/categories', authenticateAdmin, async (req, res) => {
  try {
    const { data: categories, error } = await supabase
      .from('products')
      .select('category')
      .not('category', 'is', null);

    if (error) {
      throw error;
    }

    // 去重并统计每个分类的商品数量
    const categoryCount = categories?.reduce((acc, item) => {
      acc[item.category] = (acc[item.category] || 0) + 1;
      return acc;
    }, {} as Record<string, number>) || {};

    const categoryList = Object.entries(categoryCount).map(([name, count]) => ({
      name,
      count
    }));

    res.json(categoryList);
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ error: '获取商品分类失败' });
  }
});

// 获取单个商品详情
router.get('/:productId', authenticateAdmin, async (req, res) => {
  try {
    const { productId } = req.params;

    const { data: product, error } = await supabase
      .from('products')
      .select(`
        *,
        inventory(*)
      `)
      .eq('id', productId)
      .single();

    if (error || !product) {
      return res.status(404).json({ error: '商品不存在' });
    }

    // 获取商品销售统计
    const { data: salesData } = await supabase
      .from('order_items')
      .select('quantity, unit_price, created_at')
      .eq('product_id', productId);

    const salesStats = {
      totalSold: salesData?.reduce((sum, item) => sum + item.quantity, 0) || 0,
      totalRevenue: salesData?.reduce((sum, item) => sum + (item.quantity * parseFloat(item.unit_price)), 0) || 0,
      orderCount: salesData?.length || 0
    };

    res.json({
      ...product,
      salesStats
    });
  } catch (error) {
    console.error('Get product details error:', error);
    res.status(500).json({ error: '获取商品详情失败' });
  }
});

// 创建商品
router.post('/', authenticateAdmin, async (req, res) => {
  try {
    const {
      name,
      description,
      price,
      category,
      imageUrl,
      isActive = true,
      stockQuantity = 0,
      lowStockThreshold = 10
    } = req.body;

    if (!name || !price || !category) {
      return res.status(400).json({ error: '商品名称、价格和分类不能为空' });
    }

    // 创建商品
    const { data: product, error: productError } = await supabase
      .from('products')
      .insert({
        name,
        description,
        price: parseFloat(price),
        category,
        image_url: imageUrl,
        is_active: isActive
      })
      .select()
      .single();

    if (productError) {
      throw productError;
    }

    // 创建库存记录
    const { data: inventory, error: inventoryError } = await supabase
      .from('inventory')
      .insert({
        product_id: product.id,
        stock_quantity: parseInt(stockQuantity),
        low_stock_threshold: parseInt(lowStockThreshold)
      })
      .select()
      .single();

    if (inventoryError) {
      throw inventoryError;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'create_product',
        target_type: 'product',
        target_id: product.id,
        details: { name, price, category },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.status(201).json({
      ...product,
      inventory
    });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ error: '创建商品失败' });
  }
});

// 更新商品
router.put('/:productId', authenticateAdmin, async (req, res) => {
  try {
    const { productId } = req.params;
    const {
      name,
      description,
      price,
      category,
      imageUrl,
      isActive
    } = req.body;

    const { data: product, error } = await supabase
      .from('products')
      .update({
        name,
        description,
        price: price ? parseFloat(price) : undefined,
        category,
        image_url: imageUrl,
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('id', productId)
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
        action: 'update_product',
        target_type: 'product',
        target_id: productId,
        details: { name, price, category, isActive },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json(product);
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ error: '更新商品失败' });
  }
});

// 删除商品
router.delete('/:productId', authenticateAdmin, async (req, res) => {
  try {
    const { productId } = req.params;

    // 检查商品是否存在订单项
    const { data: orderItems } = await supabase
      .from('order_items')
      .select('id')
      .eq('product_id', productId)
      .limit(1);

    if (orderItems && orderItems.length > 0) {
      return res.status(400).json({ error: '该商品已有订单记录，无法删除' });
    }

    // 删除库存记录
    await supabase
      .from('inventory')
      .delete()
      .eq('product_id', productId);

    // 删除商品
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', productId);

    if (error) {
      throw error;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'delete_product',
        target_type: 'product',
        target_id: productId,
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({ message: '商品删除成功' });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ error: '删除商品失败' });
  }
});

// 更新商品库存
router.put('/:productId/inventory', authenticateAdmin, async (req, res) => {
  try {
    const { productId } = req.params;
    const { stockQuantity, lowStockThreshold } = req.body;

    const { data: inventory, error } = await supabase
      .from('inventory')
      .update({
        stock_quantity: parseInt(stockQuantity),
        low_stock_threshold: parseInt(lowStockThreshold),
        updated_at: new Date().toISOString()
      })
      .eq('product_id', productId)
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
        action: 'update_inventory',
        target_type: 'inventory',
        target_id: productId,
        details: { stockQuantity, lowStockThreshold },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json(inventory);
  } catch (error) {
    console.error('Update inventory error:', error);
    res.status(500).json({ error: '更新库存失败' });
  }
});

// 批量更新商品状态
router.put('/batch/status', authenticateAdmin, async (req, res) => {
  try {
    const { productIds, isActive } = req.body;

    if (!Array.isArray(productIds) || productIds.length === 0) {
      return res.status(400).json({ error: '商品ID列表不能为空' });
    }

    const { data: products, error } = await supabase
      .from('products')
      .update({
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .in('id', productIds)
      .select();

    if (error) {
      throw error;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: req.admin?.adminId,
        action: 'batch_update_product_status',
        target_type: 'product',
        details: { productIds, isActive },
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({
      message: `成功${isActive ? '启用' : '禁用'}${products?.length || 0}个商品`,
      products
    });
  } catch (error) {
    console.error('Batch update product status error:', error);
    res.status(500).json({ error: '批量更新商品状态失败' });
  }
});

export default router;