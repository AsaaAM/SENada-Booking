import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SENadaApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService().requestPermissions();
  });
}

class SENadaApp extends StatelessWidget {
  const SENadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SENada',
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }
          if (auth.role == 'admin') {
            return const AdminHomeScreen();
          }
          return const MainNavigationScreen();
        },
      ),
    );
  }
}

