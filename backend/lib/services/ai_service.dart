import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis_result.dart';

class AIService {
  /// AI modelinin deploy edildiği endpoint.
  /// Model hazır olduğunda bu URL güncellenir.
  static const String _aiApiUrl = 'AI_API_URL_BURAYA';

  /// Kameradan alınan bir frame'i (görüntü byte'ları) AI API'ye gönderir
  /// ve duruş analizi sonucunu döner.
  ///
  /// [imageBytes] — Kameradan alınan frame'in ham byte verisi (JPEG/PNG)
  ///
  /// Başarılı olursa [AIAnalysisResult] döner.
  /// API erişilemezse veya hata dönerse exception fırlatır.
  static Future<AIAnalysisResult> analyzeFrame(Uint8List imageBytes) async {
    final uri = Uri.parse(_aiApiUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/octet-stream'},
      body: imageBytes,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'AI API hatası: ${response.statusCode} — ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AIAnalysisResult.fromJson(json);
  }
}
