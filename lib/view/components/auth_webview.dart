import 'dart:developer';
import 'package:duoob_desktop_app_v1/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AuthWebViewWindows extends StatefulWidget {
  const AuthWebViewWindows({super.key});

  @override
  State<AuthWebViewWindows> createState() => _AuthWebViewWindowsState();
}

class _AuthWebViewWindowsState extends State<AuthWebViewWindows> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _sessionCleared = false;
  String? _errorMessage;

  static const String _redirectBase =
      'https://rpsmart.com/redirecturl_RakpAppmob.aspx';

  /// prompt=login forces Microsoft to show the credential screen every time.
  static const String _authUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
      '?client_id=4ea53c57-1ea0-4fe6-b8e8-317b05a6cb1e'
      '&response_type=code'
      '&redirect_uri=https://rpsmart.com/redirecturl_RakpAppmob.aspx'
      '&response_mode=query'
      '&scope=offline_access%20user.read%20mail.read'
      '&state=12345'
      '&prompt=login';

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _clearMicrosoftSession();
  }

  Future<void> _clearMicrosoftSession() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteCookies(
      url: WebUri('https://login.microsoftonline.com'),
    );
    await cookieManager.deleteCookies(
      url: WebUri('https://login.live.com'),
    );
    _safeSetState(() => _sessionCleared = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionCleared) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign in with Microsoft')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in with Microsoft"),
        actions: [
          // Refresh button in case it gets stuck
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. The WebView - Wrapped in Positioned.fill for Stack stability
          Positioned.fill(
            child: InAppWebView(
              webViewEnvironment: webViewEnvironment,
              initialUrlRequest: URLRequest(url: WebUri(_authUrl)),
              // initialSettings: InAppWebViewSettings(
              //   javaScriptEnabled: true,
              //   useShouldOverrideUrlLoading: true,
              //   isInspectable: true, // Allows right-click > Inspect in debug
              //   transparentBackground: false,
              // ),
              onWebViewCreated: (controller) => _webViewController = controller,
              onLoadStart: (controller, url) {
                log("Load Started: $url");
                _safeSetState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) async {
                log("Load Stopped: $url");
                _safeSetState(() => _isLoading = false);

                if (url != null && url.toString().startsWith(_redirectBase)) {
                  String? code = url.queryParameters['code'];
                  if (code != null) {
                    Navigator.pop(context, code);
                  }
                }
              },
              onReceivedError: (controller, request, error) {
                log("WebView Error: ${error.description}");
                _safeSetState(() {
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              },
            ),
          ),

          // 2. Loading Indicator - Only shows when _isLoading is true
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // 3. Error State - Shows if the URL fails to load
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  Text("Error: $_errorMessage"),
                  ElevatedButton(
                    onPressed: () {
                      _safeSetState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _webViewController?.reload();
                    },
                    child: const Text("Retry"),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}