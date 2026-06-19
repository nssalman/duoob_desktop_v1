import 'package:duoob_desktop_app_v1/view/Ask%20RAKP%20AI/ask_rakp_workspace.dart';
import 'package:duoob_desktop_app_v1/view/My%20RAKP/my_rakp_screen.dart';
import 'package:duoob_desktop_app_v1/view/Report%20Screen/report_screen.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_workspace_listing.dart';
import 'package:duoob_desktop_app_v1/view/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _rakLogoPath = 'assets/images/rak-logo-short-wo.png';

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Theme.of(context).primaryColor,
            indicatorColor: Colors.white,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.black),
            unselectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Tasks'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: _RakpNavIcon(assetPath: _rakLogoPath, isSelected: false),
                selectedIcon:
                    _RakpNavIcon(assetPath: _rakLogoPath, isSelected: true),
                label: const Text('My RAKP'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: Text('Ask RAKP AI'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: _selectedIndex != 0,
                  child: TaskWorkspace(
                    suspendWebView: _selectedIndex != 0,
                  ),
                ),
                // Mount only the active full-screen web tab. Keeping multiple
                // InAppWebViews alive on macOS causes the native layer to stick.
                if (_selectedIndex == 1)
                  const ReportWorkspace(key: ValueKey('report-workspace')),
                if (_selectedIndex == 2)
                  const MyRakpWorkspace(key: ValueKey('my-rakp-workspace')),
                Offstage(
                  offstage: _selectedIndex != 3,
                  child: const AskRakpWorkspace(),
                ),
                Offstage(
                  offstage: _selectedIndex != 4,
                  child: const SettingsScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RakpNavIcon extends StatelessWidget {
  const _RakpNavIcon({
    required this.assetPath,
    required this.isSelected,
  });

  final String assetPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.black : Colors.white;

    return SizedBox(
      width: 24,
      height: 24,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.business_outlined,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}
