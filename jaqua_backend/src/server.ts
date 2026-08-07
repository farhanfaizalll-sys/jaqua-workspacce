import { createApp } from './app';
import { env } from './config/env';
import { prisma } from './lib/prisma';
import { connectMqtt } from './services/mqtt.service';

async function main() {
  // Fail fast if the database is unreachable.
  await prisma.$connect();

  connectMqtt();

  const app = createApp();
  const server = app.listen(env.PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`🚀 Jaqua API listening on http://localhost:${env.PORT} (${env.NODE_ENV})`);
  });

  const shutdown = async (signal: string) => {
    // eslint-disable-next-line no-console
    console.log(`\n${signal} received, shutting down...`);
    server.close(async () => {
      await prisma.$disconnect();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

main().catch(async (err) => {
  // eslint-disable-next-line no-console
  console.error('Fatal startup error:', err);
  await prisma.$disconnect();
  process.exit(1);
});
