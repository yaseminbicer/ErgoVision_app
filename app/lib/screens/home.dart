import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'posture_tracking.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/posture_session_summary.dart';
import '../models/exercise_library_model.dart';
import '../services/exercise_service.dart';
import '../settings_provider.dart';
import '../widgets/app_layout.dart';

class HomeScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const HomeScreen({super.key, required this.isFirstLaunch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Color ergonomicLineColor = Color(0xFFD9F5FF);
  static const Color nonErgonomicLineColor = Color(0xFF9178CB);

  PostureSessionSummary? _latestSessionSummary;
  List<ExerciseLibraryModel> _exercises = [];
  List<String> _activeWarnings = [];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SettingsProvider>().syncCameraPermission();
    }
  }

  void _showCameraDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Camera Access Denied"),
          content: const Text("Enable camera access to use posture tracking."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<SettingsProvider>().syncCameraPermission();
    });
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await ExerciseService.getAllExercises();
      if (!mounted) return;
      setState(() => _exercises = list);
    } catch (_) {}
  }

  Future<void> _loadExercisesByWarnings(List<String> warnings) async {
    try {
      final list = await ExerciseService.getExercisesByWarnings(warnings);
      if (!mounted) return;
      setState(() => _exercises = list);
    } catch (_) {}
  }

  Future<void> openUrl(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exercise link has not been added yet.")),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _startTracking() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.cameraEnabled) {
      _showCameraDeniedDialog();
      return;
    }

    final summary = await Navigator.push<PostureSessionSummary>(
      context,
      MaterialPageRoute(builder: (context) => const TrackingScreen()),
    );

    if (!mounted || summary == null) return;

    setState(() {
      _latestSessionSummary = summary;
      _activeWarnings = summary.finalWarnings;
    });

    if (summary.finalWarnings.isNotEmpty) {
      _loadExercisesByWarnings(summary.finalWarnings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(currentPage: 'home', builder: _buildMainUI);
  }

  Widget _buildMainUI(VoidCallback toggleMenu) {
    return Stack(
      children: [
        /// Background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/back_wallpaper.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.25),
                Colors.transparent,
                Colors.blue.withOpacity(0.25),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: toggleMenu,
                    ),

                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return Row(
                          children: [
                            Text(
                              "Live Detection:",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),

                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: settings.cameraEnabled
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              settings.cameraEnabled ? "Enabled" : "Disabled",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "Summary",
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                /// Chart
                SizedBox(height: 220, child: _buildSummaryChart()),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      _activeWarnings.isEmpty
                          ? "Recommended Exercises"
                          : "Exercises for You",
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_activeWarnings.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _activeWarnings = []);
                          _loadExercises();
                        },
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 15),

                /// Exercise List
                SizedBox(
                  height: 190,
                  child: _exercises.isEmpty
                      ? Center(
                          child: Text(
                            'Loading exercises...',
                            style: GoogleFonts.montserrat(fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            final ex = _exercises[index];

                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 12,
                                    color: Colors.black.withOpacity(0.08),
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD9F5FF),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Center(
                                              child: Image.asset(
                                                ex.imagePath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.fitness_center,
                                                  size: 40,
                                                  color: Color(0xFF8B61C2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  openUrl(ex.youtubeUrl),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  "VIEW",
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      ex.title,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const Spacer(),

                /// Button
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: ElevatedButton(
                          onPressed: _startTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF03102F,
                            ).withOpacity(0.85),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Begin Tracking",
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    "ErgoVision is intended for educational purposes only and is not a medical device.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 10),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChart() {
    final summary = _latestSessionSummary;

    if (summary == null) {
      return SizedBox.expand(
        child: Center(
          child: Text(
            "No tracking data found yet",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF212960),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final ergonomicMinutes = summary.ergonomicMinutes;
    final nonErgonomicMinutes = summary.nonErgonomicMinutes;
    final maxMinutes = [
      ergonomicMinutes,
      nonErgonomicMinutes,
      1.0,
    ].reduce((value, element) => value > element ? value : element);

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: maxMinutes,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [FlSpot(0, 0), FlSpot(1, ergonomicMinutes)],
                  isCurved: true,
                  color: ergonomicLineColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: [FlSpot(0, 0), FlSpot(1, nonErgonomicMinutes)],
                  isCurved: true,
                  color: nonErgonomicLineColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChartLegendItem(
              color: ergonomicLineColor,
              label: 'Ergonomic',
              minutes: ergonomicMinutes,
            ),
            const SizedBox(width: 18),
            _buildChartLegendItem(
              color: nonErgonomicLineColor,
              label: 'Non-ergonomic',
              minutes: nonErgonomicMinutes,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartLegendItem({
    required Color color,
    required String label,
    required double minutes,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${minutes.toStringAsFixed(1)} min',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
