-- Check current permissions for all tables
SELECT 
    grantee, 
    table_name, 
    privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
    AND grantee IN ('anon', 'authenticated') 
ORDER BY table_name, grantee;

-- Grant permissions for new tables if needed
-- For family_groups table
GRANT SELECT, INSERT, UPDATE, DELETE ON family_groups TO authenticated;
GRANT SELECT ON family_groups TO anon;

-- For family_members table
GRANT SELECT, INSERT, UPDATE, DELETE ON family_members TO authenticated;
GRANT SELECT ON family_members TO anon;

-- For pet_photos table
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_photos TO authenticated;
GRANT SELECT ON pet_photos TO anon;

-- For user_profiles table
GRANT SELECT, INSERT, UPDATE, DELETE ON user_profiles TO authenticated;
GRANT SELECT ON user_profiles TO anon;

-- For support_tickets table
GRANT SELECT, INSERT, UPDATE, DELETE ON support_tickets TO authenticated;
GRANT SELECT ON support_tickets TO anon;

-- Ensure all existing tables have proper permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON profiles TO authenticated;
GRANT SELECT ON profiles TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON pets TO authenticated;
GRANT SELECT ON pets TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON videos TO authenticated;
GRANT SELECT ON videos TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON letters TO authenticated;
GRANT SELECT ON letters TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON chat_sessions TO authenticated;
GRANT SELECT ON chat_sessions TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON chat_messages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO authenticated;
GRANT SELECT ON orders TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON order_items TO authenticated;
GRANT SELECT ON order_items TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON subscriptions TO authenticated;
GRANT SELECT ON subscriptions TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON payment_records TO authenticated;
GRANT SELECT ON payment_records TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON redeem_codes TO authenticated;
GRANT SELECT ON redeem_codes TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON redeem_code_usage TO authenticated;
GRANT SELECT ON redeem_code_usage TO anon;

-- Products table should be readable by all
GRANT SELECT ON products TO authenticated;
GRANT SELECT ON products TO anon;