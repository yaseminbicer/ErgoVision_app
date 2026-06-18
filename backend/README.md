
## Sistem Mimarisi

ErgoVision, ayrı bir backend sunucusu barındırmaz. Flutter uygulaması; Supabase SDK aracılığıyla doğrudan bulut veritabanına, `http` paketi aracılığıyla da AI API'ye bağlanır.

```
┌────────────────────────────────────────────────┐
│              Flutter Uygulaması                │
│                                                │
│  ┌──────────┐  ┌─────────────────┐  ┌───────┐ │
│  │  Models  │  │    Services     │  │  UI   │ │
│  └──────────┘  └───────┬─────────┘  └───────┘ │
└──────────────────────── │ ──────────────────────┘
              ┌───────────┴────────────┐
              │ HTTPS                  │ HTTPS
              ▼                        ▼
┌─────────────────────┐    ┌──────────────────────┐
│      Supabase       │    │       AI API         │
│  ┌───────────────┐  │    │  (Pose Estimation)   │
│  │  Auth (JWT)   │  │    │                      │
│  ├───────────────┤  │    │  frame → analiz →    │
│  │  PostgreSQL   │  │    │  açı + skor değerleri│
│  └───────────────┘  │    └──────────────────────┘
└─────────────────────┘
```

---

## Proje Dosya Yapısı

```
ergovision_app/
├── lib/
│   ├── main.dart                              # Uygulama giriş noktası
│   ├── utils/
│   │   └── supabase_config.dart              # Supabase bağlantı bilgileri
│   ├── models/
│   │   ├── user_model.dart                   # Kullanıcı veri modeli
│   │   ├── session_model.dart                # Oturum veri modeli
│   │   ├── posture_record_model.dart         # Duruş kaydı ve özet modeli
│   │   ├── exercise_model.dart               # Egzersiz önerisi modeli
│   │   └── ai_analysis_result.dart           # AI API'den dönen analiz sonucu
│   └── services/
│       ├── auth_service.dart                 # Kimlik doğrulama işlemleri
│       ├── session_service.dart              # Oturum yönetimi
│       ├── posture_service.dart              # Duruş kaydı ve analitik
│       ├── exercise_service.dart             # Egzersiz önerileri
│       ├── ai_service.dart                   # AI API ile iletişim
│       └── posture_analysis_service.dart     # AI + Supabase akışını yönetir
└── pubspec.yaml                              # Bağımlılıklar
```

---

## Sınıflar ve Detaylı Açıklamaları

### `main.dart`

Uygulamanın başladığı dosyadır. Flutter çalışmaya başlamadan önce `Supabase.initialize()` çağrılır; bu sayede uygulama boyunca tüm servisler Supabase'e bağlı kalır. `SupabaseConfig` sınıfından URL ve anonKey okunur. `ErgoVisionApp` widget'ı Material Design temasını ve yeşil renk şemasını tanımlar.

---

### `utils/supabase_config.dart`

```dart
class SupabaseConfig {
  static const String url = '...';
  static const String anonKey = '...';
}
```

Supabase proje URL'si ve anonim anahtarını tek bir yerde tutar. Bu dosya `.gitignore`'a eklenmiştir; GitHub'a gönderilmez. Tüm servisler bu bilgileri buradan okur, anahtar değiştiğinde yalnızca bu dosyanın güncellenmesi yeterlidir.

---

### `models/user_model.dart`

#### `UserModel`

Supabase `users` tablosundaki bir satırı Dart nesnesine dönüştürür.

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `String` | UUID — Supabase Auth'un atadığı benzersiz kimlik |
| `email` | `String` | Kullanıcının email adresi |
| `fullName` | `String` | Ad soyad |
| `createdAt` | `DateTime` | Hesap oluşturulma tarihi |

**`UserModel.fromMap(map)`** — Supabase'den gelen `Map<String, dynamic>` tipindeki ham veriyi `UserModel` nesnesine çevirir. `full_name` alanı veritabanında boş olabileceği için `?? ''` ile varsayılan değer atanır.

---

### `models/session_model.dart`

#### `SessionModel`

Kullanıcının bir çalışma oturumunu temsil eder. Kamera açıldığında oturum başlar, kamera kapandığında biter.

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `String` | UUID — Oturum kimliği |
| `userId` | `String` | Bu oturumun sahibi |
| `startedAt` | `DateTime` | Oturum başlangıcı |
| `endedAt` | `DateTime?` | Oturum sonu — `null` ise oturum hâlâ aktif |
| `durationSeconds` | `int?` | Toplam süre saniye cinsinden |

**`isActive`** (getter) — `endedAt == null` ise `true` döner. Aktif oturum tespitinde kullanılır.

**`formattedDuration`** (getter) — `durationSeconds` değerini `"12dk 34sn"` formatına çevirir. Raporlar ekranında gösterim için kullanılır. Süre henüz kaydedilmemişse `"-"` döner.

**`SessionModel.fromMap(map)`** — Supabase verisini nesneye dönüştürür. `ended_at` alanı `null` olabileceği için null-safe parse işlemi yapılır.

---

### `models/posture_record_model.dart`

#### `PostureRecordModel`

AI API'den dönen analiz sonucunun Supabase'e kaydedilmiş halini temsil eder. Her frame analizi sonrası bu modelden yeni bir kayıt oluşturulur.

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `String` | UUID — Kayıt kimliği |
| `sessionId` | `String` | Hangi oturuma ait olduğu |
| `userId` | `String` | Hangi kullanıcıya ait olduğu |
| `postureScore` | `double` | Genel duruş skoru (0–100 arası) |
| `isGoodPosture` | `bool` | Duruşun iyi olup olmadığı |
| `torsoAngle` | `double` | Gövde açısı (derece) |
| `neckAngle` | `double` | Boyun açısı (derece) |
| `shoulderAngle` | `double` | Omuz açısı (derece) |
| `recordedAt` | `DateTime` | Ölçümün alındığı zaman |

**`PostureRecordModel.fromMap(map)`** — Supabase'den gelen sayısal değerler `num` tipinde gelebileceği için `.toDouble()` ile açıkça `double`'a çevrilir.

#### `PostureSummary`

Birden fazla `PostureRecordModel` verisinden hesaplanan istatistik özetidir. `PostureService.getSummary()` tarafından üretilir, raporlar ekranında görüntülenir.

| Alan | Tip | Açıklama |
|---|---|---|
| `totalRecords` | `int` | Toplam ölçüm sayısı |
| `goodPostureCount` | `int` | İyi duruş sayısı |
| `badPostureCount` | `int` | Kötü duruş sayısı |
| `goodPosturePercentage` | `double` | İyi duruş yüzdesi (0–100) |
| `averageScore` | `double` | Ortalama duruş skoru |

---

### `models/exercise_model.dart`

#### `ExerciseModel`

Kullanıcıya önerilen bir egzersizi temsil eder. `ExerciseService.autoRecommend()` tarafından oluşturulur ve `exercise_recommendations` tablosuna kaydedilir.

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `String` | UUID — Öneri kimliği |
| `userId` | `String` | Kime önerildiği |
| `exerciseName` | `String` | Egzersizin adı |
| `description` | `String` | Nasıl yapılacağının açıklaması |
| `recommendedAt` | `DateTime` | Önerinin oluşturulma zamanı |

**`ExerciseModel.fromMap(map)`** — `description` alanı veritabanında boş olabileceği için `?? ''` ile boş string varsayılan değer atanır.

---

### `models/ai_analysis_result.dart`

#### `AIAnalysisResult`

AI API'nin bir kamera frame'ini analiz etmesi sonucunda döndürdüğü veriyi temsil eder. Supabase'e doğrudan kaydedilmez; `PostureAnalysisService` bu modeli alıp `PostureRecordModel`'e dönüştürerek kaydeder.

| Alan | Tip | Açıklama |
|---|---|---|
| `postureScore` | `double` | AI'ın hesapladığı genel duruş skoru (0–100) |
| `isGoodPosture` | `bool` | AI'ın iyi/kötü duruş kararı |
| `torsoAngle` | `double` | AI'ın tespit ettiği gövde açısı |
| `neckAngle` | `double` | AI'ın tespit ettiği boyun açısı |
| `shoulderAngle` | `double` | AI'ın tespit ettiği omuz açısı |

**`AIAnalysisResult.fromJson(json)`** — AI API'nin döndürdüğü JSON'u Dart nesnesine çevirir. Beklenen JSON formatı:
```json
{
  "posture_score": 72.5,
  "is_good_posture": true,
  "torso_angle": 165.0,
  "neck_angle": 158.0,
  "shoulder_angle": 162.0
}
```

---

### `services/auth_service.dart`

#### `AuthService`

Kullanıcı kimlik doğrulama işlemlerini yönetir. Supabase Auth servisi ile doğrudan konuşur. JWT token yönetimi (saklama, yenileme, geçersiz kılma) tamamen Supabase SDK tarafından otomatik yapılır.

**`register(email, password, fullName)`**
1. `supabase.auth.signUp()` ile Supabase Auth sistemine yeni kullanıcı kaydeder
2. Auth kaydı başarılıysa aynı kullanıcıyı `users` tablosuna da ekler (profil verisi için)
3. `AuthResponse` nesnesi döner

Kayıt iki adımda yapılmasının sebebi: Supabase Auth yalnızca email ve şifreyi yönetir. Ad-soyad gibi ek profil bilgilerini tutmak için ayrı bir `users` tablosu gereklidir.

**`login(email, password)`**
1. `supabase.auth.signInWithPassword()` ile kimlik doğrulaması yapar
2. Başarılıysa içinde JWT access token bulunan `AuthResponse` döner
3. Token SDK tarafından cihazda güvenli şekilde saklanır

**`logout()`**
1. `supabase.auth.signOut()` çağırır
2. Saklanan token silinir ve geçersiz kılınır

**`currentUser`** (getter) — Aktif oturumdaki `User` nesnesini döner, giriş yoksa `null`

**`currentUserId`** (getter) — Aktif kullanıcının UUID'sini döner, giriş yoksa `null`. Servislerde `user_id` parametresi olarak sık kullanılır.

**`authStateChanges`** (getter) — Giriş/çıkış olaylarını yayınlayan `Stream<AuthState>` döner. Frontend bu stream'i dinleyerek kullanıcıyı otomatik olarak doğru ekrana yönlendirir.

---

### `services/session_service.dart`

#### `SessionService`

Kullanıcının kamera açık olduğu süreleri (çalışma oturumlarını) yönetir. Her oturum `sessions` tablosunda bir satır olarak saklanır.

**`startSession(userId)`**
1. `sessions` tablosuna yeni bir kayıt ekler
2. `started_at` Supabase tarafından otomatik `NOW()` olarak atanır
3. Oluşturulan `SessionModel` döner
4. Kamera ekranı açıldığında çağrılır

**`endSession(sessionId, durationSeconds)`**
1. Verilen `sessionId`'ye sahip oturumu bulur
2. `ended_at` alanını şimdiki zamanla günceller
3. `duration_seconds` alanına toplam süreyi yazar
4. Güncellenmiş `SessionModel` döner
5. Kamera ekranı kapatıldığında çağrılır

**`getUserSessions(userId)`**
1. Kullanıcının tüm oturumlarını getirir
2. `started_at` alanına göre en yeniden eskiye sıralar
3. `List<SessionModel>` döner
4. Oturum geçmişi ekranında kullanılır

---

### `services/posture_service.dart`

#### `PostureService`

AI analizinden gelen duruş ölçümlerini veritabanına yazar ve istatistik hesaplar.

**`addRecord({sessionId, userId, postureScore, isGoodPosture, torsoAngle, neckAngle, shoulderAngle})`**
1. Tüm parametreleri alarak `posture_records` tablosuna tek bir ölçüm kaydeder
2. `recorded_at` Supabase tarafından otomatik `NOW()` olarak atanır
3. Kaydedilen `PostureRecordModel` döner
4. Doğrudan değil, `PostureAnalysisService` üzerinden çağrılır

**`getSessionRecords(sessionId)`**
1. Bir oturuma ait tüm duruş kayıtlarını getirir
2. `recorded_at` alanına göre eskiden yeniye (kronolojik) sıralar
3. `List<PostureRecordModel>` döner
4. Oturum detay ekranında grafik çizmek için kullanılır

**`getSummary(userId)`**
1. Kullanıcının son 100 kaydını `posture_score` ve `is_good_posture` alanlarıyla çeker
2. Aşağıdaki istatistikleri hesaplar:
   - **`totalRecords`**: Toplam kayıt sayısı
   - **`goodPostureCount`**: `is_good_posture == true` olan kayıt sayısı
   - **`badPostureCount`**: `totalRecords - goodPostureCount`
   - **`goodPosturePercentage`**: `(goodCount / total) * 100`
   - **`averageScore`**: Tüm `posture_score` değerlerinin aritmetik ortalaması
3. `PostureSummary` nesnesi döner
4. Ana dashboard ve raporlar ekranında kullanılır

---

### `services/exercise_service.dart`

#### `ExerciseService`

Duruş açı değerlerine göre egzersiz önerileri üretir, kaydeder ve yönetir.

**`autoRecommend({userId, postureScore, torsoAngle, neckAngle, shoulderAngle})`**

AI'dan dönen açı değerlerine göre aşağıdaki karar mantığını uygular:

| Koşul | Egzersiz | Neden? |
|---|---|---|
| `torsoAngle < 160°` | Cat-Cow Stretch | Gövde öne eğilmiş → sırt kasları gergin |
| `neckAngle < 150°` | Boyun Germe | Boyun öne düşmüş → boyun gerginliği |
| `shoulderAngle < 160°` | Omuz Açma | Omuzlar içe çökmüş → omuz kasları gergin |
| `postureScore < 50` | Kısa Yürüyüş Molası | Genel skor düşük → uzun süre kötü oturma |

- Koşulları sağlayan egzersizler bir liste olarak hazırlanır
- Tüm liste `exercise_recommendations` tablosuna tek seferinde toplu (`insert`) kaydedilir
- Hiçbir koşul sağlanmazsa boş liste döner (duruş iyidir)
- `List<ExerciseModel>` döner

**`getUserExercises(userId)`**
1. Kullanıcıya önerilmiş tüm egzersizleri getirir
2. En yeniden eskiye sıralar
3. `List<ExerciseModel>` döner

**`deleteExercise(id)`**
1. Verilen `id`'ye sahip egzersiz önerisini siler
2. Kullanıcı tamamladığı egzersizi listeden kaldırmak istediğinde çağrılır

---

### `services/ai_service.dart`

#### `AIService`

Kameradan alınan frame'i AI API'ye HTTP üzerinden gönderir ve analiz sonucunu döner. Yalnızca AI ile iletişimden sorumludur; veritabanı işlemi yapmaz.

**`analyzeFrame(imageBytes)`**
1. `Uint8List` tipinde kamera frame'ini alır
2. `Content-Type: application/octet-stream` header'ıyla AI API'ye HTTP POST isteği atar
3. API `200 OK` dönerse yanıtı `AIAnalysisResult.fromJson()` ile parse eder
4. `AIAnalysisResult` döner
5. API erişilemezse veya hata dönerse `Exception` fırlatır

AI modeli tamamlandığında `_aiApiUrl` sabitine URL yazılması yeterlidir; başka değişiklik gerekmez.

---

### `services/posture_analysis_service.dart`

#### `PostureAnalysisService`

`AIService`, `PostureService` ve `ExerciseService`'i tek bir akışta birbirine bağlayan orkestrasyon servisidir. UI yalnızca bu servis ile konuşur; diğer servisleri doğrudan çağırmasına gerek yoktur.

**`analyzeAndSave({imageBytes, sessionId, userId})`**

Kameradan gelen frame için uçtan uca analiz ve kayıt işlemini yönetir:

```
imageBytes
    │
    ▼
AIService.analyzeFrame()         → AI API'ye gönderir
    │ AIAnalysisResult
    ▼
PostureService.addRecord()       → Supabase'e kaydeder
    │ PostureRecordModel
    ▼
UI'ya döner (ekranda gösterilir)
```

**`recommendExercises({result, userId})`**

Kötü duruş tespit edildiğinde çağrılır. `AIAnalysisResult` içindeki açı değerlerini `ExerciseService.autoRecommend()`'e iletir ve önerileri Supabase'e kaydeder.

**UI Kullanım Örneği:**
```dart
// Kameradan frame geldiğinde
final record = await PostureAnalysisService.analyzeAndSave(
  imageBytes: frameBytes,
  sessionId: activeSessionId,
  userId: AuthService.currentUserId!,
);

// Kötü duruşsa egzersiz öner
if (!record.isGoodPosture) {
  await PostureAnalysisService.recommendExercises(
    result: aiResult,
    userId: AuthService.currentUserId!,
  );
}
```

---

## Veritabanı Şeması

```
users
├── id (UUID, PK) ──── auth.users.id
├── email (TEXT)
├── full_name (TEXT)
└── created_at (TIMESTAMPTZ)

sessions
├── id (UUID, PK)
├── user_id (UUID, FK) ──── users.id
├── started_at (TIMESTAMPTZ)
├── ended_at (TIMESTAMPTZ, nullable)
└── duration_seconds (INTEGER, nullable)

posture_records
├── id (UUID, PK)
├── session_id (UUID, FK) ──── sessions.id
├── user_id (UUID, FK) ──── users.id
├── posture_score (NUMERIC)
├── is_good_posture (BOOLEAN)
├── torso_angle (NUMERIC)
├── neck_angle (NUMERIC)
├── shoulder_angle (NUMERIC)
└── recorded_at (TIMESTAMPTZ)

exercise_recommendations
├── id (UUID, PK)
├── user_id (UUID, FK) ──── users.id
├── exercise_name (TEXT)
├── description (TEXT)
└── recommended_at (TIMESTAMPTZ)
```

---

## Tipik Kullanım Akışı

```
1. Kullanıcı kayıt olur
   └── AuthService.register(email, password, fullName)

2. Kullanıcı giriş yapar
   └── AuthService.login(email, password)

3. Kamera açılır, oturum başlar
   └── SessionService.startSession(userId)

4. Her kamera frame'i için analiz yapılır ve kaydedilir
   └── PostureAnalysisService.analyzeAndSave(imageBytes, sessionId, userId)
        ├── AIService.analyzeFrame()         → AI API'ye gönderilir
        └── PostureService.addRecord()       → Supabase'e kaydedilir

5. Kötü duruş tespit edilirse egzersiz önerilir
   └── PostureAnalysisService.recommendExercises(result, userId)
        └── ExerciseService.autoRecommend() → Supabase'e kaydedilir

6. Kamera kapanır, oturum biter
   └── SessionService.endSession(sessionId, durationSeconds)

7. Raporlar ekranında özet görüntülenir
   └── PostureService.getSummary(userId)

8. Egzersizler ekranında öneriler listelenir
   └── ExerciseService.getUserExercises(userId)
```

---


## Güvenlik

- Tüm tablolarda **Row Level Security (RLS)** aktiftir
- Her kullanıcı yalnızca kendi verilerine erişebilir
- Ham video/frame verisi Supabase'e hiçbir zaman gönderilmez; yalnızca AI'dan dönen açı ve skor değerleri kaydedilir
- `supabase_config.dart` dosyası `.gitignore`'a eklenmiştir
- Kimlik doğrulama JWT token tabanlıdır, Supabase tarafından otomatik yönetilir
