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
  InputNumber,
  Upload,
  message,
  Popconfirm,
  Typography,
  Row,
  Col,
  Statistic,
  Image,
  Tooltip,
  Switch,
} from 'antd';
import {
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  ReloadOutlined,
  ExportOutlined,
  SearchOutlined,
  UploadOutlined,
  EyeOutlined,
  ShoppingOutlined,
} from '@ant-design/icons';
import { ProductService } from '@/services/productService';
import { Product, ProductFormData, QueryParams } from '@/types';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { Option } = Select;
const { Search } = Input;
const { TextArea } = Input;

const ProductManagement: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [products, setProducts] = useState<Product[]>([]);
  const [productStats, setProductStats] = useState<any>(null);
  const [categories, setCategories] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const [filters, setFilters] = useState<QueryParams>({});
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  
  // 模态框状态
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [viewModalVisible, setViewModalVisible] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [viewingProduct, setViewingProduct] = useState<Product | null>(null);
  const [form] = Form.useForm();
  const [imageUrl, setImageUrl] = useState<string>('');
  const [uploading, setUploading] = useState(false);

  // 加载数据
  const loadData = async () => {
    try {
      setLoading(true);
      const params: QueryParams = {
        page: pagination.current,
        pageSize: pagination.pageSize,
        ...filters,
      };

      const [productsResult, statsData, categoriesData] = await Promise.all([
        ProductService.getProducts(params),
        ProductService.getProductStats(),
        ProductService.getCategories(),
      ]);

      setProducts(productsResult.data);
      setPagination(prev => ({ ...prev, total: productsResult.pagination.total }));
      setProductStats(statsData);
      setCategories(categoriesData);
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

  // 查看商品详情
  const handleViewProduct = async (product: Product) => {
    try {
      const productDetail = await ProductService.getProductById(product.id);
      setViewingProduct(productDetail);
      setViewModalVisible(true);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 新增商品
  const handleAddProduct = () => {
    setEditingProduct(null);
    setImageUrl('');
    form.resetFields();
    setEditModalVisible(true);
  };

  // 编辑商品
  const handleEditProduct = (product: Product) => {
    setEditingProduct(product);
    setImageUrl(product.image_url || '');
    form.setFieldsValue({
      name: product.name,
      description: product.description,
      price: product.price,
      category_id: product.category_id,
      status: product.status,
      stock_quantity: product.stock_quantity,
      sku: product.sku,
    });
    setEditModalVisible(true);
  };

  // 保存商品
  const handleSaveProduct = async (values: ProductFormData) => {
    try {
      const productData = {
        ...values,
        image_url: imageUrl,
      };

      if (editingProduct) {
        await ProductService.updateProduct(editingProduct.id, productData);
        message.success('更新商品成功');
      } else {
        await ProductService.createProduct(productData);
        message.success('创建商品成功');
      }

      setEditModalVisible(false);
      setEditingProduct(null);
      setImageUrl('');
      form.resetFields();
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 删除商品
  const handleDeleteProduct = async (product: Product) => {
    try {
      await ProductService.deleteProduct(product.id);
      message.success('删除商品成功');
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 批量删除
  const handleBatchDelete = async () => {
    try {
      await ProductService.batchDeleteProducts(selectedRowKeys as string[]);
      message.success('批量删除成功');
      setSelectedRowKeys([]);
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 切换商品状态
  const handleToggleStatus = async (product: Product) => {
    try {
      const newStatus = product.status === 'active' ? 'inactive' : 'active';
      await ProductService.updateProductStatus(product.id, newStatus);
      message.success(`${newStatus === 'active' ? '上架' : '下架'}商品成功`);
      await loadData();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 上传图片
  const handleImageUpload = async (file: File) => {
    try {
      setUploading(true);
      const result = await ProductService.uploadProductImage(file);
      setImageUrl(result.url);
      message.success('上传图片成功');
    } catch (error: any) {
      message.error(error.message);
    } finally {
      setUploading(false);
    }
  };

  // 导出数据
  const handleExport = async () => {
    try {
      const blob = await ProductService.exportProducts(filters);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `products-${dayjs().format('YYYY-MM-DD')}.csv`;
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
    loadData();
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
      title: '商品信息',
      key: 'productInfo',
      width: 250,
      render: (record: Product) => (
        <Space>
          <Image
            src={record.image_url}
            width={60}
            height={60}
            style={{ objectFit: 'cover', borderRadius: '4px' }}
            fallback="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMIAAADDCAYAAADQvc6UAAABRWlDQ1BJQ0MgUHJvZmlsZQAAKJFjYGASSSwoyGFhYGDIzSspCnJ3UoiIjFJgf8LAwSDCIMogwMCcmFxc4BgQ4ANUwgCjUcG3awyMIPqyLsis7PPOq3QdDFcvjV3jOD1boQVTPQrgSkktTgbSf4A4LbmgqISBgTEFyFYuLykAsTuAbJEioKOA7DkgdjqEvQHEToKwj4DVhAQ5A9k3gGyB5IxEoBmML4BsnSQk8XQkNtReEOBxcfXxUQg1Mjc0dyHgXNJBSWpFCYh2zi+oLMpMzyhRcASGUqqCZ16yno6CkYGRAQMDKMwhqj/fAIcloxgHQqxAjIHBEugw5sUIsSQpBobtQPdLciLEVJYzMPBHMDBsayhILEqEO4DxG0txmrERhM29nYGBddr//5/DGRjYNRkY/l7////39v///y4Dmn+LgeHANwDrkl1AuO+pmgAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAwqADAAQAAAABAAAAwwAAAAD9b/HnAAAHlklEQVR4Ae3dP3Ik1RnG4W+FgYxN"
          />
          <div>
            <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>{record.name}</div>
            <div style={{ color: '#999', fontSize: '12px' }}>SKU: {record.sku}</div>
          </div>
        </Space>
      ),
    },
    {
      title: '分类',
      dataIndex: 'category_name',
      key: 'category_name',
      width: 120,
    },
    {
      title: '价格',
      dataIndex: 'price',
      key: 'price',
      width: 100,
      render: (price: number) => `¥${price?.toFixed(2) || '0.00'}`,
      sorter: true,
    },
    {
      title: '库存',
      dataIndex: 'stock_quantity',
      key: 'stock_quantity',
      width: 80,
      render: (stock: number) => (
        <Tag color={stock > 10 ? 'green' : stock > 0 ? 'orange' : 'red'}>
          {stock}
        </Tag>
      ),
      sorter: true,
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'active' ? 'green' : 'red'}>
          {status === 'active' ? '上架' : '下架'}
        </Tag>
      ),
    },
    {
      title: '销量',
      dataIndex: 'sales_count',
      key: 'sales_count',
      width: 80,
      sorter: true,
    },
    {
      title: '创建时间',
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
      render: (record: Product) => (
        <Space>
          <Tooltip title="查看详情">
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => handleViewProduct(record)}
            />
          </Tooltip>
          <Tooltip title="编辑">
            <Button
              type="text"
              icon={<EditOutlined />}
              onClick={() => handleEditProduct(record)}
            />
          </Tooltip>
          <Tooltip title={record.status === 'active' ? '下架' : '上架'}>
            <Switch
              size="small"
              checked={record.status === 'active'}
              onChange={() => handleToggleStatus(record)}
            />
          </Tooltip>
          <Tooltip title="删除">
            <Popconfirm
              title="确定要删除该商品吗？"
              onConfirm={() => handleDeleteProduct(record)}
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
          商品管理
        </Title>
        <Space>
          <Button type="primary" icon={<PlusOutlined />} onClick={handleAddProduct}>
            新增商品
          </Button>
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
              title="商品总数"
              value={productStats?.totalProducts || 0}
              prefix={<ShoppingOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="在售商品"
              value={productStats?.activeProducts || 0}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="库存不足"
              value={productStats?.lowStockProducts || 0}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={6}>
          <Card>
            <Statistic
              title="总库存价值"
              value={productStats?.totalStockValue || 0}
              precision={2}
              prefix="¥"
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
              placeholder="搜索商品名称或SKU"
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={8} md={6}>
            <Select
              placeholder="商品分类"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilter('categoryId', value)}
            >
              {categories.map(category => (
                <Option key={category.id} value={category.id}>
                  {category.name}
                </Option>
              ))}
            </Select>
          </Col>
          <Col xs={24} sm={8} md={6}>
            <Select
              placeholder="商品状态"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilter('status', value)}
            >
              <Option value="active">上架</Option>
              <Option value="inactive">下架</Option>
            </Select>
          </Col>
          <Col xs={24} sm={8} md={6}>
            <Select
              placeholder="库存状态"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilter('stockStatus', value)}
            >
              <Option value="in_stock">有库存</Option>
              <Option value="low_stock">库存不足</Option>
              <Option value="out_of_stock">缺货</Option>
            </Select>
          </Col>
        </Row>
      </Card>

      {/* 批量操作 */}
      {selectedRowKeys.length > 0 && (
        <Card style={{ marginBottom: '16px' }}>
          <Space>
            <Text>已选择 {selectedRowKeys.length} 项</Text>
            <Popconfirm
              title="确定要批量删除选中的商品吗？"
              onConfirm={handleBatchDelete}
            >
              <Button danger>批量删除</Button>
            </Popconfirm>
            <Button onClick={() => setSelectedRowKeys([])}>取消选择</Button>
          </Space>
        </Card>
      )}

      {/* 商品表格 */}
      <Card>
        <Table
          columns={columns}
          dataSource={products}
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

      {/* 编辑商品模态框 */}
      <Modal
        title={editingProduct ? '编辑商品' : '新增商品'}
        open={editModalVisible}
        onCancel={() => {
          setEditModalVisible(false);
          setEditingProduct(null);
          setImageUrl('');
          form.resetFields();
        }}
        onOk={() => form.submit()}
        width={800}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSaveProduct}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="name"
                label="商品名称"
                rules={[{ required: true, message: '请输入商品名称' }]}
              >
                <Input placeholder="商品名称" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="sku"
                label="商品SKU"
                rules={[{ required: true, message: '请输入商品SKU' }]}
              >
                <Input placeholder="商品SKU" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="category_id"
                label="商品分类"
                rules={[{ required: true, message: '请选择商品分类' }]}
              >
                <Select placeholder="选择分类">
                  {categories.map(category => (
                    <Option key={category.id} value={category.id}>
                      {category.name}
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="price"
                label="商品价格"
                rules={[{ required: true, message: '请输入商品价格' }]}
              >
                <InputNumber
                  min={0}
                  precision={2}
                  style={{ width: '100%' }}
                  placeholder="0.00"
                  addonBefore="¥"
                />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="stock_quantity"
                label="库存数量"
                rules={[{ required: true, message: '请输入库存数量' }]}
              >
                <InputNumber
                  min={0}
                  style={{ width: '100%' }}
                  placeholder="库存数量"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="status"
                label="商品状态"
                rules={[{ required: true, message: '请选择商品状态' }]}
              >
                <Select placeholder="选择状态">
                  <Option value="active">上架</Option>
                  <Option value="inactive">下架</Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
          <Form.Item
            name="description"
            label="商品描述"
          >
            <TextArea
              rows={4}
              placeholder="商品描述"
            />
          </Form.Item>
          <Form.Item label="商品图片">
            <Upload
              name="image"
              listType="picture-card"
              showUploadList={false}
              beforeUpload={(file) => {
                handleImageUpload(file);
                return false;
              }}

            >
              {imageUrl ? (
                <Image src={imageUrl} alt="商品图片" style={{ width: '100%' }} />
              ) : (
                <div>
                  <UploadOutlined />
                  <div style={{ marginTop: 8 }}>上传图片</div>
                </div>
              )}
            </Upload>
          </Form.Item>
        </Form>
      </Modal>

      {/* 查看商品详情模态框 */}
      <Modal
        title="商品详情"
        open={viewModalVisible}
        onCancel={() => {
          setViewModalVisible(false);
          setViewingProduct(null);
        }}
        footer={null}
        width={800}
      >
        {viewingProduct && (
          <div>
            <Row gutter={[16, 16]}>
              <Col span={8}>
                <Image
                  src={viewingProduct.image_url}
                  alt={viewingProduct.name}
                  style={{ width: '100%', borderRadius: '8px' }}
                />
              </Col>
              <Col span={16}>
                <Space direction="vertical" style={{ width: '100%' }} size="middle">
                  <div>
                    <Title level={4}>{viewingProduct.name}</Title>
                    <Text type="secondary">SKU: {viewingProduct.sku}</Text>
                  </div>
                  <div>
                    <Text strong>价格: </Text>
                    <Text style={{ fontSize: '18px', color: '#f5222d' }}>
                      ¥{viewingProduct.price?.toFixed(2)}
                    </Text>
                  </div>
                  <div>
                    <Text strong>分类: </Text>
                    <Tag>{viewingProduct.category_name}</Tag>
                  </div>
                  <div>
                    <Text strong>状态: </Text>
                    <Tag color={viewingProduct.status === 'active' ? 'green' : 'red'}>
                      {viewingProduct.status === 'active' ? '上架' : '下架'}
                    </Tag>
                  </div>
                  <div>
                    <Text strong>库存: </Text>
                    <Tag color={viewingProduct.stock_quantity > 10 ? 'green' : viewingProduct.stock_quantity > 0 ? 'orange' : 'red'}>
                      {viewingProduct.stock_quantity} 件
                    </Tag>
                  </div>
                  <div>
                    <Text strong>销量: </Text>
                    <Text>{viewingProduct.sales_count || 0} 件</Text>
                  </div>
                  <div>
                    <Text strong>创建时间: </Text>
                    <Text>{dayjs(viewingProduct.created_at).format('YYYY-MM-DD HH:mm:ss')}</Text>
                  </div>
                </Space>
              </Col>
            </Row>
            {viewingProduct.description && (
              <div style={{ marginTop: '16px' }}>
                <Title level={5}>商品描述</Title>
                <Text>{viewingProduct.description}</Text>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
};

export default ProductManagement;