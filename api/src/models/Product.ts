/**
 * Product model interface matching the database schema
 */
export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  currency: string;
  category: ProductCategory;
  images: string[];
  metadata: ProductMetadata;
  is_active: boolean;
  stock_quantity?: number;
  created_at: string;
  updated_at: string;
}

/**
 * Product category enum
 */
export enum ProductCategory {
  MEMORIAL_ITEMS = 'memorial_items',
  PET_ACCESSORIES = 'pet_accessories',
  DIGITAL_SERVICES = 'digital_services',
  CUSTOM_PRODUCTS = 'custom_products'
}

/**
 * Product metadata interface
 */
export interface ProductMetadata {
  dimensions?: {
    length: number;
    width: number;
    height: number;
    weight: number;
  };
  materials?: string[];
  customization_options?: {
    text_engraving: boolean;
    photo_printing: boolean;
    color_options: string[];
    size_options: string[];
  };
  shipping_info?: {
    free_shipping: boolean;
    estimated_delivery_days: number;
    shipping_restrictions: string[];
  };
  tags?: string[];
}

/**
 * Product creation input
 */
export interface CreateProductInput {
  name: string;
  description: string;
  price: number;
  currency?: string;
  category: ProductCategory;
  images?: string[];
  metadata?: Partial<ProductMetadata>;
  stock_quantity?: number;
}

/**
 * Product update input
 */
export interface UpdateProductInput {
  name?: string;
  description?: string;
  price?: number;
  currency?: string;
  category?: ProductCategory;
  images?: string[];
  metadata?: Partial<ProductMetadata>;
  is_active?: boolean;
  stock_quantity?: number;
}

/**
 * Product with additional computed fields
 */
export interface ProductWithStats extends Product {
  order_count: number;
  revenue: number;
  average_rating: number;
  review_count: number;
}

/**
 * Product search filters
 */
export interface ProductFilters {
  category?: ProductCategory;
  price_min?: number;
  price_max?: number;
  in_stock?: boolean;
  is_active?: boolean;
  search_term?: string;
  tags?: string[];
}

/**
 * Product review model
 */
export interface ProductReview {
  id: string;
  product_id: string;
  user_id: string;
  rating: number;
  comment?: string;
  images?: string[];
  is_verified_purchase: boolean;
  created_at: string;
  updated_at: string;
}

/**
 * Product review creation input
 */
export interface CreateProductReviewInput {
  product_id: string;
  rating: number;
  comment?: string;
  images?: string[];
}

/**
 * Product review with user details
 */
export interface ProductReviewWithUser extends ProductReview {
  user: {
    id: string;
    display_name?: string;
    avatar_url?: string;
  };
}

// Export all types for use in other modules