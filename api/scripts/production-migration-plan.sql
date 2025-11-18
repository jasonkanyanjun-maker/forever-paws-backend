-- Forever Paws 生产环境数据库迁移计划
-- Production Database Migration Plan
-- 执行前请确保已备份数据库

-- ============================================
-- 第一阶段：基础架构 (Foundation Schema)
-- ============================================

-- 1. 初始架构
\i 001_initial_schema.sql

-- 2. 创建 Forever Paws 核心架构
\i create_forever_paws_schema.sql

-- 3. 添加缺失的表
\i 002_add_missing_tables.sql

-- ============================================
-- 第二阶段：架构扩展 (Schema Extensions)
-- ============================================

-- 4. 扩展 Forever Paws 功能
\i extend_forever_paws_schema.sql

-- 5. 增强功能架构
\i create_enhanced_features_schema.sql

-- 6. 升级 Forever Paws 功能
\i upgrade_forever_paws_features.sql

-- ============================================
-- 第三阶段：存储配置 (Storage Configuration)
-- ============================================

-- 7. 创建图片存储桶
\i create_images_bucket.sql

-- ============================================
-- 第四阶段：基础 RLS 策略 (Basic RLS Policies)
-- ============================================

-- 8. 基础 RLS 策略
\i 003_rls_policies.sql

-- ============================================
-- 第五阶段：RLS 策略修复 (RLS Policy Fixes)
-- ============================================

-- 9. 修复用户 RLS 策略
\i fix_users_rls_policy_v3.sql

-- 10. 修复用户档案 RLS 策略
\i fix_user_profiles_rls_final.sql

-- 11. 修复宠物照片 RLS 策略 (最新版本)
\i fix_pet_photos_rls_v3.sql

-- 12. 修复家庭组 RLS 策略
\i fix_family_groups_rls_policies.sql

-- 13. 修复家庭组插入策略
\i fix_family_groups_insert_policy.sql

-- ============================================
-- 第六阶段：综合 RLS 修复 (Comprehensive RLS Fixes)
-- ============================================

-- 14. 综合 RLS 策略修复
\i fix_all_rls_policies_comprehensive.sql

-- ============================================
-- 第七阶段：权限验证 (Permission Verification)
-- ============================================

-- 15. 检查权限配置
\i check_permissions.sql

-- ============================================
-- 迁移后验证脚本 (Post-Migration Verification)
-- ============================================

-- 验证所有表是否存在
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 验证 RLS 是否启用
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true
ORDER BY tablename;

-- 验证策略是否创建
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 验证权限配置
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND grantee IN ('anon', 'authenticated') 
ORDER BY table_name, grantee;

-- 验证存储桶
SELECT name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
ORDER BY name;

-- ============================================
-- 清理脚本 (Cleanup Scripts)
-- ============================================

-- 如果需要重置 RLS 策略，可以使用以下文件：
-- \i complete_rls_reset.sql
-- \i open_rls_policies_completely.sql

-- ============================================
-- 注意事项 (Important Notes)
-- ============================================

/*
1. 执行迁移前请确保：
   - 已备份生产数据库
   - 在测试环境中验证过所有迁移
   - 确认 Supabase 项目配置正确

2. 迁移过程中：
   - 监控迁移执行状态
   - 记录任何错误信息
   - 准备回滚计划

3. 迁移完成后：
   - 运行验证脚本确认所有表和策略正确创建
   - 测试应用程序功能
   - 验证用户权限和数据访问

4. 如果遇到问题：
   - 检查 Supabase 日志
   - 运行 check_permissions.sql 验证权限
   - 必要时使用清理脚本重置策略

5. 性能优化：
   - 迁移完成后考虑添加必要的索引
   - 监控查询性能
   - 根据需要调整 RLS 策略
*/