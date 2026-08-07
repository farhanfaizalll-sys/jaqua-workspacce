import { NextFunction, Request, Response } from 'express';
import { ZodSchema } from 'zod';
import { ApiError } from '../utils/apiError';

/**
 * Validates and *sanitizes* req.body against a zod schema.
 * On success req.body is replaced with the parsed (typed) data.
 */
export const validateBody =
  (schema: ZodSchema) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      throw new ApiError(
        422,
        'VALIDATION_ERROR',
        'Request body failed validation',
        result.error.flatten().fieldErrors,
      );
    }

    req.body = result.data;
    next();
  };
