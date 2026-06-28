import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home.dart';
import 'screens/auth/login_page.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'settings_provider.dart';
import 'utils/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<_AppStartState> _resolveStartState() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return _AppStartState.login;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenOnboarding') ?? false;
    if (!seen) {
      await prefs.setBool('seenOnboarding', true);
      return _AppStartState.onboarding;
    }
    return _AppStartState.home;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<_AppStartState>(
        future: _resolveStartState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return switch (snapshot.data!) {
            _AppStartState.login => const LoginPage(),
            _AppStartState.onboarding => const OnboardingFlow(),
            _AppStartState.home =>
              const HomeScreen(isFirstLaunch: false),
          };
        },
      ),
    );
  }
}

enum _AppStartState { login, onboarding, home }
