import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          Image.asset(
            'assets/images/loading.png',
            fit: BoxFit.cover,
          ),

          // 🌫 Optional dark overlay (remove if not needed)
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Loading animation
          Align(
            alignment: Alignment.center,
            child: Lottie.asset(
              'assets/images/loading_animation.json',
              width: 260,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}