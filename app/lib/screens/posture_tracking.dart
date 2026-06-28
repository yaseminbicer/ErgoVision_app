import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/posture_session_summary.dart';
import '../services/posture_webrtc_service.dart';
import '../services/posture_analysis_service.dart';
import '../services/posture_service.dart';
import '../services/auth_service.dart';
import 'session_summary_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final PostureWebRTCService _postureService;
  StreamSubscription<PostureWarningUpdate>? _warningSubscription;

  // Timers
  Timer? _elapsedTimer;
  Timer? _snapshotTimer;

  // Session state
  String? _sessionId;
  int _elapsedSeconds = 0;
  int _ergonomicSeconds = 0;
  int _nonErgonomicSeconds = 0;
  bool _isPaused = false;
  bool _isInitializing = true;
  String? _connectionError;

  // Latest posture data from AI
  List<String> _warnings = [];
  bool _isPostureCorrect = true;
  bool _personDetected = false;
  int _currentScore = 0;
  PostureWarningUpdate? _latestUpdate;

  @override
  void initState() {
    super.initState();
    _postureService = PostureWebRTCService();
    _initConnection();
    _startElapsedTimer();
  }

  Future<void> _initConnection() async {
    try {
      await _postureService.initialize();

      // Start Supabase session if logged in
      final session = await PostureAnalysisService.startSession();
      _sessionId = session?.id;

      _warningSubscription = _postureService.warningUpdates.listen((update) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _latestUpdate = update;
            _personDetected = update.personDetected;
            // Only show real posture warnings, not the "No person detected" meta-warning
            _warnings = update.personDetected
                ? update.warnings
                : [];
            _isPostureCorrect = update.isPostureCorrect;
            _currentScore = update.postureScore;
          });
        });
      });

      // Save a posture snapshot every 10 seconds
      _snapshotTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!_isPaused) _saveSnapshot();
      });

      if (!mounted) return;
      setState(() => _isInitializing = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _connectionError = error.toString();
      });
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !mounted) return;
      setState(() {
        _elapsedSeconds++;
        // Only count posture time when a person is actually in frame
        if (_personDetected) {
          if (_isPostureCorrect) {
            _ergonomicSeconds++;
          } else {
            _nonErgonomicSeconds++;
          }
        }
      });
    });
  }

  Future<void> _saveSnapshot() async {
    final update = _latestUpdate;
    final sessionId = _sessionId;
    final userId = AuthService.currentUserId;
    if (update == null || sessionId == null || userId == null) return;
    if (!update.personDetected) return; // skip when no person in frame

    try {
      await PostureService.addRecord(
        sessionId: sessionId,
        userId: userId,
        postureScore: update.postureScore.toDouble(),
        isGoodPosture: update.isGoodPosture,
        torsoAngle: update.postureRatio * 180,
        neckAngle: update.postureRatio * 180,
        shoulderAngle: (1 - update.shoulderTiltRatio) * 180,
      );
    } catch (_) {}
  }

  String get _formattedTime {
    final h = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _togglePause() => setState(() => _isPaused = !_isPaused);

  Future<void> _stopTracking() async {
    _elapsedTimer?.cancel();
    _snapshotTimer?.cancel();

    final sessionId = _sessionId;
    final warnings = List<String>.from(_warnings);

    final summary = await Navigator.push<PostureSessionSummary>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: sessionId,
          warnings: warnings,
          ergonomicSeconds: _ergonomicSeconds,
          nonErgonomicSeconds: _nonErgonomicSeconds,
          durationSeconds: _elapsedSeconds,
        ),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, summary);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _snapshotTimer?.cancel();
    _warningSubscription?.cancel();
    _postureService.dispose();
    super.dispose();
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final glowColor = !_personDetected
        ? Colors.grey
        : _isPostureCorrect
            ? Colors.green
            : Colors.red;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? _buildLoading()
          : _connectionError != null
              ? _buildConnectionError()
              : Stack(
                  children: [
                    // Camera
                    SizedBox.expand(
                      child: RTCVideoView(
                        _postureService.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),

                    // Posture glow border
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: glowColor, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // Glass App Bar — timer + score
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildGlassAppBar(),
                    ),

                    // No person banner
                    if (!_personDetected && !_isInitializing)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 160,
                        child: _buildNoPersonBanner(),
                      )
                    // Warning card (only when person is detected)
                    else if (_warnings.isNotEmpty)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 160,
                        child: _buildWarningsCard(),
                      ),

                    // Pause / Stop
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _glassButton(
                            label: _isPaused ? 'Resume' : 'Pause',
                            onTap: _togglePause,
                          ),
                          const SizedBox(width: 30),
                          _glassButton(label: 'Stop', onTap: _stopTracking),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B61C2)),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding:
              const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 20),
          color: const Color(0xFF8B61C2).withValues(alpha: 0.35),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _formattedTime,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              _buildScoreBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge() {
    final color = !_personDetected
        ? Colors.grey
        : _currentScore >= 70
            ? Colors.green
            : _currentScore >= 50
                ? Colors.orange
                : Colors.red;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.85),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: Center(
        child: _personDetected
            ? Text(
                '$_currentScore',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Icon(Icons.person_off, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildWarningsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _warnings
                .map(
                  (w) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        w,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPersonBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'No person detected — sit in frame',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not connect to posture backend.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _connectionError ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassButton({required String label, required VoidCallback onTap}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 75,
            height: 75,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B61C2).withValues(alpha: 0.35),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
