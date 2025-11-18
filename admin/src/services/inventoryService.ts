import { apiClient } from '@/utils/api';
import { Inventory, QueryParams, ApiResponse, Pagination } from '@/types';

export class InventoryService {
  // 获取库存列表
  static async getInventory(params?: QueryParams): Promise<{ data: Inventory[]; pagination: Pagination }> {
    const response = await apiClient.get<ApiResponse<{ data: Inventory[]; pagination: Pagination }>>('/admin/inventory', { params });
    return response.data;
  }

  // 获取库存详情
  static async getInventoryById(id: number): Promise<Inventory> {
    const response = await apiClient.get<ApiResponse<Inventory>>(`/admin/inventory/${id}`);
    return response.data;
  }

  // 更新库存
  static async updateInventory(id: number, data: { stock_quantity: number; min_stock_level?: number; max_stock_level?: number }): Promise<void> {
    await apiClient.put(`/admin/inventory/${id}`, data);
  }

  // 批量更新库存
  static async batchUpdateInventory(updates: { id: number; stock_quantity: number }[]): Promise<void> {
    await apiClient.post('/admin/inventory/batch-update', { updates });
  }

  // 获取库存统计
  static async getInventoryStats(): Promise<{
    totalProducts: number;
    lowStockProducts: number;
    outOfStockProducts: number;
    totalStockValue: number;
    averageStockLevel: number;
    stockTurnoverRate: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/inventory/stats');
    return response.data;
  }

  // 获取库存变动记录
  static async getInventoryLogs(params?: QueryParams): Promise<{ data: any[]; pagination: Pagination }> {
    const response = await apiClient.get<ApiResponse<{ data: any[]; pagination: Pagination }>>('/admin/inventory/logs', { params });
    return response.data;
  }

  // 获取库存预警
  static async getInventoryAlerts(): Promise<{
    lowStockAlerts: any[];
    outOfStockAlerts: any[];
    overStockAlerts: any[];
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/inventory/alerts');
    return response.data;
  }

  // 库存盘点
  static async performStockTaking(data: { product_id: number; actual_quantity: number; notes?: string }[]): Promise<void> {
    await apiClient.post('/admin/inventory/stock-taking', { items: data });
  }

  // 库存调整
  static async adjustStock(productId: string, data: {
    adjustment_type: 'increase' | 'decrease';
    quantity: number;
    reason: string;
    notes?: string;
  }): Promise<void> {
    await apiClient.post(`/admin/inventory/${productId}/adjust`, data);
  }

  // 设置库存预警阈值
  static async setStockThreshold(productId: string, data: {
    min_stock_level: number;
    max_stock_level?: number;
  }): Promise<void> {
    await apiClient.put(`/admin/inventory/${productId}/threshold`, data);
  }

  // 导出库存数据
  static async exportInventory(params?: QueryParams): Promise<Blob> {
    const response = await apiClient.get('/admin/inventory/export', {
      params,
      responseType: 'blob',
    });
    return response.data;
  }

  // 获取库存趋势
  static async getInventoryTrends(params: {
    product_id?: number;
    start_date: string;
    end_date: string;
  }): Promise<{
    dates: string[];
    stockLevels: number[];
    stockChanges: number[];
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/inventory/trends', { params });
    return response.data;
  }

  // 获取库存周转分析
  static async getInventoryTurnoverAnalysis(params?: {
    category_id?: number;
    start_date?: string;
    end_date?: string;
  }): Promise<{
    products: Array<{
      product_id: number;
      product_name: string;
      turnover_rate: number;
      days_in_stock: number;
      stock_value: number;
    }>;
    averageTurnoverRate: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/inventory/turnover-analysis', { params });
    return response.data;
  }
}