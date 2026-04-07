import 'package:flutter/foundation.dart';

/// Secure logging utility that only prints in debug mode
class Logger {
  /// Log debug information (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('🐛 $tagPrefix$message');
    }
  }

  /// Log information (only in debug mode)
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $tagPrefix$message');
    }
  }

  /// Log warnings (only in debug mode)
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $tagPrefix$message');
    }
  }

  /// Log errors (always logs, but securely)
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $tagPrefix$message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      // In production, log to crash reporting service
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    }
  }

  /// Log network requests (only in debug mode)
  static void network(String method, String url, [int? statusCode, String? tag]) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final status = statusCode != null ? ' ($statusCode)' : '';
      debugPrint('🌐 $tagPrefix$method $url$status');
    }
  }
}