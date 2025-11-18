import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase';
import { authenticateAdmin } from '../middleware/adminAuth';

const router = Router();

// 管理员登录
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: '用户名和密码不能为空' });
    }

    // 查询管理员用户
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('*')
      .eq('username', username)
      .eq('is_active', true)
      .single();

    if (error || !admin) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    // 验证密码
    const isValidPassword = await bcrypt.compare(password, admin.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    // 更新最后登录时间
    await supabase
      .from('admin_users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', admin.id);

    // 生成JWT token
    const token = jwt.sign(
      { 
        adminId: admin.id, 
        username: admin.username,
        role: admin.role 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    // 记录登录日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: admin.id,
        action: 'login',
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        email: admin.email,
        role: admin.role,
        last_login_at: admin.last_login_at
      }
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: '登录失败' });
  }
});

// 获取管理员信息
router.get('/profile', authenticateAdmin, async (req, res) => {
  try {
    const adminId = req.admin?.adminId;

    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('id, username, email, role, created_at, last_login_at')
      .eq('id', adminId)
      .single();

    if (error || !admin) {
      return res.status(404).json({ error: '管理员不存在' });
    }

    res.json(admin);
  } catch (error) {
    console.error('Get admin profile error:', error);
    res.status(500).json({ error: '获取管理员信息失败' });
  }
});

// 修改密码
router.put('/password', authenticateAdmin, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const adminId = req.admin?.adminId;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: '当前密码和新密码不能为空' });
    }

    // 获取当前管理员信息
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('password_hash')
      .eq('id', adminId)
      .single();

    if (error || !admin) {
      return res.status(404).json({ error: '管理员不存在' });
    }

    // 验证当前密码
    const isValidPassword = await bcrypt.compare(currentPassword, admin.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: '当前密码错误' });
    }

    // 加密新密码
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // 更新密码
    const { error: updateError } = await supabase
      .from('admin_users')
      .update({ password_hash: newPasswordHash })
      .eq('id', adminId);

    if (updateError) {
      throw updateError;
    }

    // 记录操作日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: adminId,
        action: 'change_password',
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({ message: '密码修改成功' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: '密码修改失败' });
  }
});

// 管理员登出
router.post('/logout', authenticateAdmin, async (req, res) => {
  try {
    const adminId = req.admin?.adminId;

    // 记录登出日志
    await supabase
      .from('admin_logs')
      .insert({
        admin_id: adminId,
        action: 'logout',
        ip_address: req.ip,
        user_agent: req.get('User-Agent')
      });

    res.json({ message: '登出成功' });
  } catch (error) {
    console.error('Admin logout error:', error);
    res.status(500).json({ error: '登出失败' });
  }
});

export default router;