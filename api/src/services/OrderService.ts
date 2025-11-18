import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';
import { ProductService } from './ProductService';
import { PaginatedResponse } from '../types/common';
import type { Database } from '../types/database';

type Order = Database['public']['Tables']['orders']['Row'];
type OrderStatus = Database['public']['Tables']['orders']['Row']['status'];

export interface CreateOrderData {
  items: Array<{
    product_id: string;
    quantity: number;
    price?: number;
  }>;
  shipping_address?: string;
  notes?: string;
}

export interface UpdateOrderData {
  status?: OrderStatus;
  shipping_address?: string;
  notes?: string;
  tracking_number?: string;
}

export interface OrderQueryOptions {
  page?: number;
  limit?: number;
  status?: OrderStatus;
  startDate?: string;
  endDate?: string;
  sort_by?: 'created_at' | 'total_amount' | 'status';
  sort_order?: 'asc' | 'desc';
}

export class OrderService {
  private productService = new ProductService();

  // 创建订单
  async createOrder(userId: string, data: CreateOrderData) {
    try {
      // 验证商品库存
      for (const item of data.items) {
        const isAvailable = await this.productService.checkStock(item.product_id, item.quantity);
        if (!isAvailable) {
          throw ErrorTypes.VALIDATION_ERROR(`商品 ${item.product_id} 库存不足`);
        }
      }

      // 计算订单总金额
      let totalAmount = 0;
      const orderItems = [];

      for (const item of data.items) {
        const { data: product, error } = await supabase
          .from('products')
          .select('price')
          .eq('id', item.product_id)
          .single();

        if (error || !product) {
          throw ErrorTypes.VALIDATION_ERROR(`商品 ${item.product_id} 不存在`);
        }

        const itemPrice = item.price || product.price;
        const itemTotal = itemPrice * item.quantity;
        totalAmount += itemTotal;

        orderItems.push({
          product_id: item.product_id,
          quantity: item.quantity,
          price: itemPrice
        });
      }

      // 创建订单
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
          user_id: userId,
          total_amount: totalAmount,
          status: 'pending'
        })
        .select()
        .single();

      if (orderError) {
        throw ErrorTypes.DATABASE_ERROR(orderError.message);
      }

      // 创建订单项
      const orderItemsWithOrderId = orderItems.map(item => ({
        ...item,
        order_id: order.id
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItemsWithOrderId);

      if (itemsError) {
        // 回滚订单
        await supabase.from('orders').delete().eq('id', order.id);
        throw ErrorTypes.DATABASE_ERROR(itemsError.message);
      }

      // 更新商品库存
      for (const item of orderItems) {
        await this.productService.updateStock(item.product_id, item.quantity, 'decrease');
      }

      return order;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '创建订单失败');
    }
  }

  // 获取用户订单列表
  async getOrdersByUserId(userId: string, options: OrderQueryOptions = {}): Promise<PaginatedResponse<Order>> {
    try {
      const { page = 1, limit = 10, status, startDate, endDate } = options;
      const offset = (page - 1) * limit;

      let baseQuery = supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            quantity,
            price,
            product_id,
            products (
              id,
              name,
              image_url
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (userId) {
        baseQuery = baseQuery.eq('user_id', userId);
      }

      if (status) {
        baseQuery = baseQuery.eq('status', status);
      }

      if (startDate) {
        baseQuery = baseQuery.gte('created_at', startDate);
      }

      if (endDate) {
        baseQuery = baseQuery.lte('created_at', endDate);
      }

      const { data: orders, error, count } = await baseQuery
        .range(offset, offset + limit - 1);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      return {
        data: orders || [],
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
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '获取订单列表失败');
    }
  }

  // 更新订单状态
  async updateOrderStatus(orderId: string, status: OrderStatus, userId?: string): Promise<Order> {
    try {
      const { data: order, error } = await supabase
        .from('orders')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', orderId)
        .select()
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          throw ErrorTypes.NOT_FOUND('订单不存在');
        }
        throw ErrorTypes.DATABASE_ERROR(error.message);
      }

      return order;
    } catch (error) {
      if (error instanceof Error && error.name === 'AppError') {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR(error instanceof Error ? error.message : '更新订单状态失败');
    }
  }
}