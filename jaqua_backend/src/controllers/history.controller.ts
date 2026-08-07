import { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { asyncHandler } from '../utils/apiError';
import { requireOwnedDevice } from '../services/device.service';

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

function parsePagination(query: Request['query']) {
  const limit = Math.min(Number(query.limit) || DEFAULT_LIMIT, MAX_LIMIT);
  const before = query.before ? new Date(String(query.before)) : undefined;
  return { limit, before };
}

// GET /api/devices/:deviceId/history/readings?limit=&before=  (requires auth)
// Cursor pagination: pass the `recordedAt` of the last item received as
// `before` to fetch the next older page.
export const getReadings = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.deviceId);
  const { limit, before } = parsePagination(req.query);

  const readings = await prisma.sensorReading.findMany({
    where: { deviceId: device.id, ...(before && { recordedAt: { lt: before } }) },
    orderBy: { recordedAt: 'desc' },
    take: limit,
  });
  res.json({ data: readings });
});

// GET /api/devices/:deviceId/history/feed-events?limit=&before=  (requires auth)
export const getFeedEvents = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.deviceId);
  const { limit, before } = parsePagination(req.query);

  const feedEvents = await prisma.feedEvent.findMany({
    where: { deviceId: device.id, ...(before && { createdAt: { lt: before } }) },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
  res.json({ data: feedEvents });
});
