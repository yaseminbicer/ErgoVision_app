import 'dart:ui';

import 'package:flutter/material.dart';

class Exercise extends StatelessWidget {
  static const Color buttonColor = Color(0xFFBDA7DB);

  final VoidCallback onStart;

  const Exercise({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/exercise.png', fit: BoxFit.cover),
        ),

        Positioned(
          bottom: 130,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onStart,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: buttonColor.withOpacity(0.38),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
