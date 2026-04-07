import 'package:flutter/material.dart';

const String _policyText = '''
PRIVACY POLICY (HUMSAFAR)

Effective date: April 5, 2026

App name: HumSafar (University Carpooling App)

Developer/Owner: NEXORDIS

Contact email: connect@nexordis.com

HumSafar ("we", "our", "us") is a carpooling app for university students. Users can sign up as a student (passenger) or a driver, upload verification documents, create ride posts, request/accept seats, and chat to coordinate rides. This Privacy Policy explains how we collect, use, share, and protect your information.

INFORMATION WE COLLECT

Account & Profile Information

We may collect:

• Name (first and last name)
• Email address
• Phone number
• Date of birth
• Student ID
• Verification status (verified/unverified)
• Profile image (if you add one)

Identity & Verification Documents (Sensitive)

To keep the community safe and confirm eligibility, we may collect and store:

• Student card images (front/back)
• National ID/CNIC images (front/back) (if applicable)
• Driver's license images (front/back) (for drivers)

These documents are used only for verification and safety.

Location Information

To support ride discovery and routes, we may collect:

• Approximate and/or precise location (when you use location features)
• Trip locations you enter (pickup/drop-off places)
• Coordinates (latitude/longitude) for ride posts and journeys

Ride & Booking Activity

We collect information you create or generate while using the app, such as:

• Ride posts you create (origin, destination, date/time, seats, price)
• Booking requests you make or receive
• Journey data (accepted rides, passenger lists, completion status)
• Ratings and reviews you give or receive
• Chat messages you send and receive
• Alerts you create or receive

Technical Information

We may automatically collect:

• Device information (device type, operating system, app version)
• Usage analytics (features used, time spent, crash reports)
• Network information (IP address, connection type)

HOW WE USE YOUR INFORMATION

We use your information to:

Provide Core Services

• Create and manage your account
• Verify your identity and eligibility (student/driver status)
• Enable ride posting, booking, and coordination
• Facilitate in-app messaging between users
• Process and track ride requests and journeys
• Calculate distances, routes, and pricing

Safety & Security

• Verify user identities through document checks
• Monitor for fraudulent or harmful activity
• Investigate reports of misconduct or safety issues
• Maintain community standards and safety

Communication

• Send you ride notifications and updates
• Deliver messages from other users
• Provide customer support
• Send important service announcements

App Improvement

• Analyze usage patterns to improve features
• Fix bugs and technical issues
• Develop new features based on user needs

HOW WE SHARE YOUR INFORMATION

With Other Users

When you use HumSafar, certain information is shared with other users to enable the service:

• Profile information (name, profile image, verification status, ratings)
• Ride details (for rides you post or join)
• Contact information (for coordinating rides)
• Location information (pickup/drop-off points for your rides)

With Service Providers

We may share information with trusted third parties who help us operate the app:

• Cloudinary for storing uploaded document images (verification documents)
• Google Maps Platform for displaying maps and calculating routes
• Firebase (Google) for app backend services (authentication, database, analytics)

For Legal Reasons

We may disclose information when required by law or to:

• Comply with legal processes (court orders, subpoenas)
• Protect our rights, property, or safety
• Protect the rights, property, or safety of our users
• Investigate or prevent illegal activities

DATA STORAGE & SECURITY

Where Your Data is Stored

• Firebase/Google Cloud (primary app data, authentication)
• Cloudinary for storing uploaded document images (verification documents)

Security Measures

We use reasonable administrative, technical, and organizational safeguards to protect your information. However, no method of transmission or storage is 100% secure. Please use a strong password and keep your login credentials confidential.

Data Retention

We retain your information for as long as your account is active or as needed to provide services. We may retain certain information for longer periods for legal, regulatory, or legitimate business purposes.

YOUR RIGHTS & CHOICES

Account Management

• Access: You can view and edit your profile information in the app
• Correction: You can update incorrect information through your profile settings
• Deletion: You can delete your account through the app settings

Communication Preferences

• You can manage notification settings in the app
• You cannot opt out of essential service communications (ride updates, safety alerts)

Location Sharing

• You can control location permissions through your device settings
• Some features may not work properly without location access

CHILDREN'S PRIVACY

HumSafar is intended for university students (typically 18+ years old). We do not knowingly collect information from children under 13. If we learn we have collected information from a child under 13, we will delete it promptly.

CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or by email. Your continued use of HumSafar after changes become effective constitutes acceptance of the updated policy.

CONTACT US

If you have questions about this Privacy Policy or your data, please contact us at:

Email: connect@nexordis.com

---

ACCOUNT DELETION POLICY (HUMSAFAR)

How to Delete Your Account

You can delete your account directly from the app:

• Go to Settings (or Profile) → Delete Account
• Confirm deletion

What Is Deleted

When you delete your account, we will remove:

• Your profile information (name, email, phone, etc.)
• Your verification documents (student card, CNIC, driver's license images)
• Your ride posts and booking requests
• Your journey history
• Your ratings and reviews (given and received)
• Your chat messages and conversations
• Your alerts and notifications

What May Be Retained

For legal, safety, or operational reasons, we may retain some information for a limited time:

• Anonymized usage analytics (without personal identifiers)
• Safety reports or investigations involving your account
• Financial records (if applicable) for accounting/legal compliance
• Backup data may take up to 30 days to be fully purged from our systems

Third-Party Data

Please note that data stored by third-party services may have their own retention policies:

• Cloudinary (document images) - we will request deletion
• Google/Firebase (app data) - follows our deletion requests
• Google Maps (location data) - managed by Google's privacy policy

Timeline

• Immediate: Your account becomes inaccessible and your profile is hidden from other users
• Within 7 days: Most personal data is deleted from active systems
• Within 30 days: Data is purged from backup systems and caches

Cannot Be Undone

Account deletion is permanent and cannot be reversed. You will need to create a new account if you want to use HumSafar again.

Questions

If you have questions about account deletion, contact us at connect@nexordis.com before proceeding.
''';

void showPolicyDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final maxHeight = MediaQuery.of(context).size.height * 0.85;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.maxFinite,
          height: maxHeight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Privacy Policy & Terms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _policyText,
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}