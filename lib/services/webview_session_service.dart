import 'dart:developer';

import 'package:duoob_desktop_app_v1/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Clears persisted WebView cookies/cache so a different user does not reuse
/// the previous browser session (My RAKP, Tasks, Reports, MS login).
class WebViewSessionService {
  WebViewSessionService._();

  static const List<String> _sessionOrigins = [
    'https://login.microsoftonline.com',
    'https://login.live.com',
    'https://login.microsoft.com',
    'https://account.microsoft.com',
    'https://rpsmart.com',
    'https://www.rpsmart.com',
    'https://rakp.rpsmart.com',
    'https://api.rpsmart.com',
    'https://apiv2.rpsmart.com',
    'https://rakp-prod.operations.uae.dynamics.com',
  ];

  static CookieManager get _cookieManager {
    // Windows webviews use a custom WebView2 environment / user-data folder.
    // CookieManager.instance() without it clears the wrong profile.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows &&
        webViewEnvironment != null) {
      return CookieManager.instance(webViewEnvironment: webViewEnvironment);
    }
    return CookieManager.instance();
  }

  static Future<void> clearAll() async {
    final cookies = _cookieManager;

    try {
      await cookies.deleteAllCookies();
    } catch (e) {
      log('deleteAllCookies failed: $e', name: 'WebViewSession');
    }

    try {
      await cookies.removeSessionCookies();
    } catch (e) {
      log('removeSessionCookies failed: $e', name: 'WebViewSession');
    }

    for (final origin in _sessionOrigins) {
      try {
        await cookies.deleteCookies(url: WebUri(origin));
      } catch (e) {
        log('deleteCookies($origin) failed: $e', name: 'WebViewSession');
      }
    }

    try {
      await InAppWebViewController.clearAllCache(includeDiskFiles: true);
    } catch (e) {
      log('clearAllCache failed: $e', name: 'WebViewSession');
    }

    try {
      await HttpAuthCredentialDatabase.instance().clearAllAuthCredentials();
    } catch (e) {
      log('clearAllAuthCredentials failed: $e', name: 'WebViewSession');
    }

    // Site storage (localStorage / IndexedDB) when the platform supports it.
    try {
      await WebStorageManager.instance().deleteAllData();
    } catch (e) {
      log('deleteAllData failed: $e', name: 'WebViewSession');
    }

    log('WebView session cleared', name: 'WebViewSession');
  }
}
