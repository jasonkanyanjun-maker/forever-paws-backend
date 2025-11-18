import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';
import type { 
  VideoGeneration, 
  CreateVideoGenerationInput, 
  UpdateVideoGenerationInput,
  VideoGenerationWithDetails,
  VideoGenerationFilters,
  DashScopeVideoRequest,
  DashScopeVideoResponse,
  VideoGenerationMetadata,
  PaginationParams,
  PaginatedResponse
} from '../models';
import axios from 'axios';
import crypto from 'crypto';

export class VideoGenerationService {
  private readonly veoApiUrl = 'https://api.wuyinkeji.com/api/video/veoDetail';
  private readonly veoApiKey = '6jwjvdjjTCtNdGiMDgqT8iGkQj';

  constructor() {
    {}
  }

  async createVideoGeneration(userId: string, input: CreateVideoGenerationInput): Promise<VideoGeneration> {
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

      // 创建视频生成记录
      const { data: videoGeneration, error } = await supabase
        .from('video_generations')
        .insert({
          ...input,
          user_id: userId,
          status: 'pending',
          metadata: {}
        })
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to create video generation');
      }

      // 异步开始视频生成过程
      this.startVideoGeneration(videoGeneration.id).catch(error => {
        console.error('Video generation failed:', error);
        this.updateVideoGenerationStatus(videoGeneration.id, 'failed', error.message);
      });

      return videoGeneration;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to create video generation');
    }
  }

  private async startVideoGeneration(videoGenerationId: string): Promise<void> {
    try {
      // 获取视频生成记录
      const { data: videoGeneration, error } = await supabase
        .from('video_generations')
        .select('*')
        .eq('id', videoGenerationId)
        .single();

      if (error || !videoGeneration) {
        throw new Error('Video generation record not found');
      }

      // 更新状态为处理中
      await this.updateVideoGenerationStatus(videoGenerationId, 'processing');

      const details = await this.callVeoAPI('1');
      const videoUrl = details?.videoUrl || details?.url || details?.data?.url || null;
      if (videoUrl) {
        await supabase
          .from('video_generations')
          .update({ 
            status: 'completed',
            video_url: videoUrl,
            completed_at: new Date().toISOString(),
            progress: 100,
            metadata: JSON.stringify({ veo_response: details })
          })
          .eq('id', videoGenerationId);
        return;
      }
      await this.updateVideoGenerationStatus(videoGenerationId, 'failed', 'veo3.1 response missing video url');

    } catch (error) {
      console.error('Video generation error:', error);
      await this.updateVideoGenerationStatus(
        videoGenerationId, 
        'failed', 
        error instanceof Error ? error.message : 'Unknown error'
      );
    }
  }

  private async callVeoAPI(id: string): Promise<any> {
    try {
      const response = await axios.get(this.veoApiUrl, {
        params: { key: this.veoApiKey, id },
        timeout: 20000
      });
      return response.data;
    } catch (error) {
      throw ErrorTypes.EXTERNAL_API_ERROR('veo3.1', 'Failed to call VEO API');
    }
  }

  private async pollTaskStatus(videoGenerationId: string, taskId: string): Promise<void> {
    const maxAttempts = 60; // 最多轮询60次（30分钟）
    const pollInterval = 30000; // 30秒间隔

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await new Promise(resolve => setTimeout(resolve, pollInterval));

        const statusResponse = await this.checkTaskStatus(taskId);
        
        if (statusResponse.output.task_status === 'SUCCEEDED') {
          // 任务成功完成
          const videoUrl = statusResponse.output.results?.[0]?.url;
          if (videoUrl) {
            await supabase
              .from('video_generations')
              .update({ 
                status: 'completed',
                video_url: videoUrl,
                completed_at: new Date().toISOString(),
                progress: 100,
                metadata: JSON.stringify({ dashscope_response: statusResponse })
              })
              .eq('id', videoGenerationId);
          }
          return;
        } else if (statusResponse.output.task_status === 'FAILED') {
          // 任务失败
          await this.updateVideoGenerationStatus(videoGenerationId, 'failed', 'DashScope task failed');
          return;
        } else if (statusResponse.output.task_status === 'RUNNING') {
          // 任务进行中，更新进度
          const progress = Math.min(90, (attempt / maxAttempts) * 100);
          await supabase
            .from('video_generations')
            .update({ progress })
            .eq('id', videoGenerationId);
        }
      } catch (error) {
        console.error('Error polling task status:', error);
        if (attempt === maxAttempts - 1) {
          await this.updateVideoGenerationStatus(videoGenerationId, 'failed', 'Polling timeout');
        }
      }
    }

    // 超时
    await this.updateVideoGenerationStatus(videoGenerationId, 'failed', 'Task timeout');
  }

  private async checkTaskStatus(taskId: string): Promise<any> {
    const data = await this.callVeoAPI(taskId);
    return data;
  }

  private async updateVideoGenerationStatus(
    id: string, 
    status: VideoGeneration['status'], 
    errorMessage?: string
  ): Promise<void> {
    const updateData: any = { 
      status,
      updated_at: new Date().toISOString()
    };

    if (errorMessage) {
      updateData.error_message = errorMessage;
    }

    await supabase
      .from('video_generations')
      .update(updateData)
      .eq('id', id);
  }

  async getVideoGenerationById(id: string, userId: string): Promise<VideoGeneration> {
    try {
      const { data, error } = await supabase
        .from('video_generations')
        .select('*')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw ErrorTypes.NOT_FOUND('Video generation not found');
      }

      return data;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to get video generation');
    }
  }

  async getVideoGenerationsByUserId(
    userId: string,
    pagination?: PaginationParams,
    filters?: VideoGenerationFilters
  ): Promise<PaginatedResponse<VideoGeneration>> {
    try {
      let query = supabase
        .from('video_generations')
        .select('*', { count: 'exact' })
        .eq('user_id', userId);

      // 应用过滤器
      if (filters?.pet_id) {
        query = query.eq('pet_id', filters.pet_id);
      }
      if (filters?.status) {
        query = query.eq('status', filters.status);
      }
      if (filters?.date_from) {
        query = query.gte('created_at', filters.date_from);
      }
      if (filters?.date_to) {
        query = query.lte('created_at', filters.date_to);
      }

      // 应用排序
      const sortBy = pagination?.sortBy || 'created_at';
      const sortOrder = pagination?.sortOrder || 'desc';
      query = query.order(sortBy, { ascending: sortOrder === 'asc' });

      // 应用分页
      if (pagination?.page && pagination?.limit) {
        const offset = (pagination.page - 1) * pagination.limit;
        query = query.range(offset, offset + pagination.limit - 1);
      }

      const { data, error, count } = await query;

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to get video generations');
      }

      return {
        data: data || [],
        pagination: {
          page: pagination?.page || 1,
          limit: pagination?.limit || data?.length || 0,
          total: count || 0,
          totalPages: pagination?.limit ? Math.ceil((count || 0) / pagination.limit) : 1
        }
      };
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to get video generations');
    }
  }
}
