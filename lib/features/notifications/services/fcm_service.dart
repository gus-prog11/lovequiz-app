import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../repositories/fcm_token_repository.dart';

/// Coordina las notificaciones push (FCM) de la aplicación.
///
/// - Registra el token de cada dispositivo en users/{uid}/fcmTokens.
/// - Muestra la notificación localmente cuando la app está en primer plano
///   (FCM no lo hace automáticamente en ese estado).
/// - Al tocar una notificación de recuerdos de voz navega a /voice-memories.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  /// Canal usado para mostrar las notificaciones en primer plano.
  static const String _channelId = 'voice_reminders';
  static const String _channelName = 'Recuerdos de voz';
  static const String _payloadVoiceMemories = 'voice_memories';
  static const String _dataTypeKey = 'type';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Ruta pendiente de abrir cuando la app arranca en frío desde una
  /// notificación. La consume SplashScreen tras verificar la sesión.
  static String? initialRoute;

  void Function()? _onOpenVoiceMemories;

  /// Consume y limpia la ruta inicial guardada por una notificación.
  static String? takeInitialRoute() {
    final route = initialRoute;
    initialRoute = null;
    return route;
  }

  /// Inicializa la mensajería y los listeners de navegación.
  ///
  /// Solo espera la lectura de getInitialMessage (necesaria para que
  /// SplashScreen encuentre la ruta pendiente); permisos y registro del token
  /// se hacen en segundo plano.
  Future<void> init({required void Function() onOpenVoiceMemories}) async {
    _onOpenVoiceMemories = onOpenVoiceMemories;

    await _initLocalNotifications();
    _setupListeners();

    // Registrar el dispositivo en cuanto haya sesión (cubre login y arranque).
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_registerToken(user.uid));
    });

    // Apertura en frío (app terminada): se difiere a SplashScreen.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleOpenedMessage(initial, fromTerminated: true);

    // Solicitar permisos sin bloquear el arranque de la app.
    unawaited(requestPermissions());
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: ios,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Toque en la notificación mostrada en primer plano.
        if (response.payload == _payloadVoiceMemories) {
          _openVoiceMemories();
        }
      },
    );
  }

  void _setupListeners() {
    // Actualizar el token cuando Firebase lo rota.
    _messaging.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await FcmTokenRepository.upsertToken(uid, token);
    });

    // App en primer plano: mostrar la notificación de forma local.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      unawaited(_showLocalNotification(n.title ?? '', n.body ?? ''));
    });

    // App en segundo plano y el usuario toca la notificación.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleOpenedMessage(message, fromTerminated: false);
    });
  }

  void _handleOpenedMessage(
    RemoteMessage message, {
    required bool fromTerminated,
  }) {
    if (message.data[_dataTypeKey] != _payloadVoiceMemories) return;

    if (fromTerminated) {
      // La app arrancará por SplashScreen; diferir la navegación.
      initialRoute = '/voice-memories';
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _openVoiceMemories();
    } else {
      initialRoute = '/voice-memories';
    }
  }

  void _openVoiceMemories() => _onOpenVoiceMemories?.call();

  Future<void> _registerToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FcmTokenRepository.upsertToken(uid, token);
      debugPrint('[Fcm] token registrado correctamente');
    } catch (e) {
      debugPrint('[Fcm] no se pudo registrar el token: $e');
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Avisos de recuerdos de voz próximos a expirar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: _payloadVoiceMemories,
    );
  }

  /// Solicita permisos de notificación (Android 13+ e iOS).
  Future<void> requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
