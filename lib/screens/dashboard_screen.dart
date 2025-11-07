import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/statistics_service.dart';
import '../utils/helpers.dart';
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
      icon: Icons.dashboard,
      color: Colors.blue,
    ),
    _NavItem(
      title: 'Students',
      icon: Icons.people,
      color: Colors.green,
    ),
    _NavItem(
      title: 'Teachers',
      icon: Icons.person,
      color: Colors.orange,
    ),
    _NavItem(
      title: 'Classes',
      icon: Icons.class_,
      color: Colors.purple,
    ),
    _NavItem(
      title: 'Attendance',
      icon: Icons.fact_check,
      color: Colors.teal,
    ),
    _NavItem(
      title: 'Fees',
      icon: Icons.payment,
      color: Colors.red,
    ),
    _NavItem(
      title: 'Exams',
      icon: Icons.assignment,
      color: Colors.indigo,
    ),
    _NavItem(
      title: 'Reports',
      icon: Icons.bar_chart,
      color: Colors.brown,
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
    bool confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );

    if (!confirm) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final school = authProvider.currentSchool;
    final user = authProvider.currentUser;

    if (school == null || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final primaryColor = Helpers.parseColor(school.primaryColor);
    final secondaryColor = Helpers.parseColor(school.secondaryColor);

    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: secondaryColor,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // School Logo and Name
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Column(
                      children: [
                        if (school.logoUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: school.logoUrl,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          school.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.white.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            leading: Icon(
                              item.icon,
                              color: Colors.white,
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // User Info and Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
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

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back! Here\'s your school overview',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // License Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: school.isLicenseActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: school.isLicenseActive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        school.isLicenseActive
                            ? Icons.check_circle
                            : Icons.warning,
                        color: school.isLicenseActive
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        school.isLicenseActive
                            ? 'License Active'
                            : 'License Expired',
                        style: TextStyle(
                          color: school.isLicenseActive
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats Cards
            _isLoadingStats
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        title: 'Total Students',
                        value: '${_statistics?['totalStudents'] ?? 0}',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Total Teachers',
                        value: '${_statistics?['totalTeachers'] ?? 0}',
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Fees Collected',
                        value:
                            'Rs. ${(_statistics?['totalFeesCollected'] ?? 0).toStringAsFixed(0)}',
                        icon: Icons.payment,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: 'Attendance Today',
                        value:
                            '${(_statistics?['attendancePercentage'] ?? 0).toStringAsFixed(1)}%',
                        icon: Icons.fact_check,
                        color: Colors.purple,
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            // Recent Activities
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Activities',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadStatistics,
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_recentActivities.isEmpty)
                            _buildActivityItem(
                              'No recent activities',
                              Icons.info,
                              Colors.grey,
                              null,
                            )
                          else
                            ..._recentActivities.take(5).map((activity) =>
                                _buildActivityItem(
                                  activity['message'] as String,
                                  _getIconData(activity['icon'] as String),
                                  Colors.blue,
                                  activity['time'] as DateTime,
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickAction(
                            'Add Student',
                            Icons.person_add,
                            Colors.blue,
                            () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildQuickAction(
                            'Mark Attendance',
                            Icons.fact_check,
                            Colors.green,
                            () {
                              setState(() {
                                _selectedIndex = 4;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildQuickAction(
                            'Record Fee',
                            Icons.payment,
                            Colors.orange,
                            () {
                              setState(() {
                                _selectedIndex = 5;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String text, IconData icon, Color color, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
                if (time != null)
                  Text(
                    _getTimeAgo(time),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'payment':
        return Icons.payment;
      case 'fact_check':
        return Icons.fact_check;
      default:
        return Icons.info;
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

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final Color color;

  _NavItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}
