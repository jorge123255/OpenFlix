package metadata

import (
	"regexp"
	"strconv"
	"strings"
	"unicode"
)

// qualityTags are tokens that indicate the start of technical file info.
// Anything from the first match onward gets stripped from the title.
var qualityTagRe = regexp.MustCompile(`(?i)\b(` +
	// Resolution
	`4K|2160p|1080p|1080i|720p|720i|576p|480p|480i|` +
	// HDR formats
	`HDR10\+|HDR10|Dolby\.?Vision|DV\b|HDR\b|` +
	// Source
	`BluRay|Blu-Ray|BDRip|BDRemux|REMUX|WEB-DL|WEBRip|WEB\b|HDTV|DVDRip|DVD|PDTV|` +
	// Encoding
	`HEVC|x265|H\.265|x264|H\.264|AVC|AV1|VP9|` +
	// Audio
	`TrueHD|Atmos|DTS-HD|DTS|DD5\.1|DDP5\.1|AAC|AC3|` +
	// Common scene tags
	`PROPER|REPACK|EXTENDED|THEATRICAL|UNRATED|DIRECTORS\.CUT|` +
	// Release group brackets often start with these
	`YIFY|YTS|RARBG|FGT|SPARKS|` +
	// Misc
	`COMPLETE|DUBBED|MULTI` +
	`)`)

// bracketRe matches content in [] or () that contains quality tags
var bracketQualityRe = regexp.MustCompile(`(?i)\s*[\(\[][^\)\]]*` +
	`(4K|2160p|1080p|720p|HDR|HEVC|x265|x264|BluRay|WEB|REMUX|DV\b|Dolby)` +
	`[^\)\]]*[\)\]]`)

// yearRe extracts a 4-digit year from a title
var yearRe = regexp.MustCompile(`\b(19[0-9]{2}|20[0-9]{2})\b`)

// editionTokens are recognisable quality labels we want to store
var editionTokens = []string{
	"4K", "2160p", "1080p", "1080i", "720p",
	"HDR10+", "HDR10", "Dolby Vision", "DV", "HDR",
	"HEVC", "x265", "H.265", "AV1",
	"BluRay", "REMUX", "WEB-DL", "WEBRip",
	"TrueHD", "Atmos", "DTS-HD",
}

// FilenameStyleTitle returns true when the title looks like a scene/torrent filename
// rather than a human-readable title. The distinction matters because we only write
// the cleaned title back to the DB for filenames — human titles stay as-is.
//
// Rules (any one is sufficient):
//   - Contains an underscore (almost always a filename separator)
//   - Contains a bracket group with a known quality tag e.g. [1080p HEVC]
//   - Contains a dot where both the word before AND the word after the dot are
//     2+ characters long. This correctly classifies:
//     "The.Dark.Knight" → true  (3 . 4 chars — filename separator)
//     "U.S.A."          → false (1 . 1 chars — abbreviation)
//     "Mr. Robot"       → false (dot followed by space — normal punctuation)
//     "H.264"           → false (1 . 3 chars — first segment is single char)
func FilenameStyleTitle(s string) bool {
	if strings.Contains(s, "_") {
		return true
	}
	if strings.Contains(s, "[") && bracketQualityRe.MatchString(s) {
		return true
	}
	// Measure word lengths on both sides of each dot.
	// A filename separator has >= 2 chars on both sides; abbreviations do not.
	for i, r := range s {
		if r != '.' {
			continue
		}
		if i+1 >= len(s) || s[i+1] == ' ' {
			continue // trailing dot or "word. next" — normal punctuation
		}
		// Count chars in the word ending just before this dot
		before := 0
		for j := i - 1; j >= 0 && s[j] != '.' && s[j] != ' '; j-- {
			before++
		}
		// Count chars in the word starting just after this dot
		after := 0
		for j := i + 1; j < len(s) && s[j] != '.' && s[j] != ' '; j++ {
			after++
		}
		if before >= 2 && after >= 2 {
			return true
		}
	}
	return false
}

// CleanTitle strips resolution/quality tags from a media title and extracts:
//   - cleanTitle: the human-readable title without technical junk
//   - year:       the detected release year (0 if not found)
//   - edition:    a formatted string of quality tags found (e.g. "4K HDR10 HEVC")
func CleanTitle(raw string) (cleanTitle string, year int, edition string) {
	// Step 1: collect quality tags before we strip them
	var editionParts []string
	upperRaw := strings.ToUpper(raw)
	for _, tok := range editionTokens {
		if strings.Contains(upperRaw, strings.ToUpper(tok)) {
			// Skip if a more specific token already covers this one (e.g. skip "HDR" if "HDR10" found)
			redundant := false
			for _, existing := range editionParts {
				if strings.Contains(strings.ToUpper(existing), strings.ToUpper(tok)) {
					redundant = true
					break
				}
			}
			if !redundant {
				editionParts = append(editionParts, tok)
			}
		}
	}
	if len(editionParts) > 0 {
		edition = strings.Join(editionParts, " ")
	}

	// Step 2: strip bracket groups that contain quality info
	title := bracketQualityRe.ReplaceAllString(raw, "")

	// Step 3: find the first quality token in the remaining title and cut there
	if loc := qualityTagRe.FindStringIndex(title); loc != nil {
		title = title[:loc[0]]
	}

	// Step 4: extract year
	if m := yearRe.FindString(title); m != "" {
		year, _ = strconv.Atoi(m)
		// Remove the year (with surrounding parens/brackets if present)
		title = regexp.MustCompile(`\s*[\(\[]?`+m+`[\)\]]?\s*`).ReplaceAllString(title, " ")
	}

	// Step 5: clean up leftover punctuation
	title = strings.Map(func(r rune) rune {
		if r == '_' || r == '.' {
			return ' '
		}
		return r
	}, title)

	// Collapse multiple spaces
	title = strings.Join(strings.FieldsFunc(title, unicode.IsSpace), " ")
	title = strings.Trim(title, " -–_")

	cleanTitle = title
	return
}
