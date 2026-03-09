# Debug Guide - Understanding the Console Output

## How to View Debug Logs

### Android Studio / VS Code
- Look at the "Debug Console" or "Run" tab at the bottom
- Filter for "PostCard:" to see relevant messages

### Terminal
```bash
flutter run
# Then watch the output
```

## What the Debug Logs Tell You

### Example 1: Working Driver Post with Car Info

```
PostCard: Building card for Saad Hassan (Driver)
PostCard: Car info - Make: Toyota, Model: Corolla, Color: White
PostCard: Has car info: true
PostCard: Coordinates - From: (33.6844, 73.0479), To: (33.5969, 73.0479)
PostCard: Generated map URL (key masked)
```

**Interpretation**:
✅ User is a driver  
✅ Car details are filled (Toyota Corolla White)  
✅ Has car info = true → **Car field WILL show**  
✅ Coordinates exist → **Map can be generated**  
✅ Map URL generated → **Map SHOULD show** (if API key configured)

---

### Example 2: Driver Post WITHOUT Car Info (BUG - Your Current Issue)

```
PostCard: Building card for Saad Hassan (Driver)
PostCard: Car info - Make: null, Model: null, Color: null
PostCard: Has car info: false
PostCard: Coordinates - From: (33.6844, 73.0479), To: (33.5969, 73.0479)
PostCard: Generated map URL (key masked)
```

**Interpretation**:
✅ User is a driver  
❌ Car details are null/empty  
❌ Has car info = false → **Car field will NOT show**  
✅ Coordinates exist  
✅ Map URL generated

**Solution**: Create a NEW post and fill in car make, model, and color fields

---

### Example 3: Driver Post with Empty Strings (Old Bug - Now Fixed)

```
PostCard: Building card for Saad Hassan (Driver)
PostCard: Car info - Make: , Model: , Color: 
PostCard: Has car info: false
PostCard: Coordinates - From: (33.6844, 73.0479), To: (33.5969, 73.0479)
PostCard: Generated map URL (key masked)
```

**Interpretation**:
❌ Car fields have empty strings (not null, but empty)  
❌ Has car info = false → **Car field will NOT show**  

**This was the bug**: Empty strings were being saved. **Now fixed** ✅

---

### Example 4: API Key Not Configured

```
PostCard: Building card for Saad Hassan (Driver)
PostCard: Car info - Make: Toyota, Model: Corolla, Color: White
PostCard: Has car info: true
PostCard: Coordinates - From: (33.6844, 73.0479), To: (33.5969, 73.0479)
PostCard: Google Maps API key not configured! Please update lib/config/maps_config.dart
```

**Interpretation**:
✅ Car info is good  
❌ **API key not configured** → **Map will NOT show**  

**Solution**: 
1. Get API key from Google Cloud Console
2. Update `lib/config/maps_config.dart`
3. Hot restart app

---

### Example 5: Missing Coordinates

```
PostCard: Building card for Saad Hassan (Driver)
PostCard: Car info - Make: Toyota, Model: Corolla, Color: White
PostCard: Has car info: true
PostCard: Missing coordinates for map preview
```

**Interpretation**:
✅ Car info is good  
❌ **Coordinates missing** → **Map cannot be generated**  

**This shouldn't happen** if post was created through the Create Post screen with map selection.

---

### Example 6: Passenger Post (Correct Behavior)

```
PostCard: Building card for Saad Hassan (Passenger)
PostCard: Coordinates - From: (33.6844, 73.0479), To: (33.5969, 73.0479)
PostCard: Generated map URL (key masked)
```

**Interpretation**:
✅ User is a passenger  
✅ Car info logging skipped (not applicable)  
✅ Coordinates exist  
✅ Map URL generated  
✅ **Car field will NOT show** (correct behavior for passengers)

---

## Quick Diagnostic Checklist

### Issue: Car field not showing for driver

1. Look for: `PostCard: Car info - Make: ...`
   - If all null/empty → **Car fields weren't filled when creating post**
   - **Solution**: Create new post with car details filled

2. Look for: `PostCard: Has car info: false`
   - Confirms car info is missing
   - **Solution**: Fill car fields when creating post

### Issue: Map preview not showing

1. Look for: `PostCard: Google Maps API key not configured!`
   - **Solution**: Configure API key in `lib/config/maps_config.dart`

2. Look for: `PostCard: Missing coordinates for map preview`
   - **Solution**: Use map selection in Create Post screen

3. If map URL is generated but map doesn't show:
   - Check if Maps Static API is enabled in Google Cloud
   - Check if billing is set up
   - Wait 2-3 minutes for API key activation

## Console Commands to Filter Logs

### Show only PostCard logs
```bash
flutter run 2>&1 | grep "PostCard:"
```

### Show only errors
```bash
flutter run 2>&1 | grep -i "error"
```

## Expected Flow for NEW Driver Post

When you create a new driver post with car details:

```
1. Create Post Screen:
   [User fills: Make=Toyota, Model=Corolla, Color=White]
   [User selects route on map]
   [User clicks "Post Trip"]

2. Console output:
   PostCard: Building card for Saad Hassan (Driver)
   PostCard: Car info - Make: Toyota, Model: Corolla, Color: White
   PostCard: Has car info: true  ← KEY: This should be true!
   PostCard: Coordinates - From: (33.xxx, 73.xxx), To: (33.xxx, 73.xxx)
   PostCard: Generated map URL (key masked)

3. On Screen:
   ✅ Post card shows
   ✅ Car field shows: "Toyota • Corolla • White"
   ✅ Map preview shows (if API key configured)
```

## Next Steps

1. **Run the app**
2. **Check console output** for PostCard messages
3. **Share the output** if you need help diagnosing
4. **Follow solutions** based on what you see

The debug messages will tell us exactly what's wrong! 🔍

