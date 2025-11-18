import { Request, Response } from 'express';
import { LetterService } from '../services/LetterService';
import { AuthenticatedRequest } from '../types/common';
import { asyncHandler } from '../middleware/errorHandler';

/**
 * Letter management controller
 */
export class LetterController {
  private letterService = new LetterService();

  /**
   * Create a new letter
   * POST /api/letters
   */
  createLetter = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const letterData = req.body;

    const letter = await this.letterService.createLetter(userId, letterData);

    res.status(201).json({
      code: 201,
      message: 'Letter created successfully',
      data: letter
    });
  });

  /**
   * Generate AI reply for a letter
   * POST /api/letters/:id/ai-reply
   */
  generateAIReply = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    const reply = await this.letterService.generateAIReply(id);

    res.json({
      code: 200,
      message: 'AI reply generated successfully',
      data: { reply }
    });
  });

  /**
   * Get letters for the authenticated user
   * GET /api/letters
   */
  getLetters = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const {
      page = 1,
      limit = 10,
      pet_id,
      status,
      type,
      start_date,
      end_date,
      sort_by = 'created_at',
      sort_order = 'desc'
    } = req.query;

    const filters = {
      pet_id: pet_id as string,
      status: status as 'draft' | 'sent' | 'replied',
      type: type as 'to_pet' | 'from_pet',
      start_date: start_date as string,
      end_date: end_date as string,
      sort_by: sort_by as 'created_at' | 'title' | 'status',
      sort_order: sort_order as 'asc' | 'desc'
    };

    const result = await this.letterService.getLettersByUserId(userId, {
      page: parseInt(page as string),
      limit: parseInt(limit as string),
      ...filters
    });

    res.json({
      code: 200,
      message: 'Letters retrieved successfully',
      data: result
    });
  });

  /**
   * Get letter by ID
   * GET /api/letters/:id
   */
  getLetterById = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    const letter = await this.letterService.getLetterById(id);

    res.json({
      code: 200,
      message: 'Letter retrieved successfully',
      data: letter
    });
  });

  /**
   * Get letter with details (including pet and user info)
   * GET /api/letters/:id/details
   */
  getLetterWithDetails = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    const letter = await this.letterService.getLetterWithDetails(id);

    res.json({
      code: 200,
      message: 'Letter details retrieved successfully',
      data: letter
    });
  });

  /**
   * Get letter thread (conversation)
   * GET /api/letters/:id/thread
   */
  getLetterThread = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    const thread = await this.letterService.getLetterThread(id);

    res.json({
      code: 200,
      message: 'Letter thread retrieved successfully',
      data: thread
    });
  });

  /**
   * Update letter
   * PUT /api/letters/:id
   */
  updateLetter = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;
    const updateData = req.body;

    const letter = await this.letterService.updateLetter(id, updateData);

    res.json({
      code: 200,
      message: 'Letter updated successfully',
      data: letter
    });
  });

  /**
   * Delete letter
   * DELETE /api/letters/:id
   */
  deleteLetter = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    await this.letterService.deleteLetter(id);

    res.json({
      code: 200,
      message: 'Letter deleted successfully'
    });
  });

  /**
   * Get letter statistics
   * GET /api/letters/statistics
   */
  getLetterStatistics = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    const stats = await this.letterService.getLetterStatistics(userId);

    res.json({
      code: 200,
      message: 'Letter statistics retrieved successfully',
      data: stats
    });
  });
}

export default new LetterController();