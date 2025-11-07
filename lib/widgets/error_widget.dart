import 'package:flutter/material.dart';

/// Error display widget
class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error banner widget
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;
  final Color? backgroundColor;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red[100],
        border: Border(
          left: BorderSide(
            color: Colors.red[700]!,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onAction != null && actionText != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.red[700],
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}

/// Warning banner variant
class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const WarningBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border(
          left: BorderSide(
            color: Colors.orange[700]!,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onAction != null && actionText != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText!,
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.orange[700],
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}

/// Success banner variant
class SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const SuccessBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        border: Border(
          left: BorderSide(
            color: Colors.green[700]!,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.green[700],
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
