-- 清理测试用户数据脚本
-- 邮箱: test.user@example.com

-- 首先查看用户是否存在
SELECT 'Checking auth.users table:' as step;
SELECT id, email, created_at, email_confirmed_at, last_sign_in_at
FROM auth.users 
WHERE email = 'test.user@example.com';

SELECT 'Checking public.users table:' as step;
SELECT id, email, username, display_name, created_at 
FROM public.users 
WHERE email = 'test.user@example.com';

-- 删除 public.users 表中的记录
DELETE FROM public.users 
WHERE email = 'test.user@example.com';

-- 删除 auth.users 表中的记录（需要使用 service_role 权限）
DELETE FROM auth.users 
WHERE email = 'test.user@example.com';

-- 验证删除结果
SELECT 'Verification - auth.users:' as step;
SELECT COUNT(*) as remaining_auth_users
FROM auth.users 
WHERE email = 'test.user@example.com';

SELECT 'Verification - public.users:' as step;
SELECT COUNT(*) as remaining_public_users
FROM public.users 
WHERE email = 'test.user@example.com';

SELECT 'Cleanup completed for test.user@example.com' as result;