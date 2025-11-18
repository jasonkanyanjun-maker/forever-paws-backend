import React, { useState, useEffect } from 'react';
import {
  Card,
  Table,
  Button,
  Space,
  Tag,
  Modal,
  Form,
  Input,
  Select,
  message,
  Popconfirm,
  Typography,
  Row,
  Col,
  Statistic,
  Avatar,
  Tooltip,
  Badge,
} from 'antd';
import {
  UserOutlined,
  EditOutlined,
  DeleteOutlined,
  LockOutlined,
  UnlockOutlined,
  ReloadOutlined,
  ExportOutlined,
  SearchOutlined,
  PlusOutlined,
  EyeOutlined,
} from '@ant-design/icons';
import { UserService } from '@/services/userService';
import { User, QueryParams } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { Option } = Select;
const { Search } = Input;

const UserManagement: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<User[]>([]);
  const [userStats, setUserStats] = useState<any>(null);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const [filters, setFilters] = useState<QueryParams>({});
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  
  // 模态框状态
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [viewModalVisible, setViewModalVisible] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [viewingUser, setViewingUser] = useState<User | null>(null);
  const [form] = Form.useForm();

  // 加载用户数据
  const loadUsers = async () => {
    try {
      setLoading(true);
      const params: QueryParams = {
        page: pagination.current,
        pageSize: pagination.pageSize,
        ...filters,
      };

      const [usersResult, statsData] = await Promise.all([
        UserService.getUsers(params),
        UserService.getUserStats(),
      ]);

      setUsers(usersResult.data);
      setPagination(prev => ({ ...prev, total: usersResult.pagination.total }));
      setUserStats(statsData);
    } catch (error: any) {
      message.error(error.message);
    } finally {
      setLoading(false);
    }
  };

  // 处理表格变化
  const handleTableChange = (newPagination: any, tableFilters: any, sorter: any) => {
    setPagination(newPagination);
    const newFilters: QueryParams = { ...filters };
    
    if (sorter.field) {
      newFilters.sortBy = sorter.field;
      newFilters.sortOrder = sorter.order === 'ascend' ? 'asc' : 'desc';
    }
    
    setFilters(newFilters);
  };

  // 处理搜索
  const handleSearch = (value: string) => {
    setFilters({ ...filters, search: value });
    setPagination({ ...pagination, current: 1 });
  };

  // 处理筛选
  const handleFilter = (key: string, value: any) => {
    setFilters({ ...filters, [key]: value });
    setPagination({ ...pagination, current: 1 });
  };

  // 查看用户详情
  const handleViewUser = async (user: User) => {
    try {
      const userDetail = await UserService.getUserById(user.id);
      setViewingUser(userDetail);
      setViewModalVisible(true);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 编辑用户
  const handleEditUser = (user: User) => {
    setEditingUser(user);
    form.setFieldsValue({
      username: user.username,
      email: user.email,
      phone: user.phone,
      status: user.status,
    });
    setEditModalVisible(true);
  };

  // 保存用户编辑
  const handleSaveUser = async (values: any) => {
    try {
      if (editingUser) {
        await UserService.updateUser(editingUser.id, values);
        message.success('更新用户信息成功');
        setEditModalVisible(false);
        setEditingUser(null);
        form.resetFields();
        await loadUsers();
      }
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 切换用户状态
  const handleToggleStatus = async (user: User) => {
    try {
      const newStatus = user.status === 'active' ? 'inactive' : 'active';
      await UserService.toggleUserStatus(user.id, newStatus);
      message.success(`${newStatus === 'active' ? '启用' : '禁用'}用户成功`);
      await loadUsers();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 删除用户
  const handleDeleteUser = async (user: User) => {
    try {
      await UserService.deleteUser(user.id);
      message.success('删除用户成功');
      await loadUsers();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 重置密码
  const handleResetPassword = async (user: User) => {
    try {
      const result = await UserService.resetUserPassword(user.id);
      Modal.info({
        title: '密码重置成功',
        content: (
          <div>
            <p>用户 <strong>{user.username}</strong> 的新密码为：</p>
            <p style={{ fontSize: '16px', fontWeight: 'bold', color: '#1890ff' }}>
              {result.newPassword}
            </p>
            <p style={{ color: '#999' }}>请将新密码告知用户，并提醒用户及时修改密码。</p>
          </div>
        ),
      });
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 导出用户数据
  const handleExport = async () => {
    try {
      const blob = await UserService.exportUsers(filters);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `users-${dayjs().format('YYYY-MM-DD')}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      message.success('导出成功');
    } catch (error: any) {
      message.error(error.message);
    }
  };

  useEffect(() => {
    loadUsers();
  }, [pagination.current, pagination.pageSize, filters]);

  // 表格列定义
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      sorter: true,
    },
    {
      title: '用户信息',
      key: 'userInfo',
      width: 200,
      render: (record: User) => (
        <Space>
          <Avatar
            src={record.avatar_url}
            icon={<UserOutlined />}
            size="large"
          />
          <div>
            <div style={{ fontWeight: 'bold' }}>{record.username}</div>
            <div style={{ color: '#999', fontSize: '12px' }}>{record.email}</div>
          </div>
        </Space>
      ),
    },
    {
      title: '手机号',
      dataIndex: 'phone',
      key: 'phone',
      width: 120,
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'active' ? 'green' : 'red'}>
          {status === 'active' ? '正常' : '禁用'}
        </Tag>
      ),
    },
    {
      title: 'API使用情况',
      key: 'apiUsage',
      width: 150,
      render: (record: User) => (
        <Space direction="vertical" size="small">
          <div>
            <Text type="secondary">对话: </Text>
            <Badge count={record.conversation_used || 0} showZero color="#1890ff" />
          </div>
          <div>
            <Text type="secondary">视频: </Text>
            <Badge count={record.video_used || 0} showZero color="#52c41a" />
          </div>
        </Space>
      ),
    },
    {
      title: '注册时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm'),
      sorter: true,
    },
    {
      title: '最后登录',
      dataIndex: 'last_login_at',
      key: 'last_login_at',
      width: 160,
      render: (date: string) => date ? dayjs(date).format('YYYY-MM-DD HH:mm') : '-',
      sorter: true,
    },
    {
      title: '操作',
      key: 'actions',
      width: 200,
      fixed: 'right' as const,
      render: (record: User) => (
        <Space>
          <Tooltip title="查看详情">
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => handleViewUser(record)}
            />
          </Tooltip>
          <Tooltip title="编辑">
            <Button
              type="text"
              icon={<EditOutlined />}
              onClick={() => handleEditUser(record)}
            />
          </Tooltip>
          <Tooltip title={record.status === 'active' ? '禁用' : '启用'}>
            <Button
              type="text"
              icon={record.status === 'active' ? <LockOutlined /> : <UnlockOutlined />}
              onClick={() => handleToggleStatus(record)}
            />
          </Tooltip>
          <Tooltip title="重置密码">
            <Popconfirm
              title="确定要重置该用户的密码吗？"
              onConfirm={() => handleResetPassword(record)}
            >
              <Button type="text" icon={<LockOutlined />} />
            </Popconfirm>
          </Tooltip>
          <Tooltip title="删除">
            <Popconfirm
              title="确定要删除该用户吗？此操作不可恢复！"
              onConfirm={() => handleDeleteUser(record)}
            >
              <Button type="text" danger icon={<DeleteOutlined />} />
            </Popconfirm>
          </Tooltip>
        </Space>
      ),
    },
  ];

  // 行选择配置
  const rowSelection = {
    selectedRowKeys,
    onChange: setSelectedRowKeys,
  };

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题和操作 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2} style={{ margin: 0 }}>
          用户管理
        </Title>
        <Space>
          <Button icon={<ExportOutlined />} onClick={handleExport}>
            导出数据
          </Button>
          <Button icon={<ReloadOutlined />} onClick={loadUsers} loading={loading}>
            刷新
          </Button>
        </Space>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="总用户数"
              value={userStats?.totalUsers || 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="活跃用户"
              value={userStats?.activeUsers || 0}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="今日新增"
              value={userStats?.todayNewUsers || 0}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="本月新增"
              value={userStats?.monthNewUsers || 0}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 筛选器 */}
      <Card style={{ marginBottom: '16px' }}>
        <Row gutter={16}>
          <Col xs={24} sm={8} md={6}>
            <Search
              placeholder="搜索用户名、邮箱或手机号"
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={8} md={6}>
            <Select
              placeholder="用户状态"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilter('status', value)}
            >
              <Option value="active">正常</Option>
              <Option value="inactive">禁用</Option>
            </Select>
          </Col>
          <Col xs={24} sm={8} md={6}>
            <Select
              placeholder="排序方式"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => {
                if (value) {
                  const [sortBy, sortOrder] = value.split('-');
                  setFilters({ ...filters, sortBy, sortOrder });
                } else {
                  const newFilters = { ...filters };
                  delete newFilters.sortBy;
                  delete newFilters.sortOrder;
                  setFilters(newFilters);
                }
              }}
            >
              <Option value="created_at-desc">注册时间（新到旧）</Option>
              <Option value="created_at-asc">注册时间（旧到新）</Option>
              <Option value="last_login_at-desc">最后登录（新到旧）</Option>
              <Option value="username-asc">用户名（A-Z）</Option>
            </Select>
          </Col>
        </Row>
      </Card>

      {/* 用户表格 */}
      <Card>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          rowSelection={rowSelection}
          pagination={{
            current: pagination.current,
            pageSize: pagination.pageSize,
            total: pagination.total,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
          }}
          onChange={handleTableChange}
          loading={loading}
          scroll={{ x: 1200 }}
        />
      </Card>

      {/* 编辑用户模态框 */}
      <Modal
        title="编辑用户信息"
        open={editModalVisible}
        onCancel={() => {
          setEditModalVisible(false);
          setEditingUser(null);
          form.resetFields();
        }}
        onOk={() => form.submit()}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSaveUser}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="username"
                label="用户名"
                rules={[{ required: true, message: '请输入用户名' }]}
              >
                <Input placeholder="用户名" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="email"
                label="邮箱"
                rules={[
                  { required: true, message: '请输入邮箱' },
                  { type: 'email', message: '请输入有效的邮箱地址' },
                ]}
              >
                <Input placeholder="邮箱" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="phone"
                label="手机号"
              >
                <Input placeholder="手机号" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="status"
                label="状态"
                rules={[{ required: true, message: '请选择状态' }]}
              >
                <Select placeholder="选择状态">
                  <Option value="active">正常</Option>
                  <Option value="inactive">禁用</Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>

      {/* 查看用户详情模态框 */}
      <Modal
        title="用户详情"
        open={viewModalVisible}
        onCancel={() => {
          setViewModalVisible(false);
          setViewingUser(null);
        }}
        footer={null}
        width={800}
      >
        {viewingUser && (
          <div>
            <Row gutter={[16, 16]}>
              <Col span={24}>
                <Card title="基本信息">
                  <Row gutter={16}>
                    <Col span={8}>
                      <div style={{ textAlign: 'center' }}>
                        <Avatar
                          src={viewingUser.avatar_url}
                          icon={<UserOutlined />}
                          size={80}
                        />
                        <div style={{ marginTop: '8px', fontWeight: 'bold' }}>
                          {viewingUser.username}
                        </div>
                      </div>
                    </Col>
                    <Col span={16}>
                      <Space direction="vertical" style={{ width: '100%' }}>
                        <div><Text strong>用户ID:</Text> {viewingUser.id}</div>
                        <div><Text strong>邮箱:</Text> {viewingUser.email}</div>
                        <div><Text strong>手机号:</Text> {viewingUser.phone || '-'}</div>
                        <div>
                          <Text strong>状态:</Text>{' '}
                          <Tag color={viewingUser.status === 'active' ? 'green' : 'red'}>
                            {viewingUser.status === 'active' ? '正常' : '禁用'}
                          </Tag>
                        </div>
                        <div><Text strong>注册时间:</Text> {dayjs(viewingUser.created_at).format('YYYY-MM-DD HH:mm:ss')}</div>
                        <div><Text strong>最后登录:</Text> {viewingUser.last_login_at ? dayjs(viewingUser.last_login_at).format('YYYY-MM-DD HH:mm:ss') : '-'}</div>
                      </Space>
                    </Col>
                  </Row>
                </Card>
              </Col>
              <Col span={12}>
                <Card title="API使用统计">
                  <Space direction="vertical" style={{ width: '100%' }}>
                    <div>
                      <Text strong>对话API使用:</Text> {viewingUser.conversation_used || 0} 次
                    </div>
                    <div>
                      <Text strong>视频生成API使用:</Text> {viewingUser.video_used || 0} 次
                    </div>
                    <div>
                      <Text strong>总API调用:</Text> {(viewingUser.conversation_used || 0) + (viewingUser.video_used || 0)} 次
                    </div>
                  </Space>
                </Card>
              </Col>
              <Col span={12}>
                <Card title="账户信息">
                  <Space direction="vertical" style={{ width: '100%' }}>
                    <div><Text strong>账户余额:</Text> ¥{viewingUser.balance?.toFixed(2) || '0.00'}</div>
                    <div><Text strong>累计消费:</Text> ¥{viewingUser.total_spent?.toFixed(2) || '0.00'}</div>
                    <div><Text strong>会员等级:</Text> {viewingUser.membership_level || '普通用户'}</div>
                  </Space>
                </Card>
              </Col>
            </Row>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default UserManagement;