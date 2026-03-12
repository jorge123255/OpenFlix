#!/usr/bin/env python3
"""
OpenFlix Commercial Detection — ONNX Inference Script

Takes a video file, extracts per-second audio/video features (matching the training
pipeline), runs the ONNX model, and outputs commercial break segments as JSON.

Usage:
    python3 commercial_detect.py --model /data/models/comskip.onnx --input video.ts --output-json

Dependencies: onnxruntime, numpy, librosa, scikit-learn (for scaler)
"""

import argparse
import json
import os
import pickle
import subprocess
import sys
import time
import numpy as np

# Must match training config exactly
SR = 22050
HOP_LENGTH = 512
N_MFCC = 13
SEQ_LEN = 60          # 60-second context window
INPUT_SIZE = 19        # 13 MFCC + RMS + centroid + ZCR + brightness + scene_change + position
CONFIDENCE_THRESHOLD = 0.5
MIN_COMMERCIAL_SEC = 15
MIN_CONTENT_GAP_SEC = 10  # merge commercials separated by <10s


def get_duration(video_path):
    """Get video duration in seconds via ffprobe."""
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", video_path],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe failed: {result.stderr}")
    data = json.loads(result.stdout)
    return float(data["format"]["duration"])


def extract_audio_features(video_path, duration):
    """Extract MFCC + energy features via ffmpeg → librosa."""
    import librosa

    cmd = [
        "ffmpeg", "-i", video_path,
        "-vn", "-ac", "1", "-ar", str(SR),
        "-f", "f32le", "-",
        "-loglevel", "quiet"
    ]
    proc = subprocess.run(cmd, capture_output=True)
    audio = np.frombuffer(proc.stdout, dtype=np.float32)

    if len(audio) < SR:
        return None

    mfcc = librosa.feature.mfcc(y=audio, sr=SR, n_mfcc=N_MFCC, hop_length=HOP_LENGTH)
    rms = librosa.feature.rms(y=audio, hop_length=HOP_LENGTH)[0]
    centroid = librosa.feature.spectral_centroid(y=audio, sr=SR, hop_length=HOP_LENGTH)[0]
    zcr = librosa.feature.zero_crossing_rate(y=audio, hop_length=HOP_LENGTH)[0]

    features = np.vstack([mfcc, rms, centroid, zcr]).T  # (n_frames, 16)

    frames_per_sec = SR / HOP_LENGTH
    n_seconds = int(duration)

    seg_features = []
    for sec in range(n_seconds):
        start_frame = int(sec * frames_per_sec)
        end_frame = int((sec + 1) * frames_per_sec)
        chunk = features[start_frame:end_frame]
        if len(chunk) == 0:
            seg_features.append(np.zeros(N_MFCC + 3))
        else:
            seg_features.append(np.mean(chunk, axis=0))

    return np.array(seg_features)


def extract_video_features(video_path, duration):
    """Extract brightness + scene change via ffmpeg showinfo."""
    n_seconds = int(duration)
    brightness = np.zeros(n_seconds)

    cmd = [
        "ffmpeg", "-i", video_path,
        "-vf", "fps=1,showinfo",
        "-f", "null", "-",
        "-loglevel", "info"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)

    for line in proc.stderr.split('\n'):
        if 'showinfo' in line and 'pts_time' in line:
            try:
                pts = float(line.split('pts_time:')[1].split()[0])
                sec = int(pts)
                if 0 <= sec < n_seconds and 'mean:[' in line:
                    lum_str = line.split('mean:[')[1].split(']')[0].split()[0]
                    brightness[sec] = float(lum_str)
            except Exception:
                pass

    scene_change = np.zeros(n_seconds)
    scene_change[1:] = (np.abs(np.diff(brightness)) > 20).astype(float)

    return np.column_stack([brightness, scene_change])


def build_features(video_path):
    """Extract all 19 features per second from a video."""
    duration = get_duration(video_path)
    n_seconds = int(duration)

    print(f"  Duration: {duration:.0f}s ({duration/60:.1f} min)", file=sys.stderr)
    print(f"  Extracting audio features...", file=sys.stderr)
    audio_feat = extract_audio_features(video_path, duration)
    if audio_feat is None:
        raise RuntimeError("Audio extraction failed (too short?)")

    print(f"  Extracting video features...", file=sys.stderr)
    video_feat = extract_video_features(video_path, duration)

    n = min(len(audio_feat), len(video_feat))
    position = np.arange(n, dtype=np.float32) / n

    all_features = np.hstack([
        audio_feat[:n],            # 16 features
        video_feat[:n],            # 2 features
        position[:n, np.newaxis],  # 1 feature
    ])  # total: 19

    return all_features, duration


def run_inference(features, model_path, scaler_path):
    """Run ONNX inference with sliding windows, return per-second probabilities."""
    import onnxruntime as ort

    # Load scaler
    with open(scaler_path, "rb") as f:
        scaler = pickle.load(f)

    # Normalize
    features = scaler.transform(features)

    n_seconds = len(features)
    probs = np.zeros(n_seconds)
    counts = np.zeros(n_seconds)

    # Create ONNX session
    sess = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
    input_name = sess.get_inputs()[0].name

    # Sliding window with 50% overlap (same as training)
    step = SEQ_LEN // 2
    for start in range(0, n_seconds - SEQ_LEN + 1, step):
        window = features[start:start + SEQ_LEN]
        x = window[np.newaxis, :, :].astype(np.float32)  # (1, 60, 19)
        
        result = sess.run(None, {input_name: x})
        window_probs = result[0][0]  # (60,)

        probs[start:start + SEQ_LEN] += window_probs
        counts[start:start + SEQ_LEN] += 1

    # Handle tail (last chunk if video doesn't divide evenly)
    if n_seconds > SEQ_LEN and counts[-1] == 0:
        window = features[-SEQ_LEN:]
        x = window[np.newaxis, :, :].astype(np.float32)
        result = sess.run(None, {input_name: x})
        window_probs = result[0][0]
        tail_start = n_seconds - SEQ_LEN
        probs[tail_start:] += window_probs
        counts[tail_start:] += 1

    # Average overlapping predictions
    mask = counts > 0
    probs[mask] /= counts[mask]

    return probs


def probs_to_segments(probs, threshold=CONFIDENCE_THRESHOLD,
                      min_len=MIN_COMMERCIAL_SEC, min_gap=MIN_CONTENT_GAP_SEC):
    """Convert per-second probabilities to commercial break segments."""
    is_commercial = probs >= threshold
    segments = []
    start = None

    for i in range(len(is_commercial)):
        if is_commercial[i] and start is None:
            start = i
        elif not is_commercial[i] and start is not None:
            segments.append((start, i))
            start = None
    if start is not None:
        segments.append((start, len(is_commercial)))

    # Merge segments separated by small gaps
    merged = []
    for seg in segments:
        if merged and (seg[0] - merged[-1][1]) < min_gap:
            merged[-1] = (merged[-1][0], seg[1])
        else:
            merged.append(seg)

    # Filter short segments
    result = []
    for s, e in merged:
        duration = e - s
        if duration >= min_len:
            avg_conf = float(np.mean(probs[s:e]))
            result.append({
                "start": float(s),
                "end": float(e),
                "confidence": round(avg_conf, 4),
                "label": "commercial"
            })

    return result


def main():
    parser = argparse.ArgumentParser(description="OpenFlix Comskip AI Inference")
    parser.add_argument("--model", required=True, help="Path to ONNX model")
    parser.add_argument("--input", required=True, help="Path to video file")
    parser.add_argument("--output-json", action="store_true", help="Output JSON to stdout")
    parser.add_argument("--scaler", default=None, help="Path to scaler.pkl (default: same dir as model)")
    parser.add_argument("--threshold", type=float, default=CONFIDENCE_THRESHOLD)
    args = parser.parse_args()

    scaler_path = args.scaler
    if scaler_path is None:
        scaler_path = os.path.join(os.path.dirname(args.model), "scaler.pkl")

    if not os.path.exists(args.model):
        output = {"segments": [], "duration": 0, "error": f"Model not found: {args.model}"}
        print(json.dumps(output))
        sys.exit(1)

    if not os.path.exists(scaler_path):
        output = {"segments": [], "duration": 0, "error": f"Scaler not found: {scaler_path}"}
        print(json.dumps(output))
        sys.exit(1)

    if not os.path.exists(args.input):
        output = {"segments": [], "duration": 0, "error": f"Video not found: {args.input}"}
        print(json.dumps(output))
        sys.exit(1)

    try:
        t0 = time.time()
        print(f"Processing: {args.input}", file=sys.stderr)

        features, duration = build_features(args.input)
        print(f"  Running ONNX inference ({len(features)} seconds)...", file=sys.stderr)

        probs = run_inference(features, args.model, scaler_path)
        segments = probs_to_segments(probs, threshold=args.threshold)

        elapsed = time.time() - t0
        print(f"  Found {len(segments)} commercial breaks in {elapsed:.1f}s", file=sys.stderr)

        # Also add content segments for completeness
        all_segments = list(segments)
        # Mark remaining time as content
        prev_end = 0.0
        for seg in segments:
            if seg["start"] > prev_end:
                all_segments.append({
                    "start": prev_end,
                    "end": seg["start"],
                    "confidence": round(1.0 - float(np.mean(probs[int(prev_end):int(seg["start"])])), 4),
                    "label": "content"
                })
            prev_end = seg["end"]
        if prev_end < duration:
            all_segments.append({
                "start": prev_end,
                "end": duration,
                "confidence": round(1.0 - float(np.mean(probs[int(prev_end):int(duration)])), 4),
                "label": "content"
            })

        all_segments.sort(key=lambda s: s["start"])

        output = {
            "segments": all_segments,
            "duration": duration,
            "processing_time": round(elapsed, 2),
            "model": os.path.basename(args.model),
            "threshold": args.threshold,
        }
        print(json.dumps(output))

    except Exception as e:
        output = {"segments": [], "duration": 0, "error": str(e)}
        print(json.dumps(output))
        sys.exit(1)


if __name__ == "__main__":
    main()
