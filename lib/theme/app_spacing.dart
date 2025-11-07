/// Application Spacing System
class AppSpacing {
  // Private constructor
  AppSpacing._();

  // ============ BASE SPACING SCALE ============
  // Based on 8px grid system

  static const double xs = 4.0;    // Extra small
  static const double sm = 8.0;    // Small
  static const double md = 16.0;   // Medium
  static const double lg = 24.0;   // Large
  static const double xl = 32.0;   // Extra large
  static const double xxl = 48.0;  // Double extra large
  static const double xxxl = 64.0; // Triple extra large

  // ============ SEMANTIC SPACING ============

  // Padding
  static const double paddingXs = xs;
  static const double paddingSm = sm;
  static const double paddingMd = md;
  static const double paddingLg = lg;
  static const double paddingXl = xl;

  // Margins
  static const double marginXs = xs;
  static const double marginSm = sm;
  static const double marginMd = md;
  static const double marginLg = lg;
  static const double marginXl = xl;

  // Gaps (for Row/Column spacing)
  static const double gapXs = xs;
  static const double gapSm = sm;
  static const double gapMd = md;
  static const double gapLg = lg;
  static const double gapXl = xl;

  // ============ COMPONENT-SPECIFIC SPACING ============

  // Card
  static const double cardPadding = md;
  static const double cardMargin = md;
  static const double cardGap = sm;

  // List Items
  static const double listItemPadding = md;
  static const double listItemGap = sm;
  static const double listGap = sm;

  // Form Fields
  static const double fieldPadding = md;
  static const double fieldGap = md;
  static const double fieldHorizontalPadding = md;
  static const double fieldVerticalPadding = 12.0;

  // Buttons
  static const double buttonPaddingHorizontal = lg;
  static const double buttonPaddingVertical = 12.0;
  static const double buttonGap = sm;

  // App Bar
  static const double appBarHeight = 64.0;
  static const double appBarPadding = md;

  // Sidebar
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double sidebarPadding = sm;
  static const double sidebarItemPadding = md;
  static const double sidebarItemGap = xs;

  // Page Layout
  static const double pageHorizontalPadding = lg;
  static const double pageVerticalPadding = lg;
  static const double pageSectionGap = xl;

  // Container
  static const double containerPadding = lg;
  static const double containerMargin = md;

  // Dialog
  static const double dialogPadding = lg;
  static const double dialogContentPadding = md;
  static const double dialogActionPadding = md;

  // Icon Sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // Avatar Sizes
  static const double avatarSizeXs = 24.0;
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 40.0;
  static const double avatarSizeLg = 56.0;
  static const double avatarSizeXl = 80.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999.0;

  // Elevation (Shadow depths)
  static const double elevation0 = 0.0;
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;
  static const double elevation4 = 12.0;
  static const double elevation5 = 16.0;

  // Border Widths
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 4.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 0.0;

  // Z-Index (for overlays, modals)
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 1000;
  static const int zIndexSticky = 1020;
  static const int zIndexFixed = 1030;
  static const int zIndexModalBackdrop = 1040;
  static const int zIndexModal = 1050;
  static const int zIndexPopover = 1060;
  static const int zIndexTooltip = 1070;
}
