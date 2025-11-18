import { apiClient } from '@/utils/api';
import { User, ApiResponse, Pagination, QueryParams } from '@/types';

export class UserService {
  // 获取用户列表
  static async getUsers(params: QueryParams): Promise<{ data: User[]; pagination: Pagination }> {
    try {
      const response = await apiClient.get<ApiResponse<{ data: User[]; pagination: Pagination }>>('/admin/users', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取用户列表失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取用户列表失败');
    }
  }

  // 获取用户详情
  static async getUserById(id: string): Promise<User> {
    try {
      const response = await apiClient.get<ApiResponse<User>>(`/admin/users/${id}`);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取用户详情失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取用户详情失败');
    }
  }

  // 更新用户信息
  static async updateUser(id: string, userData: Partial<User>): Promise<User> {
    try {
      const response = await apiClient.put<ApiResponse<User>>(`/admin/users/${id}`, userData);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '更新用户信息失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '更新用户信息失败');
    }
  }

  // 禁用/启用用户
  static async toggleUserStatus(id: string, status: 'active' | 'inactive'): Promise<void> {
    try {
      const response = await apiClient.patch<ApiResponse<void>>(`/admin/users/${id}/status`, { status });
      
      if (!response.success) {
        throw new Error(response.message || '更新用户状态失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '更新用户状态失败');
    }
  }

  // 删除用户
  static async deleteUser(id: string): Promise<void> {
    try {
      const response = await apiClient.delete<ApiResponse<void>>(`/admin/users/${id}`);
      
      if (!response.success) {
        throw new Error(response.message || '删除用户失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '删除用户失败');
    }
  }

  // 重置用户密码
  static async resetUserPassword(id: string): Promise<{ newPassword: string }> {
    try {
      const response = await apiClient.post<ApiResponse<{ newPassword: string }>>(`/admin/users/${id}/reset-password`);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '重置密码失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '重置密码失败');
    }
  }

  // 获取用户统计信息
  static async getUserStats(): Promise<any> {
    try {
      const response = await apiClient.get<ApiResponse<any>>('/admin/users/stats');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取用户统计失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取用户统计失败');
    }
  }

  // 导出用户数据
  static async exportUsers(params: QueryParams): Promise<Blob> {
    try {
      const response = await apiClient.get('/admin/users/export', params, {
        responseType: 'blob',
      });
      
      return response;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '导出用户数据失败');
    }
  }
}