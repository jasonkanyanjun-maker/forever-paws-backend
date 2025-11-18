import { apiClient } from '@/utils/api';
import { ApiCallLog, ApiStats, UserApiLimit, ApiResponse, Pagination, QueryParams } from '@/types';

export class ApiMonitorService {
  // 获取API调用日志列表
  static async getApiCallLogs(params: QueryParams): Promise<{ data: ApiCallLog[]; pagination: Pagination }> {
    try {
      const response = await apiClient.get<ApiResponse<{ data: ApiCallLog[]; pagination: Pagination }>>('/admin/api-monitor/logs', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取API调用日志失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取API调用日志失败');
    }
  }

  // 获取API统计数据
  static async getApiStats(startDate?: string, endDate?: string): Promise<ApiStats> {
    try {
      const params: any = {};
      if (startDate) params.startDate = startDate;
      if (endDate) params.endDate = endDate;

      const response = await apiClient.get<ApiResponse<ApiStats>>('/admin/api-monitor/stats', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取API统计数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取API统计数据失败');
    }
  }

  // 获取用户API限额列表
  static async getUserApiLimits(params: QueryParams): Promise<{ data: UserApiLimit[]; pagination: Pagination }> {
    try {
      const response = await apiClient.get<ApiResponse<{ data: UserApiLimit[]; pagination: Pagination }>>('/admin/api-monitor/user-limits', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取用户API限额失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取用户API限额失败');
    }
  }

  // 更新用户API限额
  static async updateUserApiLimit(userId: string, limitData: Partial<UserApiLimit>): Promise<UserApiLimit> {
    try {
      const response = await apiClient.put<ApiResponse<UserApiLimit>>(`/admin/api-monitor/user-limits/${userId}`, limitData);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '更新用户API限额失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '更新用户API限额失败');
    }
  }

  // 重置用户API使用量
  static async resetUserApiUsage(userId: string, apiType?: string): Promise<void> {
    try {
      const params: any = {};
      if (apiType) params.apiType = apiType;

      const response = await apiClient.post<ApiResponse<void>>(`/admin/api-monitor/user-limits/${userId}/reset`, params);
      
      if (!response.success) {
        throw new Error(response.message || '重置用户API使用量失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '重置用户API使用量失败');
    }
  }

  // 获取API调用趋势数据
  static async getApiTrends(days: number = 30, apiType?: string): Promise<any[]> {
    try {
      const params: any = { days };
      if (apiType) params.apiType = apiType;

      const response = await apiClient.get<ApiResponse<any[]>>('/admin/api-monitor/trends', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取API趋势数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取API趋势数据失败');
    }
  }

  // 获取成本分析数据
  static async getCostAnalysis(startDate?: string, endDate?: string): Promise<any> {
    try {
      const params: any = {};
      if (startDate) params.startDate = startDate;
      if (endDate) params.endDate = endDate;

      const response = await apiClient.get<ApiResponse<any>>('/admin/api-monitor/cost-analysis', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取成本分析数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取成本分析数据失败');
    }
  }

  // 导出API调用日志
  static async exportApiLogs(params: QueryParams): Promise<Blob> {
    try {
      const response = await apiClient.get('/admin/api-monitor/logs/export', params, {
        responseType: 'blob',
      });
      
      return response;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '导出API调用日志失败');
    }
  }

  // 获取实时API监控数据
  static async getRealTimeStats(): Promise<any> {
    try {
      const response = await apiClient.get<ApiResponse<any>>('/admin/api-monitor/realtime');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取实时监控数据失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取实时监控数据失败');
    }
  }

  // 获取API错误统计
  static async getErrorStats(days: number = 7): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/api-monitor/errors', { days });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取API错误统计失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取API错误统计失败');
    }
  }
}