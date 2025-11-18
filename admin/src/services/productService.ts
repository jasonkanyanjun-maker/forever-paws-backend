import { apiClient } from '@/utils/api';
import { Product, ProductFormData, ApiResponse, Pagination, QueryParams } from '@/types';

export class ProductService {
  // 获取商品列表
  static async getProducts(params: QueryParams): Promise<{ data: Product[]; pagination: Pagination }> {
    try {
      const response = await apiClient.get<ApiResponse<{ data: Product[]; pagination: Pagination }>>('/admin/products', params);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取商品列表失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取商品列表失败');
    }
  }

  // 获取商品详情
  static async getProductById(id: string): Promise<Product> {
    try {
      const response = await apiClient.get<ApiResponse<Product>>(`/admin/products/${id}`);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取商品详情失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取商品详情失败');
    }
  }

  // 创建商品
  static async createProduct(productData: ProductFormData): Promise<Product> {
    try {
      const response = await apiClient.post<ApiResponse<Product>>('/admin/products', productData);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '创建商品失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '创建商品失败');
    }
  }

  // 更新商品
  static async updateProduct(id: string, productData: Partial<ProductFormData>): Promise<Product> {
    try {
      const response = await apiClient.put<ApiResponse<Product>>(`/admin/products/${id}`, productData);
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '更新商品失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '更新商品失败');
    }
  }

  // 删除商品
  static async deleteProduct(id: string): Promise<void> {
    try {
      const response = await apiClient.delete<ApiResponse<void>>(`/admin/products/${id}`);
      
      if (!response.success) {
        throw new Error(response.message || '删除商品失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '删除商品失败');
    }
  }

  // 批量删除商品
  static async batchDeleteProducts(ids: string[]): Promise<void> {
    try {
      const response = await apiClient.post<ApiResponse<void>>('/admin/products/batch-delete', { ids });
      
      if (!response.success) {
        throw new Error(response.message || '批量删除商品失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '批量删除商品失败');
    }
  }

  // 更新商品状态
  static async updateProductStatus(id: string, status: 'active' | 'inactive'): Promise<void> {
    try {
      const response = await apiClient.patch<ApiResponse<void>>(`/admin/products/${id}/status`, { status });
      
      if (!response.success) {
        throw new Error(response.message || '更新商品状态失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '更新商品状态失败');
    }
  }

  // 获取商品分类
  static async getCategories(): Promise<any[]> {
    try {
      const response = await apiClient.get<ApiResponse<any[]>>('/admin/products/categories');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取商品分类失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取商品分类失败');
    }
  }

  // 上传商品图片
  static async uploadProductImage(file: File): Promise<{ url: string }> {
    try {
      const formData = new FormData();
      formData.append('image', file);
      
      const response = await apiClient.post<ApiResponse<{ url: string }>>('/admin/products/upload-image', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '上传图片失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '上传图片失败');
    }
  }

  // 获取商品统计
  static async getProductStats(): Promise<any> {
    try {
      const response = await apiClient.get<ApiResponse<any>>('/admin/products/stats');
      
      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.message || '获取商品统计失败');
      }
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '获取商品统计失败');
    }
  }

  // 导出商品数据
  static async exportProducts(params: QueryParams): Promise<Blob> {
    try {
      const response = await apiClient.get('/admin/products/export', params, {
        responseType: 'blob',
      });
      
      return response;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || error.message || '导出商品数据失败');
    }
  }
}