import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter errors gracefully (especially Firebase errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    // If it's a Firebase error, just log it and continue
    if (details.exception.toString().contains('Firebase') ||
        details.exception.toString().contains('firebase')) {
      debugPrint('Firebase error caught: ${details.exception}');
      return; // Don't show error screen for Firebase errors
    }
    // For other errors, use the default handler
    FlutterError.presentError(details);
  };

  // Try to initialize Firebase
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint(
      'App will continue without Firebase. Some features may not work.',
    );
    // Continue anyway - app will work in limited mode
  }

  runApp(const HumSafarApp());
}

/// Main application widget with modern theming
class HumSafarApp extends StatelessWidget {
  const HumSafarApp({super.key});

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        title: 'HumSafar - Carpool with fellow students',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.light, // Using light theme for now
        home: const SplashScreen(),
      );
  }

  /// Modern light theme with custom colors matching the app design
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF49977a),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Modern dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF49977a),
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
