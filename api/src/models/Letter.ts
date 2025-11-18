import type { Database } from '../types/database';

// 使用数据库类型定义
export type Letter = Database['public']['Tables']['letters']['Row'];
export type CreateLetterInput = Database['public']['Tables']['letters']['Insert'];
export type UpdateLetterInput = Database['public']['Tables']['letters']['Update'];

// AI 相关类型
export interface LetterAIMetadata {
  model?: string;
  temperature?: number;
  max_tokens?: number;
  response_time?: number;
  prompt_tokens?: number;
  completion_tokens?: number;
}

// 生成回复请求和响应类型
export interface GenerateReplyRequest {
  letterId: string;
  context?: string;
}

export interface GenerateReplyResponse {
  reply: string;
  metadata: LetterAIMetadata;
}

// 扩展类型，包含关联数据
export interface LetterWithDetails extends Letter {
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
  replies?: Letter[];
}

// 信件线程类型
export interface LetterThread {
  original: LetterWithDetails;
  replies: LetterWithDetails[];
}

// 信件摘要类型
export interface LetterSummary {
  id: string;
  content: string;
  type: Letter['type'];
  mood: Letter['mood'];
  created_at: string;
  pet_name: string;
  reply_count: number;
}

// 信件过滤器
export interface LetterFilters {
  pet_id?: string;
  type?: Letter['type'];
  mood?: Letter['mood'];
  date_from?: string;
  date_to?: string;
  has_replies?: boolean;
}

// 信件统计
export interface LetterStats {
  total_letters: number;
  letters_by_type: Record<string, number>;
  letters_by_mood: Record<string, number>;
  recent_activity: number;
}

// AI 回复生成请求和响应（用于外部 API）
export interface AIReplyGenerationRequest {
  original_letter: string;
  pet_context: {
    name: string;
    type: string;
    personality?: string;
    memories?: string[];
  };
  user_context?: {
    name?: string;
    relationship?: string;
  };
}

export interface AIReplyGenerationResponse {
  reply: string;
  confidence: number;
  metadata: LetterAIMetadata;
}