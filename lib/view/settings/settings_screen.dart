import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/view/components/app_version_label.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/root_wrapper.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();
  LoginResponseModel? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.getLoginResponse();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoadingUser = false;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return CustomDialog(
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
        );
      },
    );
  }

  Future<void> _logout() async {
    await _userRepository.clear();
    _userRepository.setUserLoggedIn(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RootWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Card(
                shadowColor: AppColors.blue,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildAccountRow(context),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _buildLogoutTile(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const AppVersionLabel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRow(BuildContext context) {
    if (_isLoadingUser) {
      return const Row(
        children: [
          CircleAvatar(radius: 28, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 16),
          Expanded(child: LinearProgressIndicator()),
        ],
      );
    }

    final displayName = _user?.userName ?? 'Signed in user';
    final userId = _user?.userId;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Constants.primaryColor.withValues(alpha: 0.15),
          child: Icon(
            Icons.person_outline,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (userId != null && userId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'User ID: $userId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.iconGrey,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Material(
      color: AppColors.finalRed.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.finalRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.finalRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log out',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.finalRed,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sign out and return to the login screen',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.iconGrey,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.finalRed.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
