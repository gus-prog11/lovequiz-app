import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/screens/historia_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_toast.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';

const Color _pink = AppColors.pink;
const Color _purple = Color(0xFFB8439F);

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedTab = 0;

  // Notifica a las pantallas del IndexedStack cuándo su pestaña vuelve a ser
  // la activa, para que refresquen datos (racha, alias) sin reconstruirlas.
  final ValueNotifier<int> _selectedTabNotifier = ValueNotifier(0);

  // Momento de la última pulsación de "atrás" para el cierre con doble toque.
  DateTime? _lastBackPressAt;

  @override
  void dispose() {
    _selectedTabNotifier.dispose();
    super.dispose();
  }

  // Maneja el botón atrás del dispositivo: si no estamos en la pestaña
  // principal, primero regresa a ella; en la principal pide una segunda
  // pulsación dentro de 2 segundos para salir (como las apps profesionales).
  void _onBackPressed() {
    if (_selectedTab != 0) {
      setState(() => _selectedTab = 0);
      _selectedTabNotifier.value = 0;
      return;
    }

    final now = DateTime.now();
    final wasRecent =
        _lastBackPressAt != null &&
        now.difference(_lastBackPressAt!) < const Duration(seconds: 2);

    if (wasRecent) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        SystemNavigator.pop();
      }
      return;
    }

    _lastBackPressAt = now;
    AppToast.showInfo(context, 'Pulsa de nuevo para salir');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor = isDark ? const Color(0xFF1C1624) : Colors.white;

    // IndexedStack mantiene las tres pantallas montadas: al volver a una
    // pestaña no se recarga nada (estado, consultas e imágenes se conservan),
    // igual que en apps como Instagram.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
        children: [
          HomeScreen(
            onGoToHistoria: () {
              setState(() => _selectedTab = 1);
              _selectedTabNotifier.value = 1;
            },
            tabIndex: _selectedTabNotifier,
          ),
          const HistoriaScreen(),
            // Proximamente          const PremiumScreen(),
            const ProfileScreen(),
          ],
        ),
        // Barra flotante tipo "pill": entra con un fundido y deslizamiento y
        // resalta la pestaña activa con una píldora con degradado animada.
        bottomNavigationBar: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: kBottomNavigationBarHeight + 8,
                decoration: BoxDecoration(
                  color: navColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.10,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavBarItem(
                      Icons.home_outlined,
                      Icons.home,
                      'Inicio',
                      0,
                    ),
                    _buildNavBarItem(
                      Icons.favorite_outline,
                      Icons.favorite,
                      'Historia',
                      1,
                    ),
                    // _buildNavBarItem(Icons.star_outline, Icons.star, 'Premium', 2),
                    _buildNavBarItem(
                      Icons.person_outline,
                      Icons.person,
                      'Perfil',
                      2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() => _selectedTab = index);
          _selectedTabNotifier.value = index;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_pink, _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                // El transitionBuilder por defecto copia el key del hijo al
                // FadeTransition (ValueKey<Key?>(child.key)); al alternar rápido
                // entre iconos con key <true>/<false> eso duplica claves en el
                // Stack interno y acumula render objects (flutter#121336).
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                // La pestaña activa "salta": un pop con rebote elástico
                // (easeOutBack) cada vez que se selecciona. El widget se monta
                // fresco al cambiar de estado (TweenAnimationBuilder vs Icon),
                // así el pop se reproduce de 0 -> 1 por selección.
                child: isSelected
                    ? TweenAnimationBuilder<double>(
                        key: const ValueKey('nav-pop'),
                        tween: Tween(begin: 0.6, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          selectedIcon,
                          size: 24,
                          color: Colors.white,
                        ),
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                      )
                    : Icon(
                        icon,
                        key: const ValueKey('nav-idle'),
                        size: 24,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
