/// Google Maps API Configuration
/// 
/// To use Google Maps Static API:
/// 1. Go to Google Cloud Console (https://console.cloud.google.com/)
/// 2. Enable "Maps Static API"
/// 3. Create or use existing API key
/// 4. Replace 'YOUR_API_KEY_HERE' with your actual API key
/// 
/// Note: For production, consider using environment variables or secure storage
class MapsConfig {
  // Google Maps API key (same as in AndroidManifest.xml)
  static const String apiKey = 'AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q';
  
  // Alternatively, you can use different keys for different platforms
  // static const String androidApiKey = 'YOUR_ANDROID_KEY';
  // static const String iosApiKey = 'YOUR_IOS_KEY';
  // static const String webApiKey = 'YOUR_WEB_KEY';
  
  /// Returns true if API key is configured
  static bool get isConfigured => apiKey != 'YOUR_API_KEY_HERE';
}

