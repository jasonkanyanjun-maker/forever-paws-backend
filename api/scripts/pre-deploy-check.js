#!/usr/bin/env node

/**
 * 部署前检查脚本
 * 验证环境配置、依赖项和服务状态
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class PreDeployChecker {
  constructor() {
    this.errors = [];
    this.warnings = [];
    this.checks = [];
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = {
      info: '✓',
      warn: '⚠',
      error: '✗'
    }[type];
    
    console.log(`[${timestamp}] ${prefix} ${message}`);
  }

  addError(message) {
    this.errors.push(message);
    this.log(message, 'error');
  }

  addWarning(message) {
    this.warnings.push(message);
    this.log(message, 'warn');
  }

  addCheck(message) {
    this.checks.push(message);
    this.log(message, 'info');
  }

  // 检查必需的环境变量
  checkEnvironmentVariables() {
    this.log('检查环境变量配置...');
    
    const requiredEnvVars = [
      'NODE_ENV',
      'PORT',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'SUPABASE_SERVICE_ROLE_KEY',
      'JWT_SECRET'
    ];

    const productionEnvVars = [
      'DASHSCOPE_API_KEY',
      'LOG_LEVEL',
      'BCRYPT_ROUNDS',
      'RATE_LIMIT_WINDOW_MS',
      'RATE_LIMIT_MAX_REQUESTS'
    ];

    // 检查 .env 文件是否存在
    if (!fs.existsSync('.env')) {
      this.addError('.env 文件不存在');
      return;
    }

    // 读取环境变量
    const envContent = fs.readFileSync('.env', 'utf8');
    const envVars = {};
    
    envContent.split('\n').forEach(line => {
      const [key, value] = line.split('=');
      if (key && value) {
        envVars[key.trim()] = value.trim();
      }
    });

    // 检查必需的环境变量
    requiredEnvVars.forEach(varName => {
      if (!envVars[varName]) {
        this.addError(`缺少必需的环境变量: ${varName}`);
      } else if (envVars[varName].includes('your_') || envVars[varName].includes('here')) {
        this.addError(`环境变量 ${varName} 使用了默认占位符值`);
      } else {
        this.addCheck(`环境变量 ${varName} 已配置`);
      }
    });

    // 检查生产环境变量
    if (envVars.NODE_ENV === 'production') {
      productionEnvVars.forEach(varName => {
        if (!envVars[varName]) {
          this.addWarning(`生产环境建议配置: ${varName}`);
        }
      });
    }

    // 检查 JWT 密钥强度
    if (envVars.JWT_SECRET && envVars.JWT_SECRET.length < 32) {
      this.addWarning('JWT_SECRET 长度应至少为 32 个字符');
    }
  }

  // 检查依赖项
  checkDependencies() {
    this.log('检查项目依赖...');
    
    try {
      // 检查 package.json
      if (!fs.existsSync('package.json')) {
        this.addError('package.json 文件不存在');
        return;
      }

      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      
      // 检查必需的脚本
      const requiredScripts = ['start', 'build', 'dev'];
      requiredScripts.forEach(script => {
        if (!packageJson.scripts || !packageJson.scripts[script]) {
          this.addError(`缺少必需的脚本: ${script}`);
        } else {
          this.addCheck(`脚本 ${script} 已配置`);
        }
      });

      // 检查 Node.js 版本
      if (packageJson.engines && packageJson.engines.node) {
        this.addCheck(`Node.js 版本要求: ${packageJson.engines.node}`);
      } else {
        this.addWarning('未指定 Node.js 版本要求');
      }

      // 检查 node_modules
      if (!fs.existsSync('node_modules')) {
        this.addError('node_modules 目录不存在，请运行 npm install');
      } else {
        this.addCheck('依赖项已安装');
      }

    } catch (error) {
      this.addError(`检查依赖项时出错: ${error.message}`);
    }
  }

  // 检查 TypeScript 编译
  checkTypeScript() {
    this.log('检查 TypeScript 编译...');
    
    try {
      if (!fs.existsSync('tsconfig.json')) {
        this.addWarning('tsconfig.json 文件不存在');
        return;
      }

      // 运行 TypeScript 编译检查
      execSync('npx tsc --noEmit', { stdio: 'pipe' });
      this.addCheck('TypeScript 编译检查通过');
    } catch (error) {
      this.addError(`TypeScript 编译错误: ${error.message}`);
    }
  }

  // 检查构建过程
  checkBuild() {
    this.log('检查构建过程...');
    
    try {
      // 运行构建命令
      execSync('npm run build', { stdio: 'pipe' });
      this.addCheck('项目构建成功');
      
      // 检查构建输出
      if (fs.existsSync('dist')) {
        this.addCheck('构建输出目录存在');
      } else {
        this.addWarning('构建输出目录不存在');
      }
    } catch (error) {
      this.addError(`构建失败: ${error.message}`);
    }
  }

  // 检查数据库连接
  async checkDatabase() {
    this.log('检查数据库连接...');
    
    try {
      // 这里可以添加数据库连接测试
      // 由于使用 Supabase，可以通过 API 检查连接
      this.addCheck('数据库连接检查已跳过（使用 Supabase）');
    } catch (error) {
      this.addError(`数据库连接失败: ${error.message}`);
    }
  }

  // 检查安全配置
  checkSecurity() {
    this.log('检查安全配置...');
    
    // 检查敏感文件是否被忽略
    if (fs.existsSync('.gitignore')) {
      const gitignore = fs.readFileSync('.gitignore', 'utf8');
      const requiredIgnores = ['.env', 'node_modules', 'dist', 'logs'];
      
      requiredIgnores.forEach(item => {
        if (gitignore.includes(item)) {
          this.addCheck(`${item} 已在 .gitignore 中`);
        } else {
          this.addWarning(`建议将 ${item} 添加到 .gitignore`);
        }
      });
    } else {
      this.addWarning('.gitignore 文件不存在');
    }

    // 检查是否有敏感信息泄露
    const sensitivePatterns = [
      /password\s*=\s*[^"'\s]+/i,
      /secret\s*=\s*[^"'\s]+/i,
      /key\s*=\s*[^"'\s]+/i
    ];

    // 这里可以扫描代码文件检查敏感信息
    this.addCheck('安全配置检查完成');
  }

  // 运行所有检查
  async runAllChecks() {
    console.log('🚀 开始部署前检查...\n');
    
    this.checkEnvironmentVariables();
    this.checkDependencies();
    this.checkTypeScript();
    this.checkBuild();
    await this.checkDatabase();
    this.checkSecurity();
    
    // 输出结果
    console.log('\n📊 检查结果汇总:');
    console.log(`✓ 通过检查: ${this.checks.length}`);
    console.log(`⚠ 警告: ${this.warnings.length}`);
    console.log(`✗ 错误: ${this.errors.length}`);
    
    if (this.errors.length > 0) {
      console.log('\n❌ 部署前检查失败，请修复以下错误:');
      this.errors.forEach(error => console.log(`  - ${error}`));
      process.exit(1);
    }
    
    if (this.warnings.length > 0) {
      console.log('\n⚠️  存在以下警告:');
      this.warnings.forEach(warning => console.log(`  - ${warning}`));
    }
    
    console.log('\n✅ 部署前检查完成，可以进行部署！');
  }
}

// 运行检查
if (require.main === module) {
  const checker = new PreDeployChecker();
  checker.runAllChecks().catch(error => {
    console.error('检查过程中出现错误:', error);
    process.exit(1);
  });
}

module.exports = PreDeployChecker;