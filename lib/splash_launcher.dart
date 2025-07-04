import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'core/constants.dart';

void main() {
  runApp(const SplashLauncherApp());
}

class SplashLauncherApp extends StatelessWidget {
  const SplashLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 