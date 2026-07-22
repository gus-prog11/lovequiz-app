import 'package:flutter/material.dart';
import 'package:lovequiz_app/screens/historia_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'premium_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _selectedTab,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFE91E63); // Pink color
    final appBarColor = isDark ? const Color(0xFF17131F) : Colors.white;

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          const HomeScreen(),
          const HistoriaScreen(),
          const PremiumScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(
        isDark,
        primaryColor,
        appBarColor,
      ),
    );
  }

  Widget _buildBottomNavBar(
    bool isDark,
    Color primaryColor,
    Color appBarColor,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        height: kBottomNavigationBarHeight + 18,
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavBarItem(
              Icons.home_outlined,
              Icons.home,
              'Inicio',
              0,
              primaryColor,
            ),
            _buildNavBarItem(
              Icons.favorite_outline,
              Icons.favorite,
              'Historia',
              1,
              primaryColor,
            ),
            _buildNavBarItem(
              Icons.star_outline,
              Icons.star,
              'Premium',
              2,
              primaryColor,
            ),
            _buildNavBarItem(
              Icons.person_outline,
              Icons.person,
              'Perfil',
              3,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    Color primaryColor,
  ) {
    final isSelected = _selectedTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,

                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected ? primaryColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
