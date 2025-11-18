-- 修复 users 表的 RLS 策略，允许用户注册
-- Fix users table RLS policies to allow user registration

-- 删除所有现有的 users 表策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can manage users" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;

-- 暂时禁用 RLS 来测试
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 重新启用 RLS 并创建更宽松的策略
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

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

-- 允许 service_role 进行所有操作
CREATE POLICY "Service role full access" ON public.users
  FOR ALL 
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');