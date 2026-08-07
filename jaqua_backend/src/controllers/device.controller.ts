import { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { ApiError, asyncHandler } from '../utils/apiError';
import { publishCommand } from '../services/mqtt.service';
import { requireOwnedDevice } from '../services/device.service';
import { CreateDeviceInput, SetPowerInput } from '../validators/device.validator';

// GET /api/devices  (requires auth)
export const listDevices = asyncHandler(async (req: Request, res: Response) => {
  const devices = await prisma.device.findMany({
    where: { userId: req.user!.id },
    orderBy: { createdAt: 'asc' },
  });
  res.json({ data: devices });
});

// POST /api/devices  (requires auth)
// Registers a pond unit's deviceCode (must match the code baked into its
// Gateway's MQTT topics) so its data starts appearing in this account.
export const createDevice = asyncHandler(async (req: Request, res: Response) => {
  const { name, deviceCode } = req.body as CreateDeviceInput;

  const existing = await prisma.device.findUnique({ where: { deviceCode } });
  if (existing) {
    throw new ApiError(409, 'DEVICE_CODE_TAKEN', 'This device code is already registered');
  }

  const device = await prisma.device.create({
    data: { name, deviceCode, userId: req.user!.id },
  });
  res.status(201).json({ message: 'Device registered', data: device });
});

// GET /api/devices/:id  (requires auth)
export const getDevice = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.id);
  res.json({ data: device });
});

// PATCH /api/devices/:id/power  (requires auth)
// Toggles the device on/off. Publishes an MQTT command for the Gateway to
// relay via LoRa — see mqtt.service.ts for the current firmware limitation.
export const setPower = asyncHandler(async (req: Request, res: Response) => {
  const { isOn } = req.body as SetPowerInput;
  const device = await requireOwnedDevice(req.user!.id, req.params.id);

  const updated = await prisma.device.update({ where: { id: device.id }, data: { isOn } });
  publishCommand(device.deviceCode, isOn ? 'ON' : 'OFF');

  res.json({ message: `Device turned ${isOn ? 'on' : 'off'}`, data: updated });
});

// POST /api/devices/:id/feed-now  (requires auth)
// Manual "feed now" outside the schedule. Recorded immediately (optimistic —
// there is no ack path from the hardware yet) and published as a command.
export const feedNow = asyncHandler(async (req: Request, res: Response) => {
  const device = await requireOwnedDevice(req.user!.id, req.params.id);

  const feedEvent = await prisma.feedEvent.create({
    data: { deviceId: device.id, triggeredBy: 'MANUAL' },
  });
  publishCommand(device.deviceCode, 'FEED_NOW');

  res.status(201).json({ message: 'Feed command sent', data: feedEvent });
});
