import 'dart:ui';

import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/view/Ask%20RAKP%20AI/ask_rakp_workspace.dart';
import 'package:duoob_desktop_app_v1/view/My%20RAKP/my_rakp_screen.dart';
import 'package:duoob_desktop_app_v1/view/Report%20Screen/report_screen.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_workspace_listing.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/root_wrapper.dart';
import 'package:duoob_desktop_app_v1/view/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _rakLogoPath = 'assets/images/rak-logo-short-wo.png';

  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  LoginResponseModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserRepository().getLoginResponse();
    if (!mounted) return;
    setState(() => _user = user);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomDialog(
        icon: Icons.logout_rounded,
        destructive: true,
        title: 'Log Out',
        subtitle: 'Are you sure you want to sign out of Duoob?',
        yesTitle: 'Log Out',
        noTitle: 'Cancel',
        yes: () {
          Navigator.pop(context);
          _logout();
        },
        no: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _logout() async {
    final userRepository = UserRepository();
    await userRepository.clear();
    userRepository.setUserLoggedIn(false);
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteCookies(
      url: WebUri('https://login.microsoftonline.com'),
    );
    await cookieManager.deleteCookies(
      url: WebUri('https://login.live.com'),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RootWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AppSidebar(
            selectedIndex: _selectedIndex,
            isCollapsed: _isSidebarCollapsed,
            userName: _user?.userName,
            rakLogoPath: _rakLogoPath,
            onToggleCollapse: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            onLogout: _showLogoutDialog,
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_selectedIndex != 2)
                  Offstage(
                    offstage: _selectedIndex != 0,
                    child: const MyRakpWorkspace(
                      key: ValueKey('my-rakp-workspace'),
                    ),
                  ),
                Offstage(
                  offstage: _selectedIndex != 1,
                  child: TaskWorkspace(
                    suspendWebView: _selectedIndex != 1,
                  ),
                ),
                if (_selectedIndex == 2)
                  const ReportWorkspace(key: ValueKey('report-workspace')),
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

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onDestinationSelected,
    required this.onToggleCollapse,
    required this.onLogout,
    required this.rakLogoPath,
    this.userName,
  });

  final int selectedIndex;
  final bool isCollapsed;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;
  final String rakLogoPath;
  final String? userName;

  static const _expandedWidth = 236.0;
  static const _collapsedWidth = 72.0;
  static const _labelRevealWidth = 140.0;

  static const _destinations = [
    _SidebarItem(
      label: 'My RAKP',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      isRakp: true,
    ),
    _SidebarItem(
      label: 'Tasks',
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
    ),
    _SidebarItem(
      label: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    _SidebarItem(
      label: 'Ask RAKP AI',
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy_rounded,
    ),
    _SidebarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFrom(userName);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isCollapsed ? _collapsedWidth : _expandedWidth,
      decoration: const BoxDecoration(
        color: AppColors.blue,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Drive label visibility from actual width so content
              // never overflows mid-animation.
              final showLabels = constraints.maxWidth >= _labelRevealWidth;

              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SidebarBrandHeader(
                      displayName: userName ?? 'Duoob User',
                      initials: initials,
                      showLabels: showLabels,
                      isCollapsed: isCollapsed,
                      onToggleCollapse: onToggleCollapse,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = _destinations[index];
                          return _SidebarNavTile(
                            label: item.label,
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            isSelected: selectedIndex == index,
                            showLabels: showLabels,
                            rakLogoPath: item.isRakp ? rakLogoPath : null,
                            onTap: () => onDestinationSelected(index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.14),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    _SidebarLogoutButton(
                      onTap: onLogout,
                      showLabels: showLabels,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _initialsFrom(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name
        .trim()
        .split(RegExp(r'[\s.@]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.isRakp = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isRakp;
}

class _SidebarBrandHeader extends StatelessWidget {
  const _SidebarBrandHeader({
    required this.displayName,
    required this.initials,
    required this.showLabels,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  final String displayName;
  final String initials;
  final bool showLabels;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/app_logo_no_back.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    final toggle = Tooltip(
      message: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(
              isCollapsed
                  ? Icons.keyboard_double_arrow_right_rounded
                  : Icons.keyboard_double_arrow_left_rounded,
              color: Colors.white.withValues(alpha: 0.92),
              size: 18,
            ),
          ),
        ),
      ),
    );

    if (!showLabels) {
      return Column(
        children: [
          Tooltip(message: displayName, child: logo),
          const SizedBox(height: 10),
          toggle,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duoob',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          toggle,
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.showLabels,
    required this.onTap,
    this.rakLogoPath,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool showLabels;
  final VoidCallback onTap;
  final String? rakLogoPath;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isSelected ? Colors.white : Colors.white.withValues(alpha: 0.82);

    final iconWidget = SizedBox(
      width: 22,
      height: 22,
      child: rakLogoPath != null
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
              child: Image.asset(
                rakLogoPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  isSelected ? selectedIcon : icon,
                  color: foreground,
                  size: 20,
                ),
              ),
            )
          : Icon(
              isSelected ? selectedIcon : icon,
              color: foreground,
              size: 20,
            ),
    );

    final content = showLabels
        ? Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          )
        : Center(child: iconWidget);

    Widget tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 0),
            child: content,
          ),
        ),
      ),
    );

    if (isSelected) {
      tile = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: tile,
          ),
        ),
      );
    }

    if (!showLabels) {
      return Tooltip(message: label, child: tile);
    }
    return tile;
  }
}

class _SidebarLogoutButton extends StatelessWidget {
  const _SidebarLogoutButton({
    required this.onTap,
    required this.showLabels,
  });

  final VoidCallback onTap;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: showLabels
              ? Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Log out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
        ),
      ),
    );

    if (!showLabels) {
      return Tooltip(message: 'Log out', child: child);
    }
    return child;
  }
}
