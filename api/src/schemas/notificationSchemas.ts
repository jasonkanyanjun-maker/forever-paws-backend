import Joi from 'joi';

export const notificationSchemas = {
  createNotification: Joi.object({
    user_id: Joi.string().uuid().required().messages({
      'string.uuid': '用户ID格式不正确',
      'any.required': '用户ID是必填项'
    }),
    type: Joi.string().valid('system', 'order', 'pet', 'video', 'letter').required().messages({
      'any.only': '通知类型只能是 system, order, pet, video, letter 中的一个',
      'any.required': '通知类型是必填项'
    }),
    title: Joi.string().min(1).max(255).required().messages({
      'string.empty': '通知标题不能为空',
      'string.max': '通知标题不能超过255个字符',
      'any.required': '通知标题是必填项'
    }),
    content: Joi.string().min(1).max(2000).required().messages({
      'string.empty': '通知内容不能为空',
      'string.max': '通知内容不能超过2000个字符',
      'any.required': '通知内容是必填项'
    }),
    data: Joi.object().optional().messages({
      'object.base': '附加数据必须是对象格式'
    })
  }),

  getUserNotifications: Joi.object({
    page: Joi.number().integer().min(1).default(1).messages({
      'number.integer': '页码必须是整数',
      'number.min': '页码必须大于0'
    }),
    limit: Joi.number().integer().min(1).max(100).default(20).messages({
      'number.integer': '每页数量必须是整数',
      'number.min': '每页数量必须大于0',
      'number.max': '每页数量不能超过100'
    }),
    type: Joi.string().valid('system', 'order', 'pet', 'video', 'letter').optional().messages({
      'any.only': '通知类型只能是 system, order, pet, video, letter 中的一个'
    }),
    status: Joi.string().valid('unread', 'read').optional().messages({
      'any.only': '通知状态只能是 unread 或 read'
    }),
    sort_by: Joi.string().valid('created_at', 'type', 'status').default('created_at').messages({
      'any.only': '排序字段只能是 created_at, type, status 中的一个'
    }),
    sort_order: Joi.string().valid('asc', 'desc').default('desc').messages({
      'any.only': '排序方向只能是 asc 或 desc'
    })
  }),

  markMultipleAsRead: Joi.object({
    ids: Joi.array().items(
      Joi.string().uuid().messages({
        'string.uuid': '通知ID格式不正确'
      })
    ).min(1).required().messages({
      'array.min': '至少需要选择一个通知',
      'any.required': '通知ID列表是必填项'
    })
  }),

  deleteMultipleNotifications: Joi.object({
    ids: Joi.array().items(
      Joi.string().uuid().messages({
        'string.uuid': '通知ID格式不正确'
      })
    ).min(1).required().messages({
      'array.min': '至少需要选择一个通知',
      'any.required': '通知ID列表是必填项'
    })
  }),

  sendSystemNotification: Joi.object({
    title: Joi.string().min(1).max(255).required().messages({
      'string.empty': '通知标题不能为空',
      'string.max': '通知标题不能超过255个字符',
      'any.required': '通知标题是必填项'
    }),
    content: Joi.string().min(1).max(2000).required().messages({
      'string.empty': '通知内容不能为空',
      'string.max': '通知内容不能超过2000个字符',
      'any.required': '通知内容是必填项'
    }),
    data: Joi.object().optional().messages({
      'object.base': '附加数据必须是对象格式'
    })
  }),


};