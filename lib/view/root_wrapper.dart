import 'package:duoob_desktop_app_v1/model/app_version_check_model.dart';
import 'package:duoob_desktop_app_v1/services/app_version_service.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/components/update_required_screen.dart';
import 'package:duoob_desktop_app_v1/view/login_screen.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:flutter/material.dart';

class RootWrapper extends StatefulWidget {
  RootWrapper({super.key});

  final UserRepository userRepository = UserRepository();

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  AppVersionCheckResult? _versionResult;
  bool _optionalUpdateDialogShown = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      widget.userRepository.isUserLoggedIn(),
      AppVersionService().checkForUpdate(),
    ]);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _isLoggedIn = results[0] as bool;
      _versionResult = results[1] as AppVersionCheckResult;
      _isLoading = false;
    });
  }

  void _showOptionalUpdateDialog() {
    final result = _versionResult;
    if (result == null || _optionalUpdateDialogShown || !result.updateRequired) {
      return;
    }

    _optionalUpdateDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => CustomDialog(
          icon: Icons.system_update_alt,
          title: 'Update Available',
          subtitle: result.displayMessage,
          yesTitle: 'OK',
          noTitle: 'Later',
          yes: () => Navigator.pop(context),
          no: () => Navigator.pop(context),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final versionResult = _versionResult;
    if (versionResult != null &&
        versionResult.updateRequired &&
        versionResult.forceUpdate) {
      return UpdateRequiredScreen(result: versionResult);
    }

    if (versionResult != null &&
        versionResult.updateRequired &&
        !versionResult.forceUpdate) {
      _showOptionalUpdateDialog();
    }

    if (_isLoggedIn) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}
