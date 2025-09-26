import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../admin/admin_dashboard.dart';
import '../users/auth_dialog.dart';
import '../users/survey_form.dart';
import '../users/service_section.dart';
import '../users/contact_service.dart';
import '../users/mission_vision.dart';
import '../users/doctor_service.dart';
import '../users/edit_appointment.dart';
import '../users/feedback_page.dart';
import 'dart:async';

// Text size provider for managing text scaling
class TextSizeProvider extends ChangeNotifier {
  double _textScaleFactor = 1.0;

  double get textScaleFactor => _textScaleFactor;

  void increaseTextSize() {
    if (_textScaleFactor < 1.3) {
      _textScaleFactor += 0.1;
      notifyListeners();
    }
  }

  void resetTextSize() {
    _textScaleFactor = 1.0;
    notifyListeners();
  }

  void decreaseTextSize() {
    if (_textScaleFactor > 0.7) {
      _textScaleFactor -= 0.1;
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Toggle this to true when testing locally with Firebase Emulator
  const bool useLocalEmulator = false;

  if (useLocalEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // If you have Functions:
    // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  final authService = AuthService();
  await authService.loadAuthState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider<FeedbackProvider>(
          create: (_) => FeedbackProvider(),
        ),
        ChangeNotifierProvider(create: (_) => TextSizeProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider(create: (_) => ContactService()),
        ChangeNotifierProvider(create: (_) => DoctorService()),
        Provider<TranslationService>(create: (_) => TranslationService()),
      ],
      child: GlobalCareApp(),
    ),
  );
}

class GlobalCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TextSizeProvider>(
      builder: (context, textSizeProvider, child) {
        return MaterialApp(
          title: 'Global Care Medical Center',
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            fontFamily: GoogleFonts.poppins().fontFamily,
            scaffoldBackgroundColor: Color(0xFFF8FAFC),
            textTheme: TextTheme(
              headlineMedium: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              titleLarge: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              bodyMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.black12,
              iconTheme: IconThemeData(color: Colors.indigo[900]),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: Colors.indigo.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size(100, 36),
                textStyle: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: BorderSide(color: Colors.indigo, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.black12,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => MainPage(),
            '/appointment-receipt': (context) => AppointmentReceiptPage(),
            '/admin': (context) => AdminDashboard(),
          },
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textSizeProvider.textScaleFactor),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  Widget _buildNavItem(
    BuildContext context,
    String title,
    int index,
    bool isActive,
    bool isMobile,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTap: () {
          if (Provider.of<AuthService>(context, listen: false).role ==
              'admin') {
            // No action; admins are redirected to /admin
          } else {
            DefaultTabController.of(context)?.animateTo(index);
            (context as Element).markNeedsBuild();
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.indigo[100]!.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.indigo[700] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AuthDialog());
  }

  void _showUserProfileMenu(
    BuildContext context,
    AuthService authService,
    bool isMobile,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;
    final menuWidth = 250.0; // Maintained width for balanced layout
    final menuPosition = RelativeRect.fromLTRB(
      buttonPosition.dx + buttonSize.width - menuWidth,
      buttonPosition.dy + buttonSize.height + 4,
      overlay.size.width - (buttonPosition.dx + buttonSize.width),
      overlay.size.height - (buttonPosition.dy + buttonSize.height),
    );

    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: menuPosition,
      items: <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: isMobile ? 20 : 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authService.fullname ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authService.email ?? 'No email',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Age: ${authService.age ?? 'Not set'}',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ), // Further reduced space between Age and Sex
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Sex: ${authService.sex != null && authService.sex!.isNotEmpty ? authService.sex![0] : 'Not set'}',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuDivider(
          height: 10,
          color: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.indigo[700],
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          onTap: () => authService.logout(),
        ),
        PopupMenuDivider(
          height: 10,
          color: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.delete,
                color: Colors.red[700],
                size: isMobile ? 16 : 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Account',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Delete Account',
                  style: theme.textTheme.titleLarge,
                ),
                content: Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  style: theme.textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await authService.deleteAccount();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account deleted successfully.',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red[700],
                ),
              );
            }
          },
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);

    if (authService.isLoggedIn && authService.role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin');
      });
      return SizedBox.shrink();
    }

    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 40,
                        width: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            'Failed to load Drawer logo: $error\nPath: assets/logo.png\nStackTrace: $stackTrace\nCheck: Is logo.png in assets/? Is pubspec.yaml correct?',
                          );
                          return Tooltip(
                            message: 'Failed to load logo.png',
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40, // Match the size for consistency
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Global Care',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo[900]!,
                          fontSize: isMobile ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                  if (isMobile) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.account_circle,
                            color: Colors.indigo[700]!,
                            size: MediaQuery.of(context).size.width < 600
                                ? 24
                                : 28,
                          ),
                          onPressed: () {
                            if (authService.isLoggedIn) {
                              _showUserProfileMenu(
                                context,
                                authService,
                                isMobile,
                              );
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                          tooltip: authService.isLoggedIn
                              ? 'User Profile'
                              : 'Login/Sign Up',
                        ),
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.indigo[700]!),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildNavItem(
                              context,
                              'Home',
                              0,
                              DefaultTabController.of(context)?.index == 0,
                              isMobile,
                            ),
                            SizedBox(width: 24),
                            _buildNavItem(
                              context,
                              'Appointments',
                              1,
                              DefaultTabController.of(context)?.index == 1,
                              isMobile,
                            ),
                            SizedBox(width: 24),
                            _buildNavItem(
                              context,
                              'Feedback',
                              2,
                              DefaultTabController.of(context)?.index == 2,
                              isMobile,
                            ),
                            SizedBox(width: 24),
                            _buildNavItem(
                              context,
                              'History',
                              3,
                              DefaultTabController.of(context)?.index == 3,
                              isMobile,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (!authService.isLoggedIn) ...[
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.indigo[700]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _showAuthDialog(context),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo[700],
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 6 : 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isMobile ? 4 : 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.indigo[700]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _showAuthDialog(context),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[700],
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 6 : 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: () => _showUserProfileMenu(
                              context,
                              authService,
                              isMobile,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.indigo.withOpacity(
                                      0.1,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.indigo[700]!,
                                      size: isMobile ? 20 : 24,
                                    ),
                                    radius: isMobile ? 14 : 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    authService.fullname ?? 'User',
                                    style: GoogleFonts.poppins(
                                      color: Colors.indigo[700]!,
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.indigo[700],
                                    size: isMobile ? 20 : 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        drawer: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            if (!isMobile) return SizedBox.shrink();
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo[700]!),
                    child: Row(
                      children: [
                        // For debugging, you can try 'logo.png' instead:
                        // Image.asset('logo.png', ...)
                        Image.asset(
                          'assets/logo.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Failed to load Drawer logo: $error\nPath: assets/logo.png\nStackTrace: $stackTrace\nCheck: Is logo.png in assets/? Is pubspec.yaml correct?',
                            );
                            return Tooltip(
                              message: 'Failed to load logo.png',
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 32,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Global Care',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home, color: Colors.indigo[700]!),
                    title: Text(
                      'Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: DefaultTabController.of(context)?.index == 0
                            ? Colors.indigo[700]
                            : Colors.black,
                        fontWeight: DefaultTabController.of(context)?.index == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      if (Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).role ==
                          'admin') {
                        // No action; admins are redirected to /admin
                      } else {
                        DefaultTabController.of(context)?.animateTo(0);
                        Navigator.pop(context);
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.event, color: Colors.indigo[700]!),
                    title: Text(
                      'Appointments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: DefaultTabController.of(context)?.index == 1
                            ? Colors.indigo[700]
                            : Colors.black,
                        fontWeight: DefaultTabController.of(context)?.index == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      if (Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).role ==
                          'admin') {
                        // No action; admins are redirected to /admin
                      } else {
                        DefaultTabController.of(context)?.animateTo(1);
                        Navigator.pop(context);
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.feedback, color: Colors.indigo[700]!),
                    title: Text(
                      'Feedback',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: DefaultTabController.of(context)?.index == 2
                            ? Colors.indigo[700]
                            : Colors.black,
                        fontWeight: DefaultTabController.of(context)?.index == 2
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      if (Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).role ==
                          'admin') {
                        // No action; admins are redirected to /admin
                      } else {
                        DefaultTabController.of(context)?.animateTo(2);
                        Navigator.pop(context);
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.history, color: Colors.indigo[700]!),
                    title: Text(
                      'History',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: DefaultTabController.of(context)?.index == 3
                            ? Colors.indigo[700]
                            : Colors.black,
                        fontWeight: DefaultTabController.of(context)?.index == 3
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      if (Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).role ==
                          'admin') {
                        // No action; admins are redirected to /admin
                      } else {
                        DefaultTabController.of(context)?.animateTo(3);
                        Navigator.pop(context);
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        body: TabBarView(
          children: [
            HomePage(),
            AppointmentPage(),
            FeedbackPage(),
            HistoryPage(),
          ],
        ),
        floatingActionButton: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFAB(
                    heroTag: 'decreaseText',
                    onPressed: textSizeProvider.decreaseTextSize,
                    tooltip: 'Decrease text size',
                    icon: Icons.text_decrease,
                    isMobile: isMobile,
                  ),
                  _buildFAB(
                    heroTag: 'resetText',
                    onPressed: textSizeProvider.resetTextSize,
                    tooltip: 'Reset text size',
                    icon: Icons.text_fields,
                    isMobile: isMobile,
                  ),
                  _buildFAB(
                    heroTag: 'increaseText',
                    onPressed: textSizeProvider.increaseTextSize,
                    tooltip: 'Increase text size',
                    icon: Icons.text_increase,
                    isMobile: isMobile,
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildFAB({
    required String heroTag,
    required VoidCallback onPressed,
    required String tooltip,
    required IconData icon,
    required bool isMobile,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.indigo[700]!, size: isMobile ? 18 : 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      constraints: BoxConstraints(),
      splashColor: Colors.blue[600]!,
      highlightColor: Colors.blue[400]!,
    );
  }
}

class FeedbackService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _sentimentApiUrl =
      'https://api-inference.huggingface.co/models/jcblaise/bert-tagalog-sentiment';
  static const String _apiKey = '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';

  static const List<String> _positiveEnglishKeywords = [
    'good',
    'great',
    'excellent',
    'awesome',
    'wonderful',
    'fantastic',
    'amazing',
    'happy',
    'satisfied',
    'love',
    'helpful',
    'professional',
    'friendly',
    'nice',
    'clean',
    'efficient',
    'courteous',
    'kind',
    'polite',
    'caring',
    'thank you',
    'perfect',
    'outstanding',
    'superb',
    'prompt',
    'reliable',
    'trustworthy',
    'appreciate',
    'commendable',
    'delightful',
    'impressive',
    'exceptional',
    'attentive',
    'supportive',
    'encouraging',
    'fast',
    'quick',
    'comfortable',
    'okay',
    'fine',
    'decent',
  ];

  static const List<String> _negativeEnglishKeywords = [
    'bad',
    'poor',
    'terrible',
    'awful',
    'disappointed',
    'unhappy',
    'worst',
    'horrible',
    'sad',
    'frustrating',
    'rude',
    'slow',
    'dirty',
    'unprofessional',
    'problem',
    'issue',
    'fail',
    'disappointing',
    'annoying',
    'unpleasant',
    'unsatisfactory',
    'inconvenient',
    'unacceptable',
    'unreliable',
    'neglectful',
    'careless',
    'inadequate',
    'frustrated',
    'confusing',
    'subpar',
    'lacking',
    'offensive',
    'irritating',
    'delayed',
    'overpriced',
  ];

  static const List<String> _neutralEnglishKeywords = [
    'improve',
    'improved',
    'improvement',
    'better',
    'enhance',
    'hope',
  ];

  static const List<String> _positiveTagalogKeywords = [
    'maganda',
    'mabuti',
    'masaya',
    'mahusay',
    'napakaganda',
    'salamat',
    'galing',
    'positibo',
    'magaling',
    'natutuwa',
    'kamangha-mangha',
    'perpekto',
    'malinis',
    'maayos',
    'saludo',
    'mabait',
    'maasikaso',
    'magalang',
    'mapagmalasakit',
    'komportable',
    'mabilis',
    'epektibo',
    'kaaya-aya',
    'mainam',
    'napakahusay',
    'napakagaling',
    'matulungin',
    'kahanga-handa',
    'maasahan',
    'mapagkakatiwalaan',
    'magiliw',
    'mapanuri',
    'maligaya',
    'natutuwang-natuwa',
    'pasasalamat',
    'saya',
    'sarap',
    'okay',
    'ayos',
  ];

  static const List<String> _negativeTagalogKeywords = [
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
    'overpriced',
    'hassle',
    'nakakairita',
    'nakakabwisit',
    'nakakasuya',
    'nakakagalit',
    'nakakapagod',
  ];

  static const List<String> _negationWords = [
    'hindi',
    'di',
    'wala',
    'walang',
    'huwag',
    'ayaw',
    'not',
    'never',
    'no',
    'don\'t',
    'doesn\'t',
    'didn\'t',
    'won\'t',
    'wouldn\'t',
    'shouldn\'t',
  ];

  static const List<String> _contrastWords = [
    'pero',
    'kaso',
    'subalit',
    'ngunit',
    'but',
    'however',
    'although',
    'yet',
    'despite',
    'kaso lang',
  ];

  static const Map<String, String> _tagalogPhrases = {
    'maganda ang': 'positive',
    'mabuti ang': 'positive',
    'mahusay ang': 'positive',
    'maayos ang': 'positive',
    'okay naman ang': 'positive',
    'okay at maayos naman ang': 'positive',
    'salamat sa': 'positive',
    'maraming salamat': 'positive',
    'salamat po': 'positive',
    'ang ganda ng': 'positive',
    'ang husay ng': 'positive',
    'ang bait ng': 'positive',
    'ang linis ng': 'positive',
    'ang bilis ng': 'positive',
    'sobrang ganda': 'positive',
    'sobrang husay': 'positive',
    'sobrang bait': 'positive',
    'sobrang saya': 'positive',
    'ang galing talaga': 'positive',
    'napakaganda ng': 'positive',
    'napakahusay ng': 'positive',
    'napakabait ng': 'positive',
    'walang problema': 'positive',
    'gusto ko ang': 'positive',
    'ang sarap ng': 'positive',
    'hindi ako nahirapan': 'positive',
    'hindi maayos ang': 'negative',
    'hindi ayos ang': 'negative',
    'hindi maganda ang': 'negative',
    'hindi pa available': 'negative',
    'hindi available ang': 'negative',
    'hindi okay o maganda': 'negative',
    'hindi mabuti ang': 'negative',
    'pangit ang': 'negative',
    'masama ang': 'negative',
    'ang tagal ng': 'negative',
    'ang bagal ng': 'negative',
    'ang init ng': 'negative',
    'ang sikip ng': 'negative',
    'ang hirap ng': 'negative',
    'sobrang tagal': 'negative',
    'sobrang bagal': 'negative',
    'nakakainis talaga': 'negative',
    'hindi ko gusto': 'negative',
    'hindi ko type': 'negative',
    'may problema': 'negative',
    'ang pangit ng': 'negative',
    'sana ay umayos': 'negative',
    'kailangan ayusin': 'negative',
    'dapat ayusin': 'negative',
    'nakakabigo ang': 'negative',
    'nakakainis ang': 'negative',
    'maganda naman': 'neutral',
    'mabuti naman': 'neutral',
    'maayos naman': 'neutral',
    'okay naman': 'neutral',
    'sana ma-improve': 'neutral',
    'sana ma-improve pa lalo': 'neutral',
    'pero sana': 'neutral',
    'kaso lang': 'neutral',
    'pero may': 'neutral',
    'kahit maganda': 'neutral',
  };

  static const Map<String, String> _englishPhrases = {
    'the service was good': 'positive',
    'great service': 'positive',
    'excellent service': 'positive',
    'very satisfied': 'positive',
    'really nice': 'positive',
    'thank you for': 'positive',
    'amazing experience': 'positive',
    'wonderful staff': 'positive',
    'highly recommend': 'positive',
    'very professional': 'positive',
    'the service was okay': 'positive',
    'service was fine': 'positive',
    'the service was bad': 'negative',
    'poor service': 'negative',
    'terrible experience': 'negative',
    'very disappointing': 'negative',
    'not satisfied': 'negative',
    'really slow': 'negative',
    'unacceptable service': 'negative',
    'needs improvement': 'negative',
    'bad at all': 'negative',
    'horrible staff': 'negative',
    'the service was okay but': 'neutral',
    'pretty good but': 'neutral',
    'nice but needs': 'neutral',
    'could be better': 'neutral',
    'okay but': 'neutral',
    'not bad but': 'neutral',
    'needs more cleaning': 'neutral',
    'good but could': 'neutral',
    'decent but': 'neutral',
    'hope it can be improved': 'neutral',
    'could be improved': 'neutral',
    'needs to be improved': 'neutral',
    'can be further improved': 'neutral',
    'service was fine but': 'neutral',
    'fine but could': 'neutral',
    'fine but needs': 'neutral',
  };

  String _preprocessText(String text) {
    String cleanedText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s!?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    cleanedText = cleanedText
        .replaceAll('di ', 'hindi ')
        .replaceAll("'y ", ' ay ')
        .replaceAll("'ng ", ' ang ')
        .replaceAll(' d ', ' hindi ')
        .replaceAll('dont ', 'don\'t ')
        .replaceAll('doesnt ', 'doesn\'t ')
        .replaceAll('didnt ', 'didn\'t ');

    return cleanedText;
  }

  Map<String, bool> _detectLanguages(String text) {
    final tagalogIndicators = [
      'ang',
      'ng',
      'sa',
      'at',
      'ay',
      'ko',
      'mo',
      'kami',
      'kay',
      'siya',
      'namin',
      'ninyo',
      'sila',
      'ito',
      'iyan',
      'doon',
      'dito',
      'din',
      'rin',
      'mga',
      'kung',
      'pag',
      'para',
      'nang',
      'ni',
      'na',
      'po',
    ];

    final englishIndicators = [
      'the',
      'and',
      'to',
      'of',
      'a',
      'in',
      'is',
      'it',
      'that',
      'for',
      'you',
      'this',
      'with',
      'are',
      'on',
      'not',
      'have',
      'be',
      'was',
      'were',
      'will',
      'can',
      'do',
      'does',
      'did',
      'overall',
    ];

    final words = text.toLowerCase().split(' ');
    int tagalogCount = 0;
    int englishCount = 0;

    for (var word in words) {
      if (tagalogIndicators.contains(word)) tagalogCount++;
      if (englishIndicators.contains(word)) englishCount++;
    }

    bool isTagalog =
        tagalogCount >= 2 || (tagalogCount >= 1 && englishCount == 0);
    bool isEnglish =
        englishCount >= 2 || (englishCount >= 1 && tagalogCount == 0);
    bool isTaglish = tagalogCount >= 1 && englishCount >= 1;

    return {'tagalog': isTagalog, 'english': isEnglish, 'taglish': isTaglish};
  }

  String _keywordBasedSentiment(String text, {int? rating}) {
    double positiveScore = 0.0;
    double negativeScore = 0.0;
    bool hasContrast = _contrastWords.any((word) => text.contains(' $word '));

    print('Processing text: $text');
    print('Phrase matches:');
    _tagalogPhrases.forEach((phrase, sentiment) {
      if (text.contains(phrase)) {
        print('$phrase -> $sentiment');
        if (sentiment == 'positive') {
          positiveScore += 8.0;
        } else if (sentiment == 'negative') {
          negativeScore += 8.0;
        } else if (sentiment == 'neutral') {
          positiveScore += 3.0;
          negativeScore += 3.0;
        }
      }
    });

    _englishPhrases.forEach((phrase, sentiment) {
      if (text.contains(phrase)) {
        print('$phrase -> $sentiment');
        if (sentiment == 'positive') {
          positiveScore += 8.0;
        } else if (sentiment == 'negative') {
          negativeScore += 8.0;
        } else if (sentiment == 'neutral') {
          positiveScore += 3.0;
          negativeScore += 3.0;
        }
      }
    });

    final words = text.split(' ');
    bool isNegated = false;
    int negationWindow = 4;
    int currentIndex = 0;

    print('Keyword matches:');
    for (var word in words) {
      if (_negationWords.contains(word)) {
        isNegated = true;
        negationWindow = 4;
        print('Negation detected: $word');
        currentIndex++;
        continue;
      }

      if (isNegated && negationWindow > 0) {
        if (_positiveEnglishKeywords.contains(word) ||
            _positiveTagalogKeywords.contains(word)) {
          negativeScore += 5.0;
          print('Negated positive keyword: $word -> +5.0 to negativeScore');
        } else if (_negativeEnglishKeywords.contains(word) ||
            _negativeTagalogKeywords.contains(word)) {
          positiveScore += 5.0;
          print('Negated negative keyword: $word -> +5.0 to positiveScore');
        }
        negationWindow--;
      } else {
        if (_positiveEnglishKeywords.contains(word) ||
            _positiveTagalogKeywords.contains(word)) {
          positiveScore += 2.5;
          print('Positive keyword: $word -> +2.5 to positiveScore');
        } else if (_negativeEnglishKeywords.contains(word) ||
            _negativeTagalogKeywords.contains(word)) {
          negativeScore += 2.5;
          print('Negative keyword: $word -> +2.5 to negativeScore');
        } else if (_neutralEnglishKeywords.contains(word)) {
          positiveScore += 1.5;
          negativeScore += 1.5;
          print('Neutral keyword: $word -> +1.5 to both scores');
        }
      }

      if (negationWindow <= 0) {
        isNegated = false;
      }
      currentIndex++;
    }

    print('Scores: positiveScore=$positiveScore, negativeScore=$negativeScore');
    print('Has contrast: $hasContrast');

    if (hasContrast && positiveScore > 0) {
      print('Neutral due to contrast word after positive sentiment');
      return 'Neutral';
    }

    if (rating != null) {
      if (rating >= 4) {
        positiveScore += 3.0;
        print('Rating $rating adds +3.0 to positiveScore');
      } else if (rating <= 2) {
        negativeScore += 3.0;
        print('Rating $rating adds +3.0 to negativeScore');
      } else if (rating == 3) {
        positiveScore += 2.0;
        negativeScore += 2.0;
        print('Rating $rating adds +2.0 to both scores (neutral)');
      }
    }

    if (positiveScore > negativeScore + 5.0) {
      print('Returning Positive');
      return 'Positive';
    } else if (negativeScore > positiveScore + 5.0) {
      print('Returning Negative');
      return 'Negative';
    }
    print('Returning Neutral (default)');
    return 'Neutral';
  }

  int? _getRating(Map<String, dynamic>? feedback) {
    return feedback != null && feedback.containsKey('rating')
        ? feedback['rating'] as int?
        : null;
  }

  Future<String> analyzeSentiment(
    String comment, {
    Map<String, dynamic>? feedback,
  }) async {
    try {
      final processedComment = _preprocessText(comment);
      final languages = _detectLanguages(processedComment);
      final isTagalog = languages['tagalog']!;
      final isEnglish = languages['english']!;
      final isTaglish = languages['taglish']!;
      final rating = _getRating(feedback);

      final keywordSentiment = _keywordBasedSentiment(
        processedComment,
        rating: rating,
      );

      if (isTagalog || isTaglish) {
        print(
          'Tagalog/Taglish content detected, using keyword analysis: $keywordSentiment',
        );
        return keywordSentiment;
      }

      final response = await http.post(
        Uri.parse(_sentimentApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'inputs': processedComment}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final label = result[0]['label'];
        final confidence = result[0]['score'] as double;

        String apiSentiment = label == 'POSITIVE'
            ? 'Positive'
            : label == 'NEGATIVE'
            ? 'Negative'
            : 'Neutral';

        print(
          'Sentiment Analysis: Comment="$comment"\n'
          'API Result: $apiSentiment ($label, confidence: ${confidence.toStringAsFixed(2)})\n'
          'Keyword Result: $keywordSentiment\n'
          'Languages: Tagalog=$isTagalog, English=$isEnglish, Taglish=$isTaglish\n'
          'Rating: $rating',
        );

        if (isEnglish && confidence >= 0.9) {
          return apiSentiment;
        }

        if (isTaglish || confidence < 0.9) {
          return keywordSentiment;
        }

        if (keywordSentiment == 'Neutral' && confidence >= 0.7) {
          return apiSentiment;
        }

        return keywordSentiment;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return keywordSentiment;
      }
    } catch (e) {
      print('Error calling sentiment API: $e');
      return _keywordBasedSentiment(
        _preprocessText(comment),
        rating: _getRating(feedback),
      );
    }
  }

  Future<List<Map<String, dynamic>>> loadFeedback() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
        .collection('feedback')
        .where('userId', isEqualTo: user.uid)
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  Future<void> saveSurvey(Map<String, dynamic> survey) async {
    try {
      await _firestore.collection('surveys').add(survey);
    } catch (e) {
      print('Error saving survey: $e');
      rethrow;
    }
  }

  Future<void> saveFeedback(Map<String, dynamic> feedback) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    feedback['userId'] = user.uid;
    feedback['timestamp'] =
        FieldValue.serverTimestamp(); // Add timestamp for clarity
    feedback['sentiment'] = feedback['comment']?.isNotEmpty == true
        ? await analyzeSentiment(feedback['comment'], feedback: feedback)
        : null;

    // Fetch the most recent appointment for the user
    final latestAppointment = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (latestAppointment.docs.isNotEmpty) {
      final appointmentData = latestAppointment.docs.first.data();
      feedback['appointmentId'] =
          latestAppointment.docs.first.id; // Link to most recent appointment
      feedback['department'] = appointmentData['department'] ?? 'Unknown';
      feedback['doctor'] = appointmentData['doctor'] ?? 'Unknown';
    } else {
      // Handle case where no appointments exist
      feedback['appointmentId'] = null;
      feedback['department'] = 'Unknown';
      feedback['doctor'] = 'Unknown';
    }

    await _firestore.collection('feedback').add(feedback);
    notifyListeners();
  }

  Future<void> clearFeedback() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('feedback')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    notifyListeners();
  }
}

class FeedbackPage extends StatefulWidget {
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return Container(
                    color: Color(0xFFF8FAFC),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 32 : 48,
                      horizontal: constraints.maxWidth * 0.05,
                    ),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Text(
                              'Your Feedback Matters',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 26 : 30,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Help us improve by sharing your experience.',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 500),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 800),
                              padding: EdgeInsets.all(isMobile ? 20 : 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TabButton(
                                          label: 'Feedback',
                                          active: tabIndex == 0,
                                          onTap: () =>
                                              setState(() => tabIndex = 0),
                                        ),
                                      ),
                                      Expanded(
                                        child: TabButton(
                                          label: 'Survey',
                                          active: tabIndex == 1,
                                          onTap: () =>
                                              setState(() => tabIndex = 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 16 : 24),
                                  !authService.isLoggedIn
                                      ? _buildLoginPrompt(isMobile)
                                      : tabIndex == 0
                                      ? FeedbackForm(isMobile: isMobile)
                                      : SurveyForm(isMobile: isMobile),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 32 : 48),
                      ],
                    ),
                  );
                },
              ),
              FooterSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.lock, size: isMobile ? 36 : 40, color: Colors.indigo[700]),
        SizedBox(height: 16),
        Text(
          'Sign in to share your feedback',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'Please login or create an account to provide your valuable feedback.',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 15,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            showDialog(context: context, builder: (context) => AuthDialog());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 12 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            'Login / Sign Up',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class TranslationService {
  static const String _translateUrl = 'https://api.mymemory.translated.net/get';
  static const String _detectUrl = 'https://api.mymemory.translated.net/detect';

  Future<bool> isTagalog(String text) async {
    try {
      final response = await http.get(
        Uri.parse('$_detectUrl?q=${Uri.encodeComponent(text)}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Detected language: ${data['responseData']['language']}');
        return data['responseData']['language'] == 'tl';
      }
      return false;
    } catch (e) {
      print('Language detection error: $e');
      return false;
    }
  }

  Future<String> translateToEnglish(
    String text, {
    required String sourceLanguage,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_translateUrl?q=${Uri.encodeComponent(text)}&langpair=$sourceLanguage|en',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Translated text: ${data['responseData']['translatedText']}');
        return data['responseData']['translatedText'] ?? text;
      }
      return text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeroSection(),
          MissionVisionSection(),
          ServicesSection(),
          ContactSectionWrapper(),
          FooterSection(),
        ],
      ),
    );
  }
}

class AppointmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [AppointmentSection(), FooterSection()]),
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [HistorySection(), FooterSection()]),
    );
  }
}

class AuthService extends ChangeNotifier {
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phoneNumber;
  int? _age;
  String? _sex;
  String? _role;
  bool _isLoggedIn = false;

  // Getters
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String get fullname => '${_firstName ?? ''} ${_lastName ?? ''}'.trim();
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  int? get age => _age;
  String? get sex => _sex;
  String? get role => _role;
  bool get isLoggedIn => _isLoggedIn;

  /// Loads the authentication state and user data from Firebase
  Future<void> loadAuthState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          _isLoggedIn = true;
          _firstName = userDoc.data()?['firstName'] ?? '';
          _lastName = userDoc.data()?['lastName'] ?? '';
          _email = user.email;
          _phoneNumber = userDoc.data()?['phoneNumber'] ?? '';
          _age = userDoc.data()?['age'];
          _sex = userDoc.data()?['sex'] ?? '';
          _role = userDoc.data()?['role'] ?? 'user';
        } else {
          _isLoggedIn = false;
          _firstName = null;
          _lastName = null;
          _email = null;
          _phoneNumber = null;
          _age = null;
          _sex = null;
          _role = null;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading auth state: $e');
    }
  }

  /// Sends a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Logs in a user with email and password
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await loadAuthState();
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Checks if an email is already registered in Firebase Authentication
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Use Firebase Authentication's fetchSignInMethodsForEmail to check if email exists
      final signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email.trim());
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email in Firebase Auth: $e');
      return false;
    }
  }

  /// Signs up a new user with first name, last name, email, phone number, age, sex, and password
  Future<void> signup(
    String firstName,
    String lastName,
    String email,
    String phoneNumber,
    String password, {
    required int age,
    required String sex,
  }) async {
    try {
      // Check if email exists in Firebase Authentication
      final isRegistered = await isEmailRegistered(email);
      if (isRegistered) {
        throw Exception('email-already-in-use');
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'firstName': firstName.trim(),
            'lastName': lastName.trim(),
            'email': email.trim(),
            'phoneNumber': phoneNumber.trim(),
            'age': age,
            'sex': sex,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
      _isLoggedIn = true;
      _firstName = firstName.trim();
      _lastName = lastName.trim();
      _email = email.trim();
      _phoneNumber = phoneNumber.trim();
      _age = age;
      _sex = sex;
      _role = 'user';
      notifyListeners();
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _isLoggedIn = false;
      _firstName = null;
      _lastName = null;
      _email = null;
      _phoneNumber = null;
      _age = null;
      _sex = null;
      _role = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Deletes the current user's account
  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Delete Firebase Authentication user
        await user.delete();

        _isLoggedIn = false;
        _firstName = null;
        _lastName = null;
        _email = null;
        _phoneNumber = null;
        _age = null;
        _sex = null;
        _role = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error during account deletion: $e');
      throw e;
    }
  }
}

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final int maxAppointmentsPerSlot = 10;

  Future<List<Map<String, dynamic>>> loadAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  Future<void> saveAppointment(Map<String, dynamic> appointment) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    appointment['userId'] = user.uid;

    // Parse the date string to extract date and start time
    final dateString = appointment['date'] as String? ?? '';
    final datePart = dateString.split(' at ')[0]; // Extract "Sep 8, 2025"
    final timeRange = dateString.split(
      ' at ',
    )[1]; // Extract "08:00 AM-10:00 AM"
    final startTime = timeRange.split('-')[0].trim(); // Extract "08:00 AM"
    final date = DateFormat('MMM d, yyyy').parse(datePart);
    final year = date.year.toString().substring(
      2,
    ); // Last 2 digits (e.g., "25")
    final month = date.month.toString().padLeft(2, '0'); // e.g., "09"
    final day = date.day.toString().padLeft(2, '0'); // e.g., "08"
    final doctor =
        appointment['doctor'] as String? ?? ''; // e.g., "Dra. Ashley R. Medina"

    // Extract doctor initials, removing "Dr." or "Dra." prefix
    String doctorName = doctor;
    if (doctorName.toLowerCase().startsWith('dr. ')) {
      doctorName = doctorName.substring(4).trim();
    } else if (doctorName.toLowerCase().startsWith('dra. ')) {
      doctorName = doctorName.substring(5).trim();
    }
    final doctorInitials = doctorName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0] : '')
        .join('')
        .toUpperCase(); // e.g., "AM" for "Ashley R. Medina"

    // Query existing appointments for the same doctor, date, and time slot
    final snapshot = await _firestore
        .collection('appointments')
        .where('doctor', isEqualTo: doctor)
        .where('date', isGreaterThanOrEqualTo: datePart)
        .where('date', isLessThan: '$datePart\uf8ff')
        .where('status', isNotEqualTo: 'Cancelled')
        .get();

    // Count appointments for the specific time slot
    int slotCount = 0;
    for (var doc in snapshot.docs) {
      final docDateTime = doc.data()['date'] as String;
      if (docDateTime.startsWith(datePart) && docDateTime.contains(startTime)) {
        slotCount++;
      }
    }
    slotCount += 1; // Next patient ID

    // Check if the slot is fully booked
    if (slotCount > maxAppointmentsPerSlot) {
      throw Exception('Time slot is fully booked for this doctor and date.');
    }

    // Generate patientId (e.g., AM25-0908-001)
    final patientIdNumber = slotCount.toString().padLeft(3, '0');
    final patientId =
        '${doctorInitials}${year}-${month}${day}-${patientIdNumber}';

    // Update appointment with parsed date, time, and patient ID
    appointment['date'] = dateString;
    appointment['time'] = startTime;
    appointment['patientId'] = patientId;
    await _firestore.collection('appointments').add(appointment);
    notifyListeners();
  }

  Future<void> clearAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    notifyListeners();
  }

  Future<List<String>> getBookedSlots(String doctor, DateTime date) async {
    try {
      final formattedDate = DateFormat('MMM d, yyyy').format(date);
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor', isEqualTo: doctor)
          .where('date', isGreaterThanOrEqualTo: formattedDate)
          .where('date', isLessThan: '$formattedDate\uf8ff')
          .where('status', isNotEqualTo: 'Cancelled')
          .get();

      final Map<String, int> slotCounts = {};
      for (var doc in snapshot.docs) {
        final appointmentDateTime = doc.data()['date'] as String;
        if (appointmentDateTime.startsWith(formattedDate)) {
          final time = appointmentDateTime
              .split(' at ')[1]
              .split('-')[0]
              .trim();
          slotCounts[time] = (slotCounts[time] ?? 0) + 1;
        }
      }

      final bookedSlots = slotCounts.entries
          .where((entry) => entry.value >= maxAppointmentsPerSlot)
          .map((entry) => entry.key)
          .toList();

      print(
        'getBookedSlots: Booked slots for $doctor on $formattedDate: $bookedSlots',
      );
      return bookedSlots;
    } catch (e) {
      print('getBookedSlots: Error: $e');
      return [];
    }
  }

  Future<bool> isTimeSlotBooked(
    String doctor,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      final formattedDate = DateFormat('MMM d, yyyy').format(date);
      final dateTimeString = '$formattedDate at $timeSlot';

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor', isEqualTo: doctor)
          .where('date', isEqualTo: dateTimeString)
          .where('status', isNotEqualTo: 'Cancelled')
          .get();

      final isBooked = snapshot.docs.length >= maxAppointmentsPerSlot;
      print(
        'isTimeSlotBooked: $doctor on $dateTimeString has ${snapshot.docs.length} appointments, booked: $isBooked',
      );
      return isBooked;
    } catch (e) {
      print('isTimeSlotBooked: Error: $e');
      return true;
    }
  }

  Future<void> cancelAppointment(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('appointments').doc(id).update({
      'status': 'Cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> updateAppointment(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    updatedData['userId'] = user.uid;
    updatedData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('appointments').doc(id).update(updatedData);
    notifyListeners();
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({Key? key}) : super(key: key);

  // Function to scroll to ServicesSection
  void _scrollToServicesSection(BuildContext context) {
    final RenderBox? renderBox =
        ServicesSection.servicesSectionKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox != null) {
      Scrollable.of(context).position.ensureVisible(
        renderBox,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Services Section not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final screenHeight = MediaQuery.of(context).size.height;

        return Stack(
          children: [
            Container(
              height: screenHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/2094Calamba_City_Canlubang_Roads_Landmarks_Barangays_31.jpg/1200px-2094Calamba_City_Canlubang_Roads_Landmarks_Barangays_31.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              height: screenHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xAA1E40AF), Color(0x803B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Container(
              height: screenHeight,
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: isMobile ? 16 : 24,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 1000),
                    child: Text(
                      'Welcome to Global Care Medical Center',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isMobile ? 24 : 36,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  AnimatedSlide(
                    offset: const Offset(0, 0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    child: Text(
                      'Providing compassionate care and cutting-edge medical services to our community. At Global, We Care!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 28,
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        onPressed: () {
                          if (authService.isLoggedIn) {
                            try {
                              final tabController = DefaultTabController.of(
                                context,
                              );
                              if (tabController != null) {
                                tabController.animateTo(1);
                                (context as Element).markNeedsBuild();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Navigation error. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Navigation error: $e')),
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => const AuthDialog(),
                            );
                          }
                        },
                        child: Text(
                          'Book Appointment',
                          style: GoogleFonts.poppins(
                            color: Colors.indigo[700],
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 28,
                            vertical: isMobile ? 12 : 16,
                          ),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          _scrollToServicesSection(
                            context,
                          ); // Scroll to ServicesSection
                        },
                        child: Text(
                          'Learn More',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  HeroStats(isMobile: isMobile),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class HeroStats extends StatelessWidget {
  final bool isMobile;
  HeroStats({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 1500),
      child: Container(
        margin: EdgeInsets.only(top: isMobile ? 12 : 24),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: isMobile ? 20 : 40,
          runSpacing: 12,
          children: [
            StatItem(
              icon: Icons.medical_services,
              number: '210+',
              label: 'Expert Doctors',
              isMobile: isMobile,
            ),
            StatItem(
              icon: Icons.local_hospital,
              number: '150+',
              label: 'Departments',
              isMobile: isMobile,
            ),
            StatItem(
              icon: Icons.people,
              number: '10K+',
              label: 'Happy Patients',
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final bool isMobile;
  const StatItem({
    required this.icon,
    required this.number,
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: isMobile ? 24 : 32),
        SizedBox(height: 4),
        Text(
          number,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class AppointmentSection extends StatefulWidget {
  const AppointmentSection({Key? key}) : super(key: key);

  @override
  State<AppointmentSection> createState() => _AppointmentSectionState();
}

class _AppointmentSectionState extends State<AppointmentSection> {
  int tabIndex = 0; // 0: New Appointment, 1: Upcoming (no Resource Requests)

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Container(
              color: Color(0xFFF8FAFC),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 24 : 40,
                horizontal: constraints.maxWidth * 0.05,
              ),
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Book an Appointment',
                    subtitle:
                        'Schedule your visit with our expert medical professionals.',
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        children: [
                          // Only two tabs: New Appointment and Upcoming
                          Row(
                            children: [
                              Expanded(
                                child: TabButton(
                                  label: 'New Appointment',
                                  active: tabIndex == 0,
                                  onTap: () => setState(() => tabIndex = 0),
                                ),
                              ),
                              Expanded(
                                child: TabButton(
                                  label: 'Upcoming Appointments',
                                  active: tabIndex == 1,
                                  onTap: () => setState(() => tabIndex = 1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 16 : 24),
                          if (!authService.isLoggedIn)
                            Column(
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: isMobile ? 32 : 40,
                                  color: Colors.indigo[700],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Please login or sign up to book or view appointments',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AuthDialog(),
                                  ),
                                  child: Text('Login / Sign Up'),
                                ),
                              ],
                            )
                          else
                            tabIndex == 0
                                ? AppointmentForm(isMobile: isMobile)
                                : UpcomingAppointments(isMobile: isMobile),
                        ],
                      ),
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
}

class UpcomingAppointments extends StatelessWidget {
  final bool isMobile;
  const UpcomingAppointments({Key? key, required this.isMobile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appointmentService = Provider.of<AppointmentService>(context);
    final _dateFormat = DateFormat("MMM d, yyyy 'at' h:mm a");

    // Function to show cancel confirmation dialog
    Future<void> _confirmCancel(
      BuildContext context,
      String appointmentId,
    ) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Cancel Appointment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'No',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await appointmentService.cancelAppointment(appointmentId);
          // Delete associated resources
          final resourcesSnapshot = await FirebaseFirestore.instance
              .collection('resources')
              .where('appointmentId', isEqualTo: appointmentId)
              .get();
          for (var doc in resourcesSnapshot.docs) {
            await doc.reference.delete();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment canceled successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel appointment: $e')),
          );
        }
      }
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: appointmentService.loadAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Error loading appointments: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('No appointments loaded from AppointmentService');
          return const Center(child: Text('No upcoming appointments.'));
        }

        // Filter upcoming appointments
        final now =
            DateTime.now(); // Current date and time: 2025-09-17 22:39 PST
        final upcoming = snapshot.data!.where((appointment) {
          try {
            // Extract start time from "MMM d, yyyy at h:mm a-h:mm a"
            final dateString = appointment['date'].split(
              '-',
            )[0]; // e.g., "Sep 11, 2025 at 03:00 PM"
            final appointmentDateTime = _dateFormat.parse(
              dateString + ' +0800',
            ); // Assume UTC+8
            final isUpcoming = !appointmentDateTime.isBefore(now);
            print(
              'Appointment: ${appointment['date']}, Parsed: $appointmentDateTime, IsUpcoming: $isUpcoming',
            );
            return isUpcoming; // Optionally add: && appointment['status'] == 'Upcoming'
          } catch (e) {
            print(
              'Error parsing date for appointment: ${appointment['date']}, Error: $e',
            );
            return false; // Exclude appointments with invalid dates
          }
        }).toList();

        if (upcoming.isEmpty) {
          print(
            'No upcoming appointments after filtering. Total appointments: ${snapshot.data!.length}',
          );
          return const Center(child: Text('No upcoming appointments.'));
        }

        print('Upcoming appointments found: ${upcoming.length}');
        return ListView.builder(
          shrinkWrap: true,
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            final appointment = upcoming[index];
            // Format the date for display
            String displayDate;
            try {
              final dateTime = _dateFormat.parse(
                appointment['date'].split('-')[0] + ' +0800',
              );
              displayDate = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
            } catch (e) {
              print(
                'Error formatting display date: ${appointment['date']}, Error: $e',
              );
              displayDate = appointment['date']; // Fallback to raw date
            }
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ExpansionTile(
                title: Text(
                  '${appointment['doctor']} - ${appointment['department']}',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Date: $displayDate',
                  style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient: ${appointment['patientName'] ?? 'Unknown'}',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        Text(
                          'Reason: ${appointment['reason'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Allocated Resources',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('resources')
                              .where(
                                'appointmentId',
                                isEqualTo: appointment['id'],
                              )
                              .snapshots(),
                          builder: (context, resourceSnapshot) {
                            if (resourceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text(
                                'Loading resources...',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            }
                            if (resourceSnapshot.hasError) {
                              print(
                                'Error loading resources: ${resourceSnapshot.error}',
                              );
                              return Text(
                                'Error loading resources: ${resourceSnapshot.error}',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.red[600],
                                ),
                              );
                            }
                            if (!resourceSnapshot.hasData ||
                                resourceSnapshot.data!.docs.isEmpty) {
                              return Text(
                                'No resources allocated.',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: resourceSnapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                DateTime? startTime;
                                DateTime? endTime;
                                try {
                                  startTime = _dateFormat.parse(
                                    data['startTime'],
                                  );
                                  endTime = _dateFormat.parse(data['endTime']);
                                } catch (e) {
                                  print('Error parsing resource times: $e');
                                  return Text(
                                    'Invalid time format for resource: ${data['name']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.red[600],
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resource: ${data['name']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 13 : 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Department: ${data['department']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 12 : 13,
                                        ),
                                      ),
                                      Text(
                                        'Time: ${_dateFormat.format(startTime)} - ${_dateFormat.format(endTime)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 12 : 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Edit Button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAppointmentScreen(
                                      appointment: appointment,
                                      isMobile: isMobile,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit, size: isMobile ? 18 : 20),
                              label: Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.indigo[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 8 : 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cancel Button
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _confirmCancel(context, appointment['id']),
                              icon: Icon(
                                Icons.cancel,
                                size: isMobile ? 18 : 20,
                              ),
                              label: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 8 : 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: active ? Colors.indigo[700] : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : Color(0xFF6B7280),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: active ? Colors.white : Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AppointmentForm extends StatefulWidget {
  final bool isMobile;
  AppointmentForm({required this.isMobile});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  DateTime? selectedDate;
  String? selectedTime;
  String? department;
  String? doctor;
  String? appointmentType;
  final reasonController = TextEditingController();

  final appointmentTypes = [
    'New Patient',
    'Follow-up',
    'Emergency',
    'Consultation',
    'Procedure',
  ];

  List<String> departments = [];
  List<Map<String, dynamic>> doctorList = [];

  List<String> get doctors => department != null
      ? doctorList
            .where((doc) => doc['department'] == department)
            .map((doc) => doc['name'] as String)
            .toList()
      : [];

  Future<List<String>> getTimeSlots() async {
    if (department == null || doctor == null || selectedDate == null) {
      print(
        'getTimeSlots: Missing required fields - '
        'department: $department, doctor: $doctor, selectedDate: $selectedDate',
      );
      return [];
    }
    final dayOfWeek = DateFormat('EEEE').format(selectedDate!);
    print('getTimeSlots: Day of week: $dayOfWeek');
    final selectedDoctor = doctorList.firstWhere(
      (doc) => doc['name'] == doctor && doc['department'] == department,
      orElse: () => {},
    );
    if (selectedDoctor.isEmpty) {
      print(
        'getTimeSlots: No doctor found for name: $doctor, department: $department',
      );
      return [];
    }
    final availability = selectedDoctor['availability']?[dayOfWeek];
    if (availability is! List) {
      print('getTimeSlots: No availability for $doctor on $dayOfWeek');
      return [];
    }
    print(
      'getTimeSlots: Raw availability for $doctor on $dayOfWeek: $availability',
    );
    final bookedSlots = await Provider.of<AppointmentService>(
      context,
      listen: false,
    ).getBookedSlots(doctor!, selectedDate!);
    print(
      'getTimeSlots: Booked slots for $doctor on $selectedDate: $bookedSlots',
    );
    final availableSlots = List<String>.from(
      availability,
    ).where((slot) => !bookedSlots.contains(slot)).toList();
    print('getTimeSlots: Available slots after filtering: $availableSlots');
    return availableSlots;
  }

  @override
  void initState() {
    super.initState();
    _loadDepartmentsAndDoctors();
  }

  Future<void> _loadDepartmentsAndDoctors() async {
    final doctorService = Provider.of<DoctorService>(context, listen: false);
    final doctors = await doctorService.loadDoctors();
    setState(() {
      doctorList = doctors.map((doc) {
        final availability = doc['availability'] as Map<String, dynamic>;
        return {
          ...doc,
          'availability': availability.map((key, value) {
            return MapEntry(
              key,
              value is List ? List<String>.from(value) : <String>[],
            );
          }),
        };
      }).toList();
      departments =
          doctors.map((doc) => doc['department'] as String).toSet().toList()
            ..sort();
      print('Loaded departments: $departments');
      print('Loaded doctorList: $doctorList');
    });
  }

  static String _formatHour(int h) => (h % 12 == 0 ? 12 : h % 12).toString();
  static String _ampm(int h) => h < 12 ? 'AM' : 'PM';

  Future<void> _submit() async {
    String? errorMessage;
    if (selectedDate == null) {
      errorMessage = 'Please select a date.';
    } else if (selectedTime == null) {
      errorMessage = 'Please select a time slot.';
    } else if (department == null) {
      errorMessage = 'Please select a department.';
    } else if (doctor == null) {
      errorMessage = 'Please select a doctor.';
    } else if (appointmentType == null) {
      errorMessage = 'Please select an appointment type.';
    } else {
      final appointmentService = Provider.of<AppointmentService>(
        context,
        listen: false,
      );
      final isBooked = await appointmentService.isTimeSlotBooked(
        doctor!,
        selectedDate!,
        selectedTime!,
      );
      print(
        'Submitting: Checking if slot is booked for $doctor on $selectedDate at $selectedTime: $isBooked',
      );
      if (isBooked) {
        errorMessage =
            'This time slot has reached its limit of 10 patients for the selected doctor.';
      }
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final appointment = {
      'avatar':
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${doctor!.replaceAll(' ', '')}',
      'doctor': doctor!,
      'department': department!,
      'type': appointmentType!,
      'date':
          DateFormat('MMM d, yyyy').format(selectedDate!) + ' at $selectedTime',
      'status': 'Upcoming',
      'reason': reasonController.text,
      'userId': Provider.of<AuthService>(context, listen: false).email ?? '',
    };

    try {
      await Provider.of<AppointmentService>(
        context,
        listen: false,
      ).saveAppointment(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment scheduled successfully!')),
        );
        Navigator.pushNamed(
          context,
          '/appointment-receipt',
          arguments: {
            'date': selectedDate!,
            'time': selectedTime!,
            'doctor': doctor!,
            'department': department!,
            'appointmentType': appointmentType!,
            'reason': reasonController.text,
            'username':
                Provider.of<AuthService>(context, listen: false).fullname ??
                'Guest',
          },
        );
        setState(() {
          selectedDate = null;
          selectedTime = null;
          department = null;
          doctor = null;
          appointmentType = null;
          reasonController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buildContext) => widget.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date & Time',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  onDateChanged: (date) => setState(() {
                    selectedDate = date;
                    selectedTime = null;
                    print('Date changed to: $date');
                  }),
                ),
                SizedBox(height: 12),
                Text(
                  'Available Time Slots',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: getTimeSlots(),
                  builder: (context, snapshot) {
                    print(
                      'FutureBuilder state: ${snapshot.connectionState}, '
                      'hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
                    );
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      print('FutureBuilder error: ${snapshot.error}');
                      return Text(
                        'Error loading time slots: ${snapshot.error}',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          color: Colors.red[400],
                        ),
                      );
                    }
                    final timeSlots = snapshot.data ?? [];
                    print('FutureBuilder timeSlots: $timeSlots');
                    if (timeSlots.isEmpty &&
                        department != null &&
                        doctor != null &&
                        selectedDate != null) {
                      return Text(
                        'No available time slots for selected doctor and date.',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          color: Colors.red[400],
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: timeSlots
                          .map(
                            (slot) => ChoiceChip(
                              label: Text(slot),
                              selected: selectedTime == slot,
                              onSelected: (_) => setState(() {
                                selectedTime = slot;
                                print('Selected time slot: $slot');
                              }),
                              selectedColor: Colors.indigo[700],
                              labelStyle: GoogleFonts.poppins(
                                color: selectedTime == slot
                                    ? Colors.white
                                    : Colors.indigo[700],
                                fontSize: widget.isMobile ? 14 : 16,
                              ),
                              backgroundColor: Colors.indigo.withOpacity(0.05),
                              side: BorderSide(color: Colors.indigo[700]!),
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.isMobile ? 12 : 16,
                                vertical: widget.isMobile ? 6 : 8,
                              ),
                              elevation: selectedTime == slot ? 2 : 0,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Appointment Details',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.05),
                  ),
                  value: department,
                  items: departments
                      .map(
                        (dept) =>
                            DropdownMenuItem(value: dept, child: Text(dept)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    department = value;
                    doctor = null;
                    selectedTime = null;
                    print('Department changed to: $value');
                  }),
                  hint: Text('Select Department'),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Doctor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.05),
                  ),
                  value: doctor,
                  items: doctors
                      .map(
                        (doc) => DropdownMenuItem(value: doc, child: Text(doc)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    doctor = value;
                    selectedTime = null;
                    print('Doctor changed to: $value');
                  }),
                  hint: Text('Select Doctor'),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Appointment Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.05),
                  ),
                  value: appointmentType,
                  items: appointmentTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    appointmentType = value;
                    print('Appointment type changed to: $value');
                  }),
                  hint: Text('Select Appointment Type'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Appointment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.05),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Schedule Appointment',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date & Time',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      CalendarDatePicker(
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        onDateChanged: (date) => setState(() {
                          selectedDate = date;
                          selectedTime = null;
                          print('Date changed to: $date');
                        }),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Available Time Slots',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: getTimeSlots(),
                        builder: (context, snapshot) {
                          print(
                            'FutureBuilder state: ${snapshot.connectionState}, '
                            'hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
                          );
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            print('FutureBuilder error: ${snapshot.error}');
                            return Text(
                              'Error loading time slots: ${snapshot.error}',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 14 : 16,
                                color: Colors.red[400],
                              ),
                            );
                          }
                          final timeSlots = snapshot.data ?? [];
                          print('FutureBuilder timeSlots: $timeSlots');
                          if (timeSlots.isEmpty &&
                              department != null &&
                              doctor != null &&
                              selectedDate != null) {
                            return Text(
                              'No available time slots for selected doctor and date.',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 14 : 16,
                                color: Colors.red[400],
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timeSlots
                                .map(
                                  (slot) => ChoiceChip(
                                    label: Text(slot),
                                    selected: selectedTime == slot,
                                    onSelected: (_) => setState(() {
                                      selectedTime = slot;
                                      print('Selected time slot: $slot');
                                    }),
                                    selectedColor: Colors.indigo[700],
                                    labelStyle: GoogleFonts.poppins(
                                      color: selectedTime == slot
                                          ? Colors.white
                                          : Colors.indigo[700],
                                      fontSize: widget.isMobile ? 14 : 16,
                                    ),
                                    backgroundColor: Colors.indigo.withOpacity(
                                      0.05,
                                    ),
                                    side: BorderSide(
                                      color: Colors.indigo[700]!,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: widget.isMobile ? 12 : 16,
                                      vertical: widget.isMobile ? 6 : 8,
                                    ),
                                    elevation: selectedTime == slot ? 2 : 0,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Details',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.indigo.withOpacity(0.05),
                        ),
                        value: department,
                        items: departments
                            .map(
                              (dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          department = value;
                          doctor = null;
                          selectedTime = null;
                          print('Department changed to: $value');
                        }),
                        hint: Text('Select Department'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Doctor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.indigo.withOpacity(0.05),
                        ),
                        value: doctor,
                        items: doctors
                            .map(
                              (doc) => DropdownMenuItem(
                                value: doc,
                                child: Text(doc),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          doctor = value;
                          selectedTime = null;
                          print('Doctor changed to: $value');
                        }),
                        hint: Text('Select Doctor'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Appointment Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.indigo.withOpacity(0.05),
                        ),
                        value: appointmentType,
                        items: appointmentTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          appointmentType = value;
                          print('Appointment type changed to: $value');
                        }),
                        hint: Text('Select Appointment Type'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason for Appointment',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.indigo.withOpacity(0.05),
                        ),
                        minLines: 3,
                        maxLines: 5,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Schedule Appointment',
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 15 : 16,
                            fontWeight: FontWeight.w600,
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

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}

class AppointmentHistory extends StatelessWidget {
  final bool isMobile;

  const AppointmentHistory({Key? key, required this.isMobile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<AppointmentService>(context).loadAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('No appointments loaded from AppointmentService');
          return Center(
            child: Text(
              'No past appointments available.',
              style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
            ),
          );
        }

        // Filter past appointments
        final now =
            DateTime.now(); // Current date and time: 2025-09-17 22:33 PST
        final dateFormat = DateFormat("MMM d, yyyy 'at' h:mm a");
        final pastAppointments = snapshot.data!.where((appointment) {
          try {
            // Extract the start time from "MMM d, yyyy at h:mm a-h:mm a"
            final dateString = appointment['date'].split(
              '-',
            )[0]; // Get "Sep 11, 2025 at 03:00 PM"
            final appointmentDateTime = dateFormat.parse(
              dateString + ' +0800',
            ); // Assume UTC+8
            final isPast = appointmentDateTime.isBefore(now);
            print(
              'Appointment: ${appointment['date']}, Parsed: $appointmentDateTime, IsPast: $isPast',
            );
            return isPast;
          } catch (e) {
            print(
              'Error parsing date for appointment: ${appointment['date']}, Error: $e',
            );
            return false; // Exclude appointments with invalid dates
          }
        }).toList();

        if (pastAppointments.isEmpty) {
          print(
            'No past appointments after filtering. Total appointments: ${snapshot.data!.length}',
          );
          return Center(
            child: Text(
              'No past appointments available.',
              style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
            ),
          );
        }

        print('Past appointments found: ${pastAppointments.length}');
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pastAppointments.length,
          itemBuilder: (context, index) {
            final appointment = pastAppointments[index];
            // Format the date for display
            String displayDate;
            try {
              final dateTime = dateFormat.parse(
                appointment['date'].split('-')[0] + ' +0800',
              );
              displayDate = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
            } catch (e) {
              displayDate = appointment['date']; // Fallback to raw date
            }
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(appointment['avatar']),
                ),
                title: Text(
                  appointment['doctor'],
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment['department']} - ${appointment['type']}',
                      style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
                    ),
                    Text(
                      displayDate,
                      style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
                    ),
                    Text(
                      'Status: ${appointment['status']}',
                      style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
                    ),
                    if (appointment['reason'].isNotEmpty)
                      Text(
                        'Reason: ${appointment['reason']}',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                  ],
                ),
                trailing: Icon(
                  Icons.event,
                  color: Colors.indigo[700],
                  size: isMobile ? 24 : 28,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HistorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Container(
              color: const Color(0xFFF8FAFC),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 24 : 40,
                horizontal: constraints.maxWidth * 0.05,
              ),
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Your History',
                    subtitle: 'View your past appointments and feedback.',
                  ),
                  SizedBox(height: isMobile ? 12 : 24),
                  if (!authService.isLoggedIn)
                    Column(
                      children: [
                        Icon(
                          Icons.lock,
                          size: isMobile ? 32 : 40,
                          color: Colors.indigo[700],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please login to view your history',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AuthDialog(),
                            );
                          },
                          child: const Text('Login / Sign Up'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Past Appointments',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppointmentHistory(isMobile: isMobile),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Feedback',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: Provider.of<FeedbackService>(
                                    context,
                                  ).loadFeedback(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'No feedback submitted yet.',
                                          style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                        ),
                                      );
                                    }
                                    final feedbackList = snapshot.data!;
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: feedbackList.length,
                                      itemBuilder: (context, index) {
                                        final feedback = feedbackList[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.indigo
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.feedback,
                                                color: Colors.indigo[700],
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  'Rating: ',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    feedback['rating'] as int,
                                                    (index) => Icon(
                                                      Icons.star,
                                                      color: Colors.yellow[700],
                                                      size: isMobile ? 16 : 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Doctor: ${feedback['doctor'] ?? 'Unknown'}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isMobile
                                                        ? 12
                                                        : 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.indigo[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  feedback['comment'],
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isMobile
                                                        ? 12
                                                        : 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  feedback['date'],
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isMobile
                                                        ? 12
                                                        : 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await Provider.of<AppointmentService>(
                                context,
                                listen: false,
                              ).clearAppointments();
                              await Provider.of<FeedbackService>(
                                context,
                                listen: false,
                              ).clearFeedback();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'All data cleared successfully',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to clear data: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Clear All Data',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class FooterLink {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  FooterLink({required this.text, this.icon, required this.onTap});
}

class FooterColumn extends StatelessWidget {
  final String title;
  final List<FooterLink> items;
  final bool isMobile;

  FooterColumn({
    required this.title,
    required this.items,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: item.onTap,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      color: Colors.white.withOpacity(0.7),
                      size: isMobile ? 16 : 18,
                    ),
                    SizedBox(width: 8),
                  ],
                  Text(
                    item.text,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          color: Colors.indigo[900],
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 24 : 40,
            horizontal: constraints.maxWidth * 0.05,
          ),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      children: [
                        FooterColumn(
                          title: 'Quick Links',
                          items: [
                            FooterLink(
                              text: 'Home',
                              onTap: () => DefaultTabController.of(
                                context,
                              )?.animateTo(0),
                            ),
                            FooterLink(
                              text: 'Appointments',
                              onTap: () => DefaultTabController.of(
                                context,
                              )?.animateTo(1),
                            ),
                            FooterLink(
                              text: 'Feedback',
                              onTap: () => DefaultTabController.of(
                                context,
                              )?.animateTo(2),
                            ),
                            FooterLink(
                              text: 'History',
                              onTap: () => DefaultTabController.of(
                                context,
                              )?.animateTo(3),
                            ),
                          ],
                          isMobile: isMobile,
                        ),
                        SizedBox(height: 24),
                        FooterColumn(
                          title: 'Contact Info',
                          items: [
                            FooterLink(
                              text: 'J. Yulo Avenue, Brgy. Canlubang',
                              icon: Icons.location_on,
                              onTap: () {},
                            ),
                            FooterLink(
                              text: 'gcmccanlubang@gmail.com',
                              icon: Icons.email,
                              onTap: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'gcmccanlubang@gmail.com',
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                            ),
                            FooterLink(
                              text: '(049) 520-5626',
                              icon: Icons.phone,
                              onTap: () async {
                                final Uri phoneUri = Uri(
                                  scheme: 'tel',
                                  path: '(049) 520-5626',
                                );
                                if (await canLaunchUrl(phoneUri)) {
                                  await launchUrl(phoneUri);
                                }
                              },
                            ),
                          ],
                          isMobile: isMobile,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FooterColumn(
                            title: 'Quick Links',
                            items: [
                              FooterLink(
                                text: 'Home',
                                onTap: () => DefaultTabController.of(
                                  context,
                                )?.animateTo(0),
                              ),
                              FooterLink(
                                text: 'Appointments',
                                onTap: () => DefaultTabController.of(
                                  context,
                                )?.animateTo(1),
                              ),
                              FooterLink(
                                text: 'Feedback',
                                onTap: () => DefaultTabController.of(
                                  context,
                                )?.animateTo(2),
                              ),
                              FooterLink(
                                text: 'History',
                                onTap: () => DefaultTabController.of(
                                  context,
                                )?.animateTo(3),
                              ),
                            ],
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: FooterColumn(
                            title: 'Contact Info',
                            items: [
                              FooterLink(
                                text: 'J. Yulo Avenue, Brgy. Canlubang',
                                icon: Icons.location_on,
                                onTap: () {},
                              ),
                              FooterLink(
                                text: 'gcmccanlubang@gmail.com',
                                icon: Icons.email,
                                onTap: () async {
                                  final Uri emailUri = Uri(
                                    scheme: 'mailto',
                                    path: 'gcmccanlubang@gmail.com',
                                  );
                                  if (await canLaunchUrl(emailUri)) {
                                    await launchUrl(emailUri);
                                  }
                                },
                              ),
                              FooterLink(
                                text: '(049) 520-5626',
                                icon: Icons.phone,
                                onTap: () async {
                                  final Uri phoneUri = Uri(
                                    scheme: 'tel',
                                    path: '(049) 520-5626',
                                  );
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri);
                                  }
                                },
                              ),
                            ],
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 24 : 40),
              Text(
                '© 2025 Global Care Medical Center. All rights reserved.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class AppointmentReceiptPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Appointment Receipt',
            style: GoogleFonts.poppins(
              color: Colors.indigo[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No appointment details available.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    final appointmentService = Provider.of<AppointmentService>(
      context,
      listen: false,
    );
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Receipt',
          style: GoogleFonts.poppins(
            color: Colors.indigo[900],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchAppointmentDetails(appointmentService, user, args),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching appointment details: ${snapshot.error}',
                  ),
                );
              }
              final appointment = snapshot.data ?? {};
              final patientId = appointment['patientId'] as String? ?? 'N/A';

              return SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 20 : 30,
                    horizontal: constraints.maxWidth * 0.1,
                  ),
                  child: Column(
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.lightBlue[50],
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: isMobile ? 40 : 50,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Appointment Confirmation',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[900],
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Patient ID: $patientId',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: Colors.white,
                                child: Container(
                                  width: isMobile
                                      ? constraints.maxWidth * 0.8
                                      : 400,
                                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ReceiptItem(
                                        label: 'Date',
                                        value: args['date'] != null
                                            ? DateFormat(
                                                'MMMM d, yyyy',
                                              ).format(args['date'] as DateTime)
                                            : 'N/A',
                                        isMobile: isMobile,
                                      ),
                                      ReceiptItem(
                                        label: 'Time',
                                        value: args['time'] as String? ?? 'N/A',
                                        isMobile: isMobile,
                                      ),
                                      ReceiptItem(
                                        label: 'Doctor',
                                        value:
                                            args['doctor'] as String? ?? 'N/A',
                                        isMobile: isMobile,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Note:',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '1. Appointment time may adjust slightly due to ongoing appointments before you.',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              Text(
                                '2. Minors must be accompanied by a guardian.',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'PLEASE TAKE A SCREENSHOT OR PRINT THIS RECEIPT FOR YOUR EASY REFERENCE.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'KINDLY ARRIVE ON TIME, AND CANCEL YOUR APPOINTMENT AHEAD OF TIME IF YOU ARE UNABLE TO ATTEND.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(120, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.indigo[900],
                                    ),
                                    child: Text(
                                      'Done',
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(120, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.indigo[900],
                                    ),
                                    child: Text(
                                      'Download PDF',
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAppointmentDetails(
    AppointmentService service,
    User? user,
    Map<String, dynamic>? args,
  ) async {
    if (user == null ||
        args == null ||
        args['date'] == null ||
        args['time'] == null ||
        args['doctor'] == null) {
      return {};
    }

    try {
      final appointments = await service.loadAppointments();
      final formattedDate = DateFormat(
        'MMM d, yyyy',
      ).format(args['date'] as DateTime);
      final dateTimeString = '$formattedDate at ${args['time']}';
      final matchingAppointment = appointments.firstWhere(
        (appt) =>
            appt['userId'] == user.uid &&
            appt['date'] == dateTimeString &&
            appt['doctor'] == args['doctor'],
        orElse: () => {},
      );
      return matchingAppointment;
    } catch (e) {
      print('Error fetching appointment details: $e');
      return {};
    }
  }
}

class ReceiptItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isMobile;

  const ReceiptItem({
    Key? key,
    required this.label,
    required this.value,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centered alignment
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              textAlign: TextAlign.center, // Centered text
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center, // Centered text
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
