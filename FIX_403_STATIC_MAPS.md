R# 🔧 Fix 403 Error for Static Maps API

## ⚠️ Error You're Seeing

```
HTTP request failed, statusCode: 403
```

**This means**: Your API key doesn't have permission for Static Maps API, OR the API isn't enabled.

---

## ✅ Step-by-Step Fix

### Step 1: Enable Maps Static API (CRITICAL)

1. Go to: **https://console.cloud.google.com/apis/library/static-maps-backend.googleapis.com**

2. **Select your project** (the same one you used for Google Maps Flutter)

3. Click **"ENABLE"** button

4. Wait 30 seconds for it to enable

5. **Verify it's enabled**: You should see "API enabled" with a green checkmark

---

### Step 2: Check API Key Permissions

1. Go to: **https://console.cloud.google.com/apis/credentials**

2. Find and click on your API key: `AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk`

3. Scroll down to **"API restrictions"** section

4. You have two options:

   **Option A: Remove Restrictions (Easiest - for testing)**
   - Select **"Don't restrict key"**
   - Click **"SAVE"**
   - Wait 2-3 minutes

   **Option B: Add Static Maps API to Allowed List**
   - Select **"Restrict key"**
   - Under "API restrictions", click **"Select APIs"**
   - Search for and check:
     - ✅ **Maps Static API**
     - ✅ **Maps SDK for Android** (if you have it)
     - ✅ **Directions API** (if you have it)
   - Click **"SAVE"**
   - Wait 2-3 minutes

---

### Step 3: Verify Billing is Linked to Project

1. Go to: **https://console.cloud.google.com/billing**

2. Check if your project is linked:
   - Look for your project name in the list
   - Should show "Linked" status

3. **If not linked:**
   - Click **"Link a billing account"**
   - Select your billing account
   - Click **"Set account"**

---

### Step 4: Verify Static Maps API is Enabled

1. Go to: **https://console.cloud.google.com/apis/dashboard**

2. Search for **"Maps Static API"**

3. Should show:
   - ✅ **Status: Enabled**
   - ✅ **Quotas visible**

---

### Step 5: Hot Restart App

```bash
# Press 'R' (capital R) in terminal
# Or stop and restart: flutter run
```

---

## 🔍 Debugging: Check What's Wrong

After hot restart, check your terminal for the error message. It will tell you exactly what's wrong:

### Error: "API key not valid"
- **Fix**: Check API key is correct in `lib/config/maps_config.dart`

### Error: "This API project is not authorized"
- **Fix**: Enable Maps Static API (Step 1)

### Error: "API key not valid. Please pass a valid API key"
- **Fix**: Check API key restrictions (Step 2)

### Error: "Billing not enabled"
- **Fix**: Link billing account to project (Step 3)

---

## ✅ Quick Checklist

- [ ] Maps Static API is **ENABLED** in Google Cloud Console
- [ ] API key has **no restrictions** OR **Static Maps API** is in allowed list
- [ ] Billing account is **LINKED** to your project
- [ ] Hot restarted the app
- [ ] Checked terminal for specific error message

---

## 🚨 Still Getting 403?

### Try This:

1. **Wait 5 minutes** - API changes can take time to propagate

2. **Create a new API key** (if restrictions are too complex):
   - Go to: https://console.cloud.google.com/apis/credentials
   - Click **"Create Credentials"** → **"API Key"**
   - Copy the new key
   - Update `lib/config/maps_config.dart`:
     ```dart
     static const String apiKey = 'YOUR_NEW_KEY_HERE';
     ```
   - Hot restart

3. **Check API usage in console**:
   - Go to: https://console.cloud.google.com/apis/dashboard
   - Click on "Maps Static API"
   - Check "Metrics" tab
   - See if requests are being received (even if failing)

---

## 📝 What I Fixed in Code

1. **Fixed map size**: Was `600x4000` (too large), now capped at `640x640` max
2. **Better URL encoding**: Properly encodes path and markers
3. **Added debug logging**: Shows exact error and URL in terminal

---

## ✅ Expected Result

After fixing:

- ✅ Static maps load successfully
- ✅ Route visible with green polyline
- ✅ Markers show (green "From", red "To")
- ✅ No more 403 errors
- ✅ Clean terminal output

---

**The most common issue is Step 1 - the API isn't enabled!** Make sure you click "ENABLE" on the Maps Static API page. 🎯

