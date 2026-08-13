import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/user_services.dart';
import '../services/achievement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../widgets/fade_slide_in.dart';

const Color _pink = Color(0xFFFF2E93);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRegisterPassword = true;
  bool _loginBusy = false;
  bool _registerBusy = false;
  bool _googleBusy = false;

  // Libera los recursos de los controladores de texto.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  // Inicia sesión con email y contraseña, verifica perfil y navega.
  Future<void> _login() async {
    if (_loginBusy) return;
    setState(() => _loginBusy = true);
    try {
      final userCredential = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      // Verificar si el usuario tiene perfil
      final hasProfile = await UserService.userProfileExists(
        userCredential.user!.uid,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Inicio de sesión exitoso")));

      if (!mounted) return;

      if (hasProfile) {
        // Actualizar racha diaria
        AchievementService.checkAndUpdateStreak();
        // Si tiene perfil, ir al home
        context.go('/home');
      } else {
        // Si no tiene perfil, ir a completar perfil
        context.go('/perfilRegister');
      }
    } on FirebaseAuthException catch (e) {
      String message = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        message = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        message = "Contraseña incorrecta";
      }
      if (e.code == 'invalid-email') {
        message = "Correo electrónico no válido";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error inesperado")));
    } finally {
      if (mounted) setState(() => _loginBusy = false);
    }
  }

  // Inicia sesión con Google y navega según el perfil del usuario.
  Future<void> _loginWithGoogle() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential != null) {
        // Verificar si el usuario tiene perfil
        final hasProfile = await UserService.userProfileExists(
          userCredential.user!.uid,
        );

        if (!mounted) return;

        if (hasProfile) {
          // Actualizar racha diaria
          AchievementService.checkAndUpdateStreak();
          // Si tiene perfil, ir al home
          context.go('/home');
        } else {
          // Si no tiene perfil, ir a completar perfil
          context.go('/perfilRegister');
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inicio de sesión con Google cancelado"),
          ),
        );
      }
    } catch (e) {
      final message = e is FirebaseAuthException
          ? e.message ?? "Error al iniciar sesión con Google"
          : e.toString();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar sesión con Google: $message")),
      );
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  // Registra un nuevo usuario con email y contraseña.
  Future<void> _register() async {
    if (_registerBusy) return;
    setState(() => _registerBusy = true);
    try {
      await AuthService.register(
        _registerEmailController.text.trim(),
        _registerPasswordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
      context.go('/perfilRegister');
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrarse';
      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico no válido';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al registrarse')),
      );
    } finally {
      if (mounted) setState(() => _registerBusy = false);
    }
  }

  // Construye la pantalla de login con pestañas de login y registro.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [ac.surface, ac.background]
                : [Color(0xFFFFEEF1), Color(0xFFFFF5F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const FadeSlideIn(
                child: SizedBox(
                  height: 92,
                  width: 92,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_pink, AppColors.purple],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x59FF2E93),
                          blurRadius: 28,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, size: 44, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      top: 12,
                    ),
                    child: Container(
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),

                    width: double.infinity,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: TabBar(
                              indicatorColor: _pink,
                              labelColor: _pink,
                              unselectedLabelColor: ac.textMuted,
                              tabs: const [
                                Tab(text: 'Iniciar sesión'),
                                Tab(text: 'Registrarse'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildLoginForm(),
                                _buildRegisterForm(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  // Construye el formulario de inicio de sesión con email y Google.
  Widget _buildLoginForm() {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15);
    final iconColor = isLight ? ac.textSecondary : Colors.white54;
    final labelColor = isLight ? ac.textMuted : Colors.white.withValues(alpha: 0.4);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            '¡Hola de nuevo!',
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesión para continuar',
            style: TextStyle(color: ac.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: ac.textPrimary),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo',
              labelStyle: TextStyle(color: labelColor),
              filled: true,
              fillColor: isLight ? Colors.grey.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 1.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            style: TextStyle(color: ac.textPrimary),
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: TextStyle(color: labelColor),
              filled: true,
              fillColor: isLight ? Colors.grey.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 1.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: Icon(Icons.lock_outline, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loginBusy ? null : _login,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(_pink),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              child: _loginBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: ac.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o', style: TextStyle(color: ac.textMuted)),
              ),
              Expanded(child: Divider(color: ac.divider)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _googleBusy ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: borderColor),
              ),
              child: _googleBusy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _pink,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/google_icon.png',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continuar con Google',
                          style: TextStyle(fontSize: 17, color: ac.textPrimary),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el formulario de registro de nuevo usuario.
  Widget _buildRegisterForm() {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15);
    final iconColor = isLight ? ac.textSecondary : Colors.white54;
    final labelColor = isLight ? ac.textMuted : Colors.white.withValues(alpha: 0.4);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            'Crea tu cuenta',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Regístrate con tu correo electrónico',
            style: TextStyle(fontSize: 15, color: ac.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: ac.textPrimary),

            controller: _registerEmailController,
            decoration: InputDecoration(
              labelStyle: TextStyle(color: labelColor),
              labelText: 'Email',
              filled: true,
              fillColor: isLight ? Colors.grey.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 1.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            style: TextStyle(color: ac.textPrimary),

            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            decoration: InputDecoration(
              labelStyle: TextStyle(color: labelColor),
              labelText: 'Contraseña',
              filled: true,
              fillColor: isLight ? Colors.grey.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 1.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: Icon(Icons.lock_outline, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () => setState(
                  () => _obscureRegisterPassword = !_obscureRegisterPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registerBusy ? null : _register,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(_pink),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              child: _registerBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
