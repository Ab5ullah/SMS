import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/school.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword(
      String email, String password) async {
    try {
      // Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Login failed. Please try again.',
        };
      }

      // Get user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User data not found. Please contact administrator.',
        };
      }

      AppUser appUser = AppUser.fromMap(
        userDoc.data() as Map<String, dynamic>,
        user.uid,
      );

      // Verify school license
      DocumentSnapshot schoolDoc =
          await _firestore.collection('schools').doc(appUser.schoolId).get();

      if (!schoolDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'School information not found.',
        };
      }

      School school = School.fromMap(
        schoolDoc.data() as Map<String, dynamic>,
        appUser.schoolId,
      );

      // Check license status
      if (!school.isLicenseActive) {
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Your school license has expired. Please contact support to renew.',
          'licenseExpired': true,
        };
      }

      AppLogger.info('User signed in successfully: ${user.email}');

      return {
        'success': true,
        'user': appUser,
        'school': school,
      };
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Error: ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      AppLogger.error('Sign in error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please check your internet connection.',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Sign out error: $e');
      rethrow;
    }
  }

  // Get current user data
  Future<AppUser?> getCurrentUserData() async {
    try {
      User? user = currentUser;
      if (user == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return AppUser.fromMap(
        userDoc.data() as Map<String, dynamic>,
        user.uid,
      );
    } catch (e) {
      AppLogger.error('Get current user error: $e');
      return null;
    }
  }

  // Get school data
  Future<School?> getSchoolData(String schoolId) async {
    try {
      DocumentSnapshot schoolDoc =
          await _firestore.collection('schools').doc(schoolId).get();

      if (!schoolDoc.exists) return null;

      return School.fromMap(
        schoolDoc.data() as Map<String, dynamic>,
        schoolId,
      );
    } catch (e) {
      AppLogger.error('Get school data error: $e');
      return null;
    }
  }

  // Verify license (for periodic checks)
  Future<bool> verifyLicense(String schoolId) async {
    try {
      School? school = await getSchoolData(schoolId);
      if (school == null) return false;
      return school.isLicenseActive;
    } catch (e) {
      AppLogger.error('License verification error: $e');
      // Allow temporary offline use
      return true;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }
}
