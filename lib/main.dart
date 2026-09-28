import 'dart:io';

import 'package:duoob_desktop_app_v1/controller/login_provider.dart';
import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:duoob_desktop_app_v1/services/theme.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/root_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;

WebViewEnvironment? webViewEnvironment;

/// True while the Windows app window is minimized.
///
/// WebView2 leaves its compositor surface hit-testable over the desktop
/// unless the native view is destroyed, so each [TaskWebViewWindows] unmounts
/// while this is true and remounts when it goes false.
///
/// This is updated from [WindowManager.isMinimized], not from
/// [WindowListener.onWindowRestore]. Restoring a maximized window emits
/// [WindowListener.onWindowMaximize] and never `onWindowRestore`.
final ValueNotifier<bool> appWindowMinimized = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    // 1. Get the local app data directory (safe for writing)
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String webViewDataPath = p.join(appSupportDir.path, 'webview_data');

    // 2. Create the environment with the custom path
    webViewEnvironment = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(userDataFolder: webViewDataPath),
    );
  }

  const windowOptions = WindowOptions(
    minimumSize: Size(1024, 700),
    center: true,
    title: 'Duoob',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isCloseDialogOpen = false;
  int _minimizeSyncGeneration = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncWindowMinimized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    _confirmAppClose();
  }

  @override
  void onWindowMinimize() => _syncWindowMinimized();

  @override
  void onWindowRestore() => _syncWindowMinimized();

  @override
  void onWindowMaximize() => _syncWindowMinimized();

  @override
  void onWindowUnmaximize() => _syncWindowMinimized();

  @override
  void onWindowFocus() => _syncWindowMinimized();

  /// Last query wins. Minimize/restore/maximize can overlap, and an older
  /// [WindowManager.isMinimized] result must not overwrite a newer one.
  Future<void> _syncWindowMinimized() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    final generation = ++_minimizeSyncGeneration;
    final minimized = await windowManager.isMinimized();
    if (!mounted || generation != _minimizeSyncGeneration) return;
    if (appWindowMinimized.value == minimized) return;
    appWindowMinimized.value = minimized;
  }

  Future<void> _confirmAppClose() async {
    if (_isCloseDialogOpen) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      await windowManager.destroy();
      return;
    }

    _isCloseDialogOpen = true;
    final shouldClose = await showDialog<bool>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomDialog(
        icon: Icons.logout_rounded,
        destructive: true,
        title: 'Close Duoob?',
        subtitle:
            'Are you sure you want to close the app? Any unsaved work in open tasks may be lost.',
        yesTitle: 'Close',
        noTitle: 'Cancel',
        yes: () => Navigator.pop(dialogContext, true),
        no: () => Navigator.pop(dialogContext, false),
      ),
    );
    _isCloseDialogOpen = false;

    if (shouldClose == true) {
      // windowManager.destroy() waits on native engine/plugin teardown
      // (WebView2/WKWebView instances tear down slowly), which made the
      // app appear stuck after confirming close. Hide immediately for
      // instant feedback, then force-exit the process.
      await windowManager.hide();
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Duoob',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: RootWrapper(),
    );
  }
}
