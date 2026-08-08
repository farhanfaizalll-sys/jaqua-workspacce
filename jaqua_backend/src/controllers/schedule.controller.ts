import { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { ApiError, asyncHandler } from '../utils/apiError';
import { publishCommand } from '../services/mqtt.service';
import { requireOwnedDevice, scheduleSyncCommand } from '../services/device.service';
import { CreateScheduleInput, UpdateScheduleInput } from '../validators/device.validator';

// LoRa (and the public broker.emqx.io broker it rides on) drops packets
// often enough that a single publish isn't reliable — send the same
// SCHEDULE command 3x with a short gap. Safe to repeat since applying the
// same schedule twice is a no-op on the pond unit (unlike FEED_NOW, which
// must NEVER be retried this way or it'd feed multiple times).
async function syncScheduleToDevice(deviceId: string, deviceCode: string): Promise<void> {
  const command = await scheduleSyncCommand(deviceId);
  publishCommand(deviceCode, command);
  // Don't make the caller wait for the extra retries — respond as soon as
  // the DB write + first publish are done, keep resending in background.
  setTimeout(() => publishCommand(deviceCode, command), 700);
  setTimeout(() => publishCommand(deviceCode, command), 1400);
}

// GET /api/devices/:deviceId/schedules  (requires auth)
export const listSchedules = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.deviceId);
  const schedules = await prisma.feedSchedule.findMany({
    where: { deviceId: device.id },
    orderBy: [{ jam: 'asc' }, { menit: 'asc' }],
  });
  res.json({ data: schedules });
});

// POST /api/devices/:deviceId/schedules  (requires auth)
export const createSchedule = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.deviceId);
  const { jam, menit, enabled } = req.body as CreateScheduleInput;

  const schedule = await prisma.feedSchedule.create({
    data: { deviceId: device.id, jam, menit, enabled },
  });
  await syncScheduleToDevice(device.id, device.deviceCode);

  res.status(201).json({ message: 'Schedule created', data: schedule });
});

async function requireOwnedSchedule(userId: string, scheduleId: string) {
  const schedule = await prisma.feedSchedule.findUnique({
    where: { id: scheduleId },
    include: { device: true },
  });
  if (!schedule || schedule.device.userId !== userId) {
    throw new ApiError(404, 'SCHEDULE_NOT_FOUND', 'Schedule not found');
  }
  return schedule;
}

// PATCH /api/schedules/:id  (requires auth)
export const updateSchedule = asyncHandler(async (req: Request, res: Response) => {
  const existing = await requireOwnedSchedule(req.user!.id, req.params.id);
  const patch = req.body as UpdateScheduleInput;

  const schedule = await prisma.feedSchedule.update({
    where: { id: existing.id },
    data: patch,
  });
  await syncScheduleToDevice(existing.deviceId, existing.device.deviceCode);

  res.json({ message: 'Schedule updated', data: schedule });
});

// DELETE /api/schedules/:id  (requires auth)
export const deleteSchedule = asyncHandler(async (req: Request, res: Response) => {
  const existing = await requireOwnedSchedule(req.user!.id, req.params.id);

  await prisma.feedSchedule.delete({ where: { id: existing.id } });
  await syncScheduleToDevice(existing.deviceId, existing.device.deviceCode);

  res.json({ message: 'Schedule deleted' });
});
