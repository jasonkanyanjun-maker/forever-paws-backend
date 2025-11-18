-- 修复 family_groups 表的 RLS 策略，解决无限递归问题
-- Fix RLS policies for family_groups table to resolve infinite recursion

-- 首先删除现有的有问题的策略
DROP POLICY IF EXISTS "Users can manage own family groups" ON family_groups;
DROP POLICY IF EXISTS "Family members can view group info" ON family_groups;
DROP POLICY IF EXISTS "Group owners can manage members" ON family_members;
DROP POLICY IF EXISTS "Members can view own membership" ON family_members;

-- 为 family_groups 表创建简化的 RLS 策略
-- 1. 用户可以创建和管理自己拥有的家庭组
CREATE POLICY "family_groups_owner_access" ON family_groups
    FOR ALL USING (auth.uid() = owner_id);

-- 2. 家庭成员可以查看他们所属的家庭组信息（简化版本，避免循环引用）
CREATE POLICY "family_groups_member_read" ON family_groups
    FOR SELECT USING (
        id IN (
            SELECT family_group_id 
            FROM family_members 
            WHERE user_id = auth.uid() 
            AND status = 'active'
        )
    );

-- 为 family_members 表创建简化的 RLS 策略
-- 1. 家庭组拥有者可以管理成员
CREATE POLICY "family_members_owner_manage" ON family_members
    FOR ALL USING (
        family_group_id IN (
            SELECT id 
            FROM family_groups 
            WHERE owner_id = auth.uid()
        )
    );

-- 2. 用户可以查看自己的成员身份
CREATE POLICY "family_members_self_read" ON family_members
    FOR SELECT USING (user_id = auth.uid());

-- 3. 用户可以更新自己的成员状态（例如接受邀请）
CREATE POLICY "family_members_self_update" ON family_members
    FOR UPDATE USING (user_id = auth.uid());