import { NextFunction, Request, Response } from 'express';

/**
 * A predictable error type. `code` is a stable machine-readable string the
 * Flutter app can switch on (e.g. "DEVICE_NOT_FOUND"), separate from the human message.
 */
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(statusCode: number, code: string, message: string, details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

/**
 * Wraps an async route handler so thrown/rejected errors are forwarded to the
 * Express error middleware instead of crashing the process.
 */
export const asyncHandler =
  (fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>) =>
  (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
