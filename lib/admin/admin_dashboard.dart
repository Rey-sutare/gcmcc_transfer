import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../admin/doctor_management_page.dart';
import '../admin/appointment_dashboard.dart';
import '../admin/resource_alloc.dart';
import '../admin/survey_page.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../admin/contact_messages_page.dart';

// ==================== Collapsible Sidebar ====================
class CollapsibleSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CollapsibleSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  _CollapsibleSidebarState createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  bool isExpanded = false;

  final List<Map<String, dynamic>> menuItems = [
    {"icon": Icons.dashboard, "title": "Overview"},
    {"icon": Icons.calendar_today, "title": "Appointments"},
    {"icon": Icons.feedback, "title": "Feedback"},
    {"icon": Icons.message, "title": "Messages"},
    {"icon": Icons.poll, "title": "Survey"},
    {"icon": Icons.medical_services, "title": "Doctors"},
    {"icon": Icons.inventory_2, "title": "Resources"},
    {"icon": Icons.person_add, "title": "Add Admin"},
    {"icon": Icons.logout, "title": "Logout"},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double collapsedWidth = isMobile ? 48 : 80;
    final double expandedWidth = isMobile ? 180 : 220;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      width: isExpanded ? expandedWidth : collapsedWidth,
      margin: EdgeInsets.only(
        right: isExpanded ? 0 : 30, // ✅ Add space only when collapsed
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.indigo[100]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar items (excluding logout)
          ...menuItems
              .asMap()
              .entries
              .where((e) => e.key != menuItems.length - 1)
              .map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = widget.selectedIndex == index;

                return Tooltip(
                  message: item["title"],
                  preferBelow: false,
                  verticalOffset: 10,
                  decoration: BoxDecoration(
                    color: Colors.indigo[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  child: InkWell(
                    hoverColor: Colors.indigo[50]!.withOpacity(0.3),
                    onTap: () => widget.onItemTapped(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8 : 12,
                        horizontal: isMobile ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.indigo[50]!.withOpacity(0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(
                        vertical: isMobile ? 2 : 4,
                        horizontal: isMobile ? 4 : 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item["icon"],
                            color: Colors.indigo[700],
                            size: isMobile ? 22 : 26,
                          ),
                          if (isExpanded) SizedBox(width: isMobile ? 8 : 12),
                          if (isExpanded)
                            Expanded(
                              child: Text(
                                item["title"],
                                style: GoogleFonts.poppins(
                                  color: Colors.indigo[900],
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(),

          const Spacer(),

          // Expand/Collapse button
          Padding(
            padding: EdgeInsets.only(bottom: 8, top: isMobile ? 4 : 8),
            child: InkWell(
              onTap: () => setState(() => isExpanded = !isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_double_arrow_left
                      : Icons.keyboard_double_arrow_right,
                  color: Colors.indigo[700],
                  size: isMobile ? 22 : 26,
                ),
              ),
            ),
          ),

          // Logout
          Tooltip(
            message: "Logout",
            child: InkWell(
              hoverColor: Colors.indigo[50]!.withOpacity(0.3),
              onTap: () => widget.onItemTapped(menuItems.length - 1),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 12,
                  horizontal: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: widget.selectedIndex == menuItems.length - 1
                      ? Colors.indigo[50]!.withOpacity(0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(
                  vertical: isMobile ? 2 : 4,
                  horizontal: isMobile ? 4 : 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      menuItems.last["icon"],
                      color: Colors.indigo[700],
                      size: isMobile ? 22 : 26,
                    ),
                    if (isExpanded) SizedBox(width: isMobile ? 8 : 12),
                    if (isExpanded)
                      Expanded(
                        child: Text(
                          menuItems.last["title"],
                          style: GoogleFonts.poppins(
                            color: Colors.indigo[900],
                            fontSize: isMobile ? 14 : 15,
                            fontWeight:
                                widget.selectedIndex == menuItems.length - 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
        ],
      ),
    );
  }
}

// ==================== Admin Dashboard ====================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<User?>? _authStateSubscription;
  bool _hasCheckedAdminStatus = false;

  late final Map<int, Widget Function(bool)> _pages;

  @override
  void initState() {
    super.initState();

    _pages = {
      0: (isMobile) => OverviewTab(),
      1: (isMobile) => AdminAppointmentsPage(isMobile: isMobile),
      2: (isMobile) => AdminFeedbackPage(isMobile: isMobile),
      3: (isMobile) => ContactMessagesPage(isMobile: isMobile),
      4: (isMobile) => SurveyResultsPage(isMobile: isMobile),
      5: (isMobile) => DoctorManagementPage(isMobile: isMobile),
      6: (isMobile) => ResourceManagementPage(isMobile: isMobile),
      7: (isMobile) => AdminRegistrationPage(isMobile: isMobile),
    };

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user == null && mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.logout();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedAdminStatus) {
      _checkAdminStatus();
      _hasCheckedAdminStatus = true;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to continue.'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error checking admin status: ${e.toString().split(':').last.trim()}',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _checkAdminStatus,
              ),
            ),
          );
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 8) {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.indigo[900]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.indigo[700],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldLogout == true && mounted) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.logout();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _selectedIndex = index.clamp(0, _pages.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(authService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: _buildAppBar(),
                body: Stack(
                  children: [
                    Center(child: _buildLoadingIndicator()),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CollapsibleSidebar(
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data?['role'] != 'admin') {
              return Scaffold(
                appBar: _buildAppBar(),
                body: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 48, color: Colors.indigo[700]),
                          SizedBox(height: 16),
                          Text(
                            'Access Denied: Admin Only',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[900],
                            ),
                          ),
                          SizedBox(height: 24),
                          _buildStyledButton(
                            context: context,
                            text: 'Return to Main Page',
                            onPressed: () =>
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/',
                                  (Route<dynamic> route) => false,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CollapsibleSidebar(
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              key: ValueKey('admin_dashboard'),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Image.asset('assets/logo.png', height: 40, width: 40),
                    SizedBox(width: 12),
                    Text(
                      'GCMCC Admin',
                      style: GoogleFonts.poppins(
                        color: Colors.indigo[900],
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Consumer<FeedbackProvider>(
                      builder: (context, feedbackProvider, child) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications,
                                color: Colors.indigo[700],
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => NegativeFeedbackDialog(
                                    key: ValueKey('negative_feedback_dialog'),
                                    onFeedbackViewed: () {},
                                  ),
                                );
                              },
                            ),
                            if (feedbackProvider.unreadNegativeFeedbackCount >
                                0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${feedbackProvider.unreadNegativeFeedbackCount}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    left: isMobile ? 50 : 90,
                    child:
                        _pages[_selectedIndex]?.call(isMobile) ?? OverviewTab(),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: CollapsibleSidebar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 16),
        Text(
          'Loading Dashboard...',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.indigo[900]),
        ),
      ],
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.indigo[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.indigo.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(AuthService authService) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 40, width: 40),
          const SizedBox(width: 12),
          Text(
            'GCMCC Admin',
            style: GoogleFonts.poppins(
              color: Colors.indigo[900],
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// ==================== OverviewTab ====================
class OverviewTab extends StatefulWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  _OverviewTabState createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final List<String> _timePeriods = ['Weekly', 'Monthly', 'Yearly'];
  String _selectedTimePeriod = 'Monthly';
  String _selectedDepartment = 'All';
  List<String> _departments = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      final departments =
          snapshot.docs
              .map((doc) => doc.data()['department'] as String?)
              .where((dept) => dept != null)
              .map((dept) => dept!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _departments = ['All', ...departments];
      });
    } catch (e) {
      print('Error fetching departments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isUltraSmall = screenWidth < 360;
    final isSmall = screenWidth < 600;
    final isMedium = screenWidth < 900;

    // Dynamic sizing based on screen width
    final double fontSizeTitle = isUltraSmall
        ? 20
        : isSmall
        ? 22
        : 26;
    final double fontSizeDropdown = isUltraSmall
        ? 12
        : isSmall
        ? 14
        : 16;
    final double paddingHorizontal = isUltraSmall
        ? 8
        : isSmall
        ? 12
        : 16;
    final double paddingVertical = isUltraSmall ? 12 : 16;
    final double spacing = isUltraSmall
        ? 12
        : isSmall
        ? 16
        : 20;
    final double cardHeight = screenHeight * 0.4;
    final double maxCardHeight = isUltraSmall
        ? 300
        : isSmall
        ? 350
        : 400;

    // New responsive filter sizing
    final double filterContainerWidth = isUltraSmall
        ? screenWidth * 0.6
        : isSmall
        ? screenWidth * 0.5
        : screenWidth * 0.4;

    final double filterItemWidth = isUltraSmall
        ? filterContainerWidth * 0.45
        : filterContainerWidth * 0.48;

    final double dropdownPaddingHorizontal = isUltraSmall
        ? 6
        : isSmall
        ? 8
        : 12;

    final double dropdownPaddingVertical = isUltraSmall
        ? 2
        : isSmall
        ? 4
        : 6;

    final double dropdownIconSize = isUltraSmall
        ? 16
        : isSmall
        ? 18
        : 20;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Overview',
                  style: GoogleFonts.poppins(
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: filterContainerWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        width: filterItemWidth,
                        padding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingHorizontal,
                          vertical: dropdownPaddingVertical,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedTimePeriod,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: dropdownIconSize,
                            color: Colors.indigo[700],
                          ),
                          iconSize: dropdownIconSize,
                          items: _timePeriods
                              .map(
                                (period) => DropdownMenuItem(
                                  value: period,
                                  child: Text(
                                    period,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSizeDropdown,
                                      color: Colors.indigo[900],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTimePeriod = value);
                            }
                          },
                          underline: const SizedBox(),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 0.3),
                    Flexible(
                      child: Container(
                        width: filterItemWidth,
                        padding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingHorizontal,
                          vertical: dropdownPaddingVertical,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDepartment,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: dropdownIconSize,
                            color: Colors.indigo[700],
                          ),
                          iconSize: dropdownIconSize,
                          items: _departments
                              .map(
                                (dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSizeDropdown,
                                      color: Colors.indigo[900],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDepartment = value);
                            }
                          },
                          underline: const SizedBox(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          if (isSmall)
            Column(
              children: [
                TotalAppointmentsCard(isMobile: isSmall),
                SizedBox(height: spacing),
                TotalPatientsCard(isMobile: isSmall),
                SizedBox(height: spacing),
                TotalDoctorsCard(isMobile: isSmall),
                SizedBox(height: spacing),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: cardHeight * 0.8,
                    maxHeight: maxCardHeight,
                    minWidth: double.infinity,
                  ),
                  child: DepartmentOverviewCard(
                    isMobile: isSmall,
                    timePeriod: _selectedTimePeriod,
                    selectedDepartment: _selectedDepartment,
                  ),
                ),
                SizedBox(height: spacing),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: cardHeight * 0.8,
                    maxHeight: maxCardHeight,
                    minWidth: double.infinity,
                  ),
                  child: PatientSatisfactionCard(
                    isMobile: isSmall,
                    timePeriod: _selectedTimePeriod,
                    selectedDepartment: _selectedDepartment,
                  ),
                ),
                SizedBox(height: spacing),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: cardHeight * 0.7,
                    maxHeight: maxCardHeight * 0.9,
                    minWidth: double.infinity,
                  ),
                  child: SurveyResultsCard(
                    isMobile: isSmall,
                    timePeriod: _selectedTimePeriod,
                    selectedDepartment: _selectedDepartment,
                  ),
                ),
                SizedBox(height: spacing),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: cardHeight * 0.8,
                    maxHeight: maxCardHeight,
                    minWidth: double.infinity,
                  ),
                  child: NegativeFeedbackAlerts(
                    isMobile: isSmall,
                    timePeriod: _selectedTimePeriod,
                    selectedDepartment: _selectedDepartment,
                  ),
                ),
                SizedBox(height: spacing),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: cardHeight * 0.8,
                    maxHeight: maxCardHeight,
                    minWidth: double.infinity,
                  ),
                  child: ResourceUtilizationCard(
                    isMobile: isSmall,
                    timePeriod: _selectedTimePeriod,
                    selectedDepartment: _selectedDepartment,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: TotalPatientsCard(isMobile: isSmall)),
                    SizedBox(width: spacing * 0.75),
                    Flexible(child: TotalAppointmentsCard(isMobile: isSmall)),
                    SizedBox(width: spacing * 0.75),
                    Flexible(child: TotalDoctorsCard(isMobile: isSmall)),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: isMedium ? 5 : 6,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: cardHeight,
                          maxHeight: maxCardHeight,
                          minWidth: 0,
                        ),
                        child: DepartmentOverviewCard(
                          isMobile: isSmall,
                          timePeriod: _selectedTimePeriod,
                          selectedDepartment: _selectedDepartment,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Flexible(
                      flex: isMedium ? 5 : 4,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: cardHeight,
                          maxHeight: maxCardHeight,
                          minWidth: 0,
                        ),
                        child: PatientSatisfactionCard(
                          isMobile: isSmall,
                          timePeriod: _selectedTimePeriod,
                          selectedDepartment: _selectedDepartment,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: isMedium ? 5 : 4,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: cardHeight,
                          maxHeight: maxCardHeight,
                          minWidth: 0,
                        ),
                        child: NegativeFeedbackAlerts(
                          isMobile: isSmall,
                          timePeriod: _selectedTimePeriod,
                          selectedDepartment: _selectedDepartment,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Flexible(
                      flex: isMedium ? 5 : 6,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: cardHeight,
                          maxHeight: maxCardHeight,
                          minWidth: 0,
                        ),
                        child: SurveyResultsCard(
                          isMobile: isSmall,
                          timePeriod: _selectedTimePeriod,
                          selectedDepartment: _selectedDepartment,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: cardHeight,
                          maxHeight: maxCardHeight,
                          minWidth: 0,
                        ),
                        child: ResourceUtilizationCard(
                          isMobile: isSmall,
                          timePeriod: _selectedTimePeriod,
                          selectedDepartment: _selectedDepartment,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class TotalPatientsCard extends StatelessWidget {
  final bool isMobile;

  const TotalPatientsCard({Key? key, required this.isMobile}) : super(key: key);

  Stream<int> _getTotalPatientsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e) {
          print('Error fetching total patients: $e');
          return 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 300,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total Patients',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.person, color: Colors.indigo[700], size: 24),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<int>(
              stream: _getTotalPatientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(color: Colors.indigo[700]);
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.red[700],
                    ),
                  );
                }
                return Text(
                  '${snapshot.data ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo[900],
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            Text(
              'Registered Patients',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalAppointmentsCard extends StatelessWidget {
  final bool isMobile;

  const TotalAppointmentsCard({Key? key, required this.isMobile})
    : super(key: key);

  Stream<int> _getTotalAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e) {
          print('Error fetching total appointments: $e');
          return 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 300,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total Appointments',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.indigo[700], size: 24),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<int>(
              stream: _getTotalAppointmentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(color: Colors.indigo[700]);
                }
                return Text(
                  '${snapshot.data ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo[900],
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            Text(
              'All Time Appointments',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TotalDoctorsCard extends StatelessWidget {
  final bool isMobile;

  const TotalDoctorsCard({Key? key, required this.isMobile}) : super(key: key);

  Stream<int> _getTotalDoctorsStream() {
    return FirebaseFirestore.instance
        .collection('doctors')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e) {
          print('Error fetching total doctors: $e');
          return 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 300,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total Doctors',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.medical_services,
                  color: Colors.indigo[700],
                  size: 24,
                ),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<int>(
              stream: _getTotalDoctorsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(color: Colors.indigo[700]);
                }
                return Text(
                  '${snapshot.data ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo[900],
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            Text(
              'Active Doctors',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DepartmentOverviewCard ====================
class DepartmentOverviewCard extends StatelessWidget {
  final bool isMobile;
  final String timePeriod;
  final String selectedDepartment;

  const DepartmentOverviewCard({
    Key? key,
    required this.isMobile,
    required this.timePeriod,
    required this.selectedDepartment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.indigo[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Department Overview',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Colors.indigo[700],
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(color: Colors.indigo[100], thickness: 1),
              SizedBox(height: 8),
              SizedBox(
                height: isMobile ? 200 : 240,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getDepartmentStatsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: isMobile ? 200 : 240,
                        child: Center(child: _buildLoadingIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      print(
                        'Error in DepartmentOverviewCard: ${snapshot.error}',
                      );
                      return SizedBox(
                        height: isMobile ? 200 : 240,
                        child: Center(
                          child: Text(
                            'Error loading data: ${snapshot.error}',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final departments = snapshot.data ?? [];
                    print('DepartmentOverviewCard departments: $departments');
                    if (departments.isEmpty) {
                      return SizedBox(
                        height: isMobile ? 200 : 240,
                        child: Center(
                          child: Text(
                            'No department data available for $selectedDepartment ($timePeriod)',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final maxY =
                        departments
                            .map(
                              (dept) =>
                                  (dept['appointments'] as int).toDouble(),
                            )
                            .reduce((a, b) => a > b ? a : b) *
                        1.2;
                    // Ensure interval is at least 1 and rounds to a reasonable step
                    final interval = maxY > 5 ? (maxY / 5).ceilToDouble() : 1.0;
                    print('maxY: $maxY, interval: $interval');
                    return Column(
                      children: [
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY > 0 ? maxY : 10.0,
                              barGroups: departments.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final dept = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: dept['appointments'].toDouble(),
                                      color: Colors.indigo[700],
                                      width: isMobile ? 20 : 30,
                                      borderRadius: BorderRadius.circular(4),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY: maxY,
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: interval,
                                    getTitlesWidget: (value, meta) {
                                      // Only show integer labels at the calculated interval
                                      if (value.toInt() % interval != 0)
                                        return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 12 : 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      final dept =
                                          departments[value
                                              .toInt()]['department'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Transform.rotate(
                                          angle: isMobile
                                              ? -45 * 3.14159 / 180
                                              : 0,
                                          child: Text(
                                            dept,
                                            style: GoogleFonts.poppins(
                                              fontSize: isMobile ? 10 : 12,
                                              color: Colors.grey[800],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                drawVerticalLine: false,
                                horizontalInterval: interval,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[300],
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) =>
                                      Colors.indigo[900]!.withOpacity(0.8),
                                  getTooltipItem:
                                      (group, groupIdx, rod, rodIdx) {
                                        final dept =
                                            departments[group.x
                                                .toInt()]['department'];
                                        return BarTooltipItem(
                                          '$dept\n${rod.toY.toInt()} Patients',
                                          GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Patients by Department ($timePeriod)',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 6),
        Text(
          'Loading Data...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.indigo[900],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _getDepartmentStatsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .snapshots()
        .asyncMap((appointmentSnapshot) async {
          try {
            final now = DateTime.now();
            DateTime startDate;
            switch (timePeriod) {
              case 'Weekly':
                startDate = now.subtract(Duration(days: 7));
                break;
              case 'Yearly':
                startDate = now.subtract(Duration(days: 365));
                break;
              case 'Monthly':
              default:
                startDate = now.subtract(Duration(days: 30));
                break;
            }

            print(
              'Processing department stats for timePeriod: $timePeriod, startDate: $startDate, department: $selectedDepartment',
            );

            final departmentStats = <String, Map<String, dynamic>>{};
            final userAppointments = <String, List<Map<String, dynamic>>>{};

            final dateFormat = DateFormat('MMM d, yyyy \'at\' hh:mm a');

            // Filter appointments based on selected department and date
            final filteredDocs = appointmentSnapshot.docs.where((doc) {
              final data = doc.data();

              // Filter by department
              if (selectedDepartment != 'All') {
                final department = data['department'] as String?;
                if (department != selectedDepartment) {
                  return false;
                }
              }

              // Filter by date
              final dateStr = data['date'] as String?;
              if (dateStr == null) {
                return false;
              }
              try {
                final date = dateFormat.parse(dateStr);
                return date.isAfter(startDate) ||
                    date.isAtSameMomentAs(startDate);
              } catch (e) {
                return false;
              }
            }).toList();

            // Process appointments
            for (var doc in filteredDocs) {
              final data = doc.data();
              final department = data['department'] as String? ?? 'Unknown';
              final userId = data['userId'] as String? ?? 'Unknown';

              departmentStats[department] =
                  departmentStats[department] ??
                  {
                    'appointments': 0,
                    'positive': 0,
                    'negative': 0,
                    'neutral': 0,
                    'totalRating': 0.0,
                    'feedbackCount': 0,
                  };
              departmentStats[department]!['appointments']++;

              userAppointments[userId] = userAppointments[userId] ?? [];
              userAppointments[userId]!.add(data);
            }

            // Get feedback data
            Query<Map<String, dynamic>> feedbackQuery = FirebaseFirestore
                .instance
                .collection('feedback');

            if (timePeriod != 'Yearly') {
              feedbackQuery = feedbackQuery.where(
                'date',
                isGreaterThanOrEqualTo: DateFormat(
                  'MMM d, yyyy',
                ).format(startDate),
              );
            }

            final feedbackSnapshot = await feedbackQuery.get();

            // Process feedback
            for (var doc in feedbackSnapshot.docs) {
              final data = doc.data();
              final userId = data['userId'] as String? ?? 'Unknown';
              if (userAppointments.containsKey(userId)) {
                final userAppts = userAppointments[userId]!;
                userAppts.sort((a, b) {
                  try {
                    final dateA = dateFormat.parse(a['date'] as String);
                    final dateB = dateFormat.parse(b['date'] as String);
                    return dateB.compareTo(dateA);
                  } catch (e) {
                    return 0;
                  }
                });
                final department = userAppts.isNotEmpty
                    ? userAppts.first['department'] as String? ?? 'Unknown'
                    : 'Unknown';
                if (departmentStats.containsKey(department)) {
                  departmentStats[department]!['feedbackCount']++;
                  departmentStats[department]!['totalRating'] +=
                      (data['rating'] as num?)?.toDouble() ?? 0.0;
                  switch (data['sentiment']) {
                    case 'Positive':
                      departmentStats[department]!['positive']++;
                      break;
                    case 'Negative':
                      departmentStats[department]!['negative']++;
                      break;
                    case 'Neutral':
                      departmentStats[department]!['neutral']++;
                      break;
                  }
                }
              }
            }

            // Prepare result
            final result =
                departmentStats.entries
                    .map(
                      (e) => {
                        'department': e.key,
                        'appointments': e.value['appointments'],
                        'positive': e.value['positive'],
                        'negative': e.value['negative'],
                        'neutral': e.value['neutral'],
                        'averageRating': e.value['feedbackCount'] > 0
                            ? e.value['totalRating'] / e.value['feedbackCount']
                            : 0.0,
                      },
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a['department'] ?? '').compareTo(
                      b['department'] ?? '',
                    ),
                  );

            print('Department stats result: $result');
            return result;
          } catch (e, stackTrace) {
            print('Error processing department stats: $e\n$stackTrace');
            return [];
          }
        });
  }
}

class PatientSatisfactionCard extends StatelessWidget {
  final bool isMobile;
  final String timePeriod;
  final String selectedDepartment;

  const PatientSatisfactionCard({
    Key? key,
    required this.isMobile,
    required this.timePeriod,
    required this.selectedDepartment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.indigo[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Patient Satisfaction',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.indigo[700],
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                  child: Divider(
                    color: Colors.indigo[100]!.withOpacity(0.5),
                    thickness: 1,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: isMobile ? 200 : 240,
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _getFeedbackStatsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: _buildLoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      print(
                        'Error in PatientSatisfactionCard: ${snapshot.error}',
                      );
                      return Center(
                        child: Text(
                          'Error loading data: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final stats =
                        snapshot.data ??
                        {
                          'positive': 0,
                          'negative': 0,
                          'neutral': 0,
                          'averageRating': 0.0,
                        };
                    final total =
                        stats['positive'] +
                        stats['negative'] +
                        stats['neutral'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final chartSize = isMobile
                                    ? constraints.maxWidth * 0.75
                                    : constraints.maxWidth * 0.65;
                                final maxChartSize = isMobile ? 160.0 : 200.0;
                                final finalChartSize = chartSize < maxChartSize
                                    ? chartSize
                                    : maxChartSize;
                                return SizedBox(
                                  height: finalChartSize,
                                  width: finalChartSize,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          color: Colors.green[500],
                                          value: stats['positive'].toDouble(),
                                          title: total > 0
                                              ? 'Positive\n${(stats['positive'] / total * 100).toStringAsFixed(1)}%'
                                              : 'Positive\n0%',
                                          radius: isMobile ? 50.0 : 70.0,
                                          titleStyle: GoogleFonts.poppins(
                                            fontSize: isMobile ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2.0,
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          titlePositionPercentageOffset: 0.65,
                                        ),
                                        PieChartSectionData(
                                          color: Colors.red[500],
                                          value: stats['negative'].toDouble(),
                                          title: total > 0
                                              ? 'Negative\n${(stats['negative'] / total * 100).toStringAsFixed(1)}%'
                                              : 'Negative\n0%',
                                          radius: isMobile ? 50.0 : 70.0,
                                          titleStyle: GoogleFonts.poppins(
                                            fontSize: isMobile ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2.0,
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          titlePositionPercentageOffset: 0.65,
                                        ),
                                        PieChartSectionData(
                                          color: Colors.grey[500],
                                          value: stats['neutral'].toDouble(),
                                          title: total > 0
                                              ? 'Neutral\n${(stats['neutral'] / total * 100).toStringAsFixed(1)}%'
                                              : 'Neutral\n0%',
                                          radius: isMobile ? 50.0 : 70.0,
                                          titleStyle: GoogleFonts.poppins(
                                            fontSize: isMobile ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2.0,
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          titlePositionPercentageOffset: 0.65,
                                        ),
                                      ],
                                      sectionsSpace: 4.0,
                                      centerSpaceRadius: isMobile ? 30.0 : 40.0,
                                      startDegreeOffset: 270,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Overall Rating: ${stats['averageRating'].toStringAsFixed(1)}/5.0',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.star,
                                color: Colors.amber[600],
                                size: isMobile ? 18 : 22,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 6),
        Text(
          'Loading Feedback...',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.indigo[900],
          ),
        ),
      ],
    );
  }

  Stream<Map<String, dynamic>> _getFeedbackStatsStream() {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'feedback',
      );

      return Stream.fromFuture(
        FirebaseFirestore.instance
            .collection('appointments')
            .where(
              'department',
              isEqualTo: selectedDepartment == 'All'
                  ? null
                  : selectedDepartment,
            )
            .get()
            .then((appointmentSnapshot) {
              final userAppointments = <String, String>{};
              for (var doc in appointmentSnapshot.docs) {
                final data = doc.data();
                userAppointments[data['userId'] as String? ?? 'Unknown'] =
                    selectedDepartment;
              }
              return userAppointments;
            }),
      ).asyncExpand((userAppointments) {
        return query.snapshots().map((snapshot) {
          int positive = 0, negative = 0, neutral = 0;
          double totalRating = 0.0;
          int count = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String? ?? 'Unknown';
            if (selectedDepartment != 'All' &&
                !userAppointments.containsKey(userId)) {
              continue;
            }
            count++;
            totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
            switch (data['sentiment']) {
              case 'Positive':
                positive++;
                break;
              case 'Negative':
                negative++;
                break;
              case 'Neutral':
                neutral++;
                break;
            }
          }

          return {
            'positive': positive,
            'negative': negative,
            'neutral': neutral,
            'averageRating': count > 0 ? totalRating / count : 0.0,
          };
        });
      });
    } catch (e, stackTrace) {
      print('Error streaming feedback stats: $e\n$stackTrace');
      return Stream.value({
        'positive': 0,
        'negative': 0,
        'neutral': 0,
        'averageRating': 0.0,
      });
    }
  }

  Future<Map<String, dynamic>> _getFeedbackStats() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'feedback',
      );
      final userAppointments = <String, String>{};
      if (selectedDepartment != 'All') {
        final appointmentSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('department', isEqualTo: selectedDepartment)
            .get();
        for (var doc in appointmentSnapshot.docs) {
          final data = doc.data();
          userAppointments[data['userId'] as String? ?? 'Unknown'] =
              selectedDepartment;
        }
      }

      final snapshot = await query.get();
      int positive = 0, negative = 0, neutral = 0;
      double totalRating = 0.0;
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? 'Unknown';
        if (selectedDepartment != 'All' &&
            !userAppointments.containsKey(userId)) {
          continue;
        }
        count++;
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
        switch (data['sentiment']) {
          case 'Positive':
            positive++;
            break;
          case 'Negative':
            negative++;
            break;
          case 'Neutral':
            neutral++;
            break;
        }
      }

      return {
        'positive': positive,
        'negative': negative,
        'neutral': neutral,
        'averageRating': count > 0 ? totalRating / count : 0.0,
      };
    } catch (e, stackTrace) {
      print('Error fetching feedback stats: $e\n$stackTrace');
      return {'positive': 0, 'negative': 0, 'neutral': 0, 'averageRating': 0.0};
    }
  }
}

class NegativeFeedbackAlerts extends StatefulWidget {
  final bool isMobile;
  final String timePeriod;
  final String selectedDepartment;

  const NegativeFeedbackAlerts({
    Key? key,
    required this.isMobile,
    required this.timePeriod,
    required this.selectedDepartment,
  }) : super(key: key);

  @override
  _NegativeFeedbackAlertsState createState() => _NegativeFeedbackAlertsState();
}

class _NegativeFeedbackAlertsState extends State<NegativeFeedbackAlerts> {
  List<Map<String, dynamic>> negativeWords = [];
  int totalNegativeCount = 0;
  bool isLoading = true;
  String? errorMessage;
  Stream<List<Map<String, dynamic>>>? _feedbackStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  @override
  void didUpdateWidget(NegativeFeedbackAlerts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timePeriod != widget.timePeriod ||
        oldWidget.selectedDepartment != widget.selectedDepartment) {
      _initializeStream();
    }
  }

  void _initializeStream() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    _feedbackStream = _getNegativeFeedbacksStream();
    _feedbackStream!.listen(
      (feedbacks) {
        if (mounted) {
          final words = _extractNegativeWords(feedbacks);
          setState(() {
            negativeWords = words;
            totalNegativeCount = feedbacks.length;
            isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Error loading data: $e';
            isLoading = false;
          });
          print('Error streaming negative feedback: $e');
        }
      },
    );
  }

  List<Map<String, dynamic>> _extractNegativeWords(
    List<Map<String, dynamic>> feedbacks,
  ) {
    const negativeKeywords = {
      'poor',
      'bad',
      'terrible',
      'awful',
      'disappointing',
      'horrible',
      'unpleasant',
      'rude',
      'slow',
      'unprofessional',
      'confusing',
      'painful',
      'difficult',
      'unhappy',
      'frustrating',
      'inconvenient',
      'delayed',
      'late',
      'unresponsive',
      'neglect',
      'error',
      'mistake',
      'problem',
      'issue',
      'complaint',
      'unsatisfactory',
      'inadequate',
      'substandard',
      'disorganized',
      'dirty',
      'unhygienic',
      'worst',
      'negative',
      'disappointed',
      'frustrated',
      'angry',
      'upset',
      'terribly',
      'poorly',
      'badly',
      'awfully',
      'rushed',
      'ignored',
      'wait',
      'waiting',
      'long',
      'delay',
      'unacceptable',
      'incompetent',
      'careless',
      'pangit',
      'masama',
      'nakakainis',
      'nakakabigo',
      'problema',
      'sira',
      'antagal',
      'mabagal',
      'mainit',
      'masikip',
      'mahirap',
      'nakakastress',
      'nakakadismaya',
      'nakakapanghina',
      'walang kwenta',
      'sayang',
      'hindi sulit',
      'nakakairita',
      'nakakabwisit',
      'nakakasuya',
      'nakakagalit',
      'nakakapagod',
    };

    const stopwords = {
      'the',
      'is',
      'are',
      'was',
      'were',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'lang',
      'by',
      'from',
      'up',
      'about',
      'into',
      'over',
      'after',
      'long',
      'i',
      'it',
      'he',
      'she',
      'we',
      'they',
      'that',
      'this',
      'be',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'ang',
      'sa',
      'ng',
      'mga',
      'si',
      'ay',
      'nang',
      'para',
      'kung',
      'dahil',
      'pag',
      'na',
      'ni',
      'kay',
      'ko',
      'mo',
      'kayo',
      'kami',
      'sila',
      'ito',
      'iyan',
      'yon',
      'yung',
      'rin',
      'din',
      'pa',
      'ba',
      'po',
      'nila',
      'not',
      'no',
      'very',
      'too',
      'so',
      'just',
      'only',
    };

    final wordCounts = <String, int>{};

    final negativeFeedbacks = feedbacks.where((feedback) {
      final sentiment = feedback['sentiment'] as String?;
      final rating = feedback['rating'] as int?;
      return sentiment == 'Negative' ||
          (sentiment == null && rating != null && rating <= 2);
    }).toList();

    for (var feedback in negativeFeedbacks) {
      final comment = feedback['comment']?.toString().toLowerCase() ?? '';
      print('Processing comment: "$comment"');
      if (comment.isEmpty) continue;

      final words = comment
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), '').trim())
          .where((word) => word.isNotEmpty && !stopwords.contains(word))
          .toList();

      print('Extracted words: $words');

      for (var word in words) {
        if (negativeKeywords.contains(word)) {
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
          print('Matched keyword: $word');
        }
      }
    }

    print('Word counts: $wordCounts');

    final negativeWords =
        wordCounts.entries
            .map((entry) => {'word': entry.key, 'count': entry.value})
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    print('Sorted negative words: $negativeWords');

    return negativeWords.take(10).toList();
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 6),
        Text(
          'Loading Feedback...',
          style: GoogleFonts.poppins(
            fontSize: widget.isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.indigo[900],
          ),
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _getNegativeFeedbacksStream() {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (widget.timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('feedback')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('timestamp', descending: true);

      return Stream.fromFuture(
        FirebaseFirestore.instance
            .collection('appointments')
            .where(
              'department',
              isEqualTo: widget.selectedDepartment == 'All'
                  ? null
                  : widget.selectedDepartment,
            )
            .get()
            .then((appointmentSnapshot) {
              final validUserIds = <String>{};
              for (var doc in appointmentSnapshot.docs) {
                final data = doc.data();
                final userId = data['userId'] as String? ?? 'Unknown';
                validUserIds.add(userId);
              }
              print(
                'Valid user IDs for department ${widget.selectedDepartment}: ${validUserIds.length} IDs',
              );
              return validUserIds;
            }),
      ).asyncExpand((validUserIds) {
        return query.snapshots().map((snapshot) {
          print(
            'Fetched ${snapshot.docs.length} total recent feedback documents',
          );
          final feedbacks = snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .where((feedback) {
                final sentiment = feedback['sentiment'] as String?;
                final rating = feedback['rating'] as int?;
                final isNegative =
                    sentiment == 'Negative' ||
                    (sentiment == null && rating != null && rating <= 2);
                print(
                  'Feedback ${feedback['id']}: sentiment=$sentiment, rating=$rating, isNegative=$isNegative',
                );
                return isNegative;
              })
              .toList();

          print('Filtered to ${feedbacks.length} negative feedbacks');

          final departmentFiltered = feedbacks.where((feedback) {
            if (widget.selectedDepartment == 'All') return true;
            final userId = feedback['userId'] as String? ?? 'Unknown';
            final isValid = validUserIds.contains(userId);
            print('Feedback userId: $userId, valid for dept: $isValid');
            return isValid;
          }).toList();

          print('Final filtered feedbacks: ${departmentFiltered.length}');
          return departmentFiltered;
        });
      });
    } catch (e, stackTrace) {
      print('Error streaming negative feedbacks: $e\n$stackTrace');
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        print(
          'Tip: Create the composite indexes as described in the docs or use the error link.',
        );
      }
      return Stream.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _getNegativeFeedbacks() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (widget.timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('feedback')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('timestamp', descending: true);

      final snapshot = await query.get();
      print('Fetched ${snapshot.docs.length} total recent feedback documents');

      final feedbacks = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((feedback) {
            final sentiment = feedback['sentiment'] as String?;
            final rating = feedback['rating'] as int?;
            final isNegative =
                sentiment == 'Negative' ||
                (sentiment == null && rating != null && rating <= 2);
            print(
              'Feedback ${feedback['id']}: sentiment=$sentiment, rating=$rating, isNegative=$isNegative',
            );
            return isNegative;
          })
          .toList();

      print('Filtered to ${feedbacks.length} negative feedbacks');

      final Set<String> validUserIds = <String>{};
      if (widget.selectedDepartment != 'All') {
        final appointmentSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('department', isEqualTo: widget.selectedDepartment)
            .get();
        for (var doc in appointmentSnapshot.docs) {
          final data = doc.data();
          final userId = data['userId'] as String? ?? 'Unknown';
          validUserIds.add(userId);
        }
        print(
          'Valid user IDs for department ${widget.selectedDepartment}: ${validUserIds.length} IDs',
        );
      }

      final departmentFiltered = feedbacks.where((feedback) {
        if (widget.selectedDepartment == 'All') return true;
        final userId = feedback['userId'] as String? ?? 'Unknown';
        final isValid = validUserIds.contains(userId);
        print('Feedback userId: $userId, valid for dept: $isValid');
        return isValid;
      }).toList();

      print('Final filtered feedbacks: ${departmentFiltered.length}');
      return departmentFiltered;
    } catch (e, stackTrace) {
      print('Error fetching negative feedbacks: $e\n$stackTrace');
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        print(
          'Tip: Create the composite indexes as described in the docs or use the error link.',
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.red[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(widget.isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Negative Feedback Word Frequency',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100]!.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber,
                    color: Colors.red[600],
                    size: widget.isMobile ? 26 : 28,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(color: Colors.red[100]!.withOpacity(0.5), thickness: 1),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Total Negative Feedback: $totalNegativeCount',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
            SizedBox(
              height: widget.isMobile ? 180 : 220,
              child: isLoading
                  ? Center(child: _buildLoadingIndicator())
                  : errorMessage != null
                  ? Center(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : negativeWords.isEmpty
                  ? Center(
                      child: Text(
                        'No recognized negative words found in feedback.',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.start,
                        children: negativeWords.map((wordData) {
                          return Chip(
                            label: Text(
                              '${wordData['word']} (${wordData['count']})',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 12 : 14,
                                color: Colors.indigo[900],
                              ),
                            ),
                            backgroundColor: Colors.red[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            SizedBox(height: 8),
            Text(
              'Top Negative Words (${widget.timePeriod})',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.indigo[900],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NegativeFeedbackDialog extends StatefulWidget {
  final VoidCallback onFeedbackViewed;

  const NegativeFeedbackDialog({Key? key, required this.onFeedbackViewed})
    : super(key: key);

  @override
  _NegativeFeedbackDialogState createState() => _NegativeFeedbackDialogState();
}

class _NegativeFeedbackDialogState extends State<NegativeFeedbackDialog> {
  Future<void> _markAsRead(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).update(
        {'read': true},
      );
      print('Feedback marked as read: $docId');
      Provider.of<FeedbackProvider>(
        context,
        listen: false,
      ).markFeedbackAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback marked as read'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error marking feedback as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFeedbackDetails(
    BuildContext context,
    bool isMobile,
    Map<String, dynamic> feedback,
    String docId,
    String doctor,
    String department,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Feedback Details',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Department: $department',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('Doctor: $doctor', style: GoogleFonts.poppins(fontSize: 14)),
              SizedBox(height: 8),
              Text(
                'Rating: ${feedback['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Comment: ${feedback['comment'] ?? 'No comment'}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Date: ${feedback['timestamp'] != null ? DateFormat('MMM d, yyyy HH:mm').format((feedback['timestamp'] as Timestamp).toDate()) : feedback['date'] ?? 'No date'}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.indigo[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _markAsRead(context, docId);
              Navigator.pop(context);
              widget.onFeedbackViewed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mark as Read',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(BuildContext context, bool isMobile, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respond to Feedback',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Your response',
            labelStyle: GoogleFonts.poppins(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.indigo[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Response submitted'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAppointmentDetails(
    String? appointmentId,
  ) async {
    if (appointmentId == null) {
      print('No appointmentId provided for feedback');
      return {'doctor': 'Unknown', 'department': 'Unknown'};
    }
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (docSnapshot.exists) {
        final appointment = docSnapshot.data()!;
        print('Found appointment $appointmentId: $appointment');
        return {
          'department': appointment['department'] ?? 'Unknown',
          'doctor': appointment['doctor'] ?? 'Unknown',
        };
      } else {
        print('Appointment $appointmentId not found');
      }
    } catch (e) {
      print('Error fetching appointment details for $appointmentId: $e');
    }
    return {'department': 'Unknown', 'doctor': 'Unknown'};
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.red[600],
            size: isMobile ? 20 : 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Negative Feedback',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
          ),
        ],
      ),
      content: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 400,
        height: isMobile ? MediaQuery.of(context).size.height * 0.6 : 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feedback')
              .where('sentiment', isEqualTo: 'Negative')
              .where('read', isEqualTo: false)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 8),
                    Text(
                      'Loading feedback...',
                      style: TextStyle(fontSize: 14, color: Colors.indigo),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              print('Error loading feedback: ${snapshot.error}');
              String errorMessage =
                  'Error: ${snapshot.error.toString().split(':').last.trim()}';
              if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
                errorMessage =
                    'Query requires a composite index. Create it in the Firebase Console.';
              } else if (snapshot.error.toString().contains(
                'permission-denied',
              )) {
                errorMessage = 'Permission denied: Please sign in as an admin.';
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 16,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          snapshot.error.toString().contains(
                            'FAILED_PRECONDITION',
                          )
                          ? () => print(
                              'Open Firebase Console for index creation.',
                            )
                          : () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        snapshot.error.toString().contains(
                              'FAILED_PRECONDITION',
                            )
                            ? 'Go to Console'
                            : 'Retry',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final feedbackItems = snapshot.hasData
                ? snapshot.data!.docs
                      .map(
                        (doc) => {
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        },
                      )
                      .toList()
                : [];

            if (feedbackItems.isEmpty) {
              print('No negative feedback found.');
              return Center(
                child: Text(
                  'No unread negative feedback found.',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              key: ValueKey('feedback_list'),
              shrinkWrap: true,
              itemCount: feedbackItems.length,
              itemBuilder: (context, index) {
                final feedback = feedbackItems[index];
                final docId = feedback['id'];
                final appointmentId = feedback['appointmentId']?.toString();
                return FutureBuilder<Map<String, dynamic>>(
                  future: _fetchAppointmentDetails(appointmentId),
                  builder: (context, apptSnapshot) {
                    String department = 'Unknown';
                    String doctor = 'Unknown';
                    if (apptSnapshot.connectionState == ConnectionState.done &&
                        apptSnapshot.hasData) {
                      department =
                          apptSnapshot.data!['department'] ?? 'Unknown';
                      doctor = apptSnapshot.data!['doctor'] ?? 'Unknown';
                    }
                    return Card(
                      key: ValueKey(docId),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: Colors.red[600],
                          size: isMobile ? 20 : 24,
                        ),
                        title: Text(
                          '$department ($doctor)', // Changed to department first
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 13 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rating: ${feedback['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 11 : 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feedback['comment'] ?? 'No comment',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feedback['timestamp'] != null
                                  ? DateFormat('MMM d, yyyy HH:mm').format(
                                      (feedback['timestamp'] as Timestamp)
                                          .toDate(),
                                    )
                                  : feedback['date']?.toString() ?? 'No date',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 10 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: isMobile
                            ? PopupMenuButton(
                                icon: Icon(Icons.more_vert, size: 20),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'mark_read',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[600],
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Mark as read',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'respond',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.chat,
                                          color: Colors.indigo[700],
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Respond',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'mark_read') {
                                    await _markAsRead(context, docId);
                                    widget.onFeedbackViewed();
                                  } else if (value == 'respond') {
                                    _showResponseDialog(
                                      context,
                                      isMobile,
                                      docId,
                                    );
                                  }
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green[600],
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      await _markAsRead(context, docId);
                                      widget.onFeedbackViewed();
                                    },
                                    tooltip: 'Mark as read',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chat,
                                      color: Colors.indigo[700],
                                      size: 20,
                                    ),
                                    onPressed: () => _showResponseDialog(
                                      context,
                                      isMobile,
                                      docId,
                                    ),
                                    tooltip: 'Respond',
                                  ),
                                ],
                              ),
                        onTap: () => _showFeedbackDetails(
                          context,
                          isMobile,
                          feedback,
                          docId,
                          doctor,
                          department,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.indigo[700],
            ),
          ),
        ),
      ],
    );
  }
}

class FeedbackProvider with ChangeNotifier {
  int _unreadNegativeFeedbackCount = 0;
  StreamSubscription<QuerySnapshot>? _feedbackSubscription;

  int get unreadNegativeFeedbackCount => _unreadNegativeFeedbackCount;

  FeedbackProvider() {
    _listenToFeedbackCount();
  }

  void _listenToFeedbackCount() {
    _feedbackSubscription?.cancel(); // Cancel any existing subscription
    _feedbackSubscription = FirebaseFirestore.instance
        .collection('feedback')
        .where('sentiment', isEqualTo: 'Negative')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            _unreadNegativeFeedbackCount = snapshot.docs.length;
            notifyListeners();
          },
          onError: (e) {
            print('Error listening to feedback count: $e');
          },
        );
  }

  void markFeedbackAsRead() {
    notifyListeners(); // Notify listeners to update UI
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }
}

class ResourceUtilizationCard extends StatelessWidget {
  final bool isMobile;
  final String timePeriod;
  final String selectedDepartment;

  const ResourceUtilizationCard({
    Key? key,
    required this.isMobile,
    required this.timePeriod,
    required this.selectedDepartment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = screenWidth < 360;
    final isSmall = screenWidth < 600;
    final isMedium = screenWidth < 900;

    // Dynamic sizing based on screen width
    final double fontSizeTitle = isUltraSmall
        ? 16
        : isSmall
        ? 18
        : 20;
    final double fontSizeSubtitle = isUltraSmall
        ? 12
        : isSmall
        ? 14
        : 16;
    final double padding = isUltraSmall
        ? 8
        : isSmall
        ? 12
        : 16;
    final double chartHeight = isUltraSmall
        ? 180
        : isSmall
        ? 200
        : 240;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.teal[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Tool Utilization',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal[100]!.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bar_chart,
                      color: Colors.teal[700],
                      size: isUltraSmall
                          ? 20
                          : isSmall
                          ? 22
                          : 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding * 0.5),
              Divider(color: Colors.teal[100]!.withOpacity(0.6), thickness: 1),
              SizedBox(height: padding * 0.5),
              SizedBox(
                height: chartHeight,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getResourceStatsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: _buildLoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      print(
                        'Error in ResourceUtilizationCard: ${snapshot.error}',
                      );
                      return Center(
                        child: Text(
                          'Error loading data: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final resources = snapshot.data ?? [];
                    if (resources.isEmpty) {
                      return Center(
                        child: Text(
                          'No tool allocation data available for $selectedDepartment ($timePeriod)',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeSubtitle,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Calculate maxY more robustly
                    final counts = resources
                        .map((res) => (res['count'] as int? ?? 0).toDouble())
                        .toList();
                    final maxCount = counts.isNotEmpty
                        ? counts.reduce((a, b) => a > b ? a : b)
                        : 0.0;
                    final maxY = maxCount > 0 ? maxCount * 1.2 : 10.0;

                    // Calculate appropriate interval
                    double interval;
                    if (maxY <= 5) {
                      interval = 1.0;
                    } else if (maxY <= 10) {
                      interval = 2.0;
                    } else if (maxY <= 20) {
                      interval = 5.0;
                    } else {
                      interval = (maxY / 5).ceilToDouble();
                    }

                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        barGroups: resources.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final count = (data['count'] as int? ?? 0).toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: count,
                                color: Colors.teal[700]!,
                                width: isMobile ? 20 : 30,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                // Only show integer values or if it's the first/last value
                                if (value == meta.min ||
                                    value == meta.max ||
                                    value % interval == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: isUltraSmall
                                            ? 10
                                            : isSmall
                                            ? 12
                                            : 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= resources.length)
                                  return const SizedBox();
                                final toolName =
                                    resources[value.toInt()]['name'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Transform.rotate(
                                    angle: isSmall ? -45 * 3.14159 / 180 : 0,
                                    child: Text(
                                      toolName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isUltraSmall
                                            ? 8
                                            : isSmall
                                            ? 10
                                            : 12,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.teal[200]!,
                            width: 1,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.teal[100]!.withOpacity(0.5),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                Colors.teal[900]!.withOpacity(0.9),
                            getTooltipItem: (group, groupIdx, rod, rodIdx) {
                              final toolName =
                                  resources[group.x.toInt()]['name'];
                              final count =
                                  resources[group.x.toInt()]['count'] as int? ??
                                  0;
                              return BarTooltipItem(
                                '$toolName\n$count Allocations',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isUltraSmall ? 10 : 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: padding * 0.5),
              Center(
                child: Text(
                  'Tool Allocations ($timePeriod)',
                  style: GoogleFonts.poppins(
                    fontSize: fontSizeSubtitle,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal[900],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.teal[700]),
        SizedBox(height: 6),
        Text(
          'Loading Data...',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.teal[900],
          ),
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _getResourceStatsStream() {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }
      print(
        'Streaming resource stats for timePeriod: $timePeriod, startDate: $startDate, department: $selectedDepartment',
      );

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'resources',
      );
      if (selectedDepartment != 'All') {
        query = query.where('department', isEqualTo: selectedDepartment);
      }
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );

      return query.snapshots().map((snapshot) {
        print('Resources found: ${snapshot.docs.length}');

        final toolCounts = <String, int>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) {
            print('Missing timestamp for resource ${doc.id}');
            continue;
          }
          final allocationDate = timestamp.toDate();
          if (allocationDate.isBefore(startDate)) {
            print('Skipping resource ${doc.id} with date $allocationDate');
            continue;
          }

          final toolName = data['name'] as String? ?? 'Unknown';
          toolCounts[toolName] = (toolCounts[toolName] ?? 0) + 1;
        }

        final result =
            toolCounts.entries
                .map((e) => {'name': e.key, 'count': e.value})
                .toList()
              ..sort((a, b) {
                final countA = a['count'] as int? ?? 0;
                final countB = b['count'] as int? ?? 0;
                return countB.compareTo(countA); // Descending order
              });

        print('Resource stats result: $result');
        return result.take(10).toList(); // Limit to top 10 tools for clarity
      });
    } catch (e, stackTrace) {
      print('Error streaming resource stats: $e\n$stackTrace');
      return Stream.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _getResourceStats() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (timePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }
      print(
        'Fetching resource stats for timePeriod: $timePeriod, startDate: $startDate, department: $selectedDepartment',
      );

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'resources',
      );
      if (selectedDepartment != 'All') {
        query = query.where('department', isEqualTo: selectedDepartment);
      }
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );

      final snapshot = await query.get();
      print('Resources found: ${snapshot.docs.length}');

      final toolCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp == null) {
          print('Missing timestamp for resource ${doc.id}');
          continue;
        }
        final allocationDate = timestamp.toDate();
        if (allocationDate.isBefore(startDate)) {
          print('Skipping resource ${doc.id} with date $allocationDate');
          continue;
        }

        final toolName = data['name'] as String? ?? 'Unknown';
        toolCounts[toolName] = (toolCounts[toolName] ?? 0) + 1;
      }

      final result =
          toolCounts.entries
              .map((e) => {'name': e.key, 'count': e.value})
              .toList()
            ..sort((a, b) {
              final countA = a['count'] as int? ?? 0;
              final countB = b['count'] as int? ?? 0;
              return countB.compareTo(countA); // Descending order
            });

      print('Resource stats result: $result');
      return result.take(10).toList(); // Limit to top 10 tools for clarity
    } catch (e, stackTrace) {
      print('Error fetching resource stats: $e\n$stackTrace');
      return [];
    }
  }
}

class AdminFeedbackPage extends StatefulWidget {
  final bool isMobile;

  const AdminFeedbackPage({Key? key, required this.isMobile}) : super(key: key);

  @override
  _AdminFeedbackPageState createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  String _selectedDepartment = 'All';
  String _selectedSentiment = 'All';
  String _selectedDoctor = 'All';
  List<String> _departments = ['All'];
  List<String> _doctors = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchDoctors();
  }

  Future<void> _fetchDepartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .get();
      final departments =
          snapshot.docs
              .map((doc) => doc.data()['department'] as String?)
              .where((dept) => dept != null && dept != 'Unknown')
              .map((dept) => dept!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _departments = ['All', ...departments];
      });
    } catch (e) {
      print('Error fetching departments: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .get();
      final doctors =
          snapshot.docs
              .map((doc) => doc.data()['doctor'] as String?)
              .where((doctor) => doctor != null && doctor != 'Unknown')
              .map((doctor) => doctor!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _doctors = ['All', ...doctors];
      });
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Patient Feedback',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.indigo[900],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'View and filter patient feedback',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Feedback Overview',
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.feedback, color: Colors.indigo[700], size: 24),
                    ],
                  ),
                  SizedBox(height: 8),
                  Divider(color: Colors.indigo[100], thickness: 1),
                  SizedBox(height: 12),
                  _buildFilters(),
                  SizedBox(height: 16),
                  _buildSentimentChart(),
                  SizedBox(height: 16),
                  _buildFeedbackList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: GoogleFonts.poppins(
            fontSize: widget.isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.indigo[900],
          ),
        ),
        SizedBox(height: 8),
        widget.isMobile
            ? Column(
                children: [
                  _buildDepartmentDropdown(),
                  SizedBox(height: 12),
                  _buildDoctorDropdown(),
                  SizedBox(height: 12),
                  _buildSentimentDropdown(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildDepartmentDropdown()),
                  SizedBox(width: 16),
                  Expanded(child: _buildDoctorDropdown()),
                  SizedBox(width: 16),
                  Expanded(child: _buildSentimentDropdown()),
                ],
              ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedDepartment,
        isExpanded: true,
        underline: SizedBox(),
        items: _departments.map<DropdownMenuItem<String>>((String dept) {
          return DropdownMenuItem<String>(
            value: dept,
            child: Text(
              dept,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.indigo[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedDepartment = value ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedDoctor,
        isExpanded: true,
        underline: SizedBox(),
        items: _doctors.map<DropdownMenuItem<String>>((String doctor) {
          return DropdownMenuItem<String>(
            value: doctor,
            child: Text(
              doctor,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.indigo[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedDoctor = value ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildSentimentDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedSentiment,
        isExpanded: true,
        underline: SizedBox(),
        items: ['All', 'Positive', 'Negative', 'Neutral']
            .map<DropdownMenuItem<String>>((String sentiment) {
              return DropdownMenuItem<String>(
                value: sentiment,
                child: Text(
                  sentiment,
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 15 : 17,
                    color: Colors.indigo[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            })
            .toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedSentiment = value ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildSentimentChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFeedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: widget.isMobile ? 200 : 250,
            child: _buildLoadingIndicator(),
          );
        }
        if (snapshot.hasError) {
          print('StreamBuilder error in sentiment chart: ${snapshot.error}');
          return SizedBox(
            height: widget.isMobile ? 200 : 250,
            child: Center(
              child: Text(
                'Error loading chart',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 15 : 17,
                  color: Colors.red[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox(
            height: widget.isMobile ? 200 : 250,
            child: Center(
              child: Text(
                'No feedback data for selected filters',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 15 : 17,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        final feedbackDocs = snapshot.data!.docs;
        int positive = 0, negative = 0, neutral = 0;
        for (var doc in feedbackDocs) {
          final sentiment =
              (doc.data() as Map<String, dynamic>)['sentiment'] as String? ??
              'Unknown';
          switch (sentiment) {
            case 'Positive':
              positive++;
              break;
            case 'Negative':
              negative++;
              break;
            case 'Neutral':
              neutral++;
              break;
          }
        }
        final total = positive + negative + neutral;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback Sentiment Distribution',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: widget.isMobile ? 200 : 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: total > 0 ? total.toDouble() * 1.2 : 10.0,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: positive.toDouble(),
                          color: Colors.green[600],
                          width: widget.isMobile ? 20 : 30,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: total.toDouble() * 1.2,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: negative.toDouble(),
                          color: Colors.red[600],
                          width: widget.isMobile ? 20 : 30,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: total.toDouble() * 1.2,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: neutral.toDouble(),
                          color: Colors.grey[600],
                          width: widget.isMobile ? 20 : 30,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: total.toDouble() * 1.2,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: total > 5 ? total / 5 : 1.0,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 12 : 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Positive', 'Negative', 'Neutral'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 12 : 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: total > 5 ? total / 5 : 1.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          Colors.indigo[900]!.withOpacity(0.8),
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        const titles = ['Positive', 'Negative', 'Neutral'];
                        return BarTooltipItem(
                          '${titles[group.x]}\n${rod.toY.toInt()}',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildFeedbackStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'feedback',
    );

    if (_selectedSentiment != 'All') {
      query = query.where('sentiment', isEqualTo: _selectedSentiment);
    }
    if (_selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: _selectedDepartment);
    }
    if (_selectedDoctor != 'All') {
      query = query.where('doctor', isEqualTo: _selectedDoctor);
    }

    return query.snapshots();
  }

  Widget _buildFeedbackList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFeedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading feedback',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.red[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print(
            'No feedback data for department: $_selectedDepartment, doctor: $_selectedDoctor',
          );
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No feedback available',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final feedbackDocs = snapshot.data!.docs;
        print(
          'Rendering ${feedbackDocs.length} feedback items for department: $_selectedDepartment, doctor: $_selectedDoctor',
        );
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedbackDocs.length,
          itemBuilder: (context, index) {
            final feedback = feedbackDocs[index].data() as Map<String, dynamic>;
            final department = feedback['department'] as String? ?? 'Unknown';
            final doctor = feedback['doctor'] as String? ?? 'Unknown';
            final date = feedback['date'] as String? ?? 'Unknown';
            final rating = feedback['rating']?.toString() ?? 'N/A';
            final comment = feedback['comment'] as String? ?? 'No comment';
            final sentiment = feedback['sentiment'] as String? ?? 'Unknown';
            return Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Department: $department',
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rating: $rating/5',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Doctor: $doctor',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Date: $date',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sentiment: $sentiment',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: _getSentimentColor(sentiment),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comment: $comment',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Positive':
        return Colors.green[600]!;
      case 'Negative':
        return Colors.red[600]!;
      case 'Neutral':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 12),
        Text(
          'Loading Feedback...',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.indigo[900]),
        ),
      ],
    );
  }
}

class SurveyResultsCard extends StatelessWidget {
  final bool isMobile;
  final String timePeriod;
  final String selectedDepartment;

  const SurveyResultsCard({
    Key? key,
    required this.isMobile,
    required this.timePeriod,
    required this.selectedDepartment,
  }) : super(key: key);

  final List<Map<String, dynamic>> _surveyQuestions = const [
    {
      'section': 'Infrastructures and Process',
      'questions': [
        {
          'id': 'q1',
          'text':
              'The waiting areas we used were clean, orderly, and comfortable.',
        },
        {
          'id': 'q2',
          'text':
              'The toilets and bathrooms inside the facility were kept clean, orderly and with a steady water supply.',
        },
        {
          'id': 'q3',
          'text': 'The patients’ rooms were clean, tidy, and comfortable.',
        },
        {
          'id': 'q4',
          'text':
              'The steps (including payment) I needed to do for my transaction were easy and simple.',
          'sqd': 'SQD3',
        },
        {
          'id': 'q5',
          'text':
              'The office followed the transaction’s requirements and steps based on the information provided.',
          'sqd': 'SQD2',
        },
        {
          'id': 'q6',
          'text':
              'I easily found information about my transaction from the office or its website.',
          'sqd': 'SQD4',
        },
        {
          'id': 'q7',
          'text': 'I spent a reasonable amount of time for my transaction.',
          'sqd': 'SQD1',
        },
      ],
    },
    {
      'section': 'Client Engagement and Empowerment',
      'questions': [
        {
          'id': 'q8',
          'text':
              'The medical condition, procedures, and instructions were discussed clearly.',
        },
        {
          'id': 'q9',
          'text':
              'Our sentiments, cultural background, and beliefs were heard and considered in the treatment procedure.',
        },
        {
          'id': 'q10',
          'text':
              'We were given the chance to decide which treatment procedure shall be performed.',
        },
        {
          'id': 'q11',
          'text':
              'I got what I needed from the hospital, or (if denied) denial of request was sufficiently explained to me.',
          'sqd': 'SQD8',
        },
        {
          'id': 'q12',
          'text': 'I paid a reasonable amount of fees for my transaction.',
          'sqd': 'SQD5',
        },
      ],
    },
    {
      'section': 'Culture of Responsiveness',
      'questions': [
        {
          'id': 'q13_doctor',
          'text':
              'I was treated courteously by the Doctor, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_nurse',
          'text':
              'I was treated courteously by the Nurse, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_midwife',
          'text':
              'I was treated courteously by the Midwife, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_security',
          'text':
              'I was treated courteously by the Security, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_radiology',
          'text':
              'I was treated courteously by the Radiology Staff, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_pharmacy',
          'text':
              'I was treated courteously by the Pharmacy, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_laboratory',
          'text':
              'I was treated courteously by the Laboratory, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_admitting',
          'text':
              'I was treated courteously by the Admitting Staff, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_medical_records',
          'text':
              'I was treated courteously by the Medical Records, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_billing',
          'text':
              'I was treated courteously by the Billing, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_cashier',
          'text':
              'I was treated courteously by the Cashier, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_social_worker',
          'text':
              'I was treated courteously by the Social Worker, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_food_server',
          'text':
              'I was treated courteously by the Food Server, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_janitors',
          'text':
              'I was treated courteously by the Janitors/Orderly, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q14',
          'text':
              'I was treated fairly, or “walang palakasan”, during my transaction.',
          'sqd': 'SQD6',
        },
        {
          'id': 'q15',
          'text': 'I am satisfied with the service that I availed.',
          'sqd': 'SQD0',
        },
      ],
    },
  ];

  final Map<String, double> _ratingValues = const {
    'Strongly Disagree': 1.0,
    'Disagree': 2.0,
    'Partially Agree': 3.0,
    'Agree': 4.0,
    'Strongly Agree': 5.0,
    'Not Applicable': 0.0,
  };

  Stream<Map<String, double>> _getSectionRatingsStream() {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'surveys',
      );

      DateTime now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = now;

      switch (timePeriod) {
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'All Time':
          startDate = null;
          endDate = null;
          break;
      }

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: DateFormat('MMM d, yyyy').format(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: DateFormat('MMM d, yyyy').format(endDate),
        );
      }

      if (selectedDepartment != 'All') {
        query = query.where('department', isEqualTo: selectedDepartment);
      }

      return query.snapshots().map((snapshot) {
        final sectionTotals = <String, double>{};
        final sectionCounts = <String, int>{};

        for (var doc in snapshot.docs) {
          final responses =
              (doc.data()['responses'] as Map<String, dynamic>?) ?? {};
          for (var section in _surveyQuestions) {
            final sectionName = section['section'] as String;
            sectionTotals[sectionName] = sectionTotals[sectionName] ?? 0.0;
            sectionCounts[sectionName] = sectionCounts[sectionName] ?? 0;
            for (var question in section['questions']) {
              final rating = responses[question['id']] as String?;
              if (rating != null &&
                  _ratingValues.containsKey(rating) &&
                  rating != 'Not Applicable') {
                sectionTotals[sectionName] =
                    sectionTotals[sectionName]! + _ratingValues[rating]!;
                sectionCounts[sectionName] = sectionCounts[sectionName]! + 1;
              }
            }
          }
        }

        return sectionTotals.map(
          (key, value) => MapEntry(
            key,
            sectionCounts[key]! > 0 ? value / sectionCounts[key]! : 0.0,
          ),
        );
      });
    } catch (e) {
      print('Error streaming section ratings: $e');
      return Stream.value({});
    }
  }

  Future<Map<String, double>> _getSectionRatings() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'surveys',
      );

      DateTime now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = now;

      switch (timePeriod) {
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'All Time':
          startDate = null;
          endDate = null;
          break;
      }

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: DateFormat('MMM d, yyyy').format(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: DateFormat('MMM d, yyyy').format(endDate),
        );
      }

      if (selectedDepartment != 'All') {
        query = query.where('department', isEqualTo: selectedDepartment);
      }

      final snapshot = await query.get();

      final sectionTotals = <String, double>{};
      final sectionCounts = <String, int>{};

      for (var doc in snapshot.docs) {
        final responses =
            (doc.data()['responses'] as Map<String, dynamic>?) ?? {};
        for (var section in _surveyQuestions) {
          final sectionName = section['section'] as String;
          sectionTotals[sectionName] = sectionTotals[sectionName] ?? 0.0;
          sectionCounts[sectionName] = sectionCounts[sectionName] ?? 0;
          for (var question in section['questions']) {
            final rating = responses[question['id']] as String?;
            if (rating != null &&
                _ratingValues.containsKey(rating) &&
                rating != 'Not Applicable') {
              sectionTotals[sectionName] =
                  sectionTotals[sectionName]! + _ratingValues[rating]!;
              sectionCounts[sectionName] = sectionCounts[sectionName]! + 1;
            }
          }
        }
      }

      return sectionTotals.map(
        (key, value) => MapEntry(
          key,
          sectionCounts[key]! > 0 ? value / sectionCounts[key]! : 0.0,
        ),
      );
    } catch (e) {
      print('Error fetching section ratings: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: StreamBuilder<Map<String, double>>(
            stream: _getSectionRatingsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: isMobile ? 200 : 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo[700]),
                      SizedBox(height: 12),
                      Text(
                        'Loading Survey Data...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                );
              }
              final ratings = snapshot.data ?? {};
              if (ratings.isEmpty) {
                return SizedBox(
                  height: isMobile ? 200 : 250,
                  child: Center(
                    child: Text(
                      'No survey data available.',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 15 : 17,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Survey Results',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.poll,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Divider(color: Colors.blue[100], thickness: 1),
                  SizedBox(height: 12),
                  SizedBox(
                    height: isMobile ? 200 : 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 5.0,
                        minY: 0.0,
                        barGroups: _surveyQuestions.asMap().entries.map((
                          entry,
                        ) {
                          final section = entry.value['section'] as String;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: ratings[section] ?? 0.0,
                                color: Colors.indigo[700],
                                width: isMobile ? 20 : 30,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 5.0,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              interval: 1.0,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final section =
                                    _surveyQuestions[value.toInt()]['section']
                                        as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Transform.rotate(
                                    angle: isMobile ? -45 * 3.14159 / 180 : 0,
                                    child: Text(
                                      section,
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 10 : 12,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1.0,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                Colors.indigo[900]!.withOpacity(0.8),
                            getTooltipItem: (group, groupIdx, rod, rodIdx) {
                              final section =
                                  _surveyQuestions[group.x.toInt()]['section']
                                      as String;
                              return BarTooltipItem(
                                '$section\n${rod.toY.toStringAsFixed(1)}',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==================== Admin Registration Page ====================
class AdminRegistrationPage extends StatefulWidget {
  final bool isMobile;

  const AdminRegistrationPage({Key? key, required this.isMobile})
    : super(key: key);

  @override
  _AdminRegistrationPageState createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentUserPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureCurrentUserPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentUserPasswordController.dispose();
    super.dispose();
  }

  // Map Firebase error codes to user-friendly messages
  String _getFriendlyErrorMessage(dynamic error) {
    String errorMessage = 'An unexpected error occurred. Please try again.';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage =
              'The password is too weak. Please use a stronger password.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect current admin password. Please try again.';
          break;
        case 'user-not-found':
          errorMessage = 'No user is currently logged in. Please log in again.';
          break;
        case 'invalid-credential':
          errorMessage =
              'Authentication credentials are invalid. Please log in again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage =
              'Authentication error: ${error.message ?? 'Unknown error'}';
      }
    } else if (error is FirebaseException &&
        error.code == 'permission-denied') {
      errorMessage = 'Permission denied. Ensure you are logged in as an admin.';
    } else {
      errorMessage = 'Error: ${error.toString()}';
    }
    return errorMessage;
  }

  Future<void> _registerAdmin() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Starting admin registration...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently logged in.',
        );
      }
      print('Current user: ${currentUser.email}');

      // Prevent registering the same email as the current user
      if (_emailController.text.trim() == currentUser.email) {
        throw Exception('Cannot register the same email as the current admin.');
      }

      // Verify the current user's role is admin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        print('User is not an admin: ${userDoc.data()?['role']}');
        throw Exception('You must be an admin to register a new admin.');
      }
      print('Current user is admin');

      // Reauthenticate the current user
      print('Attempting reauthentication for ${currentUser.email}');
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _currentUserPasswordController.text.trim(),
      );
      await currentUser.reauthenticateWithCredential(credential);
      print('Reauthentication successful');

      // Create new admin user
      print('Creating new user with email: ${_emailController.text.trim()}');
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      print('New user created: ${userCredential.user!.email}');

      // Store new user data in Firestore
      print('Writing new admin to Firestore: ${userCredential.user!.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _emailController.text.trim(),
            'role': 'admin',
            'createdAt': Timestamp.now(),
            'createdBy': currentUser.email, // Store the current admin's email
          });
      print('Firestore document created for new admin');

      // Clear form and show success
      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _currentUserPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin account created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(widget.isMobile ? 8 : 16),
          ),
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      setState(() {
        _errorMessage = _getFriendlyErrorMessage(e);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(widget.isMobile ? 8 : 16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Register New Admin',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.indigo[900],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Create a new admin account',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: widget.isMobile ? double.infinity : 500,
              padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Details',
                      style: GoogleFonts.poppins(
                        fontSize: widget.isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.email,
                          color: Colors.indigo[700],
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.indigo[700]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.indigo[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                          return 'Password must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                          return 'Password must contain at least one lowercase letter';
                        }
                        if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                          return 'Password must contain at least one number';
                        }
                        if (!RegExp(
                          r'(?=.*[!@#$%^&*(),.?":{}|<>])',
                        ).hasMatch(value)) {
                          return 'Password must contain at least one special character';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.indigo[700]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.indigo[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm the password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _currentUserPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Admin Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.security,
                          color: Colors.indigo[700],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentUserPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.indigo[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentUserPassword =
                                  !_obscureCurrentUserPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrentUserPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.indigo[700],
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _registerAdmin,
                            child: Text(
                              'Register Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
