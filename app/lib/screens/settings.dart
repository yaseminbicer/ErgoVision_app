import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../settings_provider.dart';
import '../widgets/app_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return AppLayout(
      currentPage: 'settings',
      builder: (toggleMenu) => Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/back_wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Top bar
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Color(0xFF5F4188),
                          size: 28,
                        ),
                        onPressed: toggleMenu,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Settings",
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

                  const SizedBox(height: 30),

                  /// Sound Settings
                  _buildSettingSection(
                    title: "Sound Settings",
                    subtitle: "Alert Session Sound",
                    value: settings.soundEnabled,
                    onChanged: settings.setSoundEnabled,
                  ),

                  const SizedBox(height: 35),

                  /// Camera Settings
                  _buildSettingSection(
                    title: "Camera Settings",
                    subtitle: "Camera Permission",
                    value: settings.cameraEnabled,
                    onChanged: settings.setCameraEnabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF212960),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF212960),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFE9FAFF),
          activeTrackColor: const Color(0xFF9EDCF4),
          inactiveThumbColor: const Color(0xFFE9FAFF),
          inactiveTrackColor: const Color(0xFF6FA8C4), // darker blue OFF
        ),
      ],
    );
  }
}
