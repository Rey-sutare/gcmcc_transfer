import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MissionVisionSection extends StatelessWidget {
  final List<Map<String, dynamic>> missionVision = [
    {
      'title': 'Our Mission',
      'icon': Icons.track_changes,
      'content':
          "To improve patient's lives by providing safe, effective and suitable medical services performed only by high capable staffs and medical professionals while establishing an environment where customers, employees and stakeholders are valued and involved in continuously improving the quality of our services towards a healthier community.",
    },
    {
      'title': 'Our Vision',
      'icon': Icons.remove_red_eye,
      'content':
          "Global Care Medical Center of Canlubang is the optimal healthcare provider in the Community that delivers excellent medical service in the most professional and compassionate way at the most reasonable cost.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 1 : 2;
        return Container(
          color: Color(0xFFF8FAFC),
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 24 : 40,
            horizontal: constraints.maxWidth * 0.05,
          ),
          child: Column(
            children: [
              SectionHeader(
                title: 'Our Mission & Vision',
                subtitle:
                    'Our commitment to excellence in healthcare and community well-being.',
              ),
              SizedBox(height: isMobile ? 16 : 24),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 16 : 24,
                mainAxisSpacing: isMobile ? 16 : 24,
                childAspectRatio: isMobile ? 1.0 : 1.75, // Adjusted for mobile
                children: missionVision
                    .asMap()
                    .entries
                    .map(
                      (entry) => MissionVisionCard(
                        title: entry.value['title'],
                        icon: entry.value['icon'],
                        content: entry.value['content'],
                        isMobile: isMobile,
                        index: entry.key,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MissionVisionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;
  final bool isMobile;
  final int index;

  MissionVisionCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.isMobile,
    required this.index,
  });

  @override
  _MissionVisionCardState createState() => _MissionVisionCardState();
}

class _MissionVisionCardState extends State<MissionVisionCard>
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
      duration: Duration(milliseconds: 800 + widget.index * 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
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
      key: Key('mission_vision_${widget.title}'),
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
                  elevation: _isHovered ? 8 : 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    transform: Matrix4.identity()
                      ..scale(_isHovered ? 1.02 : 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isHovered ? 0.15 : 0.05,
                          ),
                          blurRadius: _isHovered ? 12 : 6,
                          offset: Offset(0, _isHovered ? 6 : 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: CircleAvatar(
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                            child: Icon(
                              widget.icon,
                              color: Colors.indigo[700],
                              size: widget.isMobile ? 40 : 52,
                            ),
                            radius: widget.isMobile ? 28 : 34,
                          ),
                        ),
                        // Content
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            widget.isMobile ? 12 : 16,
                            8,
                            widget.isMobile ? 12 : 16,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.title.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.isMobile ? 15 : 18,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.content,
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 13 : 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                                // Removed maxLines and overflow to allow full text
                              ),
                            ],
                          ),
                        ),
                      ],
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
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
