import mqtt, { MqttClient } from 'mqtt';
import { env } from '../config/env';
import { prisma } from '../lib/prisma';

/**
 * Bridges the physical devices (ESP32 Gateway <-LoRa-> pond unit) to the
 * database over MQTT.
 *
 * Topics (fixed convention, one pair per device):
 *   jaqua/{deviceCode}/data  <- Gateway forwards LoRa packets received from
 *                               the pond unit here. Payload is a CSV string:
 *                               "DATA,<suhu>,<levelPeletPersen>" or "EVENT,FEED".
 *   jaqua/{deviceCode}/cmd   -> App-triggered commands published here for the
 *                               Gateway to relay back down via LoRa: "FEED_NOW",
 *                               "ON", "OFF". NOTE: as of 2026-08-01 the ESP32
 *                               firmware only sends on the data topic — it does
 *                               not yet subscribe to/act on the cmd topic. This
 *                               bridge publishes commands either way so the app
 *                               feature works end-to-end the moment the
 *                               firmware update lands (see project notes).
 */

let client: MqttClient | null = null;

const DATA_TOPIC_FILTER = 'jaqua/+/data';

function topicToDeviceCode(topic: string): string | null {
  // "jaqua/<code>/data" -> "<code>"
  const parts = topic.split('/');
  return parts.length === 3 && parts[0] === 'jaqua' && parts[2] === 'data' ? parts[1] : null;
}

async function handleDataMessage(deviceCode: string, payload: string): Promise<void> {
  const device = await prisma.device.findUnique({ where: { deviceCode } });
  if (!device) {
    // Message from a device not yet registered in the app — nothing to attach it to.
    return;
  }

  const parts = payload.split(',').map((p) => p.trim());

  if (parts[0] === 'DATA' && parts.length === 3) {
    const suhu = Number(parts[1]);
    const levelPeletPersen = Number(parts[2]);
    if (Number.isNaN(suhu) || Number.isNaN(levelPeletPersen)) return;

    await prisma.$transaction([
      prisma.sensorReading.create({
        data: { deviceId: device.id, suhu, levelPeletPersen },
      }),
      prisma.device.update({
        where: { id: device.id },
        data: { lastSuhu: suhu, lastLevelPeletPersen: levelPeletPersen, lastSeenAt: new Date() },
      }),
    ]);
    return;
  }

  if (parts[0] === 'EVENT' && parts[1] === 'FEED') {
    await prisma.$transaction([
      prisma.feedEvent.create({ data: { deviceId: device.id, triggeredBy: 'SCHEDULE' } }),
      prisma.device.update({ where: { id: device.id }, data: { lastSeenAt: new Date() } }),
    ]);
  }
}

export function connectMqtt(): MqttClient {
  if (client) return client;

  client = mqtt.connect(env.MQTT_BROKER_URL, {
    username: env.MQTT_USERNAME || undefined,
    password: env.MQTT_PASSWORD || undefined,
    reconnectPeriod: 3000,
  });

  client.on('connect', () => {
    // eslint-disable-next-line no-console
    console.log(`MQTT connected to ${env.MQTT_BROKER_URL}, subscribing to ${DATA_TOPIC_FILTER}`);
    client!.subscribe(DATA_TOPIC_FILTER);
  });

  client.on('message', (topic, payloadBuf) => {
    const deviceCode = topicToDeviceCode(topic);
    if (!deviceCode) return;
    const payload = payloadBuf.toString('utf8');
    handleDataMessage(deviceCode, payload).catch((err) => {
      // eslint-disable-next-line no-console
      console.error(`Failed to handle MQTT message on ${topic}:`, err);
    });
  });

  client.on('error', (err) => {
    // eslint-disable-next-line no-console
    console.error('MQTT client error:', err);
  });

  return client;
}

/** Publishes a command for the Gateway to relay to a device via LoRa. */
export function publishCommand(deviceCode: string, command: string): void {
  if (!client) throw new Error('MQTT client not connected yet');
  client.publish(`jaqua/${deviceCode}/cmd`, command);
}
