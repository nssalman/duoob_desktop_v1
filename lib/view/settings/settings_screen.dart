import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/view/components/app_version_label.dart';
import 'package:duoob_desktop_app_v1/view/components/info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';

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
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _SettingsCard(
                title: 'Account',
                child: _buildAccountRow(context),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Change password',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PasswordField(
                        controller: _oldPasswordController,
                        label: 'Current password',
                        obscure: _obscureOld,
                        onToggle: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: _newPasswordController,
                        label: 'New password',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return FlutterPwValidator(
                            controller: _newPasswordController,
                            minLength: 8,
                            uppercaseCharCount: 1,
                            numericCharCount: 1,
                            specialCharCount: 1,
                            width: constraints.maxWidth,
                            height: 180,
                            onSuccess: () {
                              if (!_isValidPassword) {
                                setState(() => _isValidPassword = true);
                              }
                            },
                            onFail: () {
                              if (_isValidPassword) {
                                setState(() => _isValidPassword = false);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm new password',
                        obscure: _obscureConfirm,
                        onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
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
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isChangingPassword || !_isValidPassword
                              ? null
                              : _submitChangePassword,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.blue.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isChangingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Update password',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
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
      return const LinearProgressIndicator();
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
              SizedBox(
                width: double.infinity,
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (userId != null && userId.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'User ID: $userId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.iconGrey,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
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
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
        ),
      ),
    );
  }
}
