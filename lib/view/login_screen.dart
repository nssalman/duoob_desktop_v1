import 'dart:developer';

import 'package:duoob_desktop_app_v1/controller/login_provider.dart';
import 'package:duoob_desktop_app_v1/utils/size_config.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:duoob_desktop_app_v1/view/components/app_version_label.dart';
import 'package:duoob_desktop_app_v1/view/components/auth_webview.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:duoob_desktop_app_v1/view/main_screen1.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Access the provider
    final loginProvider = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack( // Added stack to handle loading overlay
        children: [
          Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _userController,
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Standard Login Button
                  ElevatedButton(
                    onPressed: loginProvider.isLoading 
                      ? null 
                      : () => loginProvider.login(
                          context: context,
                          username: _userController.text,
                          password: _passController.text,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF102849),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: loginProvider.isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),

                  const SizedBox(height: 16),
                  const _DividerWithText(text: 'OR'),
                  const SizedBox(height: 16),

                  // Microsoft Login Button
                  OutlinedButton.icon(
                    onPressed: loginProvider.isLoading 
                      ? null 
                      : () async {
                         final code = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuthWebViewWindows()
                                ),
                              );
                          if (code != null) loginProvider.login(context: context, microsoftCode: code);
                        },
                    icon: const Icon(Icons.window, size: 20),
                    label: const Text('Sign in with Microsoft'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Global Loading Overlay
          if (loginProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: AppVersionLabel(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // const Icon(Icons.security, size: 48, color: Color(0xFF102849)),
         Card(
          color: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
          child: Padding(
           padding: const EdgeInsets.all(8.0),
           child: Image.asset('assets/images/app_logo_no_back.png',width: 70,height: 70,),
         )),
         gapH12,
        const Text(
          'Welcome Back',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        Text(
          'Enter your credentials to continue',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}


class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}