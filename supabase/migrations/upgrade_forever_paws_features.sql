-- Forever Paws 功能升级数据库迁移
-- 添加AI对话、付费系统和兑换码功能所需的表结构

-- 扩展现有profiles表，添加社交登录和视频额度字段
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS provider VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS provider_id VARCHAR(255);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name VARCHAR(100);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS video_credits INTEGER DEFAULT 0;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_profiles_provider ON public.profiles(provider, provider_id);

-- AI对话会话表
CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    session_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_pet_id ON public.chat_sessions(pet_id);

-- AI对话消息表
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at DESC);

-- 支付记录表
CREATE TABLE IF NOT EXISTS public.payment_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    purpose VARCHAR(100) DEFAULT 'video_generation',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_records_user_id ON public.payment_records(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_transaction_id ON public.payment_records(transaction_id);

-- 兑换码表
CREATE TABLE IF NOT EXISTS public.redeem_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    video_credits INTEGER DEFAULT 1,
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_redeem_codes_code ON public.redeem_codes(code);
CREATE INDEX IF NOT EXISTS idx_redeem_codes_active ON public.redeem_codes(is_active);

-- 兑换码使用记录表
CREATE TABLE IF NOT EXISTS public.redeem_code_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    redeem_code_id UUID REFERENCES public.redeem_codes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(redeem_code_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_redeem_code_usage_code_id ON public.redeem_code_usage(redeem_code_id);
CREATE INDEX IF NOT EXISTS idx_redeem_code_usage_user_id ON public.redeem_code_usage(user_id);

-- 插入示例兑换码
INSERT INTO public.redeem_codes (code, description, video_credits, expires_at) VALUES
('WELCOME2024', '新用户欢迎码', 1, NOW() + INTERVAL '30 days'),
('FREEVIDEO', '免费视频生成码', 1, NOW() + INTERVAL '7 days'),
('TESTCODE', '测试兑换码', 1, NOW() + INTERVAL '1 day')
ON CONFLICT (code) DO NOTHING;

-- 为匿名和认证用户授予权限
GRANT SELECT ON chat_sessions TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON chat_sessions TO authenticated;

GRANT SELECT ON chat_messages TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON chat_messages TO authenticated;

GRANT SELECT ON payment_records TO authenticated;
GRANT INSERT, UPDATE ON payment_records TO authenticated;

GRANT SELECT ON redeem_codes TO anon, authenticated;
GRANT SELECT ON redeem_code_usage TO authenticated;
GRANT INSERT ON redeem_code_usage TO authenticated;

-- 行级安全策略 (RLS)

-- 启用RLS
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redeem_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redeem_code_usage ENABLE ROW LEVEL SECURITY;

-- chat_sessions 策略
CREATE POLICY "Users can view their own chat sessions" ON public.chat_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own chat sessions" ON public.chat_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat sessions" ON public.chat_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chat sessions" ON public.chat_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- chat_messages 策略
CREATE POLICY "Users can view messages from their sessions" ON public.chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_sessions 
            WHERE chat_sessions.id = chat_messages.session_id 
            AND chat_sessions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages in their sessions" ON public.chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chat_sessions 
            WHERE chat_sessions.id = chat_messages.session_id 
            AND chat_sessions.user_id = auth.uid()
        )
    );

-- payment_records 策略
CREATE POLICY "Users can view their own payment records" ON public.payment_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own payment records" ON public.payment_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- redeem_codes 策略 (只读，管理员管理)
CREATE POLICY "Anyone can view active redeem codes" ON public.redeem_codes
    FOR SELECT USING (is_active = true);

-- redeem_code_usage 策略
CREATE POLICY "Users can view their own redeem code usage" ON public.redeem_code_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own redeem code usage" ON public.redeem_code_usage
    FOR INSERT WITH CHECK (auth.uid() = user_id);