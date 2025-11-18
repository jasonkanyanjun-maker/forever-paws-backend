-- 调试和修复 family_groups 表的 RLS 策略问题
-- Debug and fix RLS policy issues for family_groups table

-- 首先完全禁用 RLS 来测试基本的插入功能
ALTER TABLE family_groups DISABLE ROW LEVEL SECURITY;

-- 删除所有现有的策略
DROP POLICY IF EXISTS "family_groups_insert_fixed" ON family_groups;
DROP POLICY IF EXISTS "family_groups_select_owner_fixed" ON family_groups;
DROP POLICY IF EXISTS "family_groups_insert" ON family_groups;
DROP POLICY IF EXISTS "family_groups_select_owner" ON family_groups;
DROP POLICY IF EXISTS "family_groups_update" ON family_groups;
DROP POLICY IF EXISTS "family_groups_delete" ON family_groups;

-- 重新启用 RLS
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;

-- 创建最简单的 INSERT 策略，允许所有认证用户插入
CREATE POLICY "family_groups_insert_debug" ON family_groups
    FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

-- 创建最简单的 SELECT 策略，允许所有认证用户查看
CREATE POLICY "family_groups_select_debug" ON family_groups
    FOR SELECT 
    USING (auth.uid() IS NOT NULL);

-- 如果上面的策略工作，再创建更严格的策略
-- CREATE POLICY "family_groups_insert_strict" ON family_groups
--     FOR INSERT 
--     WITH CHECK (
--         auth.uid() IS NOT NULL 
--         AND auth.uid()::text = owner_id::text
--     );

-- CREATE POLICY "family_groups_select_strict" ON family_groups
--     FOR SELECT 
--     USING (
--         auth.uid() IS NOT NULL 
--         AND auth.uid()::text = owner_id::text
--     );