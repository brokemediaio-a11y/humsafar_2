# ✅ API Key Updated Successfully!

## What I Updated

1. ✅ **`lib/config/maps_config.dart`** - Updated API key
2. ✅ **`android/app/src/main/AndroidManifest.xml`** - Updated API key

**New API Key**: `AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q`

---

## ⚠️ IMPORTANT: Verify API Key Permissions

Since you're still getting 403 errors, the new API key needs proper permissions:

### Step 1: Check API Key Restrictions

1. Go to: **https://console.cloud.google.com/apis/credentials**

2. Find and click on your API key: `AIzaSyDTd4GTot7P6-5mb55Cav7QflvEgqdqY0Q`

3. Scroll to **"API restrictions"** section

4. **Choose one:**

   **Option A: Remove All Restrictions (Easiest)**
   - Select **"Don't restrict key"**
   - Click **"SAVE"**
   - ⚠️ **Wait 2-3 minutes** for changes to propagate

   **Option B: Add Required APIs**
   - Select **"Restrict key"**
   - Click **"Select APIs"**
   - Check these APIs:
     - ✅ **Maps Static API** (REQUIRED for static maps)
     - ✅ **Maps SDK for Android** (for interactive maps)
     - ✅ **Directions API** (for routes)
   - Click **"SAVE"**
   - ⚠️ **Wait 2-3 minutes**

---

## Step 2: Verify Billing is Linked

1. Go to: **https://console.cloud.google.com/billing**

2. Make sure your project is linked to a billing account

3. Should show **"Linked"** status

---

## Step 3: Hot Restart App

```bash
# Press 'R' (capital R) in terminal
# OR stop and restart: flutter run
```

---

## 🔍 Debug: Check Terminal After Restart

After hot restart, check your terminal. You should see:

**If working:**
- ✅ No 403 errors
- ✅ Map images load
- ✅ Route visible

**If still 403:**
- Look for the error message
- It will tell you exactly what's wrong:
  - "API key not valid" → Check key is correct
  - "This API project is not authorized" → Enable Maps Static API
  - "API key not valid. Please pass a valid API key" → Check restrictions

---

## ✅ Quick Checklist

- [x] API key updated in `maps_config.dart` ✅
- [x] API key updated in `AndroidManifest.xml` ✅
- [ ] **API key has no restrictions OR includes Maps Static API**
- [ ] **Billing account linked to project**
- [ ] **Maps Static API is ENABLED**
- [ ] **Hot restarted app**
- [ ] **Waited 2-3 minutes after changing restrictions**

---

## 🚨 Most Common Issue

**The API key restrictions!** Even if Maps Static API is enabled, if your API key is restricted and doesn't include "Maps Static API" in the allowed list, you'll get 403.

**Quick fix**: Set API key to **"Don't restrict key"** (Option A above), wait 2-3 minutes, then hot restart.

---

## Expected Result

After fixing permissions and hot restarting:

- ✅ Static maps load successfully
- ✅ Route visible with green polyline
- ✅ Markers show (green "From", red "To")
- ✅ No more 403 errors
- ✅ Clean terminal output

---

**The code is updated! Now just fix the API key permissions in Google Cloud Console.** 🎯

