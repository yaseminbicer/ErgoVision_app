import json
import asyncio
import time
import traceback
from collections import deque, Counter
import av
from aiortc import RTCPeerConnection, RTCSessionDescription, RTCConfiguration, RTCIceServer
from app.analyzer import PostureAnalyzer

active_connections = set()

_MODEL_PATH = "pose_landmarker_full.task"

# Temporal smoothing constants
_WINDOW    = 5  # last N frames kept
_THRESHOLD = 3  # warning must appear in this many frames to be emitted


def _smooth(result: dict, warning_buf: deque, score_buf: deque) -> dict:
    """Stabilise per-frame results over a rolling window."""
    person = result.get("person_detected", False)

    if not person:
        warning_buf.clear()
        score_buf.clear()
        return result

    warning_buf.append(result["warnings"])
    score_buf.append(result["posture_score"])

    counts = Counter(w for warnings in warning_buf for w in warnings)
    stable_warnings = [w for w, n in counts.items() if n >= _THRESHOLD]
    avg_score = int(sum(score_buf) / len(score_buf))

    return {
        **result,
        "warnings":       stable_warnings,
        "posture_score":  avg_score,
        "is_good_posture": len(stable_warnings) == 0,
    }


async def handle_offer(sdp: str, sdp_type: str):
    offer = RTCSessionDescription(sdp=sdp, type=sdp_type)

    config = RTCConfiguration(
        iceServers=[RTCIceServer(urls=["stun:stun.l.google.com:19302"])]
    )
    pc = RTCPeerConnection(configuration=config)
    active_connections.add(pc)

    # Fresh analyzer per connection — prevents MediaPipe timestamp state
    # from a previous session causing "monotonically increasing" rejections.
    analyzer = PostureAnalyzer(_MODEL_PATH)

    state = {"data_channel": None}

    @pc.on("datachannel")
    def on_datachannel(channel):
        state["data_channel"] = channel

    @pc.on("connectionstatechange")
    async def on_connectionstatechange():
        if pc.connectionState in ["failed", "closed"]:
            active_connections.discard(pc)

    @pc.on("track")
    def on_track(track):
        if track.kind == "video":
            async def process_video():
                start_time  = time.time()
                last_ts_ms  = 0
                warning_buf = deque(maxlen=_WINDOW)
                score_buf   = deque(maxlen=_WINDOW)

                while True:
                    try:
                        frame = await track.recv()
                        img   = frame.to_ndarray(format="bgr24")

                        # Guarantee strictly-increasing timestamps for MediaPipe VIDEO mode
                        ts = int((time.time() - start_time) * 1000)
                        ts = max(ts, last_ts_ms + 1)
                        last_ts_ms = ts

                        raw = await asyncio.to_thread(
                            analyzer.process_frame, img, ts
                        )

                        result = _smooth(raw, warning_buf, score_buf)

                        dc = state["data_channel"]
                        if dc and dc.readyState == "open":
                            dc.send(json.dumps(result))

                    except av.error.EOFError:
                        break
                    except Exception as e:
                        print(f"Track processing error: {e.__class__.__name__}: {e}")
                        traceback.print_exc()
                        break

            asyncio.ensure_future(process_video())

    await pc.setRemoteDescription(offer)
    answer = await pc.createAnswer()
    await pc.setLocalDescription(answer)

    return {"sdp": pc.localDescription.sdp, "type": pc.localDescription.type}
