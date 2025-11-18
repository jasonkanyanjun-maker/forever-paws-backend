#!/usr/bin/env node

/**
 * Forever Paws 监控配置脚本
 * Production Monitoring Setup Script
 * 
 * 用于配置生产环境监控和日志记录
 * Sets up production monitoring and logging
 */

const fs = require('fs');
const path = require('path');

class MonitoringSetup {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        console.log('📊 Forever Paws 监控配置开始');
        console.log('====================================');
    }

    // 创建监控配置文件
    createMonitoringConfig() {
        console.log('\n🔧 创建监控配置文件');
        console.log('----------------------');

        const monitoringConfig = {
            // 应用监控配置
            application: {
                name: 'forever-paws-api',
                version: '1.0.0',
                environment: process.env.NODE_ENV || 'production',
                healthCheck: {
                    enabled: true,
                    interval: 30000, // 30 秒
                    timeout: 5000,   // 5 秒
                    endpoints: [
                        '/api/health',
                        '/api/health/ping',
                        '/api/health/detailed'
                    ]
                }
            },

            // 日志配置
            logging: {
                level: process.env.LOG_LEVEL || 'info',
                format: 'json',
                timestamp: true,
                colorize: false,
                maxFiles: 10,
                maxSize: '10m',
                destinations: [
                    {
                        type: 'console',
                        level: 'info'
                    },
                    {
                        type: 'file',
                        filename: 'logs/app.log',
                        level: 'info'
                    },
                    {
                        type: 'file',
                        filename: 'logs/error.log',
                        level: 'error'
                    }
                ]
            },

            // 性能监控
            performance: {
                enabled: true,
                metrics: {
                    responseTime: true,
                    throughput: true,
                    errorRate: true,
                    memoryUsage: true,
                    cpuUsage: true
                },
                alerts: {
                    responseTime: {
                        threshold: 2000, // 2 秒
                        enabled: true
                    },
                    errorRate: {
                        threshold: 0.05, // 5%
                        enabled: true
                    },
                    memoryUsage: {
                        threshold: 0.8, // 80%
                        enabled: true
                    }
                }
            },

            // 数据库监控
            database: {
                enabled: true,
                connectionPool: {
                    monitor: true,
                    alertOnLowConnections: true,
                    minConnections: 2
                },
                queryPerformance: {
                    enabled: true,
                    slowQueryThreshold: 1000 // 1 秒
                }
            },

            // 外部服务监控
            externalServices: {
                supabase: {
                    enabled: true,
                    healthCheck: true,
                    timeout: 5000
                },
                storage: {
                    enabled: true,
                    healthCheck: true,
                    timeout: 3000
                }
            },

            // 告警配置
            alerts: {
                enabled: true,
                channels: [
                    {
                        type: 'console',
                        enabled: true
                    },
                    {
                        type: 'webhook',
                        enabled: false,
                        url: process.env.ALERT_WEBHOOK_URL || ''
                    }
                ],
                rules: [
                    {
                        name: 'High Error Rate',
                        condition: 'error_rate > 0.05',
                        severity: 'critical',
                        enabled: true
                    },
                    {
                        name: 'Slow Response Time',
                        condition: 'avg_response_time > 2000',
                        severity: 'warning',
                        enabled: true
                    },
                    {
                        name: 'Database Connection Issues',
                        condition: 'db_connection_errors > 0',
                        severity: 'critical',
                        enabled: true
                    }
                ]
            }
        };

        const configPath = path.join(this.projectRoot, 'config', 'monitoring.json');
        this.ensureDirectoryExists(path.dirname(configPath));
        fs.writeFileSync(configPath, JSON.stringify(monitoringConfig, null, 2));
        
        console.log(`✅ 监控配置文件已创建: ${configPath}`);
        return configPath;
    }

    // 创建日志配置
    createLoggingSetup() {
        console.log('\n📝 创建日志配置');
        console.log('------------------');

        // 创建 Winston 日志配置
        const winstonConfig = `
const winston = require('winston');
const path = require('path');

// 确保日志目录存在
const logDir = path.join(__dirname, '../logs');
if (!require('fs').existsSync(logDir)) {
    require('fs').mkdirSync(logDir, { recursive: true });
}

// 自定义日志格式
const logFormat = winston.format.combine(
    winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format.prettyPrint()
);

// 创建 logger 实例
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: {
        service: 'forever-paws-api',
        environment: process.env.NODE_ENV || 'production'
    },
    transports: [
        // 错误日志文件
        new winston.transports.File({
            filename: path.join(logDir, 'error.log'),
            level: 'error',
            maxsize: 10 * 1024 * 1024, // 10MB
            maxFiles: 5,
            tailable: true
        }),
        
        // 综合日志文件
        new winston.transports.File({
            filename: path.join(logDir, 'combined.log'),
            maxsize: 10 * 1024 * 1024, // 10MB
            maxFiles: 10,
            tailable: true
        }),
        
        // 控制台输出
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ],
    
    // 异常处理
    exceptionHandlers: [
        new winston.transports.File({
            filename: path.join(logDir, 'exceptions.log')
        })
    ],
    
    // 拒绝处理
    rejectionHandlers: [
        new winston.transports.File({
            filename: path.join(logDir, 'rejections.log')
        })
    ]
});

// 生产环境下不输出到控制台
if (process.env.NODE_ENV === 'production') {
    logger.remove(logger.transports.find(t => t.name === 'console'));
}

module.exports = logger;
`;

        const loggerPath = path.join(this.projectRoot, 'src', 'utils', 'logger.js');
        this.ensureDirectoryExists(path.dirname(loggerPath));
        fs.writeFileSync(loggerPath, winstonConfig.trim());
        
        console.log(`✅ 日志配置文件已创建: ${loggerPath}`);
        return loggerPath;
    }

    // 创建性能监控中间件
    createPerformanceMiddleware() {
        console.log('\n⚡ 创建性能监控中间件');
        console.log('------------------------');

        const middlewareCode = `
const logger = require('../utils/logger');

// 性能监控中间件
const performanceMonitor = (req, res, next) => {
    const startTime = Date.now();
    const startMemory = process.memoryUsage();
    
    // 监听响应完成
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const endMemory = process.memoryUsage();
        
        // 记录请求信息
        const logData = {
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            responseTime: duration,
            userAgent: req.get('User-Agent'),
            ip: req.ip || req.connection.remoteAddress,
            memory: {
                heapUsed: endMemory.heapUsed - startMemory.heapUsed,
                heapTotal: endMemory.heapTotal,
                external: endMemory.external
            },
            timestamp: new Date().toISOString()
        };
        
        // 根据响应时间和状态码决定日志级别
        if (res.statusCode >= 500) {
            logger.error('Server Error', logData);
        } else if (res.statusCode >= 400) {
            logger.warn('Client Error', logData);
        } else if (duration > 2000) {
            logger.warn('Slow Response', logData);
        } else {
            logger.info('Request Completed', logData);
        }
        
        // 性能告警
        if (duration > 5000) {
            logger.error('Performance Alert: Very Slow Response', {
                ...logData,
                alert: 'SLOW_RESPONSE',
                threshold: 5000
            });
        }
        
        if (endMemory.heapUsed > 100 * 1024 * 1024) { // 100MB
            logger.warn('Memory Usage Alert', {
                ...logData,
                alert: 'HIGH_MEMORY',
                heapUsed: endMemory.heapUsed
            });
        }
    });
    
    next();
};

// 错误监控中间件
const errorMonitor = (err, req, res, next) => {
    const errorData = {
        error: {
            message: err.message,
            stack: err.stack,
            name: err.name
        },
        request: {
            method: req.method,
            url: req.url,
            headers: req.headers,
            body: req.body,
            params: req.params,
            query: req.query
        },
        timestamp: new Date().toISOString()
    };
    
    logger.error('Unhandled Error', errorData);
    
    // 发送错误响应
    if (!res.headersSent) {
        res.status(500).json({
            error: 'Internal Server Error',
            message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
        });
    }
    
    next(err);
};

// 健康检查监控
const healthMonitor = () => {
    const healthData = {
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        cpu: process.cpuUsage(),
        version: process.version,
        platform: process.platform,
        environment: process.env.NODE_ENV
    };
    
    logger.info('Health Check', healthData);
    return healthData;
};

module.exports = {
    performanceMonitor,
    errorMonitor,
    healthMonitor
};
`;

        const middlewarePath = path.join(this.projectRoot, 'src', 'middleware', 'monitoring.js');
        this.ensureDirectoryExists(path.dirname(middlewarePath));
        fs.writeFileSync(middlewarePath, middlewareCode.trim());
        
        console.log(`✅ 性能监控中间件已创建: ${middlewarePath}`);
        return middlewarePath;
    }

    // 创建系统监控脚本
    createSystemMonitor() {
        console.log('\n🖥️  创建系统监控脚本');
        console.log('----------------------');

        const systemMonitorCode = `
#!/usr/bin/env node

const logger = require('../src/utils/logger');
const os = require('os');
const fs = require('fs');

class SystemMonitor {
    constructor() {
        this.metrics = {
            cpu: [],
            memory: [],
            disk: [],
            network: []
        };
        
        this.thresholds = {
            cpu: 80,      // 80%
            memory: 85,   // 85%
            disk: 90      // 90%
        };
    }
    
    // 获取 CPU 使用率
    getCPUUsage() {
        const cpus = os.cpus();
        let totalIdle = 0;
        let totalTick = 0;
        
        cpus.forEach(cpu => {
            for (const type in cpu.times) {
                totalTick += cpu.times[type];
            }
            totalIdle += cpu.times.idle;
        });
        
        const idle = totalIdle / cpus.length;
        const total = totalTick / cpus.length;
        const usage = 100 - ~~(100 * idle / total);
        
        return {
            usage,
            cores: cpus.length,
            model: cpus[0].model,
            speed: cpus[0].speed
        };
    }
    
    // 获取内存使用情况
    getMemoryUsage() {
        const total = os.totalmem();
        const free = os.freemem();
        const used = total - free;
        const usage = (used / total) * 100;
        
        return {
            total: Math.round(total / 1024 / 1024), // MB
            used: Math.round(used / 1024 / 1024),   // MB
            free: Math.round(free / 1024 / 1024),   // MB
            usage: Math.round(usage)
        };
    }
    
    // 获取磁盘使用情况
    getDiskUsage() {
        try {
            const stats = fs.statSync('.');
            // 简化的磁盘使用情况，实际生产环境可能需要更复杂的实现
            return {
                available: true,
                path: process.cwd()
            };
        } catch (error) {
            return {
                available: false,
                error: error.message
            };
        }
    }
    
    // 获取网络信息
    getNetworkInfo() {
        const interfaces = os.networkInterfaces();
        const networkInfo = {};
        
        for (const name in interfaces) {
            networkInfo[name] = interfaces[name].filter(iface => 
                iface.family === 'IPv4' && !iface.internal
            );
        }
        
        return networkInfo;
    }
    
    // 检查系统健康状态
    checkSystemHealth() {
        const cpu = this.getCPUUsage();
        const memory = this.getMemoryUsage();
        const disk = this.getDiskUsage();
        const network = this.getNetworkInfo();
        
        const health = {
            timestamp: new Date().toISOString(),
            system: {
                hostname: os.hostname(),
                platform: os.platform(),
                arch: os.arch(),
                uptime: os.uptime(),
                loadavg: os.loadavg()
            },
            cpu,
            memory,
            disk,
            network,
            process: {
                pid: process.pid,
                uptime: process.uptime(),
                memory: process.memoryUsage(),
                cpu: process.cpuUsage()
            }
        };
        
        // 检查告警条件
        const alerts = [];
        
        if (cpu.usage > this.thresholds.cpu) {
            alerts.push({
                type: 'CPU_HIGH',
                message: \`CPU usage is \${cpu.usage}% (threshold: \${this.thresholds.cpu}%)\`,
                severity: 'warning'
            });
        }
        
        if (memory.usage > this.thresholds.memory) {
            alerts.push({
                type: 'MEMORY_HIGH',
                message: \`Memory usage is \${memory.usage}% (threshold: \${this.thresholds.memory}%)\`,
                severity: 'warning'
            });
        }
        
        health.alerts = alerts;
        
        // 记录系统状态
        if (alerts.length > 0) {
            logger.warn('System Health Alert', health);
        } else {
            logger.info('System Health Check', health);
        }
        
        return health;
    }
    
    // 启动监控
    startMonitoring(interval = 60000) { // 默认 1 分钟
        logger.info('System monitoring started', { interval });
        
        setInterval(() => {
            this.checkSystemHealth();
        }, interval);
        
        // 立即执行一次
        this.checkSystemHealth();
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    const monitor = new SystemMonitor();
    monitor.startMonitoring();
    
    // 优雅关闭
    process.on('SIGINT', () => {
        logger.info('System monitoring stopped');
        process.exit(0);
    });
}

module.exports = SystemMonitor;
`;

        const systemMonitorPath = path.join(this.projectRoot, 'scripts', 'system-monitor.js');
        fs.writeFileSync(systemMonitorPath, systemMonitorCode.trim());
        
        console.log(`✅ 系统监控脚本已创建: ${systemMonitorPath}`);
        return systemMonitorPath;
    }

    // 更新 package.json 添加监控脚本
    updatePackageJson() {
        console.log('\n📦 更新 package.json');
        console.log('--------------------');

        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

        // 添加监控相关的脚本
        packageJson.scripts = {
            ...packageJson.scripts,
            'monitor': 'node scripts/system-monitor.js',
            'validate-deployment': 'node scripts/deployment-validation.js',
            'logs:view': 'tail -f logs/combined.log',
            'logs:error': 'tail -f logs/error.log',
            'logs:clear': 'rm -rf logs/*.log'
        };

        // 添加监控相关依赖
        if (!packageJson.dependencies.winston) {
            packageJson.dependencies.winston = '^3.8.2';
        }

        fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
        console.log('✅ package.json 已更新');
    }

    // 创建 PM2 配置文件
    createPM2Config() {
        console.log('\n🔄 创建 PM2 配置');
        console.log('------------------');

        const pm2Config = {
            apps: [
                {
                    name: 'forever-paws-api',
                    script: 'src/index.js',
                    instances: 'max',
                    exec_mode: 'cluster',
                    env: {
                        NODE_ENV: 'production',
                        PORT: 3000
                    },
                    env_production: {
                        NODE_ENV: 'production',
                        PORT: process.env.PORT || 3000
                    },
                    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
                    error_file: 'logs/pm2-error.log',
                    out_file: 'logs/pm2-out.log',
                    log_file: 'logs/pm2-combined.log',
                    time: true,
                    autorestart: true,
                    max_restarts: 10,
                    min_uptime: '10s',
                    max_memory_restart: '1G',
                    node_args: '--max-old-space-size=1024',
                    watch: false,
                    ignore_watch: ['node_modules', 'logs'],
                    merge_logs: true,
                    kill_timeout: 5000
                },
                {
                    name: 'forever-paws-monitor',
                    script: 'scripts/system-monitor.js',
                    instances: 1,
                    exec_mode: 'fork',
                    env: {
                        NODE_ENV: 'production'
                    },
                    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
                    error_file: 'logs/monitor-error.log',
                    out_file: 'logs/monitor-out.log',
                    autorestart: true,
                    max_restarts: 5,
                    min_uptime: '30s'
                }
            ]
        };

        const pm2ConfigPath = path.join(this.projectRoot, 'ecosystem.config.js');
        const configContent = `module.exports = ${JSON.stringify(pm2Config, null, 2)};`;
        fs.writeFileSync(pm2ConfigPath, configContent);
        
        console.log(`✅ PM2 配置文件已创建: ${pm2ConfigPath}`);
        return pm2ConfigPath;
    }

    // 确保目录存在
    ensureDirectoryExists(dirPath) {
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }
    }

    // 运行完整设置
    async setupMonitoring() {
        try {
            // 创建必要的目录
            this.ensureDirectoryExists(path.join(this.projectRoot, 'logs'));
            this.ensureDirectoryExists(path.join(this.projectRoot, 'config'));
            this.ensureDirectoryExists(path.join(this.projectRoot, 'reports'));

            // 执行所有设置步骤
            this.createMonitoringConfig();
            this.createLoggingSetup();
            this.createPerformanceMiddleware();
            this.createSystemMonitor();
            this.updatePackageJson();
            this.createPM2Config();

            console.log('\n🎉 监控配置完成');
            console.log('==================');
            console.log('✅ 监控配置文件已创建');
            console.log('✅ 日志系统已配置');
            console.log('✅ 性能监控中间件已创建');
            console.log('✅ 系统监控脚本已创建');
            console.log('✅ PM2 配置已创建');
            console.log('✅ package.json 已更新');

            console.log('\n📋 下一步操作:');
            console.log('1. 安装 Winston 依赖: npm install winston');
            console.log('2. 在应用中集成监控中间件');
            console.log('3. 配置生产环境变量');
            console.log('4. 使用 PM2 启动应用: pm2 start ecosystem.config.js');
            console.log('5. 运行部署验证: npm run validate-deployment');

            return true;
        } catch (error) {
            console.error('❌ 监控配置失败:', error.message);
            return false;
        }
    }
}

// 主执行函数
async function main() {
    const setup = new MonitoringSetup();
    const success = await setup.setupMonitoring();
    process.exit(success ? 0 : 1);
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = MonitoringSetup;