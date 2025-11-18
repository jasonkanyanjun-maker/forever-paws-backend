-- 完全开放 RLS 策略，允许 anon 用户进行所有操作
-- Completely open RLS policies to allow anon users to perform all operations

-- 删除所有现有的 family_groups 策略
DROP POLICY IF EXISTS "family_groups_insert_debug" ON family_groups;
DROP POLICY IF EXISTS "family_groups_select_debug" ON family_groups;
DROP POLICY IF EXISTS "family_groups_insert_fixed" ON family_groups;
DROP POLICY IF EXISTS "family_groups_select_owner_fixed" ON family_groups;
DROP POLICY IF EXISTS "family_groups_insert" ON family_groups;
DROP POLICY IF EXISTS "family_groups_select_owner" ON family_groups;
DROP POLICY IF EXISTS "family_groups_update" ON family_groups;
DROP POLICY IF EXISTS "family_groups_delete" ON family_groups;

-- 删除所有现有的 family_members 策略
DROP POLICY IF EXISTS "family_members_insert" ON family_members;
DROP POLICY IF EXISTS "family_members_select" ON family_members;
DROP POLICY IF EXISTS "family_members_update" ON family_members;
DROP POLICY IF EXISTS "family_members_delete" ON family_members;
DROP POLICY IF EXISTS "family_members_insert_by_owner" ON family_members;

-- 为 family_groups 表创建完全开放的策略
CREATE POLICY "family_groups_open_insert" ON family_groups
    FOR INSERT 
    WITH CHECK (true);

CREATE POLICY "family_groups_open_select" ON family_groups
    FOR SELECT 
    USING (true);

CREATE POLICY "family_groups_open_update" ON family_groups
    FOR UPDATE 
    USING (true)
    WITH CHECK (true);

CREATE POLICY "family_groups_open_delete" ON family_groups
    FOR DELETE 
    USING (true);

-- 为 family_members 表创建完全开放的策略
CREATE POLICY "family_members_open_insert" ON family_members
    FOR INSERT 
    WITH CHECK (true);

CREATE POLICY "family_members_open_select" ON family_members
    FOR SELECT 
    USING (true);

CREATE POLICY "family_members_open_update" ON family_members
    FOR UPDATE 
    USING (true)
    WITH CHECK (true);

CREATE POLICY "family_members_open_delete" ON family_members
    FOR DELETE 
    USING (true);

-- 确保 RLS 已启用
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;