import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/services/ai_service.dart';
import 'package:LoveQuiz/services/emotional_service.dart';
import 'package:LoveQuiz/services/premium_service.dart';
import 'package:LoveQuiz/services/social_service.dart';
import 'package:LoveQuiz/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  String _partner1 = '';
  String _partner2 = '';
  String _generatedQuestion = '';
  bool _loading = false;
  double _compatibility = 0;
  bool _compatibilityLoaded = false;
  bool _isPremium = false;
  String _coupleId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _partner1 = doc.data()?['alias'] ?? 'Tú';
        _coupleId = doc.data()?['coupleId'] ?? '';
      });
      _partner2 = 'Tu pareja';
      final premium = await PremiumService.getPremiumStatus();
      if (mounted) setState(() => _isPremium = premium.isPremium);
    } catch (e) {
      debugPrint('[AIScreen] _loadUserData error: $e');
      if (mounted) {
        AppToast.showError(context, 'No se pudieron cargar los datos');
      }
    }
  }

  Future<void> _generateQuestion() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final question = AIService.generatePersonalizedQuestion(
      partner1: _partner1,
      partner2: _partner2,
    );
    if (mounted) {
      setState(() {
        _generatedQuestion = question;
        _loading = false;
      });
    }
  }

  Future<void> _calculateCompatibility() async {
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final stats = await SocialService.getGameStats();
      final memories = await EmotionalService.getMemories();
      int favCount = 0;
      if (_coupleId.isNotEmpty) {
        final favSnapshot = await EmotionalService.favoriteAnswersStream(
          _coupleId,
        ).first;
        favCount = favSnapshot.docs.length;
      }
      final score = AIService.calculateCompatibility(
        totalGames: stats.totalGames,
        totalQuestions: stats.totalQuestions,
        streak: stats.currentStreak,
        memories: memories.length,
        favoriteAnswers: favCount,
      );
      if (mounted) {
        setState(() {
          _compatibility = score;
          _compatibilityLoaded = true;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AIScreen] _calculateCompatibility error: $e');
      if (mounted) {
        setState(() => _loading = false);
        AppToast.showError(context, 'No se pudo calcular la compatibilidad');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        elevation: 0,
        title: Text(
          'LoveQuiz IA',
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.pink, AppColors.purple],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pregunta Exclusiva para Ustedes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La IA genera preguntas únicas basadas en su conexión',
              style: TextStyle(fontSize: 14, color: ac.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generateQuestion,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Generando...' : 'Generar Pregunta'),
              ),
            ),
            if (_generatedQuestion.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ac.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: 0.3),
                  ),
                  boxShadow: isLight
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      size: 32,
                      color: AppColors.pink,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _generatedQuestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _generateQuestion,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Otra pregunta'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Divider(color: ac.divider),
            const SizedBox(height: 16),
            Text(
              'Analizador de Compatibilidad',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubre qué tan conectados están basado en su actividad',
              style: TextStyle(fontSize: 14, color: ac.textSecondary),
            ),
            const SizedBox(height: 20),
            if (!_compatibilityLoaded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _calculateCompatibility,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite),
                  label: Text(
                    _loading ? 'Analizando...' : 'Analizar Compatibilidad',
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.pink.withValues(alpha: 0.12),
                      AppColors.purple.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: _compatibility / 100,
                              strokeWidth: 10,
                              backgroundColor: ac.surface,
                              color: _compatibility >= 70
                                  ? Colors.green
                                  : (_compatibility >= 40
                                        ? Colors.orange
                                        : Colors.red),
                            ),
                          ),
                          Text(
                            '${_compatibility.round()}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ac.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AIService.getCompatibilityMessage(_compatibility),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sigan jugando para mejorar su conexión',
                      style: TextStyle(fontSize: 13, color: ac.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            if (!_isPremium) ...[
              const SizedBox(height: 24),
              Material(
                color: AppColors.pink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.go('/premium'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: AppColors.pink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Premium genera preguntas ilimitadas y análisis avanzados',
                            style: TextStyle(
                              color: ac.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.pink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
