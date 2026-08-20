import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {onCall, HttpsError} from 'firebase-functions/v2/https';

const firestore = admin.firestore();

// ─── Stale Room Cleanup ──────────────────────────────────────────────────────
// Elimina salas en estado waiting/setup/finished con más de 24 h de
// antigüedad. Estas salas quedan huérfanas cuando ambos jugadores cierran
// la app sin llamar a _exitGame o deleteRoom.

const STALE_ROOM_HOURS = 24;

interface CleanupResult {
  roomsDeleted: number;
  presenceDeleted: number;
  errors: number;
}

async function cleanupStaleRooms(): Promise<CleanupResult> {
  const cutoff = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - STALE_ROOM_HOURS * 60 * 60 * 1000),
  );

  let roomsDeleted = 0;
  let presenceDeleted = 0;
  let errors = 0;

  const staleStatuses = ['waiting', 'setup', 'playing', 'finished'];

  for (const status of staleStatuses) {
    const snapshot = await firestore
      .collection('rooms')
      .where('status', '==', status)
      .where('createdAt', '<', cutoff)
      .limit(100)
      .get();

    if (snapshot.empty) continue;
    logger.info(`Found ${snapshot.size} stale rooms with status=${status}`);

    const results = await Promise.allSettled(
      snapshot.docs.map(async (doc) => {
        // Borrar subcolección de presencia antes de la sala.
        const presenceSnap = await doc.ref.collection('presence').get();
        for (const pDoc of presenceSnap.docs) {
          await pDoc.ref.delete();
          presenceDeleted++;
        }
        await doc.ref.delete();
        roomsDeleted++;
      }),
    );

    for (const r of results) {
      if (r.status === 'rejected') {
        logger.error(`Error cleaning stale room: ${r.reason}`);
        errors++;
      }
    }
  }

  return {roomsDeleted, presenceDeleted, errors};
}

export const cleanupStaleRoomsScheduled = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'America/Mexico_City',
  },
  async () => {
    const result = await cleanupStaleRooms();
    logger.info(
      `Stale room cleanup: ${result.roomsDeleted} rooms, ${result.presenceDeleted} presence docs, ${result.errors} errors`,
    );
  },
);

export const testCleanupStaleRooms = onCall(
  {enforceAppCheck: true},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
    }
    const result = await cleanupStaleRooms();
    return {
      success: true,
      ...result,
      message: `${result.roomsDeleted} rooms, ${result.presenceDeleted} presence, ${result.errors} errors`,
    };
  },
);

// ─── Game History TTL ─────────────────────────────────────────────────────────
// Mantiene solo los últimos 100 registros de historial por usuario.
// Firestore rules bloquean delete/update en el cliente, solo Admin puede.

const GAME_HISTORY_LIMIT = 100;

async function trimGameHistory(): Promise<{
  trimmed: number;
  errors: number;
}> {
  let trimmed = 0;
  let errors = 0;

  // Obtener todos los userId únicos del game_history.
  const allHistory = await firestore
    .collection('game_history')
    .orderBy('createdAt', 'desc')
    .limit(10000)
    .get();

  const byUser = new Map<string, admin.firestore.QueryDocumentSnapshot[]>();
  for (const doc of allHistory.docs) {
    const userId = doc.data().userId as string;
    if (!userId) continue;
    const list = byUser.get(userId) ?? [];
    list.push(doc);
    byUser.set(userId, list);
  }

  const results = await Promise.allSettled(
    Array.from(byUser.entries()).map(async ([userId, docs]) => {
      if (docs.length <= GAME_HISTORY_LIMIT) return;

      // Mantener solo los más recientes; borrar el resto.
      const toDelete = docs.slice(GAME_HISTORY_LIMIT);
      for (const doc of toDelete) {
        await doc.ref.delete();
        trimmed++;
      }
    }),
  );

  for (const r of results) {
    if (r.status === 'rejected') {
      logger.error(`Error trimming game history: ${r.reason}`);
      errors++;
    }
  }

  return {trimmed, errors};
}

export const trimGameHistoryScheduled = onSchedule(
  {
    schedule: 'every day 01:00',
    timeZone: 'America/Mexico_City',
  },
  async () => {
    const result = await trimGameHistory();
    logger.info(
      `Game history trim: ${result.trimmed} records removed, ${result.errors} errors`,
    );
  },
);

export const testTrimGameHistory = onCall(
  {enforceAppCheck: true},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
    }
    const result = await trimGameHistory();
    return {
      success: true,
      ...result,
      message: `${result.trimmed} trimmed, ${result.errors} errors`,
    };
  },
);
