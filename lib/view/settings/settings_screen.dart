import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:duoob_desktop_app_v1/view/components/app_version_label.dart';
import 'package:duoob_desktop_app_v1/view/components/info_dialog.dart';
import 'package:duoob_desktop_app_v1/view/components/modern_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  LoginResponseModel? _user;
  bool _isLoadingUser = true;
  bool _isChangingPassword = false;
  bool _isValidPassword = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged() {
    final valid = _PasswordRules.isValid(_newPasswordController.text);
    setState(() => _isValidPassword = valid);
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.getLoginResponse();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoadingUser = false;
    });
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isValidPassword) {
      _showResultDialog(
        title: 'Weak password',
        message: 'Please meet all password requirements before updating.',
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showResultDialog(
        title: 'Passwords don’t match',
        message:
            'Please make sure the new password and confirmation are the same.',
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    FocusScope.of(context).unfocus();

    try {
      final success = await _userRepository.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (success) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _isValidPassword = false);
        _showResultDialog(
          title: 'Password updated',
          message: 'Your password was changed successfully.',
          isError: false,
        );
      } else {
        _showResultDialog(
          title: 'Couldn’t update password',
          message: 'Please check your current password and try again.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Something went wrong',
        message: 'Please try again in a moment.',
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    bool isError = true,
  }) {
    showDialog(
      context: context,
      builder: (_) => InfoDialog(
        message: title,
        subtext: message,
        icon: isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
        accentColor: isError ? AppColors.finalRed : AppColors.green,
        ok: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSideBySide = constraints.maxWidth >= 720;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPageHeader(context),
                    const SizedBox(height: 14),
                    if (useSideBySide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildAccountPanel(context),
                                const SizedBox(height: 14),
                                _buildAppearancePanel(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: _buildSecurityPanel(context),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAccountPanel(context),
                          const SizedBox(height: 14),
                          _buildAppearancePanel(context),
                          const SizedBox(height: 14),
                          _buildSecurityPanel(context),
                        ],
                      ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: AppVersionLabel(alignment: Alignment.centerRight),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final c = context.colors;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.brandSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.settings_rounded, color: c.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              Text(
                'Account details and security',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearancePanel(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return _SettingsPanel(
          title: 'Appearance',
          child: Row(
            children: [
              Expanded(
                child: _ThemeOptionCard(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: !themeProvider.isDarkMode,
                  onTap: () =>
                      themeProvider.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeOptionCard(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: themeProvider.isDarkMode,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountPanel(BuildContext context) {
    return _SettingsPanel(
      title: 'Profile',
      child: _buildAccountContent(context),
    );
  }

  Widget _buildSecurityPanel(BuildContext context) {
    final c = context.colors;

    return _SettingsPanel(
      title: 'Security',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              controller: _oldPasswordController,
              label: 'Current password',
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 10),
            _PasswordField(
              controller: _newPasswordController,
              label: 'New password',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 8),
            _PasswordRules(password: _newPasswordController.text),
            const SizedBox(height: 10),
            _PasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm new password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords don’t match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isChangingPassword || !_isValidPassword
                    ? null
                    : _submitChangePassword,
                style: FilledButton.styleFrom(
                  backgroundColor: c.brand,
                  foregroundColor: c.onBrand,
                  disabledBackgroundColor: c.brand.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isChangingPassword
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: ModernLoadingIndicator(
                          color: c.onBrand,
                          compact: true,
                          dotSize: 5,
                          spacing: 3,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isChangingPassword ? 'Updating…' : 'Update password',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountContent(BuildContext context) {
    final c = context.colors;

    if (_isLoadingUser) {
      return Shimmer.fromColors(
        baseColor: c.shimmerBase,
        highlightColor: c.shimmerHighlight,
        child: Column(
          children: [
            CircleAvatar(radius: 36, backgroundColor: c.cardFill),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: 140,
              decoration: BoxDecoration(
                color: c.cardFill,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    final displayName = _user?.userName ?? 'Signed in user';
    final userId = _user?.userId;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.brand, c.brand.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.brand.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: c.onBrand,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _MetaRow(
          icon: Icons.verified_user_outlined,
          label: 'Status',
          value: 'Active session',
        ),
        // if (userId != null && userId.isNotEmpty) ...[
        //   const SizedBox(height: 10),
        //   _MetaRow(
        //     icon: Icons.badge_outlined,
        //     label: 'User ID',
        //     value: userId,
        //   ),
        // ],
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.border,
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.brand,
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? c.brandSoft
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.brand : c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? c.brand : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.brand : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: c.brand),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  static bool isValid(String password) {
    return _hasMinLength(password) &&
        _hasUppercase(password) &&
        _hasNumber(password) &&
        _hasSpecial(password);
  }

  static bool _hasMinLength(String s) => s.length >= 8;
  static bool _hasUppercase(String s) => s.contains(RegExp(r'[A-Z]'));
  static bool _hasNumber(String s) => s.contains(RegExp(r'[0-9]'));
  static bool _hasSpecial(String s) =>
      s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rules = [
      ('8+ characters', _hasMinLength(password)),
      ('Uppercase', _hasUppercase(password)),
      ('Number', _hasNumber(password)),
      ('Special char', _hasSpecial(password)),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: rules.map((rule) {
        final (label, met) = rule;
        return _RuleChip(
          label: label,
          met: met,
          surfaceColor: scheme.surfaceContainerHighest,
        );
      }).toList(),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.met,
    required this.surfaceColor,
  });

  final String label;
  final bool met;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = met ? AppColors.green : Colors.grey.shade500;
    final bg = met
        ? AppColors.green.withValues(alpha: 0.1)
        : surfaceColor.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met
              ? AppColors.green.withValues(alpha: 0.3)
              : c.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.green : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.brand, width: 1.4),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
          ),
        ),
      ),
    );
  }
}
