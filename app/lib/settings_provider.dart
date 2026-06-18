import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsProvider extends ChangeNotifier {
  bool soundEnabled = true;
  bool cameraEnabled = false;

  void setCameraEnabledDirect(bool value) {
    cameraEnabled = value;
    notifyListeners();
  }

  Future<void> setCameraEnabled(bool value) async {
    if (value) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        cameraEnabled = false;
      } else {
        cameraEnabled = status.isGranted;
      }
    } else {
      cameraEnabled = false;
    }

    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    soundEnabled = value;
    notifyListeners();
  }

  Future<void> syncCameraPermission() async {
    final status = await Permission.camera.status;
    cameraEnabled = status.isGranted;
    notifyListeners();
  }
}