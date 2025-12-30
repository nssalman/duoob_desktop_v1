import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen1 extends StatelessWidget {
  const MainScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar - Stays consistently Navy (#102849) to maintain brand identity
          Container(
            width: 260,
            color: const Color(0xFF102849),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildSidebarHeader(),
                const Spacer(),
                _buildThemeToggle(themeProvider, isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 2. Main Content Area
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Main Content Area",
                        style: TextStyle(fontSize: 24),
                      ),
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

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.bolt, color: Colors.white)),
          const SizedBox(width: 12),
          Text(
            'DESKTOP APP',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.w700, // Uses OpenSans-Bold.ttf
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w600, // Uses OpenSans-SemiBold.ttf
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(ThemeProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white70),
        title: Text(
          isDark ? 'Dark Mode' : 'Light Mode',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Switch(
          value: isDark,
          activeColor: Colors.blueAccent,
          onChanged: (value) => provider.toggleTheme(value),
        ),
      ),
    );
  }
}