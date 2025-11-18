import { apiClient } from '@/utils/api';
import { AdminLoginRequest, AdminLoginResponse, Admin, ApiResponse } from '@/types';

export class AuthService {
  // 管理员登录
  static async login(credentials: AdminLoginRequest): Promise<AdminLoginResponse> {
    try {
      const response = await apiClient.post<ApiResponse<AdminLoginResponse>>('/admin/login', credentials);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '登录失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '登录失败');
    }
  }

  // 获取当前管理员信息
  static async getCurrentAdmin(): Promise<Admin> {
    try {
      const response = await apiClient.get<ApiResponse<Admin>>('/admin/profile');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取用户信息失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取用户信息失败');
    }
  }

  // 修改密码
  static async changePassword(oldPassword: string, newPassword: string): Promise<void> {
    try {
      const response = await apiClient.put<ApiResponse>('/admin/change-password', {
        oldPassword,
        newPassword,
      });
      
      if (!response.success) {
        throw new Error(response.message || '修改密码失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '修改密码失败');
    }
  }

  // 登出
  static async logout(): Promise<void> {
    try {
      await apiClient.post('/admin/logout');
    } catch (error) {
      // 即使登出接口失败，也要清除本地存储
      console.warn('登出接口调用失败，但会继续清除本地存储');
    }
  }

  // 验证token有效性
  static async validateToken(): Promise<boolean> {
    try {
      const response = await apiClient.get<ApiResponse>('/admin/validate-token');
      return response.success;
    } catch (error) {
      return false;
    }
  }

  // 刷新token
  static async refreshToken(): Promise<string> {
    try {
      const response = await apiClient.post<ApiResponse<{ token: string }>>('/admin/refresh-token');
      
      if (response.success && response.data) {
        return response.data.token;
      } else {
        throw new Error(response.message || '刷新token失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '刷新token失败');
    }
  }
}