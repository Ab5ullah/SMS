import 'package:flutter/material.dart';

/// Empty state widget to show when there's no data
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
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
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
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

/// No results found variant
class NoResultsFound extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClear;

  const NoResultsFound({
    super.key,
    this.searchQuery,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: searchQuery != null
          ? 'No results found for "$searchQuery"'
          : 'Try adjusting your filters or search query',
      actionText: onClear != null ? 'Clear Filters' : null,
      onAction: onClear,
    );
  }
}

/// No data available variant
class NoDataAvailable extends StatelessWidget {
  final String? message;

  const NoDataAvailable({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No Data Available',
      subtitle: message ?? 'There is no data to display at the moment',
    );
  }
}

/// Offline state variant
class OfflineState extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'No Internet Connection',
      subtitle: 'Please check your internet connection and try again',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }
}
