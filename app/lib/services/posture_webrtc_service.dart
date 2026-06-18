import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import '../utils/backend_config.dart';

class PostureWarningUpdate {
  final List<String> warnings;
  final int postureScore;
  final bool isGoodPosture;
  final bool personDetected;
  final double shoulderTiltRatio;
  final double postureRatio;

  const PostureWarningUpdate({
    required this.warnings,
    required this.postureScore,
    required this.isGoodPosture,
    required this.personDetected,
    required this.shoulderTiltRatio,
    required this.postureRatio,
  });

  bool get isPostureCorrect => isGoodPosture;

  factory PostureWarningUpdate.fromJson(Map<String, dynamic> json) {
    return PostureWarningUpdate(
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((w) => w.toString())
          .toList(),
      postureScore: (json['posture_score'] as num?)?.toInt() ?? 0,
      isGoodPosture: json['is_good_posture'] as bool? ?? false,
      personDetected: json['person_detected'] as bool? ?? false,
      shoulderTiltRatio: (json['shoulder_tilt_ratio'] as num?)?.toDouble() ?? 0.0,
      postureRatio: (json['posture_ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PostureWebRTCService {
  PostureWebRTCService({String? offerUrl})
      : offerUrl = offerUrl ?? BackendConfig.aiOfferUrl;

  final String offerUrl;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final StreamController<PostureWarningUpdate> _warningsController =
      StreamController<PostureWarningUpdate>.broadcast();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;

  Stream<PostureWarningUpdate> get warningUpdates => _warningsController.stream;

  Future<void> initialize() async {
    await localRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280, 'min': 640},
        'height': {'ideal': 720, 'min': 480},
        'frameRate': {'ideal': 30, 'min': 15},
      },
    });
    localRenderer.srcObject = _localStream;

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _dataChannel = await _peerConnection!.createDataChannel(
      'posture-warnings',
      RTCDataChannelInit(),
    );
    _dataChannel!.onMessage = _handleDataChannelMessage;

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await _waitForIceGathering();

    final localDescription = await _peerConnection!.getLocalDescription();
    if (localDescription == null) {
      throw StateError('Could not create WebRTC offer.');
    }

    final response = await http.post(
      Uri.parse(offerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sdp': _injectBitrate(localDescription.sdp ?? ''),
        'type': localDescription.type,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Posture backend error: ${response.statusCode}');
    }

    final answer = jsonDecode(response.body) as Map<String, dynamic>;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'] as String, answer['type'] as String),
    );
  }

  // Adds b=AS:2000 (2 Mbps) to each video m-section in the SDP.
  String _injectBitrate(String sdp) {
    final lines = sdp.split('\r\n');
    final result = <String>[];
    bool inVideo = false;
    for (final line in lines) {
      if (line.startsWith('m=video')) inVideo = true;
      if (inVideo && line.startsWith('m=') && !line.startsWith('m=video')) {
        inVideo = false;
      }
      result.add(line);
      if (inVideo && line.startsWith('c=')) {
        result.add('b=AS:2000');
      }
    }
    return result.join('\r\n');
  }

  Future<void> _waitForIceGathering() async {
    if (_peerConnection!.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }

    final completer = Completer<void>();
    Timer? timeout;

    timeout = Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) completer.complete();
    });

    _peerConnection!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        completer.complete();
      }
    };

    await completer.future;
    timeout.cancel();
  }

  void _handleDataChannelMessage(RTCDataChannelMessage message) {
    try {
      final data = jsonDecode(message.text) as Map<String, dynamic>;
      final update = PostureWarningUpdate.fromJson(data);
      // Native WebRTC callback'inden Dart event loop'una taşı
      Future.microtask(() => _warningsController.add(update));
    } catch (_) {
      // Hatalı JSON gelirse sessizce atla
    }
  }

  Future<void> dispose() async {
    await _dataChannel?.close();
    await _peerConnection?.close();

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }

    await _localStream?.dispose();
    localRenderer.srcObject = null;
    await localRenderer.dispose();
    await _warningsController.close();
  }
}
