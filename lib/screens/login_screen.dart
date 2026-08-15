import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/fade_slide_in.dart';

// Extremo del degradado del hero de login. El branding es rosa; para que el
// fondo de marca no se vea plano se hunde hacia un púrpura profundo.
const Color _heroGradientEnd = Color(0xFF6A1B9A);

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

  // Muestra un snackbar flotante y moderno (evita acumular notificaciones).
  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.pink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
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

      if (!mounted) return;

      if (hasProfile) {
        // Si tiene perfil, ir al home
        context.go('/home');
      } else {
        // Si no tiene perfil, ir a completar perfil
        context.go('/perfilRegister');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        message = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        message = "Contraseña incorrecta";
      }
      if (e.code == 'invalid-email') {
        message = "Correo electrónico no válido";
      }
      _showSnack(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error inesperado", isError: true);
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
      if (!mounted) return;

      if (userCredential != null) {
        // Verificar si el usuario tiene perfil
        final hasProfile = await UserService.userProfileExists(
          userCredential.user!.uid,
        );

        if (!mounted) return;

        if (hasProfile) {
          // Si tiene perfil, ir al home
          context.go('/home');
        } else {
          // Si no tiene perfil, ir a completar perfil
          context.go('/perfilRegister');
        }
      } else {
        _showSnack("Inicio de sesión con Google cancelado");
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is FirebaseAuthException
          ? e.message ?? "Error al iniciar sesión con Google"
          : e.toString();
      _showSnack("Error al iniciar sesión con Google: $message",
          isError: true);
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
      context.go('/perfilRegister');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Error al registrarse';
      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico no válido';
      }
      _showSnack(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error inesperado al registrarse', isError: true);
    } finally {
      if (mounted) setState(() => _registerBusy = false);
    }
  }

  // Construye la pantalla de login: hero de marca arriba y tarjeta tipo hoja
  // inferior con las pestañas de login y registro.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.pink, _heroGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero con la marca.
              Expanded(
                flex: 2,
                child: Center(
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 40,
                            color: AppColors.pink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LoveQuiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Juega con quien amas',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tarjeta tipo hoja con el formulario.
              Expanded(
                flex: 3,
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  offset: const Offset(0, 40),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const SizedBox(height: 18),
                          // Selector segmentado en píldora.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? Colors.black.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [AppColors.pink, AppColors.purple],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pink.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: ac.textMuted,
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                tabs: const [
                                  Tab(text: 'Iniciar sesión'),
                                  Tab(text: 'Registrarse'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            '¡Hola de nuevo!',
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inicia sesión para continuar',
            style: TextStyle(color: ac.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _emailController,
            label: 'Correo',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _passwordController,
            label: 'Contraseña',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loginBusy ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pink,
                disabledBackgroundColor: AppColors.pink.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: AppColors.pink.withValues(alpha: 0.4),
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
                      style: TextStyle(fontSize: 17, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _googleBusy ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
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
                        color: AppColors.pink,
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
                          style: TextStyle(
                            fontSize: 16,
                            color: ac.textPrimary,
                          ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            'Crea tu cuenta',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Regístrate con tu correo electrónico',
            style: TextStyle(fontSize: 14, color: ac.textSecondary),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _registerEmailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _registerPasswordController,
            label: 'Contraseña',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureRegisterPassword,
            onToggleObscure: () => setState(
              () => _obscureRegisterPassword = !_obscureRegisterPassword,
            ),
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _registerBusy ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pink,
                disabledBackgroundColor: AppColors.pink.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: AppColors.pink.withValues(alpha: 0.4),
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
                      style: TextStyle(fontSize: 17, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
