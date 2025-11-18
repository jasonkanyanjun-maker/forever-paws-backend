import axios, { AxiosInstance, AxiosResponse, AxiosError, InternalAxiosRequestConfig } from 'axios';
import { message } from 'antd';

// 扩展 AxiosRequestConfig 类型以包含 metadata
declare module 'axios' {
  interface InternalAxiosRequestConfig {
    metadata?: {
      startTime: Date;
    };
  }
}

// API基础配置
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api';

// 创建axios实例
const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    // 添加认证token
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // 添加请求时间戳
    config.metadata = { startTime: new Date() };
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
api.interceptors.response.use(
  (response: AxiosResponse) => {
    // 计算请求耗时
    const endTime = new Date();
    const startTime = response.config.metadata?.startTime;
    if (startTime) {
      const duration = endTime.getTime() - startTime.getTime();
      console.log(`API请求耗时: ${duration}ms - ${response.config.method?.toUpperCase()} ${response.config.url}`);
    }
    
    return response;
  },
  (error: AxiosError) => {
    // 统一错误处理
    if (error.response) {
      const { status, data } = error.response;
      
      switch (status) {
        case 401:
          // 未授权，清除token并跳转到登录页
          localStorage.removeItem('admin_token');
          window.location.href = '/login';
          message.error('登录已过期，请重新登录');
          break;
        case 403:
          message.error('权限不足，无法访问该资源');
          break;
        case 404:
          message.error('请求的资源不存在');
          break;
        case 429:
          message.error('请求过于频繁，请稍后再试');
          break;
        case 500:
          message.error('服务器内部错误，请稍后再试');
          break;
        default:
          const errorMessage = (data as any)?.error || (data as any)?.message || '请求失败';
          message.error(errorMessage);
      }
    } else if (error.request) {
      // 网络错误
      message.error('网络连接失败，请检查网络设置');
    } else {
      // 其他错误
      message.error('请求配置错误');
    }
    
    return Promise.reject(error);
  }
);

// API方法封装
export const apiClient = {
  // GET请求
  get: <T = any>(url: string, params?: any, config?: any): Promise<T> => {
    return api.get(url, { params, ...config }).then(response => response.data);
  },
  
  // POST请求
  post: <T = any>(url: string, data?: any, config?: any): Promise<T> => {
    return api.post(url, data, config).then(response => response.data);
  },
  
  // PUT请求
  put: <T = any>(url: string, data?: any, config?: any): Promise<T> => {
    return api.put(url, data, config).then(response => response.data);
  },
  
  // DELETE请求
  delete: <T = any>(url: string, config?: any): Promise<T> => {
    return api.delete(url, config).then(response => response.data);
  },
  
  // PATCH请求
  patch: <T = any>(url: string, data?: any, config?: any): Promise<T> => {
    return api.patch(url, data, config).then(response => response.data);
  },
};

// 文件上传
export const uploadFile = async (file: File, onProgress?: (progress: number) => void): Promise<string> => {
  const formData = new FormData();
  formData.append('file', file);
  
  try {
    const response = await api.post('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onProgress) {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(progress);
        }
      },
    });
    
    return response.data.url;
  } catch (error) {
    throw new Error('文件上传失败');
  }
};

// 导出CSV文件
export const downloadCSV = async (url: string, filename: string, params?: any): Promise<void> => {
  try {
    const response = await api.get(url, {
      params,
      responseType: 'blob',
    });
    
    const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8' });
    const downloadUrl = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = downloadUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(downloadUrl);
    
    message.success('文件下载成功');
  } catch (error) {
    message.error('文件下载失败');
    throw error;
  }
};

// 检查网络连接状态
export const checkNetworkStatus = (): boolean => {
  return navigator.onLine;
};

// 重试机制
export const retryRequest = async <T>(
  requestFn: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> => {
  let lastError: Error;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await requestFn();
    } catch (error) {
      lastError = error as Error;
      
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay * Math.pow(2, i)));
      }
    }
  }
  
  throw lastError!;
};

export default api;