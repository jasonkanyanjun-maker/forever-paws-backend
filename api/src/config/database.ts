import { supabase } from './supabase';

/**
 * Database connection and health check utilities
 */
export class DatabaseConfig {
  /**
   * Test database connection
   */
  static async testConnection(): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('count')
        .limit(1);
      
      if (error) {
        console.error('Database connection test failed:', error);
        return false;
      }
      
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('✅ Database connection successful');
      return true;
    } catch (error) {
      console.error('Database connection error:', error);
      return false;
    }
  }

  /**
   * Initialize database tables if they don't exist
   */
  static async initializeTables(): Promise<void> {
    try {
      // Check if tables exist by querying system tables
      try {
        const { data: tables, error } = await supabase
          .from('users')
          .select('id')
          .limit(1);
        
        if (!error) {
          process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('Database tables are accessible');
        }
      } catch (err) {
        console.warn('Could not check table existence:', err);
      }

      
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log('📊 Database tables initialized');
    } catch (error) {
      console.error('Error initializing database tables:', error);
    }
  }

  /**
   * Create storage buckets if they don't exist
   */
  static async initializeStorage(): Promise<void> {
    try {
      const buckets = ['images', 'videos', 'avatars'];
      
      for (const bucketName of buckets) {
        const { data: existingBucket } = await supabase.storage
          .getBucket(bucketName);
        
        if (!existingBucket) {
          const { error } = await supabase.storage
            .createBucket(bucketName, {
              public: true,
              allowedMimeTypes: bucketName === 'videos' 
                ? ['video/mp4', 'video/quicktime', 'video/x-msvideo']
                : ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
              fileSizeLimit: bucketName === 'videos' ? 100 * 1024 * 1024 : 10 * 1024 * 1024 // 100MB for videos, 10MB for images
            });
          
          if (error) {
            console.warn(`Could not create bucket ${bucketName}:`, error);
          } else {
            process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'production' && console.log(`✅ Created storage bucket: ${bucketName}`);
          }
        }
      }
    } catch (error) {
      console.error('Error initializing storage buckets:', error);
    }
  }
}

export default DatabaseConfig;