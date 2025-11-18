-- 修复 users 表的外键约束问题
-- 删除现有的外键约束
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 重新创建外键约束，但是使用 ON DELETE CASCADE
-- 这样当 auth.users 中的用户被删除时，public.users 中的记录也会被删除
ALTER TABLE public.users 
ADD CONSTRAINT users_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- 确保 RLS 策略正确设置
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略允许用户访问自己的记录
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
FOR INSERT WITH CHECK (auth.uid() = id);