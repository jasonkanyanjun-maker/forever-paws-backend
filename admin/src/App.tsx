import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import AdminLayout from "@/components/Layout/AdminLayout";
import ProtectedRoute from "@/components/ProtectedRoute";
import Login from "@/pages/Login";
import Dashboard from "@/pages/Dashboard";
import UserManagement from "@/pages/UserManagement";
import ProductManagement from "@/pages/ProductManagement";
import InventoryManagement from "@/pages/InventoryManagement";
import OrderManagement from "@/pages/OrderManagement";
import ApiMonitor from "@/pages/ApiMonitor";
import SystemSettings from "@/pages/SystemSettings";

export default function App() {
  return (
    <ConfigProvider locale={zhCN}>
      <Router>
        <Routes>
          {/* 重定向根路径到管理后台 */}
          <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />
          
          {/* 登录页面 */}
          <Route path="/admin/login" element={<Login />} />
          
          {/* 受保护的管理后台路由 */}
          <Route path="/admin" element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }>
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="users" element={<UserManagement />} />
            <Route path="products" element={<ProductManagement />} />
            <Route path="inventory" element={<InventoryManagement />} />
            <Route path="orders" element={<OrderManagement />} />
            <Route path="api-monitoring" element={<ApiMonitor />} />
            <Route path="settings" element={
              <ProtectedRoute requiredRole="admin">
                <SystemSettings />
              </ProtectedRoute>
            } />
          </Route>
          
          {/* 404页面 */}
          <Route path="*" element={
            <div className="flex items-center justify-center min-h-screen">
              <div className="text-center">
                <h1 className="text-4xl font-bold text-gray-800 mb-4">404</h1>
                <p className="text-gray-600 mb-4">页面未找到</p>
                <button
                  onClick={() => window.history.back()}
                  className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                >
                  返回上一页
                </button>
              </div>
            </div>
          } />
        </Routes>
      </Router>
    </ConfigProvider>
  );
}
