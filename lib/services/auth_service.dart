import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'cloudinary_service.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        return null;
      }
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }
  
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser {
    final auth = _auth;
    if (auth == null) return null;
    return auth.currentUser;
  }

  // Auth state stream
  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    return auth.authStateChanges();
  }

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required UserModel userData,
    required File studentCardFrontFile,
    required File studentCardBackFile,
    File? cnicFrontFile,
    File? cnicBackFile,
    File? licenseFrontFile,
    File? licenseBackFile,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const AuthResult.error('Firebase is not initialized. Please configure Firebase for web.');
    }
    
    try {
      // Create Firebase Auth user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        // Update user data with uid
        userData = userData.copyWith(uid: uid);

        // Upload images to Cloudinary and get URLs
        final cloudinary = CloudinaryService();
        final imageUrls = await cloudinary.uploadAllIdImages(
          userId: uid,
          studentCardFront: studentCardFrontFile,
          studentCardBack: studentCardBackFile,
          cnicFront: cnicFrontFile,
          cnicBack: cnicBackFile,
          licenseFront: licenseFrontFile,
          licenseBack: licenseBackFile,
        );

        // Update user data to store URLs instead of raw image/base64
        userData = userData.copyWith(
          studentCardFront: imageUrls['student_card_front'],
          studentCardBack: imageUrls['student_card_back'],
          cnicFront: imageUrls['cnic_front'],
          cnicBack: imageUrls['cnic_back'],
          licenseFront: imageUrls['license_front'],
          licenseBack: imageUrls['license_back'],
        );

        // Save user data to Firestore
        final success = await _firestoreService.saveUser(userData);
        if (success) {
          return AuthResult.success(userCredential.user!);
        } else {
          // If Firestore save fails, delete the auth user
          try {
            await userCredential.user?.delete();
          } catch (e) {
            debugPrint('Error deleting auth user: $e');
          }
          return const AuthResult.error(
            'Failed to save user data. Firestore database may not exist. Please create it in Firebase Console.',
          );
        }
      }
      return const AuthResult.error('Failed to create user');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      // Provide more detailed error message
      final errorMsg = e.toString();
      if (errorMsg.contains('CONFIGURATION_NOT_FOUND') || 
          errorMsg.contains('reCAPTCHA')) {
        return const AuthResult.error(
          'Firebase Auth reCAPTCHA is not configured. Please enable it in Firebase Console.',
        );
      }
      if (errorMsg.contains('PERMISSION_DENIED') || 
          errorMsg.contains('Firestore API')) {
        return const AuthResult.error(
          'Firestore API is not enabled. Please enable it in Firebase Console.',
        );
      }
      return AuthResult.error('An error occurred: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const AuthResult.error('Firebase is not initialized. Please configure Firebase for web.');
    }
    
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user is verified
      if (userCredential.user != null) {
        final userData = await _firestoreService.getUser(userCredential.user!.uid);
        if (userData != null && !userData.isVerified) {
          // Sign out the user if not verified
          await auth.signOut();
          return const AuthResult.error('User not verified. Please wait for verification.');
        }
      }
      
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An error occurred: $code';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final User? user;
  final String? error;

  AuthResult.success(this.user) : error = null;
  const AuthResult.error(this.error) : user = null;

  bool get isSuccess => user != null;
}

