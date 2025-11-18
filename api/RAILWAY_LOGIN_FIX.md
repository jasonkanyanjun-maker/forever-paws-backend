# Railway 浏览器登录解决方案

## 🚨 登录问题修复步骤

### 方法1：使用 Google Chrome 登录（推荐）

1. **打开 Google Chrome 浏览器**
2. **访问 Railway 登录页面：**
   ```
   https://railway.com/login
   ```

3. **登录成功后，获取 API Token：**
   - 点击右上角头像 → Settings
   - 找到 "API Tokens" 部分
   - 点击 "Create Token"
   - 复制生成的 Token

4. **在终端使用 Token 登录：**
   ```bash
   railway login --token YOUR_API_TOKEN
   ```

### 方法2：使用浏览器登录 CLI（备用）

1. **运行无浏览器模式：**
   ```bash
   railway login --browserless
   ```

2. **访问提供的 URL：**
   - 复制终端显示的完整 URL（类似：https://railway.com/cli-login?d=...）
   - 在浏览器中粘贴并访问
   - 确认配对码匹配

3. **确认登录：**
   - 浏览器显示 "Login Successful" 后，返回终端
   - 等待 CLI 确认登录状态

### 方法3：直接 Token 认证（最快）

如果你已经有 Railway API Token：

```bash
# 设置环境变量
export RAILWAY_API_TOKEN="your_token_here"

# 直接验证
railway whoami
```

## 🎯 项目信息确认

**项目ID：** `c27b0b27-1439-42ff-886c-b70b6a633006`

**项目域名：**
- Staging: `https://forever-paws-api-staging.up.railway.app`

## 🚀 登录验证命令

登录成功后，运行以下命令验证：

```bash
# 验证登录状态
railway whoami

# 查看项目列表
railway projects

# 链接到你的项目
railway link --project c27b0b27-1439-42ff-886c-b70b6a633006
```

## 📋 部署准备检查清单

登录成功后，请确认：
- [ ] 已登录 Railway CLI
- [ ] 项目已正确链接
- [ ] IPv6 环境变量已设置
- [ ] 应用已重新部署

## 🔧 故障排除

如果仍然无法登录：

1. **清除 Railway 配置：**
   ```bash
   rm -rf ~/.railway/
   ```

2. **重新安装 CLI：**
   ```bash
   npm uninstall -g @railway/cli
   npm install -g @railway/cli
   ```

3. **检查网络连接：**
   ```bash
   curl -I https://railway.com
   ```

完成登录后，运行部署脚本：
```bash
./deploy-manual.sh
```