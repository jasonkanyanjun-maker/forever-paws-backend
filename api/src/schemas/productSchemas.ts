import Joi from 'joi';

export const productSchemas = {
  createProduct: Joi.object({
    name: Joi.string().min(1).max(255).required().messages({
      'string.empty': '商品名称不能为空',
      'string.max': '商品名称不能超过255个字符',
      'any.required': '商品名称是必填项'
    }),
    description: Joi.string().max(2000).optional().messages({
      'string.max': '商品描述不能超过2000个字符'
    }),
    price: Joi.number().positive().precision(2).required().messages({
      'number.positive': '商品价格必须大于0',
      'any.required': '商品价格是必填项'
    }),
    category: Joi.string().min(1).max(100).required().messages({
      'string.empty': '商品分类不能为空',
      'string.max': '商品分类不能超过100个字符',
      'any.required': '商品分类是必填项'
    }),
    image_url: Joi.string().uri().optional().messages({
      'string.uri': '商品图片URL格式不正确'
    }),
    stock_quantity: Joi.number().integer().min(0).default(0).messages({
      'number.integer': '库存数量必须是整数',
      'number.min': '库存数量不能小于0'
    }),
    is_active: Joi.boolean().default(true)
  }),

  updateProduct: Joi.object({
    name: Joi.string().min(1).max(255).optional().messages({
      'string.empty': '商品名称不能为空',
      'string.max': '商品名称不能超过255个字符'
    }),
    description: Joi.string().max(2000).optional().messages({
      'string.max': '商品描述不能超过2000个字符'
    }),
    price: Joi.number().positive().precision(2).optional().messages({
      'number.positive': '商品价格必须大于0'
    }),
    category: Joi.string().min(1).max(100).optional().messages({
      'string.empty': '商品分类不能为空',
      'string.max': '商品分类不能超过100个字符'
    }),
    image_url: Joi.string().uri().optional().messages({
      'string.uri': '商品图片URL格式不正确'
    }),
    stock_quantity: Joi.number().integer().min(0).optional().messages({
      'number.integer': '库存数量必须是整数',
      'number.min': '库存数量不能小于0'
    }),
    is_active: Joi.boolean().optional()
  }),

  getProducts: Joi.object({
    page: Joi.number().integer().min(1).default(1).messages({
      'number.integer': '页码必须是整数',
      'number.min': '页码必须大于0'
    }),
    limit: Joi.number().integer().min(1).max(100).default(20).messages({
      'number.integer': '每页数量必须是整数',
      'number.min': '每页数量必须大于0',
      'number.max': '每页数量不能超过100'
    }),
    search: Joi.string().max(255).optional().messages({
      'string.max': '搜索关键词不能超过255个字符'
    }),
    category: Joi.string().max(100).optional().messages({
      'string.max': '商品分类不能超过100个字符'
    }),
    min_price: Joi.number().min(0).optional().messages({
      'number.min': '最低价格不能小于0'
    }),
    max_price: Joi.number().min(0).optional().messages({
      'number.min': '最高价格不能小于0'
    }),
    is_active: Joi.boolean().optional(),
    sort_by: Joi.string().valid('name', 'price', 'created_at').default('created_at').messages({
      'any.only': '排序字段只能是 name, price, created_at 中的一个'
    }),
    sort_order: Joi.string().valid('asc', 'desc').default('desc').messages({
      'any.only': '排序方向只能是 asc 或 desc'
    })
  }).custom((value, helpers) => {
    if (value.min_price && value.max_price && value.min_price > value.max_price) {
      return helpers.error('custom.priceRange');
    }
    return value;
  }).messages({
    'custom.priceRange': '最低价格不能大于最高价格'
  }),

  updateStock: Joi.object({
    quantity: Joi.number().integer().min(1).required().messages({
      'number.integer': '数量必须是整数',
      'number.min': '数量必须大于0',
      'any.required': '数量是必填项'
    }),
    operation: Joi.string().valid('increase', 'decrease').required().messages({
      'any.only': '操作类型只能是 increase 或 decrease',
      'any.required': '操作类型是必填项'
    })
  }),

  checkStock: Joi.object({
    quantity: Joi.number().integer().min(1).required().messages({
      'number.integer': '数量必须是整数',
      'number.min': '数量必须大于0',
      'any.required': '数量是必填项'
    })
  }),

  getPopularProducts: Joi.object({
    limit: Joi.number().integer().min(1).max(50).default(10).messages({
      'number.integer': '返回数量必须是整数',
      'number.min': '返回数量必须大于0',
      'number.max': '返回数量不能超过50'
    })
  })
};