import type { Database } from '../types/database';

// 使用数据库类型定义
export type VideoGeneration = Database['public']['Tables']['video_generations']['Row'];
export type CreateVideoGenerationInput = Database['public']['Tables']['video_generations']['Insert'];
export type UpdateVideoGenerationInput = Database['public']['Tables']['video_generations']['Update'];

// 视频生成状态枚举
export type VideoGenerationStatus = VideoGeneration['status'];

// 视频生成元数据类型
export interface VideoGenerationMetadata {
  model?: string;
  parameters?: {
    style?: string;
    duration?: number;
    resolution?: string;
    fps?: number;
  };
  processing_time?: number;
  quality_score?: number;
  error_details?: string;
}

// 扩展类型，包含关联数据
export interface VideoGenerationWithDetails extends VideoGeneration {
  pet?: {
    id: string;
    name: string;
    type: string;
    photos?: string[];
  };
  user?: {
    id: string;
    display_name?: string;
    email: string;
  };
}

// 视频生成请求类型
export interface CreateVideoGenerationRequest {
  pet_id: string;
  prompt: string;
  style?: string;
  duration?: number;
  resolution?: string;
  original_images?: string[];
}

// 视频生成响应类型
export interface VideoGenerationResponse {
  id: string;
  status: VideoGenerationStatus;
  video_url?: string;
  progress?: number;
  error_message?: string;
  metadata: VideoGenerationMetadata;
}

// 视频生成过滤器
export interface VideoGenerationFilters {
  pet_id?: string;
  user_id?: string;
  status?: VideoGenerationStatus;
  date_from?: string;
  date_to?: string;
}

// 视频生成统计
export interface VideoGenerationStats {
  total_generations: number;
  completed_generations: number;
  failed_generations: number;
  average_processing_time: number;
  status_distribution: Record<VideoGenerationStatus, number>;
}

// DashScope API 相关类型
export interface DashScopeVideoRequest {
  model: string;
  input: {
    text: string;
    image_url?: string[];
  };
  parameters: {
    style?: string;
    duration?: number;
    resolution?: string;
    fps?: number;
  };
}

export interface DashScopeVideoResponse {
  output: {
    task_id: string;
    task_status: 'PENDING' | 'RUNNING' | 'SUCCEEDED' | 'FAILED';
    results?: Array<{
      url: string;
    }>;
  };
  usage?: {
    input_tokens: number;
    output_tokens: number;
  };
  request_id: string;
}