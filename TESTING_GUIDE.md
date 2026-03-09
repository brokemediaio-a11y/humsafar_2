# Testing Guide - Booking Request System

## Prerequisites

1. Two test accounts (one driver, one passenger)
2. Flutter app running
3. Internet connection

---

## Step-by-Step Testing

### Test 1: Request a Seat (Passenger)

**Setup:**
- Login as User A (passenger)
- Go to home screen

**Steps:**
1. Find a driver post on the home screen
2. Scroll down on the driver post card
3. Tap **"Request Seat"** button
4. In the dialog:
   - Enter number of seats (e.g., **2**)
   - Add a note: **"I'm at the main gate"**
5. Tap **"Confirm"**

**Expected Result:**
- Dialog closes
- Green toast appears: **"Seat request sent successfully!"** (2 seconds)
- Toast disappears automatically

---

### Test 2: View Alert (Driver)

**Setup:**
- Login as User B (driver - the person who created the post)

**Steps:**
1. Tap **"Alerts"** tab in bottom navigation (4th icon)
2. You should see the alerts screen

**Expected Result:**
- Alert appears: **"New Booking Request"**
- Message: **"[User A Name] requested 2 seat(s)"**
- Unread indicator (green dot) visible
- Time shows: **"Just now"** or **"1m ago"**

---

### Test 3: View Booking Details (Driver)

**Setup:**
- Continue from Test 2 (alerts screen)

**Steps:**
1. Tap on the booking request alert

**Expected Result:**
- Opens **Booking Request Detail Screen**
- **Passenger Details** card shows:
  - User A's name
  - "2 seat(s) requested"
  - Passenger note: "I'm at the main gate"
- **Trip Details** card shows:
  - Pickup location
  - Drop-off location
  - Interactive map with route (green = pickup, red = drop-off)
  - Departure time
  - Price (Rs. X)
- Bottom buttons:
  - **Decline** (red outline)
  - **Approve** (green filled)

---

### Test 4: Approve Request (Driver)

**Setup:**
- Continue from Test 3 (booking detail screen)

**Steps:**
1. Tap **"Approve"** button at bottom

**Expected Result:**
- Green toast appears: **"Request approved successfully!"**
- Screen automatically closes after 0.5 seconds
- Returns to alerts screen
- Alert now shows as read (no green dot)
- **On the post:** seats decreased (e.g., 4 → 2)

---

### Test 5: Check Approval (Passenger)

**Setup:**
- Switch back to User A (passenger)

**Steps:**
1. Tap **"Alerts"** tab
2. Look for new alert

**Expected Result:**
- New alert appears: **"Request Approved! 🎉"**
- Message: **"Your seat request has been approved"**
- Unread indicator visible
- Time: **"Just now"**

---

### Test 6: Decline Request (Driver)

**Setup:**
- Create a new request from User A
- Login as User B (driver)
- Navigate to booking detail

**Steps:**
1. Tap **"Decline"** button at bottom
2. Confirmation dialog appears
3. Tap **"Decline"** again to confirm

**Expected Result:**
- Orange toast: **"Request declined"**
- Screen closes
- Returns to alerts screen

---

### Test 7: Check Decline (Passenger)

**Setup:**
- Switch back to User A (passenger)

**Steps:**
1. Tap **"Alerts"** tab

**Expected Result:**
- New alert: **"Request Declined"**
- Message: **"Your seat request was declined"**

---

## Edge Case Testing

### Test 8: Duplicate Request Prevention

**Steps:**
1. Request a seat on a post
2. Without driver responding, try to request again on same post

**Expected Result:**
- Error message: **"Failed to send request. You may already have a pending request."**

---

### Test 9: Insufficient Seats Validation

**Setup:**
- Find a post with 2 seats available

**Steps:**
1. Tap "Request Seat"
2. Enter **3** seats
3. Tap "Confirm"

**Expected Result:**
- Red validation error below input: **"Only 2 seats available"**
- Cannot submit

---

### Test 10: Request from Post Detail Screen

**Steps:**
1. Tap on any driver post card
2. Opens Post Detail Screen
3. Scroll to bottom
4. Tap **"Request Seat"** button

**Expected Result:**
- Same dialog opens
- Works identically to home screen

---

## Visual Checks

### Request Seat Dialog
- ✅ Clean, modern design
- ✅ Seat icon in header
- ✅ Available seats info banner (blue)
- ✅ Number input with validation
- ✅ Notes textarea (3 lines)
- ✅ Cancel/Confirm buttons (confirm is green)
- ✅ Loading spinner when submitting

### Alerts Screen
- ✅ Different icons for different alert types
  - 👤 New request (green)
  - ✓ Approved (green)
  - ✗ Declined (red)
- ✅ Unread alerts have green dot
- ✅ Time formatting (e.g., "2m ago", "1h ago", "2d ago")
- ✅ Tap any alert navigates correctly

### Booking Detail Screen
- ✅ Passenger photo/avatar
- ✅ Passenger note in styled container
- ✅ Route visualization with dots and line
- ✅ Interactive Google Map
- ✅ Info cards with icons
- ✅ Approve/Decline buttons at bottom (sticky)
- ✅ Loading state when processing

---

## Database Verification

### Check Firestore Console

**booking_requests collection:**
```
- Should have documents with status: pending/approved/declined
- Each has passenger info, trip details, timestamps
```

**alerts collection:**
```
- Should have alerts for both driver and passenger
- Different types: bookingRequest, bookingApproved, bookingDeclined
- isRead: true/false
```

**posts collection:**
```
- seatsAvailable should decrease when approved
- Example: 4 → 2 (if 2 seats approved)
```

---

## Common Issues & Solutions

### Issue: Toast not showing
**Solution:** Check if you're using `ScaffoldMessenger.of(context)` correctly

### Issue: Alert not appearing in real-time
**Solution:** Check Firestore rules allow read/write, check internet connection

### Issue: Map not loading
**Solution:** Verify API key is set correctly in AndroidManifest.xml

### Issue: "User data not found" error
**Solution:** Ensure user is logged in and has profile in Firestore

### Issue: Seats not decreasing
**Solution:** Check `approveBookingRequest()` logic in BookingService

---

## Performance Testing

1. **Create 10+ alerts** - Check if list scrolls smoothly
2. **Request multiple seats** - Verify calculations are correct
3. **Rapid tap "Confirm"** - Should prevent double submission
4. **Poor internet** - Check loading states appear

---

## Success Criteria

✅ All 10 tests pass  
✅ No crashes or errors  
✅ Toasts appear and disappear correctly  
✅ Real-time alerts work instantly  
✅ Database updates correctly  
✅ Navigation flows smoothly  
✅ UI looks professional  
✅ Validations work properly  

---

## Ready to Test!

Hot reload your app and follow the tests above. Everything should work seamlessly!

If you encounter any issues, check:
1. Firestore rules
2. Internet connection
3. API keys
4. User authentication status
5. Console logs for errors

Happy testing! 🚀

