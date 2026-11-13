import 'package:duoob_desktop_app_v1/main.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Fullscreen host for non-auth `window.open()` targets (e.g. task details).
/// Attaches via [CreateWindowAction.windowId] so `window.opener` stays intact.
class NewTaskViewScreen extends StatefulWidget {
  const NewTaskViewScreen({super.key, required this.createWindowRequest});
  final CreateWindowAction createWindowRequest;

  @override
  State<NewTaskViewScreen> createState() => _NewTaskViewScreenState();
}

class _NewTaskViewScreenState extends State<NewTaskViewScreen> {
  String _title = 'Task Details';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        title: Text(_title),
      ),
      body: InAppWebView(
        webViewEnvironment: webViewEnvironment,
        windowId: widget.createWindowRequest.windowId,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          supportMultipleWindows: true,
          useOnDownloadStart: true,
        ),
        onTitleChanged: (controller, title) {
          if (title == null || title.trim().isEmpty) return;
          if (!mounted) return;
          setState(() => _title = title);
        },
        onCloseWindow: (controller) async {
          if (!mounted) return;
          final navigator = Navigator.of(context);
          if (navigator.canPop()) navigator.pop();
        },
      ),
    );
  }
}
