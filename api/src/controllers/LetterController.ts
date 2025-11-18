import { Request, Response } from 'express';
import { AuthenticatedRequest } from '../types/common';
import { asyncHandler } from '../middleware/errorHandler';
import supabase from '../config/supabase';
import { AppError } from '../utils/AppError';

/**
 * Letter management controller
 */
export class LetterController {
  /**
   * Create a new letter
   * POST /api/letters
   */
  createLetter = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const letterData = req.body;

    const { data: letter, error } = await supabase
      .from('letters')
      .insert({
        ...letterData,
        user_id: userId,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create letter: ${error.message}`);
    }

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
    // 简化版AI回复生成
    const { id } = req.params;
    
    const { data: letter } = await supabase
      .from('letters')
      .select('*')
      .eq('id', id)
      .single();

    if (!letter) {
      throw new AppError('Letter not found', 404);
    }

    // 获取用户信息
    const { data: user } = await supabase
      .from('users')
      .select('display_name, email')
      .eq('id', letter.user_id || '')
      .single();

    // 获取宠物信息
    const { data: pet } = await supabase
      .from('pets')
      .select('name, type, breed')
      .eq('id', letter.pet_id)
      .single();

    // 模拟AI回复
    const reply = {
      content: `Dear ${user?.display_name || 'friend'},\n\nThank you for sharing your memories with ${pet?.name || 'your beloved pet'}. Your words truly capture the special bond you shared.\n\nRemember that love never truly leaves us - it lives on in every cherished memory, every smile, every moment of joy that your time together brought. ${pet?.name || 'Your pet'} knew they were loved, and that love continues to surround you.\n\nTake comfort in knowing that the connection you shared transcends time and space. Those precious moments are yours to keep forever.\n\nWith warm thoughts and understanding,\nForever Paws`,
      mood: 'loving',
      created_at: new Date().toISOString()
    };

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
      type,
      start_date,
      end_date,
      sort_by = 'created_at',
      sort_order = 'desc'
    } = req.query;

    let query = supabase
      .from('letters')
      .select('*')
      .eq('user_id', userId);

    if (pet_id) {
      query = query.eq('pet_id', pet_id);
    }
    if (type) {
      query = query.eq('type', type);
    }
    if (start_date) {
      query = query.gte('created_at', start_date);
    }
    if (end_date) {
      query = query.lte('created_at', end_date);
    }

    const { data: letters, error, count } = await query
      .order(sort_by as string, { ascending: sort_order === 'asc' })
      .range((parseInt(page as string) - 1) * parseInt(limit as string), parseInt(page as string) * parseInt(limit as string) - 1);

    if (error) {
      throw new Error(`Failed to fetch letters: ${error.message}`);
    }

    res.json({
      code: 200,
      message: 'Letters retrieved successfully',
      data: {
        letters,
        pagination: {
          page: parseInt(page as string),
          limit: parseInt(limit as string),
          total: count || 0,
          totalPages: Math.ceil((count || 0) / parseInt(limit as string))
        }
      }
    });
  });

  /**
   * Get letter by ID
   * GET /api/letters/:id
   */
  getLetterById = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;

    const { data: letter, error } = await supabase
      .from('letters')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !letter) {
      throw new AppError('Letter not found', 404);
    }

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

    const { data: letter, error } = await supabase
      .from('letters')
      .select(`
        *,
        pets (
          id,
          name,
          species,
          breed,
          birth_date,
          death_date,
          avatar_url
        )
      `)
      .eq('id', id)
      .single();

    if (error || !letter) {
      throw new AppError('Letter not found', 404);
    }

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

    const { data: letter, error } = await supabase
      .from('letters')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !letter) {
      throw new AppError('Letter not found', 404);
    }

    const { data: replies, error: repliesError } = await supabase
      .from('letters')
      .select('*')
      .eq('parent_id', id)
      .order('created_at', { ascending: true });

    if (repliesError) {
      throw new Error(`Failed to fetch replies: ${repliesError.message}`);
    }

    res.json({
      code: 200,
      message: 'Letter thread retrieved successfully',
      data: {
        mainLetter: letter,
        replies: replies || []
      }
    });
  });

  /**
   * Update letter
   * PUT /api/letters/:id
   */
  updateLetter = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const { id } = req.params;
    const updateData = req.body;

    const { data: letter, error } = await supabase
      .from('letters')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update letter: ${error.message}`);
    }

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

    const { error } = await supabase
      .from('letters')
      .delete()
      .eq('id', id);

    if (error) {
      throw new Error(`Failed to delete letter: ${error.message}`);
    }

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

    const { data: letters, error } = await supabase
      .from('letters')
      .select('*')
      .eq('user_id', userId);

    if (error) {
      throw new Error(`Failed to fetch letters: ${error.message}`);
    }

    const stats = {
      totalLetters: letters?.length || 0,
      memorialLetters: letters?.filter(l => l.type === 'memorial').length || 0,
      birthdayLetters: letters?.filter(l => l.type === 'birthday').length || 0,
      anniversaryLetters: letters?.filter(l => l.type === 'anniversary').length || 0,
      dailyLetters: letters?.filter(l => l.type === 'daily').length || 0,
      aiReplyLetters: letters?.filter(l => l.type === 'ai_reply').length || 0
    };

    res.json({
      code: 200,
      message: 'Letter statistics retrieved successfully',
      data: stats
    });
  });
}

export default new LetterController();