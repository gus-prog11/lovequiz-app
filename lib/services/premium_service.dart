import 'package:LoveQuiz/models/premium_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Obtiene el estado premium del usuario desde Firestore.
  static Future<PremiumModel> getPremiumStatus() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || !doc.data()!.containsKey('premium')) {
      return PremiumModel();
    }
    return PremiumModel.fromMap(doc.data()!['premium'] as Map<String, dynamic>);
  }

  // Activa la membresía premium con categorías y retos desbloqueados.
  //
  // Si ya hay una membresía vigente, los días se SUMAN a lo que queda en vez
  // de reiniciar el contador desde hoy (un re-compra no puede acortar la
  // suscripción).
  static Future<void> activatePremium({int days = 365}) async {
    final now = DateTime.now();
    var base = now;
    try {
      final current = await getPremiumStatus();
      if (current.isPremium &&
          current.expiresAt != null &&
          current.expiresAt!.isAfter(now)) {
        base = current.expiresAt!;
      }
    } catch (_) {}
    final expiresAt = base.add(Duration(days: days));
    final premium = PremiumModel(
      isPremium: true,
      expiresAt: expiresAt,
      unlockedCategories: const [
        'viajes',
        'familia',
        'intimidad_profunda',
        'futuro',
        'confesiones',
        'agradecimiento',
      ],
      unlockedChallenges: const [
        'retos_sensoriales',
        'retos_salidas',
        'retos_sorpresa',
        'retos_conexion',
        'retos_aventura',
      ],
    );
    await _db.collection('users').doc(_uid).update({
      'premium': premium.toMap(),
    });
  }

  // Guarda el tema visual seleccionado por el usuario.
  static Future<void> setTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_$_uid', themeId);
  }

  // Obtiene el tema visual guardado del usuario.
  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_$_uid');
  }

  // ─── MODO DE TEMA (Sistema / Claro / Oscuro) ──────────────────────────

  static const String _themeModeKey = 'app_theme_mode';

  // Guarda la preferencia de modo de tema.
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final index = ThemeMode.values.indexOf(mode);
    await prefs.setInt(_themeModeKey, index);
    _themeModeNotifier.value = mode;
  }

  // Obtiene el modo de tema guardado.
  static Future<ThemeMode> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeModeKey);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  // Notificador global para cambios de tema en tiempo real.
  static final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  static ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  // ─── TEMPORIZADOR ──────────────────────────────────────────────────────

  static const String _timerKey = 'app_timer_seconds';

  // Guarda el tiempo por pregunta.
  static Future<void> setTimerSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerKey, seconds);
  }

  // Obtiene el tiempo por pregunta guardado.
  static Future<int> getTimerSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timerKey) ?? 30;
  }

  // ─── SONIDO ────────────────────────────────────────────────────────────

  static const String _soundKey = 'app_sound_enabled';

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  // ─── VIBRACIÓN ─────────────────────────────────────────────────────────

  static const String _vibrationKey = 'app_vibration_enabled';

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, enabled);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  // ─── NOTIFICACIONES ────────────────────────────────────────────────────

  static const String _notificationsKey = 'app_notifications_enabled';

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  // Verifica si una categoría requiere membresía premium.
  static bool isPremiumCategory(String categoryId) {
    return premiumCategories.contains(categoryId);
  }

  // Verifica si un reto requiere membresía premium.
  static bool isPremiumChallenge(String challengeId) {
    return premiumChallenges.contains(challengeId);
  }
}
