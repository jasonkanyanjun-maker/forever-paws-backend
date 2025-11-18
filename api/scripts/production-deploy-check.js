#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Forever Paws 生产部署检查脚本');
console.log('=====================================\n');

let hasErrors = false;
const warnings = [];

// 检查函数
function checkFile(filePath, description) {
    if (fs.existsSync(filePath)) {
        console.log(`✅ ${description}: ${filePath}`);
        return true;
    } else {
        console.log(`❌ ${description}: ${filePath} - 文件不存在`);
        hasErrors = true;
        return false;
    }
}

function checkPackageJson() {
    console.log('\n📦 检查 package.json 配置...');
    
    const packagePath = path.join(__dirname, '../package.json');
    if (!checkFile(packagePath, 'package.json')) return;
    
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    
    // 检查必要的脚本
    const requiredScripts = ['start', 'build', 'dev', 'test', 'health-check', 'production-check'];
    requiredScripts.forEach(script => {
        if (packageJson.scripts && packageJson.scripts[script]) {
            console.log(`✅ 脚本存在: ${script}`);
        } else {
            console.log(`❌ 缺少脚本: ${script}`);
            hasErrors = true;
        }
    });
    
    // 检查 Node.js 版本要求
    if (packageJson.engines && packageJson.engines.node) {
        console.log(`✅ Node.js 版本要求: ${packageJson.engines.node}`);
    } else {
        warnings.push('建议在 package.json 中指定 Node.js 版本要求');
    }
    
    // 检查关键依赖
    const requiredDeps = ['express', '@supabase/supabase-js', 'cors', 'helmet'];
    requiredDeps.forEach(dep => {
        if (packageJson.dependencies && packageJson.dependencies[dep]) {
            console.log(`✅ 依赖存在: ${dep}`);
        } else {
            console.log(`❌ 缺少依赖: ${dep}`);
            hasErrors = true;
        }
    });
}

function checkRailwayConfig() {
    console.log('\n🚂 检查 Railway 配置...');
    
    const railwayPath = path.join(__dirname, '../railway.toml');
    if (!checkFile(railwayPath, 'railway.toml')) return;
    
    const railwayConfig = fs.readFileSync(railwayPath, 'utf8');
    
    // 检查健康检查配置
    if (railwayConfig.includes('healthcheckPath')) {
        console.log('✅ 健康检查路径已配置');
    } else {
        console.log('❌ 缺少健康检查路径配置');
        hasErrors = true;
    }
    
    // 检查环境变量配置
    if (railwayConfig.includes('NODE_ENV')) {
        console.log('✅ NODE_ENV 环境变量已配置');
    } else {
        warnings.push('建议在 railway.toml 中配置 NODE_ENV');
    }
}

function checkEnvironmentFiles() {
    console.log('\n🔧 检查环境变量文件...');
    
    const envExample = path.join(__dirname, '../.env.example');
    const envProduction = path.join(__dirname, '../.env.production');
    
    checkFile(envExample, '.env.example 模板文件');
    checkFile(envProduction, '.env.production 生产配置');
    
    if (fs.existsSync(envExample) && fs.existsSync(envProduction)) {
        const exampleContent = fs.readFileSync(envExample, 'utf8');
        const productionContent = fs.readFileSync(envProduction, 'utf8');
        
        // 提取环境变量键
        const exampleKeys = exampleContent.match(/^[A-Z_]+=.*/gm)?.map(line => line.split('=')[0]) || [];
        const productionKeys = productionContent.match(/^[A-Z_]+=.*/gm)?.map(line => line.split('=')[0]) || [];
        
        // 检查缺少的环境变量
        const missingKeys = exampleKeys.filter(key => !productionKeys.includes(key));
        if (missingKeys.length > 0) {
            console.log(`⚠️  生产环境缺少以下环境变量: ${missingKeys.join(', ')}`);
            warnings.push(`生产环境缺少环境变量: ${missingKeys.join(', ')}`);
        } else {
            console.log('✅ 生产环境变量配置完整');
        }
    }
}

function checkTypeScriptConfig() {
    console.log('\n📝 检查 TypeScript 配置...');
    
    const tsconfigPath = path.join(__dirname, '../tsconfig.json');
    if (!checkFile(tsconfigPath, 'tsconfig.json')) return;
    
    const tsconfig = JSON.parse(fs.readFileSync(tsconfigPath, 'utf8'));
    
    // 检查输出目录
    if (tsconfig.compilerOptions && tsconfig.compilerOptions.outDir) {
        console.log(`✅ 输出目录: ${tsconfig.compilerOptions.outDir}`);
    } else {
        warnings.push('建议在 tsconfig.json 中指定 outDir');
    }
    
    // 检查目标版本
    if (tsconfig.compilerOptions && tsconfig.compilerOptions.target) {
        console.log(`✅ 编译目标: ${tsconfig.compilerOptions.target}`);
    } else {
        warnings.push('建议在 tsconfig.json 中指定编译目标');
    }
}

function checkBuildProcess() {
    console.log('\n🔨 检查构建过程...');
    
    try {
        console.log('正在执行 TypeScript 编译检查...');
        execSync('npx tsc --noEmit', { stdio: 'pipe' });
        console.log('✅ TypeScript 编译检查通过');
    } catch (error) {
        console.log('❌ TypeScript 编译检查失败');
        console.log(error.stdout?.toString() || error.message);
        hasErrors = true;
    }
}

function checkHealthEndpoint() {
    console.log('\n🏥 检查健康检查端点...');
    
    const healthCheckPath = path.join(__dirname, '../src/routes/health.ts');
    const altHealthCheckPath = path.join(__dirname, '../routes/health.ts');
    
    if (checkFile(healthCheckPath, '健康检查路由') || checkFile(altHealthCheckPath, '健康检查路由')) {
        console.log('✅ 健康检查端点已配置');
    } else {
        console.log('❌ 缺少健康检查端点');
        hasErrors = true;
    }
}

function checkSecurityConfig() {
    console.log('\n🔒 检查安全配置...');
    
    const gitignorePath = path.join(__dirname, '../.gitignore');
    if (checkFile(gitignorePath, '.gitignore')) {
        const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
        
        const securityPatterns = ['.env', 'node_modules', '*.log', '.DS_Store'];
        securityPatterns.forEach(pattern => {
            if (gitignoreContent.includes(pattern)) {
                console.log(`✅ .gitignore 包含: ${pattern}`);
            } else {
                warnings.push(`建议在 .gitignore 中添加: ${pattern}`);
            }
        });
    }
    
    // 检查是否存在敏感文件
    const sensitiveFiles = ['.env', '.env.local', '.env.development'];
    sensitiveFiles.forEach(file => {
        const filePath = path.join(__dirname, `../${file}`);
        if (fs.existsSync(filePath)) {
            console.log(`⚠️  发现敏感文件: ${file} - 确保不会提交到版本控制`);
            warnings.push(`敏感文件 ${file} 存在，确保已添加到 .gitignore`);
        }
    });
}

function checkDatabaseMigrations() {
    console.log('\n🗄️ 检查数据库迁移文件...');
    
    const migrationsDir = path.join(__dirname, '../../supabase/migrations');
    if (fs.existsSync(migrationsDir)) {
        const migrationFiles = fs.readdirSync(migrationsDir).filter(file => file.endsWith('.sql'));
        console.log(`✅ 找到 ${migrationFiles.length} 个迁移文件`);
        
        migrationFiles.forEach(file => {
            console.log(`  - ${file}`);
        });
        
        // 检查是否有 RLS 相关的迁移
        const rlsFiles = migrationFiles.filter(file => file.toLowerCase().includes('rls'));
        if (rlsFiles.length > 0) {
            console.log(`✅ 找到 ${rlsFiles.length} 个 RLS 相关迁移文件`);
        } else {
            warnings.push('建议检查是否需要 RLS (Row Level Security) 配置');
        }
    } else {
        warnings.push('未找到 Supabase 迁移目录');
    }
}

// 执行所有检查
async function runAllChecks() {
    checkPackageJson();
    checkRailwayConfig();
    checkEnvironmentFiles();
    checkTypeScriptConfig();
    checkBuildProcess();
    checkHealthEndpoint();
    checkSecurityConfig();
    checkDatabaseMigrations();
    
    // 输出结果
    console.log('\n📊 检查结果汇总');
    console.log('==================');
    
    if (warnings.length > 0) {
        console.log('\n⚠️  警告信息:');
        warnings.forEach((warning, index) => {
            console.log(`${index + 1}. ${warning}`);
        });
    }
    
    if (hasErrors) {
        console.log('\n❌ 发现错误，请修复后再进行部署');
        process.exit(1);
    } else {
        console.log('\n✅ 所有检查通过，可以进行生产部署！');
        
        console.log('\n🚀 下一步部署建议:');
        console.log('1. 确保所有环境变量已在 Railway Dashboard 中配置');
        console.log('2. 运行数据库迁移: npm run db:migrate');
        console.log('3. 部署到 Railway: git push origin main');
        console.log('4. 验证部署: 访问健康检查端点');
        console.log('5. 更新 iOS 应用的生产 API 端点');
        
        process.exit(0);
    }
}

// 运行检查
runAllChecks().catch(error => {
    console.error('❌ 检查过程中发生错误:', error);
    process.exit(1);
});