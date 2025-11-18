-- 恢复适当的 RLS 策略以确保数据安全
-- Restore proper RLS policies to ensure data security

-- 重新启用 RLS
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

-- 验证 RLS 状态
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';