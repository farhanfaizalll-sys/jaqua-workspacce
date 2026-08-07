import { z } from 'zod';

export const createDeviceSchema = z.object({
  name: z.string().min(1).max(100),
  // Must match the MQTT topic segment the physical Gateway/pond unit uses
  // (e.g. "kolam1" for topics jaqua/kolam1/data and jaqua/kolam1/cmd).
  deviceCode: z
    .string()
    .min(1)
    .max(50)
    .regex(/^[a-zA-Z0-9_-]+$/, 'deviceCode may only contain letters, numbers, - and _'),
});

export const setPowerSchema = z.object({
  isOn: z.boolean(),
});

export const createScheduleSchema = z.object({
  jam: z.number().int().min(0).max(23),
  menit: z.number().int().min(0).max(59),
  enabled: z.boolean().default(true),
});

export const updateScheduleSchema = z
  .object({
    jam: z.number().int().min(0).max(23).optional(),
    menit: z.number().int().min(0).max(59).optional(),
    enabled: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type CreateDeviceInput = z.infer<typeof createDeviceSchema>;
export type SetPowerInput = z.infer<typeof setPowerSchema>;
export type CreateScheduleInput = z.infer<typeof createScheduleSchema>;
export type UpdateScheduleInput = z.infer<typeof updateScheduleSchema>;
