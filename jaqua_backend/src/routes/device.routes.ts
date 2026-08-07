import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { validateBody } from '../middleware/validate.middleware';
import { listDevices, createDevice, getDevice, setPower, feedNow } from '../controllers/device.controller';
import {
  listSchedules,
  createSchedule,
  updateSchedule,
  deleteSchedule,
} from '../controllers/schedule.controller';
import { getReadings, getFeedEvents } from '../controllers/history.controller';
import {
  createDeviceSchema,
  setPowerSchema,
  createScheduleSchema,
  updateScheduleSchema,
} from '../validators/device.validator';

const router = Router();

router.use(requireAuth);

router.get('/', listDevices);
router.post('/', validateBody(createDeviceSchema), createDevice);
router.get('/:id', getDevice);
router.patch('/:id/power', validateBody(setPowerSchema), setPower);
router.post('/:id/feed-now', feedNow);

router.get('/:deviceId/schedules', listSchedules);
router.post('/:deviceId/schedules', validateBody(createScheduleSchema), createSchedule);

router.get('/:deviceId/history/readings', getReadings);
router.get('/:deviceId/history/feed-events', getFeedEvents);

export default router;

// Schedule update/delete are addressed by schedule id, not device id — kept
// as a separate router mounted at /api/schedules (see routes/index.ts) since
// their URL doesn't nest under a device.
export const scheduleByIdRoutes = Router();
scheduleByIdRoutes.use(requireAuth);
scheduleByIdRoutes.patch('/:id', validateBody(updateScheduleSchema), updateSchedule);
scheduleByIdRoutes.delete('/:id', deleteSchedule);
