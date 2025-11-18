-- 删除 family 相关表和字段
-- 这个迁移将完全移除 family 功能模块

-- 删除 family 相关的 RLS 策略（如果存在）
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'family_members') THEN
        DROP POLICY IF EXISTS "Users can view their family members" ON public.family_members;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'families') THEN
        DROP POLICY IF EXISTS "Users can manage their family" ON public.families;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'family_pets') THEN
        DROP POLICY IF EXISTS "Family members can view family pets" ON public.family_pets;
    END IF;
END $$;

-- 删除 family 相关的触发器（如果存在）
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'update_families_updated_at') THEN
        DROP TRIGGER update_families_updated_at ON public.families;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'update_family_members_updated_at') THEN
        DROP TRIGGER update_family_members_updated_at ON public.family_members;
    END IF;
END $$;

-- 删除 family_pets 表（如果存在）
DROP TABLE IF EXISTS public.family_pets CASCADE;

-- 删除 family_members 表
DROP TABLE IF EXISTS public.family_members CASCADE;

-- 删除 families 表
DROP TABLE IF EXISTS public.families CASCADE;

-- 删除 family_groups 表
DROP TABLE IF EXISTS public.family_groups CASCADE;

-- 从 pets 表中删除 family_id 字段（如果存在）
ALTER TABLE public.pets DROP COLUMN IF EXISTS family_id;

-- 从 users 表中删除 family 相关字段（如果存在）
ALTER TABLE public.users DROP COLUMN IF EXISTS family_id;

-- 删除 family 相关的函数（如果存在）
DROP FUNCTION IF EXISTS get_family_members(uuid);
DROP FUNCTION IF EXISTS create_family_invite_code();
DROP FUNCTION IF EXISTS join_family_by_code(text);

-- 删除 family 相关的索引（如果存在）
DROP INDEX IF EXISTS idx_families_invite_code;
DROP INDEX IF EXISTS idx_family_members_family_id;
DROP INDEX IF EXISTS idx_family_members_user_id;
DROP INDEX IF EXISTS idx_family_pets_family_id;