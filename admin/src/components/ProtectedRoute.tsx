import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { Spin } from 'antd';
import { useAuthStore } from '@/store/authStore';
import { AuthService } from '@/services/authService';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: 'super_admin' | 'admin' | 'moderator';
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  requiredRole 
}) => {
  const { isAuthenticated, admin, token, setLoading, isLoading, logout } = useAuthStore();
  const location = useLocation();

  useEffect(() => {
    const validateAuth = async () => {
      if (token && !isAuthenticated) {
        setLoading(true);
        try {
          // 验证token有效性
          const isValid = await AuthService.validateToken();
          if (!isValid) {
            logout();
            return;
          }

          // 获取最新的管理员信息
          const currentAdmin = await AuthService.getCurrentAdmin();
          useAuthStore.getState().login(currentAdmin, token);
        } catch (error) {
          console.error('验证身份失败:', error);
          logout();
        } finally {
          setLoading(false);
        }
      }
    };

    validateAuth();
  }, [token, isAuthenticated, setLoading, logout]);

  // 显示加载状态
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Spin size="large" tip="验证身份中..." />
      </div>
    );
  }

  // 未登录，重定向到登录页
  if (!isAuthenticated || !admin) {
    return <Navigate to="/admin/login" state={{ from: location }} replace />;
  }

  // 检查角色权限
  if (requiredRole) {
    const roleHierarchy = {
      'moderator': 1,
      'admin': 2,
      'super_admin': 3,
    };

    const userRoleLevel = roleHierarchy[admin.role];
    const requiredRoleLevel = roleHierarchy[requiredRole];

    if (userRoleLevel < requiredRoleLevel) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-800 mb-4">权限不足</h2>
            <p className="text-gray-600 mb-4">您没有访问此页面的权限</p>
            <button
              onClick={() => window.history.back()}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              返回上一页
            </button>
          </div>
        </div>
      );
    }
  }

  return <>{children}</>;
};

export default ProtectedRoute;