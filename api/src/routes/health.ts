import { Router, Request, Response } from 'express';
import { supabase } from '../config/supabase';

const router = Router();

// 健康检查端点
router.get('/', async (req: Request, res: Response): Promise<void> => {
    try {
        const healthCheck = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            environment: process.env.NODE_ENV || 'development',
            version: process.env.npm_package_version || '1.0.0',
            services: {
                database: 'unknown',
                api: 'healthy'
            }
        };

        // 检查数据库连接
        try {
            const { data, error } = await supabase
                .from('users')
                .select('id')
                .limit(1);
            
            if (error) {
                healthCheck.services.database = 'error';
                console.error('Database health check failed:', error);
            } else {
                healthCheck.services.database = 'healthy';
            }
        } catch (dbError) {
            healthCheck.services.database = 'error';
            console.error('Database connection failed:', dbError);
        }

        // 如果数据库有问题，返回 503
        if (healthCheck.services.database === 'error') {
            res.status(503).json({
                ...healthCheck,
                status: 'unhealthy'
            });
            return;
        }

        res.status(200).json(healthCheck);
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: 'Internal server error'
        });
    }
});

// 简单的存活检查（不检查依赖服务）
router.get('/ping', (req: Request, res: Response) => {
    res.status(200).json({
        status: 'alive',
        timestamp: new Date().toISOString(),
        message: 'pong'
    });
});

// 详细的系统信息检查
router.get('/detailed', async (req: Request, res: Response) => {
    try {
        const detailedHealth = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            environment: process.env.NODE_ENV || 'development',
            version: process.env.npm_package_version || '1.0.0',
            system: {
                platform: process.platform,
                nodeVersion: process.version,
                memory: process.memoryUsage(),
                pid: process.pid
            },
            services: {
                database: 'unknown',
                api: 'healthy'
            },
            endpoints: {
                auth: '/api/auth',
                users: '/api/users',
                pets: '/api/pets',
                upload: '/api/upload'
            }
        };

        // 检查数据库连接和基本表
        try {
            const tables = ['users', 'user_profiles', 'pets', 'pet_photos'] as const;
            const tableChecks = await Promise.all(
                tables.map(async (table) => {
                    try {
                        const { error } = await supabase
                            .from(table)
                            .select('id')
                            .limit(1);
                        return { table, status: error ? 'error' : 'healthy', error: error?.message };
                    } catch (err) {
                        return { table, status: 'error', error: (err as Error).message };
                    }
                })
            );

            detailedHealth.services.database = tableChecks.every(check => check.status === 'healthy') ? 'healthy' : 'partial';
            (detailedHealth as any).database_tables = tableChecks;
        } catch (dbError) {
            detailedHealth.services.database = 'error';
            (detailedHealth as any).database_error = (dbError as Error).message;
        }

        const overallStatus = detailedHealth.services.database === 'error' ? 'unhealthy' : 'healthy';
        const statusCode = overallStatus === 'healthy' ? 200 : 503;

        res.status(statusCode).json({
            ...detailedHealth,
            status: overallStatus
        });
    } catch (error) {
        console.error('Detailed health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: 'Internal server error',
            details: (error as Error).message
        });
    }
});

export default router;