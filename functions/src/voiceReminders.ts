import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {onCall, HttpsError} from 'firebase-functions/v2/https';

const firestore = admin.firestore();

// Recordatorios aproximados: 24h antes y 2h antes de la expiración.
const DAY_REMINDER_MS = 24 * 60 * 60 * 1000;
const FINAL_REMINDER_MS = 2 * 60 * 60 * 1000;

interface ReminderResult {
  daySent: number;
  finalSent: number;
  errors: number;
}

interface ReminderContent {
  title: string;
  body: string;
}

function reminderFor(kind: 'day' | 'final'): ReminderContent {
  return kind === 'day'
    ? {
        title: '❤️ Un recuerdo de voz desaparecerá mañana',
        body: 'Guárdalo si quieres conservarlo para siempre.',
      }
    : {
        title: '⏳ Última oportunidad',
        body: 'Tu recuerdo de voz desaparecerá muy pronto.',
      };
}

/**
 * Recordatorio de recuerdos de voz próximos a expirar.
 *
 * Ejecución horaria para garantizar que ambos avisos (24h y 2h) caen siempre
 * dentro de su ventana: con un schedule diario el aviso de 2h dependía de que
 * la ejecución cayera en la ventana. Con una ejecución por hora:
 *   - aviso de 24h: se envía en la primera ejecución con hoursLeft <= 24
 *     (≈24h antes, ±1h);
 *   - aviso de 2h: en la primera con hoursLeft <= 2 (≈2h antes, ±1h).
 * Cada aviso se envía una sola vez gracias a los campos dayReminderSent /
 * finalReminderSent; si el envío falla, el campo no se marca y se reintenta
 * en la siguiente ejecución (idempotente y autorrecuperable).
 *
 * Solo procesa recuerdos completados (no pendientes), no permanentes y no
 * expirados.
 */
export const sendExpiringReminders = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'America/Mexico_City',
  },
  async () => {
    const result = await runExpiringReminders();
    logger.info(
      `Reminders sent: ${result.daySent} day, ${result.finalSent} final, ${result.errors} errors`,
    );
  },
);

/** Trigger manual de prueba: ejecuta los recordatorios al instante. */
export const testExpiringReminders = onCall(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
    }
    const result = await runExpiringReminders();
    return {
      success: true,
      ...result,
      message: `day=${result.daySent} final=${result.finalSent} errors=${result.errors}`,
    };
  },
);

export async function runExpiringReminders(): Promise<ReminderResult> {
  const now = Date.now();
  const lower = new Date(now);
  const upper = new Date(now + DAY_REMINDER_MS + 60 * 60 * 1000);

  // Rango simple sobre expiresAt (mismo índice que la limpieza); el resto de
  // filtros (permanente, pendiente, local, avisos ya enviados) se aplican aquí.
  const snapshot = await firestore
    .collectionGroup('voice_memories')
    .where('expiresAt', '>', lower)
    .where('expiresAt', '<', upper)
    .get();

  let daySent = 0;
  let finalSent = 0;
  let errors = 0;

  const results = await Promise.allSettled(
    snapshot.docs.map(async (doc) => {
      const data = doc.data();

      // Solo recuerdos completados (ambos audios subidos).
      if (data.pending !== false) return;
      // Los recuerdos locales (un solo dispositivo) no tienen tokens FCM.
      const coupleId = data.coupleId as string | undefined;
      if (coupleId?.startsWith('local_')) return;
      // Recordatorios permanentes: no se notifica.
      const isPermanent =
        data.savedByPlayer1 === true && data.savedByPlayer2 === true;
      if (isPermanent) return;

      const expiresAt = data.expiresAt as admin.firestore.Timestamp | undefined;
      if (!expiresAt) return;

      const hoursLeft = (expiresAt.toMillis() - now) / (60 * 60 * 1000);

      // Prioriza el aviso final si aplica; si no, el de 24h. Cada uno se
      // envía únicamente una vez (campos dayReminderSent / finalReminderSent).
      let kind: 'day' | 'final' | null = null;
      if (
        hoursLeft <= FINAL_REMINDER_MS / (60 * 60 * 1000) &&
        data.finalReminderSent !== true
      ) {
        kind = 'final';
      } else if (
        hoursLeft <= DAY_REMINDER_MS / (60 * 60 * 1000) &&
        data.dayReminderSent !== true
      ) {
        kind = 'day';
      }
      if (!kind) return;

      const player1Id = data.player1Id as string | undefined;
      const player2Id = data.player2Id as string | undefined;
      const delivered = await sendToPlayers(
        [player1Id, player2Id].filter((uid): uid is string => Boolean(uid)),
        reminderFor(kind),
      );

      // Solo se marca como enviado si al menos un dispositivo lo recibió;
      // en caso contrario se reintentará en la siguiente ejecución.
      if (!delivered) {
        errors++;
        return;
      }

      const field = kind === 'day' ? 'dayReminderSent' : 'finalReminderSent';
      await doc.ref.update({[field]: true});
      if (kind === 'day') daySent++;
      else finalSent++;
    }),
  );

  for (const result of results) {
    if (result.status === 'rejected') {
      logger.error(`Error processing reminder: ${result.reason}`);
      errors++;
    }
  }

  return {daySent, finalSent, errors};
}

/**
 * Envía el aviso a todos los dispositivos de cada miembro de la pareja
 * (varios tokens por usuario). Los tokens inválidos se eliminan sin detener
 * el envío al resto. Devuelve true si al menos un dispositivo lo recibió.
 */
async function sendToPlayers(
  uids: string[],
  reminder: ReminderContent,
): Promise<boolean> {
  const tokensByUid = new Map<string, string[]>();
  for (const uid of uids) {
    try {
      const snap = await firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .get();
      const tokens = snap.docs
        .map((d) => d.data().token as string | undefined)
        .filter((token): token is string => Boolean(token));
      if (tokens.length > 0) tokensByUid.set(uid, tokens);
    } catch (e) {
      // Un usuario fallido no detiene el envío al otro.
      logger.error(`Failed to load tokens for user ${uid}: ${e}`);
    }
  }

  const tokens = [...tokensByUid.values()].flat();
  if (tokens.length === 0) return false;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title: reminder.title, body: reminder.body},
    data: {type: 'voice_memories'},
  });

  // Eliminar tokens inválidos; los errores no detienen el envío al resto.
  response.responses.forEach((result, i) => {
    if (result.success) return;
    const code = result.error?.code ?? '';
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      const token = tokens[i];
      const uid = [...tokensByUid.entries()].find(([, ts]) =>
        ts.includes(token),
      )?.[0];
      if (uid && token) {
        firestore
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .delete()
          .then(() =>
            logger.info(`Removed invalid FCM token for user ${uid}`),
          )
          .catch((e) => logger.error(`Failed to remove invalid token: ${e}`));
      }
    } else {
      logger.error(`FCM send error (${code}): ${result.error?.message}`);
    }
  });

  return response.successCount > 0;
}
