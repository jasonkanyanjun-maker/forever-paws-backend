import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';

export interface CreateProductData {
  name: string;
  description?: string;
  price: number;
  category: string;
  image_url?: string;
  stock_quantity?: number;
  images?: string[];
}

export interface UpdateProductData {
  name?: string;
  description?: string;
  price?: number;
  category?: string;
  image_url?: string;
  stock_quantity?: number;
  images?: string[];
}

export interface ProductQueryOptions {
  page?: number;
  limit?: number;
  search?: string;
  category?: string;
  min_price?: number;
  max_price?: number;
  is_active?: boolean;
  sort_by?: 'name' | 'price' | 'created_at';
  sort_order?: 'asc' | 'desc';
}

export class ProductService {
  
  async createProduct(data: CreateProductData) {
    try {
      const { data: product, error } = await supabase
        .from('products')
        .insert({
          name: data.name,
          description: data.description,
          price: data.price,
          category: data.category,
          image_url: data.image_url,
          stock_quantity: data.stock_quantity || 0,
          images: data.images
        })
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      return product;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '创建商品失败');
    }
  }

  async getProducts(options: ProductQueryOptions = {}) {
    try {
      const { 
        page = 1, 
        limit = 10, 
        search, 
        category, 
        min_price, 
        max_price, 
        is_active = true,
        sort_by = 'created_at',
        sort_order = 'desc'
      } = options;
      
      const offset = (page - 1) * limit;

      let query = supabase
        .from('products')
        .select('*')
        .eq('is_active', is_active);

      if (search) {
        query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
      }

      if (category) {
        query = query.eq('category', category);
      }

      if (min_price !== undefined) {
        query = query.gte('price', min_price);
      }

      if (max_price !== undefined) {
        query = query.lte('price', max_price);
      }

      const { data: products, error } = await query
        .range(offset, offset + limit - 1)
        .order(sort_by, { ascending: sort_order === 'asc' });

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      // 获取总数
      let countQuery = supabase
        .from('products')
        .select('id', { count: 'exact' })
        .eq('is_active', is_active);

      if (search) {
        countQuery = countQuery.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
      }

      if (category) {
        countQuery = countQuery.eq('category', category);
      }

      if (min_price !== undefined) {
        countQuery = countQuery.gte('price', min_price);
      }

      if (max_price !== undefined) {
        countQuery = countQuery.lte('price', max_price);
      }

      const { count, error: countError } = await countQuery;

      if (countError) {
        throw ErrorTypes.DATABASE_ERROR(countError.message);
      }

      return {
        data: products || [],
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      };
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取商品列表失败');
    }
  }

  async getProductById(productId: string) {
    try {
      const { data: product, error } = await supabase
        .from('products')
        .select('*')
        .eq('id', productId)
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      if (!product) {
        throw ErrorTypes.NOT_FOUND('商品不存在');
      }

      return product;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取商品详情失败');
    }
  }

  async updateProduct(productId: string, data: UpdateProductData) {
    try {
      const { data: product, error } = await supabase
        .from('products')
        .update(data)
        .eq('id', productId)
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      if (!product) {
        throw ErrorTypes.NOT_FOUND('商品不存在');
      }

      return product;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '更新商品信息失败');
    }
  }

  async deleteProduct(productId: string) {
    try {
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', productId);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      return { success: true };
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '删除商品失败');
    }
  }

  async getCategories() {
    try {
      const { data: categories, error } = await supabase
        .from('products')
        .select('category')
        .eq('is_active', true);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      // 去重并过滤空值
      const uniqueCategories = [...new Set(
        categories
          ?.map(item => item.category)
          .filter(category => category && category.trim() !== '')
      )];

      return uniqueCategories.map(category => ({
        name: category,
        count: categories?.filter(item => item.category === category).length || 0
      }));
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取商品分类失败');
    }
  }

  async updateStock(productId: string, quantity: number, operation: 'increase' | 'decrease') {
    try {
      // 由于数据库中没有 stock_quantity 字段，我们使用 stock_quantity 字段
      const { data: product, error: productError } = await supabase
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();

      if (productError || !product) {
        throw ErrorTypes.NOT_FOUND('商品不存在');
      }

      const currentStock = product.stock_quantity || 0;
      let newStock: number;

      if (operation === 'increase') {
        newStock = currentStock + quantity;
      } else {
        newStock = currentStock - quantity;
        if (newStock < 0) {
          throw ErrorTypes.VALIDATION_ERROR('库存不足');
        }
      }

      // 更新库存
      const { data: updatedProduct, error } = await supabase
        .from('products')
        .update({ stock_quantity: newStock })
        .eq('id', productId)
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      return updatedProduct;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '更新库存失败');
    }
  }

  async checkStock(productId: string, requiredQuantity: number) {
    try {
      const { data: product, error } = await supabase
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();

      if (error || !product) {
        throw ErrorTypes.NOT_FOUND('商品不存在');
      }

      const currentStock = product.stock_quantity || 0;
      const isAvailable = currentStock >= requiredQuantity;

      return {
        available: isAvailable,
        currentStock,
        requiredQuantity
      };
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '检查库存失败');
    }
  }

  async getPopularProducts(limit: number = 10) {
    try {
      // 基于订单项统计热门商品
      const { data: popularProducts, error } = await supabase
        .from('order_items')
        .select(`
          product_id,
          quantity,
          products(*)
        `)
        .not('products', 'is', null);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      // 统计每个商品的销量
      const productSales = new Map<string, { product: any; totalSales: number }>();
      
      popularProducts?.forEach(item => {
        if (item.products) {
          const productId = item.product_id;
          const existing = productSales.get(productId);
          
          if (existing) {
            existing.totalSales += item.quantity;
          } else {
            productSales.set(productId, {
              product: item.products,
              totalSales: item.quantity
            });
          }
        }
      });

      // 排序并返回前N个
      const sortedProducts = Array.from(productSales.values())
        .sort((a, b) => b.totalSales - a.totalSales)
        .slice(0, limit)
        .map(item => ({
          ...item.product,
          total_sales: item.totalSales
        }));

      return sortedProducts;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取热门商品失败');
    }
  }

  async getProductStats() {
    try {
      const [totalProducts, activeProducts, categories, lowStockProducts] = await Promise.all([
        // 总商品数
        supabase
          .from('products')
          .select('id', { count: 'exact' }),
        
        // 上架商品数
        supabase
          .from('products')
          .select('id', { count: 'exact' })
          .eq('is_active', true),
        
        // 分类数
        supabase
          .from('products')
          .select('category')
          .eq('is_active', true),
        
        // 低库存商品数（库存 <= 10）
        supabase
          .from('products')
          .select('stock_quantity', { count: 'exact' })
          .lte('stock_quantity', 10)
      ]);

      const uniqueCategories = new Set(
        categories.data?.map(item => item.category).filter(Boolean)
      );

      // 计算低库存商品数量
      const lowStockCount = lowStockProducts.count || 0;

      const stats = {
        totalProducts: totalProducts.count || 0,
        activeProducts: activeProducts.count || 0,
        totalCategories: uniqueCategories.size,
        lowStockProducts: lowStockCount
      };

      return stats;
    } catch (error) {
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取商品统计失败');
    }
  }
}