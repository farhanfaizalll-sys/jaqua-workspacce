import { NextFunction, Request, Response } from 'express';
import { ApiError } from '../utils/apiError';
import { verifyToken } from '../utils/jwt';

/**
 * Requires a valid `Authorization: Bearer <token>` header.
 * On success, attaches { id, role } to req.user.
 */
export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    throw new ApiError(401, 'UNAUTHORIZED', 'Missing or malformed Authorization header');
  }

  const token = header.slice('Bearer '.length).trim();

  try {
    const payload = verifyToken(token);
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch {
    throw new ApiError(401, 'INVALID_TOKEN', 'Token is invalid or expired');
  }
}
