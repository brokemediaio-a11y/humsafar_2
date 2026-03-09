# Next.js Admin Dashboard - Complete Build Prompt

## Project Overview

Build a Next.js admin dashboard application for the HumSafar ride-sharing app. This dashboard allows administrators to verify new user registrations by reviewing their uploaded documents (student ID cards, CNIC, and driving licenses) and approving or rejecting them.

---

## Technical Requirements

### Framework & Setup
- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Firebase**: Firebase Admin SDK or Firebase Web SDK v9+ (modular)
- **Authentication**: Simple hardcoded admin login (no Firebase Auth needed for admin)

### Firebase Configuration

**Project Details:**
- **Project ID**: `humsafar-eb7f9`
- **Database**: Cloud Firestore
- **Collection Name**: `users`

**Firebase Setup:**
You'll need to create a Firebase configuration file. The app uses the same Firebase project as the Flutter mobile app.

**Firebase Config File Structure:**
```typescript
// lib/firebase/config.ts
const firebaseConfig = {
  apiKey: "AIzaSyD1L3xJIypZ1vU5z3lEiXj0LMOs8mOu6uQ", // From GoogleService-Info.plist
  authDomain: "humsafar-eb7f9.firebaseapp.com",
  projectId: "humsafar-eb7f9",
  storageBucket: "humsafar-eb7f9.firebasestorage.app",
  messagingSenderId: "819096727879",
  appId: "1:819096727879:ios:fe6c6546d7eb2be1f9dc62"
};
```

---

## Database Schema

### Users Collection (`users`)

Each user document contains:

```typescript
interface User {
  uid: string;                    // Firebase Auth UID
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  cnic: string;                    // CNIC number
  dateOfBirth: string;            // ISO 8601 date string
  studentId: string;
  studentCardFront: string | null; // Base64 encoded image
  studentCardBack: string | null;  // Base64 encoded image
  cnicFront: string | null;        // Base64 encoded image (optional)
  cnicBack: string | null;         // Base64 encoded image (optional)
  licenseFront: string | null;    // Base64 encoded image (optional)
  licenseBack: string | null;     // Base64 encoded image (optional)
  hasCar: boolean;
  createdAt: string;              // ISO 8601 date string
  isVerified: boolean;           // VERIFICATION STATUS - default: false
  profileImageUrl?: string | null;
  updatedAt?: string | null;
  rating: number;
  totalRides: number;
}
```

**Important Notes:**
- All images are stored as **base64 encoded strings** in the database
- Images start with `data:image/jpeg;base64,` or `data:image/png;base64,` prefix
- `isVerified` field determines if user can login (false = not verified, true = verified)
- New users are created with `isVerified: false` by default

---

## Application Features

### 1. Admin Login Page

**Route**: `/` or `/login`

**Requirements:**
- Simple login form with username and password fields
- **Hardcoded credentials**:
  - Username: `admin`
  - Password: `admin`
- No Firebase Authentication needed for admin
- Store login state in localStorage or sessionStorage
- Redirect to dashboard after successful login
- Show error message for invalid credentials
- Simple, clean UI with Tailwind CSS

**UI Elements:**
- Logo/App name: "HumSafar Admin"
- Username input field
- Password input field (masked)
- Login button
- Error message display area

---

### 2. Admin Dashboard (Main Page)

**Route**: `/dashboard` (protected - requires login)

**Requirements:**
- Display a table/list of all users from Firestore `users` collection
- Show only users where `isVerified === false` (unverified users)
- Real-time updates using Firestore listeners
- Each user row should display:
  - Full Name (firstName + lastName)
  - Email
  - Phone Number
  - Student ID
  - CNIC Number
  - Date of Birth
  - Registration Date (createdAt)
  - Verification Status (Badge: "Pending" or "Verified")
  - Action Button: "Verify User" button

**Table Structure:**
```
| Name | Email | Phone | Student ID | CNIC | Status | Actions |
|------|-------|-------|------------|------|--------|--------|
| John Doe | john@email.com | 1234567890 | STU001 | 35202-... | Pending | [Verify] |
```

**Features:**
- Responsive design (works on desktop and tablet)
- Search/filter functionality (optional but recommended)
- Sort by registration date (newest first)
- Loading states while fetching data
- Empty state when no unverified users

---

### 3. User Detail Modal/Page

**Trigger**: Click on a user row or "View Details" button

**Requirements:**
- Display all user information
- **CRITICAL**: Display all uploaded document images
  - Student Card Front (required)
  - Student Card Back (required)
  - CNIC Front (if available)
  - CNIC Back (if available)
  - License Front (if hasCar === true)
  - License Back (if hasCar === true)

**Image Display:**
- Images are stored as base64 strings in the database
- You need to decode and display them
- Use `<img>` tag with `src` set to the base64 string directly
- Example: `<img src={user.studentCardFront} alt="Student Card Front" />`
- Add image viewer with zoom capability (optional but recommended)
- Show image labels clearly

**Layout:**
```
User Information Section:
- Full Name
- Email
- Phone
- CNIC
- Student ID
- Date of Birth
- Has Car: Yes/No

Documents Section:
[Student Card Front Image] [Student Card Back Image]
[CNIC Front Image] [CNIC Back Image]
[License Front Image] [License Back Image] (if hasCar)

Action Buttons:
[Verify User] [Reject] (optional)
```

---

### 4. Verify User Functionality

**Requirements:**
- "Verify User" button in the table row or detail view
- When clicked, update the user document in Firestore:
  - Set `isVerified: true`
  - Update `updatedAt: new Date().toISOString()`
- Show confirmation dialog before verifying
- After verification:
  - Remove user from unverified list (or update status)
  - Show success message
  - Optionally send notification (not required)

**Firestore Update:**
```typescript
await updateDoc(doc(db, 'users', userId), {
  isVerified: true,
  updatedAt: new Date().toISOString()
});
```

---

## Technical Implementation Details

### Firebase Setup

**Install Dependencies:**
```bash
npm install firebase
npm install @types/node
```

**Firebase Initialization:**
```typescript
// lib/firebase/config.ts
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyD1L3xJIypZ1vU5z3lEiXj0LMOs8mOu6uQ",
  authDomain: "humsafar-eb7f9.firebaseapp.com",
  projectId: "humsafar-eb7f9",
  storageBucket: "humsafar-eb7f9.firebasestorage.app",
  messagingSenderId: "819096727879",
  appId: "1:819096727879:ios:fe6c6546d7eb2be1f9dc62"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
```

### Firestore Queries

**Get Unverified Users:**
```typescript
import { collection, query, where, getDocs, onSnapshot } from 'firebase/firestore';

// Get all unverified users
const q = query(
  collection(db, 'users'),
  where('isVerified', '==', false)
);

// Real-time listener
onSnapshot(q, (snapshot) => {
  const users = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  // Update state
});
```

**Update User Verification:**
```typescript
import { doc, updateDoc } from 'firebase/firestore';

const verifyUser = async (userId: string) => {
  await updateDoc(doc(db, 'users', userId), {
    isVerified: true,
    updatedAt: new Date().toISOString()
  });
};
```

### Base64 Image Handling

**Displaying Images:**
```typescript
// The base64 string from Firestore can be used directly
<img 
  src={user.studentCardFront} 
  alt="Student Card Front"
  className="w-full h-auto"
/>

// If the base64 string doesn't have the data URL prefix, add it:
const imageSrc = user.studentCardFront?.startsWith('data:') 
  ? user.studentCardFront 
  : `data:image/jpeg;base64,${user.studentCardFront}`;
```

---

## UI/UX Requirements

### Design Style
- Modern, clean, professional admin dashboard
- Use Tailwind CSS for styling
- Color scheme: 
  - Primary: Green (#49977a) - matches mobile app
  - Success: Green shades
  - Warning: Orange/Yellow
  - Error: Red
- Responsive design (mobile, tablet, desktop)

### Components Needed
1. **Login Page**
   - Centered form
   - Clean input fields
   - Submit button

2. **Dashboard Layout**
   - Header with app name and logout button
   - Main content area with user table
   - Sidebar (optional)

3. **User Table**
   - Sortable columns
   - Responsive table (scrollable on mobile)
   - Status badges
   - Action buttons

4. **User Detail Modal/Page**
   - Modal overlay or separate page
   - Image gallery
   - User info cards
   - Action buttons

5. **Loading States**
   - Skeleton loaders
   - Spinner for actions

6. **Empty States**
   - "No unverified users" message
   - Friendly illustration or icon

---

## File Structure

```
admin-dashboard/
├── app/
│   ├── layout.tsx
│   ├── page.tsx (login)
│   ├── dashboard/
│   │   └── page.tsx
│   └── api/ (if needed)
├── components/
│   ├── LoginForm.tsx
│   ├── UserTable.tsx
│   ├── UserDetailModal.tsx
│   ├── ImageViewer.tsx
│   └── Layout/
│       ├── Header.tsx
│       └── Sidebar.tsx
├── lib/
│   ├── firebase/
│   │   ├── config.ts
│   │   └── firestore.ts
│   └── utils/
│       ├── auth.ts
│       └── imageUtils.ts
├── types/
│   └── user.ts
├── tailwind.config.js
├── next.config.js
└── package.json
```

---

## Security Considerations

1. **Admin Authentication**: 
   - Hardcoded credentials are fine for MVP
   - For production, consider proper authentication

2. **Firestore Security Rules**:
   - The admin dashboard will need read/write access to users collection
   - Ensure Firestore rules allow admin operations (you may need to configure this separately)

3. **Environment Variables**:
   - Store Firebase config in `.env.local` (optional, but recommended)
   - Never commit sensitive data to git

---

## Additional Features (Optional but Recommended)

1. **Search/Filter**:
   - Search by name, email, student ID
   - Filter by registration date

2. **Pagination**:
   - If many users, add pagination

3. **Bulk Actions**:
   - Verify multiple users at once

4. **User Statistics**:
   - Total users
   - Verified vs Unverified count
   - Recent registrations

5. **Image Zoom/Viewer**:
   - Click image to view full size
   - Zoom in/out functionality

6. **Export Functionality**:
   - Export user list to CSV

---

## Testing Checklist

- [ ] Admin can login with hardcoded credentials
- [ ] Dashboard displays all unverified users
- [ ] User detail view shows all information
- [ ] All document images display correctly (base64 decoding)
- [ ] Verify button updates user status in Firestore
- [ ] Verified users disappear from unverified list
- [ ] Real-time updates work (new users appear automatically)
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Error handling for network issues
- [ ] Loading states display correctly

---

## Deployment

**Recommended Platforms:**
- Vercel (easiest for Next.js)
- Netlify
- Firebase Hosting

**Environment Setup:**
- Add Firebase config as environment variables
- Set up build command: `npm run build`
- Set up start command: `npm start`

---

## Summary

Build a Next.js admin dashboard that:
1. ✅ Has a simple login page (username: admin, password: admin)
2. ✅ Connects to Firebase Firestore project `humsafar-eb7f9`
3. ✅ Reads from `users` collection
4. ✅ Displays all unverified users (`isVerified === false`)
5. ✅ Shows user information and uploaded document images
6. ✅ Images are stored as base64 - decode and display them
7. ✅ Has a "Verify User" button that updates `isVerified: true` in Firestore
8. ✅ Uses real-time Firestore listeners for live updates
9. ✅ Modern, responsive UI with Tailwind CSS
10. ✅ Proper error handling and loading states

**Key Points:**
- Same Firebase project as Flutter app
- Images are base64 encoded strings
- Update `isVerified` field to verify users
- Simple hardcoded admin login
- Real-time updates using Firestore listeners

---

## Example Code Snippets

### Get Unverified Users
```typescript
'use client';
import { useEffect, useState } from 'react';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';

export default function Dashboard() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(
      collection(db, 'users'),
      where('isVerified', '==', false)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const userData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setUsers(userData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // ... rest of component
}
```

### Verify User Function
```typescript
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';

export const verifyUser = async (userId: string) => {
  try {
    await updateDoc(doc(db, 'users', userId), {
      isVerified: true,
      updatedAt: new Date().toISOString()
    });
    return { success: true };
  } catch (error) {
    console.error('Error verifying user:', error);
    return { success: false, error };
  }
};
```

### Display Base64 Image
```typescript
// Component
<img 
  src={user.studentCardFront || '/placeholder.png'} 
  alt="Student Card Front"
  className="w-full max-w-md h-auto rounded-lg shadow-md"
  onError={(e) => {
    e.currentTarget.src = '/placeholder.png';
  }}
/>
```

---

**This prompt contains all the information needed to build the admin dashboard. Follow it step by step and you'll have a fully functional verification system!**

