import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PhoneDialer {
  static const MethodChannel _channel = MethodChannel('phone_dialer');

  /// Dial a phone number using platform channel (Android/iOS)
  /// This is a fallback if url_launcher doesn't work
  static Future<bool> dial(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<bool>('dial', {'number': phoneNumber});
      return result ?? false;
    } catch (e) {
      debugPrint('Error dialing phone: $e');
      return false;
    }
  }
}
