import React, { useState, useEffect } from 'react';
import {
  Card,
  Tabs,
  Form,
  Input,
  Switch,
  Button,
  message,
  Typography,
  Row,
  Col,
  Statistic,
  Table,
  Space,
  Modal,
  Upload,
  InputNumber,
  Select,
  Tag,
  Progress,
  Alert,
  Popconfirm,
  Descriptions,
} from 'antd';
import {
  SaveOutlined,
  ReloadOutlined,
  SettingOutlined,
  DatabaseOutlined,
  SecurityScanOutlined,
  MailOutlined,
  CloudUploadOutlined,
  DeleteOutlined,
  DownloadOutlined,
  ClearOutlined,
  UploadOutlined,
  ExperimentOutlined,
} from '@ant-design/icons';
import { SystemService } from '@/services/systemService';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { TabPane } = Tabs;
const { TextArea } = Input;
const { Option } = Select;

const SystemSettings: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [systemConfig, setSystemConfig] = useState<any>(null);
  const [systemInfo, setSystemInfo] = useState<any>(null);
  const [systemLogs, setSystemLogs] = useState<any[]>([]);
  const [backups, setBackups] = useState<any[]>([]);
  const [cacheStats, setCacheStats] = useState<any>(null);
  const [queueStatus, setQueueStatus] = useState<any>(null);
  const [securitySettings, setSecuritySettings] = useState<any>(null);
  const [apiLimits, setApiLimits] = useState<any>(null);
  
  // 表单实例
  const [configForm] = Form.useForm();
  const [emailForm] = Form.useForm();
  const [securityForm] = Form.useForm();
  const [apiForm] = Form.useForm();
  
  // 模态框状态
  const [testEmailModalVisible, setTestEmailModalVisible] = useState(false);
  const [backupModalVisible, setBackupModalVisible] = useState(false);
  const [logoUrl, setLogoUrl] = useState<string>('');
  const [uploading, setUploading] = useState(false);

  // 加载系统配置
  const loadSystemConfig = async () => {
    try {
      const config = await SystemService.getSystemConfig();
      setSystemConfig(config);
      setLogoUrl(config.site_logo || '');
      configForm.setFieldsValue(config);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载系统信息
  const loadSystemInfo = async () => {
    try {
      const info = await SystemService.getSystemInfo();
      setSystemInfo(info);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载系统日志
  const loadSystemLogs = async () => {
    try {
      const logs = await SystemService.getSystemLogs({ page: 1, pageSize: 10 });
      setSystemLogs(logs.data);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载备份列表
  const loadBackups = async () => {
    try {
      const backupList = await SystemService.getBackups();
      setBackups(backupList);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载缓存统计
  const loadCacheStats = async () => {
    try {
      const stats = await SystemService.getCacheStats();
      setCacheStats(stats);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载队列状态
  const loadQueueStatus = async () => {
    try {
      const status = await SystemService.getQueueStatus();
      setQueueStatus(status);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载安全设置
  const loadSecuritySettings = async () => {
    try {
      const settings = await SystemService.getSecuritySettings();
      setSecuritySettings(settings);
      securityForm.setFieldsValue(settings);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载API限制设置
  const loadApiLimits = async () => {
    try {
      const limits = await SystemService.getApiLimits();
      setApiLimits(limits);
      apiForm.setFieldsValue(limits);
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 加载所有数据
  const loadAllData = async () => {
    try {
      setLoading(true);
      await Promise.all([
        loadSystemConfig(),
        loadSystemInfo(),
        loadSystemLogs(),
        loadBackups(),
        loadCacheStats(),
        loadQueueStatus(),
        loadSecuritySettings(),
        loadApiLimits(),
      ]);
    } finally {
      setLoading(false);
    }
  };

  // 保存系统配置
  const handleSaveConfig = async (values: any) => {
    try {
      const configData = {
        ...values,
        site_logo: logoUrl,
      };
      await SystemService.updateSystemConfig(configData);
      message.success('系统配置保存成功');
      await loadSystemConfig();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 测试邮件配置
  const handleTestEmail = async (values: any) => {
    try {
      await SystemService.testEmailConfig(values);
      message.success('邮件发送成功');
      setTestEmailModalVisible(false);
      emailForm.resetFields();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 创建备份
  const handleCreateBackup = async () => {
    try {
      await SystemService.createBackup();
      message.success('备份创建成功');
      await loadBackups();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 下载备份
  const handleDownloadBackup = async (backup: any) => {
    try {
      const blob = await SystemService.downloadBackup(backup.id);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = backup.filename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      message.success('备份下载成功');
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 删除备份
  const handleDeleteBackup = async (backupId: string) => {
    try {
      await SystemService.deleteBackup(backupId);
      message.success('备份删除成功');
      await loadBackups();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 恢复备份
  const handleRestoreBackup = async (backupId: string) => {
    try {
      await SystemService.restoreBackup(backupId);
      message.success('数据库恢复成功');
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 清理缓存
  const handleClearCache = async (type?: string) => {
    try {
      await SystemService.clearCache(type);
      message.success('缓存清理成功');
      await loadCacheStats();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 重启队列
  const handleRestartQueue = async (queueName: string) => {
    try {
      await SystemService.restartQueue(queueName);
      message.success('队列重启成功');
      await loadQueueStatus();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 清理系统日志
  const handleClearLogs = async () => {
    try {
      await SystemService.clearSystemLogs();
      message.success('日志清理成功');
      await loadSystemLogs();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 保存安全设置
  const handleSaveSecuritySettings = async (values: any) => {
    try {
      await SystemService.updateSecuritySettings(values);
      message.success('安全设置保存成功');
      await loadSecuritySettings();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 保存API限制设置
  const handleSaveApiLimits = async (values: any) => {
    try {
      await SystemService.updateApiLimits(values);
      message.success('API限制设置保存成功');
      await loadApiLimits();
    } catch (error: any) {
      message.error(error.message);
    }
  };

  // 上传Logo
  const handleLogoUpload = async (file: File) => {
    try {
      setUploading(true);
      const result = await SystemService.uploadLogo(file);
      setLogoUrl(result.url);
      message.success('Logo上传成功');
    } catch (error: any) {
      message.error(error.message);
    } finally {
      setUploading(false);
    }
  };

  useEffect(() => {
    loadAllData();
  }, []);

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题和操作 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2} style={{ margin: 0 }}>
          系统设置
        </Title>
        <Space>
          <Button icon={<ReloadOutlined />} onClick={loadAllData} loading={loading}>
            刷新
          </Button>
        </Space>
      </div>

      <Tabs defaultActiveKey="general">
        {/* 基本设置 */}
        <TabPane tab="基本设置" key="general" icon={<SettingOutlined />}>
          <Card>
            <Form
              form={configForm}
              layout="vertical"
              onFinish={handleSaveConfig}
            >
              <Row gutter={24}>
                <Col span={12}>
                  <Form.Item
                    name="site_name"
                    label="网站名称"
                    rules={[{ required: true, message: '请输入网站名称' }]}
                  >
                    <Input placeholder="网站名称" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="contact_email"
                    label="联系邮箱"
                    rules={[{ required: true, type: 'email', message: '请输入有效的邮箱地址' }]}
                  >
                    <Input placeholder="联系邮箱" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={24}>
                <Col span={12}>
                  <Form.Item
                    name="contact_phone"
                    label="联系电话"
                  >
                    <Input placeholder="联系电话" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="网站Logo">
                    <Upload
                      name="logo"
                      listType="picture-card"
                      showUploadList={false}
                      beforeUpload={(file) => {
                        handleLogoUpload(file);
                        return false;
                      }}

                    >
                      {logoUrl ? (
                        <img src={logoUrl} alt="logo" style={{ width: '100%' }} />
                      ) : (
                        <div>
                          <UploadOutlined />
                          <div style={{ marginTop: 8 }}>上传Logo</div>
                        </div>
                      )}
                    </Upload>
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item
                name="site_description"
                label="网站描述"
              >
                <TextArea rows={4} placeholder="网站描述" />
              </Form.Item>
              <Row gutter={24}>
                <Col span={8}>
                  <Form.Item
                    name="maintenance_mode"
                    label="维护模式"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="registration_enabled"
                    label="允许注册"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="email_verification_required"
                    label="邮箱验证"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={24}>
                <Col span={8}>
                  <Form.Item
                    name="max_login_attempts"
                    label="最大登录尝试次数"
                  >
                    <InputNumber min={1} max={10} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="session_timeout"
                    label="会话超时时间(分钟)"
                  >
                    <InputNumber min={5} max={1440} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="file_upload_max_size"
                    label="文件上传大小限制(MB)"
                  >
                    <InputNumber min={1} max={100} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item>
                <Button type="primary" htmlType="submit" icon={<SaveOutlined />}>
                  保存设置
                </Button>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        {/* 邮件设置 */}
        <TabPane tab="邮件设置" key="email" icon={<MailOutlined />}>
          <Card>
            <Form
              form={configForm}
              layout="vertical"
              onFinish={handleSaveConfig}
            >
              <Row gutter={24}>
                <Col span={12}>
                  <Form.Item
                    name="smtp_host"
                    label="SMTP服务器"
                    rules={[{ required: true, message: '请输入SMTP服务器' }]}
                  >
                    <Input placeholder="smtp.example.com" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="smtp_port"
                    label="SMTP端口"
                    rules={[{ required: true, message: '请输入SMTP端口' }]}
                  >
                    <InputNumber min={1} max={65535} style={{ width: '100%' }} placeholder="587" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={24}>
                <Col span={12}>
                  <Form.Item
                    name="smtp_username"
                    label="SMTP用户名"
                    rules={[{ required: true, message: '请输入SMTP用户名' }]}
                  >
                    <Input placeholder="用户名" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="smtp_password"
                    label="SMTP密码"
                    rules={[{ required: true, message: '请输入SMTP密码' }]}
                  >
                    <Input.Password placeholder="密码" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={24}>
                <Col span={12}>
                  <Form.Item
                    name="smtp_encryption"
                    label="加密方式"
                    rules={[{ required: true, message: '请选择加密方式' }]}
                  >
                    <Select placeholder="选择加密方式">
                      <Option value="tls">TLS</Option>
                      <Option value="ssl">SSL</Option>
                      <Option value="none">无</Option>
                    </Select>
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item>
                <Space>
                  <Button type="primary" htmlType="submit" icon={<SaveOutlined />}>
                    保存设置
                  </Button>
                  <Button icon={<ExperimentOutlined />} onClick={() => setTestEmailModalVisible(true)}>
                    测试邮件
                  </Button>
                </Space>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        {/* 安全设置 */}
        <TabPane tab="安全设置" key="security" icon={<SecurityScanOutlined />}>
          <Card>
            <Form
              form={securityForm}
              layout="vertical"
              onFinish={handleSaveSecuritySettings}
            >
              <Title level={4}>密码策略</Title>
              <Row gutter={24}>
                <Col span={8}>
                  <Form.Item
                    name="password_min_length"
                    label="最小密码长度"
                  >
                    <InputNumber min={6} max={32} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="password_require_uppercase"
                    label="需要大写字母"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="password_require_lowercase"
                    label="需要小写字母"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={24}>
                <Col span={8}>
                  <Form.Item
                    name="password_require_numbers"
                    label="需要数字"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="password_require_symbols"
                    label="需要特殊字符"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="two_factor_enabled"
                    label="启用双因子认证"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
              </Row>
              
              <Title level={4}>访问控制</Title>
              <Row gutter={24}>
                <Col span={8}>
                  <Form.Item
                    name="rate_limit_enabled"
                    label="启用频率限制"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="rate_limit_requests"
                    label="请求次数限制"
                  >
                    <InputNumber min={1} max={1000} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="rate_limit_window"
                    label="时间窗口(分钟)"
                  >
                    <InputNumber min={1} max={60} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>
              
              <Form.Item>
                <Button type="primary" htmlType="submit" icon={<SaveOutlined />}>
                  保存设置
                </Button>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        {/* 系统信息 */}
        <TabPane tab="系统信息" key="info" icon={<DatabaseOutlined />}>
          <Row gutter={[16, 16]}>
            {/* 服务器信息 */}
            <Col span={24}>
              <Card title="服务器信息">
                {systemInfo?.server_info && (
                  <Row gutter={[16, 16]}>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="操作系统"
                        value={systemInfo.server_info.os}
                        valueStyle={{ fontSize: '16px' }}
                      />
                    </Col>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="Node.js版本"
                        value={systemInfo.server_info.node_version}
                        valueStyle={{ fontSize: '16px' }}
                      />
                    </Col>
                    <Col xs={24} sm={6}>
                      <div>
                        <Text type="secondary">内存使用率</Text>
                        <Progress
                          percent={systemInfo.server_info.memory_usage}
                          status={systemInfo.server_info.memory_usage > 80 ? 'exception' : 'normal'}
                        />
                      </div>
                    </Col>
                    <Col xs={24} sm={6}>
                      <div>
                        <Text type="secondary">磁盘使用率</Text>
                        <Progress
                          percent={systemInfo.server_info.disk_usage}
                          status={systemInfo.server_info.disk_usage > 80 ? 'exception' : 'normal'}
                        />
                      </div>
                    </Col>
                  </Row>
                )}
              </Card>
            </Col>

            {/* 数据库信息 */}
            <Col span={12}>
              <Card title="数据库信息">
                {systemInfo?.database_info && (
                  <Descriptions column={1}>
                    <Descriptions.Item label="数据库类型">
                      {systemInfo.database_info.type}
                    </Descriptions.Item>
                    <Descriptions.Item label="版本">
                      {systemInfo.database_info.version}
                    </Descriptions.Item>
                    <Descriptions.Item label="数据库大小">
                      {(systemInfo.database_info.size / 1024 / 1024).toFixed(2)} MB
                    </Descriptions.Item>
                    <Descriptions.Item label="表数量">
                      {systemInfo.database_info.tables_count}
                    </Descriptions.Item>
                  </Descriptions>
                )}
              </Card>
            </Col>

            {/* 应用信息 */}
            <Col span={12}>
              <Card title="应用信息">
                {systemInfo?.application_info && (
                  <Descriptions column={1}>
                    <Descriptions.Item label="应用版本">
                      {systemInfo.application_info.version}
                    </Descriptions.Item>
                    <Descriptions.Item label="运行环境">
                      <Tag color={systemInfo.application_info.environment === 'production' ? 'green' : 'orange'}>
                        {systemInfo.application_info.environment}
                      </Tag>
                    </Descriptions.Item>
                    <Descriptions.Item label="调试模式">
                      <Tag color={systemInfo.application_info.debug_mode ? 'red' : 'green'}>
                        {systemInfo.application_info.debug_mode ? '开启' : '关闭'}
                      </Tag>
                    </Descriptions.Item>
                    <Descriptions.Item label="时区">
                      {systemInfo.application_info.timezone}
                    </Descriptions.Item>
                  </Descriptions>
                )}
              </Card>
            </Col>
          </Row>
        </TabPane>

        {/* 数据备份 */}
        <TabPane tab="数据备份" key="backup" icon={<CloudUploadOutlined />}>
          <Row gutter={[16, 16]}>
            <Col span={24}>
              <Card
                title="数据备份"
                extra={
                  <Button type="primary" icon={<CloudUploadOutlined />} onClick={handleCreateBackup}>
                    创建备份
                  </Button>
                }
              >
                <Table
                  dataSource={backups}
                  rowKey="id"
                  columns={[
                    {
                      title: '文件名',
                      dataIndex: 'filename',
                      key: 'filename',
                    },
                    {
                      title: '文件大小',
                      dataIndex: 'size',
                      key: 'size',
                      render: (size: number) => `${(size / 1024 / 1024).toFixed(2)} MB`,
                    },
                    {
                      title: '创建时间',
                      dataIndex: 'created_at',
                      key: 'created_at',
                      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm:ss'),
                    },
                    {
                      title: '状态',
                      dataIndex: 'status',
                      key: 'status',
                      render: (status: string) => (
                        <Tag color={status === 'completed' ? 'green' : status === 'failed' ? 'red' : 'orange'}>
                          {status === 'completed' ? '完成' : status === 'failed' ? '失败' : '进行中'}
                        </Tag>
                      ),
                    },
                    {
                      title: '操作',
                      key: 'actions',
                      render: (record: any) => (
                        <Space>
                          <Button
                            type="text"
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownloadBackup(record)}
                          />
                          <Popconfirm
                            title="确定要恢复此备份吗？这将覆盖当前数据！"
                            onConfirm={() => handleRestoreBackup(record.id)}
                          >
                            <Button type="text" icon={<ReloadOutlined />} />
                          </Popconfirm>
                          <Popconfirm
                            title="确定要删除此备份吗？"
                            onConfirm={() => handleDeleteBackup(record.id)}
                          >
                            <Button type="text" danger icon={<DeleteOutlined />} />
                          </Popconfirm>
                        </Space>
                      ),
                    },
                  ]}
                />
              </Card>
            </Col>
          </Row>
        </TabPane>

        {/* 系统日志 */}
        <TabPane tab="系统日志" key="logs">
          <Card
            title="系统日志"
            extra={
              <Popconfirm
                title="确定要清理所有日志吗？"
                onConfirm={handleClearLogs}
              >
                <Button danger icon={<ClearOutlined />}>
                  清理日志
                </Button>
              </Popconfirm>
            }
          >
            <Table
              dataSource={systemLogs}
              rowKey="id"
              columns={[
                {
                  title: '时间',
                  dataIndex: 'created_at',
                  key: 'created_at',
                  width: 180,
                  render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm:ss'),
                },
                {
                  title: '级别',
                  dataIndex: 'level',
                  key: 'level',
                  width: 100,
                  render: (level: string) => {
                    const colorMap: { [key: string]: string } = {
                      'error': 'red',
                      'warning': 'orange',
                      'info': 'blue',
                      'debug': 'green',
                    };
                    return <Tag color={colorMap[level] || 'default'}>{level.toUpperCase()}</Tag>;
                  },
                },
                {
                  title: '消息',
                  dataIndex: 'message',
                  key: 'message',
                },
              ]}
              pagination={{ pageSize: 10 }}
            />
          </Card>
        </TabPane>

        {/* 缓存管理 */}
        <TabPane tab="缓存管理" key="cache">
          <Row gutter={[16, 16]}>
            <Col span={24}>
              <Card title="缓存统计">
                {cacheStats && (
                  <Row gutter={[16, 16]}>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="缓存键数量"
                        value={cacheStats.total_keys}
                        valueStyle={{ color: '#1890ff' }}
                      />
                    </Col>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="内存使用"
                        value={cacheStats.memory_usage}
                        suffix="MB"
                        precision={2}
                        valueStyle={{ color: '#52c41a' }}
                      />
                    </Col>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="命中率"
                        value={cacheStats.hit_rate}
                        suffix="%"
                        precision={2}
                        valueStyle={{ color: '#722ed1' }}
                      />
                    </Col>
                    <Col xs={24} sm={6}>
                      <Statistic
                        title="未命中率"
                        value={cacheStats.miss_rate}
                        suffix="%"
                        precision={2}
                        valueStyle={{ color: '#faad14' }}
                      />
                    </Col>
                  </Row>
                )}
                <div style={{ marginTop: '24px' }}>
                  <Space>
                    <Button icon={<ClearOutlined />} onClick={() => handleClearCache()}>
                      清理所有缓存
                    </Button>
                    <Button icon={<ClearOutlined />} onClick={() => handleClearCache('session')}>
                      清理会话缓存
                    </Button>
                    <Button icon={<ClearOutlined />} onClick={() => handleClearCache('api')}>
                      清理API缓存
                    </Button>
                  </Space>
                </div>
              </Card>
            </Col>
          </Row>
        </TabPane>
      </Tabs>

      {/* 测试邮件模态框 */}
      <Modal
        title="测试邮件配置"
        open={testEmailModalVisible}
        onCancel={() => {
          setTestEmailModalVisible(false);
          emailForm.resetFields();
        }}
        onOk={() => emailForm.submit()}
      >
        <Form
          form={emailForm}
          layout="vertical"
          onFinish={handleTestEmail}
        >
          <Form.Item
            name="test_email"
            label="测试邮箱"
            rules={[{ required: true, type: 'email', message: '请输入有效的邮箱地址' }]}
          >
            <Input placeholder="输入测试邮箱地址" />
          </Form.Item>
          <Alert
            message="将使用当前的SMTP配置发送测试邮件"
            type="info"
            showIcon
          />
        </Form>
      </Modal>
    </div>
  );
};

export default SystemSettings;