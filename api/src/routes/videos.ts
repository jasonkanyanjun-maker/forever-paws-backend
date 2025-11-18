import { Router } from 'express';
import VideoGenerationController from '../controllers/VideoGenerationController';
import { authenticateToken } from '../middleware/auth';
import { validate, validateQuery } from '../middleware/validation';
import { videoSchemas, commonSchemas } from '../middleware/validation';

const router = Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     VideoGeneration:
 *       type: object
 *       required:
 *         - pet_id
 *         - prompt
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Video generation unique identifier
 *         user_id:
 *           type: string
 *           format: uuid
 *           description: User ID who created the video
 *         pet_id:
 *           type: string
 *           format: uuid
 *           description: Pet ID for the video
 *         prompt:
 *           type: string
 *           description: Text prompt for video generation
 *         style:
 *           type: string
 *           enum: [realistic, cartoon, anime, oil_painting, watercolor]
 *           description: Video generation style
 *         duration:
 *           type: integer
 *           minimum: 3
 *           maximum: 10
 *           description: Video duration in seconds
 *         resolution:
 *           type: string
 *           enum: [1024x1024, 720x1280, 1280x720]
 *           description: Video resolution
 *         status:
 *           type: string
 *           enum: [pending, processing, completed, failed]
 *           description: Generation status
 *         video_url:
 *           type: string
 *           format: uri
 *           description: Generated video URL
 *         error_message:
 *           type: string
 *           description: Error message if generation failed
 *         metadata:
 *           type: object
 *           description: Additional metadata
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 *         completed_at:
 *           type: string
 *           format: date-time
 *     
 *     CreateVideoGenerationInput:
 *       type: object
 *       required:
 *         - pet_id
 *         - prompt
 *       properties:
 *         pet_id:
 *           type: string
 *           format: uuid
 *         prompt:
 *           type: string
 *           minLength: 10
 *           maxLength: 500
 *         style:
 *           type: string
 *           enum: [realistic, cartoon, anime, oil_painting, watercolor]
 *           default: realistic
 *         duration:
 *           type: integer
 *           minimum: 3
 *           maximum: 10
 *           default: 5
 *         resolution:
 *           type: string
 *           enum: [1024x1024, 720x1280, 1280x720]
 *           default: 1024x1024
 *         metadata:
 *           type: object
 *     
 *     UpdateVideoGenerationInput:
 *       type: object
 *       properties:
 *         prompt:
 *           type: string
 *           minLength: 10
 *           maxLength: 500
 *         style:
 *           type: string
 *           enum: [realistic, cartoon, anime, oil_painting, watercolor]
 *         duration:
 *           type: integer
 *           minimum: 3
 *           maximum: 10
 *         resolution:
 *           type: string
 *           enum: [1024x1024, 720x1280, 1280x720]
 *         metadata:
 *           type: object
 */

/**
 * @swagger
 * /api/videos:
 *   post:
 *     summary: Create a new video generation task
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateVideoGenerationInput'
 *     responses:
 *       201:
 *         description: Video generation task created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 201
 *                 message:
 *                   type: string
 *                   example: Video generation task created successfully
 *                 data:
 *                   $ref: '#/components/schemas/VideoGeneration'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.post('/', 
  authenticateToken, 
  validate(videoSchemas.create), 
  VideoGenerationController.createVideoGeneration
);

/**
 * @swagger
 * /api/videos:
 *   get:
 *     summary: Get all video generations for current user
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Items per page
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [created_at, updated_at, status]
 *         description: Sort field
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: Sort order
 *       - in: query
 *         name: pet_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by pet ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, processing, completed, failed]
 *         description: Filter by status
 *       - in: query
 *         name: style
 *         schema:
 *           type: string
 *           enum: [realistic, cartoon, anime, oil_painting, watercolor]
 *         description: Filter by style
 *       - in: query
 *         name: created_from
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter created date from
 *       - in: query
 *         name: created_to
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter created date to
 *     responses:
 *       200:
 *         description: Video generations retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generations retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/VideoGeneration'
 *                     pagination:
 *                       $ref: '#/components/schemas/PaginationInfo'
 *       401:
 *         description: Unauthorized
 */
router.get('/', 
  authenticateToken, 
  validateQuery(commonSchemas.pagination), 
  VideoGenerationController.getVideoGenerations
);

/**
 * @swagger
 * /api/videos/statistics:
 *   get:
 *     summary: Get video generation statistics
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Video generation statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation statistics retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     total_videos:
 *                       type: integer
 *                     completed_videos:
 *                       type: integer
 *                     pending_videos:
 *                       type: integer
 *                     failed_videos:
 *                       type: integer
 *                     videos_by_style:
 *                       type: object
 *                     recent_generations:
 *                       type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/statistics', 
  authenticateToken, 
  VideoGenerationController.getVideoGenerationStatistics
);

/**
 * @swagger
 * /api/videos/{id}:
 *   get:
 *     summary: Get video generation by ID
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Video generation ID
 *     responses:
 *       200:
 *         description: Video generation retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation retrieved successfully
 *                 data:
 *                   $ref: '#/components/schemas/VideoGeneration'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Video generation not found
 */
router.get('/:id', 
  authenticateToken, 
  VideoGenerationController.getVideoGenerationById
);

/**
 * @swagger
 * /api/videos/{id}/details:
 *   get:
 *     summary: Get video generation with details
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Video generation ID
 *     responses:
 *       200:
 *         description: Video generation details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation details retrieved successfully
 *                 data:
 *                   type: object
 *                   allOf:
 *                     - $ref: '#/components/schemas/VideoGeneration'
 *                     - type: object
 *                       properties:
 *                         pet:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: string
 *                             name:
 *                               type: string
 *                             type:
 *                               type: string
 *                             breed:
 *                               type: string
 *                             photos:
 *                               type: array
 *                               items:
 *                                 type: string
 *                         user:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: string
 *                             username:
 *                               type: string
 *                             email:
 *                               type: string
 *                             avatar_url:
 *                               type: string
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Video generation not found
 */
router.get('/:id/details', 
  authenticateToken, 
  VideoGenerationController.getVideoGenerationWithDetails
);

/**
 * @swagger
 * /api/videos/{id}:
 *   put:
 *     summary: Update video generation
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Video generation ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateVideoGenerationInput'
 *     responses:
 *       200:
 *         description: Video generation updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation updated successfully
 *                 data:
 *                   $ref: '#/components/schemas/VideoGeneration'
 *       400:
 *         description: Invalid input data or cannot update completed/processing video
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Video generation not found
 */
router.put('/:id', 
  authenticateToken, 
  validate(videoSchemas.update), 
  VideoGenerationController.updateVideoGeneration
);

/**
 * @swagger
 * /api/videos/{id}:
 *   delete:
 *     summary: Delete video generation
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Video generation ID
 *     responses:
 *       200:
 *         description: Video generation deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation deleted successfully
 *                 data:
 *                   type: null
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Video generation not found
 */
router.delete('/:id', 
  authenticateToken, 
  VideoGenerationController.deleteVideoGeneration
);

/**
 * @swagger
 * /api/videos/{id}/retry:
 *   post:
 *     summary: Retry failed video generation
 *     tags: [Video Generation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Video generation ID
 *     responses:
 *       200:
 *         description: Video generation retry started successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code:
 *                   type: integer
 *                   example: 200
 *                 message:
 *                   type: string
 *                   example: Video generation retry started successfully
 *                 data:
 *                   $ref: '#/components/schemas/VideoGeneration'
 *       400:
 *         description: Can only retry failed video generations
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Video generation not found
 */
router.post('/:id/retry', 
  authenticateToken, 
  VideoGenerationController.retryVideoGeneration
);

export default router;