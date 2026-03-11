**☁ Cloudinary + Flutter**

**Complete Integration Guide**

_Image upload solution for HumSafar App signup flow_

**📋 What This Guide Covers**

This guide walks you through replacing base64 image storage in Firestore with Cloudinary hosted URLs. By the end, your signup flow will upload ID card images to Cloudinary, store only the resulting URLs in Firestore, and work reliably on all devices including high-resolution iPhones and Samsung flagships.

# **Overview - The Problem & Solution**

### **Why Base64 in Firestore Fails**

Firestore documents have a 1MB maximum size. A single high-resolution ID card photo compressed to JPEG can still easily be 200-400KB as base64 (base64 adds ~33% overhead). With 6 images in one document:

| **Scenario** | **Estimated Firestore doc size** |
| --- | --- |
| 6 images @ 100KB each (base64) | ~800KB ⚠ Near limit |
| 6 images @ 200KB each (base64) | ~1.6MB ✗ FAILS |
| iPhone 14 Pro photos (base64) | ~8-15MB ✗ FAILS badly |
| 6 Cloudinary URLs stored | ~600 bytes ✓ Tiny |

### **How Cloudinary Solves This**

- Images are uploaded directly to Cloudinary's CDN servers
- Cloudinary returns a short HTTPS URL per image
- You store only that URL string in Firestore (< 100 bytes)
- Your app fetches images back using the URL when needed
- Free tier: 25GB storage + 25GB bandwidth per month

# **Step-by-Step Implementation**

| **1** | **Create a Free Cloudinary Account** |
| --- | --- |

- Go to cloudinary.com and click Sign Up Free
- Fill in your name, email, password - no credit card required
- Verify your email address
- You will land on the Cloudinary Dashboard

**🔑 Credentials to Note from Dashboard**

On your Cloudinary dashboard homepage, you will see three values you need: Cloud Name (e.g. dxyz123abc), API Key (a long number), and API Secret (keep this private). Note all three down.

| **2** | **Create an Upload Preset** |
| --- | --- |

An upload preset allows your Flutter app to upload images without exposing your API secret in the app code.

- In Cloudinary dashboard, click the Settings gear icon (top right)
- Go to the Upload tab
- Scroll down to Upload presets and click Add upload preset
- Set the following values:
  - Signing mode → Unsigned
  - Preset name → humsafar_ids (you can choose any name)
  - Folder → humsafar/ids (optional, keeps files organized)
- Click Save

**⚠ Security Note**

Unsigned presets are fine for a student FYP. For a production app shipping to real users, you would use signed uploads via a backend endpoint so your API secret is never in the app. The unsigned approach used here is intentional for simplicity.

| **3** | **Add Dependencies to pubspec.yaml** |
| --- | --- |

Open your pubspec.yaml file and add the following packages under dependencies:

dependencies:

flutter:

sdk: flutter

\# Already in your project:

firebase_core: ^3.x.x

firebase_auth: ^5.x.x

cloud_firestore: ^5.x.x

\# Add these if not already present:

http: ^1.2.0

flutter_image_compress: ^2.3.0

Then run this in your terminal:

flutter pub get

| **4** | **Create the Cloudinary Service File** |
| --- | --- |

Create a new file at:

lib/services/cloudinary_service.dart

Paste the complete code below into that file. Replace YOUR_CLOUD_NAME and YOUR_PRESET_NAME with the values from Step 1 and Step 2:

import 'dart:io';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_image_compress/flutter_image_compress.dart';

class CloudinaryService {

// Replace these with YOUR values from Cloudinary dashboard

static const String \_cloudName = 'YOUR_CLOUD_NAME';

static const String \_uploadPreset = 'YOUR_PRESET_NAME';

/// Compress a single image and upload to Cloudinary.

/// Returns the secure HTTPS URL of the uploaded image.

Future&lt;String&gt; uploadIdImage({

required File imageFile,

required String userId,

required String imageType,

}) async {

// Step A: Compress the image before uploading

final compressed = await FlutterImageCompress.compressWithFile(

imageFile.absolute.path,

minWidth: 1000,

minHeight: 700,

quality: 75,

format: CompressFormat.jpeg,

);

if (compressed == null) {

throw Exception('Image compression failed for \$imageType');

}

// Step B: Build the Cloudinary upload URL

final uri = Uri.parse(

'<https://api.cloudinary.com/v1_1/\$\_cloudName/image/upload>',

);

// Step C: Build multipart request

final request = http.MultipartRequest('POST', uri)

..fields\['upload_preset'\] = \_uploadPreset

..fields\['folder'\] = 'humsafar/users/\$userId'

..fields\['public_id'\] = imageType

..files.add(http.MultipartFile.fromBytes(

'file',

compressed,

filename: '\$imageType.jpg',

));

// Step D: Send and parse response

final streamedResponse = await request.send();

final responseBody = await streamedResponse.stream.bytesToString();

if (streamedResponse.statusCode != 200) {

throw Exception('Upload failed for \$imageType: \$responseBody');

}

final json = jsonDecode(responseBody);

return json\['secure_url'\] as String;

}

/// Upload all ID card images. Pass null for license images

/// if the user does not have a car.

Future&lt;Map<String, String&gt;> uploadAllIdImages({

required String userId,

required File studentIdBack,

required File nationalIdFront,

required File nationalIdBack,

File? licenseFront,

File? licenseBack,

}) async {

final results = &lt;String, String&gt;{};

// Upload sequentially with clear error messages per image

results\['student_id_back'\] = await uploadIdImage(

imageFile: studentIdBack,

userId: userId,

imageType: 'student_id_back',

);

results\['national_id_front'\] = await uploadIdImage(

imageFile: nationalIdFront,

userId: userId,

imageType: 'national_id_front',

);

results\['national_id_back'\] = await uploadIdImage(

imageFile: nationalIdBack,

userId: userId,

imageType: 'national_id_back',

);

if (licenseFront != null) {

results\['license_front'\] = await uploadIdImage(

imageFile: licenseFront,

userId: userId,

imageType: 'license_front',

);

}

if (licenseBack != null) {

results\['license_back'\] = await uploadIdImage(

imageFile: licenseBack,

userId: userId,

imageType: 'license_back',

);

}

return results;

}

}

| **5** | **Update Your Signup Method** |
| --- | --- |

Find your existing signup method (likely in your auth service or signup screen). Replace the base64 image handling with the Cloudinary service. Here is the complete updated pattern:

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../services/cloudinary_service.dart';

Future&lt;void&gt; signUp({

required String email,

required String password,

required File studentIdBack,

required File nationalIdFront,

required File nationalIdBack,

bool hasCar = false,

File? licenseFront,

File? licenseBack,

}) async {

UserCredential? credential;

try {

// ── Step 1: Create Firebase Auth user ──────────────

credential = await FirebaseAuth.instance

.createUserWithEmailAndPassword(

email: email,

password: password,

);

final userId = credential.user!.uid;

// ── Step 2: Upload images to Cloudinary ────────────

// This replaces ALL your base64 encoding logic

final cloudinary = CloudinaryService();

final imageUrls = await cloudinary.uploadAllIdImages(

userId: userId,

studentIdBack: studentIdBack,

nationalIdFront: nationalIdFront,

nationalIdBack: nationalIdBack,

licenseFront: hasCar ? licenseFront : null,

licenseBack: hasCar ? licenseBack : null,

);

// ── Step 3: Save small URL strings to Firestore ────

// The Firestore document is now tiny (< 1KB)

await FirebaseFirestore.instance

.collection('users')

.doc(userId)

.set({

'email': email,

'hasCar': hasCar,

'idImages': imageUrls, // Map of imageType -> URL

'createdAt': FieldValue.serverTimestamp(),

'isVerified': false,

});

print('Signup complete for user: \$userId');

} catch (e) {

// If Firestore save fails after images were uploaded,

// delete the auth user to keep state clean

if (credential != null) {

await credential.user?.delete();

}

print('Signup error: \$e');

rethrow;

}

}

| **6** | **Add a Progress Indicator in Your UI** |
| --- | --- |

Uploading 6 images takes a few seconds. You must show the user that something is happening. Without this, users tap the button multiple times thinking it froze.

Add a loading state to your signup screen widget:

// In your signup screen State class:

bool \_isUploading = false;

String \_uploadStatus = '';

// Replace your signup button with this:

\_isUploading

? Column(

children: \[

const CircularProgressIndicator(),

const SizedBox(height: 12),

Text(\_uploadStatus, style: const TextStyle(color: Colors.grey)),

\],

)

: ElevatedButton(

onPressed: \_handleSignup,

child: const Text('Create Account'),

),

// In your \_handleSignup method:

Future&lt;void&gt; \_handleSignup() async {

setState(() {

\_isUploading = true;

\_uploadStatus = 'Uploading documents...';

});

try {

await signUp(/\* your params \*/);

// navigate to next screen

} catch (e) {

setState(() => \_isUploading = false);

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text('Signup failed: \$e')),

);

}

}

| **7** | **Fetching Images Back in Your App** |
| --- | --- |

When you need to display a user's uploaded ID image anywhere in the app, fetch the URL from Firestore and use it directly with Image.network:

// Fetch the user document

final doc = await FirebaseFirestore.instance

.collection('users')

.doc(userId)

.get();

final data = doc.data()!;

final imageUrls = Map&lt;String, String&gt;.from(data\['idImages'\]);

// Display an image - Cloudinary URLs work directly

Image.network(

imageUrls\['national_id_front'\]!,

fit: BoxFit.cover,

loadingBuilder: (context, child, progress) {

if (progress == null) return child;

return const CircularProgressIndicator();

},

errorBuilder: (context, error, stack) {

return const Icon(Icons.broken_image);

},

),

# **Troubleshooting**

| **Error** | **Fix** |
| --- | --- |
| Upload failed: 401 Unauthorized | Your upload preset is set to Signed. Change it to Unsigned in Cloudinary Settings → Upload. |
| Upload failed: 400 Invalid upload preset | The preset name in your Dart code does not match the name you created. Check for typos and case sensitivity. |
| CloudName not found | Check \_cloudName in cloudinary_service.dart matches your Cloud Name exactly from the dashboard. |
| Image loads broken in app | The URL in Firestore may be http not https. Use json\['secure_url'\] not json\['url'\] - already done in the guide code. |
| Compression returns null | The source File path may be wrong. Add a null-check and log imageFile.absolute.path before compressing. |
| Signup works but no images in Cloudinary | Check your Cloudinary Media Library. Try the humsafar/ids folder. The upload may be going to a different folder. |

# **Resulting Firestore Data Structure**

After a successful signup, your Firestore user document will look like this - tiny and fast:

{

"email": "<user@example.com>",

"hasCar": true,

"isVerified": false,

"createdAt": Timestamp,

"idImages": {

"student_id_back": "<https://res.cloudinary.com/dxyz/image/upload/v1/humsafar/users/uid123/student_id_back.jpg>",

"national_id_front": "<https://res.cloudinary.com/dxyz/image/upload/v1/humsafar/users/uid123/national_id_front.jpg>",

"national_id_back": "<https://res.cloudinary.com/dxyz/image/upload/v1/humsafar/users/uid123/national_id_back.jpg>",

"license_front": "<https://res.cloudinary.com/dxyz/image/upload/v1/humsafar/users/uid123/license_front.jpg>",

"license_back": "<https://res.cloudinary.com/dxyz/image/upload/v1/humsafar/users/uid123/license_back.jpg>"

}

}

**✅ Document Size Comparison**

Before (base64): 2-15MB per document - fails Firestore's 1MB limit on high-res devices. After (URLs): ~800 bytes per document - 99.9% smaller, zero timeouts, works on all devices.

# **Final Checklist**

- Cloudinary account created at cloudinary.com
- Cloud name, API key, API secret noted from dashboard
- Upload preset created with Unsigned signing mode
- http and flutter_image_compress added to pubspec.yaml
- flutter pub get run successfully
- lib/services/cloudinary_service.dart created with your credentials
- Signup method updated to use CloudinaryService
- Loading indicator added to signup button
- Tested on at least one high-resolution device (iPhone or Samsung)
- Images appear in Cloudinary Media Library after test signup
- Firestore document shows URL strings, not base64 blobs

_HumSafar App - FYP Development Guide_