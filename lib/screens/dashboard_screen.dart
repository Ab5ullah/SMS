import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/statistics_service.dart';
import '../utils/helpers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_widgets.dart';
import 'login_screen.dart';
import 'students/students_screen.dart';
import 'teachers/teachers_screen.dart';
import 'classes/classes_screen.dart';
import 'attendance/attendance_screen.dart';
import 'fees/fees_screen.dart';
import 'exams/exams_screen.dart';
import 'reports/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final StatisticsService _statisticsService = StatisticsService();
  Map<String, dynamic>? _statistics;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingStats = true;

  final List<_NavItem> _navItems = [
    _NavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      color: AppColors.dashboardStudents,
    ),
    _NavItem(
      title: 'Students',
      icon: Icons.people_rounded,
      color: AppColors.dashboardStudents,
    ),
    _NavItem(
      title: 'Teachers',
      icon: Icons.person_rounded,
      color: AppColors.dashboardTeachers,
    ),
    _NavItem(
      title: 'Classes',
      icon: Icons.class_rounded,
      color: AppColors.dashboardClasses,
    ),
    _NavItem(
      title: 'Attendance',
      icon: Icons.fact_check_rounded,
      color: AppColors.dashboardAttendance,
    ),
    _NavItem(
      title: 'Fees',
      icon: Icons.payments_rounded,
      color: AppColors.statusPaid,
    ),
    _NavItem(
      title: 'Exams',
      icon: Icons.assignment_rounded,
      color: AppColors.secondaryLight,
    ),
    _NavItem(
      title: 'Reports',
      icon: Icons.bar_chart_rounded,
      color: AppColors.infoLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id;

    if (schoolId == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _statisticsService.getSchoolStatistics(schoolId);
      final activities = await _statisticsService.getRecentActivities(schoolId);

      if (mounted) {
        setState(() {
          _statistics = stats;
          _recentActivities = activities;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _handleLogout() async {
    bool? confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDanger: true,
    );

    if (confirm != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final school = authProvider.currentSchool;
    final user = authProvider.currentUser;

    if (school == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final primaryColor = Helpers.parseColor(school.primaryColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Modern Sidebar
          _buildModernSidebar(school, user, primaryColor, isDark),
          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildModernSidebar(school, user, Color primaryColor, bool isDark) {
    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color.lerp(primaryColor, Colors.black, 0.2)!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // School Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            width: AppSpacing.sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                if (school.logoUrl.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: school.logoUrl,
                        height: AppSpacing.avatarSizeXl,
                        width: AppSpacing.avatarSizeXl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        errorWidget: (context, url, error) => Container(
                          height: AppSpacing.avatarSizeXl,
                          width: AppSpacing.avatarSizeXl,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: AppSpacing.avatarSizeXl,
                    width: AppSpacing.avatarSizeXl,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  school.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return _buildNavItem(item, isSelected, index);
              },
            ),
          ),
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                _buildUserProfile(user),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: Colors.white,
                  size: AppSpacing.iconSizeMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            radius: 20,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const StudentsScreen();
      case 2:
        return const TeachersScreen();
      case 3:
        return const ClassesScreen();
      case 4:
        return const AttendanceScreen();
      case 5:
        return const FeesScreen();
      case 6:
        return const ExamsScreen();
      case 7:
        return const ReportsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final school = authProvider.currentSchool!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header
            _buildDashboardHeader(school, isDark),
            const SizedBox(height: AppSpacing.xl),
            // Stats Grid
            if (_isLoadingStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: LoadingWidget(message: 'Loading statistics...'),
                ),
              )
            else
              _buildStatsGrid(),
            const SizedBox(height: AppSpacing.xl),
            // Recent Activities & Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRecentActivities(isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildQuickActions(isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(school, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: AppTypography.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Welcome back! Here\'s your school overview',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        // License Status Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: school.isLicenseActive
                ? AppColors.successLight.withValues(alpha: 0.1)
                : AppColors.errorLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: school.isLicenseActive
                  ? AppColors.successLight
                  : AppColors.errorLight,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                school.isLicenseActive
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: school.isLicenseActive
                    ? AppColors.successLight
                    : AppColors.errorLight,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                school.isLicenseActive ? 'License Active' : 'License Expired',
                style: AppTypography.labelLarge.copyWith(
                  color: school.isLicenseActive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: [
            StatsCard(
              title: 'Total Students',
              value: '${_statistics?['totalStudents'] ?? 0}',
              icon: Icons.people_rounded,
              color: AppColors.dashboardStudents,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            StatsCard(
              title: 'Total Teachers',
              value: '${_statistics?['totalTeachers'] ?? 0}',
              icon: Icons.person_rounded,
              color: AppColors.dashboardTeachers,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            StatsCard(
              title: 'Fees Collected',
              value:
                  'Rs. ${(_statistics?['totalFeesCollected'] ?? 0).toStringAsFixed(0)}',
              icon: Icons.payments_rounded,
              color: AppColors.dashboardAttendance,
              subtitle: 'This month',
              onTap: () => setState(() => _selectedIndex = 5),
            ),
            StatsCard(
              title: 'Attendance Today',
              value:
                  '${(_statistics?['attendancePercentage'] ?? 0).toStringAsFixed(1)}%',
              icon: Icons.fact_check_rounded,
              color: AppColors.dashboardClasses,
              subtitle: _getAttendanceStatus(
                _statistics?['attendancePercentage'] ?? 0,
              ),
              onTap: () => setState(() => _selectedIndex = 4),
            ),
          ],
        );
      },
    );
  }

  String _getAttendanceStatus(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Average';
    return 'Needs attention';
  }

  Widget _buildRecentActivities(bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activities',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadStatistics,
                tooltip: 'Refresh',
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_recentActivities.isEmpty)
            _buildActivityItem(
              'No recent activities',
              Icons.info_outline_rounded,
              isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              null,
              isDark,
            )
          else
            ..._recentActivities
                .take(6)
                .map(
                  (activity) => _buildActivityItem(
                    activity['message'] as String,
                    _getIconData(activity['icon'] as String),
                    AppColors.dashboardStudents,
                    activity['time'] as DateTime,
                    isDark,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String text,
    IconData icon,
    Color color,
    DateTime? time,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getTimeAgo(time),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildQuickActionButton(
            'Add Student',
            Icons.person_add_rounded,
            AppColors.dashboardStudents,
            () => setState(() => _selectedIndex = 1),
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildQuickActionButton(
            'Mark Attendance',
            Icons.fact_check_rounded,
            AppColors.dashboardClasses,
            () => setState(() => _selectedIndex = 4),
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildQuickActionButton(
            'Record Fee',
            Icons.payments_rounded,
            AppColors.dashboardAttendance,
            () => setState(() => _selectedIndex = 5),
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildQuickActionButton(
            'Generate Report',
            Icons.bar_chart_rounded,
            AppColors.infoLight,
            () => setState(() => _selectedIndex = 7),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'fact_check':
        return Icons.fact_check_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final Color color;

  _NavItem({required this.title, required this.icon, required this.color});
}
