import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovequiz_app/models/premium_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<PremiumModel> getPremiumStatus() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || !doc.data()!.containsKey('premium')) {
      return PremiumModel();
    }
    return PremiumModel.fromMap(
      doc.data()!['premium'] as Map<String, dynamic>,
    );
  }

  static Future<void> activatePremium({int days = 365}) async {
    final expiresAt = DateTime.now().add(Duration(days: days));
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
    await _db
        .collection('users')
        .doc(_uid)
        .update({'premium': premium.toMap()});
  }

  static Future<void> setTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_$_uid', themeId);
  }

  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_$_uid');
  }

  static bool isPremiumCategory(String categoryId) {
    return premiumCategories.contains(categoryId);
  }

  static bool isPremiumChallenge(String challengeId) {
    return premiumChallenges.contains(challengeId);
  }
}
