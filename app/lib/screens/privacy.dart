import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_layout.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentPage: 'privacy',
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
                            "Privacy Policy",
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF212960),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                /// Privacy policy card
                Expanded(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.84,
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
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
                      child: SingleChildScrollView(
                        child: Text(
                          '''• ErgoVision uses your device’s camera to analyze posture in real time. All processing is performed locally on your device.

• ErgoVision does not store, record, or transmit any video or image data.

• ErgoVision may store session summaries (such as duration of correct and incorrect posture) locally on your device to provide insights and progress tracking.

• We do not share any data with third parties.

• You may stop using the app at any time and revoke camera permissions through your device settings.


This app is intended for educational purposes only and is not a medical device. For medical concerns, please consult a qualified healthcare professional.''',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF212960),
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
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
}
