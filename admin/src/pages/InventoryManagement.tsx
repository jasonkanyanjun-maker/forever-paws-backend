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
  InputNumber,
  message,
  Typography,
  Row,
  Col,
  Statistic,
  Progress,
  Tooltip,
  Alert,
  Select,
  DatePicker,
  Tabs,
} from 'antd';
import {
  ReloadOutlined,
  ExportOutlined,
  SearchOutlined,
  WarningOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  BarChartOutlined,
  EditOutlined,
  HistoryOutlined,
} from '@ant-design/icons';
import { InventoryService } from '@/services/inventoryService';
import { Inventory, QueryParams } from '@/types';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { Search } = Input;
const { RangePicker } = DatePicker;
const { TabPane } = Tabs;
const { TextArea } = Input;

const InventoryManagement: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [inventory, setInventory] = useState<Inventory[]>([]);
  const [inventoryStats, setInventoryStats] = useState<any>(null);
  const [inventoryAlerts, setInventoryAlerts] = useState<any>(null);
  const [inventoryLogs, setInventoryLogs] = useState<any[]>([]);
  const [inventoryTrends, setInventoryTrends] = useState<any>(null);
  const [turnoverAnalysis, setTurnoverAnalysis] = useState<any>(null);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const [filters, setFilters] = useState<QueryParams>({});
  
  // 模态框状态
  const [adjustModalVisible, setAdjustModalVisible] = useState(false);
  const [thresholdModalVisible, setThresholdModalVisible] = useState(false);
  const [stockTakingModalVisible, setStockTakingModalVisible] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<Inventory | null>(null);
  const [form] = Form.useForm();
  const [adjustForm] = Form.useForm();
  const [thresholdForm] = Form.useForm();

  // 加载数据
  const loadData = async () => {
    try {
      setLoading(true);
      const params: QueryParams = {
        page: pagination.current,
        pageSize: pagination.pageSize,
        ...filters,
      };

      const [inventoryResult, statsData, alertsData, logsData] = await Promise.all([
        InventoryService.getInventory(params),
        InventoryService.getInventoryStats(),
        InventoryService.getInventoryAlerts(),
        InventoryService.getInventoryLogs({ page: 1, pageSize: 10 }),
      ]);

      setInventory(inventoryResult.data);
      setPagination(prev => ({ ...prev, total: inventoryResult.pagination.total }));
      setInventoryStats(statsData);
      setInventoryAlerts(alertsData);
      setInventoryLogs(logsData.data);
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
      
      const [trendsData, turnoverData] = await Promise.all([
        InventoryService.getInventoryTrends({
          start_date: startDate.format('YYYY-MM-DD'),
          end_date: endDate.format('YYYY-MM-DD'),
        }),
        InventoryService.getInventoryTurnoverAnalysis({
          start_date: startDate.format('YYYY-MM-DD'),
          end_date: endDate.format('YYYY-MM-DD'),
        }),
      ]);

      setInventoryTrends(trendsData);
      setTurnoverAnalysis(turnoverData);
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

  // 库存调整
  const handleAdjustStock = (product: Inventory) => {
    setSelectedProduct(product);
    adjustForm.resetFields();
    setAdjustModalVisible(true);
  };

  // 保存库存调整
  const handleSaveAdjustment = async (values: any) => {
    try {
      if (!selectedProduct) return;
      
      await InventoryService.adjustStock(selectedProduct.product_id, values);
      message.success('库存调整成功');
      setAdjustModalVisible(false);
      setSelectedProduct(null);
      adjustForm.resetFields();
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 设置库存阈值
  const handleSetThreshold = (product: Inventory) => {
    setSelectedProduct(product);
    thresholdForm.setFieldsValue({
      min_stock_level: product.min_stock_level,
      max_stock_level: product.max_stock_level,
    });
    setThresholdModalVisible(true);
  };

  // 保存库存阈值
  const handleSaveThreshold = async (values: any) => {
    try {
      if (!selectedProduct) return;
      
      await InventoryService.setStockThreshold(selectedProduct.product_id, values);
      message.success('库存阈值设置成功');
      setThresholdModalVisible(false);
      setSelectedProduct(null);
      thresholdForm.resetFields();
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 导出数据
  const handleExport = async () => {
    try {
      const blob = await InventoryService.exportInventory(filters);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `inventory-${dayjs().format('YYYY-MM-DD')}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      message.success('导出成功');
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 获取库存状态
  const getStockStatus = (item: Inventory) => {
    if (item.stock_quantity === 0) {
      return { status: 'error', text: '缺货', color: 'red' };
    } else if (item.stock_quantity <= item.min_stock_level) {
      return { status: 'warning', text: '库存不足', color: 'orange' };
    } else if (item.max_stock_level && item.stock_quantity >= item.max_stock_level) {
      return { status: 'processing', text: '库存过多', color: 'blue' };
    } else {
      return { status: 'success', text: '正常', color: 'green' };
    }
  };

  // 计算库存健康度
  const getStockHealthScore = (item: Inventory) => {
    if (item.stock_quantity === 0) return 0;
    if (item.stock_quantity <= item.min_stock_level) return 30;
    if (item.max_stock_level && item.stock_quantity >= item.max_stock_level) return 60;
    return 100;
  };

  useEffect(() => {
    loadData();
    loadTrendsData();
  }, [pagination.current, pagination.pageSize, filters]);

  // 表格列定义
  const columns = [
    {
      title: 'ID',
      dataIndex: 'product_id',
      key: 'product_id',
      width: 80,
      sorter: true,
    },
    {
      title: '商品信息',
      key: 'productInfo',
      width: 200,
      render: (record: Inventory) => (
        <div>
          <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>{record.product_name}</div>
          <div style={{ color: '#999', fontSize: '12px' }}>SKU: {record.sku}</div>
        </div>
      ),
    },
    {
      title: '当前库存',
      dataIndex: 'stock_quantity',
      key: 'stock_quantity',
      width: 120,
      render: (stock: number, record: Inventory) => {
        const stockStatus = getStockStatus(record);
        return (
          <Space direction="vertical" size="small">
            <Tag color={stockStatus.color}>{stock} 件</Tag>
            <Text type="secondary" style={{ fontSize: '12px' }}>
              {stockStatus.text}
            </Text>
          </Space>
        );
      },
      sorter: true,
    },
    {
      title: '库存健康度',
      key: 'healthScore',
      width: 120,
      render: (record: Inventory) => {
        const score = getStockHealthScore(record);
        return (
          <Progress
            percent={score}
            size="small"
            status={score < 50 ? 'exception' : score < 80 ? 'active' : 'success'}
            showInfo={false}
          />
        );
      },
    },
    {
      title: '预警阈值',
      key: 'threshold',
      width: 120,
      render: (record: Inventory) => (
        <Space direction="vertical" size="small">
          <Text style={{ fontSize: '12px' }}>
            最低: {record.min_stock_level || 0}
          </Text>
          {record.max_stock_level && (
            <Text style={{ fontSize: '12px' }}>
              最高: {record.max_stock_level}
            </Text>
          )}
        </Space>
      ),
    },
    {
      title: '库存价值',
      key: 'stockValue',
      width: 120,
      render: (record: Inventory) => (
        <Text>¥{((record.stock_quantity || 0) * (record.unit_price || 0)).toFixed(2)}</Text>
      ),
      sorter: true,
    },
    {
      title: '最后更新',
      dataIndex: 'updated_at',
      key: 'updated_at',
      width: 160,
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm'),
      sorter: true,
    },
    {
      title: '操作',
      key: 'actions',
      width: 150,
      fixed: 'right' as const,
      render: (record: Inventory) => (
        <Space>
          <Tooltip title="调整库存">
            <Button
              type="text"
              icon={<EditOutlined />}
              onClick={() => handleAdjustStock(record)}
            />
          </Tooltip>
          <Tooltip title="设置阈值">
            <Button
              type="text"
              icon={<WarningOutlined />}
              onClick={() => handleSetThreshold(record)}
            />
          </Tooltip>
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题和操作 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2} style={{ margin: 0 }}>
          库存管理
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

      {/* 库存预警 */}
      {inventoryAlerts && (
        <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
          {inventoryAlerts.lowStockAlerts?.length > 0 && (
            <Col span={24}>
              <Alert
                message={`库存不足预警: ${inventoryAlerts.lowStockAlerts.length} 个商品库存不足`}
                type="warning"
                showIcon
                closable
              />
            </Col>
          )}
          {inventoryAlerts.outOfStockAlerts?.length > 0 && (
            <Col span={24}>
              <Alert
                message={`缺货预警: ${inventoryAlerts.outOfStockAlerts.length} 个商品已缺货`}
                type="error"
                showIcon
                closable
              />
            </Col>
          )}
        </Row>
      )}

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="商品总数"
              value={inventoryStats?.totalProducts || 0}
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="库存不足"
              value={inventoryStats?.lowStockProducts || 0}
              prefix={<WarningOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="缺货商品"
              value={inventoryStats?.outOfStockProducts || 0}
              prefix={<ArrowDownOutlined />}
              valueStyle={{ color: '#f5222d' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="库存总价值"
              value={inventoryStats?.totalStockValue || 0}
              precision={2}
              prefix="¥"
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 标签页 */}
      <Tabs defaultActiveKey="inventory">
        <TabPane tab="库存列表" key="inventory">
          {/* 筛选器 */}
          <Card style={{ marginBottom: '16px' }}>
            <Row gutter={16}>
              <Col xs={24} sm={8} md={6}>
                <Search
                  placeholder="搜索商品名称或SKU"
                  onSearch={handleSearch}
                  style={{ width: '100%' }}
                />
              </Col>
              <Col xs={24} sm={8} md={6}>
                <Select
                  placeholder="库存状态"
                  style={{ width: '100%' }}
                  allowClear
                  onChange={(value) => setFilters({ ...filters, stockStatus: value })}
                >
                  <Select.Option value="normal">正常</Select.Option>
                  <Select.Option value="low_stock">库存不足</Select.Option>
                  <Select.Option value="out_of_stock">缺货</Select.Option>
                  <Select.Option value="over_stock">库存过多</Select.Option>
                </Select>
              </Col>
            </Row>
          </Card>

          {/* 库存表格 */}
          <Card>
            <Table
              columns={columns}
              dataSource={inventory}
              rowKey="product_id"
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
              scroll={{ x: 1000 }}
            />
          </Card>
        </TabPane>

        <TabPane tab="库存趋势" key="trends">
          <Row gutter={[16, 16]}>
            <Col span={24}>
              <Card title="库存变化趋势">
                {inventoryTrends && (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={inventoryTrends.dates?.map((date: string, index: number) => ({
                      date,
                      stockLevel: inventoryTrends.stockLevels[index],
                      stockChange: inventoryTrends.stockChanges[index],
                    }))}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis />
                      <RechartsTooltip />
                      <Line type="monotone" dataKey="stockLevel" stroke="#1890ff" name="库存水平" />
                      <Line type="monotone" dataKey="stockChange" stroke="#52c41a" name="库存变化" />
                    </LineChart>
                  </ResponsiveContainer>
                )}
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="周转分析" key="turnover">
          <Card title="库存周转分析">
            {turnoverAnalysis && (
              <div>
                <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
                  <Col span={8}>
                    <Statistic
                      title="平均周转率"
                      value={turnoverAnalysis.averageTurnoverRate}
                      precision={2}
                      suffix="次/年"
                    />
                  </Col>
                </Row>
                <Table
                  dataSource={turnoverAnalysis.products}
                  rowKey="product_id"
                  columns={[
                    {
                      title: '商品名称',
                      dataIndex: 'product_name',
                      key: 'product_name',
                    },
                    {
                      title: '周转率',
                      dataIndex: 'turnover_rate',
                      key: 'turnover_rate',
                      render: (rate: number) => `${rate.toFixed(2)} 次/年`,
                      sorter: (a: any, b: any) => a.turnover_rate - b.turnover_rate,
                    },
                    {
                      title: '库存天数',
                      dataIndex: 'days_in_stock',
                      key: 'days_in_stock',
                      render: (days: number) => `${days} 天`,
                      sorter: (a: any, b: any) => a.days_in_stock - b.days_in_stock,
                    },
                    {
                      title: '库存价值',
                      dataIndex: 'stock_value',
                      key: 'stock_value',
                      render: (value: number) => `¥${value.toFixed(2)}`,
                      sorter: (a: any, b: any) => a.stock_value - b.stock_value,
                    },
                  ]}
                  pagination={{ pageSize: 10 }}
                />
              </div>
            )}
          </Card>
        </TabPane>

        <TabPane tab="操作记录" key="logs">
          <Card title="库存操作记录">
            <Table
              dataSource={inventoryLogs}
              rowKey="id"
              columns={[
                {
                  title: '时间',
                  dataIndex: 'created_at',
                  key: 'created_at',
                  render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm:ss'),
                },
                {
                  title: '商品',
                  dataIndex: 'product_name',
                  key: 'product_name',
                },
                {
                  title: '操作类型',
                  dataIndex: 'operation_type',
                  key: 'operation_type',
                  render: (type: string) => {
                    const typeMap: { [key: string]: { text: string; color: string } } = {
                      'increase': { text: '增加', color: 'green' },
                      'decrease': { text: '减少', color: 'red' },
                      'adjustment': { text: '调整', color: 'blue' },
                      'stock_taking': { text: '盘点', color: 'purple' },
                    };
                    const config = typeMap[type] || { text: type, color: 'default' };
                    return <Tag color={config.color}>{config.text}</Tag>;
                  },
                },
                {
                  title: '数量变化',
                  dataIndex: 'quantity_change',
                  key: 'quantity_change',
                  render: (change: number) => (
                    <Text style={{ color: change > 0 ? '#52c41a' : '#f5222d' }}>
                      {change > 0 ? '+' : ''}{change}
                    </Text>
                  ),
                },
                {
                  title: '操作人',
                  dataIndex: 'operator_name',
                  key: 'operator_name',
                },
                {
                  title: '备注',
                  dataIndex: 'notes',
                  key: 'notes',
                },
              ]}
              pagination={{ pageSize: 10 }}
            />
          </Card>
        </TabPane>
      </Tabs>

      {/* 库存调整模态框 */}
      <Modal
        title="库存调整"
        open={adjustModalVisible}
        onCancel={() => {
          setAdjustModalVisible(false);
          setSelectedProduct(null);
          adjustForm.resetFields();
        }}
        onOk={() => adjustForm.submit()}
      >
        <Form
          form={adjustForm}
          layout="vertical"
          onFinish={handleSaveAdjustment}
        >
          {selectedProduct && (
            <div style={{ marginBottom: '16px', padding: '12px', backgroundColor: '#f5f5f5', borderRadius: '4px' }}>
              <Text strong>{selectedProduct.product_name}</Text>
              <br />
              <Text type="secondary">当前库存: {selectedProduct.stock_quantity} 件</Text>
            </div>
          )}
          <Form.Item
            name="adjustment_type"
            label="调整类型"
            rules={[{ required: true, message: '请选择调整类型' }]}
          >
            <Select placeholder="选择调整类型">
              <Select.Option value="increase">增加库存</Select.Option>
              <Select.Option value="decrease">减少库存</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item
            name="quantity"
            label="调整数量"
            rules={[{ required: true, message: '请输入调整数量' }]}
          >
            <InputNumber
              min={1}
              style={{ width: '100%' }}
              placeholder="调整数量"
            />
          </Form.Item>
          <Form.Item
            name="reason"
            label="调整原因"
            rules={[{ required: true, message: '请输入调整原因' }]}
          >
            <Select placeholder="选择调整原因">
              <Select.Option value="purchase">采购入库</Select.Option>
              <Select.Option value="sale">销售出库</Select.Option>
              <Select.Option value="damage">商品损坏</Select.Option>
              <Select.Option value="loss">商品丢失</Select.Option>
              <Select.Option value="return">退货入库</Select.Option>
              <Select.Option value="other">其他</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item
            name="notes"
            label="备注"
          >
            <TextArea
              rows={3}
              placeholder="备注信息"
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* 设置库存阈值模态框 */}
      <Modal
        title="设置库存阈值"
        open={thresholdModalVisible}
        onCancel={() => {
          setThresholdModalVisible(false);
          setSelectedProduct(null);
          thresholdForm.resetFields();
        }}
        onOk={() => thresholdForm.submit()}
      >
        <Form
          form={thresholdForm}
          layout="vertical"
          onFinish={handleSaveThreshold}
        >
          {selectedProduct && (
            <div style={{ marginBottom: '16px', padding: '12px', backgroundColor: '#f5f5f5', borderRadius: '4px' }}>
              <Text strong>{selectedProduct.product_name}</Text>
              <br />
              <Text type="secondary">当前库存: {selectedProduct.stock_quantity} 件</Text>
            </div>
          )}
          <Form.Item
            name="min_stock_level"
            label="最低库存阈值"
            rules={[{ required: true, message: '请输入最低库存阈值' }]}
          >
            <InputNumber
              min={0}
              style={{ width: '100%' }}
              placeholder="最低库存阈值"
            />
          </Form.Item>
          <Form.Item
            name="max_stock_level"
            label="最高库存阈值"
          >
            <InputNumber
              min={0}
              style={{ width: '100%' }}
              placeholder="最高库存阈值（可选）"
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default InventoryManagement;