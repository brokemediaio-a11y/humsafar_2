# 🔒 Security & Deployment Guide

## ✅ Automated Security Fixes Applied

The following security improvements have been automatically implemented:

### 1. **API Key Security** ✅
- Google Maps API key now uses environment variables
- AndroidManifest.xml updated to use `${GOOGLE_MAPS_API_KEY}` placeholder
- Fallback values provided for development

### 2. **Package Name Updated** ✅
- Changed from `com.example.humsafar_app` to `com.nexordis.humsafar`
- Updated in all configuration files
- MainActivity moved to correct package structure

### 3. **Release Build Configuration** ✅
- Added proper release signing configuration
- Enabled code obfuscation and minification
- Created ProGuard rules for Flutter and Firebase

### 4. **Network Security** ✅
- Added network security configuration
- Disabled cleartext traffic
- Configured trusted domains for Firebase, Google APIs, and Cloudinary

### 5. **Secure Logging** ✅
- Created secure Logger utility
- Debug prints only show in development
- Production logs can be integrated with crash reporting

### 6. **Build Security** ✅
- Updated .gitignore to exclude sensitive files
- Created keystore.properties template
- Added backup prevention in AndroidManifest

---

## 🔧 Manual Steps Required

### **STEP 1: Create Release Keystore** (Required)

```bash
# Navigate to android folder
cd android

# Generate release keystore
keytool -genkey -v -keystore humsafar-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias humsafar-key

# Follow prompts and remember your passwords!
```

### **STEP 2: Configure Keystore Properties** (Required)

```bash
# Copy template and fill in your values
cp keystore.properties.template keystore.properties

# Edit keystore.properties with your actual values:
# storePassword=your_actual_store_password
# keyPassword=your_actual_key_password  
# keyAlias=humsafar-key
# storeFile=../humsafar-keystore.jks
```

### **STEP 3: Set Environment Variables** (Required)

For development:
```bash
# Windows (PowerShell)
$env:GOOGLE_MAPS_API_KEY="AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q"

# macOS/Linux
export GOOGLE_MAPS_API_KEY="AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q"
```

For production build:
```bash
# Set your restricted production API key
$env:GOOGLE_MAPS_API_KEY="your_production_api_key"
```

### **STEP 4: Update Firebase Configuration** (Required)

1. **Update Firebase Console:**
   - Go to Firebase Console → Project Settings
   - Add new Android app with package name: `com.nexordis.humsafar`
   - Download new `google-services.json`
   - Replace the existing file

2. **Update Firebase Options:**
   - Run: `flutterfire configure`
   - Select your project
   - Choose platforms (Android, iOS, Web)
   - This will update `lib/firebase_options.dart` with new package name

### **STEP 5: Restrict API Keys** (Critical)

1. **Google Cloud Console:**
   - Go to APIs & Credentials
   - Edit your Google Maps API key
   - Add Application restrictions:
     - **Android apps:** `com.nexordis.humsafar`
     - **SHA-1 fingerprint:** (get from your keystore)
   - Add API restrictions:
     - Maps SDK for Android
     - Maps Static API
     - Geocoding API (if used)

2. **Get SHA-1 fingerprint:**
```bash
keytool -list -v -keystore humsafar-keystore.jks -alias humsafar-key
```

### **STEP 6: Build Release APK** (Final Step)

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

---

## 🛡️ Security Checklist

Before Play Store submission, verify:

- [ ] API keys are restricted to your app package and SHA-1
- [ ] No hardcoded secrets in source code
- [ ] Release signing is configured
- [ ] Code obfuscation is enabled
- [ ] Network security config is applied
- [ ] Debug logging is disabled in production
- [ ] Firebase rules are properly configured
- [ ] App uses HTTPS for all network requests

---

## 🚨 Important Security Notes

1. **Never commit these files:**
   - `keystore.properties`
   - `*.jks` or `*.keystore` files
   - `.env` files with real API keys

2. **API Key Security:**
   - Use different API keys for development and production
   - Always restrict API keys to your app package
   - Monitor API usage in Google Cloud Console

3. **Firebase Security:**
   - Configure Firestore security rules
   - Enable App Check for production
   - Monitor authentication logs

4. **Regular Security Updates:**
   - Keep dependencies updated
   - Monitor security advisories
   - Review permissions regularly

---

## 📞 Need Help?

If you encounter issues during deployment:
1. Check the error logs carefully
2. Verify all environment variables are set
3. Ensure keystore properties are correct
4. Test with `flutter build apk --debug` first

Your app is now significantly more secure and ready for Play Store deployment! 🚀