import { PrismaClient } from '@prisma/client';
import { isProd } from '../config/env';

/**
 * A single shared PrismaClient instance.
 * In dev, `tsx watch` reloads the module frequently, so we cache the client on
 * `globalThis` to avoid opening a new DB connection pool on every reload.
 */
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: isProd ? ['error'] : ['query', 'warn', 'error'],
  });

if (!isProd) {
  globalForPrisma.prisma = prisma;
}
