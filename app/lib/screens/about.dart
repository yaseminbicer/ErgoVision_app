import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentPage: 'about',
      builder: (toggleMenu) => Stack(
        children: [
          /// Wallpaper background
          Positioned.fill(
            child: Image.asset(
              'assets/images/back_wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top bar with menu and title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Color(0xFF5F4188),
                          size: 24,
                        ),
                        onPressed: toggleMenu,
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            "About",
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF212960),
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// About info card
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9FAFF),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      '''ErgoVision is an application aiming at helping you build better posture habits through real-time feedback.

This app uses AI to monitor posture and provide insights and exercises to improve sitting behavior over time.

Features:
• Real-time posture detection
• Session tracking
• Exercise recommendations
• Privacy-focused design

Developed as a Capstone Project by Emre Ozkan, Yasemin Bicer, and Maiyas Ismail.

Version 1.0''',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF212960),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
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
}
