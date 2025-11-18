import { OrderStatus } from '../types/common';

/**
 * Order model interface matching the database schema
 */
export interface Order {
  id: string;
  user_id: string;
  status: OrderStatus;
  total_amount: number;
  currency: string;
  shipping_address: ShippingAddress;
  billing_address?: ShippingAddress;
  payment_method: PaymentMethod;
  metadata: OrderMetadata;
  created_at: string;
  updated_at: string;
}

/**
 * Order item model interface
 */
export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  customization?: Record<string, any>;
  created_at: string;
}

/**
 * Shipping address interface
 */
export interface ShippingAddress {
  recipient_name: string;
  phone: string;
  address_line1: string;
  address_line2?: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
}

/**
 * Payment method interface
 */
export interface PaymentMethod {
  type: 'credit_card' | 'debit_card' | 'paypal' | 'apple_pay' | 'google_pay';
  last_four?: string;
  brand?: string;
  expires_at?: string;
}

/**
 * Order metadata interface
 */
export interface OrderMetadata {
  payment_intent_id?: string;
  tracking_number?: string;
  estimated_delivery?: string;
  actual_delivery?: string;
  notes?: string;
  discount_code?: string;
  discount_amount?: number;
  tax_amount?: number;
  shipping_cost?: number;
}

/**
 * Order creation input
 */
export interface CreateOrderInput {
  items: Array<{
    product_id: string;
    quantity: number;
    customization?: Record<string, any>;
  }>;
  shipping_address: ShippingAddress;
  billing_address?: ShippingAddress;
  payment_method: PaymentMethod;
  discount_code?: string;
  notes?: string;
}

/**
 * Order update input
 */
export interface UpdateOrderInput {
  status?: OrderStatus;
  shipping_address?: ShippingAddress;
  billing_address?: ShippingAddress;
  metadata?: Partial<OrderMetadata>;
}

/**
 * Order with items and product details
 */
export interface OrderWithDetails extends Order {
  items: Array<OrderItem & {
    product: {
      id: string;
      name: string;
      images: string[];
      category: string;
    };
  }>;
  user: {
    id: string;
    display_name?: string;
    email: string;
  };
}

/**
 * Order summary for listing
 */
export interface OrderSummary {
  id: string;
  status: OrderStatus;
  total_amount: number;
  currency: string;
  item_count: number;
  created_at: string;
  estimated_delivery?: string;
}

/**
 * Order search filters
 */
export interface OrderFilters {
  status?: OrderStatus;
  date_from?: string;
  date_to?: string;
  amount_min?: number;
  amount_max?: number;
  payment_method?: string;
  has_tracking?: boolean;
}

/**
 * Order statistics
 */
export interface OrderStats {
  total_orders: number;
  total_revenue: number;
  average_order_value: number;
  status_distribution: Record<OrderStatus, number>;
  top_products: Array<{
    product_id: string;
    product_name: string;
    quantity_sold: number;
    revenue: number;
  }>;
  monthly_revenue: Array<{
    month: string;
    revenue: number;
    order_count: number;
  }>;
}

/**
 * Payment record model
 */
export interface PaymentRecord {
  id: string;
  order_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  payment_method: PaymentMethod;
  transaction_id?: string;
  failure_reason?: string;
  processed_at?: string;
  created_at: string;
}

// Export all types for use in other modules