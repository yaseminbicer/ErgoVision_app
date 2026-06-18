import 'dart:ui';

import 'package:flutter/material.dart';

class CameraPermission extends StatelessWidget {
  static const Color buttonColor = Color(0xFFBDA7DB);

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const CameraPermission({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/camera_permission.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          bottom: 130,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _button("Enable Access", onEnable),
              _button("Maybe Later", onSkip),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: buttonColor.withOpacity(0.38),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Text(text, style: const TextStyle(fontFamily: 'Montserrat')),
          ),
        ),
      ),
    );
  }
}
