import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Statistic,
  Table,
  Tag,
  Typography,
  Spin,
  Alert,
  Progress,
  List,
  Avatar,
  Space,
  Button,
  DatePicker,
  Select,
} from 'antd';
import {
  UserOutlined,
  ShoppingCartOutlined,
  DollarOutlined,
  ApiOutlined,
  ArrowUpOutlined,
  EyeOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { DashboardService } from '@/services/dashboardService';
import { DashboardStats } from '@/types';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;
const { Option } = Select;

const Dashboard: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [apiTrends, setApiTrends] = useState<any[]>([]);
  const [salesTrends, setSalesTrends] = useState<any[]>([]);
  const [recentActivities, setRecentActivities] = useState<any[]>([]);
  const [topProducts, setTopProducts] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // 加载仪表板数据
  const loadDashboardData = async () => {
    try {
      setError(null);
      const [statsData, trendsData, salesData, activitiesData, productsData] = await Promise.all([
        DashboardService.getDashboardStats(),
        DashboardService.getApiTrends(7),
        DashboardService.getSalesTrends(30),
        DashboardService.getRecentActivities(10),
        DashboardService.getTopProducts(5),
      ]);

      setStats(statsData);
      setApiTrends(trendsData);
      setSalesTrends(salesData);
      setRecentActivities(activitiesData);
      setTopProducts(productsData);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  // 刷新数据
  const handleRefresh = async () => {
    setRefreshing(true);
    await loadDashboardData();
  };

  useEffect(() => {
    loadDashboardData();
  }, []);

  // 图表颜色配置
  const COLORS = ['#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1'];

  // API调用类型分布数据
  const apiTypeData = stats ? [
    { name: '对话API', value: stats.apiStats.conversationCalls, color: '#1890ff' },
    { name: '视频生成API', value: stats.apiStats.videoCalls, color: '#52c41a' },
  ] : [];

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '400px' }}>
        <Spin size="large" />
      </div>
    );
  }

  if (error) {
    return (
      <Alert
        message="加载失败"
        description={error}
        type="error"
        showIcon
        action={
          <Button size="small" onClick={handleRefresh}>
            重试
          </Button>
        }
      />
    );
  }

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题和操作 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2} style={{ margin: 0 }}>
          仪表板
        </Title>
        <Space>
          <Button icon={<ReloadOutlined />} onClick={handleRefresh} loading={refreshing}>
            刷新
          </Button>
        </Space>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总用户数"
              value={stats?.totalUsers || 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总订单数"
              value={stats?.totalOrders || 0}
              prefix={<ShoppingCartOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总销售额"
              value={stats?.totalRevenue || 0}
              prefix={<DollarOutlined />}
              precision={2}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="API调用总数"
              value={stats?.totalApiCalls || 0}
              prefix={<ApiOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
      </Row>

      {/* AI API 概览 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} lg={12}>
          <Card title="AI API 调用统计" extra={<EyeOutlined />}>
            <Row gutter={16}>
              <Col span={12}>
                <Statistic
                  title="对话API调用"
                  value={stats?.apiStats.conversationCalls || 0}
                  valueStyle={{ color: '#1890ff' }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="视频生成API调用"
                  value={stats?.apiStats.videoCalls || 0}
                  valueStyle={{ color: '#52c41a' }}
                />
              </Col>
            </Row>
            <div style={{ marginTop: '16px' }}>
              <Text type="secondary">总成本: ¥{stats?.apiStats.totalCost?.toFixed(2) || '0.00'}</Text>
            </div>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="API调用类型分布">
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie
                  data={apiTypeData}
                  cx="50%"
                  cy="50%"
                  innerRadius={40}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {apiTypeData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* 趋势图表 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} lg={12}>
          <Card title="API调用趋势（最近7天）">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={apiTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="conversationCalls" stroke="#1890ff" name="对话API" />
                <Line type="monotone" dataKey="videoCalls" stroke="#52c41a" name="视频生成API" />
              </LineChart>
            </ResponsiveContainer>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="销售趋势（最近30天）">
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={salesTrends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="revenue" fill="#faad14" name="销售额" />
                <Bar dataKey="orders" fill="#1890ff" name="订单数" />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* 最近活动和热门商品 */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="最近活动" extra={<Button type="link">查看全部</Button>}>
            <List
              itemLayout="horizontal"
              dataSource={recentActivities}
              renderItem={(item) => (
                <List.Item>
                  <List.Item.Meta
                    avatar={<Avatar icon={<UserOutlined />} />}
                    title={item.action}
                    description={
                      <Space>
                        <Text type="secondary">{item.admin_name}</Text>
                        <Text type="secondary">{item.created_at}</Text>
                      </Space>
                    }
                  />
                  <Tag color={item.status === 'success' ? 'green' : 'red'}>
                    {item.status === 'success' ? '成功' : '失败'}
                  </Tag>
                </List.Item>
              )}
            />
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="热门商品" extra={<Button type="link">查看全部</Button>}>
            <List
              itemLayout="horizontal"
              dataSource={topProducts}
              renderItem={(item, index) => (
                <List.Item>
                  <List.Item.Meta
                    avatar={
                      <Avatar
                        src={item.image_url}
                        style={{ backgroundColor: COLORS[index % COLORS.length] }}
                      >
                        {item.name?.charAt(0)}
                      </Avatar>
                    }
                    title={item.name}
                    description={
                      <Space>
                        <Text>销量: {item.sales_count}</Text>
                        <Text>¥{item.price}</Text>
                      </Space>
                    }
                  />
                  <div>
                    <Progress
                      type="circle"
                      size={50}
                      percent={Math.min((item.sales_count / (topProducts[0]?.sales_count || 1)) * 100, 100)}
                      format={() => `#${index + 1}`}
                    />
                  </div>
                </List.Item>
              )}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;