# 📱 iOS Setup Guide for HumSafar App

This comprehensive guide will help you set up your Flutter app to run on iOS devices, including Firebase and Google Maps configuration.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase iOS Setup](#firebase-ios-setup)
3. [Google Maps iOS Setup](#google-maps-ios-setup)
4. [iOS Configuration Files](#ios-configuration-files)
5. [Testing on Your iPhone](#testing-on-your-iphone)
6. [Naming Conventions](#naming-conventions)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Prerequisites

Before you begin, make sure you have:
- ✅ A Mac computer (required for iOS development)
- ✅ Xcode installed (latest version from App Store)
- ✅ CocoaPods installed (`sudo gem install cocoapods`)
- ✅ An Apple Developer account (free account works for testing)
- ✅ Your iPhone connected via USB
- ✅ Firebase project already set up (you have `humsafar-eb7f9`)

---

## 🔥 Firebase iOS Setup

### Step 1: Add iOS App to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **humsafar-eb7f9**
3. Click the **⚙️ Settings** icon → **Project settings**
4. Scroll down to **Your apps** section
5. Click **Add app** → Select **iOS** (Apple icon)
6. Fill in the iOS app registration:
   - **iOS bundle ID**: `com.example.humsafarApp`
     - ⚠️ **Important**: This must match your Xcode bundle identifier exactly
   - **App nickname** (optional): `HumSafar iOS`
   - **App Store ID** (optional): Leave blank for now
7. Click **Register app**

### Step 2: Download GoogleService-Info.plist

1. After registering, you'll see a **Download GoogleService-Info.plist** button
2. Click to download the file
3. **DO NOT** add it to your project yet - we'll do that in the next step

### Step 3: Add GoogleService-Info.plist to Xcode

**Option A: Using Xcode (Recommended)**
1. Open your project in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```
   ⚠️ **Important**: Open `.xcworkspace`, NOT `.xcodeproj`

2. In Xcode, right-click on the **Runner** folder (blue icon) in the left sidebar
3. Select **Add Files to "Runner"...**
4. Navigate to your downloaded `GoogleService-Info.plist`
5. **IMPORTANT**: 
   - ✅ Check "Copy items if needed"
   - ✅ Select "Runner" as the target
   - ✅ Make sure "Create groups" is selected
6. Click **Add**

**Option B: Manual Copy (Alternative)**
1. Copy the downloaded `GoogleService-Info.plist` file
2. Paste it into: `ios/Runner/GoogleService-Info.plist`
3. Make sure it's in the same folder as `Info.plist`

### Step 4: Verify GoogleService-Info.plist

The file should contain:
- `PROJECT_ID`: `humsafar-eb7f9`
- `BUNDLE_ID`: `com.example.humsafarApp`
- Various API keys and configuration

---

## 🗺️ Google Maps iOS Setup

### Step 1: Enable Maps SDK for iOS in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **humsafar-eb7f9**
3. Go to **APIs & Services** → **Library**
4. Search for **"Maps SDK for iOS"**
5. Click on it and press **Enable**

### Step 2: Create iOS API Key (Recommended) or Use Existing

**Option A: Create Separate iOS API Key (More Secure)**
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Name it: `HumSafar iOS Maps API Key`
4. Click **Restrict Key**:
   - **Application restrictions**: Select **iOS apps**
   - Click **Add an item**
   - **Bundle ID**: `com.example.humsafarApp`
   - Click **Save**
5. **API restrictions**: Select **Restrict key**
   - Check: ✅ Maps SDK for iOS
   - Check: ✅ Maps Static API
   - Check: ✅ Geocoding API
   - Click **Save**
6. Copy the API key

**Option B: Use Existing API Key (Simpler)**
- You can use your existing key: `AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk`
- Just make sure **Maps SDK for iOS** is enabled in your project

### Step 3: Configure Google Maps in iOS Code

The `AppDelegate.swift` file has been updated to include Google Maps initialization. The API key is configured in `Info.plist`.

---

## 📝 iOS Configuration Files

### Files That Need Configuration:

1. **✅ Info.plist** - Location permissions and Google Maps API key
2. **✅ AppDelegate.swift** - Google Maps initialization
3. **✅ GoogleService-Info.plist** - Firebase configuration (you'll download this)
4. **✅ Podfile** - Dependencies (Flutter manages this automatically)

All configuration files have been updated for you! You just need to:
1. Download `GoogleService-Info.plist` from Firebase
2. Add it to your Xcode project

---

## 📱 Testing on Your iPhone

### Step 1: Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. Unlock your iPhone
3. If prompted, tap **Trust This Computer** on your iPhone

### Step 2: Configure Signing in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** in the left sidebar (blue icon)
3. Select the **Runner** target
4. Go to **Signing & Capabilities** tab
5. Check **Automatically manage signing**
6. Select your **Team** (your Apple ID)
   - If you don't see your team, click **Add Account...** and sign in
7. Xcode will automatically create a provisioning profile

### Step 3: Select Your Device

1. In Xcode toolbar, click the device selector (next to the Run button)
2. Select your connected iPhone

### Step 4: Build and Run

**Option A: From Xcode**
1. Click the **▶️ Play** button in Xcode
2. Wait for the build to complete
3. The app will install and launch on your iPhone

**Option B: From Terminal (Flutter)**
```bash
flutter devices  # See connected devices
flutter run -d <device-id>  # Run on specific device
# Or simply:
flutter run  # Flutter will ask which device to use
```

### Step 5: Trust Developer Certificate (First Time Only)

If you see "Untrusted Developer" on your iPhone:
1. Go to **Settings** → **General** → **VPN & Device Management**
2. Tap on your developer certificate
3. Tap **Trust** → **Trust**

---

## 🏷️ Naming Conventions

### Current Configuration:

| Item | Android | iOS |
|------|---------|-----|
| **Package/Bundle ID** | `com.example.humsafar_app` | `com.example.humsafarApp` |
| **App Name** | `humsafar_app` | `Humsafar App` |
| **Display Name** | `humsafar_app` | `Humsafar App` |

### Recommended Changes (For Production):

For a production app, you should use a proper reverse domain notation:

**Android:**
- Package: `com.humsafar.app` or `com.yourcompany.humsafar`

**iOS:**
- Bundle ID: `com.humsafar.app` or `com.yourcompany.humsafar`

**To Change Bundle ID:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** → **Runner** target
3. Go to **General** tab
4. Change **Bundle Identifier** to your desired ID
5. Update Firebase iOS app registration with new Bundle ID
6. Download new `GoogleService-Info.plist` again

---

## 🔧 Troubleshooting

### Issue: "No GoogleService-Info.plist found"

**Solution:**
- Make sure you downloaded the file from Firebase Console
- Verify it's in `ios/Runner/` folder
- In Xcode, make sure it's added to the **Runner** target (check in File Inspector)

### Issue: "Google Maps shows blank screen"

**Solutions:**
1. Verify Maps SDK for iOS is enabled in Google Cloud Console
2. Check API key is correct in `Info.plist`
3. Make sure billing is enabled (Google Maps requires billing, but has $200 free credit)
4. Check Xcode console for error messages

### Issue: "Signing for Runner requires a development team"

**Solution:**
1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. In Runner target → Signing & Capabilities, select your team

### Issue: "Build failed" or "Pod install failed"

**Solutions:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Issue: "Location permissions not working"

**Solution:**
- Verify `Info.plist` has location permission descriptions
- Check that location permissions are requested in your Dart code
- Test on a real device (simulator location may not work properly)

### Issue: "Firebase not connecting"

**Solutions:**
1. Verify `GoogleService-Info.plist` is in the correct location
2. Check Bundle ID matches Firebase console
3. Clean and rebuild:
   ```bash
   flutter clean
   cd ios
   pod install
   cd ..
   flutter run
   ```

---

## ✅ Checklist

Before running on iOS, make sure:

- [ ] Xcode is installed and updated
- [ ] CocoaPods is installed (`pod --version`)
- [ ] iOS app added to Firebase Console
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode project
- [ ] Maps SDK for iOS enabled in Google Cloud Console
- [ ] API key configured in `Info.plist`
- [ ] Location permissions added to `Info.plist`
- [ ] Signing configured in Xcode
- [ ] iPhone connected and trusted
- [ ] Developer certificate trusted on iPhone (first time)

---

## 🚀 Quick Start Commands

```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Clean and rebuild
flutter clean
flutter pub get

# Run on connected iOS device
flutter run

# Or open in Xcode
cd ios
open Runner.xcworkspace
```

---

## 📚 Additional Resources

- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Google Maps iOS SDK](https://developers.google.com/maps/documentation/ios-sdk)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

---

**Need Help?** Check the troubleshooting section or review the error messages in Xcode console for specific guidance.

