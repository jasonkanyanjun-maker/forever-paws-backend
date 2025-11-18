#!/usr/bin/env node

/**
 * Forever Paws 性能优化脚本
 * Performance Optimization Script
 * 
 * 分析和优化应用性能，包括代码分析、依赖优化、配置调优等
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class PerformanceOptimizer {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        this.results = {
            analysis: {},
            optimizations: [],
            recommendations: []
        };
        
        console.log('⚡ Forever Paws 性能优化分析');
        console.log('===============================');
    }

    // 分析 package.json 依赖
    analyzeDependencies() {
        console.log('📦 分析项目依赖...');
        
        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        if (!fs.existsSync(packageJsonPath)) {
            throw new Error('package.json 文件不存在');
        }
        
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
        const dependencies = packageJson.dependencies || {};
        const devDependencies = packageJson.devDependencies || {};
        
        const analysis = {
            totalDependencies: Object.keys(dependencies).length,
            totalDevDependencies: Object.keys(devDependencies).length,
            heavyDependencies: [],
            unusedDependencies: [],
            outdatedDependencies: []
        };
        
        // 检查可能的重型依赖
        const heavyPackages = ['lodash', 'moment', 'axios', 'express'];
        heavyPackages.forEach(pkg => {
            if (dependencies[pkg]) {
                analysis.heavyDependencies.push({
                    name: pkg,
                    suggestion: this.getAlternativeSuggestion(pkg)
                });
            }
        });
        
        this.results.analysis.dependencies = analysis;
        
        console.log(`   ✅ 生产依赖: ${analysis.totalDependencies}`);
        console.log(`   ✅ 开发依赖: ${analysis.totalDevDependencies}`);
        if (analysis.heavyDependencies.length > 0) {
            console.log(`   ⚠️  重型依赖: ${analysis.heavyDependencies.length}`);
        }
        
        return analysis;
    }

    // 获取依赖替代建议
    getAlternativeSuggestion(packageName) {
        const alternatives = {
            'lodash': 'native ES6+ methods or lodash-es for tree shaking',
            'moment': 'date-fns or dayjs (smaller bundle size)',
            'axios': 'native fetch API or ky (lighter alternative)',
            'express': 'fastify (better performance) or koa (lighter)'
        };
        
        return alternatives[packageName] || 'Consider lighter alternatives';
    }

    // 分析代码结构
    analyzeCodeStructure() {
        console.log('🔍 分析代码结构...');
        
        const srcPath = path.join(this.projectRoot, 'src');
        if (!fs.existsSync(srcPath)) {
            console.log('   ⚠️  src 目录不存在，跳过代码分析');
            return {};
        }
        
        const analysis = {
            totalFiles: 0,
            largeFiles: [],
            duplicateCode: [],
            complexFunctions: []
        };
        
        // 递归分析文件
        this.analyzeDirectory(srcPath, analysis);
        
        this.results.analysis.codeStructure = analysis;
        
        console.log(`   ✅ 总文件数: ${analysis.totalFiles}`);
        if (analysis.largeFiles.length > 0) {
            console.log(`   ⚠️  大文件 (>500行): ${analysis.largeFiles.length}`);
        }
        
        return analysis;
    }

    // 递归分析目录
    analyzeDirectory(dirPath, analysis) {
        const items = fs.readdirSync(dirPath);
        
        items.forEach(item => {
            const itemPath = path.join(dirPath, item);
            const stat = fs.statSync(itemPath);
            
            if (stat.isDirectory()) {
                this.analyzeDirectory(itemPath, analysis);
            } else if (item.endsWith('.js') || item.endsWith('.ts') || item.endsWith('.tsx')) {
                analysis.totalFiles++;
                
                const content = fs.readFileSync(itemPath, 'utf8');
                const lines = content.split('\n').length;
                
                // 检查大文件
                if (lines > 500) {
                    analysis.largeFiles.push({
                        file: path.relative(this.projectRoot, itemPath),
                        lines,
                        suggestion: 'Consider splitting into smaller modules'
                    });
                }
                
                // 检查复杂函数（简单启发式）
                const functionMatches = content.match(/function\s+\w+|const\s+\w+\s*=\s*\(/g);
                if (functionMatches && functionMatches.length > 20) {
                    analysis.complexFunctions.push({
                        file: path.relative(this.projectRoot, itemPath),
                        functions: functionMatches.length,
                        suggestion: 'Consider refactoring into smaller functions'
                    });
                }
            }
        });
    }

    // 分析数据库查询性能
    analyzeDatabaseQueries() {
        console.log('🗄️  分析数据库查询...');
        
        const analysis = {
            queries: [],
            recommendations: []
        };
        
        // 查找包含数据库查询的文件
        const queryFiles = this.findFilesWithQueries();
        
        queryFiles.forEach(file => {
            const content = fs.readFileSync(file, 'utf8');
            
            // 检查可能的性能问题
            if (content.includes('select(\'*\')')) {
                analysis.queries.push({
                    file: path.relative(this.projectRoot, file),
                    issue: 'Using SELECT *',
                    suggestion: 'Specify only needed columns'
                });
            }
            
            if (content.includes('.from(') && !content.includes('.limit(')) {
                analysis.queries.push({
                    file: path.relative(this.projectRoot, file),
                    issue: 'Query without LIMIT',
                    suggestion: 'Add pagination or limit results'
                });
            }
        });
        
        this.results.analysis.database = analysis;
        
        console.log(`   ✅ 检查了 ${queryFiles.length} 个查询文件`);
        if (analysis.queries.length > 0) {
            console.log(`   ⚠️  发现 ${analysis.queries.length} 个潜在问题`);
        }
        
        return analysis;
    }

    // 查找包含数据库查询的文件
    findFilesWithQueries() {
        const files = [];
        const searchPatterns = ['supabase', 'from(', 'select(', 'insert(', 'update(', 'delete('];
        
        try {
            const result = execSync('find . -name "*.js" -o -name "*.ts" -o -name "*.tsx"', {
                cwd: this.projectRoot,
                encoding: 'utf8'
            });
            
            const allFiles = result.trim().split('\n').filter(f => f);
            
            allFiles.forEach(file => {
                const fullPath = path.join(this.projectRoot, file);
                if (fs.existsSync(fullPath)) {
                    const content = fs.readFileSync(fullPath, 'utf8');
                    if (searchPatterns.some(pattern => content.includes(pattern))) {
                        files.push(fullPath);
                    }
                }
            });
        } catch (error) {
            console.log('   ⚠️  无法搜索查询文件:', error.message);
        }
        
        return files;
    }

    // 分析 API 性能
    analyzeAPIPerformance() {
        console.log('🌐 分析 API 性能...');
        
        const analysis = {
            routes: [],
            middlewares: [],
            recommendations: []
        };
        
        // 查找路由文件
        const routesPath = path.join(this.projectRoot, 'src', 'routes');
        if (fs.existsSync(routesPath)) {
            const routeFiles = fs.readdirSync(routesPath);
            
            routeFiles.forEach(file => {
                if (file.endsWith('.js') || file.endsWith('.ts')) {
                    const filePath = path.join(routesPath, file);
                    const content = fs.readFileSync(filePath, 'utf8');
                    
                    // 检查是否有错误处理
                    if (!content.includes('try') && !content.includes('catch')) {
                        analysis.routes.push({
                            file,
                            issue: 'Missing error handling',
                            suggestion: 'Add try-catch blocks for better error handling'
                        });
                    }
                    
                    // 检查是否有输入验证
                    if (!content.includes('validate') && !content.includes('joi') && !content.includes('zod')) {
                        analysis.routes.push({
                            file,
                            issue: 'Missing input validation',
                            suggestion: 'Add input validation middleware'
                        });
                    }
                }
            });
        }
        
        this.results.analysis.api = analysis;
        
        console.log(`   ✅ 检查了 API 路由配置`);
        if (analysis.routes.length > 0) {
            console.log(`   ⚠️  发现 ${analysis.routes.length} 个改进点`);
        }
        
        return analysis;
    }

    // 生成优化建议
    generateOptimizations() {
        console.log('💡 生成优化建议...');
        
        const optimizations = [];
        
        // 依赖优化
        if (this.results.analysis.dependencies?.heavyDependencies?.length > 0) {
            optimizations.push({
                category: 'Dependencies',
                priority: 'high',
                title: '优化重型依赖',
                description: '替换或优化重型依赖包以减少 bundle 大小',
                actions: this.results.analysis.dependencies.heavyDependencies.map(dep => 
                    `考虑将 ${dep.name} 替换为 ${dep.suggestion}`
                )
            });
        }
        
        // 代码结构优化
        if (this.results.analysis.codeStructure?.largeFiles?.length > 0) {
            optimizations.push({
                category: 'Code Structure',
                priority: 'medium',
                title: '拆分大文件',
                description: '将大文件拆分为更小的模块以提高可维护性',
                actions: this.results.analysis.codeStructure.largeFiles.map(file => 
                    `拆分 ${file.file} (${file.lines} 行)`
                )
            });
        }
        
        // 数据库优化
        if (this.results.analysis.database?.queries?.length > 0) {
            optimizations.push({
                category: 'Database',
                priority: 'high',
                title: '优化数据库查询',
                description: '改进数据库查询性能和效率',
                actions: this.results.analysis.database.queries.map(query => 
                    `${query.file}: ${query.suggestion}`
                )
            });
        }
        
        // API 优化
        if (this.results.analysis.api?.routes?.length > 0) {
            optimizations.push({
                category: 'API',
                priority: 'medium',
                title: '改进 API 设计',
                description: '增强 API 的错误处理和输入验证',
                actions: this.results.analysis.api.routes.map(route => 
                    `${route.file}: ${route.suggestion}`
                )
            });
        }
        
        // 通用性能优化
        optimizations.push(
            {
                category: 'Performance',
                priority: 'medium',
                title: '启用 Gzip 压缩',
                description: '在生产环境启用 Gzip 压缩以减少传输大小',
                actions: ['在 Express 中添加 compression 中间件']
            },
            {
                category: 'Performance',
                priority: 'low',
                title: '添加缓存策略',
                description: '为静态资源和 API 响应添加适当的缓存',
                actions: ['配置 HTTP 缓存头', '考虑使用 Redis 缓存']
            },
            {
                category: 'Monitoring',
                priority: 'medium',
                title: '性能监控',
                description: '添加性能监控和分析工具',
                actions: ['集成 APM 工具', '添加响应时间监控']
            }
        );
        
        this.results.optimizations = optimizations;
        
        console.log(`   ✅ 生成了 ${optimizations.length} 项优化建议`);
        
        return optimizations;
    }

    // 创建性能优化配置文件
    createOptimizationConfigs() {
        console.log('⚙️  创建优化配置文件...');
        
        // 创建 compression 中间件配置
        const compressionConfig = `
// compression.js - Gzip 压缩中间件配置
const compression = require('compression');

const compressionOptions = {
    // 压缩级别 (1-9, 9 为最高压缩)
    level: 6,
    // 最小压缩大小 (字节)
    threshold: 1024,
    // 压缩过滤器
    filter: (req, res) => {
        // 不压缩已经压缩的内容
        if (req.headers['x-no-compression']) {
            return false;
        }
        // 使用默认过滤器
        return compression.filter(req, res);
    }
};

module.exports = compression(compressionOptions);
`;
        
        // 创建缓存配置
        const cacheConfig = `
// cache.js - 缓存配置
const cacheControl = (maxAge = 3600) => {
    return (req, res, next) => {
        // 设置缓存控制头
        res.set('Cache-Control', \`public, max-age=\${maxAge}\`);
        next();
    };
};

// 不同类型资源的缓存策略
const cacheStrategies = {
    // 静态资源 - 长期缓存
    static: cacheControl(31536000), // 1年
    
    // API 响应 - 短期缓存
    api: cacheControl(300), // 5分钟
    
    // 用户数据 - 不缓存
    user: (req, res, next) => {
        res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        next();
    }
};

module.exports = { cacheControl, cacheStrategies };
`;
        
        // 创建性能监控中间件
        const performanceMiddleware = `
// performance.js - 性能监控中间件
const performanceMonitor = (req, res, next) => {
    const startTime = Date.now();
    
    // 监听响应完成
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const { method, url } = req;
        const { statusCode } = res;
        
        // 记录性能数据
        console.log(\`[\${new Date().toISOString()}] \${method} \${url} - \${statusCode} - \${duration}ms\`);
        
        // 如果响应时间过长，记录警告
        if (duration > 1000) {
            console.warn(\`⚠️  Slow response: \${method} \${url} took \${duration}ms\`);
        }
    });
    
    next();
};

module.exports = performanceMonitor;
`;
        
        // 写入配置文件
        const configsDir = path.join(this.projectRoot, 'src', 'config');
        if (!fs.existsSync(configsDir)) {
            fs.mkdirSync(configsDir, { recursive: true });
        }
        
        fs.writeFileSync(path.join(configsDir, 'compression.js'), compressionConfig);
        fs.writeFileSync(path.join(configsDir, 'cache.js'), cacheConfig);
        fs.writeFileSync(path.join(configsDir, 'performance.js'), performanceMiddleware);
        
        console.log('   ✅ 创建了性能优化配置文件');
        
        return {
            compression: path.join(configsDir, 'compression.js'),
            cache: path.join(configsDir, 'cache.js'),
            performance: path.join(configsDir, 'performance.js')
        };
    }

    // 生成性能报告
    generatePerformanceReport() {
        const report = {
            timestamp: new Date().toISOString(),
            analysis: this.results.analysis,
            optimizations: this.results.optimizations,
            summary: {
                totalIssues: 0,
                highPriority: 0,
                mediumPriority: 0,
                lowPriority: 0
            }
        };
        
        // 计算问题统计
        this.results.optimizations.forEach(opt => {
            report.summary.totalIssues++;
            switch (opt.priority) {
                case 'high':
                    report.summary.highPriority++;
                    break;
                case 'medium':
                    report.summary.mediumPriority++;
                    break;
                case 'low':
                    report.summary.lowPriority++;
                    break;
            }
        });
        
        // 保存报告
        const reportsDir = path.join(this.projectRoot, 'reports');
        if (!fs.existsSync(reportsDir)) {
            fs.mkdirSync(reportsDir, { recursive: true });
        }
        
        const reportFile = path.join(reportsDir, `performance-analysis-${Date.now()}.json`);
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        
        return { report, reportFile };
    }

    // 显示结果
    displayResults() {
        const { report, reportFile } = this.generatePerformanceReport();
        
        console.log('\n⚡ 性能优化分析结果');
        console.log('====================');
        
        // 显示统计
        console.log('📊 问题统计:');
        console.log(`   🔴 高优先级: ${report.summary.highPriority}`);
        console.log(`   🟡 中优先级: ${report.summary.mediumPriority}`);
        console.log(`   🟢 低优先级: ${report.summary.lowPriority}`);
        console.log(`   📝 总计: ${report.summary.totalIssues}`);
        
        // 显示主要优化建议
        console.log('\n💡 主要优化建议:');
        const highPriorityOpts = this.results.optimizations.filter(opt => opt.priority === 'high');
        
        if (highPriorityOpts.length === 0) {
            console.log('   ✅ 没有发现高优先级性能问题');
        } else {
            highPriorityOpts.forEach((opt, index) => {
                console.log(`   ${index + 1}. ${opt.title}`);
                console.log(`      📝 ${opt.description}`);
                if (opt.actions.length > 0) {
                    console.log(`      🔧 ${opt.actions[0]}`);
                }
            });
        }
        
        console.log('\n🚀 下一步操作:');
        console.log('   1. 查看详细性能报告');
        console.log('   2. 优先处理高优先级问题');
        console.log('   3. 实施性能优化配置');
        console.log('   4. 进行性能测试验证');
        
        console.log(`\n📄 详细报告: ${reportFile}`);
        
        return report.summary.highPriority === 0;
    }

    // 运行完整性能分析
    async runCompleteAnalysis() {
        try {
            this.analyzeDependencies();
            this.analyzeCodeStructure();
            this.analyzeDatabaseQueries();
            this.analyzeAPIPerformance();
            this.generateOptimizations();
            this.createOptimizationConfigs();
            
            return this.displayResults();
        } catch (error) {
            console.error('❌ 性能分析过程中发生错误:', error.message);
            return false;
        }
    }
}

// 主执行函数
async function main() {
    const optimizer = new PerformanceOptimizer();
    
    try {
        const success = await optimizer.runCompleteAnalysis();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 性能优化分析失败:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = PerformanceOptimizer;