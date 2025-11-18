#!/usr/bin/env node

/**
 * Forever Paws 安全审计脚本
 * Security Audit Script
 * 
 * 用于检查生产环境的安全配置和潜在风险
 * Checks production security configuration and potential risks
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class SecurityAuditor {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        this.results = {
            passed: 0,
            failed: 0,
            warnings: 0,
            critical: 0,
            checks: []
        };
        
        console.log('🔒 Forever Paws 安全审计开始');
        console.log('====================================');
    }

    // 记录检查结果
    logCheck(name, passed, message = '', severity = 'info') {
        const severityIcons = {
            critical: '🚨',
            warning: '⚠️',
            info: '✅',
            error: '❌'
        };
        
        const icon = passed ? severityIcons.info : severityIcons[severity] || severityIcons.error;
        const result = {
            name,
            passed,
            message,
            severity,
            timestamp: new Date().toISOString()
        };
        
        this.results.checks.push(result);
        
        if (passed) {
            this.results.passed++;
            console.log(`${icon} ${name}`);
        } else {
            if (severity === 'critical') {
                this.results.critical++;
            } else if (severity === 'warning') {
                this.results.warnings++;
            } else {
                this.results.failed++;
            }
            console.log(`${icon} ${name}: ${message}`);
        }
    }

    // 1. 环境变量安全检查
    checkEnvironmentSecurity() {
        console.log('\n🔐 环境变量安全检查');
        console.log('----------------------');

        const envFiles = ['.env', '.env.production', '.env.local'];
        const sensitivePatterns = [
            /password/i,
            /secret/i,
            /key/i,
            /token/i,
            /auth/i
        ];

        envFiles.forEach(envFile => {
            const envPath = path.join(this.projectRoot, envFile);
            
            if (fs.existsSync(envPath)) {
                const content = fs.readFileSync(envPath, 'utf8');
                
                // 检查是否有明文密码
                const hasPlaintextSecrets = sensitivePatterns.some(pattern => 
                    content.match(new RegExp(`${pattern.source}.*=.*[^\\s]`, 'i'))
                );
                
                this.logCheck(
                    `${envFile} 敏感信息检查`,
                    !hasPlaintextSecrets,
                    hasPlaintextSecrets ? '发现可能的明文敏感信息' : '',
                    'warning'
                );

                // 检查文件权限（在 Unix 系统上）
                if (process.platform !== 'win32') {
                    try {
                        const stats = fs.statSync(envPath);
                        const mode = stats.mode & parseInt('777', 8);
                        const isSecure = mode <= parseInt('600', 8); // 只有所有者可读写
                        
                        this.logCheck(
                            `${envFile} 文件权限`,
                            isSecure,
                            !isSecure ? `权限过于宽松: ${mode.toString(8)}` : '',
                            'warning'
                        );
                    } catch (error) {
                        this.logCheck(`${envFile} 权限检查`, false, error.message, 'warning');
                    }
                }
            }
        });

        // 检查是否有 .env 文件被意外提交
        const gitignorePath = path.join(this.projectRoot, '.gitignore');
        if (fs.existsSync(gitignorePath)) {
            const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
            const ignoresEnv = gitignoreContent.includes('.env');
            
            this.logCheck(
                '.env 文件 Git 忽略',
                ignoresEnv,
                !ignoresEnv ? '.env 文件可能被意外提交到版本控制' : '',
                'critical'
            );
        }
    }

    // 2. 依赖安全检查
    checkDependencySecurity() {
        console.log('\n📦 依赖安全检查');
        console.log('------------------');

        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        
        if (fs.existsSync(packageJsonPath)) {
            const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
            
            // 检查是否有已知的不安全依赖
            const knownVulnerableDeps = [
                'lodash@4.17.20', // 示例，实际应该从安全数据库获取
                'moment@2.29.1'   // 示例
            ];
            
            const allDeps = {
                ...packageJson.dependencies,
                ...packageJson.devDependencies
            };
            
            let hasVulnerableDeps = false;
            for (const [dep, version] of Object.entries(allDeps)) {
                const depString = `${dep}@${version}`;
                if (knownVulnerableDeps.includes(depString)) {
                    hasVulnerableDeps = true;
                    break;
                }
            }
            
            this.logCheck(
                '已知漏洞依赖检查',
                !hasVulnerableDeps,
                hasVulnerableDeps ? '发现已知存在漏洞的依赖' : '',
                'critical'
            );

            // 检查是否使用了不安全的依赖版本范围
            const hasWildcardVersions = Object.values(allDeps).some(version => 
                version.includes('*') || version.includes('x')
            );
            
            this.logCheck(
                '依赖版本固定',
                !hasWildcardVersions,
                hasWildcardVersions ? '使用了通配符版本，可能引入不安全的更新' : '',
                'warning'
            );
        }
    }

    // 3. 代码安全检查
    checkCodeSecurity() {
        console.log('\n💻 代码安全检查');
        console.log('------------------');

        const srcPath = path.join(this.projectRoot, 'src');
        
        if (fs.existsSync(srcPath)) {
            const jsFiles = this.findFiles(srcPath, /\.(js|ts)$/);
            
            let hasConsoleLog = false;
            let hasEval = false;
            let hasHardcodedSecrets = false;
            
            jsFiles.forEach(file => {
                const content = fs.readFileSync(file, 'utf8');
                
                // 检查 console.log（生产环境不应该有）
                if (content.includes('console.log') && !content.includes('// TODO: remove')) {
                    hasConsoleLog = true;
                }
                
                // 检查 eval 使用
                if (content.includes('eval(')) {
                    hasEval = true;
                }
                
                // 检查硬编码的密钥
                const secretPatterns = [
                    /sk_[a-zA-Z0-9]{24,}/,  // Stripe secret key
                    /pk_[a-zA-Z0-9]{24,}/,  // Stripe public key
                    /[a-zA-Z0-9]{32,}/      // 长字符串可能是密钥
                ];
                
                if (secretPatterns.some(pattern => pattern.test(content))) {
                    hasHardcodedSecrets = true;
                }
            });
            
            this.logCheck(
                '生产环境 console.log',
                !hasConsoleLog,
                hasConsoleLog ? '代码中存在 console.log 语句' : '',
                'warning'
            );
            
            this.logCheck(
                'eval() 使用检查',
                !hasEval,
                hasEval ? '代码中使用了不安全的 eval()' : '',
                'critical'
            );
            
            this.logCheck(
                '硬编码密钥检查',
                !hasHardcodedSecrets,
                hasHardcodedSecrets ? '代码中可能存在硬编码的密钥' : '',
                'critical'
            );
        }
    }

    // 4. API 安全检查
    checkApiSecurity() {
        console.log('\n🌐 API 安全检查');
        console.log('------------------');

        const routesPath = path.join(this.projectRoot, 'src', 'routes');
        
        if (fs.existsSync(routesPath)) {
            const routeFiles = this.findFiles(routesPath, /\.(js|ts)$/);
            
            let hasRateLimit = false;
            let hasInputValidation = false;
            let hasAuthMiddleware = false;
            let hasErrorHandling = false;
            
            routeFiles.forEach(file => {
                const content = fs.readFileSync(file, 'utf8');
                
                // 检查速率限制
                if (content.includes('rateLimit') || content.includes('rate-limit')) {
                    hasRateLimit = true;
                }
                
                // 检查输入验证
                if (content.includes('validate') || content.includes('joi') || content.includes('yup')) {
                    hasInputValidation = true;
                }
                
                // 检查认证中间件
                if (content.includes('auth') || content.includes('jwt') || content.includes('token')) {
                    hasAuthMiddleware = true;
                }
                
                // 检查错误处理
                if (content.includes('try') && content.includes('catch')) {
                    hasErrorHandling = true;
                }
            });
            
            this.logCheck(
                'API 速率限制',
                hasRateLimit,
                !hasRateLimit ? '未发现速率限制配置' : '',
                'warning'
            );
            
            this.logCheck(
                'API 输入验证',
                hasInputValidation,
                !hasInputValidation ? '未发现输入验证机制' : '',
                'critical'
            );
            
            this.logCheck(
                'API 认证机制',
                hasAuthMiddleware,
                !hasAuthMiddleware ? '未发现认证中间件' : '',
                'critical'
            );
            
            this.logCheck(
                'API 错误处理',
                hasErrorHandling,
                !hasErrorHandling ? '缺少适当的错误处理' : '',
                'warning'
            );
        }
    }

    // 5. 数据库安全检查
    checkDatabaseSecurity() {
        console.log('\n🗄️  数据库安全检查');
        console.log('--------------------');

        const migrationsPath = path.join(this.projectRoot, '../supabase/migrations');
        
        if (fs.existsSync(migrationsPath)) {
            const migrationFiles = this.findFiles(migrationsPath, /\.sql$/);
            
            let hasRLS = false;
            let hasProperPermissions = false;
            let hasIndexes = false;
            
            migrationFiles.forEach(file => {
                const content = fs.readFileSync(file, 'utf8').toLowerCase();
                
                // 检查 RLS 策略
                if (content.includes('row level security') || content.includes('enable rls')) {
                    hasRLS = true;
                }
                
                // 检查权限配置
                if (content.includes('grant')) {
                    hasProperPermissions = true;
                }
                
                // 检查索引
                if (content.includes('create index')) {
                    hasIndexes = true;
                }
            });
            
            this.logCheck(
                '数据库 RLS 策略',
                hasRLS,
                !hasRLS ? '未发现行级安全策略配置' : '',
                'critical'
            );
            
            this.logCheck(
                '数据库权限配置',
                hasProperPermissions,
                !hasProperPermissions ? '未发现适当的权限配置' : '',
                'critical'
            );
            
            this.logCheck(
                '数据库索引优化',
                hasIndexes,
                !hasIndexes ? '未发现性能优化索引' : '',
                'warning'
            );
        }
    }

    // 6. 配置文件安全检查
    checkConfigSecurity() {
        console.log('\n⚙️  配置文件安全检查');
        console.log('----------------------');

        // 检查 Railway 配置
        const railwayConfigPath = path.join(this.projectRoot, 'railway.toml');
        if (fs.existsSync(railwayConfigPath)) {
            const content = fs.readFileSync(railwayConfigPath, 'utf8');
            
            const hasHealthCheck = content.includes('healthcheck');
            const hasProperBuild = content.includes('build');
            
            this.logCheck(
                'Railway 健康检查配置',
                hasHealthCheck,
                !hasHealthCheck ? '缺少健康检查配置' : '',
                'warning'
            );
            
            this.logCheck(
                'Railway 构建配置',
                hasProperBuild,
                !hasProperBuild ? '缺少构建配置' : '',
                'warning'
            );
        }

        // 检查 package.json 安全配置
        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        if (fs.existsSync(packageJsonPath)) {
            const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
            
            const hasSecurityScripts = packageJson.scripts && 
                (packageJson.scripts['security-check'] || packageJson.scripts['audit']);
            
            this.logCheck(
                'package.json 安全脚本',
                hasSecurityScripts,
                !hasSecurityScripts ? '缺少安全检查脚本' : '',
                'warning'
            );
        }
    }

    // 7. 生成安全报告
    generateSecurityReport() {
        console.log('\n📊 生成安全报告');
        console.log('------------------');

        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                total: this.results.checks.length,
                passed: this.results.passed,
                failed: this.results.failed,
                warnings: this.results.warnings,
                critical: this.results.critical
            },
            checks: this.results.checks,
            recommendations: this.generateRecommendations(),
            riskLevel: this.calculateRiskLevel()
        };

        const reportsDir = path.join(this.projectRoot, 'reports');
        if (!fs.existsSync(reportsDir)) {
            fs.mkdirSync(reportsDir, { recursive: true });
        }

        const reportFile = path.join(reportsDir, `security-audit-${Date.now()}.json`);
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        console.log(`✅ 安全报告已生成: ${reportFile}`);
        return report;
    }

    // 生成安全建议
    generateRecommendations() {
        const recommendations = [];
        
        if (this.results.critical > 0) {
            recommendations.push({
                priority: 'critical',
                message: '立即修复关键安全问题，不建议部署到生产环境'
            });
        }
        
        if (this.results.failed > 0) {
            recommendations.push({
                priority: 'high',
                message: '修复失败的安全检查项'
            });
        }
        
        if (this.results.warnings > 0) {
            recommendations.push({
                priority: 'medium',
                message: '处理安全警告，提高系统安全性'
            });
        }
        
        // 通用安全建议
        recommendations.push(
            {
                priority: 'medium',
                message: '定期更新依赖包，修复已知漏洞'
            },
            {
                priority: 'medium',
                message: '实施定期安全审计和渗透测试'
            },
            {
                priority: 'low',
                message: '配置安全监控和告警系统'
            }
        );
        
        return recommendations;
    }

    // 计算风险等级
    calculateRiskLevel() {
        if (this.results.critical > 0) {
            return 'CRITICAL';
        } else if (this.results.failed > 2) {
            return 'HIGH';
        } else if (this.results.warnings > 3) {
            return 'MEDIUM';
        } else {
            return 'LOW';
        }
    }

    // 查找文件的辅助函数
    findFiles(dir, pattern) {
        const files = [];
        
        const scan = (currentDir) => {
            const items = fs.readdirSync(currentDir);
            
            items.forEach(item => {
                const fullPath = path.join(currentDir, item);
                const stat = fs.statSync(fullPath);
                
                if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
                    scan(fullPath);
                } else if (stat.isFile() && pattern.test(item)) {
                    files.push(fullPath);
                }
            });
        };
        
        if (fs.existsSync(dir)) {
            scan(dir);
        }
        
        return files;
    }

    // 运行完整的安全审计
    async runSecurityAudit() {
        const startTime = Date.now();
        
        this.checkEnvironmentSecurity();
        this.checkDependencySecurity();
        this.checkCodeSecurity();
        this.checkApiSecurity();
        this.checkDatabaseSecurity();
        this.checkConfigSecurity();
        
        const duration = Date.now() - startTime;
        const report = this.generateSecurityReport();
        
        console.log('\n🎯 安全审计结果汇总');
        console.log('======================');
        console.log(`✅ 通过: ${this.results.passed}`);
        console.log(`❌ 失败: ${this.results.failed}`);
        console.log(`⚠️  警告: ${this.results.warnings}`);
        console.log(`🚨 关键: ${this.results.critical}`);
        console.log(`🎚️  风险等级: ${report.riskLevel}`);
        console.log(`⏱️  耗时: ${duration}ms`);
        
        // 显示关键问题
        if (this.results.critical > 0) {
            console.log('\n🚨 关键安全问题:');
            this.results.checks
                .filter(check => check.severity === 'critical' && !check.passed)
                .forEach(check => {
                    console.log(`   - ${check.name}: ${check.message}`);
                });
        }
        
        // 显示建议
        console.log('\n💡 安全建议:');
        report.recommendations.forEach(rec => {
            const icon = rec.priority === 'critical' ? '🚨' : 
                        rec.priority === 'high' ? '⚠️' : 
                        rec.priority === 'medium' ? '💡' : 'ℹ️';
            console.log(`   ${icon} ${rec.message}`);
        });
        
        // 部署建议
        console.log('\n🚀 部署建议:');
        if (report.riskLevel === 'CRITICAL') {
            console.log('   ❌ 不建议部署：存在关键安全风险');
        } else if (report.riskLevel === 'HIGH') {
            console.log('   ⚠️  谨慎部署：建议先修复高风险问题');
        } else if (report.riskLevel === 'MEDIUM') {
            console.log('   ✅ 可以部署：建议处理警告项以提高安全性');
        } else {
            console.log('   ✅ 安全部署：通过安全审计');
        }
        
        return report.riskLevel !== 'CRITICAL';
    }
}

// 主执行函数
async function main() {
    const auditor = new SecurityAuditor();
    
    try {
        const success = await auditor.runSecurityAudit();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 安全审计过程中发生错误:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = SecurityAuditor;