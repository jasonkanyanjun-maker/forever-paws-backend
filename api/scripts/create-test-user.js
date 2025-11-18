const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function createTestUser() {
  try {
    console.log('🔧 Creating test user in Supabase...');
    
    // 首先创建auth用户
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: 'askme@gmail.com',
      password: '123456',
      email_confirm: true
    });

    if (authError) {
      console.error('❌ Auth user creation error:', authError);
      return;
    }

    console.log('✅ Auth user created:', authUser.user.id);

    // 然后在public.users表中创建用户记录
    const { data: publicUser, error: publicError } = await supabase
      .from('users')
      .insert({
        id: authUser.user.id,
        username: 'askme',
        email: 'askme@gmail.com',
        full_name: 'Test User',
        display_name: 'askme',
        provider: 'email',
        password_hash: await bcrypt.hash('123456', 12)
      })
      .select()
      .single();

    if (publicError) {
      console.error('❌ Public user creation error:', publicError);
      return;
    }

    console.log('✅ Public user created:', publicUser);
    console.log('✅ Test user setup complete!');

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  }
}

createTestUser();