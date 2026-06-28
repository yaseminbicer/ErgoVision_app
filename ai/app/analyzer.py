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
            min_tracking_confidence=0.5
        )
        self.detector = vision.PoseLandmarker.create_from_options(options)

    def evaluate_posture(self, landmarks, w: int, h: int):
        warnings = []
        
        nose = landmarks[0]
        l_sh = landmarks[11]
        r_sh = landmarks[12]

        # Ensure the upper body is actually visible before running heuristics
        if nose.visibility < 0.5 or l_sh.visibility < 0.5 or r_sh.visibility < 0.5:
            return {
                "person_detected": True,
                "warnings": ["Low Visibility - Please sit in frame"],
                "posture_score": 0,
                "shoulder_tilt_ratio": 0.0,
                "posture_ratio": 0.0
            }


        nose_x, nose_y = nose.x * w, nose.y * h
        l_sh_x, l_sh_y = l_sh.x * w, l_sh.y * h
        r_sh_x, r_sh_y = r_sh.x * w, r_sh.y * h

        shoulder_width = math.hypot(
            l_sh_x - r_sh_x, 
            l_sh_y - r_sh_y
        )
        
        if shoulder_width < 1e-5:
            return {
                "person_detected": True,
                "warnings": warnings,
                "posture_score": 100,
                "shoulder_tilt_ratio": 0.0,
                "posture_ratio": 0.0
            }

        y_diff = abs(l_sh_y - r_sh_y)
        tilt_ratio = y_diff / shoulder_width
        
        if tilt_ratio > 0.08:
            warnings.append("Uneven Shoulders")

        # 3. Check for Slouching (Forward Head Posture)
        shoulder_midpoint_y = (l_sh_y + r_sh_y) / 2.0
        neck_height = shoulder_midpoint_y - nose_y
        posture_ratio = neck_height / shoulder_width
        
        if posture_ratio < 0.6:  
            warnings.append("Slouching Detected")

        # Basic score calculation
        score = 100 - (len(warnings) * 20)

        return {
            "person_detected": True,
            "warnings": warnings,
            "posture_score": max(0, score),
            "shoulder_tilt_ratio": tilt_ratio,
            "posture_ratio": posture_ratio
        }

    def process_frame(self, bgr_image, timestamp_ms: int):
        # Extract actual image dimensions to pass to the evaluator
        h, w, _ = bgr_image.shape

        image_rgb = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)
        
        results = self.detector.detect_for_video(mp_image, timestamp_ms)
        
        if results.pose_landmarks:
            # Pass width (w) and height (h) to un-normalize the coordinates
            return self.evaluate_posture(results.pose_landmarks[0], w, h)
            
        # Fallback dictionary if no person is found in the frame
        return {
            "person_detected": False,
            "warnings": [],
            "posture_score": 0,
            "shoulder_tilt_ratio": 0.0,
            "posture_ratio": 0.0
        }