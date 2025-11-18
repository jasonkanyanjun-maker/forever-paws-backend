#!/usr/bin/env node

/**
 * Forever Paws 完整部署检查脚本
 * Complete Deployment Check Script
 * 
 * 运行所有部署前检查，包括生产检查、安全审计、迁移检查和部署清单
 * Runs all pre-deployment checks including production, security, migration, and checklist
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class CompleteDeploymentCheck {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        this.results = {
            checks: [],
            summary: {
                total: 0,
                passed: 0,
                failed: 0,
                warnings: 0
            }
        };
        
        console.log('🚀 Forever Paws 完整部署检查');
        console.log('====================================');
        console.log('正在运行所有部署前检查...\n');
    }

    // 运行单个检查脚本
    async runCheck(name, script, description) {
        console.log(`📋 ${name}`);
        console.log('─'.repeat(name.length + 4));
        console.log(`${description}\n`);
        
        const startTime = Date.now();
        let success = false;
        let output = '';
        let error = '';
        
        try {
            output = execSync(`npm run ${script}`, {
                cwd: this.projectRoot,
                encoding: 'utf8',
                stdio: 'pipe'
            });
            success = true;
            console.log(output);
        } catch (err) {
            error = err.message;
            output = err.stdout || '';
            console.log(output);
            console.error(`❌ ${name} 检查失败:`, err.stderr || err.message);
        }
        
        const duration = Date.now() - startTime;
        
        const result = {
            name,
            script,
            description,
            success,
            duration,
            output,
            error,
            timestamp: new Date().toISOString()
        };
        
        this.results.checks.push(result);
        this.results.summary.total++;
        
        if (success) {
            this.results.summary.passed++;
            console.log(`✅ ${name} 检查通过 (耗时: ${duration}ms)\n`);
        } else {
            this.results.summary.failed++;
            console.log(`❌ ${name} 检查失败 (耗时: ${duration}ms)\n`);
        }
        
        return success;
    }

    // 运行所有检查
    async runAllChecks() {
        const checks = [
            {
                name: '生产环境检查',
                script: 'production-check',
                description: '检查生产环境配置、健康检查端点、TypeScript 编译和环境变量'
            },
            {
                name: '数据库迁移检查',
                script: 'migration-check',
                description: '分析 Supabase 迁移文件、RLS 策略和权限配置'
            },
            {
                name: '安全审计',
                script: 'security-audit',
                description: '检查环境变量安全、代码安全、API 安全和配置安全'
            },
            {
                name: '部署检查清单',
                script: 'deployment-checklist',
                description: '综合检查项目配置、环境设置、代码质量和部署就绪度'
            }
        ];

        const results = [];
        
        for (const check of checks) {
            const success = await this.runCheck(check.name, check.script, check.description);
            results.push(success);
            
            // 在检查之间添加分隔符
            console.log('═'.repeat(60) + '\n');
        }
        
        return results;
    }

    // 生成综合报告
    generateComprehensiveReport() {
        const report = {
            timestamp: new Date().toISOString(),
            summary: this.results.summary,
            checks: this.results.checks,
            recommendations: this.generateRecommendations(),
            deploymentReadiness: this.assessDeploymentReadiness()
        };

        const reportsDir = path.join(this.projectRoot, 'reports');
        if (!fs.existsSync(reportsDir)) {
            fs.mkdirSync(reportsDir, { recursive: true });
        }

        const reportFile = path.join(reportsDir, `complete-deployment-check-${Date.now()}.json`);
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        return { report, reportFile };
    }

    // 生成建议
    generateRecommendations() {
        const recommendations = [];
        const failedChecks = this.results.checks.filter(check => !check.success);
        
        if (failedChecks.length === 0) {
            recommendations.push({
                priority: 'info',
                message: '所有检查都已通过，可以安全部署到生产环境'
            });
        } else {
            recommendations.push({
                priority: 'critical',
                message: `有 ${failedChecks.length} 项检查失败，建议修复后再部署`
            });
            
            failedChecks.forEach(check => {
                recommendations.push({
                    priority: 'high',
                    message: `修复 ${check.name} 中发现的问题`,
                    details: check.error
                });
            });
        }
        
        // 通用建议
        recommendations.push(
            {
                priority: 'medium',
                message: '在生产环境部署前，建议在测试环境进行完整验证'
            },
            {
                priority: 'medium',
                message: '部署后监控应用性能和错误日志'
            },
            {
                priority: 'low',
                message: '定期运行安全审计和依赖更新'
            }
        );
        
        return recommendations;
    }

    // 评估部署就绪度
    assessDeploymentReadiness() {
        const { total, passed, failed } = this.results.summary;
        const successRate = (passed / total) * 100;
        
        let readiness;
        let message;
        let canDeploy;
        
        if (failed === 0) {
            readiness = 'READY';
            message = '所有检查通过，已准备好部署到生产环境';
            canDeploy = true;
        } else if (successRate >= 75) {
            readiness = 'MOSTLY_READY';
            message = '大部分检查通过，建议修复失败项后部署';
            canDeploy = false;
        } else if (successRate >= 50) {
            readiness = 'NEEDS_WORK';
            message = '需要修复多个问题才能部署';
            canDeploy = false;
        } else {
            readiness = 'NOT_READY';
            message = '存在严重问题，不建议部署';
            canDeploy = false;
        }
        
        return {
            level: readiness,
            score: Math.round(successRate),
            message,
            canDeploy,
            passedChecks: passed,
            failedChecks: failed,
            totalChecks: total
        };
    }

    // 显示最终结果
    displayFinalResults() {
        const { report, reportFile } = this.generateComprehensiveReport();
        
        console.log('🎯 完整部署检查结果');
        console.log('======================');
        
        // 显示各项检查结果
        this.results.checks.forEach(check => {
            const icon = check.success ? '✅' : '❌';
            console.log(`${icon} ${check.name}: ${check.success ? '通过' : '失败'}`);
        });
        
        console.log('\n📊 检查统计:');
        console.log(`   总计: ${this.results.summary.total}`);
        console.log(`   通过: ${this.results.summary.passed}`);
        console.log(`   失败: ${this.results.summary.failed}`);
        console.log(`   成功率: ${Math.round((this.results.summary.passed / this.results.summary.total) * 100)}%`);
        
        const readiness = report.deploymentReadiness;
        const readinessIcon = {
            'READY': '🟢',
            'MOSTLY_READY': '🟡',
            'NEEDS_WORK': '🟠',
            'NOT_READY': '🔴'
        }[readiness.level];
        
        console.log(`\n${readinessIcon} 部署就绪度: ${readiness.level} (${readiness.score}%)`);
        console.log(`💬 ${readiness.message}`);
        
        // 显示失败的检查
        const failedChecks = this.results.checks.filter(check => !check.success);
        if (failedChecks.length > 0) {
            console.log('\n🔧 失败的检查项:');
            failedChecks.forEach(check => {
                console.log(`   ❌ ${check.name}`);
                if (check.error) {
                    console.log(`      错误: ${check.error.split('\n')[0]}`);
                }
            });
        }
        
        // 显示建议
        console.log('\n💡 部署建议:');
        const criticalRecs = report.recommendations.filter(rec => rec.priority === 'critical' || rec.priority === 'high');
        criticalRecs.slice(0, 3).forEach(rec => {
            const icon = rec.priority === 'critical' ? '🚨' : '⚠️';
            console.log(`   ${icon} ${rec.message}`);
        });
        
        console.log('\n🚀 下一步操作:');
        if (readiness.canDeploy) {
            console.log('   ✅ 可以开始部署流程');
            console.log('   1. 确认生产环境配置');
            console.log('   2. 执行数据库迁移');
            console.log('   3. 部署应用到 Railway');
            console.log('   4. 运行部署后验证');
        } else {
            console.log('   ❌ 请先修复失败的检查项');
            console.log('   1. 查看详细错误信息');
            console.log('   2. 修复发现的问题');
            console.log('   3. 重新运行检查');
            console.log('   4. 确认所有检查通过后再部署');
        }
        
        console.log(`\n📄 详细报告: ${reportFile}`);
        
        return readiness.canDeploy;
    }

    // 运行完整检查流程
    async runCompleteCheck() {
        const startTime = Date.now();
        
        await this.runAllChecks();
        const canDeploy = this.displayFinalResults();
        
        const totalDuration = Date.now() - startTime;
        console.log(`\n⏱️  总耗时: ${Math.round(totalDuration / 1000)}秒`);
        
        return canDeploy;
    }
}

// 主执行函数
async function main() {
    const checker = new CompleteDeploymentCheck();
    
    try {
        const success = await checker.runCompleteCheck();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 完整部署检查过程中发生错误:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = CompleteDeploymentCheck;