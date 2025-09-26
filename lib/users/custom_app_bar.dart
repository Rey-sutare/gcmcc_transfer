import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isMobile;

  const CustomAppBar({required this.isMobile, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Row(
        children: [
          Text(
            'HealthCare',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[700],
            ),
          ),
          const Spacer(),
          NavItem(
            text: 'Home',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Home clicked!')));
            },
            isMobile: isMobile,
          ),
          NavItem(
            text: 'About',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('About clicked!')));
            },
            isMobile: isMobile,
          ),
          NavItem(
            text: 'Services',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Services clicked!')),
              );
            },
            isMobile: isMobile,
          ),
          NavItem(
            text: 'Contact',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Contact clicked!')));
            },
            isMobile: isMobile,
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class NavItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isMobile;

  const NavItem({
    required this.text,
    required this.onTap,
    required this.isMobile,
    super.key,
  });

  @override
  _NavItemState createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8.0 : 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: TextButton(
            onPressed: widget.onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 8 : 12,
                vertical: 8,
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: _isHovered ? Colors.indigo[900] : Colors.indigo[700],
                decoration: _isHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: Colors.indigo[900],
                decorationThickness: 2,
              ),
              child: Text(widget.text),
            ),
          ),
        ),
      ),
    );
  }
}
