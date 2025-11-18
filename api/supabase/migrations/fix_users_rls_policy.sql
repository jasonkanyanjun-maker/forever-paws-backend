-- 暂时完全禁用 users 表的 RLS 来测试注册功能
-- Temporarily disable RLS on users table to test registration

-- 删除所有现有策略
DROP POLICY IF EXISTS "Allow user registration" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can delete own account" ON public.users;
DROP POLICY IF EXISTS "Service role full access" ON public.users;
DROP POLICY IF EXISTS "Service role can manage users" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;

-- 完全禁用 RLS
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 验证 RLS 状态
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';