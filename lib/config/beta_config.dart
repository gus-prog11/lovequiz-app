/// Configuración del Modo Beta de los Recuerdos de Voz.
///
/// El proyecto todavía no tiene Firebase Blaze, por lo que las capacidades
/// que dependen de backend gestionado (Cloud Functions, Cloud Scheduler y
/// Firebase Messaging / notificaciones push) están TEMPORALMENTE
/// deshabilitadas. Todo ese código permanece en el proyecto y se reactiva en
/// cuanto el proyecto tenga Blaze.
///
/// Cómo activar la funcionalidad completa cuando exista Blaze:
///   1. Activar el plan Blaze del proyecto Firebase (requisito de Cloud
///      Scheduler, que dispara limpieza y recordatorios).
///   2. Poner [isBetaEnabled] a `false`.
///   3. Desplegar las Cloud Functions (carpeta functions/):
///      `firebase deploy --only functions`.
///      (El CLI crea además el índice de Firestore de firestore.indexes.json
///      necesario para consultar por expiresAt en collection-group.)
///   4. Opcional pero recomendado: configurar las credenciales de Cloudinary
///      en Cloud Functions (Config del proyecto o variables de entorno):
///      CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY y CLOUDINARY_API_SECRET.
///      Sin ellas, la limpieza borra el documento de Firestore pero deja el
///      audio huérfano en Cloudinary.
///   5. Push en cada plataforma (ya preparado en el código):
///      - Android: el permiso POST_NOTIFICATIONS ya está en el manifest y el
///        cliente pide permiso en Android 13+ (FcmService.requestPermissions).
///      - iOS: la app tiene Runner.entitlements con aps-environment y
///        UIBackgroundModes = remote-notification en Info.plist. Antes de
///        subir a la App Store cambia aps-environment a `production`. Además
///        hay que registrar la key APNs del proyecto en la consola de Firebase
///        y firmar con un perfil de aprovisionamiento que incluya Push.
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
  static const bool isBetaEnabled = false;

  /// En beta la limpieza automática de recuerdos expirados está desactivada
  /// (la Cloud Function no está desplegada). Los recuerdos se conservan; la
  /// interfaz sigue mostrando el tiempo restante con expiresAt.
  static bool get cleanupEnabled => !isBetaEnabled;

  /// En beta no se registran tokens FCM ni se muestran notificaciones push.
  static bool get notificationsEnabled => !isBetaEnabled;
}
