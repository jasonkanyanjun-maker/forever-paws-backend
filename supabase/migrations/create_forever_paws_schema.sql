-- Forever Paws Pet Memorial App Database Schema
-- 创建完整的数据库架构

-- 用户配置表 (Supabase Auth 会自动处理 auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 宠物信息表
CREATE TABLE public.pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100),
    photo_url TEXT,
    birth_date DATE,
    memorial_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 视频生成表
CREATE TABLE public.videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    video_url TEXT,
    thumbnail_url TEXT,
    status VARCHAR(20) DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 信件表
CREATE TABLE public.letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 订阅表
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_type VARCHAR(20) DEFAULT 'free' CHECK (plan_type IN ('free', 'premium')),
    amount DECIMAL(10,2),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 纪念品产品表
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    customization_options JSONB,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 订单表
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 订单项目表
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    customization_data JSONB
);

-- 启用行级安全 (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略
-- 用户配置策略
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 宠物管理策略
CREATE POLICY "Users can manage own pets" ON public.pets
    FOR ALL USING (auth.uid() = user_id);

-- 视频管理策略
CREATE POLICY "Users can manage own videos" ON public.videos
    FOR ALL USING (auth.uid() = user_id);

-- 信件管理策略
CREATE POLICY "Users can manage own letters" ON public.letters
    FOR ALL USING (auth.uid() = user_id);

-- 订阅查看策略
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- 订单管理策略
CREATE POLICY "Users can manage own orders" ON public.orders
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- 创建索引以提高查询性能
CREATE INDEX idx_pets_user_id ON public.pets(user_id);
CREATE INDEX idx_videos_user_id ON public.videos(user_id);
CREATE INDEX idx_videos_pet_id ON public.videos(pet_id);
CREATE INDEX idx_videos_created_at ON public.videos(created_at DESC);
CREATE INDEX idx_letters_user_id ON public.letters(user_id);
CREATE INDEX idx_letters_pet_id ON public.letters(pet_id);
CREATE INDEX idx_letters_sent_at ON public.letters(sent_at DESC);
CREATE INDEX idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_products_category ON public.products(category);

-- 授予权限
GRANT SELECT ON public.products TO anon;
GRANT ALL PRIVILEGES ON public.profiles TO authenticated;
GRANT ALL PRIVILEGES ON public.pets TO authenticated;
GRANT ALL PRIVILEGES ON public.videos TO authenticated;
GRANT ALL PRIVILEGES ON public.letters TO authenticated;
GRANT ALL PRIVILEGES ON public.subscriptions TO authenticated;
GRANT ALL PRIVILEGES ON public.orders TO authenticated;
GRANT ALL PRIVILEGES ON public.order_items TO authenticated;

-- 插入示例纪念品产品数据
INSERT INTO public.products (name, description, price, category, image_url, customization_options) VALUES
('Custom Pet Tombstone', 'Beautiful granite tombstone with custom engraving for your beloved pet', 299.99, 'tombstone', 'https://example.com/tombstone.jpg', '{"materials": ["granite", "marble"], "sizes": ["small", "medium", "large"], "engravings": true}'),
('Fur Collection Necklace', 'Elegant necklace to hold a small amount of your pet''s fur as a keepsake', 89.99, 'jewelry', 'https://example.com/necklace.jpg', '{"metals": ["silver", "gold"], "chain_lengths": ["16in", "18in", "20in"], "pendant_shapes": ["heart", "paw", "circle"]}'),
('Memorial Photo Frame', 'Wooden photo frame with custom engraving for pet memorial photos', 49.99, 'frame', 'https://example.com/frame.jpg', '{"wood_types": ["oak", "pine", "walnut"], "sizes": ["5x7", "8x10", "11x14"], "engravings": true}'),
('Pet Memory Box', 'Handcrafted wooden box to store your pet''s favorite toys and memories', 79.99, 'box', 'https://example.com/memory_box.jpg', '{"wood_types": ["cedar", "pine", "oak"], "sizes": ["small", "medium", "large"], "interior_lining": ["velvet", "satin"]}'),
('Paw Print Keepsake', 'Clay impression kit to create a lasting paw print memorial', 24.99, 'keepsake', 'https://example.com/paw_print.jpg', '{"clay_colors": ["white", "terracotta", "gray"], "frame_included": true}');