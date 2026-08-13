import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {onCall} from 'firebase-functions/v2/https';
import {v2 as cloudinary} from 'cloudinary';

// ─── Modo Beta (sin Firebase Blaze) ─────────────────────────────────────────
// Este paquete (functions/) contiene las funciones de backend que dependen de
// Cloud Functions / Cloud Scheduler / Firebase Messaging y solo se despliegan
// cuando el proyecto tenga Blaze (ver lib/config/beta_config.dart en la app).
// Durante la beta NO se despliega: la app funciona sin ellas (grabación,
// Cloudinary, Firestore, historial y guardado permanente son 100% cliente).
//
// Para activar el backend cuando exista Blaze:
//   1. En lib/config/beta_config.dart poner BetaConfig.isBetaEnabled a false.
//   2. firebase deploy --only functions
//
// NO eliminar este código: es la limpieza automática de expirados y los
// recordatorios de expiración que se habilitarán en el futuro.

// Recordatorios de recuerdos de voz próximos a expirar.
export {sendExpiringReminders, testExpiringReminders} from './voiceReminders';

admin.initializeApp();

const firestore = admin.firestore();

// Cloudinary solo se configura si las credenciales existen. Configurar en
// Cloud Functions > Config: firebase functions:config:set (o variables de
// entorno) con CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY y
// CLOUDINARY_API_SECRET. Sin credenciales, la limpieza omite el borrado de
// audios (solo elimina los documentos de Firestore).
const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET;
if (cloudName && apiKey && apiSecret) {
  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
  });
}

interface CleanupResult {
  deleted: number;
  errors: number;
}

/**
 * Borra un audio de Cloudinary usando su publicId (no la URL).
 * Los fallos solo se registran: no bloquean la eliminación del documento.
 */
async function deleteCloudinaryAudio(publicId: string): Promise<void> {
  if (!publicId || !cloudName) return;
  try {
    // Los audios se suben con resource_type "video" (tipo que Cloudinary usa
    // para archivos de audio).
    await cloudinary.uploader.destroy(publicId, {resource_type: 'video'});
    logger.info(`Deleted Cloudinary asset: ${publicId}`);
  } catch (e) {
    logger.error(`Failed to delete Cloudinary asset ${publicId}: ${e}`);
  }
}

async function deleteExpiredMemories(): Promise<CleanupResult> {
  const now = admin.firestore.Timestamp.now();
  let deleted = 0;
  let errors = 0;

  logger.info('Starting cleanup of expired voice memories');

  const snapshot = await firestore
    .collectionGroup('voice_memories')
    .where('expiresAt', '<', now)
    .get();

  logger.info(`Found ${snapshot.size} documents with expired expiresAt`);

  const results = await Promise.allSettled(
    snapshot.docs.map(async (doc): Promise<boolean> => {
      const data = doc.data();

      // Skip permanent memories (both players have saved)
      const isPermanent = data.savedByPlayer1 === true && data.savedByPlayer2 === true;
      if (isPermanent) {
        logger.info(`Skipping permanent memory: ${doc.id}`);
        return false;
      }

      // Eliminar los audios en Cloudinary mediante su publicId y después
      // borrar el documento de Firestore.
      const p1PublicId = (data.player1PublicId as string | undefined) ?? '';
      const p2PublicId = (data.player2PublicId as string | undefined) ?? '';
      await deleteCloudinaryAudio(p1PublicId);
      await deleteCloudinaryAudio(p2PublicId);

      await doc.ref.delete();
      logger.info(`Deleted expired voice memory: ${doc.id}`);
      return true;
    }),
  );

  for (const result of results) {
    if (result.status === 'fulfilled') {
      if (result.value) deleted++;
    } else {
      logger.error(`Error processing memory: ${result.reason}`);
      errors++;
    }
  }

  return {deleted, errors};
}

/**
 * Scheduled cleanup — runs daily at midnight Mexico City time.
 */
export const cleanupExpiredMemories = onSchedule(
  {
    schedule: 'every day 00:00',
    timeZone: 'America/Mexico_City',
  },
  async () => {
    const result = await deleteExpiredMemories();
    logger.info(
      `Cleanup complete: ${result.deleted} memories deleted, ${result.errors} errors`,
    );
  },
);

/**
 * Manual trigger for testing — call from anywhere to run cleanup immediately.
 */
export const testCleanupExpiredMemories = onCall(
  {
    enforceAppCheck: false,
  },
  async () => {
    const result = await deleteExpiredMemories();
    return {
      success: true,
      deleted: result.deleted,
      errors: result.errors,
      message: `${result.deleted} memories deleted, ${result.errors} errors`,
    };
  },
);
