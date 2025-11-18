import { Request, Response } from 'express';
import AuthService from '../services/AuthService';
import { AuthenticatedRequest } from '../types/common';
import { asyncHandler } from '../utils/asyncHandler';

/**
 * Authentication controller
 */
export class AuthController {
  /**
   * Register new user
   * POST /api/auth/register
   */
  register = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email, password, display_name } = req.body;

    const result = await AuthService.register({
      email,
      password,
      display_name
    });

    res.status(201).json({
      code: 201,
      message: 'User registered successfully',
      data: result
    });
  });

  /**
   * Login user
   * POST /api/auth/login
   */
  login = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body;

    const result = await AuthService.login({ email, password });

    res.status(200).json({
      code: 200,
      message: 'Login successful',
      data: result
    });
  });

  /**
   * OAuth login (Apple, Google)
   * POST /api/auth/oauth
   */
  oauthLogin = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { provider, provider_id, email, display_name, avatar_url } = req.body;

    const result = await AuthService.oauthLogin({
      provider,
      provider_id,
      email,
      display_name,
      avatar_url
    });

    res.status(200).json({
      code: 200,
      message: 'OAuth login successful',
      data: result
    });
  });

  /**
   * Get current user profile
   * GET /api/auth/profile
   */
  getProfile = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    const profile = await AuthService.getUserProfile(userId);

    res.status(200).json({
      code: 200,
      message: 'Profile retrieved successfully',
      data: profile
    });
  });

  /**
   * Update user profile
   * PUT /api/auth/profile
   */
  updateProfile = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const updates = req.body;

    const profile = await AuthService.updateProfile(userId, updates);

    res.status(200).json({
      code: 200,
      message: 'Profile updated successfully',
      data: profile
    });
  });

  /**
   * Refresh access token
   * POST /api/auth/refresh
   */
  refreshToken = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    const result = await AuthService.refreshToken(userId);

    res.status(200).json({
      code: 200,
      message: 'Token refreshed successfully',
      data: result
    });
  });

  /**
   * Verify token (POST method)
   * POST /api/auth/verify
   */
  verifyToken = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { token } = req.body;

    const result = await AuthService.verifyToken(token);

    res.status(200).json({
      code: 200,
      message: 'Token is valid',
      data: result
    });
  });

  /**
   * Validate token (GET method for auto-login)
   * GET /api/auth/validate
   */
  validateToken = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;
    const email = req.user!.email;

    // Get user profile
    const profile = await AuthService.getUserProfile(userId);

    res.status(200).json({
      code: 200,
      message: 'Token is valid',
      data: {
        user: profile,
        access_token: req.headers.authorization?.replace('Bearer ', ''),
        expires_in: 3600 // 1 hour
      }
    });
  });

  /**
   * Logout user (client-side token removal)
   * POST /api/auth/logout
   */
  logout = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    // Since we're using stateless JWT, logout is handled client-side
    // This endpoint can be used for logging purposes or token blacklisting in the future
    
    res.status(200).json({
      code: 200,
      message: 'Logout successful',
      data: null
    });
  });

  /**
   * Delete user account
   * DELETE /api/auth/account
   */
  deleteAccount = asyncHandler(async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    const userId = req.user!.userId;

    await AuthService.deleteAccount(userId);

    res.status(200).json({
      code: 200,
      message: 'Account deleted successfully',
      data: null
    });
  });

  /**
   * Check if user exists by email
   * GET /api/auth/check-user?email=xxx
   */
  checkUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email } = req.query;

    if (!email || typeof email !== 'string') {
      res.status(400).json({
        code: 400,
        message: 'Email parameter is required',
        data: null
      });
      return;
    }

    const result = await AuthService.checkUserExists(email);

    res.status(200).json({
      code: 200,
      message: 'User check completed',
      data: result
    });
  });

  /**
   * Clean up user data (for testing purposes)
   * DELETE /api/auth/cleanup-user?email=xxx
   */
  cleanupUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    // 只在开发环境中允许清理用户数据
    if (process.env.NODE_ENV === 'production') {
      res.status(403).json({
        code: 403,
        message: 'User cleanup is not allowed in production environment',
        data: null
      });
      return;
    }

    const { email } = req.query;

    if (!email || typeof email !== 'string') {
      res.status(400).json({
        code: 400,
        message: 'Email parameter is required',
        data: null
      });
      return;
    }

    const result = await AuthService.cleanupUser(email);

    res.status(200).json({
      code: 200,
      message: 'User cleanup completed',
      data: result
    });
  });

  /**
   * Send password reset email
   * POST /api/auth/reset-password
   */
  resetPassword = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email } = req.body;

    await AuthService.resetPassword(email);

    res.status(200).json({
      code: 200,
      message: 'Password reset email sent successfully',
      data: null
    });
  });

  /**
   * Update password with reset token
   * POST /api/auth/update-password
   */
  updatePassword = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { password, access_token, refresh_token } = req.body;

    if (!password || !access_token) {
      res.status(400).json({
        code: 400,
        message: 'Password and access token are required',
        data: null
      });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({
        code: 400,
        message: 'Password must be at least 6 characters long',
        data: null
      });
      return;
    }

    try {
      await AuthService.updatePasswordWithToken(password, access_token, refresh_token);

      res.status(200).json({
        success: true,
        message: 'Password updated successfully'
      });
    } catch (error: any) {
      console.error('Update password error:', error);
      res.status(401).json({
        success: false,
        message: error.message || 'Invalid or expired token'
      });
    }
  });
}

export default new AuthController();