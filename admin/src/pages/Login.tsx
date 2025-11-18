import React, { useState } from 'react';
import { Form, Input, Button, Card, message, Checkbox } from 'antd';
import { UserOutlined, LockOutlined, EyeInvisibleOutlined, EyeTwoTone } from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { AuthService } from '@/services/authService';
import { LoginFormData } from '@/types';

const Login: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuthStore();

  const from = (location.state as any)?.from?.pathname || '/admin/dashboard';

  const onFinish = async (values: LoginFormData & { remember: boolean }) => {
    setLoading(true);
    try {
      const response = await AuthService.login({
        username: values.username,
        password: values.password,
      });

      if (response.success) {
        login(response.admin, response.token);
        message.success('登录成功！');
        navigate(from, { replace: true });
      } else {
        message.error('登录失败，请检查用户名和密码');
      }
    } catch (error: any) {
      message.error(error.message || '登录失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-500 rounded-full mb-4">
            <span className="text-white text-2xl font-bold">FP</span>
          </div>
          <h1 className="text-3xl font-bold text-gray-800 mb-2">Forever Paws</h1>
          <p className="text-gray-600">后台管理系统</p>
        </div>

        <Card className="shadow-lg border-0">
          <Form
            name="login"
            initialValues={{ remember: true }}
            onFinish={onFinish}
            size="large"
            layout="vertical"
          >
            <Form.Item
              name="username"
              label="用户名"
              rules={[
                { required: true, message: '请输入用户名' },
                { min: 3, message: '用户名至少3个字符' },
              ]}
            >
              <Input
                prefix={<UserOutlined className="text-gray-400" />}
                placeholder="请输入用户名"
                autoComplete="username"
              />
            </Form.Item>

            <Form.Item
              name="password"
              label="密码"
              rules={[
                { required: true, message: '请输入密码' },
                { min: 6, message: '密码至少6个字符' },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined className="text-gray-400" />}
                placeholder="请输入密码"
                autoComplete="current-password"
                iconRender={(visible) => (visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />)}
              />
            </Form.Item>

            <Form.Item>
              <div className="flex items-center justify-between">
                <Form.Item name="remember" valuePropName="checked" noStyle>
                  <Checkbox>记住登录状态</Checkbox>
                </Form.Item>
                <Button type="link" className="p-0 h-auto">
                  忘记密码？
                </Button>
              </div>
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                loading={loading}
                className="w-full h-12 text-base font-medium"
              >
                {loading ? '登录中...' : '登录'}
              </Button>
            </Form.Item>
          </Form>

          <div className="mt-6 text-center text-sm text-gray-500">
            <p>默认管理员账户</p>
            <p className="mt-1">
              用户名: <span className="font-mono bg-gray-100 px-2 py-1 rounded">admin</span>
            </p>
            <p className="mt-1">
              密码: <span className="font-mono bg-gray-100 px-2 py-1 rounded">admin123</span>
            </p>
          </div>
        </Card>

        <div className="mt-8 text-center text-xs text-gray-400">
          <p>&copy; 2024 Forever Paws. All rights reserved.</p>
        </div>
      </div>
    </div>
  );
};

export default Login;