import { apiClient } from '@/utils/api';
import { DashboardStats, ApiResponse } from '@/types';

export class DashboardService {
  // 获取仪表板统计数据
  static async getDashboardStats(): Promise<DashboardStats> {
    try {
      const response = await apiClient.get<ApiResponse<DashboardStats>>('/admin/dashboard/stats');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取统计数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取统计数据失败');
    }
  }

  // 获取最近活动日志
  static async getRecentActivities(limit: number = 10): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/dashboard/activities', {
        limit,
      });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取活动日志失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取活动日志失败');
    }
  }

  // 获取API调用趋势数据
  static async getApiTrends(days: number = 7): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/dashboard/api-trends', {
        days,
      });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取API趋势数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取API趋势数据失败');
    }
  }

  // 获取销售趋势数据
  static async getSalesTrends(days: number = 30): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/dashboard/sales-trends', {
        days,
      });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取销售趋势数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取销售趋势数据失败');
    }
  }

  // 获取热门商品数据
  static async getTopProducts(limit: number = 5): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/dashboard/top-products', {
        limit,
      });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取热门商品数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取热门商品数据失败');
    }
  }
}