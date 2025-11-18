-- 修复 users 表的 RLS 策略，允许用户注册
-- Fix users table RLS policies to allow user registration

-- 删除所有现有的 users 表策略
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "users_insert" ON users;
DROP POLICY IF EXISTS "users_select" ON users;
DROP POLICY IF EXISTS "users_update" ON users;
DROP POLICY IF EXISTS "users_delete" ON users;

-- 创建新的 users 表策略，允许注册和基本操作
-- 1. 允许任何人插入新用户（注册）
CREATE POLICY "users_insert_policy" ON users
    FOR INSERT 
    WITH CHECK (true);

-- 2. 用户可以查看自己的资料
CREATE POLICY "users_select_policy" ON users
    FOR SELECT 
    USING (auth.uid() = id OR auth.role() = 'service_role');

-- 3. 用户可以更新自己的资料
CREATE POLICY "users_update_policy" ON users
    FOR UPDATE 
    USING (auth.uid() = id OR auth.role() = 'service_role')
    WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

-- 4. 用户可以删除自己的账户
CREATE POLICY "users_delete_policy" ON users
    FOR DELETE 
    USING (auth.uid() = id OR auth.role() = 'service_role');

-- 确保 RLS 已启用
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 验证策略是否正确创建
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;