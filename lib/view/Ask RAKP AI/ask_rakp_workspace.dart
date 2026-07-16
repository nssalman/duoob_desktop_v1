import 'package:duoob_desktop_app_v1/services/copilot_auth_service.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:duoob_desktop_app_v1/view/Ask%20RAKP%20AI/copilot_screen.dart';
import 'package:duoob_desktop_app_v1/view/components/interactive_loading_view.dart';
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.brandSoft,
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.9)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: c.brand.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: c.onBrand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask RAKP AI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Workplace assistant',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    if (_isAuthenticating) {
      return const InteractiveLoadingView(
        title: 'Connecting to Ask RAKP AI',
        tips: [
          'Authenticating with Copilot…',
          'Preparing your assistant session…',
          'Almost ready to chat…',
        ],
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.finalRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 34,
                  color: AppColors.finalRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not open Ask RAKP AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: _authenticate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  foregroundColor: c.brand,
                  backgroundColor: c.brandSoft,
                ),
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
