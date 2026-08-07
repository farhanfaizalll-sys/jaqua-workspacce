import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { isProd } from './config/env';
import apiRoutes from './routes';
import { notFound, errorHandler } from './middleware/error.middleware';

export function createApp(): Application {
  const app = express();

  // Render (and most PaaS) sit behind a reverse proxy — trust the first hop
  // so req.ip / req.secure reflect the real client instead of the proxy.
  app.set('trust proxy', 1);

  // Security headers.
  app.use(helmet());

  // CORS — the Flutter app calls from mobile; tighten `origin` for web clients.
  app.use(cors());

  // Body parsing.
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Request logging.
  app.use(morgan(isProd ? 'combined' : 'dev'));

  // All API routes live under /api.
  app.use('/api', apiRoutes);

  // 404 + centralized error handler (must be registered last).
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
