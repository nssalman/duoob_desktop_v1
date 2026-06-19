import 'package:duoob_desktop_app_v1/services/copilot_auth_service.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/view/Ask%20RAKP%20AI/copilot_screen.dart';
import 'package:flutter/material.dart';

class AskRakpWorkspace extends StatefulWidget {
  const AskRakpWorkspace({super.key});

  @override
  State<AskRakpWorkspace> createState() => _AskRakpWorkspaceState();
}

class _AskRakpWorkspaceState extends State<AskRakpWorkspace> {
  final CopilotAuthService _authService = CopilotAuthService();

  String? _appAccessToken;
  String? _errorMessage;
  bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getServiceAccountCopilotToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Could not authenticate with Copilot.';
          _isAuthenticating = false;
        });
        return;
      }

      setState(() {
        _appAccessToken = token;
        _isAuthenticating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        shadowColor: AppColors.blue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: AppColors.blue,
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Ask RAKP AI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isAuthenticating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening Ask RAKP AI...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.finalRed),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _authenticate,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return CopilotChatPage(
      key: ValueKey(_appAccessToken),
      backendBaseUrl: Constants.copilotBackendBaseUrl,
      appAccessToken: _appAccessToken!,
      embedded: true,
    );
  }
}
