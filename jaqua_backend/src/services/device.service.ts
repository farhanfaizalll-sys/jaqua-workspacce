import { prisma } from '../lib/prisma';
import { ApiError } from '../utils/apiError';

/** Fetches a device and throws 404 unless it belongs to the given user. */
export async function requireOwnedDevice(userId: string, deviceId: string) {
  const device = await prisma.device.findUnique({ where: { id: deviceId } });
  if (!device || device.userId !== userId) {
    throw new ApiError(404, 'DEVICE_NOT_FOUND', 'Device not found');
  }
  return device;
}

/** Formats a device's active schedules as the CSV-style command the firmware expects. */
export async function scheduleSyncCommand(deviceId: string): Promise<string> {
  const schedules = await prisma.feedSchedule.findMany({
    where: { deviceId, enabled: true },
    orderBy: [{ jam: 'asc' }, { menit: 'asc' }],
  });
  const times = schedules.map(
    (s) => `${String(s.jam).padStart(2, '0')}:${String(s.menit).padStart(2, '0')}`,
  );
  return `SCHEDULE,${times.join(',')}`;
}
