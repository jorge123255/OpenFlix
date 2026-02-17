package dvr

import (
	"encoding/json"
	"strconv"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/models"
)

// ParseQuery parses a JSON query DSL string into a slice of RuleConditions
func ParseQuery(queryJSON string) ([]models.RuleCondition, error) {
	if queryJSON == "" || queryJSON == "[]" {
		return nil, nil
	}
	var conditions []models.RuleCondition
	if err := json.Unmarshal([]byte(queryJSON), &conditions); err != nil {
		return nil, err
	}
	return conditions, nil
}

// EvaluateQuery checks if a program matches ALL conditions in the query (AND logic)
func EvaluateQuery(conditions []models.RuleCondition, program *models.Program) bool {
	if len(conditions) == 0 {
		return false // Empty query matches nothing
	}
	for _, cond := range conditions {
		if !EvaluateCondition(cond, program) {
			return false
		}
	}
	return true
}

// EvaluateCondition checks if a program matches a single condition
func EvaluateCondition(cond models.RuleCondition, program *models.Program) bool {
	fieldValue := getFieldValue(cond.Field, program)
	return evaluateOp(cond.Op, fieldValue, cond.Value, cond.Field)
}

// getFieldValue extracts the value of a field from a Program for comparison
func getFieldValue(field string, p *models.Program) string {
	switch strings.ToLower(field) {
	case "title":
		return p.Title
	case "subtitle":
		return p.Subtitle
	case "channel":
		return p.ChannelID
	case "category":
		return p.Category
	case "genre":
		return p.Category // Genre maps to category in EPG
	case "isnew":
		return strconv.FormatBool(p.IsNew)
	case "issports":
		return strconv.FormatBool(p.IsSports)
	case "ismovie":
		return strconv.FormatBool(p.IsMovie)
	case "iskids":
		return strconv.FormatBool(p.IsKids)
	case "isnews":
		return strconv.FormatBool(p.IsNews)
	case "ispremiere":
		return strconv.FormatBool(p.IsPremiere)
	case "islive":
		return strconv.FormatBool(p.IsLive)
	case "isfinale":
		return strconv.FormatBool(p.IsFinale)
	case "team":
		return p.Teams
	case "league":
		return p.League
	case "dayofweek":
		return p.Start.Weekday().String()
	case "timeslot":
		return p.Start.Format("15:04")
	case "seriesid":
		return p.SeriesID
	case "contentrating", "rating":
		return p.Rating
	case "episodenum":
		return p.EpisodeNum
	case "description":
		return p.Description
	default:
		return ""
	}
}

// evaluateOp applies an operator to compare field value against condition value
func evaluateOp(op, fieldValue, condValue, field string) bool {
	switch strings.ToUpper(op) {
	case "EQ":
		return equalOp(fieldValue, condValue, field)
	case "NE":
		return !equalOp(fieldValue, condValue, field)
	case "LIKE":
		return likeOp(fieldValue, condValue)
	case "IN":
		return inOp(fieldValue, condValue, field)
	case "NI":
		return !inOp(fieldValue, condValue, field)
	case "GT":
		return compareOp(fieldValue, condValue) > 0
	case "LT":
		return compareOp(fieldValue, condValue) < 0
	default:
		return false
	}
}

// equalOp handles EQ comparison with type-awareness for booleans
func equalOp(fieldValue, condValue, field string) bool {
	// For boolean fields, normalize
	if isBoolField(field) {
		return strings.EqualFold(fieldValue, condValue)
	}
	return strings.EqualFold(fieldValue, condValue)
}

// likeOp handles LIKE matching - case-insensitive substring search
func likeOp(fieldValue, condValue string) bool {
	fv := strings.ToLower(fieldValue)
	cv := strings.ToLower(condValue)

	// Support SQL-like wildcards
	if strings.HasPrefix(cv, "%") && strings.HasSuffix(cv, "%") {
		return strings.Contains(fv, cv[1:len(cv)-1])
	}
	if strings.HasPrefix(cv, "%") {
		return strings.HasSuffix(fv, cv[1:])
	}
	if strings.HasSuffix(cv, "%") {
		return strings.HasPrefix(fv, cv[:len(cv)-1])
	}

	// Default: substring match (most intuitive for title searches)
	return strings.Contains(fv, cv)
}

// inOp handles IN matching - checks if field value is in a comma-separated list
// For fields like "team" that are themselves comma-separated, checks for overlap
func inOp(fieldValue, condValue, field string) bool {
	condValues := splitTrim(condValue)

	// For multi-value fields (team, channel with multiple values), check overlap
	if field == "team" {
		fieldValues := splitTrim(fieldValue)
		for _, fv := range fieldValues {
			for _, cv := range condValues {
				if strings.EqualFold(fv, cv) {
					return true
				}
				// Also check substring for team matching
				// (e.g., "Chicago Bulls" matches "Bulls")
				if strings.Contains(strings.ToLower(fv), strings.ToLower(cv)) {
					return true
				}
			}
		}
		return false
	}

	// For channel field, check if channel ID is in the list
	if field == "channel" {
		for _, cv := range condValues {
			if strings.EqualFold(fieldValue, strings.TrimSpace(cv)) {
				return true
			}
		}
		return false
	}

	// For dayOfWeek, check if the day is in the list
	if field == "dayofweek" || field == "dayOfWeek" {
		for _, cv := range condValues {
			if strings.EqualFold(fieldValue, strings.TrimSpace(cv)) {
				return true
			}
		}
		return false
	}

	// Default: check if field value is in the condition values list
	for _, cv := range condValues {
		if strings.EqualFold(fieldValue, strings.TrimSpace(cv)) {
			return true
		}
	}
	return false
}

// compareOp does numeric comparison, returning -1, 0, or 1
func compareOp(fieldValue, condValue string) int {
	// Try numeric comparison first
	fv, err1 := strconv.ParseFloat(fieldValue, 64)
	cv, err2 := strconv.ParseFloat(condValue, 64)
	if err1 == nil && err2 == nil {
		if fv < cv {
			return -1
		}
		if fv > cv {
			return 1
		}
		return 0
	}

	// Try time comparison (HH:MM format)
	ft, err1 := time.Parse("15:04", fieldValue)
	ct, err2 := time.Parse("15:04", condValue)
	if err1 == nil && err2 == nil {
		if ft.Before(ct) {
			return -1
		}
		if ft.After(ct) {
			return 1
		}
		return 0
	}

	// Fall back to string comparison
	return strings.Compare(strings.ToLower(fieldValue), strings.ToLower(condValue))
}

// isBoolField returns true if the field stores a boolean value
func isBoolField(field string) bool {
	switch strings.ToLower(field) {
	case "isnew", "issports", "ismovie", "iskids", "isnews", "ispremiere", "islive", "isfinale":
		return true
	}
	return false
}

// splitTrim splits a string by comma and trims whitespace
func splitTrim(s string) []string {
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			result = append(result, p)
		}
	}
	return result
}

// MatchProgramsForRule finds all programs in the given time window that match a rule's query
func MatchProgramsForRule(programs []models.Program, rule *models.DVRRule) []models.Program {
	conditions, err := ParseQuery(rule.Query)
	if err != nil || len(conditions) == 0 {
		return nil
	}

	var matched []models.Program
	for i := range programs {
		if EvaluateQuery(conditions, &programs[i]) {
			matched = append(matched, programs[i])
		}
	}
	return matched
}
