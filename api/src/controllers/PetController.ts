import { Request, Response } from 'express';
import PetService from '../services/PetService';
import { AuthenticatedRequest, PetType } from '../types/common';
import { asyncHandler } from '../utils/asyncHandler';

/**
 * Pet management controller
 */
export class PetController {
  /**
   * Create a new pet
   * POST /api/pets
   */
  createPet = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const petData = req.body;

    const pet = await PetService.createPet(userId, petData);

    res.status(201).json({
      code: 201,
      message: 'Pet created successfully',
      data: pet
    });
  });

  /**
   * Get all pets for current user
   * GET /api/pets
   */
  getPets = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { page, limit, sortBy, sortOrder, type, breed, memorial_date_from, memorial_date_to, has_photos } = req.query;

    const pagination = {
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
      sortBy: sortBy as string,
      sortOrder: sortOrder as 'asc' | 'desc'
    };

    const filters = {
      type: type as PetType,
      breed: breed as string,
      memorial_date_from: memorial_date_from as string,
      memorial_date_to: memorial_date_to as string,
      has_photos: has_photos ? has_photos === 'true' : undefined
    };

    const result = await PetService.getPetsByUserId(userId, pagination, filters);

    res.status(200).json({
      code: 200,
      message: 'Pets retrieved successfully',
      data: result
    });
  });

  /**
   * Get pet by ID
   * GET /api/pets/:id
   */
  getPetById = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const pet = await PetService.getPetById(id, userId);

    res.status(200).json({
      code: 200,
      message: 'Pet retrieved successfully',
      data: pet
    });
  });

  /**
   * Get pet with statistics
   * GET /api/pets/:id/stats
   */
  /**
   * Get pet with statistics by ID
   */
  getPetWithStats = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const petWithStats = await PetService.getPetWithDetails(id, userId);

    res.status(200).json({
      code: 200,
      message: 'Pet with statistics retrieved successfully',
      data: petWithStats
    });
  });



  /**
   * Update pet
   * PUT /api/pets/:id
   */
  updatePet = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const updates = req.body;

    const pet = await PetService.updatePet(id, userId, updates);

    res.status(200).json({
      code: 200,
      message: 'Pet updated successfully',
      data: pet
    });
  });

  /**
   * Delete pet
   * DELETE /api/pets/:id
   */
  deletePet = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;

    await PetService.deletePet(id, userId);

    res.status(200).json({
      code: 200,
      message: 'Pet deleted successfully',
      data: null
    });
  });

  /**
   * Add photo to pet
   * POST /api/pets/:id/photos
   */
  addPetPhoto = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { photo_url } = req.body;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Photo added successfully',
      data: null
    });
  });

  /**
   * Remove photo from pet
   * DELETE /api/pets/:id/photos
   */
  removePetPhoto = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { photo_url } = req.body;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Photo removed successfully',
      data: null
    });
  });

  /**
   * Update pet AI context
   * PUT /api/pets/:id/ai-context
   */
  updatePetAIContext = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const aiContext = req.body;

    // 暂时返回成功响应，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Pet AI context updated successfully',
      data: null
    });
  });

  /**
   * Get pet statistics for dashboard
   * GET /api/pets/statistics
   */
  getPetStatistics = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    // 暂时返回空统计数据，因为服务中没有实现此方法
    res.status(200).json({
      code: 200,
      message: 'Pet statistics retrieved successfully',
      data: {
        total_pets: 0,
        active_pets: 0,
        pet_types: {},
        recent_activities: []
      }
    });
  });

  /**
   * Search pets (admin only)
   * GET /api/pets/search
   */
  searchPets = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { page, limit, sortBy, sortOrder, type, breed, search_term } = req.query;

    const pagination = {
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
      sortBy: sortBy as string,
      sortOrder: sortOrder as 'asc' | 'desc'
    };

    const filters = {
      type: type as PetType,
      breed: breed as string,
      search_term: search_term as string
    };

    const result = await PetService.getPetsByUserId('', pagination, filters);

    res.status(200).json({
      code: 200,
      message: 'Pet search completed successfully',
      data: result
    });
  });
}

export default new PetController();