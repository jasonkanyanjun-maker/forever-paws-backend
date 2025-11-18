import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Table,
  Tag,
  Typography,
  Spin,
  Alert,
  Button,
  Space,
  DatePicker,
  Select,
  Input,
  Statistic,
  Modal,
  Form,
  InputNumber,
  message,
  Tabs,
  Progress,
  Tooltip,
} from 'antd';
import {
  ApiOutlined,
  DollarOutlined,
  UserOutlined,
  ReloadOutlined,
  ExportOutlined,
  EditOutlined,
  SearchOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts';
import { ApiMonitorService } from '@/services/apiMonitorService';
import { ApiCallLog, ApiStats, UserApiLimit, QueryParams } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;
const { Option } = Select;
const { Search } = Input;
const { TabPane } = Tabs;

const ApiMonitor: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [apiLogs, setApiLogs] = useState<ApiCallLog[]>([]);
  const [apiStats, setApiStats] = useState<ApiStats | null>(null);
  const [userLimits, setUserLimits] = useState<UserApiLimit[]>([]);
  const [apiTrends, setApiTrends] = useState<any[]>([]);
  const [costAnalysis, setCostAnalysis] = useState<any>(null);
  const [errorStats, setErrorStats] = useState<any[]>([]);
  const [realTimeStats, setRealTimeStats] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  
  // 分页和筛选状态
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const [filters, setFilters] = useState<QueryParams>({});
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  
  // 模态框状态
  const [limitModalVisible, setLimitModalVisible] = useState(false);
  const [editingLimit, setEditingLimit] = useState<UserApiLimit | null>(null);
  const [form] = Form.useForm();

  // 加载API监控数据
  const loadApiMonitorData = async () => {
    try {
      setError(null);
      const params: QueryParams = {
        page: pagination.current,
        pageSize: pagination.pageSize,
        ...filters,
      };

      if (dateRange) {
        params.startDate = dateRange[0].format('YYYY-MM-DD');
        params.endDate = dateRange[1].format('YYYY-MM-DD');
      }

      const [logsResult, statsData, limitsResult, trendsData, costData, errorsData, realtimeData] = await Promise.all([
        ApiMonitorService.getApiCallLogs(params),
        ApiMonitorService.getApiStats(params.startDate, params.endDate),
        ApiMonitorService.getUserApiLimits({ page: 1, pageSize: 100 }),
        ApiMonitorService.getApiTrends(30),
        ApiMonitorService.getCostAnalysis(params.startDate, params.endDate),
        ApiMonitorService.getErrorStats(7),
        ApiMonitorService.getRealTimeStats(),
      ]);

      setApiLogs(logsResult.data);
      setPagination(prev => ({ ...prev, total: logsResult.pagination.total }));
      setApiStats(statsData);
      setUserLimits(limitsResult.data);
      setApiTrends(trendsData);
      setCostAnalysis(costData);
      setErrorStats(errorsData);
      setRealTimeStats(realtimeData);
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
    await loadApiMonitorData();
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

  // 编辑用户限额
  const handleEditLimit = (record: UserApiLimit) => {
    setEditingLimit(record);
    form.setFieldsValue(record);
    setLimitModalVisible(true);
  };

  // 保存用户限额
  const handleSaveLimit = async (values: any) => {
    try {
      if (editingLimit) {
        await ApiMonitorService.updateUserApiLimit(editingLimit.user_id, values);
        message.success('更新用户限额成功');
        setLimitModalVisible(false);
        setEditingLimit(null);
        form.resetFields();
        await loadApiMonitorData();
      }
    } catch (err: any) {
      message.error(err.message);
    }
  };

  // 重置用户使用量
  const handleResetUsage = async (userId: string, apiType?: string) => {
    try {
      await ApiMonitorService.resetUserApiUsage(userId, apiType);
      message.success('重置用户使用量成功');
      await loadApiMonitorData();
    } catch (err: any) {
      message.error(err.message);
    }
  };

  // 导出日志
  const handleExport = async () => {
    try {
      const params: QueryParams = { ...filters };
      if (dateRange) {
        params.startDate = dateRange[0].format('YYYY-MM-DD');
        params.endDate = dateRange[1].format('YYYY-MM-DD');
      }
      
      const blob = await ApiMonitorService.exportApiLogs(params);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `api-logs-${dayjs().format('YYYY-MM-DD')}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      message.success('导出成功');
    } catch (err: any) {
      message.error(err.message);
    }
  };

  useEffect(() => {
    loadApiMonitorData();
  }, [pagination.current, pagination.pageSize, filters, dateRange]);

  // 实时数据轮询
  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const realtimeData = await ApiMonitorService.getRealTimeStats();
        setRealTimeStats(realtimeData);
      } catch (err) {
        // 静默处理错误
      }
    }, 30000); // 30秒更新一次

    return () => clearInterval(interval);
  }, []);

  // API调用日志表格列
  const logColumns = [
    {
      title: '用户ID',
      dataIndex: 'user_id',
      key: 'user_id',
      width: 80,
    },
    {
      title: 'API类型',
      dataIndex: 'api_type',
      key: 'api_type',
      width: 120,
      render: (type: string) => (
        <Tag color={type === 'conversation' ? 'blue' : 'green'}>
          {type === 'conversation' ? '对话API' : '视频生成API'}
        </Tag>
      ),
    },
    {
      title: '端点',
      dataIndex: 'endpoint',
      key: 'endpoint',
      width: 200,
      ellipsis: true,
    },
    {
      title: '状态',
      dataIndex: 'status_code',
      key: 'status_code',
      width: 80,
      render: (status: number) => (
        <Tag color={status === 200 ? 'success' : 'error'}>
          {status}
        </Tag>
      ),
    },
    {
      title: '响应时间',
      dataIndex: 'response_time',
      key: 'response_time',
      width: 100,
      render: (time: number) => `${time}ms`,
      sorter: true,
    },
    {
      title: '成本',
      dataIndex: 'cost',
      key: 'cost',
      width: 80,
      render: (cost: number) => `¥${cost?.toFixed(4) || '0.0000'}`,
      sorter: true,
    },
    {
      title: '调用时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm:ss'),
      sorter: true,
    },
  ];

  // 用户限额表格列
  const limitColumns = [
    {
      title: '用户ID',
      dataIndex: 'user_id',
      key: 'user_id',
      width: 80,
    },
    {
      title: '用户名',
      dataIndex: 'username',
      key: 'username',
      width: 120,
    },
    {
      title: '对话API',
      key: 'conversation',
      width: 200,
      render: (record: UserApiLimit) => (
        <div>
          <Progress
            percent={Math.min((record.conversation_used / record.conversation_limit) * 100, 100)}
            size="small"
            status={record.conversation_used >= record.conversation_limit ? 'exception' : 'active'}
          />
          <Text type="secondary">
            {record.conversation_used} / {record.conversation_limit}
          </Text>
        </div>
      ),
    },
    {
      title: '视频生成API',
      key: 'video',
      width: 200,
      render: (record: UserApiLimit) => (
        <div>
          <Progress
            percent={Math.min((record.video_used / record.video_limit) * 100, 100)}
            size="small"
            status={record.video_used >= record.video_limit ? 'exception' : 'active'}
          />
          <Text type="secondary">
            {record.video_used} / {record.video_limit}
          </Text>
        </div>
      ),
    },
    {
      title: '操作',
      key: 'actions',
      width: 200,
      render: (record: UserApiLimit) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditLimit(record)}
          >
            编辑
          </Button>
          <Button
            type="link"
            icon={<ReloadOutlined />}
            onClick={() => handleResetUsage(record.user_id)}
          >
            重置
          </Button>
        </Space>
      ),
    },
  ];

  // 图表颜色
  const COLORS = ['#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1'];

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
          AI API 监控
        </Title>
        <Space>
          <Button icon={<ExportOutlined />} onClick={handleExport}>
            导出日志
          </Button>
          <Button icon={<ReloadOutlined />} onClick={handleRefresh} loading={refreshing}>
            刷新
          </Button>
        </Space>
      </div>

      {/* 实时统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="今日API调用"
              value={realTimeStats?.todayCalls || 0}
              prefix={<ApiOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="今日成本"
              value={realTimeStats?.todayCost || 0}
              prefix={<DollarOutlined />}
              precision={2}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="活跃用户"
              value={realTimeStats?.activeUsers || 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="错误率"
              value={realTimeStats?.errorRate || 0}
              suffix="%"
              prefix={<WarningOutlined />}
              precision={2}
              valueStyle={{ color: realTimeStats?.errorRate > 5 ? '#f5222d' : '#52c41a' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 标签页 */}
      <Tabs defaultActiveKey="overview">
        <TabPane tab="概览" key="overview">
          {/* API统计概览 */}
          <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
            <Col xs={24} lg={12}>
              <Card title="API调用趋势">
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={apiTrends}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <RechartsTooltip />
                    <Legend />
                    <Area
                      type="monotone"
                      dataKey="conversationCalls"
                      stackId="1"
                      stroke="#1890ff"
                      fill="#1890ff"
                      name="对话API"
                    />
                    <Area
                      type="monotone"
                      dataKey="videoCalls"
                      stackId="1"
                      stroke="#52c41a"
                      fill="#52c41a"
                      name="视频生成API"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="成本分析">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={costAnalysis?.dailyCosts || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <RechartsTooltip />
                    <Legend />
                    <Bar dataKey="conversationCost" fill="#1890ff" name="对话API成本" />
                    <Bar dataKey="videoCost" fill="#52c41a" name="视频生成API成本" />
                  </BarChart>
                </ResponsiveContainer>
              </Card>
            </Col>
          </Row>

          {/* 错误统计 */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <Card title="错误统计（最近7天）">
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={errorStats}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <RechartsTooltip />
                    <Legend />
                    <Line type="monotone" dataKey="errorCount" stroke="#f5222d" name="错误数量" />
                    <Line type="monotone" dataKey="errorRate" stroke="#faad14" name="错误率(%)" />
                  </LineChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="API类型分布">
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={[
                        { name: '对话API', value: apiStats?.conversationCalls || 0, color: '#1890ff' },
                        { name: '视频生成API', value: apiStats?.videoCalls || 0, color: '#52c41a' },
                      ]}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={100}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {[
                        { name: '对话API', value: apiStats?.conversationCalls || 0, color: '#1890ff' },
                        { name: '视频生成API', value: apiStats?.videoCalls || 0, color: '#52c41a' },
                      ].map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="调用日志" key="logs">
          {/* 筛选器 */}
          <Card style={{ marginBottom: '16px' }}>
            <Row gutter={16}>
              <Col xs={24} sm={8} md={6}>
                <Search
                  placeholder="搜索用户ID或端点"
                  onSearch={handleSearch}
                  style={{ width: '100%' }}
                />
              </Col>
              <Col xs={24} sm={8} md={6}>
                <Select
                  placeholder="API类型"
                  style={{ width: '100%' }}
                  allowClear
                  onChange={(value) => handleFilter('apiType', value)}
                >
                  <Option value="conversation">对话API</Option>
                  <Option value="video">视频生成API</Option>
                </Select>
              </Col>
              <Col xs={24} sm={8} md={6}>
                <Select
                  placeholder="状态码"
                  style={{ width: '100%' }}
                  allowClear
                  onChange={(value) => handleFilter('statusCode', value)}
                >
                  <Option value="200">200 - 成功</Option>
                  <Option value="400">400 - 请求错误</Option>
                  <Option value="401">401 - 未授权</Option>
                  <Option value="429">429 - 限流</Option>
                  <Option value="500">500 - 服务器错误</Option>
                </Select>
              </Col>
              <Col xs={24} sm={24} md={6}>
                <RangePicker
                  style={{ width: '100%' }}
                  onChange={(dates) => setDateRange(dates)}
                />
              </Col>
            </Row>
          </Card>

          {/* API调用日志表格 */}
          <Card>
            <Table
              columns={logColumns}
              dataSource={apiLogs}
              rowKey="id"
              pagination={{
                current: pagination.current,
                pageSize: pagination.pageSize,
                total: pagination.total,
                showSizeChanger: true,
                showQuickJumper: true,
                showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
              }}
              onChange={handleTableChange}
              loading={refreshing}
              scroll={{ x: 800 }}
            />
          </Card>
        </TabPane>

        <TabPane tab="用户限额" key="limits">
          {/* 用户限额表格 */}
          <Card>
            <Table
              columns={limitColumns}
              dataSource={userLimits}
              rowKey="user_id"
              pagination={{
                pageSize: 10,
                showSizeChanger: true,
                showQuickJumper: true,
                showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
              }}
              loading={refreshing}
              scroll={{ x: 800 }}
            />
          </Card>
        </TabPane>
      </Tabs>

      {/* 编辑用户限额模态框 */}
      <Modal
        title="编辑用户API限额"
        open={limitModalVisible}
        onCancel={() => {
          setLimitModalVisible(false);
          setEditingLimit(null);
          form.resetFields();
        }}
        onOk={() => form.submit()}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSaveLimit}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="conversation_limit"
                label="对话API限额"
                rules={[{ required: true, message: '请输入对话API限额' }]}
              >
                <InputNumber
                  min={0}
                  style={{ width: '100%' }}
                  placeholder="每月限额"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="video_limit"
                label="视频生成API限额"
                rules={[{ required: true, message: '请输入视频生成API限额' }]}
              >
                <InputNumber
                  min={0}
                  style={{ width: '100%' }}
                  placeholder="每月限额"
                />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item
            name="notes"
            label="备注"
          >
            <Input.TextArea
              rows={3}
              placeholder="限额调整备注"
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default ApiMonitor;