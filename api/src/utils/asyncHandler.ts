import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../types/common';

type AsyncFunction = (req: Request | AuthenticatedRequest, res: Response, next: NextFunction) => Promise<any>;

export const asyncHandler = (fn: AsyncFunction) => {
  return (req: Request | AuthenticatedRequest, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

export default asyncHandler;