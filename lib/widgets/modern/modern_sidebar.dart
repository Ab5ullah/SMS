import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// Modern Sidebar Navigation Widget
class ModernSidebar extends StatefulWidget {
  final String schoolName;
  final String? schoolLogo;
  final List<SidebarItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const ModernSidebar({
    super.key,
    required this.schoolName,
    this.schoolLogo,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = widget.isCollapsed
        ? AppSpacing.sidebarCollapsedWidth
        : AppSpacing.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: AppSpacing.borderThin,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & School Name
          _buildHeader(isDark),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingSm,
                vertical: AppSpacing.paddingMd,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(
                  widget.items[index],
                  index,
                  isDark,
                );
              },
            ),
          ),

          // Collapse Toggle Button
          _buildCollapseButton(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? AppSpacing.paddingSm : AppSpacing.paddingMd,
        vertical: AppSpacing.paddingMd,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: AppSpacing.borderThin,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: widget.schoolLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      widget.schoolLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultLogo(),
                    ),
                  )
                : _buildDefaultLogo(),
          ),

          // School Name
          if (!widget.isCollapsed) ...[
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Text(
                widget.schoolName,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return const Center(
      child: Icon(
        Icons.school,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item, int index, bool isDark) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.paddingSm),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onItemSelected(index),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? AppSpacing.paddingSm : AppSpacing.paddingMd,
                vertical: AppSpacing.paddingMd,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isHovered
                        ? (isDark ? AppColors.hoverDark : AppColors.hoverLight)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    size: AppSpacing.iconSizeMd,
                  ),
                  if (!widget.isCollapsed) ...[
                    const SizedBox(width: AppSpacing.gapMd),
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (item.badge != null && !widget.isCollapsed) ...[
                    const SizedBox(width: AppSpacing.gapSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        item.badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingMd),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: AppSpacing.borderThin,
          ),
        ),
      ),
      child: Center(
        child: IconButton(
          onPressed: widget.onToggleCollapse,
          icon: Icon(
            widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.hoverDark : AppColors.hoverLight,
            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          tooltip: widget.isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
        ),
      ),
    );
  }
}

/// Sidebar Item Model
class SidebarItem {
  final String title;
  final IconData icon;
  final String? badge;

  const SidebarItem({
    required this.title,
    required this.icon,
    this.badge,
  });
}
