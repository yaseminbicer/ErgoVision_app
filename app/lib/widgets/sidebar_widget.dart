import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../screens/home.dart';
import '../screens/settings.dart';
import '../screens/about.dart';
import '../screens/privacy.dart';
import '../screens/auth/login_page.dart';
import '../services/auth_service.dart';

class SidebarWidget extends StatelessWidget {
  final String currentPage;
  final VoidCallback onClose;

  const SidebarWidget({required this.currentPage, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          color: Colors.white.withOpacity(0.75),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// App Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "ErgoVision",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Home
                _buildSidebarItem(
                  context: context,
                  icon: Icons.home,
                  title: "Home",
                  isActive: currentPage == 'home',
                  onTap: () {
                    onClose();
                    if (currentPage == 'home') return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const HomeScreen(isFirstLaunch: false),
                      ),
                      (route) => false,
                    );
                  },
                ),

                /// Settings
                _buildSidebarItem(
                  context: context,
                  isActive: currentPage == 'settings',
                  icon: null,
                  svgIcon: "assets/images/settings_icon.svg",
                  title: "Settings",
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                /// Privacy & Disclaimer
                _buildSidebarItem(
                  context: context,
                  icon: Icons.privacy_tip,
                  title: "Privacy & Disclaimer",
                  isActive: currentPage == 'privacy',
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyScreen(),
                      ),
                    );
                  },
                ),

                /// About
                _buildSidebarItem(
                  context: context,
                  icon: Icons.info,
                  title: "About",
                  isActive: currentPage == 'about',
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                /// Log Out
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Color(0xFFB00020),
                      ),
                      title: Text(
                        "Log Out",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB00020),
                        ),
                      ),
                      onTap: () => _confirmLogout(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFB00020),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    IconData? icon,
    String? svgIcon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF5F4188).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: svgIcon != null
            ? SvgPicture.asset(
                svgIcon,
                width: 22,
                height: 22,
                colorFilter: isActive
                    ? const ColorFilter.mode(Color(0xFF5F4188), BlendMode.srcIn)
                    : null,
              )
            : Icon(
                icon,
                color: isActive ? const Color(0xFF5F4188) : Colors.black,
              ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF5F4188) : Colors.black,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
