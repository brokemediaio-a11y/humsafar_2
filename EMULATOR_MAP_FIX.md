# 🗺️ Fix Grey/Blank Map in Android Emulator

## ⚠️ The Problem

You're seeing a **grey/blank map** with only the Google logo because:
- **Android emulators without Google Play Services** cannot display Google Maps
- Google Maps requires Google Play Services to render
- Most default Android emulators don't include Google Play Services

---

## ✅ Solutions (Choose One)

### Solution 1: Use Emulator WITH Google Play Services (Recommended)

**Create a new emulator with Google Play:**

1. Open **Android Studio**
2. Go to **Tools** → **Device Manager** (or **AVD Manager**)
3. Click **Create Device**
4. Select a device (e.g., Pixel 5)
5. **IMPORTANT**: Choose a system image that says **"Google Play"** in the name
   - ✅ **"Tiramisu" (API 33) with Google Play** ← Choose this
   - ❌ **"Tiramisu" (API 33)** ← Don't choose this (no Google Play)
6. Click **Next** → **Finish**
7. Start the new emulator
8. Run your app: `flutter run`

**How to identify Google Play emulators:**
- Look for **"Google Play"** text in the system image name
- Icon shows Google Play logo
- Download size is larger (includes Google Play Services)

---

### Solution 2: Test on Real Android Device (Best Option)

**Real devices always work:**

1. Enable **Developer Options** on your Android phone:
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times
2. Enable **USB Debugging**:
   - Go to **Settings** → **Developer Options**
   - Enable **USB Debugging**
3. Connect phone via USB
4. Run: `flutter run`
5. Select your device when prompted

**Why this is better:**
- ✅ Always works (has Google Play Services)
- ✅ Real performance testing
- ✅ Actual GPS location
- ✅ Better for testing location features

---

### Solution 3: Install Google Play Services on Existing Emulator

**If you want to keep your current emulator:**

1. Download **Google Play Services APK**:
   - Search for "Google Play Services APK" for your Android version
   - Download from trusted source
2. Install via ADB:
   ```bash
   adb install -r google-play-services.apk
   ```
3. Restart emulator
4. Run your app

**Note**: This can be tricky and may not always work. Solution 1 or 2 is easier.

---

## 🔍 Verify the Issue

### Check if Google Play Services is Installed:

1. In your emulator, open **Settings**
2. Go to **Apps** → **See all apps**
3. Search for **"Google Play Services"**
4. If **NOT found** → That's your problem!

### Check API Key:

1. Verify API key in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk" />
   ```
2. Make sure it matches your `lib/config/maps_config.dart`

---

## 🎯 Quick Test

### Test if it's an emulator issue:

1. **Try on real device** → If it works, it's the emulator
2. **Check emulator system image** → Does it say "Google Play"?
3. **Check logcat** for errors:
   ```bash
   flutter run
   # Look for errors like:
   # "Google Play services not available"
   # "MapsInitializer failed"
   ```

---

## 📱 Recommended Emulator Setup

### For Google Maps Development:

**Best Emulator Configuration:**
- **Device**: Pixel 5 or Pixel 6
- **System Image**: **API 33 (Tiramisu) with Google Play**
- **RAM**: 2GB minimum (4GB recommended)
- **Graphics**: Hardware - GLES 2.0

**How to Create:**
1. Android Studio → Device Manager
2. Create Device → Pixel 5
3. **Select "Tiramisu" with Google Play icon**
4. Finish → Start

---

## ✅ Expected Results

### With Google Play Services:
- ✅ Map renders properly
- ✅ Shows actual map tiles
- ✅ Route displays correctly
- ✅ Markers visible
- ✅ Can interact with map

### Without Google Play Services:
- ❌ Grey/blank map
- ❌ Only Google logo visible
- ❌ No map tiles
- ❌ Cannot interact

---

## 🚀 Quick Fix Steps

1. **Check your current emulator:**
   - Does it have Google Play Store app?
   - If NO → Create new emulator with Google Play

2. **Create new emulator:**
   - Android Studio → Device Manager
   - Create Device
   - **Choose system image with "Google Play"**

3. **Test:**
   ```bash
   flutter clean
   flutter run
   ```

4. **If still grey:**
   - Try on real device
   - Check API key configuration
   - Verify Directions API is enabled

---

## 💡 Pro Tips

1. **Always use Google Play emulators** for Google Maps development
2. **Test on real device** before releasing
3. **Keep emulator updated** (Google Play Services updates automatically)
4. **Use hardware acceleration** for better performance

---

## 🐛 Still Not Working?

### Additional Checks:

1. **Internet Connection:**
   - Emulator needs internet to load map tiles
   - Check emulator can access internet

2. **API Key Restrictions:**
   - Go to Google Cloud Console
   - Check API key restrictions
   - Make sure Android app restriction includes your package name

3. **Billing:**
   - Google Maps requires billing (but has $200 free credit)
   - Verify billing is enabled

4. **Logcat Errors:**
   ```bash
   adb logcat | grep -i "maps\|google"
   ```
   Look for specific error messages

---

**The grey map is almost always because the emulator doesn't have Google Play Services. Create a new emulator with Google Play and it should work!** 🎉

