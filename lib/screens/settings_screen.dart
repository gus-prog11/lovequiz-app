import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovequiz_app/models/premium_model.dart';
import 'package:lovequiz_app/services/premium_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkMode = false;
  bool _isPremium = false;
  String? _currentTheme;

  /// Construye la interfaz principal de la pantalla de ajustes
  /// Contiene un AppBar, un fondo con degradado y las secciones de configuración
  @override
  void initState() {
    super.initState();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    final premium = await PremiumService.getPremiumStatus();
    final theme = await PremiumService.getTheme();
    if (mounted) setState(() {
      _isPremium = premium.isPremium;
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Sonido y Vibraciones
                _buildSectionTitle('Sonido y Vibraciones'),
                _buildSettingsCard(
                  children: [
                    _buildToggleSetting(
                      icon: Icons.volume_up_rounded,
                      title: 'Sonido',
                      subtitle: 'Activa el sonido en las preguntas',
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildToggleSetting(
                      icon: Icons.vibration,
                      title: 'Vibración',
                      subtitle: 'Háptica al responder preguntas',
                      value: _vibrationEnabled,
                      onChanged: (value) {
                        setState(() => _vibrationEnabled = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Notificaciones
                _buildSectionTitle('Notificaciones'),
                _buildSettingsCard(
                  children: [
                    _buildToggleSetting(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notificaciones',
                      subtitle: 'Recibe alertas de nuevos desafíos',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Apariencia
                _buildSectionTitle('Apariencia'),
                _buildSettingsCard(
                  children: [
                    _buildToggleSetting(
                      icon: Icons.dark_mode_rounded,
                      title: 'Modo Oscuro',
                      subtitle: 'Activa el tema oscuro (próximamente)',
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                      },
                      enabled: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Temas
                _buildSectionTitle('Temas Visuales'),
                _buildSettingsCard(
                  children: [
                    ...AppTheme.availableThemes.map((theme) {
                      final isSelected = _currentTheme == theme.id;
                      final isLocked = theme.isPremium && !_isPremium;
                      return Column(
                        children: [
                          if (theme != AppTheme.availableThemes.first)
                            const Divider(height: 1, indent: 60),
                          ListTile(
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isLocked ? Colors.grey : null),
                            ),
                            title: Text(theme.name),
                            subtitle: Text(theme.description,
                                style: const TextStyle(fontSize: 12)),
                            trailing: isLocked
                                ? const Icon(Icons.lock, size: 18, color: Colors.grey)
                                : null,
                            onTap: isLocked
                                ? null
                                : () async {
                                    await PremiumService.setTheme(theme.id);
                                    if (mounted) setState(() => _currentTheme = theme.id);
                                  },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Juego
                _buildSectionTitle('Configuración de Juego'),
                _buildSettingsCard(
                  children: [
                    _buildListTileSetting(
                      icon: Icons.timer_rounded,
                      title: 'Tiempo por Pregunta',
                      subtitle: '30 segundos',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showTimerDialog(context);
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildListTileSetting(
                      icon: Icons.category_rounded,
                      title: 'Categorías Favoritas',
                      subtitle: 'Personaliza tus categorías',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función próximamente disponible'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Privacidad y Seguridad
                _buildSectionTitle('Privacidad y Seguridad'),
                _buildSettingsCard(
                  children: [
                    _buildListTileSetting(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Política de Privacidad',
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo política de privacidad...'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildListTileSetting(
                      icon: Icons.description_rounded,
                      title: 'Términos y Condiciones',
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo términos y condiciones...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Información
                _buildSectionTitle('Información'),
                _buildSettingsCard(
                  children: [
                    _buildListTileSetting(
                      icon: Icons.info_rounded,
                      title: 'Sobre LoveQuiz',
                      subtitle: 'Versión 1.0.0',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildListTileSetting(
                      icon: Icons.bug_report_rounded,
                      title: 'Reportar un Problema',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo formulario de reporte...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón de Cerrar Sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el título de cada sección (ej: "Sonido y Vibraciones", "Notificaciones")
  /// Recibe el texto del título y lo formatea con el estilo principal de la app
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Crea una tarjeta redondeada que contiene múltiples opciones de configuración
  /// Las opciones se muestran en una columna dentro de la tarjeta
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  /// Construye una opción de configuración con un switch (interruptor) activable/desactivable
  /// Muestra un icono, título, descripción y un switch que cambia el estado de la opción
  /// El parámetro 'enabled' permite desactivar la opción si se desea
  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Construye una opción de configuración con navegación (sin switch)
  /// Se usa para opciones que abren diálogos o tienen acciones específicas
  /// Muestra un icono, título, descripción opcional y un ícono de navegación
  Widget _buildListTileSetting({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Muestra un diálogo modal para que el usuario configure el tiempo de respuesta
  /// Permite al usuario seleccionar cuántos segundos tiene para responder cada pregunta
  void _showTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiempo por Pregunta'),
        content: const Text(
          'Selecciona el tiempo para responder cada pregunta',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación para cerrar sesión
  /// Al confirmar, cierra sesión en Firebase y redirige a la pantalla de login
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            // Cierra sesión en Firebase y navega a la pantalla de login
            onPressed: () {
              FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo informativo con detalles sobre la aplicación
  /// Incluye la versión de la app y una breve descripción de qué es LoveQuiz
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre LoveQuiz'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LoveQuiz v1.0.0'),
            SizedBox(height: 12),
            Text(
              'La aplicación de preguntas para parejas que te ayuda a conocer mejor a tu pareja y divertirte juntos.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
