import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServicesSection extends StatelessWidget {
  // Add a GlobalKey to identify the ServicesSection widget
  static final GlobalKey servicesSectionKey = GlobalKey();

  final List<Map<String, dynamic>> services = [
    {
      'image': 'assets/images/service0.png',
      'title': 'Emergency Care',
      'desc':
          'Available 24/7 for all emergency medical needs with state-of-the-art facilities.',
    },
    {
      'image': 'assets/images/service1.png',
      'title': 'Primary Care',
      'desc':
          'Comprehensive primary healthcare services for patients of all ages.',
    },
    {
      'image': 'assets/images/service2.png',
      'title': 'Specialized Treatment',
      'desc':
          'Expert specialists providing advanced care across multiple medical disciplines.',
    },
    {
      'image': 'assets/images/service3.png',
      'title': 'Laboratory Services',
      'desc': 'Advanced diagnostic testing with quick and accurate results.',
    },
    {
      'image': 'assets/images/service4.png',
      'title': 'Pharmacy',
      'desc':
          'On-site pharmacy providing prescription medications and health products.',
    },
    {
      'image': 'assets/images/service5.png',
      'title': 'Rehabilitation',
      'desc':
          'Rehabilitation services to help patients recover and regain independence.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final crossAxisCount = isMobile
            ? 1
            : isTablet
            ? 2
            : 3;
        final childAspectRatio = isMobile
            ? 0.8
            : isTablet
            ? 1.0
            : 1.2;
        return Container(
          key: servicesSectionKey, // Attach the key here
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 24 : 40,
            horizontal: constraints.maxWidth * 0.05,
          ),
          child: Column(
            children: [
              SectionHeader(
                title: 'Our Services',
                subtitle:
                    'Comprehensive medical services to meet all your healthcare needs.',
              ),
              SizedBox(height: isMobile ? 16 : 24),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isMobile ? 16 : 24,
                  mainAxisSpacing: isMobile ? 16 : 24,
                  mainAxisExtent: isMobile
                      ? null
                      : 320, // ✅ auto height on mobile
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final entry = services[index];
                  return ServiceCard(
                    image: entry['image'],
                    title: entry['title'],
                    desc: entry['desc'],
                    isMobile: isMobile,
                    isTablet: isTablet,
                    index: index,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ServiceCard extends StatefulWidget {
  final String image;
  final String title;
  final String desc;
  final bool isMobile;
  final bool isTablet;
  final int index;

  ServiceCard({
    required this.image,
    required this.title,
    required this.desc,
    required this.isMobile,
    required this.isTablet,
    required this.index,
  });

  @override
  _ServiceCardState createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800 + widget.index * 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('service_${widget.title}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_isVisible) {
          setState(() {
            _isVisible = true;
            _controller.forward();
          });
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _slideAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Card(
                  elevation: _isHovered ? 10 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _isHovered
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    transform: Matrix4.identity()
                      ..scale(_isHovered ? 1.03 : 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isHovered ? 0.2 : 0.08,
                          ),
                          blurRadius: _isHovered ? 14 : 8,
                          offset: Offset(0, _isHovered ? 8 : 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imageHeight = widget.isMobile
                            ? constraints.maxHeight *
                                  0.35 // reduced from 0.45
                            : constraints.maxHeight * 0.55;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image with Subtle Gradient Overlay
                            Stack(
                              children: [
                                Image.asset(
                                  widget.image,
                                  height: imageHeight,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'Failed to load image: $error\nPath: ${widget.image}\nStackTrace: $stackTrace\nCheck: Is ${widget.image} in assets/? Is pubspec.yaml correct?',
                                    );
                                    return Container(
                                      height: imageHeight,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Tooltip(
                                          message: 'Failed to load image',
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.redAccent,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: imageHeight * 0.4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.7),
                                          Colors.white,
                                        ],
                                        stops: [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Content
                            Padding(
                              padding: EdgeInsets.all(
                                widget.isMobile
                                    ? 14
                                    : widget.isTablet
                                    ? 16
                                    : 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize
                                    .min, // shrink-wrap instead of expanding
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getIconForService(widget.title),
                                        size: widget.isMobile
                                            ? 20
                                            : widget.isTablet
                                            ? 22
                                            : 24,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.title.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: widget.isMobile
                                                ? 16
                                                : widget.isTablet
                                                ? 18
                                                : 20,
                                            letterSpacing: 0.8,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.desc,
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.isMobile
                                          ? 14
                                          : widget.isTablet
                                          ? 15
                                          : 16,
                                      color: Colors.grey[800],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to assign icons based on service title
  IconData _getIconForService(String title) {
    switch (title.toLowerCase()) {
      case 'emergency care':
        return Icons.emergency;
      case 'primary care':
        return Icons.medical_services;
      case 'specialized treatment':
        return Icons.health_and_safety;
      case 'laboratory services':
        return Icons.science;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'rehabilitation':
        return Icons.accessibility_new;
      default:
        return Icons.medical_information;
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
