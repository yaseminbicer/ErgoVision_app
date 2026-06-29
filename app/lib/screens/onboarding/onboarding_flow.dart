import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome.dart';
import 'camera_permission.dart';
import 'exercise.dart';
import '../auth/sign_up_page.dart';
import 'package:provider/provider.dart';
import '../../settings_provider.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int currentPage = 0;
  bool _isRequestingPermission = false;

  void nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> requestCamera() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    final granted = status.isGranted;
    context.read<SettingsProvider>().setCameraEnabledDirect(granted);

    _isRequestingPermission = false;
    nextPage();
  }

  Future<void> skipCamera() async {
    await context.read<SettingsProvider>().setCameraEnabled(false);
    nextPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> goToSignUp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  Widget buildDot(int index) {
    bool active = index == currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF8B61C2) : Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => currentPage = i),
            children: [
              const Welcome(),

              CameraPermission(
                onEnable: requestCamera,
                onSkip: skipCamera, // goes to screen 3
              ),

              Exercise(onStart: goToSignUp),
            ],
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, buildDot),
            ),
          ),
        ],
      ),
    );
  }
}
