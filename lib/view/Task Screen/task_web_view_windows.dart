import 'dart:developer';
import 'package:duoob_desktop_app_v1/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';



// Enum to manage which overlay to show
enum TaskResult { none, success, failure }
class TaskWebViewWindows extends StatefulWidget {
  final String? url;
  const TaskWebViewWindows({super.key,  this.url});

  @override
  State<TaskWebViewWindows> createState() => _TaskWebViewWindowsState();
}

class _TaskWebViewWindowsState extends State<TaskWebViewWindows> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _showSuccessAnimation = false;
  String? _activeUrl;

 // Track the current result state
  TaskResult _currentResult = TaskResult.none; 

  // URL Constants
  final String successUrl = 'D365Close.aspx?Action=Success';
  final String successUrl1 = 'Resultpage.aspx';
  final String failureUrl = 'D365Close.aspx?Action=Failure';

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.url;
  }

  @override
  void didUpdateWidget(TaskWebViewWindows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _activeUrl = widget.url;
      _currentResult = TaskResult.none;
    }
  }
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Central logic to handle animations and clearing the view
  void _triggerOverlay(bool isSuccess) async {
    _safeSetState(() {
      _currentResult = isSuccess ? TaskResult.success : TaskResult.failure;
    });

    // Wait for animation to play (e.g., 2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));

    // Reset to empty state
    _safeSetState(() {
      _currentResult = TaskResult.none;
      _activeUrl = null; 
    });
  }

  void _handleTaskCompletion() async {
    // 1. Show the success overlay
    _safeSetState(() {
      _showSuccessAnimation = true;
    });

    // 2. Wait for the animation to finish (adjust duration as needed)
    // Most success animations are 2-3 seconds long
    await Future.delayed(const Duration(milliseconds: 2500));

    // 3. Clear state to show _buildEmptyState()
    _safeSetState(() {
      _showSuccessAnimation = false;
      _activeUrl = null; 
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeUrl == null) {
      return _buildEmptyState();
    }
    return Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            webViewEnvironment: webViewEnvironment,
            initialUrlRequest: URLRequest(url: WebUri(_activeUrl!)),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: "notifyClose",
                callback: (args) => _triggerOverlay(true),
              );
            },
            onLoadStart: (controller, url) => _safeSetState(() => _isLoading = true),
            onLoadStop: (controller, url) async {
              log(url.toString(), name: 'onLoadStop');
              _safeSetState(() => _isLoading = false);

              final currentUrl = url.toString();
              
              // URL-based trigger logic
              if (currentUrl.contains(successUrl) || currentUrl.contains(successUrl1)) {
                _triggerOverlay(true);
              } else if (currentUrl.contains(failureUrl)) {
                _triggerOverlay(false);
              }
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) _safeSetState(() => _isLoading = false);
            },
            onReceivedError: (controller, request, error) {
              if (request.url.toString() == "about:blank") return;
              log("WebView Error: ${error.description}");
            },
          ),
        ),

        // 1. Loading Indicator
        if (_isLoading)
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: CircularProgressIndicator()),
          ),

        // 2. Success Overlay
        if (_currentResult == TaskResult.success)
          _buildOverlay(
            color: Colors.white,
            asset: 'assets/animations/success.json',
          ),

        // 3. Failure Overlay
        if (_currentResult == TaskResult.failure)
          _buildOverlay(
            color: Colors.white,
            asset: 'assets/animations/error.json', // Your error animation path
          ),
      ],
    );
  }

  /// Reusable overlay builder
  Widget _buildOverlay({required Color color, required String asset}) {
    return Positioned.fill(
      child: Container(
        color: color,
        child: Center(
          child: Lottie.asset(
            asset,
            width: 180,
            repeat: false,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Select a task to view details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }
}