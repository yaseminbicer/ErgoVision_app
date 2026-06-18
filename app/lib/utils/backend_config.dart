class BackendConfig {
  /// iPhone gerçek cihaz testi: Mac'in yerel ağ IP'si.
  /// AI backend Mac'te çalışıyorsa bu IP kullanılır.
  /// Sunucuya deploy edildiyse domain/IP ile değiştir.
  static const String aiOfferUrl = 'http://172.20.10.3:8000/offer';
}
