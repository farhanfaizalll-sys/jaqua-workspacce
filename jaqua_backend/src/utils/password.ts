import bcrypt from 'bcryptjs';

// bcryptjs is pure JS (no native build step) — much easier to install on a
// Windows/Render environment than the native `bcrypt` package.
const SALT_ROUNDS = 10;

export const hashPassword = (plain: string): Promise<string> =>
  bcrypt.hash(plain, SALT_ROUNDS);

export const verifyPassword = (plain: string, hash: string): Promise<boolean> =>
  bcrypt.compare(plain, hash);
