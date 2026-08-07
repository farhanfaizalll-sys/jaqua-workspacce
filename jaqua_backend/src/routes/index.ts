import { Router } from 'express';
import authRoutes from './auth.routes';
import deviceRoutes, { scheduleByIdRoutes } from './device.routes';

const router = Router();

router.get('/health', (_req, res) => res.json({ status: 'ok', ts: Date.now() }));

router.use('/auth', authRoutes);
router.use('/devices', deviceRoutes);
router.use('/schedules', scheduleByIdRoutes);

export default router;
