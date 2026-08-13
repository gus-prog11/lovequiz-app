import 'dart:math';

import 'package:flutter/material.dart';

import 'package:LoveQuiz/config/app_colors.dart';

import '../data/question_bank_v1.dart';
import '../domain/enums/chapter.dart';
import '../domain/enums/intensity.dart';
import '../domain/models/game_engine_state.dart';
import '../domain/models/game_round.dart';
import '../domain/models/game_settings.dart';
import '../domain/repositories/in_memory_question_repository.dart';
import '../engine/game_engine.dart';

/// Pantalla de prueba del motor (partida paralela al juego actual).
///
/// Juega una partida generada por [GameEngine] con el banco V1
/// (`bancoV1Questions`) y muestra en pantalla, por ronda, el capítulo, la
/// emoción, la intensidad y la pregunta elegida por el selector, más un panel
/// DEBUG temporal con los metadatos en bruto (tipo, categoría, id) para
/// verificar que el motor decide lo que diseñamos. No toca el flujo legacy.
class EngineTestScreen extends StatefulWidget {
  const EngineTestScreen({super.key, this.initialSeed = 0});

  /// Semilla inicial del motor. Cada "Nueva partida" la incrementa para
  /// explorar distintos recorridos.
  final int initialSeed;

  @override
  State<EngineTestScreen> createState() => _EngineTestScreenState();
}

class _EngineTestScreenState extends State<EngineTestScreen> {
  static const _pink = Color(0xFFFF2E93);

  late GameEngine _engine;
  int _seed = 0;

  GameRound? _currentRound;
  bool _loading = true;
  bool _finished = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _seed = widget.initialSeed;
    _engine = _createEngine(_seed);
    _startMatch();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  GameEngine _createEngine(int seed) => GameEngine(
    settings: const GameSettings(chapters: Chapter.values),
    repository: InMemoryQuestionRepository(bancoV1Questions),
    random: Random(seed),
  );

  Future<void> _startMatch() async {
    await _engine.start();
    if (!mounted) return;
    await _advance();
  }

  Future<void> _restart() async {
    _seed += 1;
    _engine.dispose();
    setState(() {
      _engine = _createEngine(_seed);
      _loading = true;
      _finished = false;
      _currentRound = null;
      _notice = null;
    });
    await _startMatch();
  }

  /// Pide la siguiente pregunta del motor y la muestra.
  Future<void> _advance() async {
    if (!_engine.state.canContinue) {
      if (mounted) setState(() => _finished = true);
      return;
    }
    if (mounted) setState(() => _loading = true);

    // Las rondas sin pregunta compatible (Nivel 5) se omiten solas, una tras
    // otra, hasta encontrar una jugable o terminar la partida.
    var skippedCount = 0;
    var question = await _engine.next();
    while (question == null && _engine.state.canContinue) {
      final round = _engine.state.rounds[_engine.state.roundIndex];
      await _engine.answer(round.copyWith(skipped: true));
      skippedCount++;
      question = await _engine.next();
    }
    if (!mounted) return;

    if (question == null) {
      // La última ronda también quedó sin pregunta: la partida termina.
      setState(() {
        _notice = skippedCount > 0
            ? 'N5 · $skippedCount rondas omitidas sin pregunta compatible'
            : null;
        _currentRound = null;
        _loading = false;
        _finished = true;
      });
      return;
    }

    setState(() {
      _currentRound = _engine.state.rounds[_engine.state.roundIndex];
      _loading = false;
      _notice = skippedCount > 0
          ? 'N5 · $skippedCount rondas omitidas sin pregunta compatible'
          : null;
    });
  }

  Future<void> _answer({required bool skipped}) async {
    final round = _currentRound;
    if (round == null) return;
    await _engine.answer(round.copyWith(skipped: skipped));
    if (!mounted) return;
    await _advance();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final state = _engine.state;

    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildHeader(
                ac,
                roundIndex: state.roundIndex,
                totalRounds: state.totalRounds,
              ),
              if (!_finished && state.totalRounds > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: state.roundIndex / state.totalRounds,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: ac.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(_pink),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildBody(ac, state)),
              const SizedBox(height: 16),
              _buildBottomBar(ac),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppColors ac, {
    required int roundIndex,
    required int totalRounds,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: ac.textPrimary),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Motor · Prueba',
                style: TextStyle(
                  color: _pink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Semilla $_seed · banco V1 (${bancoV1Questions.length})',
                style: TextStyle(color: ac.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (!_finished && totalRounds > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: ac.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Ronda ${roundIndex + 1}/$totalRounds',
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          tooltip: 'Nueva partida (semilla ${_seed + 1})',
          onPressed: _restart,
          icon: Icon(Icons.refresh, color: ac.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBody(AppColors ac, GameEngineState state) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }
    if (_finished) return _buildFinished(ac, state);

    final round = _currentRound;
    if (round == null || round.question == null) {
      return Center(
        child: Text('Preparando...', style: TextStyle(color: ac.textMuted)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRoundCard(ac, round),
          const SizedBox(height: 16),
          _buildDebugPanel(ac, round),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(
              _notice!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundCard(AppColors ac, GameRound round) {
    final q = round.question!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5FA2), Color(0xFFFF7A8A), Color(0xFFB8439F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5FA2).withValues(alpha: .30),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: ac.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            _meta('CAPÍTULO', round.chapter.label),
            const SizedBox(height: 14),
            _meta('EMOCIÓN', '${round.emotion.emoji} ${round.emotion.label}'),
            const SizedBox(height: 14),
            _meta(
              'INTENSIDAD',
              '${q.intensity.label} · ${q.intensity.level}/${Intensity.values.length}',
            ),
            const SizedBox(height: 22),
            Container(height: 1, color: ac.divider),
            const SizedBox(height: 22),
            Text(
              q.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: ac.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _pink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDebugPanel(AppColors ac, GameRound round) {
    final q = round.question!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.developer_mode, color: Color(0xFF00E676), size: 15),
              SizedBox(width: 6),
              Text(
                'DEBUG',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _debugLine('Chapter', q.chapter.name),
          _debugLine('Emotion', q.emotion.name),
          _debugLine('Intensity planeada', round.intensity.level),
          _debugLine('Intensity pregunta', q.intensity.level),
          _debugLine('QuestionType', q.type.name),
          _debugLine('Category', q.category.name),
          _debugLine('Question ID', q.id),
        ],
      ),
    );
  }

  Widget _debugLine(String key, Object value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(AppColors ac, GameEngineState state) {
    final answered = state.history.where((r) => !r.skipped).length;
    final skipped = state.history.where((r) => r.skipped).length;
    final withoutQuestion = state.rounds
        .where((r) => r.question == null)
        .length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ac.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ac.borderLight),
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration, color: _pink, size: 36),
              const SizedBox(height: 8),
              Text(
                'Partida terminada',
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Respondidas: $answered  ·  Omitidas: $skipped'
                '${withoutQuestion > 0 ? '  ·  Sin pregunta (N5): $withoutQuestion' : ''}',
                textAlign: TextAlign.center,
                style: TextStyle(color: ac.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildJourney(ac, state.history),
              const SizedBox(height: 16),
              Text(
                'Rondas',
                style: TextStyle(
                  color: ac.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < state.history.length; i++) ...[
                _buildRoundTile(ac, state.history[i], i),
                if (i < state.history.length - 1)
                  const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Recorrido emocional de la partida: para cada ronda muestra el capítulo,
  /// la emoción y la intensidad planeada (espacio) vs real (pregunta), con
  /// marcadores de saltos bruscos (≥ 2 niveles) entre rondas consecutivas.
  Widget _buildJourney(AppColors ac, List<GameRound> history) {
    final planned = _pink.withValues(alpha: .40);
    final inactive = ac.divider;

    final rows = <Widget>[];
    Intensity? prevReal;
    for (var i = 0; i < history.length; i++) {
      final r = history[i];
      final real = r.question?.intensity;
      final jumped =
          prevReal != null && real != null && real.level - prevReal.level >= 2;
      rows.add(
        _buildJourneyRow(
          ac,
          r,
          index: i,
          real: real,
          jumped: jumped,
          plannedColor: planned,
          inactiveColor: inactive,
        ),
      );
      if (real != null) prevReal = real;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: _pink, size: 16),
              SizedBox(width: 6),
              Text(
                'RECORRIDO EMOCIONAL',
                style: TextStyle(
                  color: _pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Pips(level: 1, active: planned, inactive: inactive),
              const SizedBox(width: 8),
              Text(
                'planeada  ·  ',
                style: TextStyle(color: ac.textMuted, fontSize: 10),
              ),
              _Pips(level: 1, active: _pink, inactive: inactive),
              const SizedBox(width: 8),
              Text(
                'real (pregunta)',
                style: TextStyle(color: ac.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildJourneyRow(
    AppColors ac,
    GameRound r, {
    required int index,
    required Intensity? real,
    required bool jumped,
    required Color plannedColor,
    required Color inactiveColor,
  }) {
    final delta = real == null ? null : real.level - r.intensity.level;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: jumped ? const Color(0x1AFFB300) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: jumped
            ? Border.all(color: const Color(0xFFFFB300).withValues(alpha: .5))
            : null,
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(color: ac.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.chapter.label,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${r.emotion.emoji} ${r.emotion.label}',
                  style: TextStyle(color: ac.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _Pips(level: r.intensity.level, active: plannedColor, inactive: inactiveColor),
          const SizedBox(width: 10),
          if (real == null)
            Text(
              '—',
              style: TextStyle(color: ac.textMuted, fontSize: 12),
            )
          else
            _Pips(level: real.level, active: _pink, inactive: inactiveColor),
          const SizedBox(width: 12),
          if (delta == null)
            const SizedBox(width: 18)
          else if (delta == 0)
            const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 15)
          else if (jumped)
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFB300),
              size: 16,
            )
          else
            Text(
              delta > 0 ? '▲$delta' : '▼${delta.abs()}',
              style: TextStyle(
                color: delta > 0 ? const Color(0xFF00E676) : const Color(0xFFFFA000),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundTile(AppColors ac, GameRound r, int index) {
    final q = r.question;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(color: ac.textMuted, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.chapter.label} · ${r.emotion.emoji} '
                  '${r.emotion.label}',
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (q != null)
                  Text(
                    q.id,
                    style: TextStyle(
                      color: ac.textMuted,
                      fontSize: 11,
                    ),
                  )
                else
                  const Text(
                    'Sin pregunta compatible (N5)',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            r.skipped ? Icons.skip_next : Icons.check_circle,
            color: r.skipped
                ? ac.textMuted
                : const Color(0xFF00E676),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppColors ac) {
    if (_loading) return const SizedBox.shrink();

    if (_finished) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Salir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.textSecondary,
                side: BorderSide(color: ac.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PinkButton(
              onPressed: _restart,
              icon: Icons.refresh,
              label: 'Nueva partida',
            ),
          ),
        ],
      );
    }

    final hasRound = _currentRound != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasRound ? () => _answer(skipped: true) : null,
            icon: const Icon(Icons.skip_next, size: 20),
            label: const Text('Omitir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _pink,
              side: BorderSide(color: _pink.withValues(alpha: .5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PinkButton(
            onPressed: hasRound ? () => _answer(skipped: false) : null,
            icon: Icons.arrow_forward,
            label: 'Siguiente',
          ),
        ),
      ],
    );
  }
}

/// Indicador de intensidad en 4 puntos (niveles del enum [Intensity]).
class _Pips extends StatelessWidget {
  final int level;
  final Color active;
  final Color inactive;

  const _Pips({
    required this.level,
    required this.active,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < level ? active : inactive,
            ),
          ),
      ],
    );
  }
}

/// Botón relleno con el gradiente rosa del branding de la app.
class _PinkButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _PinkButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.pink, AppColors.pinkGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: .30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white38,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
