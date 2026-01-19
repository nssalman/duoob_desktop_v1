import 'dart:io';

import 'package:duoob_desktop_app_v1/controller/login_provider.dart';
import 'package:duoob_desktop_app_v1/controller/report_provider.dart';
import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:duoob_desktop_app_v1/services/theme.dart';
import 'package:duoob_desktop_app_v1/view/login_screen.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:duoob_desktop_app_v1/view/root_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;


WebViewEnvironment? webViewEnvironment;
void main() async{
    WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    // 1. Get the local app data directory (safe for writing)
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String webViewDataPath = p.join(appSupportDir.path, 'webview_data');

    // 2. Create the environment with the custom path
    webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: webViewDataPath)
    );
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()), 
        ChangeNotifierProvider(create: (_) => TaskProvider()), 
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'WebView App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: RootWrapper(),
    );
  }
}

