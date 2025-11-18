-- 修复 family_groups 表的 INSERT 策略，解决 401 权限错误
-- Fix INSERT policy for family_groups table to resolve 401 permission error

-- 删除现有的 INSERT 策略
DROP POLICY IF EXISTS "family_groups_insert" ON family_groups;

-- 创建新的 INSERT 策略，确保用户可以插入自己拥有的家庭组
-- 使用 WITH CHECK 子句验证插入的数据
CREATE POLICY "family_groups_insert_fixed" ON family_groups
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND auth.uid() = owner_id::uuid
    );

-- 同时确保用户可以查看自己创建的家庭组
-- 删除并重新创建 SELECT 策略以确保一致性
DROP POLICY IF EXISTS "family_groups_select_owner" ON family_groups;

CREATE POLICY "family_groups_select_owner_fixed" ON family_groups
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = owner_id::uuid
    );