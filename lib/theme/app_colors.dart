import 'package:flutter/material.dart';

/// Application Color Palette
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============ LIGHT THEME COLORS ============

  // Primary Colors
  static const Color primaryLight = Color(0xFF2563EB); // Blue 600
  static const Color primaryLightVariant = Color(0xFF1E40AF); // Blue 700
  static const Color secondaryLight = Color(0xFF7C3AED); // Violet 600
  static const Color secondaryLightVariant = Color(0xFF6D28D9); // Violet 700

  // Background Colors
  static const Color backgroundLight = Color(0xFFF9FAFB); // Gray 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color cardLight = Color(0xFFFFFFFF); // White

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF111827); // Gray 900
  static const Color textSecondaryLight = Color(0xFF6B7280); // Gray 500
  static const Color textDisabledLight = Color(0xFF9CA3AF); // Gray 400

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB); // Gray 200
  static const Color dividerLight = Color(0xFFF3F4F6); // Gray 100

  // Status Colors (Light)
  static const Color successLight = Color(0xFF10B981); // Green 500
  static const Color warningLight = Color(0xFFF59E0B); // Amber 500
  static const Color errorLight = Color(0xFFEF4444); // Red 500
  static const Color infoLight = Color(0xFF3B82F6); // Blue 500

  // ============ DARK THEME COLORS ============

  // Primary Colors
  static const Color primaryDark = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDarkVariant = Color(0xFF60A5FA); // Blue 400
  static const Color secondaryDark = Color(0xFF8B5CF6); // Violet 500
  static const Color secondaryDarkVariant = Color(0xFFA78BFA); // Violet 400

  // Background Colors
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF334155); // Slate 700

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Gray 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textDisabledDark = Color(0xFF64748B); // Slate 500

  // Border Colors
  static const Color borderDark = Color(0xFF475569); // Slate 600
  static const Color dividerDark = Color(0xFF334155); // Slate 700

  // Status Colors (Dark)
  static const Color successDark = Color(0xFF34D399); // Green 400
  static const Color warningDark = Color(0xFFFBBF24); // Amber 400
  static const Color errorDark = Color(0xFFF87171); // Red 400
  static const Color infoDark = Color(0xFF60A5FA); // Blue 400

  // ============ SEMANTIC COLORS ============

  // Hover & Focus States
  static const Color hoverLight = Color(0xFFF3F4F6); // Gray 100
  static const Color hoverDark = Color(0xFF475569); // Slate 600

  // Active & Selected States
  static const Color selectedLight = Color(0xFFDDEAFE); // Blue 100
  static const Color selectedDark = Color(0xFF1E3A8A); // Blue 900

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // Black 10%
  static const Color shadowDark = Color(0x33000000); // Black 20%

  // Overlay Colors
  static const Color overlayLight = Color(0x80000000); // Black 50%
  static const Color overlayDark = Color(0xB3000000); // Black 70%

  // ============ GRADIENT COLORS ============

  static const List<Color> gradientPrimary = [
    Color(0xFF2563EB), // Blue 600
    Color(0xFF7C3AED), // Violet 600
  ];

  static const List<Color> gradientSuccess = [
    Color(0xFF10B981), // Green 500
    Color(0xFF059669), // Green 600
  ];

  static const List<Color> gradientWarning = [
    Color(0xFFF59E0B), // Amber 500
    Color(0xFFD97706), // Amber 600
  ];

  static const List<Color> gradientError = [
    Color(0xFFEF4444), // Red 500
    Color(0xFFDC2626), // Red 600
  ];

  // ============ MODULE-SPECIFIC COLORS ============

  // Dashboard
  static const Color dashboardStudents = Color(0xFF3B82F6); // Blue
  static const Color dashboardTeachers = Color(0xFF8B5CF6); // Violet
  static const Color dashboardClasses = Color(0xFF10B981); // Green
  static const Color dashboardAttendance = Color(0xFFF59E0B); // Amber

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981); // Green
  static const Color statusUnpaid = Color(0xFFEF4444); // Red
  static const Color statusPartial = Color(0xFFF59E0B); // Amber
  static const Color statusPresent = Color(0xFF10B981); // Green
  static const Color statusAbsent = Color(0xFFEF4444); // Red
  static const Color statusLeave = Color(0xFF6B7280); // Gray
  static const Color statusActive = Color(0xFF10B981); // Green
  static const Color statusExpired = Color(0xFFEF4444); // Red

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xEC4899), // Pink
    Color(0xFF6366F1), // Indigo
  ];
}
