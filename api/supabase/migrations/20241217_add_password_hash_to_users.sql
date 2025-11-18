-- Add password_hash column to users table for email/password authentication
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Add provider column to track authentication method
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS provider VARCHAR(20) DEFAULT 'email';

-- Add display_name column
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);

-- Update existing users to have display_name based on username or email
UPDATE public.users 
SET display_name = COALESCE(username, split_part(email, '@', 1))
WHERE display_name IS NULL;

-- Create index on provider for better query performance
CREATE INDEX IF NOT EXISTS idx_users_provider ON public.users(provider);

-- Create index on email and provider combination
CREATE INDEX IF NOT EXISTS idx_users_email_provider ON public.users(email, provider);