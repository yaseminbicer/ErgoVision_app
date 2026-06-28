import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/posture_session_summary.dart';
import '../models/exercise_library_model.dart';
import '../services/posture_analysis_service.dart';
import '../services/exercise_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String? sessionId;
  final List<String> warnings;
  final int ergonomicSeconds;
  final int nonErgonomicSeconds;
  final int durationSeconds;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.warnings,
    required this.ergonomicSeconds,
    required this.nonErgonomicSeconds,
    required this.durationSeconds,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  List<ExerciseLibraryModel> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _finishSession();
  }

  Future<void> _finishSession() async {
    final sessionId = widget.sessionId;
    if (sessionId != null) {
      await PostureAnalysisService.endSession(
        sessionId: sessionId,
        durationSeconds: widget.durationSeconds,
        activeWarnings: widget.warnings,
      );
      final exercises = await ExerciseService.getExercisesForSession(sessionId);
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  double get _goodPosturePercent {
    final total = widget.ergonomicSeconds + widget.nonErgonomicSeconds;
    if (total == 0) return 0;
    return widget.ergonomicSeconds / total * 100;
  }

  void _done() {
    Navigator.pop(
      context,
      PostureSessionSummary(
        sessionId: widget.sessionId,
        ergonomicSeconds: widget.ergonomicSeconds,
        nonErgonomicSeconds: widget.nonErgonomicSeconds,
        durationSeconds: widget.durationSeconds,
        finalWarnings: widget.warnings,
      ),
    );
  }

  Future<void> _openYoutube(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back_wallpaper.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8B61C2)),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsRow(),
                            if (widget.warnings.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildWarningsSection(),
                            ],
                            const SizedBox(height: 24),
                            _buildExercisesSection(),
                            const SizedBox(height: 32),
                            _buildDoneButton(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Text(
        'Session Summary',
        style: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF212960),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(widget.durationSeconds),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            icon: Icons.self_improvement,
            label: 'Good Posture',
            value: '${_goodPosturePercent.toStringAsFixed(0)}%',
            valueColor: _goodPosturePercent >= 70
                ? const Color(0xFF4CAF50)
                : _goodPosturePercent >= 40
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B61C2), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF212960),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issues Detected',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212960),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: widget.warnings
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          w,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212960),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _exercises.isEmpty
              ? 'Exercises'
              : 'Recommended Exercises',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212960),
          ),
        ),
        const SizedBox(height: 10),
        if (_exercises.isNotEmpty)
          ..._exercises.map((ex) => _exerciseCard(ex))
        else if (_goodPosturePercent == 100)
          _emptyCard('Great job! No specific exercises needed for this session.')
        else
          _emptyCard('No exercises could be found for this session.'),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black54),
      ),
    );
  }

  Widget _exerciseCard(ExerciseLibraryModel ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: Image.asset(
              ex.imagePath,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 90,
                height: 90,
                color: const Color(0xFFE8E0F0),
                child: const Icon(Icons.fitness_center,
                    color: Color(0xFF8B61C2), size: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212960),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openYoutube(ex.youtubeUrl),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Watch on YouTube',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: _done,
          child: Container(
            width: double.infinity,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF8B61C2).withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
