/// Google Maps API Configuration
/// 
/// To use Google Maps Static API:
/// 1. Go to Google Cloud Console (https://console.cloud.google.com/)
/// 2. Enable "Maps Static API"
/// 3. Create or use existing API key
/// 4. Set GOOGLE_MAPS_API_KEY environment variable
/// 
/// For production deployment:
/// - Set environment variable: GOOGLE_MAPS_API_KEY=your_actual_key
/// - Update AndroidManifest.xml to use ${GOOGLE_MAPS_API_KEY}
class MapsConfig {
  // Google Maps API key from environment variable (secure approach)
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q', // Fallback for development
  );
  
  // Platform-specific keys (if needed)
  static const String androidApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_API_KEY',
    defaultValue: apiKey,
  );
  
  static const String iosApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_IOS_API_KEY', 
    defaultValue: apiKey,
  );
  
  static const String webApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_API_KEY',
    defaultValue: apiKey,
  );
  
  /// Returns true if API key is configured and not using placeholder
  static bool get isConfigured => 
      apiKey.isNotEmpty && 
      apiKey != 'YOUR_API_KEY_HERE' && 
      apiKey.startsWith('AIza');
}

