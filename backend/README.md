# ErgoVision — Teknik Dokümantasyon

## Sistem Mimarisi

ErgoVision üç katmanlı bir yapıya sahiptir. Flutter uygulaması; veri kalıcılığı için Supabase'e, gerçek zamanlı duruş analizi için ise WebRTC aracılığıyla bir Python AI servisine bağlanır.

```
┌──────────────────────────────────────────────────────────────┐
│                   FLUTTER MOBIL UYGULAMA                     │
│          Ekranlar / Servisler / Modeller (Dart)              │
└────────────────┬─────────────────────────┬───────────────────┘
                 │ WebRTC                  │ HTTPS (Supabase SDK)
                 │ (video + data channel)  │
                 ▼                         ▼
┌───────────────────────┐     ┌────────────────────────────────┐
│      AI SERVİSİ       │     │           SUPABASE             │
│  Python / FastAPI     │     │   PostgreSQL + Auth + RLS      │
│  MediaPipe / aiortc   │     │        (Bulut)                 │
│  port 8000            │     │                                │
└───────────────────────┘     └────────────────────────────────┘
```

---

## AI Servisi

**Teknoloji:** Python 3.11, FastAPI, aiortc, MediaPipe Pose Landmarker, OpenCV, Docker

### Endpoint'ler

| Method | Path | Açıklama |
|---|---|---|
| `GET` | `/` | Sağlık kontrolü |
| `POST` | `/offer` | WebRTC SDP offer alır, SDP answer döner |

### Duruş Analizi (`analyzer.py`)

Her frame'de **MediaPipe Pose Landmarker** ile 33 vücut noktası tespit edilir. Analiz 3 temel noktaya dayanır:

- **Landmark 0** — Burun
- **Landmark 11** — Sol omuz
- **Landmark 12** — Sağ omuz

**Eğik Omuz tespiti:**
```
tilt_ratio = |sol_omuz_y - sağ_omuz_y| / omuz_genişliği
tilt_ratio > 0.08  →  uyarı: "Uneven Shoulders"
```

**Öne Eğilme tespiti:**
```
posture_ratio = (omuz_orta_y - burun_y) / omuz_genişliği
posture_ratio < 0.6  →  uyarı: "Slouching Detected"
```

**Puan hesaplama:**
```
skor = max(0, 100 - (uyarı_sayısı × 20))
```

### Temporal Smoothing (`webrtc.py`)

Ham frame analizleri gürültülü olabileceğinden **5 frame'lik kayan pencere** uygulanır. Bir uyarının son 5 frame'in en az 3'ünde görülmesi gerekir.

### Data Channel Çıktısı

Sonuçlar `posture-warnings` adlı WebRTC data channel üzerinden Flutter uygulamasına iletilir:

```json
{
  "person_detected": true,
  "warnings": ["Slouching Detected"],
  "posture_score": 80,
  "is_good_posture": false,
  "shoulder_tilt_ratio": 0.05,
  "posture_ratio": 0.55
}
```

Ham video frame'leri hiçbir zaman saklanmaz; yalnızca analiz sonuçları kaydedilir.

### AI Servisini Başlatma

```bash
cd ai/
bash start_backend.sh        # uvicorn'u arka planda port 8000'de başlatır
```

Docker ile:
```bash
docker build -t posture-api .
docker run -d -p 8000:8000 --name posture-server posture-api
```

---

## Flutter Uygulaması — Dosya Yapısı

```
app/lib/
├── main.dart                              # Giriş noktası, Supabase başlatma, auth yönlendirme
├── utils/
│   ├── supabase_config.dart              # Supabase URL ve anon key
│   └── backend_config.dart              # AI servis URL'si
├── models/
│   ├── user_model.dart
│   ├── session_model.dart
│   ├── posture_record_model.dart
│   ├── posture_session_summary.dart      # Ekranlar arası geçen oturum özeti
│   ├── exercise_model.dart               # exercise_recommendations tablosu satırı
│   ├── exercise_library_model.dart       # exercises kataloğu satırı
│   └── ai_analysis_result.dart
├── services/
│   ├── auth_service.dart
│   ├── session_service.dart
│   ├── posture_service.dart
│   ├── exercise_service.dart
│   ├── posture_analysis_service.dart     # endSession + autoRecommend orkestratörü
│   └── posture_webrtc_service.dart       # AI servisine WebRTC bağlantısı
├── screens/
│   ├── home.dart
│   ├── posture_tracking.dart
│   ├── session_summary_screen.dart
│   ├── settings.dart
│   ├── about.dart
│   ├── privacy.dart
│   ├── loading.dart
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── sign_up_page.dart
│   └── onboarding/
│       └── onboarding_flow.dart
└── widgets/
    ├── app_layout.dart                   # Sidebar animasyon sarmalayıcı
    └── sidebar_widget.dart               # Yan menü
```

---

## Ekran Akışı

```
Uygulama Açılışı
  ├── Oturum yok   ──► LoginPage / SignUpPage
  └── Oturum var
        ├── İlk açılış  ──► OnboardingFlow ──► SignUpPage
        └── Normal      ──► HomeScreen
                                  │
                           [Begin Tracking]
                                  │
                          TrackingScreen
                          (WebRTC canlı yayın)
                                  │
                              [Stop]
                                  │
                        SessionSummaryScreen
                        (istatistikler + egzersizler)
                                  │
                              [Done]
                                  │
                          HomeScreen (güncellenir)
```

---

## Servisler

### `AuthService`

Supabase Auth'u sarar. JWT token saklama ve yenileme SDK tarafından otomatik yönetilir.

| Metot | Açıklama |
|---|---|
| `register(email, password, fullName)` | Supabase Auth kullanıcısı oluşturur + `users` tablosuna satır ekler |
| `login(email, password)` | Şifre ile giriş yapar, `AuthResponse` döner |
| `logout()` | Çıkış yapar, token silinir |
| `currentUserId` | Aktif kullanıcının UUID'sini döner |
| `authStateChanges` | Giriş/çıkış olaylarının Stream'i |

---

### `SessionService`

`sessions` tablosundaki satırları yönetir.

| Metot | Açıklama |
|---|---|
| `startSession(userId)` | Yeni oturum ekler, `SessionModel` döner |
| `endSession(sessionId, durationSeconds)` | `ended_at` ve `duration_seconds` günceller |
| `getUserSessions(userId)` | Tüm oturumları en yeniden eskiye sıralı döner |

---

### `PostureService`

Duruş ölçümlerini `posture_records` tablosuna yazar ve istatistik hesaplar.

| Metot | Açıklama |
|---|---|
| `addRecord({...})` | Tek duruş anlık görüntüsü ekler |
| `getSessionRecords(sessionId)` | Oturuma ait tüm kayıtları kronolojik sırayla döner |
| `getSummary(userId)` | Son 100 kayıttan `PostureSummary` hesaplar (ort. skor, iyi/kötü %) |

---

### `ExerciseService`

Egzersiz kataloğunu ve oturuma özel önerileri yönetir.

| Metot | Açıklama |
|---|---|
| `getAllExercises()` | `exercises` tablosundan tüm kataloğu döner |
| `getExercisesByWarnings(warnings)` | `warning_keys` eşleşmesine göre filtreler. `warning_keys` boş olanlar her zaman dahil edilir |
| `autoRecommend({userId, sessionId, activeWarnings})` | Uyarıları egzersizlerle eşleştirir, `exercise_id` FK ile `exercise_recommendations`'a kaydeder |
| `getExercisesForSession(sessionId)` | Tek JOIN sorgusu: `exercise_recommendations` ⟶ `exercises` (`exercise_id` üzerinden) |
| `getUserRecommendations(userId)` | Kullanıcının tüm önerilerini döner |

**Egzersiz eşleştirme mantığı:**
```
exercises.warning_keys = ["Slouching Detected"]  →  öne eğilme tespit edilince gösterilir
exercises.warning_keys = ["Uneven Shoulders"]    →  eğik omuz tespit edilince gösterilir
exercises.warning_keys = []                      →  her zaman gösterilir (genel egzersiz)
```

---

### `PostureAnalysisService`

Oturum sınırlarında çağrılan orkestrasyon katmanı.

| Metot | Açıklama |
|---|---|
| `startSession()` | Mevcut kullanıcı için `SessionService.startSession()` çağırır |
| `endSession({sessionId, durationSeconds, activeWarnings})` | DB'de oturumu kapatır, ardından `ExerciseService.autoRecommend()` çağırır |

---

### `PostureWebRTCService`

AI servisine WebRTC peer bağlantısını yönetir.

**Bağlantı akışı:**
1. Kamera izni iste
2. Google STUN sunucusuyla `RTCPeerConnection` oluştur
3. Yerel video track'i ekle
4. `posture-warnings` data channel'ı aç
5. SDP offer oluştur (`b=AS:2000` bitrate ipucu eklenmiş)
6. Offer'ı `BackendConfig.aiOfferUrl`'e POST et
7. SDP answer'ı remote description olarak ayarla
8. `PostureWarningUpdate` nesnelerini `StreamController` üzerinden yayınla

**`PostureWarningUpdate` alanları:**

| Alan | Tip | Açıklama |
|---|---|---|
| `warnings` | `List<String>` | Aktif uyarı etiketleri |
| `postureScore` | `int` | 0–100 |
| `isGoodPosture` | `bool` | Uyarı listesi boşsa true |
| `personDetected` | `bool` | Kişi frame dışındaysa false |
| `shoulderTiltRatio` | `double` | AI'dan gelen ham tilt oranı |
| `postureRatio` | `double` | AI'dan gelen ham boyun-yükseklik oranı |

---

## Modeller

### `PostureSessionSummary`

`TrackingScreen`'den `SessionSummaryScreen` üzerinden `HomeScreen`'e taşınan bellek içi sonuç nesnesi.

| Alan | Tip |
|---|---|
| `sessionId` | `String?` |
| `ergonomicSeconds` | `int` |
| `nonErgonomicSeconds` | `int` |
| `durationSeconds` | `int` |
| `finalWarnings` | `List<String>` |

Hesaplanan getter'lar: `ergonomicPercentage`, `nonErgonomicPercentage`, `totalSeconds`

---

### `ExerciseLibraryModel`

`exercises` kataloğu tablosundan bir satır.

| Alan | Tip |
|---|---|
| `id` | `String` |
| `title` | `String` |
| `imagePath` | `String` |
| `youtubeUrl` | `String` |
| `warningKeys` | `List<String>` |

`matchesWarnings(activeWarnings)` — herhangi bir uyarı anahtarı eşleşirse veya `warningKeys` boşsa `true` döner.

---

### `ExerciseModel`

`exercise_recommendations` tablosundan bir satır.

| Alan | Tip |
|---|---|
| `id` | `String` |
| `userId` | `String` |
| `sessionId` | `String?` |
| `exerciseId` | `String?` |
| `exerciseName` | `String` |
| `description` | `String` |
| `recommendedAt` | `DateTime` |

---

## Veritabanı Şeması

```
users
├── id           UUID  PK  ──── auth.users.id
├── email        TEXT
├── full_name    TEXT
└── created_at   TIMESTAMPTZ

sessions
├── id               UUID  PK
├── user_id          UUID  FK ──── users.id
├── started_at       TIMESTAMPTZ
├── ended_at         TIMESTAMPTZ  nullable
└── duration_seconds INTEGER      nullable

posture_records
├── id              UUID  PK
├── session_id      UUID  FK ──── sessions.id
├── user_id         UUID  FK ──── users.id
├── posture_score   NUMERIC
├── is_good_posture BOOLEAN
├── torso_angle     NUMERIC
├── neck_angle      NUMERIC
├── shoulder_angle  NUMERIC
└── recorded_at     TIMESTAMPTZ

exercises  (salt okunur katalog)
├── id           UUID  PK
├── title        TEXT
├── image_path   TEXT
├── youtube_url  TEXT
└── warning_keys TEXT[]

exercise_recommendations
├── id              UUID  PK
├── user_id         UUID  FK ──── users.id
├── session_id      UUID  FK ──── sessions.id
├── exercise_id     UUID  FK ──── exercises.id
├── exercise_name   TEXT
├── description     TEXT
└── recommended_at  TIMESTAMPTZ
```

---

## Uçtan Uca Oturum Akışı

```
1. [Begin Tracking]
   PostureAnalysisService.startSession()
   → sessions tablosuna INSERT

2. WebRTC el sıkışması
   POST /offer → SDP answer
   → video akışı başlar

3. Her frame (30 fps, WebRTC data channel):
   AI landmark tespiti → uyarı hesaplama → 5-frame smoothing → JSON

4. Her 10 saniyede bir (kişi frame'deyse):
   PostureService.addRecord()
   → posture_records tablosuna INSERT

5. Oturum boyunca uyarı birikimi:
   _sessionWarnings (Set<String>) tüm unique uyarıları toplar

6. [Stop]
   → SessionSummaryScreen açılır (sessionId + _sessionWarnings geçer)

7. SessionSummaryScreen.initState():
   PostureAnalysisService.endSession()
   → sessions tablosu UPDATE (ended_at, duration_seconds)
   → ExerciseService.autoRecommend()
      → exercise_recommendations tablosuna INSERT (exercise_id FK ile)

   ExerciseService.getExercisesForSession()
   → exercise_recommendations JOIN exercises ON exercise_id
     WHERE session_id = ?  (tek sorgu)

8. [Done]
   → PostureSessionSummary HomeScreen'e döner
   → HomeScreen özet grafiği ve egzersiz listesini günceller
```

---

## Güvenlik

- Tüm tablolarda **Row Level Security (RLS)** aktiftir — kullanıcılar yalnızca kendi verilerine erişebilir
- **JWT kimlik doğrulaması** Supabase Flutter SDK tarafından otomatik yönetilir
- **Ham video frame'leri hiçbir zaman saklanmaz** — yalnızca AI analiz sonuçları (skor, uyarılar) kaydedilir
- `supabase_config.dart` `.gitignore` ile versiyon kontrolünden hariç tutulmuştur
- AI servisi geliştirme aşamasında yerel ağda çalışır; yalnızca Supabase endpoint'i buluta açıktır
