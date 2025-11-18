import { Router } from 'express';
import LetterController from '../controllers/LetterController';
import { authenticateToken } from '../middleware/auth';
import { validate, validateQuery } from '../middleware/validation';
import { letterSchemas, commonSchemas } from '../middleware/validation';

const router = Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     Letter:
 *       type: object
 *       required:
 *         - pet_id
 *         - content
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Letter unique identifier
 *         user_id:
 *           type: string
 *           format: uuid
 *           description: User ID who wrote the letter
 *         pet_id:
 *           type: string
 *           format: uuid
 *           description: Pet ID the letter is for
 *         content:
 *           type: string
 *           description: Letter content
 *         type:
 *           type: string
 *           enum: [memorial, birthday, anniversary, daily, ai_reply]
 *           description: Letter type
 *         mood:
 *           type: string
 *           enum: [happy, sad, loving, nostalgic, grateful]
 *           description: Letter mood
 *         parent_letter_id:
 *           type: string
 *           format: uuid
 *           description: Parent letter ID for replies
 *         ai_metadata:
 *           type: object
 *           description: AI generation metadata
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 *     
 *     CreateLetterInput:
 *       type: object
 *       required:
 *         - pet_id
 *         - content
 *       properties:
 *         pet_id:
 *           type: string
 *           format: uuid
 *         content:
 *           type: string
 *           minLength: 10
 *           maxLength: 2000
 *         type:
 *           type: string
 *           enum: [memorial, birthday, anniversary, daily]
 *           default: memorial
 *         mood:
 *           type: string
 *           enum: [happy, sad, loving, nostalgic, grateful]
 *         ai_metadata:
 *           type: object
 *     
 *     UpdateLetterInput:
 *       type: object
 *       properties:
 *         content:
 *           type: string
 *           minLength: 10
 *           maxLength: 2000
 *         type:
 *           type: string
 *           enum: [memorial, birthday, anniversary, daily]
 *         mood:
 *           type: string
 *           enum: [happy, sad, loving, nostalgic, grateful]
 *         ai_metadata:
 *           type: object
 *     
 *     AIReplyGenerationRequest:
 *       type: object
 *       properties:
 *         model:
 *           type: string
 *           enum: [gpt-3.5-turbo, gpt-4, gpt-4-turbo]
 *           default: gpt-3.5-turbo
 *         tone:
 *           type: string
 *           enum: [loving, comforting, playful, wise, gentle]
 *           default: loving
 *         max_length:
 *           type: integer
 *           minimum: 50
 *           maximum: 500
 *           default: 200
 *         creativity_level:
 *           type: number
 *           minimum: 0.1
 *           maximum: 1.0
 *           default: 0.7
 *     
 *     AIReplyGenerationResponse:
 *       type: object
 *       properties:
 *         reply_letter_id:
 *           type: string
 *           format: uuid
 *         content:
 *           type: string
 *         mood:
 *           type: string
 *         model_used:
 *           type: string
 *         generation_time:
 *           type: integer
 *         prompt_tokens:
 *           type: integer
 *         completion_tokens:
 *           type: integer
 *         confidence_score:
 *           type: number
 */

/**
 * @swagger
 * /api/letters:
 *   post:
 *     summary: Create a new letter
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateLetterInput'
 *     responses:
 *       201:
 *         description: Letter created successfully
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
 *                   example: Letter created successfully
 *                 data:
 *                   $ref: '#/components/schemas/Letter'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.post('/', 
  authenticateToken, 
  validate(letterSchemas.createLetter), 
  LetterController.createLetter
);

/**
 * @swagger
 * /api/letters:
 *   get:
 *     summary: Get all letters for current user
 *     tags: [Letters]
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
 *           enum: [created_at, updated_at, type]
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
 *         name: type
 *         schema:
 *           type: string
 *           enum: [memorial, birthday, anniversary, daily, ai_reply]
 *         description: Filter by letter type
 *       - in: query
 *         name: mood
 *         schema:
 *           type: string
 *           enum: [happy, sad, loving, nostalgic, grateful]
 *         description: Filter by mood
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
 *       - in: query
 *         name: has_ai_reply
 *         schema:
 *           type: boolean
 *         description: Filter letters with AI replies
 *     responses:
 *       200:
 *         description: Letters retrieved successfully
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
 *                   example: Letters retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Letter'
 *                     pagination:
 *                       $ref: '#/components/schemas/PaginationInfo'
 *       401:
 *         description: Unauthorized
 */
router.get('/', 
  authenticateToken, 
  validateQuery(commonSchemas.pagination), 
  LetterController.getLetters
);

/**
 * @swagger
 * /api/letters/statistics:
 *   get:
 *     summary: Get letter statistics
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Letter statistics retrieved successfully
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
 *                   example: Letter statistics retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     total_letters:
 *                       type: integer
 *                     letters_by_type:
 *                       type: object
 *                     letters_by_mood:
 *                       type: object
 *                     recent_letters:
 *                       type: integer
 *                     ai_replies_generated:
 *                       type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/statistics', 
  authenticateToken, 
  LetterController.getLetterStatistics
);

/**
 * @swagger
 * /api/letters/{id}:
 *   get:
 *     summary: Get letter by ID
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     responses:
 *       200:
 *         description: Letter retrieved successfully
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
 *                   example: Letter retrieved successfully
 *                 data:
 *                   $ref: '#/components/schemas/Letter'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 */
router.get('/:id', 
  authenticateToken, 
  LetterController.getLetterById
);

/**
 * @swagger
 * /api/letters/{id}/details:
 *   get:
 *     summary: Get letter with details
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     responses:
 *       200:
 *         description: Letter details retrieved successfully
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
 *                   example: Letter details retrieved successfully
 *                 data:
 *                   type: object
 *                   allOf:
 *                     - $ref: '#/components/schemas/Letter'
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
 *                         parent_letter:
 *                           $ref: '#/components/schemas/Letter'
 *                         replies:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Letter'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 */
router.get('/:id/details', 
  authenticateToken, 
  LetterController.getLetterWithDetails
);

/**
 * @swagger
 * /api/letters/{id}/thread:
 *   get:
 *     summary: Get letter thread (conversation)
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     responses:
 *       200:
 *         description: Letter thread retrieved successfully
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
 *                   example: Letter thread retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     thread_id:
 *                       type: string
 *                       format: uuid
 *                     letters:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Letter'
 *                     total_letters:
 *                       type: integer
 *                     last_activity:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 */
router.get('/:id/thread', 
  authenticateToken, 
  LetterController.getLetterThread
);

/**
 * @swagger
 * /api/letters/{id}/ai-reply:
 *   post:
 *     summary: Generate AI reply for a letter
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/AIReplyGenerationRequest'
 *     responses:
 *       201:
 *         description: AI reply generated successfully
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
 *                   example: AI reply generated successfully
 *                 data:
 *                   $ref: '#/components/schemas/AIReplyGenerationResponse'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 *       503:
 *         description: AI service unavailable
 */
router.post('/:id/ai-reply', 
  authenticateToken, 
  LetterController.generateAIReply
);

/**
 * @swagger
 * /api/letters/{id}:
 *   put:
 *     summary: Update letter
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateLetterInput'
 *     responses:
 *       200:
 *         description: Letter updated successfully
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
 *                   example: Letter updated successfully
 *                 data:
 *                   $ref: '#/components/schemas/Letter'
 *       400:
 *         description: Invalid input data or cannot update AI replies
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 */
router.put('/:id', 
  authenticateToken, 
  validate(letterSchemas.updateLetter), 
  LetterController.updateLetter
);

/**
 * @swagger
 * /api/letters/{id}:
 *   delete:
 *     summary: Delete letter
 *     tags: [Letters]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Letter ID
 *     responses:
 *       200:
 *         description: Letter deleted successfully
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
 *                   example: Letter deleted successfully
 *                 data:
 *                   type: null
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Letter not found
 */
router.delete('/:id', 
  authenticateToken, 
  LetterController.deleteLetter
);

export default router;