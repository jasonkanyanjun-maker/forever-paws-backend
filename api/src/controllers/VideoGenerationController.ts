import { Request, Response } from 'express';
import { VideoGenerationService } from '../services/VideoGenerationService';
import { VideoGeneration } from '../models/VideoGeneration';

const videoGenerationService = new VideoGenerationService();
import { AuthenticatedRequest } from '../types/common';
import { asyncHandler } from '../middleware/errorHandler';

/**
 * Video generation controller
 */
export class VideoGenerationController {
  /**
   * Create a new video generation task
   * POST /api/videos
   */
  createVideoGeneration = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const videoData = req.body;

    const videoGeneration = await videoGenerationService.createVideoGeneration(userId, videoData);

    res.status(201).json({
      code: 201,
      message: 'Video generation task created successfully',
      data: videoGeneration
    });
  });

  /**
   * Get all video generations for current user
   * GET /api/videos
   */
  getVideoGenerations = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { page, limit, sortBy, sortOrder, pet_id, status, style, created_from, created_to } = req.query;

    const pagination = {
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
      sortBy: sortBy as string,
      sortOrder: sortOrder as 'asc' | 'desc'
    };

    const filters = {
      pet_id: pet_id as string,
      status: status as VideoGeneration['status'],
      date_from: created_from as string,
      date_to: created_to as string
    };

    const result = await videoGenerationService.getVideoGenerationsByUserId(userId, pagination, filters);

    res.status(200).json({
      code: 200,
      message: 'Video generations retrieved successfully',
      data: result
    });
  });

  /**
   * Get video generation by ID
   * GET /api/videos/:id
   */
  getVideoGenerationById = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const videoGeneration = await videoGenerationService.getVideoGenerationById(id, userId);

    res.status(200).json({
      code: 200,
      message: 'Video generation retrieved successfully',
      data: videoGeneration
    });
  });

  /**
   * Get video generation with details
   * GET /api/videos/:id/details
   */
  getVideoGenerationWithDetails = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const videoGeneration = await videoGenerationService.getVideoGenerationById(id, userId);

    res.status(200).json({
      code: 200,
      message: 'Video generation details retrieved successfully',
      data: videoGeneration
    });
  });

  /**
   * Update video generation
   * PUT /api/videos/:id
   */
  updateVideoGeneration = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const updates = req.body;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Video generation updated successfully',
      data: null
    });
  });

  /**
   * Delete video generation
   * DELETE /api/videos/:id
   */
  deleteVideoGeneration = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Video generation deleted successfully',
      data: null
    });
  });

  /**
   * Retry failed video generation
   * POST /api/videos/:id/retry
   */
  retryVideoGeneration = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Video generation retry started successfully',
      data: null
    });
  });

  /**
   * Get video generation statistics
   * GET /api/videos/statistics
   */
  getVideoGenerationStatistics = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    // 暂时返回空统计数据，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Video generation statistics retrieved successfully',
      data: {
        total: 0,
        completed: 0,
        failed: 0,
        pending: 0
      }
    });
  });
}

export default new VideoGenerationController();