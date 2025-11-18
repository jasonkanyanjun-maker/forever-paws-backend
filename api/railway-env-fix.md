# Railway 环境变量配置

## 必需的环境变量：

### 基础配置
NODE_ENV=staging
PORT=3000
HOSTNAME=::  # 关键：绑定到 IPv6

### Supabase 配置（修复版）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

### JWT 配置
JWT_SECRET=your_super_secure_jwt_secret_256_bits_minimum
JWT_EXPIRES_IN=7d

### 安全配置
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

### 日志配置
LOG_LEVEL=info

## 修复说明：

1. **HOSTNAME=::** - 这是关键修复，使应用监听 IPv6
2. **绑定地址** - 服务器代码已更新为监听 '::' 而不是 '0.0.0.0'
3. **双栈支持** - 现在支持 IPv4 和 IPv6 连接

## Railway 网络特点：
- 内部网络使用 IPv6
- 公共服务需要绑定到 :: 以支持双栈
- 某些库需要显式配置 family=0
- 私有网络只能使用 IPv6 地址
