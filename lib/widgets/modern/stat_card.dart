import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// Modern Stat Card Widget
///
/// A beautifully designed card for displaying statistics with gradients,
/// icons, and optional trend indicators
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? trend; // Positive = increase, Negative = decrease
  final VoidCallback? onTap;
  final bool useGradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.onTap,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.paddingLg),
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: useGradient ? null : (isDark ? AppColors.cardDark : AppColors.cardLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: useGradient
                ? null
                : Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: AppSpacing.borderThin,
                  ),
            boxShadow: [
              BoxShadow(
                color: useGradient
                    ? color.withValues(alpha: 0.3)
                    : (isDark ? AppColors.shadowDark : AppColors.shadowLight),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Trend Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.paddingMd),
                    decoration: BoxDecoration(
                      color: useGradient
                          ? Colors.white.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: useGradient ? Colors.white : color,
                      size: AppSpacing.iconSizeLg,
                    ),
                  ),
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),

              const SizedBox(height: AppSpacing.gapMd),

              // Title
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: useGradient
                      ? Colors.white.withValues(alpha: 0.9)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.gapSm),

              // Value
              Text(
                value,
                style: AppTypography.numericLarge.copyWith(
                  color: useGradient
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.gapXs),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: useGradient
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = trend! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSm,
        vertical: AppSpacing.paddingXs,
      ),
      decoration: BoxDecoration(
        color: useGradient
            ? Colors.white.withValues(alpha: 0.2)
            : (isPositive ? AppColors.successLight : AppColors.errorLight).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: useGradient
                ? Colors.white
                : (isPositive ? AppColors.successLight : AppColors.errorLight),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${trend!.abs().toStringAsFixed(1)}%',
            style: AppTypography.labelSmall.copyWith(
              color: useGradient
                  ? Colors.white
                  : (isPositive ? AppColors.successLight : AppColors.errorLight),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
