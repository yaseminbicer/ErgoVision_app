import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import math


class PostureAnalyzer:
    def __init__(self, model_path: str = 'pose_landmarker_full.task'):
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.VIDEO,
            min_pose_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        self.detector = vision.PoseLandmarker.create_from_options(options)

    # MediaPipe landmark indices
    # 0:nose  7:left-ear  8:right-ear
    # 11:left-shoulder  12:right-shoulder
    # 23:left-hip  24:right-hip

    def _vis(self, lm, threshold=0.4) -> bool:
        return lm.visibility >= threshold

    def evaluate_posture(self, landmarks) -> dict:
        warnings = []

        nose   = landmarks[0]
        l_ear  = landmarks[7]
        r_ear  = landmarks[8]
        l_sh   = landmarks[11]
        r_sh   = landmarks[12]
        l_hip  = landmarks[23]
        r_hip  = landmarks[24]

        # ── Core landmarks must be visible ──────────────────────────────────
        if not (self._vis(nose) and self._vis(l_sh) and self._vis(r_sh)):
            return {
                "warnings": ["Low Visibility - Please sit in frame"],
                "posture_score": 0,
                "is_good_posture": False,
                "person_detected": True,
                "shoulder_tilt_ratio": 0.0,
                "posture_ratio": 0.0,
            }

        shoulder_width = math.hypot(l_sh.x - r_sh.x, l_sh.y - r_sh.y)
        if shoulder_width < 1e-5:
            return {
                "warnings": [],
                "posture_score": 100,
                "is_good_posture": True,
                "person_detected": True,
                "shoulder_tilt_ratio": 0.0,
                "posture_ratio": 1.0,
            }

        shoulder_mid_x = (l_sh.x + r_sh.x) / 2.0
        shoulder_mid_y = (l_sh.y + r_sh.y) / 2.0

        # ── 1. Uneven Shoulders (tilt_ratio > 8 %) ──────────────────────────
        y_diff     = abs(l_sh.y - r_sh.y)
        tilt_ratio = y_diff / shoulder_width
        if tilt_ratio > 0.08:
            warnings.append("Uneven Shoulders")

        # ── 2. Slouching — neck-height to shoulder-width ratio < 0.70 ───────
        neck_height   = shoulder_mid_y - nose.y
        posture_ratio = neck_height / shoulder_width
        if posture_ratio < 0.7:
            warnings.append("Slouching Detected")

        # ── 3. Forward Head Posture — nose ahead of shoulder midpoint ────────
        # In normalized coordinates x increases rightward; for front-facing cam
        # nose should be close to shoulder_mid_x horizontally.
        # We use the horizontal offset scaled by shoulder_width.
        forward_offset = abs(nose.x - shoulder_mid_x) / shoulder_width
        if forward_offset > 0.18:
            warnings.append("Forward Head Posture")

        # ── 4. Head Tilt — ear level difference ──────────────────────────────
        if self._vis(l_ear) and self._vis(r_ear):
            ear_tilt = abs(l_ear.y - r_ear.y) / shoulder_width
            if ear_tilt > 0.10:
                warnings.append("Head Tilting")

        # ── 5. Hip Imbalance ─────────────────────────────────────────────────
        if self._vis(l_hip) and self._vis(r_hip):
            hip_width = math.hypot(l_hip.x - r_hip.x, l_hip.y - r_hip.y)
            if hip_width > 1e-5:
                hip_tilt = abs(l_hip.y - r_hip.y) / hip_width
                if hip_tilt > 0.10:
                    warnings.append("Uneven Hips")

        # ── Score ─────────────────────────────────────────────────────────────
        # Shoulder tilt: up to 30 pts
        shoulder_penalty = min(30, int((tilt_ratio / 0.08) * 30))
        # Slouching: up to 40 pts
        posture_penalty  = min(40, int((1 - min(posture_ratio / 0.7, 1.0)) * 40))
        # Forward head: up to 20 pts
        forward_penalty  = min(20, int((forward_offset / 0.18) * 20))
        # Head tilt: up to 10 pts (only when visible)
        ear_penalty = 0
        if self._vis(l_ear) and self._vis(r_ear):
            ear_tilt_val = abs(l_ear.y - r_ear.y) / shoulder_width
            ear_penalty  = min(10, int((ear_tilt_val / 0.10) * 10))

        posture_score = max(0, 100 - shoulder_penalty - posture_penalty - forward_penalty - ear_penalty)

        return {
            "warnings": warnings,
            "posture_score": posture_score,
            "is_good_posture": len(warnings) == 0,
            "person_detected": True,
            "shoulder_tilt_ratio": round(tilt_ratio, 4),
            "posture_ratio": round(posture_ratio, 4),
        }

    def process_frame(self, bgr_image, timestamp_ms: int) -> dict:
        image_rgb = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2RGB)
        mp_image  = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)

        results = self.detector.detect_for_video(mp_image, timestamp_ms)

        if results.pose_landmarks:
            return self.evaluate_posture(results.pose_landmarks[0])

        return {
            "warnings": ["No person detected"],
            "posture_score": 0,
            "is_good_posture": False,
            "person_detected": False,
            "shoulder_tilt_ratio": 0.0,
            "posture_ratio": 0.0,
        }
