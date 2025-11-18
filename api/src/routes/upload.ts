import { Router, Request, Response } from 'express';
import multer from 'multer';
import { supabase } from '../config/supabase';
import { authenticateToken } from '../middleware/auth';
import { ErrorTypes } from '../utils/errors';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';

const router = Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Check file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed.'));
    }
  },
});

/**
 * @swagger
 * /api/upload/photo:
 *   post:
 *     summary: Upload a photo to Supabase Storage
 *     tags: [Upload]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               photo:
 *                 type: string
 *                 format: binary
 *                 description: The photo file to upload
 *               type:
 *                 type: string
 *                 enum: [avatar, pet, general]
 *                 description: Type of photo being uploaded
 *               pet_id:
 *                 type: string
 *                 description: Pet ID (required if type is 'pet')
 *     responses:
 *       200:
 *         description: Photo uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     url:
 *                       type: string
 *                       description: Public URL of the uploaded photo
 *                     path:
 *                       type: string
 *                       description: Storage path of the uploaded photo
 *       400:
 *         description: Bad request - invalid file or missing parameters
 *       401:
 *         description: Unauthorized - invalid or missing token
 *       413:
 *         description: File too large
 *       500:
 *         description: Internal server error
 */
router.post('/photo', authenticateToken, upload.single('photo'), async (req: Request, res: Response) => {
  try {
    const file = req.file;
    const { type = 'general', pet_id } = req.body;
    const userId = (req as any).user?.userId;

    if (!file) {
      throw ErrorTypes.VALIDATION_ERROR('No file uploaded');
    }

    if (!userId) {
      throw ErrorTypes.UNAUTHORIZED('User not authenticated');
    }

    // Validate type and pet_id relationship
    if (type === 'pet' && !pet_id) {
      throw ErrorTypes.VALIDATION_ERROR('pet_id is required when type is "pet"');
    }

    // Generate unique filename
    const fileExtension = path.extname(file.originalname);
    const fileName = `${uuidv4()}${fileExtension}`;
    
    // Determine storage path based on type
    let storagePath: string;
    let bucketName = 'images';
    
    switch (type) {
      case 'avatar':
        storagePath = `avatars/${userId}/${fileName}`;
        break;
      case 'pet':
        storagePath = `pets/${pet_id}/${fileName}`;
        break;
      default:
        storagePath = `general/${userId}/${fileName}`;
    }

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(storagePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (uploadError) {
      console.error('Supabase upload error:', uploadError);
      throw ErrorTypes.INTERNAL_ERROR(`Failed to upload file: ${uploadError.message}`);
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(storagePath);

    if (!urlData?.publicUrl) {
      throw ErrorTypes.INTERNAL_ERROR('Failed to get public URL for uploaded file');
    }

    return res.json({
      success: true,
      message: 'Photo uploaded successfully',
      data: {
        url: urlData.publicUrl,
        path: storagePath,
        type,
        size: file.size,
        mimetype: file.mimetype,
      },
    });

  } catch (error: any) {
    console.error('Upload error:', error);
    
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({
        success: false,
        message: 'File too large. Maximum size is 10MB.',
      });
    }

    if (error.message?.includes('Invalid file type')) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    // Handle custom errors
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Internal server error during file upload',
    });
  }
});

/**
 * @swagger
 * /api/upload/avatar:
 *   post:
 *     summary: Upload user avatar
 *     tags: [Upload]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               avatar:
 *                 type: string
 *                 format: binary
 *                 description: The avatar image file
 *     responses:
 *       200:
 *         description: Avatar uploaded successfully
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal server error
 */
router.post('/avatar', authenticateToken, upload.single('avatar'), async (req: Request, res: Response) => {
  try {
    const file = req.file;
    const userId = (req as any).user?.userId;

    if (!file) {
      throw ErrorTypes.VALIDATION_ERROR('No avatar file uploaded');
    }

    if (!userId) {
      throw ErrorTypes.UNAUTHORIZED('User not authenticated');
    }

    // Generate unique filename for avatar
    const fileExtension = path.extname(file.originalname);
    const fileName = `avatar_${Date.now()}${fileExtension}`;
    const storagePath = `avatars/${userId}/${fileName}`;

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('images')
      .upload(storagePath, file.buffer, {
        contentType: file.mimetype,
        upsert: true, // Allow overwriting for avatars
      });

    if (uploadError) {
      console.error('Avatar upload error:', uploadError);
      throw ErrorTypes.INTERNAL_ERROR(`Failed to upload avatar: ${uploadError.message}`);
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('images')
      .getPublicUrl(storagePath);

    if (!urlData?.publicUrl) {
      throw ErrorTypes.INTERNAL_ERROR('Failed to get public URL for avatar');
    }

    // Update user profile with new avatar URL in both tables
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('📤 Updating avatar URL in database:', urlData.publicUrl);
    
    // Update users table
    const { error: updateUsersError } = await supabase
      .from('users')
      .update({ avatar_url: urlData.publicUrl })
      .eq('id', userId);

    if (updateUsersError) {
      console.error('Failed to update users table avatar URL:', updateUsersError);
    }

    // Also update user_profiles table to ensure consistency
    const { error: updateProfileError } = await supabase
      .from('user_profiles')
      .update({ avatar_url: urlData.publicUrl })
      .eq('user_id', userId);

    if (updateProfileError) {
      console.error('Failed to update user_profiles table avatar URL:', updateProfileError);
      // Don't throw error here, file is already uploaded
    }

    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ Avatar URL updated in both users and user_profiles tables');

    return res.json({
      success: true,
      message: 'Avatar uploaded successfully',
      data: {
        url: urlData.publicUrl,
        path: storagePath,
      },
    });

  } catch (error: any) {
    console.error('Avatar upload error:', error);
    
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({
        success: false,
        message: 'Avatar file too large. Maximum size is 10MB.',
      });
    }

    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Internal server error during avatar upload',
    });
  }
});

export default router;