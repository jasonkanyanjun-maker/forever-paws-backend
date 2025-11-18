#!/usr/bin/env node

/**
 * Forever Paws 部署验证脚本
 * Production Deployment Validation Script
 * 
 * 用于验证生产环境部署是否成功
 * Validates production deployment success
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

class DeploymentValidator {
    constructor() {
        this.results = {
            passed: 0,
            failed: 0,
            warnings: 0,
            tests: []
        };
        
        // 从环境变量或配置文件读取 API 基础 URL
        this.apiBaseUrl = process.env.API_BASE_URL || 'http://localhost:3000';
        this.productionUrl = process.env.PRODUCTION_API_URL || 'https://your-production-api.railway.app';
        
        console.log('🚀 Forever Paws 部署验证开始');
        console.log('====================================');
    }

    // HTTP 请求工具函数
    async makeRequest(url, options = {}) {
        return new Promise((resolve, reject) => {
            const isHttps = url.startsWith('https');
            const client = isHttps ? https : http;
            
            const req = client.request(url, {
                method: options.method || 'GET',
                headers: options.headers || {},
                timeout: options.timeout || 10000,
                ...options
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        data: data,
                        body: data
                    });
                });
            });

            req.on('error', reject);
            req.on('timeout', () => reject(new Error('Request timeout')));
            
            if (options.body) {
                req.write(options.body);
            }
            
            req.end();
        });
    }

    // 记录测试结果
    logTest(name, passed, message = '', warning = false) {
        const status = warning ? '⚠️' : (passed ? '✅' : '❌');
        const result = {
            name,
            passed: warning ? null : passed,
            warning,
            message,
            timestamp: new Date().toISOString()
        };
        
        this.results.tests.push(result);
        
        if (warning) {
            this.results.warnings++;
            console.log(`${status} ${name}: ${message}`);
        } else if (passed) {
            this.results.passed++;
            console.log(`${status} ${name}`);
        } else {
            this.results.failed++;
            console.log(`${status} ${name}: ${message}`);
        }
    }

    // 1. 基础健康检查
    async testBasicHealth() {
        console.log('\n📊 基础健康检查');
        console.log('------------------');
        
        try {
            // 测试根路径
            const rootResponse = await this.makeRequest(`${this.apiBaseUrl}/api`);
            this.logTest(
                '根路径响应',
                rootResponse.statusCode === 200,
                rootResponse.statusCode !== 200 ? `状态码: ${rootResponse.statusCode}` : ''
            );

            // 测试健康检查端点
            const healthResponse = await this.makeRequest(`${this.apiBaseUrl}/api/health`);
            this.logTest(
                '健康检查端点',
                healthResponse.statusCode === 200,
                healthResponse.statusCode !== 200 ? `状态码: ${healthResponse.statusCode}` : ''
            );

            // 测试详细健康检查
            const detailedHealthResponse = await this.makeRequest(`${this.apiBaseUrl}/api/health/detailed`);
            this.logTest(
                '详细健康检查',
                detailedHealthResponse.statusCode === 200,
                detailedHealthResponse.statusCode !== 200 ? `状态码: ${detailedHealthResponse.statusCode}` : ''
            );

            // 解析健康检查响应
            if (detailedHealthResponse.statusCode === 200) {
                try {
                    const healthData = JSON.parse(detailedHealthResponse.data);
                    this.logTest(
                        '数据库连接',
                        healthData.database?.status === 'healthy',
                        healthData.database?.status !== 'healthy' ? '数据库连接失败' : ''
                    );
                    
                    this.logTest(
                        '系统信息',
                        healthData.system?.status === 'healthy',
                        healthData.system?.status !== 'healthy' ? '系统状态异常' : ''
                    );
                } catch (e) {
                    this.logTest('健康检查数据解析', false, '无法解析健康检查响应');
                }
            }

        } catch (error) {
            this.logTest('基础健康检查', false, `连接失败: ${error.message}`);
        }
    }

    // 2. API 端点测试
    async testApiEndpoints() {
        console.log('\n🔌 API 端点测试');
        console.log('------------------');

        const endpoints = [
            { path: '/api/auth/profile', method: 'GET', requiresAuth: true },
            { path: '/api/pets', method: 'GET', requiresAuth: true },
            { path: '/api/letters', method: 'GET', requiresAuth: true },
            { path: '/api/products', method: 'GET', requiresAuth: false },
            { path: '/api/videos', method: 'GET', requiresAuth: false },
        ];

        for (const endpoint of endpoints) {
            try {
                const response = await this.makeRequest(`${this.apiBaseUrl}${endpoint.path}`, {
                    method: endpoint.method
                });

                if (endpoint.requiresAuth) {
                    // 需要认证的端点应该返回 401
                    this.logTest(
                        `${endpoint.path} (认证检查)`,
                        response.statusCode === 401,
                        response.statusCode !== 401 ? `期望 401，实际 ${response.statusCode}` : ''
                    );
                } else {
                    // 公开端点应该返回 200 或其他成功状态
                    this.logTest(
                        `${endpoint.path} (公开访问)`,
                        response.statusCode < 500,
                        response.statusCode >= 500 ? `服务器错误: ${response.statusCode}` : ''
                    );
                }
            } catch (error) {
                this.logTest(`${endpoint.path}`, false, `请求失败: ${error.message}`);
            }
        }
    }

    // 3. 数据库连接测试
    async testDatabaseConnection() {
        console.log('\n🗄️  数据库连接测试');
        console.log('--------------------');

        try {
            const response = await this.makeRequest(`${this.apiBaseUrl}/api/health/detailed`);
            
            if (response.statusCode === 200) {
                const healthData = JSON.parse(response.data);
                
                if (healthData.database) {
                    this.logTest(
                        '数据库连接状态',
                        healthData.database.status === 'healthy',
                        healthData.database.status !== 'healthy' ? healthData.database.message : ''
                    );

                    if (healthData.database.tables) {
                        const expectedTables = ['users', 'pets', 'letters', 'products', 'orders'];
                        const availableTables = healthData.database.tables;
                        
                        for (const table of expectedTables) {
                            this.logTest(
                                `表 ${table} 存在`,
                                availableTables.includes(table),
                                !availableTables.includes(table) ? '表不存在或无法访问' : ''
                            );
                        }
                    }
                } else {
                    this.logTest('数据库健康检查', false, '无法获取数据库状态信息');
                }
            } else {
                this.logTest('数据库连接测试', false, '无法访问健康检查端点');
            }
        } catch (error) {
            this.logTest('数据库连接测试', false, `测试失败: ${error.message}`);
        }
    }

    // 4. 性能测试
    async testPerformance() {
        console.log('\n⚡ 性能测试');
        console.log('------------');

        const performanceTests = [
            { name: '根路径响应时间', path: '/api' },
            { name: '健康检查响应时间', path: '/api/health' },
            { name: '产品列表响应时间', path: '/api/products' }
        ];

        for (const test of performanceTests) {
            try {
                const startTime = Date.now();
                const response = await this.makeRequest(`${this.apiBaseUrl}${test.path}`);
                const responseTime = Date.now() - startTime;

                this.logTest(
                    test.name,
                    responseTime < 2000,
                    responseTime >= 2000 ? `响应时间: ${responseTime}ms (超过 2 秒)` : `响应时间: ${responseTime}ms`,
                    responseTime >= 1000 && responseTime < 2000
                );
            } catch (error) {
                this.logTest(test.name, false, `性能测试失败: ${error.message}`);
            }
        }
    }

    // 5. 安全性测试
    async testSecurity() {
        console.log('\n🔒 安全性测试');
        console.log('---------------');

        try {
            // 测试 CORS 头
            const response = await this.makeRequest(`${this.apiBaseUrl}/api`, {
                headers: {
                    'Origin': 'https://malicious-site.com'
                }
            });

            const corsHeader = response.headers['access-control-allow-origin'];
            this.logTest(
                'CORS 配置',
                corsHeader !== '*' || corsHeader === undefined,
                corsHeader === '*' ? '警告: 允许所有来源访问' : '',
                corsHeader === '*'
            );

            // 测试安全头
            const securityHeaders = [
                'x-frame-options',
                'x-content-type-options',
                'x-xss-protection'
            ];

            for (const header of securityHeaders) {
                this.logTest(
                    `安全头 ${header}`,
                    response.headers[header] !== undefined,
                    response.headers[header] === undefined ? '缺少安全头' : '',
                    response.headers[header] === undefined
                );
            }

        } catch (error) {
            this.logTest('安全性测试', false, `测试失败: ${error.message}`);
        }
    }

    // 6. 环境变量检查
    async testEnvironmentConfig() {
        console.log('\n🔧 环境配置检查');
        console.log('------------------');

        const requiredEnvVars = [
            'NODE_ENV',
            'PORT',
            'SUPABASE_URL',
            'SUPABASE_ANON_KEY'
        ];

        // 通过健康检查端点获取环境信息
        try {
            const response = await this.makeRequest(`${this.apiBaseUrl}/api/health/detailed`);
            
            if (response.statusCode === 200) {
                const healthData = JSON.parse(response.data);
                
                if (healthData.system && healthData.system.environment) {
                    const env = healthData.system.environment;
                    
                    this.logTest(
                        '生产环境模式',
                        env.NODE_ENV === 'production',
                        env.NODE_ENV !== 'production' ? `当前环境: ${env.NODE_ENV}` : '',
                        env.NODE_ENV !== 'production'
                    );

                    this.logTest(
                        '端口配置',
                        env.PORT !== undefined,
                        env.PORT === undefined ? '端口未配置' : `端口: ${env.PORT}`
                    );
                } else {
                    this.logTest('环境配置检查', false, '无法获取环境配置信息');
                }
            }
        } catch (error) {
            this.logTest('环境配置检查', false, `检查失败: ${error.message}`);
        }
    }

    // 7. 生产环境特定测试
    async testProductionSpecific() {
        console.log('\n🏭 生产环境特定测试');
        console.log('---------------------');

        // 测试生产 URL（如果配置了）
        if (this.productionUrl && this.productionUrl !== this.apiBaseUrl) {
            try {
                const response = await this.makeRequest(`${this.productionUrl}/api/health`);
                this.logTest(
                    '生产环境可访问性',
                    response.statusCode === 200,
                    response.statusCode !== 200 ? `状态码: ${response.statusCode}` : ''
                );
            } catch (error) {
                this.logTest('生产环境可访问性', false, `无法访问生产环境: ${error.message}`);
            }
        }

        // 检查是否有开发环境的调试信息泄露
        try {
            const response = await this.makeRequest(`${this.apiBaseUrl}/api`);
            const hasDebugInfo = response.data.includes('debug') || 
                                response.data.includes('development') ||
                                response.data.includes('localhost');
            
            this.logTest(
                '调试信息泄露检查',
                !hasDebugInfo,
                hasDebugInfo ? '响应中包含调试信息' : '',
                hasDebugInfo
            );
        } catch (error) {
            this.logTest('调试信息检查', false, `检查失败: ${error.message}`);
        }
    }

    // 运行所有测试
    async runAllTests() {
        const startTime = Date.now();
        
        await this.testBasicHealth();
        await this.testApiEndpoints();
        await this.testDatabaseConnection();
        await this.testPerformance();
        await this.testSecurity();
        await this.testEnvironmentConfig();
        await this.testProductionSpecific();

        const duration = Date.now() - startTime;
        
        console.log('\n📋 验证结果汇总');
        console.log('==================');
        console.log(`✅ 通过: ${this.results.passed}`);
        console.log(`❌ 失败: ${this.results.failed}`);
        console.log(`⚠️  警告: ${this.results.warnings}`);
        console.log(`⏱️  耗时: ${duration}ms`);
        
        // 生成详细报告
        this.generateReport();
        
        // 返回验证结果
        const success = this.results.failed === 0;
        console.log(`\n🎯 总体结果: ${success ? '✅ 验证通过' : '❌ 验证失败'}`);
        
        if (!success) {
            console.log('\n🔧 需要修复的问题:');
            this.results.tests
                .filter(test => test.passed === false)
                .forEach(test => {
                    console.log(`   - ${test.name}: ${test.message}`);
                });
        }

        if (this.results.warnings > 0) {
            console.log('\n⚠️  需要注意的警告:');
            this.results.tests
                .filter(test => test.warning)
                .forEach(test => {
                    console.log(`   - ${test.name}: ${test.message}`);
                });
        }

        console.log('\n🚀 部署建议:');
        if (success && this.results.warnings === 0) {
            console.log('   ✅ 可以安全部署到生产环境');
        } else if (success && this.results.warnings > 0) {
            console.log('   ⚠️  可以部署，但建议先处理警告项');
        } else {
            console.log('   ❌ 不建议部署，请先修复失败的测试项');
        }

        return success;
    }

    // 生成详细报告
    generateReport() {
        const reportPath = path.join(__dirname, '../reports');
        
        // 确保报告目录存在
        if (!fs.existsSync(reportPath)) {
            fs.mkdirSync(reportPath, { recursive: true });
        }

        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                passed: this.results.passed,
                failed: this.results.failed,
                warnings: this.results.warnings,
                total: this.results.tests.length
            },
            tests: this.results.tests,
            environment: {
                apiBaseUrl: this.apiBaseUrl,
                productionUrl: this.productionUrl,
                nodeVersion: process.version,
                platform: process.platform
            }
        };

        const reportFile = path.join(reportPath, `deployment-validation-${Date.now()}.json`);
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        console.log(`\n📄 详细报告已保存: ${reportFile}`);
    }
}

// 主执行函数
async function main() {
    const validator = new DeploymentValidator();
    
    try {
        const success = await validator.runAllTests();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 验证过程中发生错误:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = DeploymentValidator;