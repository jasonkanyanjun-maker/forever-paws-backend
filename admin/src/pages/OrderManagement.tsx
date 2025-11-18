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
  Typography,
  Row,
  Col,
  Statistic,
  Descriptions,
  Steps,
  Timeline,
  Popconfirm,
  InputNumber,
  DatePicker,
  Tabs,
  Divider,
} from 'antd';
import {
  ReloadOutlined,
  ExportOutlined,
  SearchOutlined,
  EyeOutlined,
  EditOutlined,
  TruckOutlined,
  DollarOutlined,
  ShoppingCartOutlined,
  CloseCircleOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
} from '@ant-design/icons';
import { OrderService } from '@/services/orderService';
import { Order, QueryParams } from '@/types';
import { PieChart, Pie, Cell, ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, BarChart, Bar } from 'recharts';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { Search } = Input;
const { RangePicker } = DatePicker;
const { TabPane } = Tabs;
const { TextArea } = Input;
const { Step } = Steps;

const OrderManagement: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [orders, setOrders] = useState<Order[]>([]);
  const [orderStats, setOrderStats] = useState<any>(null);
  const [orderTrends, setOrderTrends] = useState<any>(null);
  const [salesAnalysis, setSalesAnalysis] = useState<any>(null);
  const [statusDistribution, setStatusDistribution] = useState<any>(null);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const [filters, setFilters] = useState<QueryParams>({});
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  
  // 模态框状态
  const [viewModalVisible, setViewModalVisible] = useState(false);
  const [statusModalVisible, setStatusModalVisible] = useState(false);
  const [refundModalVisible, setRefundModalVisible] = useState(false);
  const [shippingModalVisible, setShippingModalVisible] = useState(false);
  const [noteModalVisible, setNoteModalVisible] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [orderNotes, setOrderNotes] = useState<any[]>([]);
  const [shippingInfo, setShippingInfo] = useState<any>(null);
  const [paymentInfo, setPaymentInfo] = useState<any>(null);
  
  const [statusForm] = Form.useForm();
  const [refundForm] = Form.useForm();
  const [shippingForm] = Form.useForm();
  const [noteForm] = Form.useForm();

  // 加载数据
  const loadData = async () => {
    try {
      setLoading(true);
      const params: QueryParams = {
        page: pagination.current,
        pageSize: pagination.pageSize,
        ...filters,
      };

      const [ordersResult, statsData, statusData] = await Promise.all([
        OrderService.getOrders(params),
        OrderService.getOrderStats(),
        OrderService.getOrderStatusDistribution(),
      ]);

      setOrders(ordersResult.data);
      setPagination(prev => ({ ...prev, total: ordersResult.pagination.total }));
      setOrderStats(statsData);
      setStatusDistribution(statusData);
    } catch (error: any) {
      message.error(error.message);
    } finally {
      setLoading(false);
    }
  };

  // 加载趋势数据
  const loadTrendsData = async () => {
    try {
      const endDate = dayjs();
      const startDate = endDate.subtract(30, 'day');
      
      const [trendsData, salesData] = await Promise.all([
        OrderService.getOrderTrends({
          start_date: startDate.format('YYYY-MM-DD'),
          end_date: endDate.format('YYYY-MM-DD'),
          group_by: 'day',
        }),
        OrderService.getSalesAnalysis({
          start_date: startDate.format('YYYY-MM-DD'),
          end_date: endDate.format('YYYY-MM-DD'),
        }),
      ]);

      setOrderTrends(trendsData);
      setSalesAnalysis(salesData);
    } catch (error: any) {
      message.error(error.message);
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

  // 查看订单详情
  const handleViewOrder = async (order: Order) => {
    try {
      const [orderDetail, notes, shipping, payment] = await Promise.all([
        OrderService.getOrderById(order.id),
        OrderService.getOrderNotes(order.id),
        OrderService.getShippingInfo(order.id).catch(() => null),
        OrderService.getPaymentInfo(order.id).catch(() => null),
      ]);

      setSelectedOrder(orderDetail);
      setOrderNotes(notes);
      setShippingInfo(shipping);
      setPaymentInfo(payment);
      setViewModalVisible(true);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 更新订单状态
  const handleUpdateStatus = (order: Order) => {
    setSelectedOrder(order);
    statusForm.setFieldsValue({ status: order.status });
    setStatusModalVisible(true);
  };

  // 保存状态更新
  const handleSaveStatus = async (values: any) => {
    try {
      if (!selectedOrder) return;
      
      await OrderService.updateOrderStatus(selectedOrder.id, values.status, values.notes);
      message.success('订单状态更新成功');
      setStatusModalVisible(false);
      setSelectedOrder(null);
      statusForm.resetFields();
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 批量更新状态
  const handleBatchUpdateStatus = async (status: string) => {
    try {
      await OrderService.batchUpdateOrderStatus(selectedRowKeys as string[], status);
      message.success('批量更新状态成功');
      setSelectedRowKeys([]);
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 处理退款
  const handleRefund = (order: Order) => {
    setSelectedOrder(order);
    refundForm.setFieldsValue({ refund_amount: order.total_amount });
    setRefundModalVisible(true);
  };

  // 保存退款
  const handleSaveRefund = async (values: any) => {
    try {
      if (!selectedOrder) return;
      
      await OrderService.processRefund(selectedOrder.id, values);
      message.success('退款处理成功');
      setRefundModalVisible(false);
      setSelectedOrder(null);
      refundForm.resetFields();
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 取消订单
  const handleCancelOrder = async (order: Order, reason: string) => {
    try {
      await OrderService.cancelOrder(order.id, reason);
      message.success('订单取消成功');
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 更新物流信息
  const handleUpdateShipping = (order: Order) => {
    setSelectedOrder(order);
    if (shippingInfo) {
      shippingForm.setFieldsValue({
        tracking_number: shippingInfo.tracking_number,
        shipping_company: shippingInfo.shipping_company,
      });
    }
    setShippingModalVisible(true);
  };

  // 保存物流信息
  const handleSaveShipping = async (values: any) => {
    try {
      if (!selectedOrder) return;
      
      await OrderService.updateShippingInfo(selectedOrder.id, values);
      message.success('物流信息更新成功');
      setShippingModalVisible(false);
      setSelectedOrder(null);
      shippingForm.resetFields();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 添加备注
  const handleAddNote = (order: Order) => {
    setSelectedOrder(order);
    noteForm.resetFields();
    setNoteModalVisible(true);
  };

  // 保存备注
  const handleSaveNote = async (values: any) => {
    try {
      if (!selectedOrder) return;
      
      await OrderService.addOrderNote(selectedOrder.id, values.note);
      message.success('备注添加成功');
      setNoteModalVisible(false);
      setSelectedOrder(null);
      noteForm.resetFields();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 导出数据
  const handleExport = async () => {
    try {
      const blob = await OrderService.exportOrders(filters);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `orders-${dayjs().format('YYYY-MM-DD')}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      message.success('导出成功');
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 获取订单状态配置
  const getOrderStatusConfig = (status: string) => {
    const statusMap: { [key: string]: { text: string; color: string; icon: React.ReactNode } } = {
      'pending': { text: '待处理', color: 'orange', icon: <ClockCircleOutlined /> },
      'processing': { text: '处理中', color: 'blue', icon: <EditOutlined /> },
      'shipped': { text: '已发货', color: 'cyan', icon: <TruckOutlined /> },
      'delivered': { text: '已送达', color: 'green', icon: <CheckCircleOutlined /> },
      'cancelled': { text: '已取消', color: 'red', icon: <CloseCircleOutlined /> },
      'refunded': { text: '已退款', color: 'purple', icon: <DollarOutlined /> },
    };
    return statusMap[status] || { text: status, color: 'default', icon: null };
  };

  // 获取订单步骤
  const getOrderSteps = (order: Order) => {
    const steps = [
      { title: '订单创建', status: 'finish' },
      { title: '支付确认', status: order.payment_status === 'paid' ? 'finish' : 'wait' },
      { title: '商品准备', status: ['processing', 'shipped', 'delivered'].includes(order.status) ? 'finish' : 'wait' },
      { title: '发货', status: ['shipped', 'delivered'].includes(order.status) ? 'finish' : 'wait' },
      { title: '送达', status: order.status === 'delivered' ? 'finish' : 'wait' },
    ];

    if (order.status === 'cancelled') {
      return [{ title: '订单取消', status: 'error' }];
    }

    return steps;
  };

  useEffect(() => {
    loadData();
    loadTrendsData();
  }, [pagination.current, pagination.pageSize, filters]);

  // 表格列定义
  const columns = [
    {
      title: '订单号',
      dataIndex: 'order_number',
      key: 'order_number',
      width: 150,
      render: (orderNumber: string) => (
        <Text copyable style={{ fontFamily: 'monospace' }}>{orderNumber}</Text>
      ),
    },
    {
      title: '客户信息',
      key: 'customer',
      width: 150,
      render: (record: Order) => (
        <div>
          <div style={{ fontWeight: 'bold' }}>{record.customer_name}</div>
          <div style={{ color: '#999', fontSize: '12px' }}>{record.customer_email}</div>
        </div>
      ),
    },
    {
      title: '订单金额',
      dataIndex: 'total_amount',
      key: 'total_amount',
      width: 120,
      render: (amount: number) => (
        <Text strong style={{ color: '#f5222d' }}>¥{amount?.toFixed(2) || '0.00'}</Text>
      ),
      sorter: true,
    },
    {
      title: '订单状态',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: string) => {
        const config = getOrderStatusConfig(status);
        return (
          <Tag color={config.color} icon={config.icon}>
            {config.text}
          </Tag>
        );
      },
    },
    {
      title: '支付状态',
      dataIndex: 'payment_status',
      key: 'payment_status',
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'paid' ? 'green' : status === 'pending' ? 'orange' : 'red'}>
          {status === 'paid' ? '已支付' : status === 'pending' ? '待支付' : '支付失败'}
        </Tag>
      ),
    },
    {
      title: '商品数量',
      dataIndex: 'item_count',
      key: 'item_count',
      width: 100,
      render: (count: number) => `${count || 0} 件`,
    },
    {
      title: '下单时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm'),
      sorter: true,
    },
    {
      title: '操作',
      key: 'actions',
      width: 200,
      fixed: 'right' as const,
      render: (record: Order) => (
        <Space>
          <Button
            type="text"
            icon={<EyeOutlined />}
            onClick={() => handleViewOrder(record)}
          />
          <Button
            type="text"
            icon={<EditOutlined />}
            onClick={() => handleUpdateStatus(record)}
          />
          {record.status === 'shipped' && (
            <Button
              type="text"
              icon={<TruckOutlined />}
              onClick={() => handleUpdateShipping(record)}
            />
          )}
          {['pending', 'processing'].includes(record.status) && (
            <Popconfirm
              title="确定要取消该订单吗？"
              onConfirm={() => handleCancelOrder(record, '管理员取消')}
            >
              <Button type="text" danger icon={<CloseCircleOutlined />} />
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  // 行选择配置
  const rowSelection = {
    selectedRowKeys,
    onChange: setSelectedRowKeys,
  };

  // 状态分布图表数据
  const statusChartData = statusDistribution ? Object.entries(statusDistribution).map(([key, value]) => ({
    name: getOrderStatusConfig(key).text,
    value: value as number,
    color: getOrderStatusConfig(key).color,
  })) : [];

  const COLORS = ['#ff7875', '#ffa940', '#40a9ff', '#73d13d', '#b37feb', '#ffec3d'];

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题和操作 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2} style={{ margin: 0 }}>
          订单管理
        </Title>
        <Space>
          <Button icon={<ExportOutlined />} onClick={handleExport}>
            导出数据
          </Button>
          <Button icon={<ReloadOutlined />} onClick={loadData} loading={loading}>
            刷新
          </Button>
        </Space>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="订单总数"
              value={orderStats?.totalOrders || 0}
              prefix={<ShoppingCartOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="待处理订单"
              value={orderStats?.pendingOrders || 0}
              prefix={<ClockCircleOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="总收入"
              value={orderStats?.totalRevenue || 0}
              precision={2}
              prefix="¥"
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="平均订单价值"
              value={orderStats?.averageOrderValue || 0}
              precision={2}
              prefix="¥"
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 标签页 */}
      <Tabs defaultActiveKey="orders">
        <TabPane tab="订单列表" key="orders">
          {/* 筛选器 */}
          <Card style={{ marginBottom: '16px' }}>
            <Row gutter={16}>
              <Col xs={24} sm={8} md={6}>
                <Search
                  placeholder="搜索订单号或客户"
                  onSearch={handleSearch}
                  style={{ width: '100%' }}
                />
              </Col>
              <Col xs={24} sm={8} md={6}>
                <Select
                  placeholder="订单状态"
                  style={{ width: '100%' }}
                  allowClear
                  onChange={(value) => setFilters({ ...filters, status: value })}
                >
                  <Select.Option value="pending">待处理</Select.Option>
                  <Select.Option value="processing">处理中</Select.Option>
                  <Select.Option value="shipped">已发货</Select.Option>
                  <Select.Option value="delivered">已送达</Select.Option>
                  <Select.Option value="cancelled">已取消</Select.Option>
                  <Select.Option value="refunded">已退款</Select.Option>
                </Select>
              </Col>
              <Col xs={24} sm={8} md={6}>
                <Select
                  placeholder="支付状态"
                  style={{ width: '100%' }}
                  allowClear
                  onChange={(value) => setFilters({ ...filters, paymentStatus: value })}
                >
                  <Select.Option value="paid">已支付</Select.Option>
                  <Select.Option value="pending">待支付</Select.Option>
                  <Select.Option value="failed">支付失败</Select.Option>
                </Select>
              </Col>
              <Col xs={24} sm={8} md={6}>
                <RangePicker
                  style={{ width: '100%' }}
                  onChange={(dates) => {
                    if (dates) {
                      setFilters({
                        ...filters,
                        startDate: dates[0]?.format('YYYY-MM-DD'),
                        endDate: dates[1]?.format('YYYY-MM-DD'),
                      });
                    } else {
                      const { startDate, endDate, ...rest } = filters;
                      setFilters(rest);
                    }
                  }}
                />
              </Col>
            </Row>
          </Card>

          {/* 批量操作 */}
          {selectedRowKeys.length > 0 && (
            <Card style={{ marginBottom: '16px' }}>
              <Space>
                <Text>已选择 {selectedRowKeys.length} 项</Text>
                <Button onClick={() => handleBatchUpdateStatus('processing')}>
                  批量设为处理中
                </Button>
                <Button onClick={() => handleBatchUpdateStatus('shipped')}>
                  批量设为已发货
                </Button>
                <Button onClick={() => setSelectedRowKeys([])}>取消选择</Button>
              </Space>
            </Card>
          )}

          {/* 订单表格 */}
          <Card>
            <Table
              columns={columns}
              dataSource={orders}
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
        </TabPane>

        <TabPane tab="数据分析" key="analytics">
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <Card title="订单趋势">
                {orderTrends && (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={orderTrends.dates?.map((date: string, index: number) => ({
                      date: dayjs(date).format('MM-DD'),
                      orders: orderTrends.orderCounts[index],
                      revenue: orderTrends.revenues[index],
                    }))}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis yAxisId="left" />
                      <YAxis yAxisId="right" orientation="right" />
                      <RechartsTooltip />
                      <Bar yAxisId="left" dataKey="orders" fill="#1890ff" name="订单数" />
                      <Line yAxisId="right" type="monotone" dataKey="revenue" stroke="#52c41a" name="收入" />
                    </LineChart>
                  </ResponsiveContainer>
                )}
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="订单状态分布">
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={statusChartData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {statusChartData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col span={24}>
              <Card title="热销商品">
                {salesAnalysis?.topProducts && (
                  <Table
                    dataSource={salesAnalysis.topProducts}
                    rowKey="product_id"
                    pagination={false}
                    columns={[
                      {
                        title: '商品名称',
                        dataIndex: 'product_name',
                        key: 'product_name',
                      },
                      {
                        title: '销量',
                        dataIndex: 'sales_count',
                        key: 'sales_count',
                        render: (count: number) => `${count} 件`,
                        sorter: (a: any, b: any) => a.sales_count - b.sales_count,
                      },
                      {
                        title: '销售额',
                        dataIndex: 'revenue',
                        key: 'revenue',
                        render: (revenue: number) => `¥${revenue.toFixed(2)}`,
                        sorter: (a: any, b: any) => a.revenue - b.revenue,
                      },
                    ]}
                  />
                )}
              </Card>
            </Col>
          </Row>
        </TabPane>
      </Tabs>

      {/* 查看订单详情模态框 */}
      <Modal
        title="订单详情"
        open={viewModalVisible}
        onCancel={() => {
          setViewModalVisible(false);
          setSelectedOrder(null);
        }}
        footer={null}
        width={1000}
      >
        {selectedOrder && (
          <div>
            {/* 订单基本信息 */}
            <Descriptions title="订单信息" bordered column={2}>
              <Descriptions.Item label="订单号">{selectedOrder.order_number}</Descriptions.Item>
              <Descriptions.Item label="订单状态">
                <Tag color={getOrderStatusConfig(selectedOrder.status).color}>
                  {getOrderStatusConfig(selectedOrder.status).text}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="客户姓名">{selectedOrder.customer_name}</Descriptions.Item>
              <Descriptions.Item label="客户邮箱">{selectedOrder.customer_email}</Descriptions.Item>
              <Descriptions.Item label="订单金额">¥{selectedOrder.total_amount?.toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="支付状态">
                <Tag color={selectedOrder.payment_status === 'paid' ? 'green' : 'orange'}>
                  {selectedOrder.payment_status === 'paid' ? '已支付' : '待支付'}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="下单时间">
                {dayjs(selectedOrder.created_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
              <Descriptions.Item label="收货地址" span={2}>
                {selectedOrder.shipping_address}
              </Descriptions.Item>
            </Descriptions>

            <Divider />

            {/* 订单进度 */}
            <Title level={4}>订单进度</Title>
            <Steps current={getOrderSteps(selectedOrder).findIndex(step => step.status === 'wait')}>
              {getOrderSteps(selectedOrder).map((step, index) => (
                <Step key={index} title={step.title} status={step.status as any} />
              ))}
            </Steps>

            <Divider />

            {/* 商品列表 */}
            <Title level={4}>商品列表</Title>
            <Table
              dataSource={selectedOrder.items}
              rowKey="id"
              pagination={false}
              columns={[
                {
                  title: '商品名称',
                  dataIndex: 'product_name',
                  key: 'product_name',
                },
                {
                  title: '单价',
                  dataIndex: 'unit_price',
                  key: 'unit_price',
                  render: (price: number) => `¥${price?.toFixed(2)}`,
                },
                {
                  title: '数量',
                  dataIndex: 'quantity',
                  key: 'quantity',
                },
                {
                  title: '小计',
                  key: 'subtotal',
                  render: (record: any) => `¥${(record.unit_price * record.quantity).toFixed(2)}`,
                },
              ]}
            />

            {/* 支付信息 */}
            {paymentInfo && (
              <>
                <Divider />
                <Title level={4}>支付信息</Title>
                <Descriptions bordered column={2}>
                  <Descriptions.Item label="支付方式">{paymentInfo.payment_method}</Descriptions.Item>
                  <Descriptions.Item label="支付状态">{paymentInfo.payment_status}</Descriptions.Item>
                  <Descriptions.Item label="支付时间">{paymentInfo.payment_time}</Descriptions.Item>
                  <Descriptions.Item label="交易号">{paymentInfo.transaction_id}</Descriptions.Item>
                </Descriptions>
              </>
            )}

            {/* 物流信息 */}
            {shippingInfo && (
              <>
                <Divider />
                <Title level={4}>物流信息</Title>
                <Descriptions bordered column={2}>
                  <Descriptions.Item label="快递公司">{shippingInfo.shipping_company}</Descriptions.Item>
                  <Descriptions.Item label="快递单号">{shippingInfo.tracking_number}</Descriptions.Item>
                </Descriptions>
                {shippingInfo.tracking_info && (
                  <Timeline style={{ marginTop: '16px' }}>
                    {shippingInfo.tracking_info.map((info: any, index: number) => (
                      <Timeline.Item key={index}>
                        <div>
                          <Text strong>{info.status}</Text>
                          <br />
                          <Text type="secondary">{info.time} - {info.location}</Text>
                          <br />
                          <Text>{info.description}</Text>
                        </div>
                      </Timeline.Item>
                    ))}
                  </Timeline>
                )}
              </>
            )}

            {/* 订单备注 */}
            {orderNotes.length > 0 && (
              <>
                <Divider />
                <Title level={4}>订单备注</Title>
                <Timeline>
                  {orderNotes.map((note: any) => (
                    <Timeline.Item key={note.id}>
                      <div>
                        <Text>{note.note}</Text>
                        <br />
                        <Text type="secondary">
                          {note.created_by} - {dayjs(note.created_at).format('YYYY-MM-DD HH:mm:ss')}
                        </Text>
                      </div>
                    </Timeline.Item>
                  ))}
                </Timeline>
              </>
            )}
          </div>
        )}
      </Modal>

      {/* 更新状态模态框 */}
      <Modal
        title="更新订单状态"
        open={statusModalVisible}
        onCancel={() => {
          setStatusModalVisible(false);
          setSelectedOrder(null);
          statusForm.resetFields();
        }}
        onOk={() => statusForm.submit()}
      >
        <Form
          form={statusForm}
          layout="vertical"
          onFinish={handleSaveStatus}
        >
          <Form.Item
            name="status"
            label="订单状态"
            rules={[{ required: true, message: '请选择订单状态' }]}
          >
            <Select placeholder="选择状态">
              <Select.Option value="pending">待处理</Select.Option>
              <Select.Option value="processing">处理中</Select.Option>
              <Select.Option value="shipped">已发货</Select.Option>
              <Select.Option value="delivered">已送达</Select.Option>
              <Select.Option value="cancelled">已取消</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item
            name="notes"
            label="备注"
          >
            <TextArea
              rows={3}
              placeholder="状态更新备注"
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* 退款模态框 */}
      <Modal
        title="处理退款"
        open={refundModalVisible}
        onCancel={() => {
          setRefundModalVisible(false);
          setSelectedOrder(null);
          refundForm.resetFields();
        }}
        onOk={() => refundForm.submit()}
      >
        <Form
          form={refundForm}
          layout="vertical"
          onFinish={handleSaveRefund}
        >
          <Form.Item
            name="refund_amount"
            label="退款金额"
            rules={[{ required: true, message: '请输入退款金额' }]}
          >
            <InputNumber
              min={0}
              precision={2}
              style={{ width: '100%' }}
              placeholder="退款金额"
              addonBefore="¥"
            />
          </Form.Item>
          <Form.Item
            name="refund_reason"
            label="退款原因"
            rules={[{ required: true, message: '请选择退款原因' }]}
          >
            <Select placeholder="选择退款原因">
              <Select.Option value="customer_request">客户申请</Select.Option>
              <Select.Option value="product_defect">商品缺陷</Select.Option>
              <Select.Option value="shipping_issue">物流问题</Select.Option>
              <Select.Option value="other">其他</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item
            name="notes"
            label="备注"
          >
            <TextArea
              rows={3}
              placeholder="退款备注"
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* 物流信息模态框 */}
      <Modal
        title="更新物流信息"
        open={shippingModalVisible}
        onCancel={() => {
          setShippingModalVisible(false);
          setSelectedOrder(null);
          shippingForm.resetFields();
        }}
        onOk={() => shippingForm.submit()}
      >
        <Form
          form={shippingForm}
          layout="vertical"
          onFinish={handleSaveShipping}
        >
          <Form.Item
            name="shipping_company"
            label="快递公司"
            rules={[{ required: true, message: '请输入快递公司' }]}
          >
            <Select placeholder="选择快递公司">
              <Select.Option value="顺丰速运">顺丰速运</Select.Option>
              <Select.Option value="圆通速递">圆通速递</Select.Option>
              <Select.Option value="中通快递">中通快递</Select.Option>
              <Select.Option value="申通快递">申通快递</Select.Option>
              <Select.Option value="韵达速递">韵达速递</Select.Option>
              <Select.Option value="百世汇通">百世汇通</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item
            name="tracking_number"
            label="快递单号"
            rules={[{ required: true, message: '请输入快递单号' }]}
          >
            <Input placeholder="快递单号" />
          </Form.Item>
        </Form>
      </Modal>

      {/* 添加备注模态框 */}
      <Modal
        title="添加订单备注"
        open={noteModalVisible}
        onCancel={() => {
          setNoteModalVisible(false);
          setSelectedOrder(null);
          noteForm.resetFields();
        }}
        onOk={() => noteForm.submit()}
      >
        <Form
          form={noteForm}
          layout="vertical"
          onFinish={handleSaveNote}
        >
          <Form.Item
            name="note"
            label="备注内容"
            rules={[{ required: true, message: '请输入备注内容' }]}
          >
            <TextArea
              rows={4}
              placeholder="请输入备注内容"
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default OrderManagement;