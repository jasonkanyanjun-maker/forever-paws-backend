// 管理员相关类型
export interface Admin {
  id: string;
  username: string;
  email: string;
  role: 'super_admin' | 'admin' | 'moderator';
  isActive: boolean;
  lastLoginAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AdminLoginRequest {
  username: string;
  password: string;
}

export interface AdminLoginResponse {
  success: boolean;
  token: string;
  admin: Admin;
}

// 用户相关类型
export interface User {
  id: string;
  email: string;
  username?: string;
  isActive: boolean;
  status?: string;
  createdAt: string;
  created_at?: string;
  updatedAt: string;
  lastLoginAt?: string;
  last_login_at?: string;
  membership_level?: string;
  total_spent?: number;
  conversation_used?: number;
  video_used?: number;
  balance?: number;
  avatar_url?: string;
  phone?: string;
  apiUsage?: {
    totalCalls: number;
    totalCost: number;
    monthlyUsage: number;
  };
}

// API监控相关类型
export interface ApiCallLog {
  id: string;
  userId: string;
  apiType: 'conversation' | 'video_generation';
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number;
  inputTokens?: number;
  outputTokens?: number;
  cost: number;
  createdAt: string;
  metadata?: Record<string, any>;
}

export interface ApiStats {
  totalCalls?: number;
  totalApiCalls: number;
  totalApiCost: number;
  totalCost?: number;
  averageResponseTime: number;
  successRate?: number;
  apiCallsToday: number;
  conversationCalls?: number;
  videoCalls?: number;
  dailyStats?: Array<{
    date: string;
    calls: number;
    cost: number;
    averageResponseTime: number;
  }>;
}

export interface UserApiLimit {
  id: string;
  userId: string;
  user_id?: string;
  apiType: 'conversation' | 'video_generation';
  dailyLimit: number;
  monthlyLimit: number;
  dailyUsed: number;
  monthlyUsed: number;
  resetDate: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  video_used?: number;
  video_limit?: number;
  conversation_used?: number;
  conversation_limit?: number;
}

// 商品相关类型
export interface Product {
  id: string;
  name: string;
  description?: string;
  price: number;
  category: string;
  category_id?: string;
  imageUrl?: string;
  image_url?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  created_at?: string;
  stock_quantity?: number;
  sales_count?: number;
  sku?: string;
  category_name?: string;
  status?: string;
  inventory?: Inventory;
  salesStats?: {
    totalSold: number;
    totalRevenue: number;
    orderCount: number;
  };
}

export interface Inventory {
  id: string;
  productId: string;
  product_id?: string;
  stockQuantity: number;
  stock_quantity?: number;
  reservedQuantity: number;
  lowStockThreshold: number;
  createdAt: string;
  updatedAt: string;
  product_name?: string;
  max_stock_level?: number;
  min_stock_level?: number;
  sku?: string;
  unit_price?: number;
}

// 订单相关类型
export interface Order {
  id: string;
  userId: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  totalAmount: number;
  total_amount?: number;
  createdAt: string;
  updatedAt: string;
  created_at?: string;
  shippingAddress?: Record<string, any>;
  shipping_address?: string;
  paymentMethod?: string;
  paymentStatus?: 'pending' | 'paid' | 'failed' | 'refunded';
  payment_status?: string;
  trackingNumber?: string;
  notes?: string;
  items?: OrderItem[];
  order_number?: string;
  customer_name?: string;
  customer_email?: string;
}

export interface OrderItem {
  id: string;
  orderId: string;
  productId: string;
  quantity: number;
  unitPrice: number;
  createdAt: string;
  products?: Product;
}

// 仪表板统计类型
export interface DashboardStats {
  totalRevenue?: number;
  totalApiCalls?: number;
  totalUsers?: number;
  totalOrders?: number;
  userStats: {
    totalUsers: number;
    activeUsers: number;
    newUsersToday: number;
    userGrowthRate: number;
  };
  orderStats: {
    totalOrders: number;
    pendingOrders: number;
    completedOrders: number;
    totalRevenue: number;
    revenueGrowthRate: number;
  };
  productStats: {
    totalProducts: number;
    activeProducts: number;
    lowStockProducts: number;
  };
  apiStats: {
    totalApiCalls: number;
    totalApiCost: number;
    averageResponseTime: number;
    apiCallsToday: number;
    conversationCalls?: number;
    videoCalls?: number;
    totalCost?: number;
  };
}

// 通用分页类型
export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: Pagination;
}

// 通用API响应类型
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

// 操作日志类型
export interface AdminLog {
  id: string;
  adminId: string;
  action: string;
  targetType?: string;
  targetId?: string;
  details?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: string;
}

// 表单相关类型
export interface LoginFormData {
  username: string;
  password: string;
}

export interface ProductFormData {
  name: string;
  description?: string;
  price: number;
  category: string;
  imageUrl?: string;
  isActive: boolean;
  stockQuantity: number;
  lowStockThreshold: number;
}

export interface UserLimitFormData {
  userId: string;
  apiType: 'conversation' | 'video_generation';
  dailyLimit: number;
  monthlyLimit: number;
  isActive: boolean;
}

// 筛选和排序类型
export interface FilterOptions {
  search?: string;
  status?: string;
  category?: string;
  dateFrom?: string;
  dateTo?: string;
  isActive?: boolean;
}

export interface SortOptions {
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface QueryParams extends FilterOptions, SortOptions {
  page?: number;
  limit?: number;
  pageSize?: number;
  startDate?: string;
  endDate?: string;
  paymentStatus?: string;
  stockStatus?: string;
}