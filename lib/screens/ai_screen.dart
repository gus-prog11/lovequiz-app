import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovequiz_app/services/ai_service.dart';
import 'package:lovequiz_app/services/emotional_service.dart';
import 'package:lovequiz_app/services/social_service.dart';
import 'package:lovequiz_app/services/premium_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    setState(() => _partner1 = doc.data()?['alias'] ?? 'Tú');
    _partner2 = 'Tu pareja';
    final premium = await PremiumService.getPremiumStatus();
    if (mounted) setState(() => _isPremium = premium.isPremium);
  }

  Future<void> _generateQuestion() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final question = AIService.generatePersonalizedQuestion(
      partner1: _partner1,
      partner2: _partner2,
    );
    if (mounted) setState(() {
      _generatedQuestion = question;
      _loading = false;
    });
  }

  Future<void> _calculateCompatibility() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final stats = await SocialService.getGameStats();
    final memories = await EmotionalService.getMemories();
    final favSnapshot = await EmotionalService.favoriteAnswersStream().first;
    final score = AIService.calculateCompatibility(
      totalGames: stats.totalGames,
      totalQuestions: stats.totalQuestions,
      streak: stats.currentStreak,
      memories: memories.length,
      favoriteAnswers: favSnapshot.docs.length,
    );
    if (mounted) setState(() {
      _compatibility = score;
      _compatibilityLoaded = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('LoveQuiz IA'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.blue.shade300]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pregunta Exclusiva para Ustedes',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('La IA genera preguntas únicas basadas en su conexión',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generateQuestion,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote, size: 32, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(_generatedQuestion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.4)),
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
            const Divider(),
            const SizedBox(height: 16),
            const Text('Analizador de Compatibilidad',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Descubre qué tan conectados están basado en su actividad',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            if (!_compatibilityLoaded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _calculateCompatibility,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.favorite),
                  label: Text(_loading ? 'Analizando...' : 'Analizar Compatibilidad'),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.purple.shade100]),
                  borderRadius: BorderRadius.circular(24),
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
                              backgroundColor: Colors.white,
                              color: _compatibility >= 70 ? Colors.green : (_compatibility >= 40 ? Colors.orange : Colors.red),
                            ),
                          ),
                          Text('${_compatibility.round()}%',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AIService.getCompatibilityMessage(_compatibility),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Sigan jugando para mejorar su conexión',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
            if (!_isPremium) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Premium genera preguntas ilimitadas y análisis avanzados',
                          style: TextStyle(color: Colors.amber.shade800, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
