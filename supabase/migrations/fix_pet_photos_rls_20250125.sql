-- 修复 pet_photos 表的 RLS 策略
-- Fix pet_photos table RLS policies only

-- 删除现有的 pet_photos 策略
DROP POLICY IF EXISTS "Users can view pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can insert pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can update pet photos" ON pet_photos;
DROP POLICY IF EXISTS "Users can delete pet photos" ON pet_photos;
DROP POLICY IF EXISTS "pet_photos_select_policy" ON pet_photos;
DROP POLICY IF EXISTS "pet_photos_insert_policy" ON pet_photos;
DROP POLICY IF EXISTS "pet_photos_update_policy" ON pet_photos;
DROP POLICY IF EXISTS "pet_photos_delete_policy" ON pet_photos;

-- 确保 pet_photos 表启用 RLS
ALTER TABLE pet_photos ENABLE ROW LEVEL SECURITY;

-- 创建新的 pet_photos 策略
-- 用户可以查看自己宠物的照片
CREATE POLICY "pet_photos_select_policy" ON pet_photos
    FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

-- 用户可以为自己的宠物上传照片
CREATE POLICY "pet_photos_insert_policy" ON pet_photos
    FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

-- 用户可以更新自己宠物的照片
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

-- 用户可以删除自己宠物的照片
CREATE POLICY "pet_photos_delete_policy" ON pet_photos
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

-- 验证策略创建
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'pet_photos'
ORDER BY policyname;