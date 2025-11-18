import Joi from 'joi';

export const orderSchemas = {
  createOrder: Joi.object({
    items: Joi.array().items(
      Joi.object({
        product_id: Joi.string().uuid().required().messages({
          'string.uuid': '商品ID格式不正确',
          'any.required': '商品ID是必填项'
        }),
        quantity: Joi.number().integer().min(1).required().messages({
          'number.integer': '商品数量必须是整数',
          'number.min': '商品数量必须大于0',
          'any.required': '商品数量是必填项'
        })
      })
    ).min(1).required().messages({
      'array.min': '订单必须包含至少一个商品',
      'any.required': '订单商品列表是必填项'
    }),
    shipping_address: Joi.string().min(1).max(500).required().messages({
      'string.empty': '收货地址不能为空',
      'string.max': '收货地址不能超过500个字符',
      'any.required': '收货地址是必填项'
    }),
    contact_phone: Joi.string().pattern(/^1[3-9]\d{9}$/).required().messages({
      'string.pattern.base': '联系电话格式不正确',
      'any.required': '联系电话是必填项'
    }),
    notes: Joi.string().max(1000).optional().messages({
      'string.max': '订单备注不能超过1000个字符'
    })
  }),

  updateOrder: Joi.object({
    shipping_address: Joi.string().min(1).max(500).optional().messages({
      'string.empty': '收货地址不能为空',
      'string.max': '收货地址不能超过500个字符'
    }),
    contact_phone: Joi.string().pattern(/^1[3-9]\d{9}$/).optional().messages({
      'string.pattern.base': '联系电话格式不正确'
    }),
    notes: Joi.string().max(1000).optional().messages({
      'string.max': '订单备注不能超过1000个字符'
    })
  }),

  getUserOrders: Joi.object({
    page: Joi.number().integer().min(1).default(1).messages({
      'number.integer': '页码必须是整数',
      'number.min': '页码必须大于0'
    }),
    limit: Joi.number().integer().min(1).max(100).default(20).messages({
      'number.integer': '每页数量必须是整数',
      'number.min': '每页数量必须大于0',
      'number.max': '每页数量不能超过100'
    }),
    status: Joi.string().valid('pending', 'confirmed', 'shipped', 'delivered', 'cancelled').optional().messages({
      'any.only': '订单状态只能是 pending, confirmed, shipped, delivered, cancelled 中的一个'
    }),
    sort_by: Joi.string().valid('created_at', 'total_amount', 'status').default('created_at').messages({
      'any.only': '排序字段只能是 created_at, total_amount, status 中的一个'
    }),
    sort_order: Joi.string().valid('asc', 'desc').default('desc').messages({
      'any.only': '排序方向只能是 asc 或 desc'
    })
  }),

  getAllOrders: Joi.object({
    page: Joi.number().integer().min(1).default(1).messages({
      'number.integer': '页码必须是整数',
      'number.min': '页码必须大于0'
    }),
    limit: Joi.number().integer().min(1).max(100).default(20).messages({
      'number.integer': '每页数量必须是整数',
      'number.min': '每页数量必须大于0',
      'number.max': '每页数量不能超过100'
    }),
    status: Joi.string().valid('pending', 'confirmed', 'shipped', 'delivered', 'cancelled').optional().messages({
      'any.only': '订单状态只能是 pending, confirmed, shipped, delivered, cancelled 中的一个'
    }),
    user_id: Joi.string().uuid().optional().messages({
      'string.uuid': '用户ID格式不正确'
    }),
    sort_by: Joi.string().valid('created_at', 'total_amount', 'status').default('created_at').messages({
      'any.only': '排序字段只能是 created_at, total_amount, status 中的一个'
    }),
    sort_order: Joi.string().valid('asc', 'desc').default('desc').messages({
      'any.only': '排序方向只能是 asc 或 desc'
    })
  }),

  updateOrderStatus: Joi.object({
    status: Joi.string().valid('pending', 'confirmed', 'shipped', 'delivered', 'cancelled').required().messages({
      'any.only': '订单状态只能是 pending, confirmed, shipped, delivered, cancelled 中的一个',
      'any.required': '订单状态是必填项'
    })
  })
};