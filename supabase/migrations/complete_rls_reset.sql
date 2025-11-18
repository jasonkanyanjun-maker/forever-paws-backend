-- 完全重置 family_groups 和 family_members 表的 RLS 策略
-- Complete reset of RLS policies for family_groups and family_members tables

-- 禁用 RLS 以便清理所有策略
ALTER TABLE family_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE family_members DISABLE ROW LEVEL SECURITY;

-- 删除所有现有的策略（包括可能存在的任何策略）
DROP POLICY IF EXISTS "Users can manage own family groups" ON family_groups;
DROP POLICY IF EXISTS "Family members can view group info" ON family_groups;
DROP POLICY IF EXISTS "family_groups_owner_access" ON family_groups;
DROP POLICY IF EXISTS "family_groups_member_read" ON family_groups;

DROP POLICY IF EXISTS "Group owners can manage members" ON family_members;
DROP POLICY IF EXISTS "Members can view own membership" ON family_members;
DROP POLICY IF EXISTS "family_members_owner_manage" ON family_members;
DROP POLICY IF EXISTS "family_members_self_read" ON family_members;
DROP POLICY IF EXISTS "family_members_self_update" ON family_members;

-- 重新启用 RLS
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

-- 为 family_groups 表创建最简单的策略
-- 1. 用户可以插入自己拥有的家庭组
CREATE POLICY "family_groups_insert" ON family_groups
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- 2. 用户可以查看自己拥有的家庭组
CREATE POLICY "family_groups_select_owner" ON family_groups
    FOR SELECT USING (auth.uid() = owner_id);

-- 3. 用户可以更新自己拥有的家庭组
CREATE POLICY "family_groups_update" ON family_groups
    FOR UPDATE USING (auth.uid() = owner_id);

-- 4. 用户可以删除自己拥有的家庭组
CREATE POLICY "family_groups_delete" ON family_groups
    FOR DELETE USING (auth.uid() = owner_id);

-- 为 family_members 表创建最简单的策略
-- 1. 用户可以查看自己的成员记录
CREATE POLICY "family_members_select_self" ON family_members
    FOR SELECT USING (auth.uid() = user_id);

-- 2. 家庭组拥有者可以插入成员记录
CREATE POLICY "family_members_insert_owner" ON family_members
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT owner_id FROM family_groups WHERE id = family_group_id
        )
    );

-- 3. 家庭组拥有者可以更新成员记录
CREATE POLICY "family_members_update_owner" ON family_members
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT owner_id FROM family_groups WHERE id = family_group_id
        )
    );

-- 4. 家庭组拥有者可以删除成员记录
CREATE POLICY "family_members_delete_owner" ON family_members
    FOR DELETE USING (
        auth.uid() IN (
            SELECT owner_id FROM family_groups WHERE id = family_group_id
        )
    );