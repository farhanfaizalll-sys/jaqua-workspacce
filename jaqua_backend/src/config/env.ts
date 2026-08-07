import 'dotenv/config';
import { z } from 'zod';

/**
 * Validates process.env at startup. If anything required is missing or malformed
 * the app crashes immediately with a clear message instead of failing later.
 */
const schema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  PORT: z.coerce.number().default(4000),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),

  // ─── MQTT broker ───────────────────────────────────────────
  // Public by default (broker.emqx.io) for early hardware bring-up.
  // Swap for a private broker + credentials before real deployment.
  MQTT_BROKER_URL: z.string().default('mqtt://broker.emqx.io:1883'),
  MQTT_USERNAME: z.string().optional(),
  MQTT_PASSWORD: z.string().optional(),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('❌ Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export const isProd = env.NODE_ENV === 'production';
