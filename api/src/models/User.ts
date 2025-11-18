import { AuthProvider } from '../types/common';

/**
 * User model interface matching the database schema
 */
export interface User {
  id: string;
  email: string;
  display_name?: string;
  avatar_url?: string;
  provider: AuthProvider;
  provider_id?: string;
  password_hash?: string;
  preferences: UserPreferences;
  created_at: string;
  updated_at: string;
}

/**
 * User preferences interface
 */
export interface UserPreferences {
  notifications: {
    email: boolean;
    push: boolean;
    video_completed: boolean;
    order_updates: boolean;
  };
  privacy: {
    profile_visibility: 'public' | 'private';
  };
  theme: {
    mode: 'light' | 'dark' | 'system';
    language: string;
  };
}

/**
 * User creation input
 */
export interface CreateUserInput {
  email: string;
  password?: string;
  display_name?: string;
  provider: AuthProvider;
  provider_id?: string;
  preferences?: Partial<UserPreferences>;
}

/**
 * User update input
 */
export interface UpdateUserInput {
  display_name?: string;
  avatar_url?: string;
  preferences?: Partial<UserPreferences>;
}

/**
 * User profile response (excludes sensitive data)
 */
export interface UserProfile {
  id: string;
  email: string;
  display_name?: string;
  avatar_url?: string;
  provider: AuthProvider;
  preferences: UserPreferences;
  created_at: string;
  updated_at: string;
}

/**
 * User authentication response
 */
export interface AuthResponse {
  user: UserProfile;
  access_token: string;
  refresh_token?: string;
  expires_in: number;
}

/**
 * Login credentials
 */
export interface LoginCredentials {
  email: string;
  password: string;
}

/**
 * Registration data
 */
export interface RegisterData {
  email: string;
  password: string;
  display_name?: string;
}

/**
 * Third-party OAuth data
 */
export interface OAuthData {
  provider: AuthProvider;
  provider_id: string;
  email: string;
  display_name?: string;
  avatar_url?: string;
}

/**
 * Password reset request
 */
export interface PasswordResetRequest {
  email: string;
}

/**
 * Password reset confirmation
 */
export interface PasswordResetConfirmation {
  token: string;
  new_password: string;
}

// Export all types for use in other modules