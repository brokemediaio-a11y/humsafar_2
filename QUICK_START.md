# Quick Start - Post Card Fixes

## What Was Fixed

✅ **Google Maps preview** now shows in post cards  
✅ **Car details** display correctly for driver posts  
✅ **Car field** hidden for passenger posts  

## To Get It Working

### Step 1: Get Google Maps API Key (5 minutes)

1. Go to https://console.cloud.google.com/
2. Create/select a project
3. Enable these APIs:
   - Maps Static API
   - Maps SDK for Android/iOS
   - Geocoding API
4. Create API Key (Credentials → Create Credentials → API Key)
5. Copy the API key

### Step 2: Configure API Key (1 minute)

Open `lib/config/maps_config.dart` and replace:

```dart
static const String apiKey = 'YOUR_API_KEY_HERE';
```

With your actual key:

```dart
static const String apiKey = 'AIzaSyC...your-actual-key-here';
```

### Step 3: Enable Billing (2 minutes)

1. Go to https://console.cloud.google.com/billing
2. Link a billing account
3. **Don't worry**: Includes $200/month FREE credit
4. Your university app won't exceed free tier

### Step 4: Test It

```bash
flutter run
```

1. Create a driver post with car details
2. Go to home screen
3. You should see:
   - Map with route preview ✅
   - Car details displayed ✅

## Expected Result

### Driver Post Card:
```
┌─────────────────────────────┐
│ 👤 Saad Hassan     [Driver] │
│                              │
│ ● From Islamabad             │
│ │                            │
│ ● To Rawalpindi              │
│                              │
│ [Map Preview with Route]     │
│                              │
│ Seats: 3 available           │
│ Car: Toyota • Corolla • White│
│                              │
│ [Request Seat]  [Message]    │
└─────────────────────────────┘
```

### Passenger Post Card:
```
┌─────────────────────────────┐
│ 👤 Saad Hassan  [Passenger] │
│                              │
│ ● From Bahria University     │
│ │                            │
│ ● To G9, Islamabad          │
│                              │
│ [Map Preview with Route]     │
│                              │
│ Seats: 3 needed              │
│ (No car field - correct!)    │
│                              │
│ [Offer Ride]     [Message]   │
└─────────────────────────────┘
```

## Troubleshooting

### Problem: "Map preview unavailable"

**Solutions**:
- Check if Maps Static API is enabled
- Verify API key in `maps_config.dart`
- Enable billing in Google Cloud Console
- Wait 2-3 minutes for API key to activate

### Problem: Car field still not showing for drivers

**Solutions**:
- Make sure you enter car details when creating post
- Check that make, model, or color fields are filled
- Restart the app

### Problem: Car field showing for passengers

**Solutions**:
- This should be fixed now
- If still showing, ensure you selected "Passenger" when creating post
- Clear app data and try again

## Need Detailed Instructions?

See `GOOGLE_MAPS_SETUP.md` for comprehensive setup guide.

## Security Reminder

🔒 **Before sharing code or committing to Git**:

1. Add to `.gitignore`:
   ```
   lib/config/maps_config.dart
   ```

2. Or create a template file:
   ```dart
   // maps_config.template.dart
   class MapsConfig {
     static const String apiKey = 'REPLACE_WITH_YOUR_KEY';
   }
   ```

3. In Google Cloud Console:
   - Restrict API key to your app only
   - Set budget alerts

## Cost Information

**Free Tier (Monthly)**:
- Static Maps: 100,000 requests FREE
- Maps SDK: 100,000 map loads FREE
- Total credit: $200 FREE

**Your App Usage (Estimated)**:
- Post card views: ~1,000-5,000/month
- **Cost: $0** (well within free tier)

## All Set! 🎉

Your post cards should now show:
✅ Beautiful map previews  
✅ Proper car info for drivers  
✅ Clean layout for passengers  

Happy coding! 🚀

