import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/school.dart';
import '../utils/logger.dart';

class LicenseService {
  static final LicenseService instance = LicenseService._init();
  LicenseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _licenseCheckTimer;

  // License check interval (24 hours)
  static const Duration _checkInterval = Duration(hours: 24);

  // Grace period when offline (14 days)
  static const Duration _gracePeriod = Duration(days: 14);

  // Warning thresholds (days before expiry)
  static const List<int> _warningThresholds = [30, 14, 7, 3, 1];

  // Callbacks
  Function(LicenseStatus)? onLicenseStatusChanged;
  Function(int)? onWarningTriggered; // Days remaining
  Function()? onLicenseExpired;

  /// Initialize license service with periodic checks
  Future<void> initialize({String? schoolId}) async {
    AppLogger.info('Initializing License Service...');

    // Perform initial check
    if (schoolId != null) {
      await checkLicense(schoolId);
    }

    // Start periodic checks (every 24 hours)
    startPeriodicCheck(schoolId);

    AppLogger.info('License Service initialized successfully');
  }

  /// Start periodic license verification
  void startPeriodicCheck(String? schoolId) {
    _licenseCheckTimer?.cancel();

    if (schoolId == null) {
      AppLogger.warning('Cannot start periodic check: schoolId is null');
      return;
    }

    _licenseCheckTimer = Timer.periodic(_checkInterval, (timer) async {
      AppLogger.info('Performing periodic license check...');
      await checkLicense(schoolId);
    });

    AppLogger.info('Periodic license check started (every ${_checkInterval.inHours} hours)');
  }

  /// Stop periodic license checks
  void stopPeriodicCheck() {
    _licenseCheckTimer?.cancel();
    AppLogger.info('Periodic license check stopped');
  }

  /// Check license status
  Future<LicenseCheckResult> checkLicense(String schoolId) async {
    try {
      // Try to fetch from Firestore
      final school = await _fetchSchoolFromFirestore(schoolId);

      if (school != null) {
        // Update last check timestamp
        await _updateLastCheckTime();

        // Validate license
        final result = _validateLicense(school);

        // Save license info locally
        await _saveLicenseInfo(school);

        // Trigger callbacks
        _notifyStatusChange(result.status);

        // Check for warnings
        if (result.daysRemaining != null && result.daysRemaining! > 0) {
          _checkWarningThresholds(result.daysRemaining!);
        }

        // Handle expiry
        if (result.status == LicenseStatus.expired) {
          onLicenseExpired?.call();
        }

        return result;
      } else {
        // School not found online, check grace period
        return await _checkGracePeriod(schoolId);
      }
    } catch (e) {
      AppLogger.error('Error checking license: $e');
      // On error, check grace period
      return await _checkGracePeriod(schoolId);
    }
  }

  /// Fetch school from Firestore
  Future<School?> _fetchSchoolFromFirestore(String schoolId) async {
    try {
      final doc = await _firestore.collection('schools').doc(schoolId).get();

      if (doc.exists) {
        return School.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching school from Firestore: $e');
      return null;
    }
  }

  /// Validate license based on school data
  LicenseCheckResult _validateLicense(School school) {
    final now = DateTime.now();
    final expiryDate = school.expiryDate;

    // Check if expired
    if (expiryDate.isBefore(now)) {
      final daysOverdue = now.difference(expiryDate).inDays;
      return LicenseCheckResult(
        status: LicenseStatus.expired,
        message: 'License expired $daysOverdue days ago',
        school: school,
        daysRemaining: -daysOverdue,
      );
    }

    // Check license status from Firestore
    if (school.licenseStatus == 'active') {
      final daysRemaining = expiryDate.difference(now).inDays;
      return LicenseCheckResult(
        status: LicenseStatus.active,
        message: 'License is active ($daysRemaining days remaining)',
        school: school,
        daysRemaining: daysRemaining,
      );
    } else if (school.licenseStatus == 'expired') {
      return LicenseCheckResult(
        status: LicenseStatus.expired,
        message: 'License has been marked as expired',
        school: school,
      );
    } else {
      return LicenseCheckResult(
        status: LicenseStatus.invalid,
        message: 'Invalid license status: ${school.licenseStatus}',
        school: school,
      );
    }
  }

  /// Check grace period when offline
  Future<LicenseCheckResult> _checkGracePeriod(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get last successful check time
    final lastCheckStr = prefs.getString('last_license_check');
    if (lastCheckStr == null) {
      return LicenseCheckResult(
        status: LicenseStatus.invalid,
        message: 'No previous license check found. Please connect to the internet.',
      );
    }

    final lastCheck = DateTime.parse(lastCheckStr);
    final now = DateTime.now();
    final daysSinceCheck = now.difference(lastCheck).inDays;

    // Check if within grace period
    if (daysSinceCheck <= _gracePeriod.inDays) {
      final graceDaysRemaining = _gracePeriod.inDays - daysSinceCheck;

      // Get cached license info
      final cachedLicenseStatus = prefs.getString('cached_license_status');
      final cachedExpiryStr = prefs.getString('cached_expiry_date');

      if (cachedLicenseStatus == 'active' && cachedExpiryStr != null) {
        final cachedExpiry = DateTime.parse(cachedExpiryStr);

        // Check if cached license is still valid
        if (cachedExpiry.isAfter(now)) {
          return LicenseCheckResult(
            status: LicenseStatus.graceperiod,
            message: 'Offline mode: $graceDaysRemaining days remaining in grace period',
            daysRemaining: graceDaysRemaining,
          );
        } else {
          return LicenseCheckResult(
            status: LicenseStatus.expired,
            message: 'License expired. Please connect to the internet.',
          );
        }
      }
    }

    // Grace period exceeded
    return LicenseCheckResult(
      status: LicenseStatus.graceperiodExceeded,
      message: 'Grace period exceeded. Please connect to the internet to verify license.',
    );
  }

  /// Update last check timestamp
  Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_license_check', DateTime.now().toIso8601String());
  }

  /// Save license info locally for offline access
  Future<void> _saveLicenseInfo(School school) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_license_status', school.licenseStatus);
    await prefs.setString('cached_expiry_date', school.expiryDate.toIso8601String());
    await prefs.setString('cached_school_name', school.name);
  }

  /// Check if warning thresholds are crossed
  void _checkWarningThresholds(int daysRemaining) {
    for (var threshold in _warningThresholds) {
      if (daysRemaining == threshold) {
        AppLogger.warning('License warning: $daysRemaining days remaining');
        onWarningTriggered?.call(daysRemaining);
        break;
      }
    }
  }

  /// Notify listeners of status change
  void _notifyStatusChange(LicenseStatus status) {
    onLicenseStatusChanged?.call(status);
  }

  /// Check if license is valid
  Future<bool> isLicenseValid(String schoolId) async {
    final result = await checkLicense(schoolId);
    return result.status == LicenseStatus.active ||
           result.status == LicenseStatus.graceperiod;
  }

  /// Get cached license info
  Future<Map<String, String?>> getCachedLicenseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'status': prefs.getString('cached_license_status'),
      'expiryDate': prefs.getString('cached_expiry_date'),
      'schoolName': prefs.getString('cached_school_name'),
      'lastCheck': prefs.getString('last_license_check'),
    };
  }

  /// Manually trigger license check
  Future<LicenseCheckResult> manualCheck(String schoolId) async {
    AppLogger.info('Manual license check triggered');
    return await checkLicense(schoolId);
  }

  /// Admin override (for testing or emergency access)
  Future<void> adminOverride({
    required String adminPassword,
    required Duration overrideDuration,
  }) async {
    // Verify admin password (this should be secured properly)
    const String expectedPassword = 'ADMIN_OVERRIDE_2024'; // Change this in production

    if (adminPassword != expectedPassword) {
      throw Exception('Invalid admin password');
    }

    final prefs = await SharedPreferences.getInstance();
    final overrideUntil = DateTime.now().add(overrideDuration);

    await prefs.setString('admin_override_until', overrideUntil.toIso8601String());
    AppLogger.warning('Admin override activated until: $overrideUntil');
  }

  /// Check if admin override is active
  Future<bool> isAdminOverrideActive() async {
    final prefs = await SharedPreferences.getInstance();
    final overrideStr = prefs.getString('admin_override_until');

    if (overrideStr == null) return false;

    final overrideUntil = DateTime.parse(overrideStr);
    final isActive = DateTime.now().isBefore(overrideUntil);

    if (!isActive) {
      // Clear expired override
      await prefs.remove('admin_override_until');
    }

    return isActive;
  }

  /// Dispose resources
  void dispose() {
    _licenseCheckTimer?.cancel();
    AppLogger.info('License Service disposed');
  }
}

// ============ MODELS ============

enum LicenseStatus {
  active,
  expired,
  invalid,
  graceperiod,
  graceperiodExceeded,
}

class LicenseCheckResult {
  final LicenseStatus status;
  final String message;
  final School? school;
  final int? daysRemaining;

  LicenseCheckResult({
    required this.status,
    required this.message,
    this.school,
    this.daysRemaining,
  });

  bool get isValid =>
      status == LicenseStatus.active || status == LicenseStatus.graceperiod;
}
