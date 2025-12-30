import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TaskWebViewWindows extends StatefulWidget {
  final String url;
  const TaskWebViewWindows({super.key, required this.url});

  @override
  State<TaskWebViewWindows> createState() => _TaskWebViewWindowsState();
}

class _TaskWebViewWindowsState extends State<TaskWebViewWindows> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  // @override
  // void dispose() {
  //   // 1. Mark controller null immediately so callbacks stop triggering UI updates
  //   _webViewController.di 
  //   super.dispose();
  // }

  // Helper to safely call setState
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 2. Wrapped in a sized container to prevent "attached" errors during resize/layout
        Positioned.fill(
          child: InAppWebView(
            // Use WebUri directly for the initial load
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            // initialSettings: InAppWebViewSettings(
            //   userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            //   javaScriptEnabled: true,
            //   transparentBackground: true,
            //   // Critical for Windows stability
            //   useShouldOverrideUrlLoading: true, 
            //   isInspectable: true,
            // ),
            onWebViewCreated: (controller) => _webViewController = controller,
            onLoadStart: (controller, url) => _safeSetState(() => _isLoading = true),
            onLoadStop: (controller, url) => _safeSetState(() => _isLoading = false),
            onProgressChanged: (controller, progress) {
              if (progress == 100) _safeSetState(() => _isLoading = false);
            },
            // 3. Silence the "about:blank" error log
            onReceivedError: (controller, request, error) {
              if (request.url.toString() == "about:blank") return;
              log("WebView Error: ${error.description}");
            },
          ),
        ),

        if (_isLoading)
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}