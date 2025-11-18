import { apiClient } from '@/utils/api';
import { Order, OrderItem, QueryParams, ApiResponse, Pagination } from '@/types';

export class OrderService {
  // 获取订单列表
  static async getOrders(params?: QueryParams): Promise<{ data: Order[]; pagination: Pagination }> {
    const response = await apiClient.get<ApiResponse<{ data: Order[]; pagination: Pagination }>>('/admin/orders', { params });
    return response.data;
  }

  // 获取订单详情
  static async getOrderById(id: string): Promise<Order> {
    const response = await apiClient.get<ApiResponse<Order>>(`/admin/orders/${id}`);
    return response.data;
  }

  // 更新订单状态
  static async updateOrderStatus(id: string, status: string, notes?: string): Promise<void> {
    await apiClient.put(`/admin/orders/${id}/status`, { status, notes });
  }

  // 批量更新订单状态
  static async batchUpdateOrderStatus(orderIds: string[], status: string): Promise<void> {
    await apiClient.post('/admin/orders/batch-status', { order_ids: orderIds, status });
  }

  // 获取订单统计
  static async getOrderStats(): Promise<{
    totalOrders: number;
    pendingOrders: number;
    processingOrders: number;
    shippedOrders: number;
    deliveredOrders: number;
    cancelledOrders: number;
    totalRevenue: number;
    averageOrderValue: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/orders/stats');
    return response.data;
  }

  // 获取订单趋势
  static async getOrderTrends(params: {
    start_date: string;
    end_date: string;
    group_by?: 'day' | 'week' | 'month';
  }): Promise<{
    dates: string[];
    orderCounts: number[];
    revenues: number[];
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/orders/trends', { params });
    return response.data;
  }

  // 获取销售分析
  static async getSalesAnalysis(params?: {
    start_date?: string;
    end_date?: string;
    category_id?: number;
  }): Promise<{
    topProducts: Array<{
      product_id: number;
      product_name: string;
      sales_count: number;
      revenue: number;
    }>;
    categoryStats: Array<{
      category_id: number;
      category_name: string;
      sales_count: number;
      revenue: number;
    }>;
    totalRevenue: number;
    totalOrders: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/orders/sales-analysis', { params });
    return response.data;
  }

  // 获取订单状态分布
  static async getOrderStatusDistribution(): Promise<{
    pending: number;
    processing: number;
    shipped: number;
    delivered: number;
    cancelled: number;
    refunded: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/orders/status-distribution');
    return response.data;
  }

  // 处理退款
  static async processRefund(orderId: string, data: {
    refund_amount: number;
    refund_reason: string;
    notes?: string;
  }): Promise<void> {
    await apiClient.post(`/admin/orders/${orderId}/refund`, data);
  }

  // 取消订单
  static async cancelOrder(orderId: string, reason: string): Promise<void> {
    await apiClient.post(`/admin/orders/${orderId}/cancel`, { reason });
  }

  // 添加订单备注
  static async addOrderNote(orderId: string, note: string): Promise<void> {
    await apiClient.post(`/admin/orders/${orderId}/notes`, { note });
  }

  // 获取订单备注
  static async getOrderNotes(orderId: string): Promise<Array<{
    id: number;
    note: string;
    created_by: string;
    created_at: string;
  }>> {
    const response = await apiClient.get<ApiResponse<any[]>>(`/admin/orders/${orderId}/notes`);
    return response.data;
  }

  // 导出订单数据
  static async exportOrders(params?: QueryParams): Promise<Blob> {
    const response = await apiClient.get('/admin/orders/export', {
      params,
      responseType: 'blob',
    });
    return response.data;
  }

  // 获取物流信息
  static async getShippingInfo(orderId: string): Promise<{
    tracking_number: string;
    shipping_company: string;
    shipping_status: string;
    tracking_info: Array<{
      time: string;
      status: string;
      location: string;
      description: string;
    }>;
  }> {
    const response = await apiClient.get<ApiResponse<any>>(`/admin/orders/${orderId}/shipping`);
    return response.data;
  }

  // 更新物流信息
  static async updateShippingInfo(orderId: string, data: {
    tracking_number: string;
    shipping_company: string;
  }): Promise<void> {
    await apiClient.put(`/admin/orders/${orderId}/shipping`, data);
  }

  // 获取订单支付信息
  static async getPaymentInfo(orderId: string): Promise<{
    payment_method: string;
    payment_status: string;
    payment_time: string;
    transaction_id: string;
    payment_amount: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>(`/admin/orders/${orderId}/payment`);
    return response.data;
  }

  // 获取客户订单历史
  static async getCustomerOrderHistory(customerId: string, params?: QueryParams): Promise<{ data: Order[]; pagination: Pagination }> {
    const response = await apiClient.get<ApiResponse<{ data: Order[]; pagination: Pagination }>>(`/admin/customers/${customerId}/orders`, { params });
    return response.data;
  }
}