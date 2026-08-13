/// Configuración del Modo Beta de los Recuerdos de Voz.
///
/// El proyecto todavía no tiene Firebase Blaze, por lo que las capacidades
/// que dependen de backend gestionado (Cloud Functions, Cloud Scheduler y
/// Firebase Messaging / notificaciones push) están TEMPORALMENTE
/// deshabilitadas. Todo ese código permanece en el proyecto y se reactiva en
/// cuanto el proyecto tenga Blaze.
///
/// Cómo activar la funcionalidad completa cuando exista Blaze:
///   1. Poner [isBetaEnabled] a `false`.
///   2. Desplegar las Cloud Functions (carpeta functions/):
///      `firebase deploy --only functions`.
///
/// Dónde vive cada parte:
///   - Beta (cliente, activo siempre):
///       grabación/reproducción de voz, regrabado, subida a Cloudinary,
///       escritura en Firestore, sincronización entre jugadores, historial,
///       guardado permanente y contador de expiración (expiresAt).
///   - Blaze (backend, inactivo en beta, NO eliminar):
///       functions/src/index.ts            -> limpieza de expirados (scheduler).
///       functions/src/voiceReminders.ts   -> recordatorios 24h/2h (scheduler + FCM).
///       FcmService (features/notifications) -> registro de token FCM y push.
class BetaConfig {
  /// `true` = modo beta sin Blaze (no se usa Cloud Functions, Cloud
  /// Scheduler ni Firebase Messaging). `false` = funcionalidad completa.
  static const bool isBetaEnabled = true;

  /// En beta la limpieza automática de recuerdos expirados está desactivada
  /// (la Cloud Function no está desplegada). Los recuerdos se conservan; la
  /// interfaz sigue mostrando el tiempo restante con expiresAt.
  static bool get cleanupEnabled => !isBetaEnabled;

  /// En beta no se registran tokens FCM ni se muestran notificaciones push.
  static bool get notificationsEnabled => !isBetaEnabled;
}
