-- 修复 RLS 策略，确保 service_role 可以插入用户
-- Fix RLS policies to ensure service_role can insert users

-- 删除所有现有策略
DROP POLICY IF EXISTS "Allow user registration" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can delete own account" ON public.users;
DROP POLICY IF EXISTS "Service role full access" ON public.users;

-- 确保 RLS 已启用
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 允许 service_role 进行所有操作（这是最重要的）
CREATE POLICY "Service role full access" ON public.users
  FOR ALL 
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 允许任何人插入用户（用于注册）
CREATE POLICY "Allow user registration" ON public.users
  FOR INSERT 
  WITH CHECK (true);

-- 允许用户查看自己的资料
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT 
  USING (auth.uid() = id);

-- 允许用户更新自己的资料
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE 
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 允许用户删除自己的账户
CREATE POLICY "Users can delete own account" ON public.users
  FOR DELETE 
  USING (auth.uid() = id);

-- 验证策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';