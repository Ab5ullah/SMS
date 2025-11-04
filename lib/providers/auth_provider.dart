import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/school.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  School? _currentSchool;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  School? get currentSchool => _currentSchool;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result =
          await _authService.signInWithEmailPassword(email, password);

      if (result['success']) {
        _currentUser = result['user'];
        _currentSchool = result['school'];

        // Save school ID to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('schoolId', _currentSchool!.id);
        await prefs.setString('userId', _currentUser!.id);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _currentSchool = null;

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('schoolId');
    await prefs.remove('userId');

    notifyListeners();
  }

  // Load saved session
  Future<bool> loadSavedSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final schoolId = prefs.getString('schoolId');

      if (schoolId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get user data
      _currentUser = await _authService.getCurrentUserData();
      if (_currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get school data and verify license
      _currentSchool = await _authService.getSchoolData(schoolId);
      if (_currentSchool == null || !_currentSchool!.isLicenseActive) {
        await signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify license
  Future<bool> verifyLicense() async {
    if (_currentSchool == null) return false;
    return await _authService.verifyLicense(_currentSchool!.id);
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
