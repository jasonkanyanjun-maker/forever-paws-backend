#!/usr/bin/env node

/**
 * Forever Paws 部署检查清单
 * Production Deployment Checklist
 * 
 * 综合部署前检查清单，确保生产环境部署的完整性和安全性
 * Comprehensive pre-deployment checklist for production readiness
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class DeploymentChecklist {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        this.checklist = {
            categories: [],
            summary: {
                total: 0,
                completed: 0,
                failed: 0,
                warnings: 0,
                critical: 0
            }
        };
        
        console.log('📋 Forever Paws 部署检查清单');
        console.log('====================================');
    }

    // 添加检查项
    addCheck(category, name, checkFunction, priority = 'medium', required = true) {
        let categoryObj = this.checklist.categories.find(cat => cat.name === category);
        
        if (!categoryObj) {
            categoryObj = {
                name: category,
                checks: [],
                passed: 0,
                failed: 0,
                warnings: 0
            };
            this.checklist.categories.push(categoryObj);
        }
        
        categoryObj.checks.push({
            name,
            checkFunction,
            priority,
            required,
            status: 'pending',
            message: '',
            timestamp: null
        });
        
        this.checklist.summary.total++;
    }

    // 执行单个检查
    async executeCheck(category, check) {
        try {
            const result = await check.checkFunction();
            
            check.status = result.passed ? 'passed' : 'failed';
            check.message = result.message || '';
            check.timestamp = new Date().toISOString();
            
            const categoryObj = this.checklist.categories.find(cat => cat.name === category);
            
            if (result.passed) {
                categoryObj.passed++;
                this.checklist.summary.completed++;
            } else {
                if (check.priority === 'critical') {
                    categoryObj.failed++;
                    this.checklist.summary.critical++;
                } else if (check.required) {
                    categoryObj.failed++;
                    this.checklist.summary.failed++;
                } else {
                    categoryObj.warnings++;
                    this.checklist.summary.warnings++;
                }
            }
            
            const icon = result.passed ? '✅' : 
                        check.priority === 'critical' ? '🚨' : 
                        check.required ? '❌' : '⚠️';
            
            console.log(`  ${icon} ${check.name}${result.message ? ': ' + result.message : ''}`);
            
        } catch (error) {
            check.status = 'error';
            check.message = error.message;
            check.timestamp = new Date().toISOString();
            
            const categoryObj = this.checklist.categories.find(cat => cat.name === category);
            categoryObj.failed++;
            this.checklist.summary.failed++;
            
            console.log(`  ❌ ${check.name}: 检查失败 - ${error.message}`);
        }
    }

    // 初始化所有检查项
    initializeChecks() {
        // 1. 项目配置检查
        this.addCheck('项目配置', 'package.json 存在且有效', async () => {
            const packagePath = path.join(this.projectRoot, 'package.json');
            if (!fs.existsSync(packagePath)) {
                return { passed: false, message: 'package.json 文件不存在' };
            }
            
            try {
                const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
                const hasRequiredFields = packageJson.name && packageJson.version && packageJson.scripts;
                return { 
                    passed: hasRequiredFields, 
                    message: hasRequiredFields ? '' : '缺少必要字段' 
                };
            } catch (error) {
                return { passed: false, message: 'package.json 格式无效' };
            }
        }, 'critical', true);

        this.addCheck('项目配置', 'Railway 配置文件', async () => {
            const railwayPath = path.join(this.projectRoot, 'railway.toml');
            return { 
                passed: fs.existsSync(railwayPath), 
                message: fs.existsSync(railwayPath) ? '' : 'railway.toml 文件不存在' 
            };
        }, 'high', true);

        this.addCheck('项目配置', 'TypeScript 配置', async () => {
            const tsconfigPath = path.join(this.projectRoot, 'tsconfig.json');
            return { 
                passed: fs.existsSync(tsconfigPath), 
                message: fs.existsSync(tsconfigPath) ? '' : 'tsconfig.json 文件不存在' 
            };
        }, 'medium', false);

        // 2. 环境配置检查
        this.addCheck('环境配置', '生产环境变量文件', async () => {
            const envProdPath = path.join(this.projectRoot, '.env.production');
            return { 
                passed: fs.existsSync(envProdPath), 
                message: fs.existsSync(envProdPath) ? '' : '.env.production 文件不存在' 
            };
        }, 'critical', true);

        this.addCheck('环境配置', '环境变量模板', async () => {
            const envExamplePath = path.join(this.projectRoot, '.env.example');
            return { 
                passed: fs.existsSync(envExamplePath), 
                message: fs.existsSync(envExamplePath) ? '' : '.env.example 文件不存在' 
            };
        }, 'medium', false);

        this.addCheck('环境配置', 'Git 忽略配置', async () => {
            const gitignorePath = path.join(this.projectRoot, '.gitignore');
            if (!fs.existsSync(gitignorePath)) {
                return { passed: false, message: '.gitignore 文件不存在' };
            }
            
            const content = fs.readFileSync(gitignorePath, 'utf8');
            const ignoresEnv = content.includes('.env');
            return { 
                passed: ignoresEnv, 
                message: ignoresEnv ? '' : '.env 文件未被忽略' 
            };
        }, 'critical', true);

        // 3. 代码质量检查
        this.addCheck('代码质量', 'TypeScript 编译', async () => {
            try {
                execSync('npx tsc --noEmit', { 
                    cwd: this.projectRoot, 
                    stdio: 'pipe' 
                });
                return { passed: true };
            } catch (error) {
                return { passed: false, message: 'TypeScript 编译错误' };
            }
        }, 'high', true);

        this.addCheck('代码质量', 'ESLint 检查', async () => {
            try {
                execSync('npx eslint src --ext .js,.ts', { 
                    cwd: this.projectRoot, 
                    stdio: 'pipe' 
                });
                return { passed: true };
            } catch (error) {
                return { passed: false, message: 'ESLint 检查失败' };
            }
        }, 'medium', false);

        // 4. 依赖检查
        this.addCheck('依赖管理', 'node_modules 存在', async () => {
            const nodeModulesPath = path.join(this.projectRoot, 'node_modules');
            return { 
                passed: fs.existsSync(nodeModulesPath), 
                message: fs.existsSync(nodeModulesPath) ? '' : '依赖未安装' 
            };
        }, 'critical', true);

        this.addCheck('依赖管理', 'package-lock.json 存在', async () => {
            const lockPath = path.join(this.projectRoot, 'package-lock.json');
            return { 
                passed: fs.existsSync(lockPath), 
                message: fs.existsSync(lockPath) ? '' : 'package-lock.json 不存在' 
            };
        }, 'medium', false);

        this.addCheck('依赖管理', '安全漏洞检查', async () => {
            try {
                execSync('npm audit --audit-level=high', { 
                    cwd: this.projectRoot, 
                    stdio: 'pipe' 
                });
                return { passed: true };
            } catch (error) {
                return { passed: false, message: '发现高风险安全漏洞' };
            }
        }, 'high', true);

        // 5. API 和路由检查
        this.addCheck('API 配置', '健康检查端点', async () => {
            const healthRoutePath = path.join(this.projectRoot, 'src', 'routes', 'health.ts');
            return { 
                passed: fs.existsSync(healthRoutePath), 
                message: fs.existsSync(healthRoutePath) ? '' : '健康检查路由不存在' 
            };
        }, 'critical', true);

        this.addCheck('API 配置', '主路由配置', async () => {
            const indexRoutePath = path.join(this.projectRoot, 'src', 'routes', 'index.ts');
            return { 
                passed: fs.existsSync(indexRoutePath), 
                message: fs.existsSync(indexRoutePath) ? '' : '主路由文件不存在' 
            };
        }, 'critical', true);

        this.addCheck('API 配置', '中间件配置', async () => {
            const middlewarePath = path.join(this.projectRoot, 'src', 'middleware');
            return { 
                passed: fs.existsSync(middlewarePath), 
                message: fs.existsSync(middlewarePath) ? '' : '中间件目录不存在' 
            };
        }, 'medium', false);

        // 6. 数据库配置检查
        this.addCheck('数据库配置', 'Supabase 迁移文件', async () => {
            const migrationsPath = path.join(this.projectRoot, '../supabase/migrations');
            if (!fs.existsSync(migrationsPath)) {
                return { passed: false, message: '迁移目录不存在' };
            }
            
            const files = fs.readdirSync(migrationsPath).filter(f => f.endsWith('.sql'));
            return { 
                passed: files.length > 0, 
                message: files.length > 0 ? `发现 ${files.length} 个迁移文件` : '没有迁移文件' 
            };
        }, 'high', true);

        this.addCheck('数据库配置', 'RLS 策略文件', async () => {
            const migrationsPath = path.join(this.projectRoot, '../supabase/migrations');
            if (!fs.existsSync(migrationsPath)) {
                return { passed: false, message: '迁移目录不存在' };
            }
            
            const files = fs.readdirSync(migrationsPath);
            const rlsFiles = files.filter(f => f.includes('rls') || f.includes('policy'));
            return { 
                passed: rlsFiles.length > 0, 
                message: rlsFiles.length > 0 ? `发现 ${rlsFiles.length} 个 RLS 文件` : '没有 RLS 策略文件' 
            };
        }, 'critical', true);

        // 7. 构建和部署检查
        this.addCheck('构建部署', '构建脚本存在', async () => {
            const packagePath = path.join(this.projectRoot, 'package.json');
            const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
            const hasBuildScript = packageJson.scripts && packageJson.scripts.build;
            return { 
                passed: hasBuildScript, 
                message: hasBuildScript ? '' : '缺少构建脚本' 
            };
        }, 'high', true);

        this.addCheck('构建部署', '启动脚本存在', async () => {
            const packagePath = path.join(this.projectRoot, 'package.json');
            const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
            const hasStartScript = packageJson.scripts && packageJson.scripts.start;
            return { 
                passed: hasStartScript, 
                message: hasStartScript ? '' : '缺少启动脚本' 
            };
        }, 'critical', true);

        this.addCheck('构建部署', '生产检查脚本', async () => {
            const packagePath = path.join(this.projectRoot, 'package.json');
            const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
            const hasProductionCheck = packageJson.scripts && packageJson.scripts['production-check'];
            return { 
                passed: hasProductionCheck, 
                message: hasProductionCheck ? '' : '缺少生产检查脚本' 
            };
        }, 'medium', false);

        // 8. 安全检查
        this.addCheck('安全配置', '敏感文件保护', async () => {
            const sensitiveFiles = ['.env', '.env.local', '.env.production'];
            const exposedFiles = sensitiveFiles.filter(file => {
                const filePath = path.join(this.projectRoot, file);
                return fs.existsSync(filePath);
            });
            
            // 检查这些文件是否在 .gitignore 中
            const gitignorePath = path.join(this.projectRoot, '.gitignore');
            if (fs.existsSync(gitignorePath)) {
                const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
                const protectedFiles = exposedFiles.filter(file => 
                    gitignoreContent.includes(file) || gitignoreContent.includes('.env')
                );
                
                return { 
                    passed: protectedFiles.length === exposedFiles.length, 
                    message: protectedFiles.length !== exposedFiles.length ? '部分敏感文件未被保护' : '' 
                };
            }
            
            return { passed: false, message: '.gitignore 文件不存在' };
        }, 'critical', true);

        this.addCheck('安全配置', '生产环境配置', async () => {
            const envProdPath = path.join(this.projectRoot, '.env.production');
            if (!fs.existsSync(envProdPath)) {
                return { passed: false, message: '.env.production 文件不存在' };
            }
            
            const content = fs.readFileSync(envProdPath, 'utf8');
            const hasRequiredVars = content.includes('NODE_ENV=production') && 
                                   content.includes('SUPABASE_URL') && 
                                   content.includes('SUPABASE_ANON_KEY');
            
            return { 
                passed: hasRequiredVars, 
                message: hasRequiredVars ? '' : '缺少必要的生产环境变量' 
            };
        }, 'critical', true);

        // 9. 监控和日志
        this.addCheck('监控日志', '日志目录配置', async () => {
            const logsPath = path.join(this.projectRoot, 'logs');
            // 日志目录可能不存在，但应该能够创建
            try {
                if (!fs.existsSync(logsPath)) {
                    fs.mkdirSync(logsPath, { recursive: true });
                }
                return { passed: true };
            } catch (error) {
                return { passed: false, message: '无法创建日志目录' };
            }
        }, 'medium', false);

        this.addCheck('监控日志', '监控配置脚本', async () => {
            const monitoringScriptPath = path.join(this.projectRoot, 'scripts', 'monitoring-setup.js');
            return { 
                passed: fs.existsSync(monitoringScriptPath), 
                message: fs.existsSync(monitoringScriptPath) ? '' : '监控配置脚本不存在' 
            };
        }, 'medium', false);

        // 10. 文档和说明
        this.addCheck('文档说明', 'README 文件', async () => {
            const readmePath = path.join(this.projectRoot, 'README.md');
            return { 
                passed: fs.existsSync(readmePath), 
                message: fs.existsSync(readmePath) ? '' : 'README.md 文件不存在' 
            };
        }, 'low', false);

        this.addCheck('文档说明', '部署文档', async () => {
            const deployDocPath = path.join(this.projectRoot, '../.trae/documents');
            if (!fs.existsSync(deployDocPath)) {
                return { passed: false, message: '部署文档目录不存在' };
            }
            
            const files = fs.readdirSync(deployDocPath);
            const hasDeployDoc = files.some(f => f.includes('deploy') || f.includes('Deployment'));
            return { 
                passed: hasDeployDoc, 
                message: hasDeployDoc ? '' : '缺少部署文档' 
            };
        }, 'low', false);
    }

    // 运行所有检查
    async runAllChecks() {
        console.log('\n🔍 开始执行检查...\n');
        
        for (const category of this.checklist.categories) {
            console.log(`📂 ${category.name}`);
            console.log('─'.repeat(category.name.length + 4));
            
            for (const check of category.checks) {
                await this.executeCheck(category.name, check);
            }
            
            console.log('');
        }
    }

    // 生成检查报告
    generateReport() {
        const report = {
            timestamp: new Date().toISOString(),
            summary: this.checklist.summary,
            categories: this.checklist.categories.map(cat => ({
                name: cat.name,
                passed: cat.passed,
                failed: cat.failed,
                warnings: cat.warnings,
                total: cat.checks.length,
                checks: cat.checks.map(check => ({
                    name: check.name,
                    status: check.status,
                    message: check.message,
                    priority: check.priority,
                    required: check.required,
                    timestamp: check.timestamp
                }))
            })),
            readiness: this.calculateReadiness()
        };

        const reportsDir = path.join(this.projectRoot, 'reports');
        if (!fs.existsSync(reportsDir)) {
            fs.mkdirSync(reportsDir, { recursive: true });
        }

        const reportFile = path.join(reportsDir, `deployment-checklist-${Date.now()}.json`);
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        return { report, reportFile };
    }

    // 计算部署就绪度
    calculateReadiness() {
        const { total, completed, failed, critical } = this.checklist.summary;
        
        if (critical > 0) {
            return {
                level: 'NOT_READY',
                score: 0,
                message: '存在关键问题，不建议部署'
            };
        }
        
        if (failed > 0) {
            return {
                level: 'NEEDS_FIXES',
                score: Math.round((completed / total) * 100),
                message: '需要修复失败项后才能部署'
            };
        }
        
        const score = Math.round((completed / total) * 100);
        
        if (score >= 90) {
            return {
                level: 'READY',
                score,
                message: '已准备好部署到生产环境'
            };
        } else if (score >= 75) {
            return {
                level: 'MOSTLY_READY',
                score,
                message: '基本准备就绪，建议处理剩余项目'
            };
        } else {
            return {
                level: 'NEEDS_WORK',
                score,
                message: '需要完成更多检查项'
            };
        }
    }

    // 显示最终结果
    displayResults() {
        const { report, reportFile } = this.generateReport();
        
        console.log('📊 检查结果汇总');
        console.log('==================');
        console.log(`✅ 通过: ${this.checklist.summary.completed}`);
        console.log(`❌ 失败: ${this.checklist.summary.failed}`);
        console.log(`⚠️  警告: ${this.checklist.summary.warnings}`);
        console.log(`🚨 关键: ${this.checklist.summary.critical}`);
        console.log(`📊 总计: ${this.checklist.summary.total}`);
        
        const readiness = report.readiness;
        const readinessIcon = {
            'READY': '🟢',
            'MOSTLY_READY': '🟡',
            'NEEDS_WORK': '🟠',
            'NEEDS_FIXES': '🔴',
            'NOT_READY': '🚨'
        }[readiness.level];
        
        console.log(`\n${readinessIcon} 部署就绪度: ${readiness.level} (${readiness.score}%)`);
        console.log(`💬 ${readiness.message}`);
        
        // 显示失败的关键检查
        if (this.checklist.summary.critical > 0 || this.checklist.summary.failed > 0) {
            console.log('\n🔧 需要修复的问题:');
            
            this.checklist.categories.forEach(category => {
                const failedChecks = category.checks.filter(check => 
                    check.status === 'failed' && (check.priority === 'critical' || check.required)
                );
                
                if (failedChecks.length > 0) {
                    console.log(`\n  📂 ${category.name}:`);
                    failedChecks.forEach(check => {
                        const icon = check.priority === 'critical' ? '🚨' : '❌';
                        console.log(`    ${icon} ${check.name}: ${check.message}`);
                    });
                }
            });
        }
        
        // 显示警告
        if (this.checklist.summary.warnings > 0) {
            console.log('\n⚠️  建议处理的警告:');
            
            this.checklist.categories.forEach(category => {
                const warningChecks = category.checks.filter(check => 
                    check.status === 'failed' && !check.required
                );
                
                if (warningChecks.length > 0) {
                    console.log(`\n  📂 ${category.name}:`);
                    warningChecks.forEach(check => {
                        console.log(`    ⚠️  ${check.name}: ${check.message}`);
                    });
                }
            });
        }
        
        console.log(`\n📄 详细报告已保存: ${reportFile}`);
        
        return readiness.level === 'READY' || readiness.level === 'MOSTLY_READY';
    }

    // 运行完整的检查流程
    async runChecklist() {
        const startTime = Date.now();
        
        this.initializeChecks();
        await this.runAllChecks();
        const success = this.displayResults();
        
        const duration = Date.now() - startTime;
        console.log(`\n⏱️  检查耗时: ${duration}ms`);
        
        return success;
    }
}

// 主执行函数
async function main() {
    const checklist = new DeploymentChecklist();
    
    try {
        const success = await checklist.runChecklist();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 检查过程中发生错误:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = DeploymentChecklist;