import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';
import { AuthProvider, PetType, VideoGenerationStatus, OrderStatus, NotificationType } from '../types/common';

/**
 * Generic validation middleware factory
 */
export const validate = (schema: Joi.ObjectSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      res.status(400).json({
        code: 400,
        message: 'Validation failed',
        data: { errors }
      });
      return;
    }
    
    next();
  };
};

/**
 * Query parameter validation middleware
 */
export const validateQuery = (schema: Joi.ObjectSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error } = schema.validate(req.query, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      res.status(400).json({
        code: 400,
        message: 'Query validation failed',
        data: { errors }
      });
      return;
    }
    
    next();
  };
};

// Common validation schemas
export const commonSchemas = {
  pagination: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  idParam: Joi.object({
    id: Joi.string().uuid().required()
  }),

  uuidParam: Joi.object({
    id: Joi.string().uuid().required()
  }),

  search: Joi.object({
    q: Joi.string().min(1).max(100).optional(),
    sort: Joi.string().valid('created_at', 'updated_at', 'name').default('created_at'),
    order: Joi.string().valid('asc', 'desc').default('desc')
  }),

  // UUID
  uuid: Joi.string().uuid().required(),
  
  // Email
  email: Joi.string().email().required(),
  
  // Password - 更宽松的密码规则，只要求最少8位字符
  password: Joi.string().min(8).max(128).required()
    .messages({
      'string.min': 'Password must be at least 8 characters long',
      'string.max': 'Password must not exceed 128 characters',
      'any.required': 'Password is required'
    })
};

// User validation schemas
export const userSchemas = {
  register: Joi.object({
    email: commonSchemas.email,
    password: commonSchemas.password,
    display_name: Joi.string().min(1).max(100).optional()
  }),

  login: Joi.object({
    email: commonSchemas.email,
    password: Joi.string().required()
  }),

  oauthLogin: Joi.object({
    provider: Joi.string().valid(...Object.values(AuthProvider)).required(),
    provider_id: Joi.string().required(),
    email: commonSchemas.email,
    display_name: Joi.string().min(1).max(100).optional(),
    avatar_url: Joi.string().uri().optional()
  }),

  updateProfile: Joi.object({
    display_name: Joi.string().min(1).max(100).optional(),
    avatar_url: Joi.string().uri().optional(),
    preferences: Joi.object({
      notifications: Joi.object({
        email: Joi.boolean().optional(),
        push: Joi.boolean().optional(),
        video_completed: Joi.boolean().optional(),
        order_updates: Joi.boolean().optional(),
      }).optional(),
      privacy: Joi.object({
        profile_visibility: Joi.string().valid('public', 'private').optional()
      }).optional(),
      theme: Joi.object({
        mode: Joi.string().valid('light', 'dark', 'system').optional(),
        language: Joi.string().optional()
      }).optional()
    }).optional()
  }),

  resetPassword: Joi.object({
    email: commonSchemas.email
  })
};

// Pet validation schemas
export const petSchemas = {
  create: Joi.object({
    id: Joi.string().uuid().optional(),
    name: Joi.string().min(1).max(50).required(),
    type: Joi.string().valid(...Object.values(PetType)).required(),
    breed: Joi.string().max(50).allow('').optional(),
    age: Joi.alternatives().try(
      Joi.number().integer().min(0).max(50),
      Joi.string().allow('')
    ).optional(),
    gender: Joi.string().valid('male', 'female', 'unknown').optional(),
    description: Joi.string().max(500).allow('').optional(),
    birth_date: Joi.string().isoDate().optional(),
    memorial_date: Joi.string().isoDate().optional().allow(null),
    personality_traits: Joi.array().items(Joi.string().max(50)).max(10).optional(),
    health_info: Joi.object({
      allergies: Joi.array().items(Joi.string().max(100)).optional(),
      medications: Joi.array().items(Joi.string().max(100)).optional(),
      vet_contact: Joi.string().max(200).optional(),
      special_needs: Joi.string().max(500).optional()
    }).optional(),
    preferences: Joi.object({
      favorite_activities: Joi.array().items(Joi.string().max(100)).optional(),
      favorite_foods: Joi.array().items(Joi.string().max(100)).optional(),
      dislikes: Joi.array().items(Joi.string().max(100)).optional()
    }).optional()
  }),

  createPet: Joi.object({
    id: Joi.string().uuid().optional(),
    name: Joi.string().min(1).max(50).required(),
    type: Joi.string().valid(...Object.values(PetType)).required(),
    breed: Joi.string().max(50).allow('').optional(),
    age: Joi.alternatives().try(
      Joi.number().integer().min(0).max(50),
      Joi.string().allow('')
    ).optional(),
    gender: Joi.string().valid('male', 'female', 'unknown').optional(),
    description: Joi.string().max(500).allow('').optional(),
    birth_date: Joi.string().isoDate().optional(),
    memorial_date: Joi.string().isoDate().optional().allow(null),
    personality_traits: Joi.array().items(Joi.string().max(50)).max(10).optional(),
    health_info: Joi.object({
      allergies: Joi.array().items(Joi.string().max(100)).optional(),
      medications: Joi.array().items(Joi.string().max(100)).optional(),
      vet_contact: Joi.string().max(200).optional(),
      special_needs: Joi.string().max(500).optional()
    }).optional(),
    preferences: Joi.object({
      favorite_activities: Joi.array().items(Joi.string().max(100)).optional(),
      favorite_foods: Joi.array().items(Joi.string().max(100)).optional(),
      dislikes: Joi.array().items(Joi.string().max(100)).optional()
    }).optional()
  }),

  update: Joi.object({
    name: Joi.string().min(1).max(50).optional(),
    type: Joi.string().valid(...Object.values(PetType)).optional(),
    breed: Joi.string().max(50).optional(),
    age: Joi.number().integer().min(0).max(50).optional(),
    gender: Joi.string().valid('male', 'female', 'unknown').optional(),
    description: Joi.string().max(500).optional(),
    personality_traits: Joi.array().items(Joi.string().max(50)).max(10).optional(),
    health_info: Joi.object({
      allergies: Joi.array().items(Joi.string().max(100)).optional(),
      medications: Joi.array().items(Joi.string().max(100)).optional(),
      vet_contact: Joi.string().max(200).optional(),
      special_needs: Joi.string().max(500).optional()
    }).optional(),
    preferences: Joi.object({
      favorite_activities: Joi.array().items(Joi.string().max(100)).optional(),
      favorite_foods: Joi.array().items(Joi.string().max(100)).optional(),
      dislikes: Joi.array().items(Joi.string().max(100)).optional()
    }).optional()
  }),

  updatePet: Joi.object({
    name: Joi.string().min(1).max(50).optional(),
    type: Joi.string().valid(...Object.values(PetType)).optional(),
    breed: Joi.string().max(50).optional(),
    age: Joi.number().integer().min(0).max(50).optional(),
    gender: Joi.string().valid('male', 'female', 'unknown').optional(),
    description: Joi.string().max(500).optional(),
    personality_traits: Joi.array().items(Joi.string().max(50)).max(10).optional(),
    health_info: Joi.object({
      allergies: Joi.array().items(Joi.string().max(100)).optional(),
      medications: Joi.array().items(Joi.string().max(100)).optional(),
      vet_contact: Joi.string().max(200).optional(),
      special_needs: Joi.string().max(500).optional()
    }).optional(),
    preferences: Joi.object({
      favorite_activities: Joi.array().items(Joi.string().max(100)).optional(),
      favorite_foods: Joi.array().items(Joi.string().max(100)).optional(),
      dislikes: Joi.array().items(Joi.string().max(100)).optional()
    }).optional()
  })
};

// Video generation validation schemas
export const videoSchemas = {
  create: Joi.object({
    pet_id: commonSchemas.uuid,
    original_images: Joi.array().items(Joi.string().uri()).min(1).max(5).required(),
    prompt: Joi.string().max(500).optional()
  }),

  update: Joi.object({
    status: Joi.string().valid(...Object.values(VideoGenerationStatus)).optional(),
    progress: Joi.number().min(0).max(100).optional(),
    generated_video_url: Joi.string().uri().optional(),
    metadata: Joi.object().optional()
  })
};

// Letter validation schemas
export const letterSchemas = {
  create: Joi.object({
    pet_id: commonSchemas.uuid,
    content: Joi.string().min(1).max(2000).required()
  }),

  createLetter: Joi.object({
    pet_id: commonSchemas.uuid,
    content: Joi.string().min(1).max(2000).required()
  }),

  update: Joi.object({
    content: Joi.string().min(1).max(2000).optional(),
    reply: Joi.string().min(1).max(2000).optional()
  }),

  updateLetter: Joi.object({
    content: Joi.string().min(1).max(2000).optional(),
    reply: Joi.string().min(1).max(2000).optional()
  })
};

// Family validation schemas removed

// Product validation schemas
export const productSchemas = {
  create: Joi.object({
    name: Joi.string().min(1).max(200).required(),
    description: Joi.string().min(1).max(2000).required(),
    price: Joi.number().positive().required(),
    currency: Joi.string().length(3).default('USD'),
    category: Joi.string().valid('memorial_items', 'pet_accessories', 'digital_services', 'custom_products').required(),
    images: Joi.array().items(Joi.string().uri()).max(10).optional(),
    stock_quantity: Joi.number().integer().min(0).optional(),
    metadata: Joi.object().optional()
  })
};

// Order validation schemas
export const orderSchemas = {
  create: Joi.object({
    items: Joi.array().items(
      Joi.object({
        product_id: commonSchemas.uuid,
        quantity: Joi.number().integer().min(1).required(),
        customization: Joi.object().optional()
      })
    ).min(1).required(),
    shipping_address: Joi.object({
      recipient_name: Joi.string().min(1).max(100).required(),
      phone: Joi.string().min(10).max(20).required(),
      address_line1: Joi.string().min(1).max(200).required(),
      address_line2: Joi.string().max(200).optional(),
      city: Joi.string().min(1).max(100).required(),
      state: Joi.string().min(1).max(100).required(),
      postal_code: Joi.string().min(1).max(20).required(),
      country: Joi.string().length(2).required()
    }).required(),
    billing_address: Joi.object({
      recipient_name: Joi.string().min(1).max(100).required(),
      phone: Joi.string().min(10).max(20).required(),
      address_line1: Joi.string().min(1).max(200).required(),
      address_line2: Joi.string().max(200).optional(),
      city: Joi.string().min(1).max(100).required(),
      state: Joi.string().min(1).max(100).required(),
      postal_code: Joi.string().min(1).max(20).required(),
      country: Joi.string().length(2).required()
    }).optional(),
    payment_method: Joi.object({
      type: Joi.string().valid('credit_card', 'debit_card', 'paypal', 'apple_pay', 'google_pay').required(),
      last_four: Joi.string().length(4).optional(),
      brand: Joi.string().optional(),
      expires_at: Joi.string().optional()
    }).required(),
    discount_code: Joi.string().optional(),
    notes: Joi.string().max(500).optional()
  })
};

// Notification validation schemas
export const notificationSchemas = {
  create: Joi.object({
    user_id: commonSchemas.uuid,
    type: Joi.string().valid(...Object.values(NotificationType)).required(),
    title: Joi.string().min(1).max(200).required(),
    message: Joi.string().min(1).max(1000).required(),
    data: Joi.object({
      target_id: Joi.string().optional(),
      target_type: Joi.string().valid('pet', 'video', 'order', 'letter').optional(),
      action_url: Joi.string().uri().optional(),
      image_url: Joi.string().uri().optional(),
      metadata: Joi.object().optional()
    }).optional()
  }),

  createNotification: Joi.object({
    user_id: commonSchemas.uuid,
    type: Joi.string().valid(...Object.values(NotificationType)).required(),
    title: Joi.string().min(1).max(200).required(),
    message: Joi.string().min(1).max(1000).required(),
    data: Joi.object({
      target_id: Joi.string().optional(),
      target_type: Joi.string().valid('pet', 'video', 'order', 'letter').optional(),
      action_url: Joi.string().uri().optional(),
      image_url: Joi.string().uri().optional(),
      metadata: Joi.object().optional()
    }).optional()
  }),

  createBulk: Joi.object({
    user_ids: Joi.array().items(commonSchemas.uuid).min(1).required(),
    type: Joi.string().valid(...Object.values(NotificationType)).required(),
    title: Joi.string().min(1).max(200).required(),
    message: Joi.string().min(1).max(1000).required(),
    data: Joi.object({
      target_id: Joi.string().optional(),
      target_type: Joi.string().valid('pet', 'video', 'order', 'letter').optional(),
      action_url: Joi.string().uri().optional(),
      image_url: Joi.string().uri().optional(),
      metadata: Joi.object().optional()
    }).optional()
  }),

  getUserNotifications: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    type: Joi.string().valid(...Object.values(NotificationType)).optional(),
    is_read: Joi.boolean().optional()
  }),

  markMultipleAsRead: Joi.object({
    notification_ids: Joi.array().items(commonSchemas.uuid).min(1).required()
  }),

  deleteMultipleNotifications: Joi.object({
    notification_ids: Joi.array().items(commonSchemas.uuid).min(1).required()
  }),

  sendSystemNotification: Joi.object({
    type: Joi.string().valid(...Object.values(NotificationType)).required(),
    title: Joi.string().min(1).max(200).required(),
    message: Joi.string().min(1).max(1000).required(),
    data: Joi.object({
      target_id: Joi.string().optional(),
      target_type: Joi.string().valid('pet', 'video', 'order', 'letter').optional(),
      action_url: Joi.string().uri().optional(),
      image_url: Joi.string().uri().optional(),
      metadata: Joi.object().optional()
    }).optional()
  }),


};

export default {
  validate,
  validateQuery,
  commonSchemas,
  userSchemas,
  petSchemas,
  videoSchemas,
  letterSchemas,
  // familySchemas 已移除
  productSchemas,
  orderSchemas,
  notificationSchemas
};