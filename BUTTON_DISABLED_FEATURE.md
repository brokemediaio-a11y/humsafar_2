# Request Seat Button - Disabled State Feature

## Overview

The "Request Seat" button now intelligently disables itself based on two conditions:
1. **User already requested** - If the current user has a pending request on this post
2. **Seats fully booked** - If all seats are taken (seatsAvailable = 0)

---

## Implementation

### Files Modified

1. **lib/widgets/post_card.dart**
   - Changed from `StatelessWidget` to `StatefulWidget`
   - Added `BookingService` and `AuthService`
   - Added `_checkPendingRequest()` method
   - Added button state management logic

2. **lib/screens/post_detail_screen.dart**
   - Added `BookingService`
   - Added `_checkPendingRequest()` method
   - Added button state management logic
   - Auto-refreshes status after successful request

---

## Button States

### 1. Normal State (Enabled)
```
┌──────────────────┐
│  Request Seat    │  ← Green button, clickable
└──────────────────┘
```
- Seats available > 0
- No pending request
- User can click to request

### 2. Request Pending
```
┌──────────────────┐
│ Request Pending  │  ← Gray button, disabled
└──────────────────┘
```
- User already has a pending request
- Button is disabled
- Text changes to "Request Pending"

### 3. Fully Booked
```
┌──────────────────┐
│  Fully Booked    │  ← Gray button, disabled
└──────────────────┘
```
- seatsAvailable = 0
- Button is disabled
- Text changes to "Fully Booked"

### 4. Loading State
```
┌──────────────────┐
│       ⟳          │  ← Spinner while checking
└──────────────────┘
```
- While checking for pending requests
- Shows loading spinner
- Prevents premature clicks

---

## Logic Flow

### On Screen Load:

```
1. Screen/Widget initializes
2. Call _checkPendingRequest()
3. Query Firestore for pending requests
4. Update state:
   - _hasPendingRequest = true/false
   - _isLoading = false
5. Button renders with correct state
```

### Button Press Logic:

```dart
VoidCallback? _getButtonAction() {
  if (_isButtonDisabled()) return null; // Disabled
  
  return widget.post.type == PostType.driver
      ? widget.onRequestSeat
      : widget.onOfferRide;
}

bool _isButtonDisabled() {
  if (widget.post.type == PostType.driver) {
    return (widget.post.seatsAvailable! <= 0) ||  // No seats
           _hasPendingRequest;                     // Already requested
  }
  return false;
}
```

### Button Text Logic:

```dart
Widget _buildButtonChild() {
  if (_isLoading) return CircularProgressIndicator();
  
  if (seatsAvailable <= 0) return Text('Fully Booked');
  if (_hasPendingRequest) return Text('Request Pending');
  
  return Text('Request Seat');
}
```

---

## User Experience

### Scenario 1: First Time Requesting
1. User sees driver post
2. Button shows "Request Seat" (green)
3. User taps button
4. Dialog opens
5. User confirms request
6. Button changes to "Request Pending" (gray)
7. Button is now disabled

### Scenario 2: Fully Booked Post
1. Driver has 2 seats
2. Two passengers request (both approved)
3. seatsAvailable becomes 0
4. All other users see "Fully Booked" (gray)
5. Button is disabled for everyone

### Scenario 3: Return After Request
1. User requests seat
2. User navigates away
3. User comes back to home screen
4. Button still shows "Request Pending" (persisted state)
5. Status is checked again on each screen load

---

## Database Queries

### Check Pending Request
```dart
Future<bool> hasPendingRequest(String userId, String postId) async {
  final query = await _bookingsCollection
      .where('postId', isEqualTo: postId)
      .where('passengerId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .get();
  
  return query.docs.isNotEmpty;
}
```

This query:
- Checks `booking_requests` collection
- Filters by post ID and user ID
- Only looks for 'pending' status
- Returns true if any pending request exists

---

## Performance Considerations

### Caching
- Each post card checks independently
- Query happens once on widget init
- Result is cached in widget state
- No redundant queries

### Refresh Strategy
- **Post Card**: Checks on mount
- **Post Detail Screen**: 
  - Checks on mount
  - Re-checks after successful request
  - Updates button immediately

### Network Efficiency
- Only queries when needed (driver posts only)
- Skips query for passenger posts
- Skips query if user not logged in

---

## Edge Cases Handled

### 1. User Not Logged In
```dart
if (currentUser == null) {
  setState(() => _isLoading = false);
  return; // Don't check, keep button enabled
}
```

### 2. Passenger Posts
```dart
if (widget.post.type != PostType.driver) {
  setState(() => _isLoading = false);
  return; // Passenger posts use "Offer Ride"
}
```

### 3. Null Seats
```dart
if (widget.post.seatsAvailable != null && 
    widget.post.seatsAvailable! <= 0)
```

### 4. Request Approved/Declined
- Status changes from 'pending' to 'approved'/'declined'
- `hasPendingRequest()` returns false
- Button becomes enabled again
- User can request again (if seats available)

---

## Visual Indicators

### Colors:
- **Green** (`Color(0xFF49977a)`) - Normal, enabled
- **Gray** (`Colors.grey.shade400`) - Disabled state
- **White** - Text color (both states)

### States:
- **Enabled**: Full saturation green
- **Disabled**: Desaturated gray
- **Loading**: Spinner with white color

---

## Testing Checklist

### Test 1: First Request
- [ ] Button shows "Request Seat"
- [ ] Button is green and clickable
- [ ] After request, button shows "Request Pending"
- [ ] Button is gray and disabled

### Test 2: Fully Booked
- [ ] Post with 1 seat available
- [ ] Another user requests and gets approved
- [ ] Your button shows "Fully Booked"
- [ ] Button is gray and disabled

### Test 3: Navigation
- [ ] Request seat on post A
- [ ] Navigate to another screen
- [ ] Come back to home
- [ ] Post A still shows "Request Pending"

### Test 4: Multiple Posts
- [ ] Request seat on post A
- [ ] Post A shows "Request Pending"
- [ ] Post B still shows "Request Seat"
- [ ] Can request on post B independently

### Test 5: Post Detail Screen
- [ ] Open driver post detail
- [ ] Button matches home screen state
- [ ] Request from detail screen
- [ ] Button updates to "Request Pending"

### Test 6: Driver Approves
- [ ] Driver approves your request
- [ ] Status changes from pending to approved
- [ ] Button becomes enabled again (if seats left)

### Test 7: Driver Declines
- [ ] Driver declines your request
- [ ] Status changes from pending to declined
- [ ] Button becomes enabled again
- [ ] Can request again

---

## Code Locations

### Post Card Widget
- **File**: `lib/widgets/post_card.dart`
- **Line**: 26-56 (state management)
- **Line**: 72-120 (button logic)
- **Line**: 325-340 (button UI)

### Post Detail Screen
- **File**: `lib/screens/post_detail_screen.dart`
- **Line**: 22-55 (state management)
- **Line**: 173-222 (button logic)
- **Line**: 720-737 (button UI)

### Booking Service
- **File**: `lib/services/booking_service.dart`
- **Line**: 228-242 (`hasPendingRequest` method)

---

## Summary

✅ **Smart button disabling**  
✅ **Visual feedback (text + color)**  
✅ **Prevents duplicate requests**  
✅ **Shows booking status**  
✅ **Real-time state management**  
✅ **Efficient database queries**  
✅ **Works on both home screen and detail screen**  
✅ **Auto-refreshes after actions**  

The button now provides clear, immediate feedback about:
- Whether user can request
- Current request status
- Seat availability

This prevents confusion and duplicate requests while providing excellent UX!

🚀 **Ready to test!**

Hot reload and try requesting a seat - you'll see the button instantly change to "Request Pending" and become disabled!

