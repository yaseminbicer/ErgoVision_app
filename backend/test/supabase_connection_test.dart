import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ergovision_app/utils/supabase_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  test('Supabase bağlantısı çalışıyor mu?', () async {
    final supabase = Supabase.instance.client;
    expect(supabase, isNotNull);
    print('✅ Supabase client oluşturuldu');
  });

  test('users tablosuna erişilebiliyor mu?', () async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase.from('users').select().limit(1);
      print('✅ users tablosu erişilebilir - ${data.length} kayıt döndü');
    } catch (e) {
      print('❌ Hata: $e');
      fail('users tablosuna erişilemedi: $e');
    }
  });

  test('sessions tablosuna erişilebiliyor mu?', () async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase.from('sessions').select().limit(1);
      print('✅ sessions tablosu erişilebilir - ${data.length} kayıt döndü');
    } catch (e) {
      print('❌ Hata: $e');
      fail('sessions tablosuna erişilemedi: $e');
    }
  });

  test('posture_records tablosuna erişilebiliyor mu?', () async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase.from('posture_records').select().limit(1);
      print('✅ posture_records tablosu erişilebilir - ${data.length} kayıt döndü');
    } catch (e) {
      print('❌ Hata: $e');
      fail('posture_records tablosuna erişilemedi: $e');
    }
  });

  test('exercise_recommendations tablosuna erişilebiliyor mu?', () async {
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase.from('exercise_recommendations').select().limit(1);
      print('✅ exercise_recommendations tablosu erişilebilir - ${data.length} kayıt döndü');
    } catch (e) {
      print('❌ Hata: $e');
      fail('exercise_recommendations tablosuna erişilemedi: $e');
    }
  });
}
