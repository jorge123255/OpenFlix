package dvr

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"os/exec"
	"sort"
	"strconv"
	"strings"
)

// AcoustIDDetector detects intro/outro segments using chromaprint audio fingerprinting.
// Install: apt-get install libchromaprint-tools  (provides fpcalc)
type AcoustIDDetector struct {
	FPCalcPath string // path to fpcalc binary (defaults to "fpcalc" in PATH)
	APIKey     string // optional AcoustID API key for music DB lookup
}

type fpCalcResult struct {
	Duration    float64 `json:"duration"`
	Fingerprint string  `json:"fingerprint"`
}

// Available returns true if fpcalc is installed and callable
func (a *AcoustIDDetector) Available() bool {
	fp := a.fpCalcBin()
	_, err := exec.LookPath(fp)
	return err == nil
}

func (a *AcoustIDDetector) fpCalcBin() string {
	if a.FPCalcPath != "" {
		return a.FPCalcPath
	}
	return "fpcalc"
}

// Fingerprint generates a chromaprint fingerprint for the given video/audio file.
// maxDuration=0 means fingerprint the entire file.
func (a *AcoustIDDetector) Fingerprint(ctx context.Context, filePath string, maxDuration float64) (*fpCalcResult, error) {
	args := []string{"-json"}
	if maxDuration > 0 {
		args = append(args, "-length", strconv.Itoa(int(maxDuration)))
	}
	args = append(args, filePath)

	cmd := exec.CommandContext(ctx, a.fpCalcBin(), args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("fpcalc failed: %w", err)
	}

	var result fpCalcResult
	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("fpcalc parse error: %w", err)
	}
	return &result, nil
}

// IntroSegment represents a detected intro/outro common to a series
type IntroSegment struct {
	StartSec   float64 `json:"start_sec"`
	EndSec     float64 `json:"end_sec"`
	Confidence float64 `json:"confidence"` // 0-1 similarity score
	Type       string  `json:"type"`       // "intro" or "outro"
}

// Status returns setup information about the AcoustID detector
func (a *AcoustIDDetector) Status() map[string]interface{} {
	avail := a.Available()
	return map[string]interface{}{
		"fpcalc_available": avail,
		"fpcalc_path":      a.fpCalcBin(),
		"ready":            avail,
		"setup_hint":       "Install chromaprint: apt-get install libchromaprint-tools",
	}
}

// DetectIntro fingerprints multiple episodes of the same series and finds
// the common audio segment at the start (intro).
// filePaths should contain 2+ episode files of the same series.
func (a *AcoustIDDetector) DetectIntro(ctx context.Context, filePaths []string) (*IntroSegment, error) {
	if len(filePaths) < 2 {
		return nil, fmt.Errorf("need at least 2 episodes to detect intro")
	}
	if !a.Available() {
		return nil, fmt.Errorf("fpcalc not available; install chromaprint: apt-get install libchromaprint-tools")
	}

	// Fingerprint first 5 minutes of each episode (intros are always near the start)
	const maxDuration = 5 * 60.0

	type fpEntry struct{ ints []int32 }
	var fps []fpEntry

	for _, path := range filePaths {
		result, err := a.Fingerprint(ctx, path, maxDuration)
		if err != nil {
			continue
		}
		ints, err := parseFP(result.Fingerprint)
		if err != nil {
			continue
		}
		fps = append(fps, fpEntry{ints: ints})
	}

	if len(fps) < 2 {
		return nil, fmt.Errorf("could not fingerprint enough files (got %d/%d)", len(fps), len(filePaths))
	}

	// Compare pairwise to get overall similarity distribution
	var similarities []float64
	for i := 0; i < len(fps)-1; i++ {
		for j := i + 1; j < len(fps); j++ {
			sim := fpSimilarity(fps[i].ints, fps[j].ints)
			similarities = append(similarities, sim)
		}
	}
	sort.Float64s(similarities)
	medianSim := similarities[len(similarities)/2]

	if medianSim < 0.5 {
		return nil, fmt.Errorf("no common intro found (median similarity: %.2f)", medianSim)
	}

	// Find how long the common prefix is using fps[0] vs fps[1]
	// (sliding window in 15-sec increments)
	fp0, fp1 := fps[0].ints, fps[1].ints
	minInts := len(fp0)
	if len(fp1) < minInts {
		minInts = len(fp1)
	}

	// chromaprint encodes ~8 ints/sec
	const intsPerSec = 8.0
	introDuration := 0.0

	for windowSec := 30.0; windowSec <= float64(minInts)/intsPerSec; windowSec += 15.0 {
		windowInts := int(windowSec * intsPerSec)
		if windowInts > len(fp0) || windowInts > len(fp1) {
			break
		}
		sim := fpSimilarity(fp0[:windowInts], fp1[:windowInts])
		if sim >= 0.6 {
			introDuration = windowSec
		} else {
			break
		}
	}

	if introDuration < 20 {
		return nil, fmt.Errorf("intro too short to be reliable (%.0f sec)", introDuration)
	}

	return &IntroSegment{
		StartSec:   0,
		EndSec:     introDuration,
		Confidence: medianSim,
		Type:       "intro",
	}, nil
}

// DetectOutro finds a common segment at the end of multiple episodes (credits).
func (a *AcoustIDDetector) DetectOutro(ctx context.Context, filePaths []string) (*IntroSegment, error) {
	if len(filePaths) < 2 {
		return nil, fmt.Errorf("need at least 2 episodes to detect outro")
	}
	if !a.Available() {
		return nil, fmt.Errorf("fpcalc not available")
	}

	// For outros, fingerprint the last 5 minutes
	// fpcalc doesn't support seeking, so we'd need ffmpeg to clip first
	// For now return unimplemented — this is a future improvement
	return nil, fmt.Errorf("outro detection requires ffmpeg clip pre-processing (coming soon)")
}

// ---- helpers ----

func parseFP(fp string) ([]int32, error) {
	parts := strings.Split(fp, ",")
	ints := make([]int32, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		n, err := strconv.ParseInt(p, 10, 32)
		if err != nil {
			return nil, err
		}
		ints = append(ints, int32(n))
	}
	return ints, nil
}

func hammingDist(a, b int32) int {
	x := uint32(a ^ b)
	count := 0
	for x != 0 {
		count += int(x & 1)
		x >>= 1
	}
	return count
}

// fpSimilarity returns 0-1 similarity between two fingerprint int arrays.
// Uses the shorter as a needle and slides it over the longer one.
func fpSimilarity(fp1, fp2 []int32) float64 {
	if len(fp1) == 0 || len(fp2) == 0 {
		return 0
	}
	needle, haystack := fp1, fp2
	if len(fp2) < len(fp1) {
		needle, haystack = fp2, fp1
	}
	if len(needle) > len(haystack) {
		return 0
	}

	best := 0.0
	totalBits := len(needle) * 32
	for i := 0; i <= len(haystack)-len(needle); i++ {
		window := haystack[i : i+len(needle)]
		diff := 0
		for j, n := range needle {
			diff += hammingDist(n, window[j])
		}
		sim := 1.0 - float64(diff)/float64(totalBits)
		if sim > best {
			best = sim
		}
	}
	return math.Round(best*1000) / 1000
}
