import type { Database } from '../types/database';
import { PetType } from '../types/common';

// 基础数据库类型
export type Pet = Database['public']['Tables']['pets']['Row'];
export type CreatePetInput = Database['public']['Tables']['pets']['Insert'];
export type UpdatePetInput = Database['public']['Tables']['pets']['Update'];

// 扩展接口
export interface PetWithDetails extends Pet {
  letters?: { count: number }[];
  video_generations?: { count: number }[];
}

export interface PetFilters {
  type?: string;
  breed?: string;
  age_min?: number;
  age_max?: number;
}

export interface PetStats {
  total_pets: number;
  pets_by_type: Record<string, number>;
  recent_pets: number;
}

/**
 * Pet AI context for personalized interactions
 */
export interface PetAIContext {
  personality: string[];
  memories: string[];
  relationships: Record<string, string>;
  preferences: Record<string, any>;
  behavioral_patterns: string[];
}

/**
 * Pet photo upload data
 */
export interface PetPhotoUpload {
  pet_id: string;
  photo_url: string;
  caption?: string;
  is_primary?: boolean;
}

/**
 * Pet with additional computed fields
 */
export interface PetWithStats extends Pet {
  video_count: number;
  letter_count: number;
  last_interaction: string | null;
}

/**
 * Pet search filters
 */
export interface PetSearchFilters {
  type?: PetType;
  breed?: string;
  memorial_date_from?: string;
  memorial_date_to?: string;
  has_photos?: boolean;
}

// Export all types for use in other modules