import bcrypt from 'bcryptjs';
import jwt, { SignOptions } from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../config/supabase';
import { 
  User, 
  CreateUserInput, 
  UserProfile, 
  AuthResponse, 
  LoginCredentials, 
  RegisterData, 
  OAuthData,
  UserPreferences 
} from '../models/User';
import { AuthProvider } from '../types/common';
import { ErrorTypes } from '../middleware/errorHandler';

/**
 * Authentication service class
 */
export class AuthService {
  private readonly JWT_SECRET: string;
  private readonly JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
  private readonly SALT_ROUNDS = 12;

  constructor() {
    this.JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
    if (!process.env.JWT_SECRET) {
      console.warn('⚠️ [AuthService] JWT_SECRET not set in environment variables, using default');
    } else {
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [AuthService] JWT_SECRET loaded from environment');
    }
  }

  /**
   * Generate JWT token for user
   */
  private generateToken(userId: string, email: string, provider?: string): string {
    return jwt.sign(
      { userId, email, provider },
      this.JWT_SECRET,
      { expiresIn: this.JWT_EXPIRES_IN } as SignOptions
    );
  }

  /**
   * Hash password
   */
  private async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }

  /**
   * Verify password
   */
  private async verifyPassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  /**
   * Get default user preferences
   */
  private getDefaultPreferences(): UserPreferences {
    return {
      notifications: {
        email: true,
        push: true,
        video_completed: true,
        order_updates: true,

      },
      privacy: {
        profile_visibility: 'private'
      },
      theme: {
        mode: 'system',
        language: 'en'
      }
    };
  }

  /**
   * Convert user data to profile (exclude sensitive data)
   */
  private userToProfile(user: any): UserProfile {
    return {
      id: user.id,
      email: user.email,
      display_name: user.display_name || user.full_name,
      avatar_url: user.avatar_url,
      provider: user.provider || 'email',
      preferences: user.preferences || this.getDefaultPreferences(),
      created_at: user.created_at,
      updated_at: user.updated_at
    };
  }

  /**
   * Check if user exists by email
   */
  async checkUserExists(email: string): Promise<{ existsInAuth: boolean; existsInPublic: boolean; authUserId?: string; publicUserId?: string }> {
    try {
      // Check in auth.users table
      const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
      const authUser = authUsers?.users?.find(user => user.email === email);
      
      // Check in public.users table
      const { data: publicUser, error: publicError } = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .single();

      return {
        existsInAuth: !!authUser,
        existsInPublic: !publicError && !!publicUser,
        authUserId: authUser?.id,
        publicUserId: publicUser?.id
      };
    } catch (error) {
      console.error('Error checking user existence:', error);
      return {
        existsInAuth: false,
        existsInPublic: false
      };
    }
  }

  /**
   * Clean up user data (for testing purposes)
   */
  async cleanupUser(email: string): Promise<{ success: boolean; message: string }> {
    try {
      const userCheck = await this.checkUserExists(email);
      
      let cleanedAuth = false;
      let cleanedPublic = false;

      // Clean up from public.users table
      if (userCheck.existsInPublic) {
        const { error: publicError } = await supabase
          .from('users')
          .delete()
          .eq('email', email);
        
        if (!publicError) {
          cleanedPublic = true;
          process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`Cleaned up public.users record for ${email}`);
        } else {
          console.error('Error cleaning public.users:', publicError);
        }
      }

      // Clean up from auth.users table
      if (userCheck.existsInAuth && userCheck.authUserId) {
        const { error: authError } = await supabase.auth.admin.deleteUser(userCheck.authUserId);
        
        if (!authError) {
          cleanedAuth = true;
          process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`Cleaned up auth.users record for ${email}`);
        } else {
          console.error('Error cleaning auth.users:', authError);
        }
      }

      const message = `Cleanup completed for ${email}. Auth: ${cleanedAuth ? 'cleaned' : 'not found/error'}, Public: ${cleanedPublic ? 'cleaned' : 'not found/error'}`;
      
      return {
        success: cleanedAuth || cleanedPublic,
        message
      };
    } catch (error: any) {
      console.error('Cleanup error:', error);
      return {
        success: false,
        message: `Cleanup failed: ${error.message}`
      };
    }
  }

  /**
   * Email/password registration
   */
  async register(data: RegisterData): Promise<AuthResponse> {
    const { email, password, display_name } = data;

    try {
      // Check if user already exists
      const userCheck = await this.checkUserExists(email);
      if (userCheck.existsInAuth || userCheck.existsInPublic) {
        throw ErrorTypes.EMAIL_ALREADY_EXISTS();
      }

      // Generate display name and username from display_name or email
      const displayName = display_name || email.split('@')[0];
      const baseUsername = displayName.toLowerCase().replace(/[^a-z0-9]/g, '');
      
      // Generate unique username by adding timestamp if needed
      let username = baseUsername;
      let attempts = 0;
      while (attempts < 10) {
        const { data: existingUser } = await supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .single();
        
        if (!existingUser) {
          break; // Username is available
        }
        
        // Add timestamp to make it unique
        username = `${baseUsername}${Date.now()}${attempts}`;
        attempts++;
      }

      // First create auth user
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true, // Auto-confirm in development
        user_metadata: {
          display_name: displayName
        }
      });

      if (authError) {
        console.error('Auth error:', authError);
        const msg = authError.message || 'Failed to create user account';
        if (/email/i.test(msg) && /exists|registered|already/i.test(msg)) {
          throw ErrorTypes.EMAIL_ALREADY_EXISTS();
        }
        if (/password/i.test(msg) && /weak|short|too/i.test(msg)) {
          throw ErrorTypes.VALIDATION_ERROR('Password does not meet requirements');
        }
        throw ErrorTypes.INTERNAL_ERROR(msg);
      }

      if (!authData.user) {
        throw ErrorTypes.INTERNAL_ERROR('Failed to create user account');
      }

      // Then create user profile in public.users table with the auth user ID
      const { data: newUser, error: profileError } = await supabase
        .from('users')
        .insert({
          id: authData.user.id, // Use the auth user's ID
          username,
          email,
          full_name: displayName,
          display_name: displayName,
          provider: 'email',
          preferences: this.getDefaultPreferences()
        })
        .select()
        .single();

      if (profileError) {
        console.error('Profile creation error:', profileError);
        console.error('Profile creation error details:', JSON.stringify(profileError, null, 2));
        // Clean up the auth user if profile creation fails
        await supabase.auth.admin.deleteUser(authData.user.id);
        const pmsg = profileError.message || profileError.code || 'Unknown error';
        if (/duplicate/i.test(pmsg)) {
          throw ErrorTypes.CONFLICT('Duplicate profile record');
        }
        throw ErrorTypes.DATABASE_ERROR(`Failed to create user profile: ${pmsg}`);
      }

      // Generate JWT token
      const access_token = this.generateToken(authData.user.id, email, 'email');

      return {
        user: this.userToProfile(newUser),
        access_token,
        expires_in: 7 * 24 * 60 * 60 // 7 days in seconds
      };
    } catch (error: any) {
      if (error.name === 'AppError') {
        throw error;
      }
      console.error('Registration error:', error);
      throw ErrorTypes.INTERNAL_ERROR(error?.message || 'Registration failed');
    }
  }

  /**
   * Login user with email and password
   */
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const { email, password } = credentials;
    process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('🔧 [AuthService] Login attempt for:', email);

    try {
      // 直接使用Supabase Auth进行登录
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (authError) {
        console.error('❌ [AuthService] Auth error:', authError);
        throw ErrorTypes.UNAUTHORIZED('Invalid email or password');
      }

      if (!authData.user) {
        process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('❌ [AuthService] No user data returned from auth');
        throw ErrorTypes.UNAUTHORIZED('Invalid email or password');
      }

      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [AuthService] Auth successful for user:', authData.user.id);

      // 检查或创建public.users表中的用户记录
      let { data: existingUser, error: userCheckError } = await supabase
        .from('users')
        .select('*')
        .eq('id', authData.user.id)
        .single();

      if (userCheckError && userCheckError.code !== 'PGRST116') {
        console.error('❌ [AuthService] Error checking user:', userCheckError);
        throw ErrorTypes.INTERNAL_ERROR('Database error');
      }

      if (!existingUser) {
        // 创建用户记录
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert({
            email: authData.user.email!,
            display_name: authData.user.user_metadata?.display_name || authData.user.email?.split('@')[0],
            preferences: this.getDefaultPreferences()
          })
          .select()
          .single();

        if (createError) {
          console.error('❌ [AuthService] Error creating user:', createError);
          throw ErrorTypes.INTERNAL_ERROR('Failed to create user profile');
        }

        existingUser = newUser;
        process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [AuthService] User profile created:', existingUser.id);
      }

      // Generate JWT token
      const access_token = this.generateToken(existingUser.id, existingUser.email, 'email');
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ [AuthService] JWT token generated');

      const profile = this.userToProfile(existingUser);

      return {
        access_token,
        expires_in: 604800, // 7 days
        user: profile
      };
    } catch (error) {
      console.error('❌ [AuthService] Login error:', error);
      if (error instanceof Error && error.message.includes('Invalid email or password')) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Login failed');
    }
  }

  /**
   * OAuth login (Apple, Google)
   */
  async oauthLogin(oauthData: OAuthData): Promise<AuthResponse> {
    // For now, we'll use Supabase Auth for OAuth authentication
    // This is a simplified implementation - in production you'd use Supabase Auth
    throw ErrorTypes.NOT_FOUND('OAuth login not implemented - use Supabase Auth instead');
  }

  /**
   * Get user profile by ID
   */
  async getUserProfile(userId: string): Promise<UserProfile> {
    throw ErrorTypes.NOT_FOUND('User profile methods not implemented - use Supabase Auth instead');
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, updates: Partial<UserProfile>): Promise<UserProfile> {
    throw ErrorTypes.NOT_FOUND('User profile methods not implemented - use Supabase Auth instead');
  }

  /**
   * Verify JWT token
   */
  async verifyToken(token: string): Promise<{ userId: string; email: string; provider?: string }> {
    try {
      const decoded = jwt.verify(token, this.JWT_SECRET) as any;
      return {
        userId: decoded.userId,
        email: decoded.email,
        provider: decoded.provider
      };
    } catch (error) {
      throw ErrorTypes.UNAUTHORIZED('Invalid token');
    }
  }

  /**
   * Refresh access token
   */
  async refreshToken(userId: string): Promise<{ access_token: string; expires_in: number }> {
    throw ErrorTypes.NOT_FOUND('Refresh token not implemented - use Supabase Auth instead');
  }

  /**
   * Delete user account
   */
  async deleteAccount(userId: string): Promise<void> {
    throw ErrorTypes.NOT_FOUND('Delete account not implemented - use Supabase Auth instead');
  }

  /**
   * Send password reset email
   */
  async resetPassword(email: string): Promise<void> {
    try {
      // Send password reset email using Supabase Auth
      // This will automatically check if the user exists and send email if they do
      // Use the correct server IP address that works with mobile devices
      const redirectUrl = process.env.FRONTEND_URL || 'http://192.168.0.105:3001';
      const resetUrl = `${redirectUrl}/reset-password.html`;
      
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('Sending password reset email with redirect URL:', resetUrl);
      
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: resetUrl
      });

      if (resetError) {
        console.error('Password reset error:', resetError);
        throw new Error('Failed to send password reset email');
      }
      
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('Password reset email sent successfully to:', email);
    } catch (error) {
      console.error('Reset password error:', error);
      throw error;
    }
  }

  /**
   * Update password with reset token
   */
  async updatePasswordWithToken(password: string, accessToken: string, refreshToken?: string): Promise<void> {
    try {
      // Set the session with the tokens from the reset email
      const { data: sessionData, error: sessionError } = await supabase.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken || ''
      });

      if (sessionError || !sessionData.user) {
        console.error('Session error:', sessionError);
        throw new Error('Invalid or expired reset token');
      }

      // Update the password
      const { error: updateError } = await supabase.auth.updateUser({
        password: password
      });

      if (updateError) {
        console.error('Password update error:', updateError);
        throw new Error('Failed to update password');
      }

      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('Password updated successfully for user:', sessionData.user.email);
    } catch (error) {
      console.error('Update password with token error:', error);
      throw error;
    }
  }
}

export default new AuthService();
