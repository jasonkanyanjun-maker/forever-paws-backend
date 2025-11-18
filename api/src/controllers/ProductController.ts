import { Request, Response } from 'express';
import { ProductService } from '../services/ProductService';
import { asyncHandler } from '../utils/asyncHandler';

const productService = new ProductService();

export class ProductController {
  // 创建商品（管理员功能）
  createProduct = asyncHandler(async (req: Request, res: Response) => {
    const product = await productService.createProduct(req.body);
    
    res.status(201).json({
      success: true,
      message: '商品创建成功',
      data: product
    });
  });

  // 获取商品列表
  getProducts = asyncHandler(async (req: Request, res: Response) => {
    const { 
      page, 
      limit, 
      search, 
      category, 
      min_price, 
      max_price, 
      is_active,
      sort_by,
      sort_order 
    } = req.query;
    
    const result = await productService.getProducts({
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
      search: search as string,
      category: category as string,
      min_price: min_price ? parseFloat(min_price as string) : undefined,
      max_price: max_price ? parseFloat(max_price as string) : undefined,
      is_active: is_active ? is_active === 'true' : undefined,
      sort_by: sort_by as 'name' | 'price' | 'created_at',
      sort_order: sort_order as 'asc' | 'desc'
    });
    
    res.json({
      success: true,
      message: '获取商品列表成功',
      data: result.data,
      pagination: result.pagination
    });
  });

  // 根据ID获取商品详情
  getProductById = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    
    const product = await productService.getProductById(id);
    
    res.json({
      success: true,
      message: '获取商品详情成功',
      data: product
    });
  });

  // 更新商品信息（管理员功能）
  updateProduct = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    
    const product = await productService.updateProduct(id, req.body);
    
    res.json({
      success: true,
      message: '商品信息更新成功',
      data: product
    });
  });

  // 删除商品（管理员功能）
  deleteProduct = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    
    const result = await productService.deleteProduct(id);
    
    res.json({
      success: true,
      message: '商品删除成功'
    });
  });

  // 获取商品分类列表
  getCategories = asyncHandler(async (req: Request, res: Response) => {
    const categories = await productService.getCategories();
    
    res.json({
      success: true,
      message: '获取商品分类成功',
      data: categories
    });
  });

  // 更新商品库存（管理员功能）
  updateStock = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { quantity, operation } = req.body;
    
    const product = await productService.updateStock(id, quantity, operation);
    
    res.json({
      success: true,
      message: '库存更新成功',
      data: product
    });
  });

  // 检查商品库存
  checkStock = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { quantity } = req.query;
    
    const stockInfo = await productService.checkStock(id, parseInt(quantity as string));
    
    res.json({
      success: true,
      message: '库存检查完成',
      data: stockInfo
    });
  });

  // 获取热门商品
  getPopularProducts = asyncHandler(async (req: Request, res: Response) => {
    const { limit } = req.query;
    
    const products = await productService.getPopularProducts(
      limit ? parseInt(limit as string) : undefined
    );
    
    res.json({
      success: true,
      message: '获取热门商品成功',
      data: products
    });
  });

  // 获取商品统计信息（管理员功能）
  getProductStats = asyncHandler(async (req: Request, res: Response) => {
    const stats = await productService.getProductStats();
    
    res.json({
      success: true,
      message: '获取商品统计成功',
      data: stats
    });
  });
}