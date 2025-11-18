import { Router } from 'express';
import PetController from '../controllers/PetController';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validate, validateQuery } from '../middleware/validation';
import { petSchemas, commonSchemas } from '../middleware/validation';

const router = Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     Pet:
 *       type: object
 *       required:
 *         - name
 *         - type
 *         - breed
 *         - memorial_date
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Pet unique identifier
 *         user_id:
 *           type: string
 *           format: uuid
 *           description: Owner user ID
 *         name:
 *           type: string
 *           description: Pet name
 *         type:
 *           type: string
 *           enum: [dog, cat, bird, fish, rabbit, hamster, other]
 *           description: Pet type
 *         breed:
 *           type: string
 *           description: Pet breed
 *         birth_date:
 *           type: string
 *           format: date
 *           description: Pet birth date
 *         memorial_date:
 *           type: string
 *           format: date
 *           description: Pet memorial date
 *         description:
 *           type: string
 *           description: Pet description
 *         photos:
 *           type: array
 *           items:
 *             type: string
 *           description: Pet photo URLs
 *         ai_context:
 *           $ref: '#/components/schemas/PetAIContext'
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 *     
 *     PetAIContext:
 *       type: object
 *       properties:
 *         personality_traits:
 *           type: array
 *           items:
 *             type: string
 *         favorite_activities:
 *           type: array
 *           items:
 *             type: string
 *         memorable_moments:
 *           type: array
 *           items:
 *             type: string
 *         voice_characteristics:
 *           type: string
 *         behavioral_patterns:
 *           type: array
 *           items:
 *             type: string
 *     
 *     CreatePetInput:
 *       type: object
 *       required:
 *         - name
 *         - type
 *         - breed
 *         - memorial_date
 *       properties:
 *         name:
 *           type: string
 *         type:
 *           type: string
 *           enum: [dog, cat, bird, fish, rabbit, hamster, other]
 *         breed:
 *           type: string
 *         birth_date:
 *           type: string
 *           format: date
 *         memorial_date:
 *           type: string
 *           format: date
 *         description:
 *           type: string
 *         photos:
 *           type: array
 *           items:
 *             type: string
 *         ai_context:
 *           $ref: '#/components/schemas/PetAIContext'
 *     
 *     UpdatePetInput:
 *       type: object
 *       properties:
 *         name:
 *           type: string
 *         type:
 *           type: string
 *           enum: [dog, cat, bird, fish, rabbit, hamster, other]
 *         breed:
 *           type: string
 *         birth_date:
 *           type: string
 *           format: date
 *         memorial_date:
 *           type: string
 *           format: date
 *         description:
 *           type: string
 *         photos:
 *           type: array
 *           items:
 *             type: string
 *         ai_context:
 *           $ref: '#/components/schemas/PetAIContext'
 */

/**
 * @swagger
 * /api/pets:
 *   post:
 *     summary: Create a new pet
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreatePetInput'
 *     responses:
 *       201:
 *         description: Pet created successfully
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
 *                   example: Pet created successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 */
router.post('/', 
  authenticateToken, 
  validate(petSchemas.createPet), 
  PetController.createPet
);

/**
 * @swagger
 * /api/pets:
 *   get:
 *     summary: Get all pets for current user
 *     tags: [Pets]
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
 *           enum: [name, type, memorial_date, created_at]
 *         description: Sort field
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: Sort order
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [dog, cat, bird, fish, rabbit, hamster, other]
 *         description: Filter by pet type
 *       - in: query
 *         name: breed
 *         schema:
 *           type: string
 *         description: Filter by breed
 *       - in: query
 *         name: memorial_date_from
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter memorial date from
 *       - in: query
 *         name: memorial_date_to
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter memorial date to
 *       - in: query
 *         name: has_photos
 *         schema:
 *           type: boolean
 *         description: Filter pets with photos
 *     responses:
 *       200:
 *         description: Pets retrieved successfully
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
 *                   example: Pets retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     pets:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Pet'
 *                     pagination:
 *                       $ref: '#/components/schemas/PaginationInfo'
 *       401:
 *         description: Unauthorized
 */
router.get('/', 
  authenticateToken, 
  validateQuery(commonSchemas.pagination), 
  PetController.getPets
);

/**
 * @swagger
 * /api/pets/statistics:
 *   get:
 *     summary: Get pet statistics for dashboard
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Pet statistics retrieved successfully
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
 *                   example: Pet statistics retrieved successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     total_pets:
 *                       type: integer
 *                     pets_by_type:
 *                       type: object
 *                     recent_memorials:
 *                       type: integer
 *                     total_photos:
 *                       type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/statistics', 
  authenticateToken, 
  PetController.getPetStatistics
);

/**
 * @swagger
 * /api/pets/search:
 *   get:
 *     summary: Search pets (admin only)
 *     tags: [Pets]
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
 *         name: search_term
 *         schema:
 *           type: string
 *         description: Search term for pet name or breed
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [dog, cat, bird, fish, rabbit, hamster, other]
 *         description: Filter by pet type
 *       - in: query
 *         name: breed
 *         schema:
 *           type: string
 *         description: Filter by breed
 *     responses:
 *       200:
 *         description: Pet search completed successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin access required
 */
router.get('/search', 
  authenticateToken, 
  requireRole(['admin']), 
  validateQuery(commonSchemas.pagination), 
  PetController.searchPets
);

/**
 * @swagger
 * /api/pets/{id}:
 *   get:
 *     summary: Get pet by ID
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     responses:
 *       200:
 *         description: Pet retrieved successfully
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
 *                   example: Pet retrieved successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.get('/:id', 
  authenticateToken, 
  PetController.getPetById
);

/**
 * @swagger
 * /api/pets/{id}/stats:
 *   get:
 *     summary: Get pet with statistics
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     responses:
 *       200:
 *         description: Pet statistics retrieved successfully
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
 *                   example: Pet statistics retrieved successfully
 *                 data:
 *                   type: object
 *                   allOf:
 *                     - $ref: '#/components/schemas/Pet'
 *                     - type: object
 *                       properties:
 *                         stats:
 *                           type: object
 *                           properties:
 *                             total_letters:
 *                               type: integer
 *                             total_videos:
 *                               type: integer
 *                             total_photos:
 *                               type: integer
 *                             last_activity:
 *                               type: string
 *                               format: date-time
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.get('/:id/stats', 
  authenticateToken, 
  PetController.getPetWithStats
);

/**
 * @swagger
 * /api/pets/{id}:
 *   put:
 *     summary: Update pet
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdatePetInput'
 *     responses:
 *       200:
 *         description: Pet updated successfully
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
 *                   example: Pet updated successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.put('/:id', 
  authenticateToken, 
  validate(petSchemas.updatePet), 
  PetController.updatePet
);

/**
 * @swagger
 * /api/pets/{id}:
 *   delete:
 *     summary: Delete pet
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     responses:
 *       200:
 *         description: Pet deleted successfully
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
 *                   example: Pet deleted successfully
 *                 data:
 *                   type: null
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.delete('/:id', 
  authenticateToken, 
  PetController.deletePet
);

/**
 * @swagger
 * /api/pets/{id}/photos:
 *   post:
 *     summary: Add photo to pet
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - photo_url
 *             properties:
 *               photo_url:
 *                 type: string
 *                 format: uri
 *                 description: Photo URL to add
 *     responses:
 *       200:
 *         description: Photo added successfully
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
 *                   example: Photo added successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.post('/:id/photos', 
  authenticateToken, 
  PetController.addPetPhoto
);

/**
 * @swagger
 * /api/pets/{id}/photos:
 *   delete:
 *     summary: Remove photo from pet
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - photo_url
 *             properties:
 *               photo_url:
 *                 type: string
 *                 format: uri
 *                 description: Photo URL to remove
 *     responses:
 *       200:
 *         description: Photo removed successfully
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
 *                   example: Photo removed successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.delete('/:id/photos', 
  authenticateToken, 
  PetController.removePetPhoto
);

/**
 * @swagger
 * /api/pets/{id}/ai-context:
 *   put:
 *     summary: Update pet AI context
 *     tags: [Pets]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Pet ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PetAIContext'
 *     responses:
 *       200:
 *         description: Pet AI context updated successfully
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
 *                   example: Pet AI context updated successfully
 *                 data:
 *                   $ref: '#/components/schemas/Pet'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Pet not found
 */
router.put('/:id/ai-context', 
  authenticateToken, 
  PetController.updatePetAIContext
);

export default router;