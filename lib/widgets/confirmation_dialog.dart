import 'package:flutter/material.dart';

/// Confirmation dialog widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = isDangerous
        ? Colors.red
        : (confirmColor ?? Theme.of(context).primaryColor);

    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: btnColor),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        isDangerous: isDangerous,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }
}

/// Delete confirmation dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final String itemName;
  final String? itemType;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    this.itemType,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Delete ${itemType ?? 'Item'}',
      message: 'Are you sure you want to delete "$itemName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDangerous: true,
      onConfirm: onConfirm,
    );
  }

  /// Show delete confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String itemName,
    String? itemType,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        itemName: itemName,
        itemType: itemType,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
  }
}

/// Info dialog
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData? icon;
  final Color? iconColor;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Show info dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}

/// Success dialog
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return InfoDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  /// Show success dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }
}

/// Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return InfoDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
  }

  /// Show error dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }
}
