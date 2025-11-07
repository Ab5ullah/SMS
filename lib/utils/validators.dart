/// Input validation utilities
class Validators {
  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate phone number (Pakistan format: 03XXXXXXXXX)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check for Pakistan format: 03XXXXXXXXX (11 digits starting with 03)
    final pakistanRegex = RegExp(r'^03\d{9}$');

    // Also accept international format: +923XXXXXXXXX
    final internationalRegex = RegExp(r'^\+923\d{9}$');

    if (!pakistanRegex.hasMatch(cleaned) &&
        !internationalRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number (e.g., 03001234567)';
    }

    return null;
  }

  /// Validate CNIC (Pakistan National ID Card: XXXXX-XXXXXXX-X)
  static String? cnic(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }

    // Remove dashes
    final cleaned = value.replaceAll('-', '');

    // Check if it's exactly 13 digits
    final cnicRegex = RegExp(r'^\d{13}$');

    if (!cnicRegex.hasMatch(cleaned)) {
      return 'Please enter a valid CNIC (e.g., 12345-1234567-1)';
    }

    return null;
  }

  /// Validate numeric input
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate integer input
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (int.tryParse(value) == null) {
      return 'Please enter a valid integer';
    }

    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > maxLength) {
      return '${fieldName ?? 'This field'} must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validate minimum value
  static String? minValue(String? value, double minValue, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }

    if (numValue < minValue) {
      return '${fieldName ?? 'Value'} must be at least $minValue';
    }

    return null;
  }

  /// Validate maximum value
  static String? maxValue(String? value, double maxValue, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }

    if (numValue > maxValue) {
      return '${fieldName ?? 'Value'} must not exceed $maxValue';
    }

    return null;
  }

  /// Validate range
  static String? range(
    String? value,
    double minValue,
    double maxValue, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }

    if (numValue < minValue || numValue > maxValue) {
      return '${fieldName ?? 'Value'} must be between $minValue and $maxValue';
    }

    return null;
  }

  /// Validate password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'\d'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate roll number
  static String? rollNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Roll number is required';
    }

    if (value.isEmpty || value.length > 10) {
      return 'Roll number must be between 1 and 10 characters';
    }

    return null;
  }

  /// Validate date range
  static String? dateRange(
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (date == null) {
      return 'Date is required';
    }

    if (startDate != null && date.isBefore(startDate)) {
      return 'Date must be after ${_formatDate(startDate)}';
    }

    if (endDate != null && date.isAfter(endDate)) {
      return 'Date must be before ${_formatDate(endDate)}';
    }

    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validate alphabetic characters only
  static String? alphabetic(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final alphaRegex = RegExp(r'^[a-zA-Z\s]+$');

    if (!alphaRegex.hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only letters';
    }

    return null;
  }

  /// Validate alphanumeric characters
  static String? alphanumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9\s]+$');

    if (!alphanumericRegex.hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only letters and numbers';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (var validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  /// Helper to format date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Form validator extensions
extension FormValidatorExtensions on String? {
  /// Check if value is empty or null
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Check if value is not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Validate as email
  String? validateEmail() => Validators.email(this);

  /// Validate as phone number
  String? validatePhoneNumber() => Validators.phoneNumber(this);

  /// Validate as CNIC
  String? validateCnic() => Validators.cnic(this);

  /// Validate as numeric
  String? validateNumeric({String? fieldName}) =>
      Validators.numeric(this, fieldName: fieldName);

  /// Validate as required
  String? validateRequired({String? fieldName}) =>
      Validators.required(this, fieldName: fieldName);
}
