-- Forever Paws 后台管理系统数据库表结构
-- 创建时间: 2024-12-23

-- 1. 创建管理员用户表
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'admin' CHECK (role IN ('super_admin', 'admin', 'operator')),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建管理员用户表索引
CREATE INDEX IF NOT EXISTS idx_admin_users_username ON admin_users(username);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_is_active ON admin_users(is_active);

-- 插入默认超级管理员账户 (密码: admin123)
INSERT INTO admin_users (username, password_hash, role, email) VALUES
('admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PmvlmO', 'super_admin', 'admin@foreverpaws.com')
ON CONFLICT (username) DO NOTHING;

-- 2. 创建用户API限额表
CREATE TABLE IF NOT EXISTS user_api_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    daily_conversation_limit INTEGER DEFAULT 50,
    daily_video_limit INTEGER DEFAULT 10,
    monthly_total_limit INTEGER DEFAULT 1000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建用户API限额表索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_api_limits_user_id ON user_api_limits(user_id);

-- 3. 创建API调用日志表
CREATE TABLE IF NOT EXISTS api_call_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    api_type VARCHAR(20) NOT NULL CHECK (api_type IN ('conversation', 'video')),
    model_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255),
    tokens_used INTEGER,
    cost DECIMAL(10,4) DEFAULT 0,
    response_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    request_data JSONB,
    response_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建API调用日志表索引
CREATE INDEX IF NOT EXISTS idx_api_call_logs_user_id ON api_call_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_api_call_logs_api_type ON api_call_logs(api_type);
CREATE INDEX IF NOT EXISTS idx_api_call_logs_created_at ON api_call_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_call_logs_success ON api_call_logs(success);
-- 创建按日期分区的索引（用于快速查询每日统计）
-- 暂时移除复杂索引，后续可以通过查询优化
-- CREATE INDEX IF NOT EXISTS idx_api_call_logs_date_user ON api_call_logs(date_trunc('day', created_at), user_id, api_type);

-- 4. 创建商品表
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建商品表索引
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);

-- 5. 创建库存表
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 10,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建库存表索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_stock_quantity ON inventory(stock_quantity);

-- 6. 订单表已存在，添加缺失的字段
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(100);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS notes TEXT;

-- 创建订单表索引
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 7. 创建订单项表
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建订单项表索引
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- 8. 创建管理员操作日志表
CREATE TABLE IF NOT EXISTS admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建管理员操作日志表索引
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON admin_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON admin_logs(created_at DESC);

-- 9. 创建API调用统计视图
CREATE OR REPLACE VIEW api_daily_stats AS
SELECT 
    DATE(created_at) as call_date,
    user_id,
    api_type,
    COUNT(*) as call_count,
    SUM(cost) as total_cost,
    AVG(response_time_ms) as avg_response_time,
    COUNT(CASE WHEN success = false THEN 1 END) as error_count
FROM api_call_logs
GROUP BY DATE(created_at), user_id, api_type;

-- 10. 创建用户每日API使用统计视图
CREATE OR REPLACE VIEW user_daily_api_usage AS
SELECT 
    user_id,
    DATE(created_at) as usage_date,
    SUM(CASE WHEN api_type = 'conversation' THEN 1 ELSE 0 END) as conversation_calls,
    SUM(CASE WHEN api_type = 'video' THEN 1 ELSE 0 END) as video_calls,
    COUNT(*) as total_calls,
    SUM(cost) as daily_cost
FROM api_call_logs
WHERE success = true
GROUP BY user_id, DATE(created_at);

-- 11. 为现有用户创建默认API限额
INSERT INTO user_api_limits (user_id) 
SELECT id FROM users 
WHERE id NOT IN (SELECT user_id FROM user_api_limits WHERE user_id IS NOT NULL)
ON CONFLICT (user_id) DO NOTHING;

-- 12. 插入示例商品数据
INSERT INTO products (name, description, price, category) VALUES
('宠物纪念相框', '精美的宠物纪念相框，可定制宠物照片', 89.99, '纪念用品'),
('宠物骨灰盒', '高品质木质宠物骨灰盒，刻字定制', 199.99, '纪念用品'),
('宠物纪念项链', '925银宠物纪念项链，可刻字', 129.99, '纪念饰品'),
('宠物纪念石', '天然石材宠物纪念石，户外纪念', 79.99, '纪念用品'),
('宠物纪念册', '精装宠物纪念册，记录美好回忆', 59.99, '纪念用品')
ON CONFLICT DO NOTHING;

-- 13. 为商品创建库存记录
INSERT INTO inventory (product_id, stock_quantity, low_stock_threshold)
SELECT id, 50, 10 FROM products
WHERE id NOT IN (SELECT product_id FROM inventory WHERE product_id IS NOT NULL)
ON CONFLICT (product_id) DO NOTHING;

-- 14. 插入示例订单数据
INSERT INTO orders (user_id, status, total_amount, shipping_address)
SELECT 
    u.id,
    CASE 
        WHEN random() < 0.2 THEN 'pending'::order_status
        WHEN random() < 0.4 THEN 'paid'::order_status
        WHEN random() < 0.6 THEN 'processing'::order_status
        WHEN random() < 0.8 THEN 'shipped'::order_status
        ELSE 'delivered'::order_status
    END,
    (random() * 300 + 50)::DECIMAL(10,2),
    jsonb_build_object(
        'street', '北京市朝阳区示例地址' || floor(random() * 100 + 1)::text || '号',
        'city', '北京市',
        'country', '中国'
    )
FROM users u
LIMIT 10
ON CONFLICT DO NOTHING;

-- 15. 插入示例API调用日志数据
INSERT INTO api_call_logs (user_id, api_type, model_name, endpoint, tokens_used, cost, response_time_ms, success)
SELECT 
    u.id,
    CASE WHEN random() < 0.7 THEN 'conversation' ELSE 'video' END,
    CASE WHEN random() < 0.5 THEN 'gpt-3.5-turbo' ELSE 'qwen-turbo' END,
    '/api/letters/generate',
    floor(random() * 1000 + 100)::INTEGER,
    (random() * 0.1 + 0.01)::DECIMAL(10,4),
    floor(random() * 2000 + 500)::INTEGER,
    random() < 0.95
FROM users u
CROSS JOIN generate_series(1, 5)
LIMIT 100
ON CONFLICT DO NOTHING;

-- 16. 设置RLS策略
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_api_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

-- 管理员表只允许认证用户访问
CREATE POLICY "Admin users can be accessed by authenticated users" ON admin_users
    FOR ALL USING (auth.role() = 'authenticated');

-- API限额表允许用户查看自己的限额
CREATE POLICY "Users can view their own API limits" ON user_api_limits
    FOR SELECT USING (auth.uid() = user_id);

-- API调用日志允许用户查看自己的日志
CREATE POLICY "Users can view their own API logs" ON api_call_logs
    FOR SELECT USING (auth.uid() = user_id);

-- 商品表允许所有人查看
CREATE POLICY "Products are viewable by everyone" ON products
    FOR SELECT USING (true);

-- 库存表允许认证用户查看
CREATE POLICY "Inventory is viewable by authenticated users" ON inventory
    FOR SELECT USING (auth.role() = 'authenticated');

-- 订单表允许用户查看自己的订单
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

-- 订单项表允许通过订单查看
CREATE POLICY "Order items are viewable through orders" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- 管理员日志只允许管理员查看
CREATE POLICY "Admin logs are viewable by admins" ON admin_logs
    FOR SELECT USING (auth.role() = 'authenticated');

-- 授权给anon和authenticated角色
GRANT SELECT ON admin_users TO anon, authenticated;
GRANT ALL ON admin_users TO service_role;

GRANT SELECT ON user_api_limits TO anon, authenticated;
GRANT ALL ON user_api_limits TO service_role;

GRANT SELECT ON api_call_logs TO anon, authenticated;
GRANT ALL ON api_call_logs TO service_role;

GRANT SELECT ON products TO anon, authenticated;
GRANT ALL ON products TO service_role;

GRANT SELECT ON inventory TO anon, authenticated;
GRANT ALL ON inventory TO service_role;

GRANT SELECT ON orders TO anon, authenticated;
GRANT ALL ON orders TO service_role;

GRANT SELECT ON order_items TO anon, authenticated;
GRANT ALL ON order_items TO service_role;

GRANT SELECT ON admin_logs TO anon, authenticated;
GRANT ALL ON admin_logs TO service_role;

-- 授权视图访问权限
GRANT SELECT ON api_daily_stats TO anon, authenticated, service_role;
GRANT SELECT ON user_daily_api_usage TO anon, authenticated, service_role;

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加更新时间触发器（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_admin_users_updated_at') THEN
        CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_api_limits_updated_at') THEN
        CREATE TRIGGER update_user_api_limits_updated_at BEFORE UPDATE ON user_api_limits
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_inventory_updated_at') THEN
        CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;