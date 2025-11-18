-- Forever Paws Enhanced Features Migration
-- 照片管理与家庭共享系统数据库架构

-- 创建用户资料表
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100),
    avatar_url TEXT,
    hobbies JSONB DEFAULT '[]'::jsonb,
    preferences JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 宠物照片表
CREATE TABLE IF NOT EXISTS pet_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    crop_data JSONB,
    is_primary BOOLEAN DEFAULT false,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 家庭群组表
CREATE TABLE IF NOT EXISTS family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    invite_code VARCHAR(20) UNIQUE NOT NULL DEFAULT substring(md5(random()::text), 1, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 家庭成员表
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    permissions JSONB DEFAULT '["read"]'::jsonb,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_group_id, user_id)
);

-- 支持工单表
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    attachments JSONB DEFAULT '[]'::jsonb,
    admin_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_pet_photos_pet_id ON pet_photos(pet_id);
CREATE INDEX IF NOT EXISTS idx_pet_photos_is_primary ON pet_photos(is_primary) WHERE is_primary = true;
CREATE INDEX IF NOT EXISTS idx_family_members_family_group_id ON family_members(family_group_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_family_groups_invite_code ON family_groups(invite_code);

-- 设置权限
GRANT SELECT, INSERT, UPDATE ON user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_photos TO authenticated;
GRANT SELECT, INSERT, UPDATE ON family_groups TO authenticated;
GRANT SELECT, INSERT, UPDATE ON family_members TO authenticated;
GRANT SELECT, INSERT, UPDATE ON support_tickets TO authenticated;

-- 行级安全策略
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的资料
CREATE POLICY "Users can manage own profile" ON user_profiles
    FOR ALL USING (auth.uid() = user_id);

-- 用户可以访问自己宠物的照片
CREATE POLICY "Users can manage own pet photos" ON pet_photos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE pets.id = pet_photos.pet_id 
            AND pets.user_id = auth.uid()
        )
    );

-- 家庭成员可以查看共享内容
CREATE POLICY "Family members can view shared content" ON pet_photos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_members fm
            JOIN pets p ON p.user_id = fm.user_id
            WHERE fm.user_id = auth.uid()
            AND p.id = pet_photos.pet_id
            AND fm.status = 'active'
        )
    );

-- 家庭群组策略
CREATE POLICY "Users can manage own family groups" ON family_groups
    FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Family members can view group info" ON family_groups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_members 
            WHERE family_members.family_group_id = family_groups.id 
            AND family_members.user_id = auth.uid()
            AND family_members.status = 'active'
        )
    );

-- 家庭成员策略
CREATE POLICY "Group owners can manage members" ON family_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM family_groups 
            WHERE family_groups.id = family_members.family_group_id 
            AND family_groups.owner_id = auth.uid()
        )
    );

CREATE POLICY "Members can view own membership" ON family_members
    FOR SELECT USING (auth.uid() = user_id);

-- 支持工单策略
CREATE POLICY "Users can manage own tickets" ON support_tickets
    FOR ALL USING (auth.uid() = user_id);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表创建更新时间触发器
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON support_tickets FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 为宠物表添加个性特征字段（如果不存在）
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'personality_traits') THEN
        ALTER TABLE pets ADD COLUMN personality_traits JSONB DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- 为宠物表添加详细描述字段（如果不存在）
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'detailed_description') THEN
        ALTER TABLE pets ADD COLUMN detailed_description TEXT;
    END IF;
END $$;