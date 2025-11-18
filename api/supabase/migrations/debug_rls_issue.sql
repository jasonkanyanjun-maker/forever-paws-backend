-- 调试 RLS 问题
-- Debug RLS issue

-- 检查当前 RLS 状态
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- 检查当前策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

-- 检查当前用户角色
SELECT current_user, session_user, current_setting('role');

-- 检查 auth.uid() 函数
SELECT auth.uid();

-- 测试插入权限（这应该会失败并显示详细错误）
INSERT INTO public.users (id, username, email, full_name, display_name, provider, preferences)
VALUES (
  gen_random_uuid(),
  'testuser_' || extract(epoch from now())::text,
  'test_' || extract(epoch from now())::text || '@example.com',
  'Test User',
  'Test User',
  'email',
  '{"theme":{"mode":"system","language":"en"},"privacy":{"profile_visibility":"private"},"notifications":{"push":true,"email":true,"order_updates":true,"video_completed":true}}'::jsonb
);