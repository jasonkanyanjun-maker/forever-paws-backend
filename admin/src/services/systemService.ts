import { apiClient } from '@/utils/api';
import { ApiResponse } from '@/types';

export class SystemService {
  // 获取系统配置
  static async getSystemConfig(): Promise<{
    site_name: string;
    site_description: string;
    site_logo: string;
    contact_email: string;
    contact_phone: string;
    maintenance_mode: boolean;
    registration_enabled: boolean;
    email_verification_required: boolean;
    max_login_attempts: number;
    session_timeout: number;
    file_upload_max_size: number;
    allowed_file_types: string[];
    smtp_host: string;
    smtp_port: number;
    smtp_username: string;
    smtp_password: string;
    smtp_encryption: string;
    backup_enabled: boolean;
    backup_frequency: string;
    backup_retention_days: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/config');
    return response.data;
  }

  // 更新系统配置
  static async updateSystemConfig(config: any): Promise<void> {
    await apiClient.put('/admin/system/config', config);
  }

  // 获取系统信息
  static async getSystemInfo(): Promise<{
    server_info: {
      os: string;
      node_version: string;
      memory_usage: number;
      cpu_usage: number;
      disk_usage: number;
      uptime: number;
    };
    database_info: {
      type: string;
      version: string;
      size: number;
      tables_count: number;
    };
    application_info: {
      version: string;
      environment: string;
      debug_mode: boolean;
      timezone: string;
    };
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/info');
    return response.data;
  }

  // 获取系统日志
  static async getSystemLogs(params?: {
    level?: string;
    start_date?: string;
    end_date?: string;
    page?: number;
    pageSize?: number;
  }): Promise<{
    data: Array<{
      id: number;
      level: string;
      message: string;
      context: any;
      created_at: string;
    }>;
    pagination: {
      current: number;
      pageSize: number;
      total: number;
    };
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/logs', { params });
    return response.data;
  }

  // 清理系统日志
  static async clearSystemLogs(beforeDate?: string): Promise<void> {
    await apiClient.delete('/admin/system/logs', {
      data: { before_date: beforeDate }
    });
  }

  // 创建数据库备份
  static async createBackup(): Promise<{
    backup_id: string;
    filename: string;
    size: number;
    created_at: string;
  }> {
    const response = await apiClient.post<ApiResponse<any>>('/admin/system/backup');
    return response.data;
  }

  // 获取备份列表
  static async getBackups(): Promise<Array<{
    id: string;
    filename: string;
    size: number;
    created_at: string;
    status: string;
  }>> {
    const response = await apiClient.get<ApiResponse<any[]>>('/admin/system/backups');
    return response.data;
  }

  // 下载备份文件
  static async downloadBackup(backupId: string): Promise<Blob> {
    const response = await apiClient.get(`/admin/system/backups/${backupId}/download`, {
      responseType: 'blob',
    });
    return response.data;
  }

  // 删除备份文件
  static async deleteBackup(backupId: string): Promise<void> {
    await apiClient.delete(`/admin/system/backups/${backupId}`);
  }

  // 恢复数据库
  static async restoreBackup(backupId: string): Promise<void> {
    await apiClient.post(`/admin/system/backups/${backupId}/restore`);
  }

  // 测试邮件配置
  static async testEmailConfig(config: {
    smtp_host: string;
    smtp_port: number;
    smtp_username: string;
    smtp_password: string;
    smtp_encryption: string;
    test_email: string;
  }): Promise<void> {
    await apiClient.post('/admin/system/test-email', config);
  }

  // 获取缓存统计
  static async getCacheStats(): Promise<{
    total_keys: number;
    memory_usage: number;
    hit_rate: number;
    miss_rate: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/cache/stats');
    return response.data;
  }

  // 清理缓存
  static async clearCache(type?: string): Promise<void> {
    await apiClient.delete('/admin/system/cache', { data: { type } });
  }

  // 获取队列状态
  static async getQueueStatus(): Promise<{
    queues: Array<{
      name: string;
      waiting: number;
      active: number;
      completed: number;
      failed: number;
    }>;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/queue/status');
    return response.data;
  }

  // 重启队列
  static async restartQueue(queueName: string): Promise<void> {
    await apiClient.post(`/admin/system/queue/${queueName}/restart`);
  }

  // 获取安全设置
  static async getSecuritySettings(): Promise<{
    password_min_length: number;
    password_require_uppercase: boolean;
    password_require_lowercase: boolean;
    password_require_numbers: boolean;
    password_require_symbols: boolean;
    two_factor_enabled: boolean;
    ip_whitelist: string[];
    rate_limit_enabled: boolean;
    rate_limit_requests: number;
    rate_limit_window: number;
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/security');
    return response.data;
  }

  // 更新安全设置
  static async updateSecuritySettings(settings: any): Promise<void> {
    await apiClient.put('/admin/system/security', settings);
  }

  // 获取API限制设置
  static async getApiLimits(): Promise<{
    global_rate_limit: number;
    user_rate_limit: number;
    api_key_required: boolean;
    cors_enabled: boolean;
    cors_origins: string[];
  }> {
    const response = await apiClient.get<ApiResponse<any>>('/admin/system/api-limits');
    return response.data;
  }

  // 更新API限制设置
  static async updateApiLimits(limits: any): Promise<void> {
    await apiClient.put('/admin/system/api-limits', limits);
  }

  // 上传系统Logo
  static async uploadLogo(file: File): Promise<{ url: string }> {
    const formData = new FormData();
    formData.append('logo', file);
    const response = await apiClient.post<ApiResponse<{ url: string }>>('/admin/system/upload-logo', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  }
}