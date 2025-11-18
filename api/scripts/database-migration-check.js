#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🗄️ Forever Paws 数据库迁移检查脚本');
console.log('=====================================\n');

let hasErrors = false;
const warnings = [];
const migrationFiles = [];

// 检查迁移文件目录
function checkMigrationsDirectory() {
    console.log('📁 检查迁移文件目录...');
    
    const migrationsDir = path.join(__dirname, '../../supabase/migrations');
    if (!fs.existsSync(migrationsDir)) {
        console.log('❌ Supabase 迁移目录不存在');
        hasErrors = true;
        return false;
    }
    
    console.log(`✅ 迁移目录存在: ${migrationsDir}`);
    
    // 读取所有 SQL 文件
    const files = fs.readdirSync(migrationsDir)
        .filter(file => file.endsWith('.sql'))
        .sort();
    
    console.log(`✅ 找到 ${files.length} 个迁移文件`);
    
    files.forEach(file => {
        const filePath = path.join(migrationsDir, file);
        const stats = fs.statSync(filePath);
        migrationFiles.push({
            name: file,
            path: filePath,
            size: stats.size,
            modified: stats.mtime
        });
        console.log(`  - ${file} (${stats.size} bytes)`);
    });
    
    return true;
}

// 分析迁移文件内容
function analyzeMigrationFiles() {
    console.log('\n🔍 分析迁移文件内容...');
    
    const categories = {
        schema: [],
        rls: [],
        policies: [],
        functions: [],
        triggers: [],
        indexes: [],
        permissions: [],
        data: []
    };
    
    migrationFiles.forEach(file => {
        const content = fs.readFileSync(file.path, 'utf8').toLowerCase();
        
        // 分类文件
        if (content.includes('create table') || content.includes('alter table')) {
            categories.schema.push(file.name);
        }
        if (content.includes('row level security') || content.includes('enable rls')) {
            categories.rls.push(file.name);
        }
        if (content.includes('create policy') || content.includes('drop policy')) {
            categories.policies.push(file.name);
        }
        if (content.includes('create function') || content.includes('create or replace function')) {
            categories.functions.push(file.name);
        }
        if (content.includes('create trigger')) {
            categories.triggers.push(file.name);
        }
        if (content.includes('create index')) {
            categories.indexes.push(file.name);
        }
        if (content.includes('grant') || content.includes('revoke')) {
            categories.permissions.push(file.name);
        }
        if (content.includes('insert into') || content.includes('update') || content.includes('delete from')) {
            categories.data.push(file.name);
        }
    });
    
    // 输出分类结果
    Object.entries(categories).forEach(([category, files]) => {
        if (files.length > 0) {
            console.log(`✅ ${category.toUpperCase()} 相关文件 (${files.length}个):`);
            files.forEach(file => console.log(`  - ${file}`));
        }
    });
    
    return categories;
}

// 检查 RLS 策略完整性
function checkRLSPolicies() {
    console.log('\n🔒 检查 RLS 策略完整性...');
    
    const rlsFiles = migrationFiles.filter(file => 
        file.name.toLowerCase().includes('rls') || 
        file.name.toLowerCase().includes('policy')
    );
    
    console.log(`✅ 找到 ${rlsFiles.length} 个 RLS 相关文件`);
    
    // 检查关键表的 RLS 策略
    const criticalTables = ['users', 'user_profiles', 'pets', 'pet_photos', 'letters', 'orders'];
    const tablesWithRLS = new Set();
    
    rlsFiles.forEach(file => {
        const content = fs.readFileSync(file.path, 'utf8').toLowerCase();
        criticalTables.forEach(table => {
            if (content.includes(table)) {
                tablesWithRLS.add(table);
            }
        });
    });
    
    criticalTables.forEach(table => {
        if (tablesWithRLS.has(table)) {
            console.log(`✅ ${table} 表有 RLS 策略`);
        } else {
            console.log(`⚠️  ${table} 表可能缺少 RLS 策略`);
            warnings.push(`${table} 表可能缺少 RLS 策略`);
        }
    });
    
    return tablesWithRLS;
}

// 检查权限配置
function checkPermissions() {
    console.log('\n👥 检查权限配置...');
    
    const permissionFiles = migrationFiles.filter(file => {
        const content = fs.readFileSync(file.path, 'utf8').toLowerCase();
        return content.includes('grant') || content.includes('anon') || content.includes('authenticated');
    });
    
    if (permissionFiles.length > 0) {
        console.log(`✅ 找到 ${permissionFiles.length} 个权限配置文件:`);
        permissionFiles.forEach(file => console.log(`  - ${file.name}`));
    } else {
        console.log('⚠️  未找到明确的权限配置文件');
        warnings.push('建议检查数据库表的 anon 和 authenticated 角色权限');
    }
    
    // 检查是否有权限检查脚本
    const checkPermissionFile = migrationFiles.find(file => 
        file.name.includes('check_permissions') || 
        file.name.includes('permission')
    );
    
    if (checkPermissionFile) {
        console.log(`✅ 找到权限检查脚本: ${checkPermissionFile.name}`);
    } else {
        warnings.push('建议创建权限检查脚本');
    }
}

// 检查迁移文件冲突
function checkMigrationConflicts() {
    console.log('\n⚡ 检查迁移文件冲突...');
    
    // 检查重复的表创建
    const tableCreations = new Map();
    const policyCreations = new Map();
    
    migrationFiles.forEach(file => {
        const content = fs.readFileSync(file.path, 'utf8');
        
        // 检查 CREATE TABLE
        const tableMatches = content.match(/CREATE TABLE\s+(\w+)/gi);
        if (tableMatches) {
            tableMatches.forEach(match => {
                const tableName = match.split(/\s+/)[2].toLowerCase();
                if (!tableCreations.has(tableName)) {
                    tableCreations.set(tableName, []);
                }
                tableCreations.get(tableName).push(file.name);
            });
        }
        
        // 检查 CREATE POLICY
        const policyMatches = content.match(/CREATE POLICY\s+"([^"]+)"/gi);
        if (policyMatches) {
            policyMatches.forEach(match => {
                const policyName = match.match(/"([^"]+)"/)[1].toLowerCase();
                if (!policyCreations.has(policyName)) {
                    policyCreations.set(policyName, []);
                }
                policyCreations.get(policyName).push(file.name);
            });
        }
    });
    
    // 检查重复创建
    let hasConflicts = false;
    
    tableCreations.forEach((files, table) => {
        if (files.length > 1) {
            console.log(`⚠️  表 ${table} 在多个文件中创建: ${files.join(', ')}`);
            warnings.push(`表 ${table} 可能存在重复创建`);
            hasConflicts = true;
        }
    });
    
    policyCreations.forEach((files, policy) => {
        if (files.length > 1) {
            console.log(`⚠️  策略 ${policy} 在多个文件中创建: ${files.join(', ')}`);
            warnings.push(`策略 ${policy} 可能存在重复创建`);
            hasConflicts = true;
        }
    });
    
    if (!hasConflicts) {
        console.log('✅ 未发现明显的迁移冲突');
    }
}

// 生成迁移执行计划
function generateMigrationPlan() {
    console.log('\n📋 生成迁移执行计划...');
    
    // 按照逻辑顺序排序迁移文件
    const orderedMigrations = [];
    
    // 1. 基础架构文件
    const schemaFiles = migrationFiles.filter(file => 
        file.name.includes('initial') || 
        file.name.includes('schema') || 
        file.name.includes('create_forever_paws')
    );
    orderedMigrations.push(...schemaFiles);
    
    // 2. 表结构扩展
    const extensionFiles = migrationFiles.filter(file => 
        file.name.includes('extend') || 
        file.name.includes('add_missing') || 
        file.name.includes('upgrade')
    );
    orderedMigrations.push(...extensionFiles);
    
    // 3. RLS 策略
    const rlsFiles = migrationFiles.filter(file => 
        file.name.includes('rls') && 
        !file.name.includes('fix') &&
        !orderedMigrations.includes(file)
    );
    orderedMigrations.push(...rlsFiles);
    
    // 4. RLS 修复文件
    const fixFiles = migrationFiles.filter(file => 
        file.name.includes('fix') && 
        !orderedMigrations.includes(file)
    );
    orderedMigrations.push(...fixFiles);
    
    // 5. 其他文件
    const remainingFiles = migrationFiles.filter(file => 
        !orderedMigrations.includes(file)
    );
    orderedMigrations.push(...remainingFiles);
    
    console.log('建议的迁移执行顺序:');
    orderedMigrations.forEach((file, index) => {
        console.log(`${index + 1}. ${file.name}`);
    });
    
    return orderedMigrations;
}

// 主函数
async function runMigrationCheck() {
    if (!checkMigrationsDirectory()) {
        return;
    }
    
    const categories = analyzeMigrationFiles();
    checkRLSPolicies();
    checkPermissions();
    checkMigrationConflicts();
    const migrationPlan = generateMigrationPlan();
    
    // 输出结果汇总
    console.log('\n📊 迁移检查结果汇总');
    console.log('====================');
    
    console.log(`\n📈 统计信息:`);
    console.log(`- 总迁移文件数: ${migrationFiles.length}`);
    console.log(`- RLS 相关文件: ${categories.rls.length + categories.policies.length}`);
    console.log(`- 架构文件: ${categories.schema.length}`);
    console.log(`- 权限文件: ${categories.permissions.length}`);
    
    if (warnings.length > 0) {
        console.log('\n⚠️  警告信息:');
        warnings.forEach((warning, index) => {
            console.log(`${index + 1}. ${warning}`);
        });
    }
    
    if (hasErrors) {
        console.log('\n❌ 发现错误，请修复后再进行数据库迁移');
        process.exit(1);
    } else {
        console.log('\n✅ 数据库迁移文件检查通过！');
        
        console.log('\n🚀 下一步建议:');
        console.log('1. 在生产环境执行迁移前，先在测试环境验证');
        console.log('2. 按照建议的顺序执行迁移文件');
        console.log('3. 执行迁移后验证 RLS 策略是否正常工作');
        console.log('4. 检查所有表的权限配置');
        console.log('5. 运行权限检查脚本验证访问控制');
        
        process.exit(0);
    }
}

// 运行检查
runMigrationCheck().catch(error => {
    console.error('❌ 迁移检查过程中发生错误:', error);
    process.exit(1);
});