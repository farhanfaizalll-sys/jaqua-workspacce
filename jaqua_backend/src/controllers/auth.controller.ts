import { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { ApiError, asyncHandler } from '../utils/apiError';
import { hashPassword, verifyPassword } from '../utils/password';
import { signToken } from '../utils/jwt';
import { RegisterInput, LoginInput, ChangePasswordInput } from '../validators/auth.validator';

/** Shape returned to the client — never includes the password hash. */
function publicUser(user: { id: string; email: string; name: string | null; role: string }) {
  return { id: user.id, email: user.email, name: user.name, role: user.role };
}

// POST /api/auth/register
export const register = asyncHandler(async (req: Request, res: Response) => {
  const { email, password, name } = req.body as RegisterInput;

  // Reject duplicates early with a clean message (unique index is the real guard).
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new ApiError(409, 'EMAIL_TAKEN', 'An account with this email already exists');
  }

  const passwordHash = await hashPassword(password);
  const user = await prisma.user.create({
    data: { email, passwordHash, name },
  });

  const token = signToken({ sub: user.id, role: user.role });

  res.status(201).json({
    message: 'Registration successful',
    data: { user: publicUser(user), token },
  });
});

// POST /api/auth/login
export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body as LoginInput;

  const user = await prisma.user.findUnique({ where: { email } });

  // Use the same generic message whether the email or password is wrong,
  // so we don't reveal which emails are registered.
  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
  }

  const token = signToken({ sub: user.id, role: user.role });

  res.json({
    message: 'Login successful',
    data: { user: publicUser(user), token },
  });
});

// GET /api/auth/me  (requires auth)
export const me = asyncHandler(async (req: Request, res: Response) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json({ data: publicUser(user) });
});

// POST /api/auth/change-password  (requires auth)
export const changePassword = asyncHandler(async (req: Request, res: Response) => {
  const { oldPassword, newPassword } = req.body as ChangePasswordInput;

  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });

  if (!(await verifyPassword(oldPassword, user.passwordHash))) {
    throw new ApiError(401, 'INVALID_PASSWORD', 'Old password is incorrect');
  }

  const passwordHash = await hashPassword(newPassword);
  await prisma.user.update({ where: { id: user.id }, data: { passwordHash } });

  res.json({ message: 'Password updated' });
});

// POST /api/auth/logout  (requires auth)
// JWTs are stateless, so "logout" is a client-side action (discard the
// stored token). This endpoint exists so the app has a clean call to make
// and a place to hang server-side session invalidation later if ever needed.
export const logout = asyncHandler(async (_req: Request, res: Response) => {
  res.json({ message: 'Logged out' });
});
