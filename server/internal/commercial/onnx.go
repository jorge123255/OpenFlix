package commercial

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"time"
)

// ONNXDetector uses an ONNX model for commercial detection via Python subprocess
type ONNXDetector struct {
	ModelPath  string
	ScriptPath string
}

type onnxResult struct {
	Segments []struct {
		Start      float64 `json:"start"`
		End        float64 `json:"end"`
		Confidence float64 `json:"confidence"`
		Label      string  `json:"label"` // "commercial" or "content"
	} `json:"segments"`
	Duration float64 `json:"duration"`
	Error    string  `json:"error,omitempty"`
}

// Detect runs ONNX inference on the video file, returning commercial breaks.
// Requires python3 + onnxruntime + numpy installed, plus a trained model at ModelPath.
func (o *ONNXDetector) Detect(ctx context.Context, videoPath string) ([]CommercialBreak, error) {
	scriptPath := o.ScriptPath
	if scriptPath == "" {
		scriptPath = "/data/models/commercial_detect.py"
	}

	ctx, cancel := context.WithTimeout(ctx, 20*time.Minute)
	defer cancel()

	cmd := exec.CommandContext(ctx, "python3", scriptPath,
		"--model", o.ModelPath,
		"--input", videoPath,
		"--output-json",
	)

	output, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return nil, fmt.Errorf("ONNX inference failed: %s", string(exitErr.Stderr))
		}
		return nil, fmt.Errorf("ONNX inference failed: %w", err)
	}

	var result onnxResult
	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse ONNX output: %w", err)
	}

	if result.Error != "" {
		return nil, fmt.Errorf("ONNX error: %s", result.Error)
	}

	var breaks []CommercialBreak
	for _, seg := range result.Segments {
		if seg.Label == "commercial" {
			breaks = append(breaks, CommercialBreak{
				StartTime:  seg.Start,
				EndTime:    seg.End,
				Duration:   seg.End - seg.Start,
				Confidence: seg.Confidence,
			})
		}
	}
	return breaks, nil
}

// ModelAvailable checks whether the ONNX model file and python3 exist
func (o *ONNXDetector) ModelAvailable() bool {
	if o.ModelPath == "" {
		return false
	}
	if _, err := exec.LookPath("python3"); err != nil {
		return false
	}
	cmd := exec.Command("test", "-f", o.ModelPath)
	return cmd.Run() == nil
}

// Status returns a human-readable status string for the ONNX detector
func (o *ONNXDetector) Status() map[string]interface{} {
	hasPython := false
	if _, err := exec.LookPath("python3"); err == nil {
		hasPython = true
	}
	modelExists := o.ModelAvailable()
	return map[string]interface{}{
		"python3_available": hasPython,
		"model_path":        o.ModelPath,
		"model_exists":      modelExists,
		"ready":             hasPython && modelExists,
		"setup_hint":        "pip3 install onnxruntime numpy; place model at /data/models/commercial_skip_v5.onnx and scaler at /data/models/scaler_v5.pkl",
	}
}
