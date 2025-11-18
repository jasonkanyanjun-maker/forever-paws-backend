import Joi from 'joi';

// Common pagination schema
export const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  sortBy: Joi.string().optional(),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc')
});

// Common ID parameter schema
export const idParamSchema = Joi.object({
  id: Joi.string().uuid().required()
});

// Common search schema
export const searchSchema = Joi.object({
  q: Joi.string().min(1).max(100).optional(),
  ...paginationSchema.describe().keys
});

export const commonSchemas = {
  pagination: paginationSchema,
  idParam: idParamSchema,
  search: searchSchema
};

export default commonSchemas;