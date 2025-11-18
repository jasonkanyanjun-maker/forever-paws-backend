-- Comprehensive fix for all RLS policies to resolve 401 authentication errors
-- This migration addresses user_profiles, pet_photos, and users table RLS issues

-- ============================================================================
-- 1. Fix user_profiles table RLS policies
-- ============================================================================

-- Drop all existing policies for user_profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow public read access to user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow users to delete their own profile" ON user_profiles;

-- Enable RLS for user_profiles table and create proper policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile
CREATE POLICY "user_profiles_insert_policy" ON user_profiles
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own profile
CREATE POLICY "user_profiles_select_policy" ON user_profiles
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Allow users to update their own profile
CREATE POLICY "user_profiles_update_policy" ON user_profiles
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own profile
CREATE POLICY "user_profiles_delete_policy" ON user_profiles
    FOR DELETE 
    USING (auth.uid() = user_id);

-- ============================================================================
-- 2. Fix pet_photos table RLS policies
-- ============================================================================

-- Drop all existing policies for pet_photos table
DROP POLICY IF EXISTS "Users can view pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can insert pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can update pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can delete pet photos" ON pet_photos;

-- Create policies for pet_photos table
-- Note: We need to join with pets table to check ownership (using user_id, not owner_id)
CREATE POLICY "pet_photos_select_policy" ON pet_photos
    FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "pet_photos_insert_policy" ON pet_photos
    FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "pet_photos_update_policy" ON pet_photos
    FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "pet_photos_delete_policy" ON pet_photos
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 3. Ensure users table has proper RLS setup (keep it disabled for now)
-- ============================================================================

-- Keep users table RLS disabled as it's working
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. Verification queries
-- ============================================================================

-- Verify RLS status for all tables
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('users', 'user_profiles', 'pet_photos') 
AND schemaname = 'public'
ORDER BY tablename;

-- Verify policies are created
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'pet_photos') 
AND schemaname = 'public'
ORDER BY tablename, policyname;