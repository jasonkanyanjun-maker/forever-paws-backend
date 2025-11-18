#!/usr/bin/env node

/**
 * Forever Paws 安全问题修复脚本
 * Security Issues Fix Script
 * 
 * 自动修复安全审计中发现的关键问题
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class SecurityFixer {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '..');
        this.fixes = [];
        
        console.log('🔒 Forever Paws 安全问题修复');
        console.log('==============================');
    }

    // 移除生产环境的 console.log
    removeProductionConsoleLog() {
        console.log('🧹 移除生产环境 console.log...');
        
        const filesToFix = [
            'src/start.ts',
            'src/middleware/auth.ts',
            'src/server.ts',
            'src/routes/upload.ts',
            'src/app.ts',
            'src/services/AuthService.ts',
            'src/config/database.ts',
            'src/middleware/monitoring.ts'
        ];
        
        let totalFixed = 0;
        
        filesToFix.forEach(relativePath => {
            const filePath = path.join(this.projectRoot, relativePath);
            if (!fs.existsSync(filePath)) return;
            
            let content = fs.readFileSync(filePath, 'utf8');
            const originalContent = content;
            
            // 替换 console.log 为条件日志
            content = content.replace(
                /console\.log\(/g,
                'process.env.NODE_ENV !== \'production\' && console.log('
            );
            
            // 替换 console.error 为条件日志（保留错误日志）
            content = content.replace(
                /console\.error\(/g,
                'console.error('
            );
            
            if (content !== originalContent) {
                fs.writeFileSync(filePath, content);
                const changes = (originalContent.match(/console\.log\(/g) || []).length;
                totalFixed += changes;
                console.log(`   ✅ 修复 ${relativePath}: ${changes} 个 console.log`);
            }
        });
        
        this.fixes.push({
            type: 'console-log-removal',
            description: '移除生产环境 console.log',
            filesFixed: filesToFix.length,
            totalChanges: totalFixed
        });
        
        console.log(`   📊 总计修复: ${totalFixed} 个 console.log`);
    }

    // 修复硬编码密钥问题
    fixHardcodedSecrets() {
        console.log('🔑 修复硬编码密钥问题...');
        
        const supabaseConfigPath = path.join(this.projectRoot, 'src/config/supabase.ts');
        
        if (fs.existsSync(supabaseConfigPath)) {
            let content = fs.readFileSync(supabaseConfigPath, 'utf8');
            
            // 检查是否有硬编码的 service key
            if (content.includes('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')) {
                // 替换硬编码的 service key
                content = content.replace(
                    /const supabaseServiceKey = process\.env\.SUPABASE_SERVICE_ROLE_KEY \|\| '[^']+';/,
                    `const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY environment variable is required');
}`
                );
                
                fs.writeFileSync(supabaseConfigPath, content);
                console.log('   ✅ 移除硬编码的 Supabase Service Key');
                
                this.fixes.push({
                    type: 'hardcoded-secrets',
                    description: '移除硬编码密钥',
                    file: 'src/config/supabase.ts',
                    action: '替换为环境变量验证'
                });
            }
        }
    }

    // 修复文件权限
    fixFilePermissions() {
        console.log('🔐 修复敏感文件权限...');
        
        const sensitiveFiles = ['.env', '.env.production', '.env.local'];
        let fixedFiles = 0;
        
        sensitiveFiles.forEach(file => {
            const filePath = path.join(this.projectRoot, file);
            if (fs.existsSync(filePath)) {
                try {
                    // 设置文件权限为 600 (只有所有者可读写)
                    execSync(`chmod 600 "${filePath}"`);
                    console.log(`   ✅ 修复 ${file} 权限为 600`);
                    fixedFiles++;
                } catch (error) {
                    console.log(`   ⚠️  无法修复 ${file} 权限: ${error.message}`);
                }
            }
        });
        
        this.fixes.push({
            type: 'file-permissions',
            description: '修复敏感文件权限',
            filesFixed: fixedFiles
        });
    }

    // 添加 API 速率限制
    addRateLimiting() {
        console.log('🚦 添加 API 速率限制配置...');
        
        const rateLimitConfig = `
// rate-limit.js - API 速率限制配置
const rateLimit = require('express-rate-limit');

// 通用 API 速率限制
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 分钟
    max: 100, // 每个 IP 最多 100 次请求
    message: {
        error: 'Too many requests from this IP, please try again later.',
        retryAfter: '15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// 认证相关的严格限制
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 分钟
    max: 5, // 每个 IP 最多 5 次认证请求
    message: {
        error: 'Too many authentication attempts, please try again later.',
        retryAfter: '15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// 上传文件的限制
const uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 小时
    max: 10, // 每个 IP 最多 10 次上传
    message: {
        error: 'Too many upload requests, please try again later.',
        retryAfter: '1 hour'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

module.exports = {
    apiLimiter,
    authLimiter,
    uploadLimiter
};
`;
        
        const configDir = path.join(this.projectRoot, 'src', 'config');
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        
        const rateLimitPath = path.join(configDir, 'rate-limit.js');
        fs.writeFileSync(rateLimitPath, rateLimitConfig);
        
        console.log('   ✅ 创建速率限制配置文件');
        
        this.fixes.push({
            type: 'rate-limiting',
            description: '添加 API 速率限制',
            file: 'src/config/rate-limit.js',
            action: '创建速率限制配置'
        });
    }

    // 创建安全中间件
    createSecurityMiddleware() {
        console.log('🛡️  创建安全中间件...');
        
        const securityMiddleware = `
// security.js - 安全中间件
const helmet = require('helmet');
const cors = require('cors');

// 安全头配置
const securityHeaders = helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.supabase.co"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
        },
    },
    crossOriginEmbedderPolicy: false,
});

// CORS 配置
const corsOptions = {
    origin: function (origin, callback) {
        // 允许的域名列表
        const allowedOrigins = [
            'http://localhost:3000',
            'http://localhost:5173',
            'https://your-production-domain.com'
        ];
        
        // 在开发环境允许所有来源
        if (process.env.NODE_ENV === 'development') {
            return callback(null, true);
        }
        
        // 检查来源是否在允许列表中
        if (!origin || allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
};

// 请求大小限制
const requestSizeLimit = '10mb';

// 安全日志中间件
const securityLogger = (req, res, next) => {
    // 记录可疑请求
    const suspiciousPatterns = [
        /\.\./,  // 路径遍历
        /<script/i,  // XSS 尝试
        /union.*select/i,  // SQL 注入尝试
    ];
    
    const url = req.url;
    const userAgent = req.get('User-Agent') || '';
    
    suspiciousPatterns.forEach(pattern => {
        if (pattern.test(url) || pattern.test(userAgent)) {
            console.warn(\`🚨 Suspicious request detected: \${req.method} \${url} from \${req.ip}\`);
        }
    });
    
    next();
};

module.exports = {
    securityHeaders,
    corsOptions,
    requestSizeLimit,
    securityLogger
};
`;
        
        const middlewareDir = path.join(this.projectRoot, 'src', 'middleware');
        if (!fs.existsSync(middlewareDir)) {
            fs.mkdirSync(middlewareDir, { recursive: true });
        }
        
        const securityPath = path.join(middlewareDir, 'security.js');
        fs.writeFileSync(securityPath, securityMiddleware);
        
        console.log('   ✅ 创建安全中间件文件');
        
        this.fixes.push({
            type: 'security-middleware',
            description: '创建安全中间件',
            file: 'src/middleware/security.js',
            action: '添加安全头和 CORS 配置'
        });
    }

    // 更新 package.json 添加安全依赖
    updatePackageJsonSecurity() {
        console.log('📦 更新 package.json 安全配置...');
        
        const packageJsonPath = path.join(this.projectRoot, 'package.json');
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
        
        // 添加安全相关的脚本
        if (!packageJson.scripts['security-check']) {
            packageJson.scripts['security-check'] = 'npm audit && npm run security-audit';
        }
        
        if (!packageJson.scripts['fix-security']) {
            packageJson.scripts['fix-security'] = 'node scripts/fix-security-issues.js';
        }
        
        // 添加安全相关依赖（如果不存在）
        const securityDeps = {
            'helmet': '^7.0.0',
            'express-rate-limit': '^7.0.0'
        };
        
        let addedDeps = 0;
        Object.entries(securityDeps).forEach(([dep, version]) => {
            if (!packageJson.dependencies[dep]) {
                packageJson.dependencies[dep] = version;
                addedDeps++;
            }
        });
        
        fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
        
        console.log(`   ✅ 添加了 ${addedDeps} 个安全依赖`);
        console.log('   ✅ 添加了安全检查脚本');
        
        this.fixes.push({
            type: 'package-security',
            description: '更新 package.json 安全配置',
            addedDependencies: addedDeps,
            addedScripts: 2
        });
    }

    // 创建环境变量模板
    createEnvTemplate() {
        console.log('📝 创建环境变量模板...');
        
        const envTemplate = `# Forever Paws API Environment Variables Template
# 复制此文件为 .env 并填入实际值

# 应用配置
NODE_ENV=development
PORT=3001
JWT_SECRET=your-super-secret-jwt-key-here

# Supabase 配置
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# 数据库配置 (如果使用直接数据库连接)
DATABASE_URL=your-database-url

# 邮件配置 (如果需要)
SMTP_HOST=your-smtp-host
SMTP_PORT=587
SMTP_USER=your-smtp-user
SMTP_PASS=your-smtp-password

# 文件上传配置
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif

# 安全配置
BCRYPT_ROUNDS=12
SESSION_SECRET=your-session-secret

# 第三方服务 (如果需要)
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret

# 监控和日志
LOG_LEVEL=info
ENABLE_REQUEST_LOGGING=true
`;
        
        const envTemplatePath = path.join(this.projectRoot, '.env.template');
        fs.writeFileSync(envTemplatePath, envTemplate);
        
        console.log('   ✅ 创建环境变量模板文件');
        
        this.fixes.push({
            type: 'env-template',
            description: '创建环境变量模板',
            file: '.env.template',
            action: '提供安全的环境变量配置指南'
        });
    }

    // 运行所有修复
    async runAllFixes() {
        console.log('🔧 开始修复安全问题...\n');
        
        try {
            this.removeProductionConsoleLog();
            console.log();
            
            this.fixHardcodedSecrets();
            console.log();
            
            this.fixFilePermissions();
            console.log();
            
            this.addRateLimiting();
            console.log();
            
            this.createSecurityMiddleware();
            console.log();
            
            this.updatePackageJsonSecurity();
            console.log();
            
            this.createEnvTemplate();
            console.log();
            
            return true;
        } catch (error) {
            console.error('❌ 修复过程中发生错误:', error.message);
            return false;
        }
    }

    // 显示修复结果
    displayResults() {
        console.log('🎯 安全问题修复结果');
        console.log('====================');
        
        console.log(`📊 总计修复: ${this.fixes.length} 类问题`);
        
        this.fixes.forEach((fix, index) => {
            console.log(`${index + 1}. ${fix.description}`);
            if (fix.filesFixed) {
                console.log(`   📁 修复文件: ${fix.filesFixed}`);
            }
            if (fix.totalChanges) {
                console.log(`   🔧 总变更: ${fix.totalChanges}`);
            }
            if (fix.file) {
                console.log(`   📄 文件: ${fix.file}`);
            }
        });
        
        console.log('\n🚀 下一步操作:');
        console.log('   1. 安装新的安全依赖: npm install');
        console.log('   2. 更新应用配置以使用新的安全中间件');
        console.log('   3. 重新运行安全审计: npm run security-audit');
        console.log('   4. 测试应用功能是否正常');
        
        console.log('\n⚠️  重要提醒:');
        console.log('   - 确保所有环境变量都已正确配置');
        console.log('   - 检查 .env 文件权限是否为 600');
        console.log('   - 在生产环境部署前进行完整测试');
    }
}

// 主执行函数
async function main() {
    const fixer = new SecurityFixer();
    
    try {
        const success = await fixer.runAllFixes();
        fixer.displayResults();
        
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('❌ 安全修复失败:', error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main();
}

module.exports = SecurityFixer;