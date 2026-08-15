import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/models/premium_model.dart';
import 'package:LoveQuiz/services/achievement_service.dart';
import 'package:LoveQuiz/services/premium_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla de ajustes con estilo profesional y todas las opciones funcionales.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _isPremium = false;
  String? _currentTheme;
  ThemeMode _themeMode = ThemeMode.system;
  int _timerSeconds = 30;
  int? _selectedTimer;
  bool _loading = true;

  // Carga todas las preferencias guardadas.
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await Future.wait([
      PremiumService.getPremiumStatus(),
      PremiumService.getTheme(),
      PremiumService.getSoundEnabled(),
      PremiumService.getVibrationEnabled(),
      PremiumService.getNotificationsEnabled(),
      PremiumService.getTimerSeconds(),
    ]);

    if (!mounted) return;

    final savedThemeMode = await PremiumService.getSavedThemeMode();

    setState(() {
      _isPremium = (prefs[0] as dynamic).isPremium;
      _currentTheme = prefs[1] as String?;
      _soundEnabled = prefs[2] as bool;
      _vibrationEnabled = prefs[3] as bool;
      _notificationsEnabled = prefs[4] as bool;
      _timerSeconds = prefs[5] as int;
      _themeMode = savedThemeMode;
      _loading = false;
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSection(context, 'Apariencia', [
                      _buildThemeModeSelector(context),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Temas Visuales', [
                      ...AppTheme.availableThemes.map((theme) {
                        final isSelected = _currentTheme == theme.id;
                        final isLocked = theme.isPremium && !_isPremium;
                        return Column(
                          children: [
                            if (theme != AppTheme.availableThemes.first)
                              _buildDivider(context),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.pink.withValues(alpha: 0.12)
                                      : ac.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected ? AppColors.pink : ac.textMuted,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                theme.name,
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                theme.description,
                                style: TextStyle(
                                  color: ac.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isLocked
                                  ? Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: ac.textMuted,
                                    )
                                  : isSelected
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pink.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Activo',
                                        style: TextStyle(
                                          color: AppColors.pink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: isLocked
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Disponible en premium',
                                          ),
                                        ),
                                      );
                                    }
                                  : () async {
                                      await PremiumService.setTheme(theme.id);
                                      if (mounted)
                                        setState(
                                          () => _currentTheme = theme.id,
                                        );
                                    },
                            ),
                          ],
                        );
                      }),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Sonido y Notificaciones', [
                      _buildToggle(
                        context,
                        Icons.volume_up_rounded,
                        'Sonido',
                        'Efectos de sonido en el juego',
                        _soundEnabled,
                        (v) {
                          setState(() => _soundEnabled = v);
                          PremiumService.setSoundEnabled(v);
                        },
                      ),
                      _buildDivider(context),
                      _buildToggle(
                        context,
                        Icons.vibration,
                        'Vibración',
                        'Respuesta háptica al responder',
                        _vibrationEnabled,
                        (v) {
                          setState(() => _vibrationEnabled = v);
                          PremiumService.setVibrationEnabled(v);
                        },
                      ),
                      _buildDivider(context),
                      _buildToggle(
                        context,
                        Icons.notifications_active_rounded,
                        'Notificaciones',
                        'Alertas de nuevos desafíos',
                        _notificationsEnabled,
                        (v) {
                          setState(() => _notificationsEnabled = v);
                          PremiumService.setNotificationsEnabled(v);
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Juego', [
                      _buildSelectable(
                        context,
                        Icons.timer_rounded,
                        'Tiempo por pregunta',
                        '$_timerSeconds segundos',
                        () {
                          _showTimerDialog(context);
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Información', [
                      _buildListTile(
                        context,
                        Icons.multitrack_audio_rounded,
                        '[DEV] Prueba de voz',
                        null,
                        () => context.push('/voice-demo'),
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.science_rounded,
                        '[DEV] Motor de prueba',
                        'Partida con el nuevo motor',
                        () => context.push('/engine-test'),
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.favorite_rounded,
                        'Recuerdos de voz',
                        null,
                        () => context.push('/voice-memories'),
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.info_rounded,
                        'Sobre LoveQuiz',
                        'Versión 1.0.0',
                        () {
                          _showAboutDialog(context);
                        },
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.bug_report_rounded,
                        'Reportar un problema',
                        null,
                        () {
                          _showReportDialog(context);
                        },
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.description_rounded,
                        'Términos y condiciones',
                        null,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abrir términos y condiciones...'),
                            ),
                          );
                        },
                      ),
                      _buildDivider(context),
                      _buildListTile(
                        context,
                        Icons.privacy_tip_rounded,
                        'Política de privacidad',
                        null,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abrir política de privacidad...'),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Cerrar Sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── SECCIONES Y COMPONENTES ──────────────────────────────────────────

  // Sección con fondo y bordes redondeados (estilo Instagram).
  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final ac = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.pink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ac.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // Toggle switch con icono.
  Widget _buildToggle(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final ac = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.pink, size: 20),
      ),
      title: Text(title, style: TextStyle(color: ac.textPrimary, fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: ac.textMuted, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.pink,
        activeTrackColor: AppColors.pink.withValues(alpha: 0.4),
      ),
    );
  }

  // ListTile simple con navegación (chevron).
  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
  ) {
    final ac = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.pink, size: 20),
      ),
      title: Text(title, style: TextStyle(color: ac.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: ac.textMuted, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: ac.textMuted, size: 22),
      onTap: onTap,
    );
  }

  // Item tipo opción seleccionable (como tiempo de juego).
  Widget _buildSelectable(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final ac = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.pink, size: 20),
      ),
      title: Text(title, style: TextStyle(color: ac.textPrimary, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: ac.textMuted, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: ac.textMuted, size: 22),
        ],
      ),
      onTap: onTap,
    );
  }

  // Selector de modo de tema (Sistema / Claro / Oscuro).
  Widget _buildThemeModeSelector(BuildContext context) {
    final ac = AppColors.of(context);
    final modes = [
      (ThemeMode.system, 'Del sistema', Icons.settings_suggest_outlined),
      (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppColors.pink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Modo de tema',
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: modes.map((mode) {
              final isSelected = _themeMode == mode.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await PremiumService.setThemeMode(mode.$1);
                    if (mounted) setState(() => _themeMode = mode.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pink : ac.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode.$3,
                          color: isSelected ? Colors.white : ac.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : ac.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Línea separadora.
  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.of(context).divider,
      indent: 60,
    );
  }

  // ─── DIÁLOGOS ──────────────────────────────────────────────────────────

  // Diálogo para seleccionar tiempo por pregunta.
  void _showTimerDialog(BuildContext context) {
    _selectedTimer = _timerSeconds;
    final options = [15, 30, 45, 60, 90, 120];

    showDialog(
      context: context,
      builder: (ctx) {
        final ac = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: ac.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tiempo por pregunta',
            style: TextStyle(color: ac.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((seconds) {
              return RadioListTile<int>(
                title: Text(
                  '$seconds segundos',
                  style: TextStyle(color: ac.textPrimary),
                ),
                activeColor: AppColors.pink,
                value: seconds,
                groupValue: _selectedTimer,
                onChanged: (v) => setState(() => _selectedTimer = v),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
            ),
            TextButton(
              onPressed: () {
                if (_selectedTimer != null) {
                  PremiumService.setTimerSeconds(_selectedTimer!);
                  setState(() => _timerSeconds = _selectedTimer!);
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de cerrar sesión.
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ac = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: ac.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(color: ac.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(color: ac.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
            ),
            TextButton(
              onPressed: () {
                // Limpiar la caché para que el siguiente usuario no vea los
                // datos del anterior.
                AchievementService.invalidateCache();
                FirebaseAuth.instance.signOut();
                Navigator.pop(ctx);
                context.go('/login');
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Diálogo "Sobre LoveQuiz".
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ac = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: ac.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sobre LoveQuiz',
            style: TextStyle(color: ac.textPrimary, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LoveQuiz v1.0.0',
                style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'La aplicación de preguntas para parejas que te ayuda a conocer mejor a tu pareja y divertirte juntos.',
                style: TextStyle(
                  color: ac.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cerrar', style: TextStyle(color: ac.textMuted)),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para reportar un problema.
  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final ac = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: ac.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Reportar problema',
            style: TextStyle(color: ac.textPrimary, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: ac.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe el problema...',
              hintStyle: TextStyle(color: ac.textMuted, fontSize: 14),
              filled: true,
              fillColor: ac.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reporte enviado. Gracias.')),
                );
              },
              child: const Text(
                'Enviar',
                style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
