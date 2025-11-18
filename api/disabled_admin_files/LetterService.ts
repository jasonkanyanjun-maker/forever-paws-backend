import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';
import axios from 'axios';
import type { 
  Letter, 
  CreateLetterInput, 
  UpdateLetterInput,
  LetterWithDetails,
  LetterFilters,
  LetterStats,
  AIReplyGenerationRequest,
  AIReplyGenerationResponse
} from '../models';
import { PaginatedResponse } from '../types/common';

export class LetterService {
  private readonly openrouterApiKey = process.env.OPENROUTER_API_KEY;
  private readonly openrouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  private readonly openrouterModel = process.env.OPENROUTER_MODEL || 'deepseek/deepseek-r1-t2-chimera:free';

  constructor() {}

  async createLetter(userId: string, input: CreateLetterInput): Promise<Letter> {
    try {
      // 验证宠物是否属于用户
      const { data: pet, error: petError } = await supabase
        .from('pets')
        .select('id, user_id')
        .eq('id', input.pet_id)
        .single();

      if (petError || !pet) {
        throw ErrorTypes.NOT_FOUND('Pet not found');
      }

      if (pet.user_id !== userId) {
        throw ErrorTypes.FORBIDDEN('Pet does not belong to user');
      }

      // 创建信件
      const { data: letter, error } = await supabase
        .from('letters')
        .insert({
          ...input,
          user_id: userId
        })
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to create letter');
      }

      return letter;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to create letter');
    }
  }

  async getLettersByUserId(userId: string, options: any): Promise<PaginatedResponse<Letter>> {
    try {
      const { page = 1, limit = 10, ...filters } = options;
      const offset = (page - 1) * limit;

      let query = supabase
        .from('letters')
        .select('*', { count: 'exact' })
        .eq('user_id', userId)
        .range(offset, offset + limit - 1);

      if (filters.pet_id) {
        query = query.eq('pet_id', filters.pet_id);
      }

      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      if (filters.type) {
        query = query.eq('type', filters.type);
      }

      const { data: letters, error, count } = await query;

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to fetch letters');
      }

      return {
        data: letters || [],
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      };
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to fetch letters');
    }
  }

  async getLetterById(id: string): Promise<Letter> {
    try {
      const { data: letter, error } = await supabase
        .from('letters')
        .select('*')
        .eq('id', id)
        .single();

      if (error || !letter) {
        throw ErrorTypes.NOT_FOUND('Letter not found');
      }

      return letter;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to fetch letter');
    }
  }

  async getLetterWithDetails(id: string): Promise<LetterWithDetails> {
    try {
      const { data: letter, error } = await supabase
        .from('letters')
        .select(`
          *,
          pet:pets(*),
          user:users(*)
        `)
        .eq('id', id)
        .single();

      if (error || !letter) {
        throw ErrorTypes.NOT_FOUND('Letter not found');
      }

      return letter as LetterWithDetails;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to fetch letter details');
    }
  }

  async getLetterThread(id: string): Promise<Letter[]> {
    try {
      const { data: letters, error } = await supabase
        .from('letters')
        .select('*')
        .or(`id.eq.${id},parent_letter_id.eq.${id}`)
        .order('created_at', { ascending: true });

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to fetch letter thread');
      }

      return letters || [];
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to fetch letter thread');
    }
  }

  async updateLetter(id: string, input: UpdateLetterInput): Promise<Letter> {
    try {
      const { data: letter, error } = await supabase
        .from('letters')
        .update(input)
        .eq('id', id)
        .select()
        .single();

      if (error || !letter) {
        throw ErrorTypes.NOT_FOUND('Letter not found or update failed');
      }

      return letter;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to update letter');
    }
  }

  async deleteLetter(id: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('letters')
        .delete()
        .eq('id', id);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to delete letter');
      }
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to delete letter');
    }
  }

  async getLetterStatistics(userId: string): Promise<LetterStats> {
    try {
      const { data: stats, error } = await supabase
         .from('letters')
         .select('type, mood, created_at')
         .eq('user_id', userId);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to fetch letter statistics');
      }

      const total = stats?.length || 0;

      return {
         total_letters: total,
         letters_by_type: {
           memorial: stats?.filter(s => s.type === 'memorial').length || 0,
           birthday: stats?.filter(s => s.type === 'birthday').length || 0,
           anniversary: stats?.filter(s => s.type === 'anniversary').length || 0,
           daily: stats?.filter(s => s.type === 'daily').length || 0,
           ai_reply: stats?.filter(s => s.type === 'ai_reply').length || 0
         },
         letters_by_mood: {
           happy: stats?.filter(s => s.mood === 'happy').length || 0,
           sad: stats?.filter(s => s.mood === 'sad').length || 0,
           nostalgic: stats?.filter(s => s.mood === 'nostalgic').length || 0
         },
         recent_activity: stats?.filter(s => {
           if (!s.created_at) return false;
           const createdAt = new Date(s.created_at);
           const weekAgo = new Date();
           weekAgo.setDate(weekAgo.getDate() - 7);
           return createdAt >= weekAgo;
         }).length || 0
       };
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to fetch letter statistics');
    }
  }

  async generateAIReply(letterId: string): Promise<string> {
    try {
      // 获取原始信件和相关信息
      const { data: letter, error: letterError } = await supabase
        .from('letters')
        .select(`
          *,
          pet:pets(id, name, type, personality),
          user:users(id, display_name, email)
        `)
        .eq('id', letterId)
        .single();

      if (letterError || !letter) {
        throw ErrorTypes.NOT_FOUND('Letter not found');
      }

      if (!letter.pet) {
        throw ErrorTypes.NOT_FOUND('Pet not found');
      }

      // 构建 AI 请求
      const aiRequest: AIReplyGenerationRequest = {
        original_letter: letter.content,
        pet_context: {
          name: letter.pet.name,
          type: letter.pet.type,
          personality: letter.pet.personality || undefined,
          memories: []
        },
        user_context: {
          name: letter.user?.display_name || undefined,
          relationship: 'owner'
        }
      };

      // 调用 AI 服务生成回复
      const aiReply = await this.callAIService(aiRequest);

      // 创建回复信件
      const { data: replyLetter, error: replyError } = await supabase
        .from('letters')
        .insert({
          content: aiReply.reply,
          pet_id: letter.pet_id,
          user_id: letter.user_id,
          parent_letter_id: letterId,
          type: 'ai_reply',
          ai_metadata: aiReply.metadata as any
        })
        .select()
        .single();

      if (replyError) {
        throw ErrorTypes.DATABASE_ERROR('Failed to create AI reply');
      }

      // 更新原始信件的回复时间
      await supabase
        .from('letters')
        .update({ replied_at: new Date().toISOString() })
        .eq('id', letterId);

      return aiReply.reply;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to generate AI reply');
    }
  }

  private async callAIService(request: AIReplyGenerationRequest): Promise<AIReplyGenerationResponse> {
    if (!this.openrouterApiKey) {
      throw ErrorTypes.SERVICE_UNAVAILABLE('OpenRouter API key not configured');
    }
    const system = `You are ${request.pet_context.name}, a ${request.pet_context.type}. Reply lovingly as the pet, based on the owner's letter and context.`;
    const user = [
      `Owner: ${request.user_context.name || 'friend'}`,
      `Pet personality: ${request.pet_context.personality || 'warm'}`,
      `Letter: ${request.original_letter}`
    ].join('\n');
    try {
      const resp = await axios.post(this.openrouterUrl, {
        model: this.openrouterModel,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user }
        ]
      }, {
        headers: {
          Authorization: `Bearer ${this.openrouterApiKey}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      });
      const text = resp.data?.choices?.[0]?.message?.content || '';
      if (!text) {
        throw ErrorTypes.EXTERNAL_API_ERROR('openrouter', 'Empty reply');
      }
      return {
        reply: text,
        confidence: 0.9,
        metadata: { provider: 'openrouter', model: this.openrouterModel }
      };
    } catch (e) {
      throw ErrorTypes.EXTERNAL_API_ERROR('openrouter', 'Failed to call OpenRouter');
    }
  }
}
