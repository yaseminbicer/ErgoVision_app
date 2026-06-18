import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/supabase_config.dart';

// Uygulamanın her yerinden Supabase'e erişmek için global değişken
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ErgoVisionApp());
}

class ErgoVisionApp extends StatelessWidget {
  const ErgoVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ErgoVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6B),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ErgoVision')),
      ),
    );
  }
}
