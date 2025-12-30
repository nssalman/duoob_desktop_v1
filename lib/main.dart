import 'package:duoob_desktop_app_v1/controller/login_provider.dart';
import 'package:duoob_desktop_app_v1/controller/report_provider.dart';
import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:duoob_desktop_app_v1/services/theme.dart';
import 'package:duoob_desktop_app_v1/view/login_screen.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
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
      home: const LoginScreen(),
    );
  }
}

