export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const ErrorTypes = {
  VALIDATION_ERROR: (message: string) => new AppError(message, 400),
  UNAUTHORIZED: (message: string) => new AppError(message, 401),
  FORBIDDEN: (message: string) => new AppError(message, 403),
  NOT_FOUND: (message: string) => new AppError(message, 404),
  CONFLICT: (message: string) => new AppError(message, 409),
  INTERNAL_ERROR: (message: string) => new AppError(message, 500),
  SERVICE_UNAVAILABLE: (message: string) => new AppError(message, 503),
};