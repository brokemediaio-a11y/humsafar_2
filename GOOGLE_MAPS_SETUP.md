# Google Maps API Setup Guide

This guide will help you set up Google Maps API for the HumSafar app.

## Overview

The app uses two Google Maps features:
1. **Google Maps Flutter** - Interactive maps in the Create Post screen
2. **Google Maps Static API** - Map preview images in post cards

## Step-by-Step Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID

### 2. Enable Required APIs

Enable the following APIs in your project:

1. **Maps SDK for Android** (for Android app)
   - Go to: https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com
   - Click "Enable"

2. **Maps SDK for iOS** (for iOS app)
   - Go to: https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com
   - Click "Enable"

3. **Maps JavaScript API** (for Web app)
   - Go to: https://console.cloud.google.com/apis/library/maps-backend.googleapis.com
   - Click "Enable"

4. **Maps Static API** (for post card previews)
   - Go to: https://console.cloud.google.com/apis/library/static-maps-backend.googleapis.com
   - Click "Enable"

5. **Geocoding API** (for address search)
   - Go to: https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com
   - Click "Enable"

### 3. Create API Keys

#### Option A: Single API Key (Simpler, less secure)

1. Go to [Credentials page](https://console.cloud.google.com/apis/credentials)
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. (Recommended) Click "Restrict Key" and add your app's package name

#### Option B: Multiple API Keys (More secure)

Create separate API keys for each platform:
- One for Android (restricted to your Android app)
- One for iOS (restricted to your iOS app)
- One for Web (restricted to your domain)

### 4. Configure API Keys in the App

#### For Static Maps (Post Card Previews)

Edit `lib/config/maps_config.dart`:

```dart
class MapsConfig {
  static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
}
```

Replace `'YOUR_ACTUAL_API_KEY_HERE'` with your actual API key.

#### For Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <application ...>
        <!-- Add this inside <application> tag -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_API_KEY"/>
        ...
    </application>
</manifest>
```

#### For iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")  // Add this line
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### For Web

Edit `web/index.html`:

Add this script tag before the closing `</body>` tag:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
```

### 5. Restrict API Keys (Important for Security)

To prevent unauthorized use of your API keys:

#### For Android Key:
1. Go to API Credentials page
2. Click on your Android API key
3. Under "Application restrictions", select "Android apps"
4. Click "Add package name"
5. Add your package name: `com.example.humsafar_app` (or your actual package name)
6. Add your SHA-1 certificate fingerprint

To get your SHA-1 fingerprint:
```bash
# For debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release key
keytool -list -v -keystore /path/to/your-release-key.keystore
```

#### For iOS Key:
1. Select "iOS apps"
2. Add your bundle identifier: `com.example.humsafarApp` (or your actual bundle ID)

#### For Web Key:
1. Select "HTTP referrers"
2. Add your domains (e.g., `localhost:*`, `yourdomain.com/*`)

#### For Static Maps API Key:
1. Under "API restrictions", select "Restrict key"
2. Select "Maps Static API"
3. Click "Save"

### 6. Set Up Billing (Required)

Google Maps Platform requires a billing account, but includes:
- **$200 monthly free credit**
- Static Maps: Free up to 100,000 requests/month
- Maps SDK: Free up to 100,000 map loads/month

1. Go to [Billing page](https://console.cloud.google.com/billing)
2. Link a billing account to your project
3. Don't worry - you're unlikely to exceed free tier for a university app

### 7. Test Your Setup

After configuring:

1. Run your app:
   ```bash
   flutter run
   ```

2. Create a post with route locations
3. Check if:
   - Map appears in Create Post screen
   - Map preview appears in post cards on home screen

### Troubleshooting

#### Map Preview Not Showing

**Issue**: Post cards show "Map preview unavailable"

**Solutions**:
1. Check if Static Maps API is enabled
2. Verify API key in `lib/config/maps_config.dart`
3. Check browser console/logcat for error messages
4. Ensure billing is enabled
5. Check API key restrictions aren't blocking requests

#### Interactive Map Not Loading

**Issue**: Map in Create Post screen is blank or shows "For development purposes only"

**Solutions**:
1. Verify platform-specific API key configuration
2. Check if Maps SDK for your platform is enabled
3. For Android: Verify SHA-1 fingerprint is correct
4. For iOS: Verify bundle ID matches
5. Enable billing account

#### Error: "This API project is not authorized to use this API"

**Solution**: The required API is not enabled. Go back to step 2 and enable all APIs.

#### Error: "API key not valid"

**Solution**: 
1. Check if you copied the API key correctly
2. Wait a few minutes - new keys take time to propagate
3. Check if key restrictions are too strict

### Cost Optimization Tips

1. **Use Static Maps for previews** (not interactive maps) - Already implemented ✓
2. **Cache map images** - Consider implementing image caching
3. **Limit zoom levels** - Already optimized ✓
4. **Monitor usage** - Set up budget alerts in Google Cloud Console

### Monitoring Usage

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" → "Dashboard"
4. View usage statistics for each API

### Setting Up Budget Alerts

1. Go to [Budgets & alerts](https://console.cloud.google.com/billing/budgets)
2. Click "CREATE BUDGET"
3. Set a budget (e.g., $50/month)
4. Set alert thresholds (e.g., 50%, 90%, 100%)
5. Add your email for notifications

## Alternative: OpenStreetMap (Free)

If you want to avoid Google Maps billing completely, consider using:
- **flutter_map** package with OpenStreetMap tiles
- Free and no API key required
- Trade-off: Less features and data coverage

Would you like instructions for switching to OpenStreetMap?

## Need Help?

- [Google Maps Platform Documentation](https://developers.google.com/maps)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Stack Overflow - google-maps tag](https://stackoverflow.com/questions/tagged/google-maps)

