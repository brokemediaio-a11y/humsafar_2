# Enable Maps Static API - Quick Guide

## Your API Key is Already Configured! ✅

I found your API key in `AndroidManifest.xml` and updated `lib/config/maps_config.dart` automatically.

**API Key**: `AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk`

## What You Need to Do Now

### Step 1: Enable Maps Static API (2 minutes)

1. Go to Google Cloud Console:
   ```
   https://console.cloud.google.com/apis/library/static-maps-backend.googleapis.com
   ```

2. **Select your project** (the one you used for the Google Maps Flutter)

3. Click the **"ENABLE"** button

4. Wait a few seconds for it to enable

### Step 2: Hot Reload Your App

```bash
# Press 'r' in terminal or click hot reload
```

### Step 3: Check if It Works

The map previews should now appear in your post cards! 🎉

---

## If You Get 403 Error (Billing Not Enabled)

If you still see:
```
HTTP request failed, statusCode: 403
```

Then you need to **enable billing**:

1. Go to: https://console.cloud.google.com/billing

2. Click **"Link a billing account"**

3. Add a credit card

4. **Don't worry - you get $200/month FREE!**
   - Static Maps: 100,000 requests FREE per month
   - Your app will use ~1,000-5,000 requests/month
   - **Cost: $0** (well within free tier)

---

## If You Get 403 Error (API Key Restrictions)

If billing is enabled but still getting 403:

1. Go to: https://console.cloud.google.com/apis/credentials
undefinedR

2. Click on your API key: `AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk`

3. Under **"API restrictions"**:
   - Select **"Don't restrict key"** (for testing)
   - OR add "Maps Static API" to the list of allowed APIs

4. Click **"Save"**

5. Wait 2-3 minutes for changes to take effect

6. Hot reload your app

---

## Expected Result

After enabling the API and hot reloading:

```
┌─────────────────────────────┐
│ 👤 Saad Hassan     [Driver] │
│ ● From Islamabad             │
│ ● To Rawalpindi              │
│                              │
│ [MAP WITH ROUTE SHOWING] ✅  │  ← Should now appear!
│                              │
│ Seats: 3 available           │
│ Car: Toyota • Corolla • White│
│                              │
│ [Request Seat]  [Message]    │
└─────────────────────────────┘
```

---

## Quick Checklist

- [x] API key configured in `lib/config/maps_config.dart` ✅ (Done automatically)
- [ ] Enable Maps Static API in Google Cloud Console
- [ ] Enable billing (if required)
- [ ] Hot reload app
- [ ] Verify map previews appear

---

## Troubleshooting

### Still getting 403 after enabling API?

Wait 2-3 minutes, then:
1. Stop the app completely
2. Run `flutter clean`
3. Run `flutter run`

### Maps Static API not found?

Make sure you're in the **correct Google Cloud project** (the same one you used for Google Maps Flutter).

### Need to check which project?

Your interactive map in Create Post screen is working, so you already have:
- ✅ A Google Cloud project
- ✅ Maps SDK enabled
- ✅ API key created
- ✅ Billing enabled (maybe)

Just need to enable one more API: **Maps Static API**

---

## Summary

**What was wrong**: Maps Static API wasn't enabled for your project

**Quick fix**: 
1. Enable Maps Static API (link above)
2. Hot reload
3. Done! 🚀

**Time**: 2 minutes

---

Need help? Share any error messages you see!

