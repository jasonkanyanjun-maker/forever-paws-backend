#!/usr/bin/env node

/**
 * 健康检查工具
 * 用于检查服务器和相关服务的健康状态
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

class HealthChecker {
  constructor(options = {}) {
    this.timeout = options.timeout || 10000;
    this.retries = options.retries || 3;
    this.retryDelay = options.retryDelay || 1000;
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = {
      info: '✓',
      warn: '⚠',
      error: '✗',
      debug: '🔍'
    }[type];
    
    console.log(`[${timestamp}] ${prefix} ${message}`);
  }

  // HTTP 请求工具
  async makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      const client = urlObj.protocol === 'https:' ? https : http;
      
      const requestOptions = {
        hostname: urlObj.hostname,
        port: urlObj.port,
        path: urlObj.pathname + urlObj.search,
        method: options.method || 'GET',
        timeout: this.timeout,
        headers: {
          'User-Agent': 'HealthChecker/1.0',
          ...options.headers
        }
      };

      const req = client.request(requestOptions, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
            responseTime: Date.now() - startTime
          });
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      const startTime = Date.now();
      req.end();
    });
  }

  // 重试机制
  async withRetry(fn, context = '') {
    let lastError;
    
    for (let i = 0; i < this.retries; i++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error;
        
        if (i < this.retries - 1) {
          this.log(`${context} 失败，${this.retryDelay}ms 后重试... (${i + 1}/${this.retries})`, 'warn');
          await new Promise(resolve => setTimeout(resolve, this.retryDelay));
        }
      }
    }
    
    throw lastError;
  }

  // 检查 API 服务器健康状态
  async checkApiHealth(baseUrl) {
    this.log(`检查 API 服务器健康状态: ${baseUrl}`);
    
    try {
      const response = await this.withRetry(
        () => this.makeRequest(`${baseUrl}/api/health`),
        'API 健康检查'
      );
      
      if (response.statusCode === 200) {
        const healthData = JSON.parse(response.body);
        this.log(`API 服务器健康 - 响应时间: ${response.responseTime}ms`);
        this.log(`服务状态: ${healthData.status || 'unknown'}`);
        
        if (healthData.timestamp) {
          this.log(`服务器时间: ${healthData.timestamp}`);
        }
        
        return {
          status: 'healthy',
          responseTime: response.responseTime,
          data: healthData
        };
      } else {
        throw new Error(`健康检查返回状态码: ${response.statusCode}`);
      }
    } catch (error) {
      this.log(`API 服务器健康检查失败: ${error.message}`, 'error');
      return {
        status: 'unhealthy',
        error: error.message
      };
    }
  }

  // 检查数据库连接
  async checkDatabase(baseUrl) {
    this.log('检查数据库连接...');
    
    try {
      const response = await this.withRetry(
        () => this.makeRequest(`${baseUrl}/api/health/database`),
        '数据库连接检查'
      );
      
      if (response.statusCode === 200) {
        const dbData = JSON.parse(response.body);
        this.log(`数据库连接正常 - 响应时间: ${response.responseTime}ms`);
        
        return {
          status: 'healthy',
          responseTime: response.responseTime,
          data: dbData
        };
      } else {
        throw new Error(`数据库检查返回状态码: ${response.statusCode}`);
      }
    } catch (error) {
      this.log(`数据库连接检查失败: ${error.message}`, 'error');
      return {
        status: 'unhealthy',
        error: error.message
      };
    }
  }

  // 检查外部服务依赖
  async checkExternalServices() {
    this.log('检查外部服务依赖...');
    
    const services = [
      {
        name: 'Supabase',
        url: process.env.SUPABASE_URL,
        path: '/rest/v1/'
      },
      {
        name: 'DashScope API',
        url: process.env.DASHSCOPE_BASE_URL || 'https://dashscope.aliyuncs.com',
        path: '/api/v1/services/aigc/text-generation/generation'
      }
    ];

    const results = {};

    for (const service of services) {
      if (!service.url) {
        this.log(`${service.name} URL 未配置`, 'warn');
        results[service.name] = { status: 'not_configured' };
        continue;
      }

      try {
        const response = await this.withRetry(
          () => this.makeRequest(service.url + service.path),
          `${service.name} 连接检查`
        );
        
        this.log(`${service.name} 连接正常 - 响应时间: ${response.responseTime}ms`);
        results[service.name] = {
          status: 'healthy',
          responseTime: response.responseTime
        };
      } catch (error) {
        this.log(`${service.name} 连接失败: ${error.message}`, 'error');
        results[service.name] = {
          status: 'unhealthy',
          error: error.message
        };
      }
    }

    return results;
  }

  // 检查系统资源
  async checkSystemResources() {
    this.log('检查系统资源...');
    
    const memoryUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();
    
    const memoryMB = {
      rss: Math.round(memoryUsage.rss / 1024 / 1024),
      heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
      heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
      external: Math.round(memoryUsage.external / 1024 / 1024)
    };
    
    this.log(`内存使用情况:`);
    this.log(`  RSS: ${memoryMB.rss} MB`);
    this.log(`  Heap Total: ${memoryMB.heapTotal} MB`);
    this.log(`  Heap Used: ${memoryMB.heapUsed} MB`);
    this.log(`  External: ${memoryMB.external} MB`);
    
    // 检查内存使用是否过高
    const heapUsagePercent = (memoryUsage.heapUsed / memoryUsage.heapTotal) * 100;
    if (heapUsagePercent > 80) {
      this.log(`内存使用率过高: ${heapUsagePercent.toFixed(2)}%`, 'warn');
    }
    
    return {
      memory: memoryMB,
      heapUsagePercent: heapUsagePercent.toFixed(2),
      uptime: process.uptime()
    };
  }

  // 检查环境配置
  checkEnvironmentConfig() {
    this.log('检查环境配置...');
    
    const requiredEnvVars = [
      'NODE_ENV',
      'PORT',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'JWT_SECRET'
    ];

    const missingVars = [];
    const configuredVars = [];

    requiredEnvVars.forEach(varName => {
      if (process.env[varName]) {
        configuredVars.push(varName);
      } else {
        missingVars.push(varName);
      }
    });

    this.log(`已配置环境变量: ${configuredVars.length}/${requiredEnvVars.length}`);
    
    if (missingVars.length > 0) {
      this.log(`缺少环境变量: ${missingVars.join(', ')}`, 'warn');
    }

    return {
      configured: configuredVars,
      missing: missingVars,
      nodeEnv: process.env.NODE_ENV,
      port: process.env.PORT
    };
  }

  // 执行完整的健康检查
  async runFullHealthCheck(baseUrl) {
    console.log('🏥 开始完整健康检查...\n');
    
    const results = {
      timestamp: new Date().toISOString(),
      overall: 'healthy',
      checks: {}
    };

    try {
      // API 健康检查
      results.checks.api = await this.checkApiHealth(baseUrl);
      
      // 数据库检查
      results.checks.database = await this.checkDatabase(baseUrl);
      
      // 外部服务检查
      results.checks.externalServices = await this.checkExternalServices();
      
      // 系统资源检查
      results.checks.systemResources = await this.checkSystemResources();
      
      // 环境配置检查
      results.checks.environment = this.checkEnvironmentConfig();
      
      // 判断整体健康状态
      const hasUnhealthyServices = Object.values(results.checks).some(check => {
        if (check.status) {
          return check.status === 'unhealthy';
        }
        if (typeof check === 'object') {
          return Object.values(check).some(subCheck => 
            subCheck && subCheck.status === 'unhealthy'
          );
        }
        return false;
      });
      
      if (hasUnhealthyServices) {
        results.overall = 'degraded';
      }
      
    } catch (error) {
      this.log(`健康检查过程中出现错误: ${error.message}`, 'error');
      results.overall = 'unhealthy';
      results.error = error.message;
    }

    // 输出结果摘要
    console.log('\n📊 健康检查结果摘要:');
    console.log(`整体状态: ${results.overall.toUpperCase()}`);
    
    if (results.overall === 'healthy') {
      console.log('✅ 所有服务运行正常');
    } else if (results.overall === 'degraded') {
      console.log('⚠️  部分服务存在问题');
    } else {
      console.log('❌ 服务存在严重问题');
    }

    return results;
  }

  // 持续监控模式
  async startMonitoring(baseUrl, interval = 30000) {
    console.log(`🔄 开始持续监控模式 (间隔: ${interval/1000}秒)\n`);
    
    const runCheck = async () => {
      try {
        const results = await this.runFullHealthCheck(baseUrl);
        
        if (results.overall !== 'healthy') {
          console.log('⚠️  检测到服务异常，请检查日志');
        }
        
        console.log(`下次检查时间: ${new Date(Date.now() + interval).toLocaleString()}\n`);
      } catch (error) {
        this.log(`监控检查失败: ${error.message}`, 'error');
      }
    };

    // 立即执行一次检查
    await runCheck();
    
    // 设置定时检查
    setInterval(runCheck, interval);
  }
}

// 命令行接口
async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'check';
  const baseUrl = args[1] || process.env.API_BASE_URL || 'http://localhost:3000';
  
  const checker = new HealthChecker({
    timeout: 10000,
    retries: 3,
    retryDelay: 1000
  });

  try {
    switch (command) {
      case 'check':
        const results = await checker.runFullHealthCheck(baseUrl);
        console.log('\n📋 详细结果:');
        console.log(JSON.stringify(results, null, 2));
        
        // 根据结果设置退出码
        process.exit(results.overall === 'healthy' ? 0 : 1);
        break;
        
      case 'monitor':
        const interval = parseInt(args[2]) || 30000;
        await checker.startMonitoring(baseUrl, interval);
        break;
        
      case 'api':
        const apiResult = await checker.checkApiHealth(baseUrl);
        console.log(JSON.stringify(apiResult, null, 2));
        process.exit(apiResult.status === 'healthy' ? 0 : 1);
        break;
        
      default:
        console.log('健康检查工具使用方法:');
        console.log('  node health-check.js check [baseUrl]     # 执行完整健康检查');
        console.log('  node health-check.js monitor [baseUrl] [interval]  # 持续监控模式');
        console.log('  node health-check.js api [baseUrl]       # 仅检查 API 健康状态');
        console.log('');
        console.log('参数:');
        console.log('  baseUrl   API 服务器地址 (默认: http://localhost:3000)');
        console.log('  interval  监控间隔毫秒数 (默认: 30000)');
        break;
    }
  } catch (error) {
    console.error('健康检查失败:', error.message);
    process.exit(1);
  }
}

// 运行主程序
if (require.main === module) {
  main().catch(error => {
    console.error('程序执行失败:', error);
    process.exit(1);
  });
}

module.exports = HealthChecker;