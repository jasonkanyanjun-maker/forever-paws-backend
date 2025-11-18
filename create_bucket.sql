-- 创建images bucket用于存储图片文件
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'images',
    'images', 
    true,  -- 设置为public，允许公开访问
    10485760,  -- 10MB文件大小限制
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']  -- 允许的图片MIME类型
)
ON CONFLICT (id) DO NOTHING;  -- 如果bucket已存在则忽略

-- 创建RLS策略允许所有用户上传和读取图片
CREATE POLICY "Allow public uploads" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow public downloads" ON storage.objects
FOR SELECT USING (bucket_id = 'images');