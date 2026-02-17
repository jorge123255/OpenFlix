package search

import (
	"fmt"
	"strings"
	"time"

	"github.com/blevesearch/bleve/v2"
	"github.com/blevesearch/bleve/v2/mapping"
	bleveQuery "github.com/blevesearch/bleve/v2/search/query"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// Document type prefixes used in index IDs
const (
	DocTypeFile    = "file"
	DocTypeGroup   = "group"
	DocTypeMedia   = "media"
	DocTypeChannel = "channel"
	DocTypeProgram = "program"
)

// SearchEngine wraps a bleve full-text search index backed by a GORM database.
type SearchEngine struct {
	index bleve.Index
	db    *gorm.DB
}

// SearchResult represents a single search hit.
type SearchResult struct {
	ID       string  `json:"id"`
	Type     string  `json:"type"`               // file, group, media, channel, program
	Title    string  `json:"title"`
	Subtitle string  `json:"subtitle,omitempty"`
	Thumb    string  `json:"thumb,omitempty"`
	Score    float64 `json:"score"`
	Snippet  string  `json:"snippet,omitempty"`
}

// SearchResults is the envelope returned from a search query.
type SearchResults struct {
	Query   string                     `json:"query"`
	Total   int                        `json:"total"`
	Took    time.Duration              `json:"took"`
	Results []SearchResult             `json:"results"`
	Facets  map[string][]FacetCount    `json:"facets,omitempty"`
}

// FacetCount represents a single facet bucket.
type FacetCount struct {
	Term  string `json:"term"`
	Count int    `json:"count"`
}

// indexDocument is the internal structure stored in the bleve index.
type indexDocument struct {
	Type        string `json:"type"`
	Title       string `json:"title"`
	Subtitle    string `json:"subtitle"`
	Description string `json:"description"`
	Thumb       string `json:"thumb"`
}

// buildIndexMapping creates the custom bleve index mapping with boosted fields.
func buildIndexMapping() mapping.IndexMapping {
	// --- field mappings ---
	titleFieldMapping := bleve.NewTextFieldMapping()
	titleFieldMapping.Analyzer = "standard"
	titleFieldMapping.Store = true
	titleFieldMapping.IncludeTermVectors = true

	subtitleFieldMapping := bleve.NewTextFieldMapping()
	subtitleFieldMapping.Analyzer = "standard"
	subtitleFieldMapping.Store = true
	subtitleFieldMapping.IncludeTermVectors = true

	descriptionFieldMapping := bleve.NewTextFieldMapping()
	descriptionFieldMapping.Analyzer = "standard"
	descriptionFieldMapping.Store = true
	descriptionFieldMapping.IncludeTermVectors = true

	typeFieldMapping := bleve.NewKeywordFieldMapping()
	typeFieldMapping.Store = true

	thumbFieldMapping := bleve.NewKeywordFieldMapping()
	thumbFieldMapping.Store = true
	thumbFieldMapping.Index = false

	// --- document mapping ---
	docMapping := bleve.NewDocumentMapping()
	docMapping.AddFieldMappingsAt("title", titleFieldMapping)
	docMapping.AddFieldMappingsAt("subtitle", subtitleFieldMapping)
	docMapping.AddFieldMappingsAt("description", descriptionFieldMapping)
	docMapping.AddFieldMappingsAt("type", typeFieldMapping)
	docMapping.AddFieldMappingsAt("thumb", thumbFieldMapping)

	// --- index mapping ---
	indexMapping := bleve.NewIndexMapping()
	indexMapping.DefaultMapping = docMapping
	indexMapping.DefaultAnalyzer = "standard"

	return indexMapping
}

// NewSearchEngine creates or opens a bleve index at dataDir/search.bleve and
// returns a ready-to-use SearchEngine.
func NewSearchEngine(db *gorm.DB, dataDir string) (*SearchEngine, error) {
	indexPath := dataDir + "/search.bleve"

	// Try to open an existing index first.
	idx, err := bleve.Open(indexPath)
	if err != nil {
		// Index does not exist yet -- create it.
		logger.Infof("Creating new search index at %s", indexPath)
		idx, err = bleve.New(indexPath, buildIndexMapping())
		if err != nil {
			return nil, fmt.Errorf("failed to create search index: %w", err)
		}
	} else {
		logger.Infof("Opened existing search index at %s", indexPath)
	}

	return &SearchEngine{
		index: idx,
		db:    db,
	}, nil
}

// Close releases the underlying bleve index.
func (se *SearchEngine) Close() error {
	if se.index != nil {
		return se.index.Close()
	}
	return nil
}

// ---------- Indexing helpers ----------

func docID(docType string, id interface{}) string {
	return fmt.Sprintf("%s:%v", docType, id)
}

// IndexDVRFile indexes a DVR file record.
func (se *SearchEngine) IndexDVRFile(file *models.DVRFile) {
	if file == nil {
		return
	}

	// Build a combined description from all relevant text fields.
	descParts := []string{}
	if file.Description != "" {
		descParts = append(descParts, file.Description)
	}
	if file.Summary != "" {
		descParts = append(descParts, file.Summary)
	}
	if file.Genres != "" {
		descParts = append(descParts, file.Genres)
	}
	if file.ChannelName != "" {
		descParts = append(descParts, file.ChannelName)
	}
	if file.Category != "" {
		descParts = append(descParts, file.Category)
	}

	doc := indexDocument{
		Type:        DocTypeFile,
		Title:       file.Title,
		Subtitle:    file.Subtitle,
		Description: strings.Join(descParts, " "),
		Thumb:       file.Thumb,
	}

	if err := se.index.Index(docID(DocTypeFile, file.ID), doc); err != nil {
		logger.Errorf("search: failed to index DVR file %d: %v", file.ID, err)
	}
}

// IndexDVRGroup indexes a DVR group record.
func (se *SearchEngine) IndexDVRGroup(group *models.DVRGroup) {
	if group == nil {
		return
	}

	descParts := []string{}
	if group.Description != "" {
		descParts = append(descParts, group.Description)
	}
	if group.Categories != "" {
		descParts = append(descParts, group.Categories)
	}
	if group.Genres != "" {
		descParts = append(descParts, group.Genres)
	}
	if group.Cast != "" {
		descParts = append(descParts, group.Cast)
	}

	doc := indexDocument{
		Type:        DocTypeGroup,
		Title:       group.Title,
		Description: strings.Join(descParts, " "),
		Thumb:       group.Thumb,
	}

	if err := se.index.Index(docID(DocTypeGroup, group.ID), doc); err != nil {
		logger.Errorf("search: failed to index DVR group %d: %v", group.ID, err)
	}
}

// IndexMediaItem indexes a media item (movie, show, episode, etc.).
func (se *SearchEngine) IndexMediaItem(item *models.MediaItem) {
	if item == nil {
		return
	}

	descParts := []string{}
	if item.Summary != "" {
		descParts = append(descParts, item.Summary)
	}

	// Flatten genres
	for _, g := range item.Genres {
		descParts = append(descParts, g.Tag)
	}

	// Flatten cast
	for _, c := range item.Cast {
		if c.Tag != "" {
			descParts = append(descParts, c.Tag)
		}
		if c.Role != "" {
			descParts = append(descParts, c.Role)
		}
	}

	subtitle := item.Tagline
	if subtitle == "" {
		subtitle = item.OriginalTitle
	}

	doc := indexDocument{
		Type:        DocTypeMedia,
		Title:       item.Title,
		Subtitle:    subtitle,
		Description: strings.Join(descParts, " "),
		Thumb:       item.Thumb,
	}

	if err := se.index.Index(docID(DocTypeMedia, item.ID), doc); err != nil {
		logger.Errorf("search: failed to index media item %d: %v", item.ID, err)
	}
}

// IndexChannel indexes a live TV channel.
func (se *SearchEngine) IndexChannel(ch *models.Channel) {
	if ch == nil {
		return
	}

	descParts := []string{}
	if ch.Group != "" {
		descParts = append(descParts, ch.Group)
	}
	if ch.SourceName != "" {
		descParts = append(descParts, ch.SourceName)
	}

	doc := indexDocument{
		Type:        DocTypeChannel,
		Title:       ch.Name,
		Description: strings.Join(descParts, " "),
		Thumb:       ch.Logo,
	}

	if err := se.index.Index(docID(DocTypeChannel, ch.ID), doc); err != nil {
		logger.Errorf("search: failed to index channel %d: %v", ch.ID, err)
	}
}

// IndexProgram indexes an EPG program.
func (se *SearchEngine) IndexProgram(prog *models.Program) {
	if prog == nil {
		return
	}

	descParts := []string{}
	if prog.Description != "" {
		descParts = append(descParts, prog.Description)
	}
	if prog.Category != "" {
		descParts = append(descParts, prog.Category)
	}
	if prog.Teams != "" {
		descParts = append(descParts, prog.Teams)
	}
	if prog.League != "" {
		descParts = append(descParts, prog.League)
	}

	doc := indexDocument{
		Type:        DocTypeProgram,
		Title:       prog.Title,
		Subtitle:    prog.Subtitle,
		Description: strings.Join(descParts, " "),
		Thumb:       prog.Icon,
	}

	if err := se.index.Index(docID(DocTypeProgram, prog.ID), doc); err != nil {
		logger.Errorf("search: failed to index program %d: %v", prog.ID, err)
	}
}

// RemoveFromIndex removes a single document from the index by type and ID.
func (se *SearchEngine) RemoveFromIndex(docType string, id string) {
	if err := se.index.Delete(docID(docType, id)); err != nil {
		logger.Errorf("search: failed to remove %s:%s from index: %v", docType, id, err)
	}
}

// ---------- Searching ----------

// Search performs a full-text search across the index.
//
// Parameters:
//   - query: the user's search string
//   - types: optional slice of document types to restrict results (e.g. ["file", "media"])
//   - limit: maximum number of results to return (capped at 200)
//   - offset: pagination offset
func (se *SearchEngine) Search(query string, types []string, limit, offset int) (*SearchResults, error) {
	if query == "" {
		return &SearchResults{Query: query, Results: []SearchResult{}}, nil
	}

	// Sanitise limits.
	if limit <= 0 {
		limit = 25
	}
	if limit > 200 {
		limit = 200
	}
	if offset < 0 {
		offset = 0
	}

	// Build the search request.
	// Use a disjunction of match queries across the three text fields with
	// query-time boosting: title (3x), subtitle (2x), description (1x).
	titleQuery := bleve.NewMatchQuery(query)
	titleQuery.SetField("title")
	titleQuery.SetBoost(3.0)

	subtitleQuery := bleve.NewMatchQuery(query)
	subtitleQuery.SetField("subtitle")
	subtitleQuery.SetBoost(2.0)

	descQuery := bleve.NewMatchQuery(query)
	descQuery.SetField("description")
	descQuery.SetBoost(1.0)

	disjunction := bleve.NewDisjunctionQuery(titleQuery, subtitleQuery, descQuery)
	disjunction.SetMin(1)

	var searchQuery bleveQuery.Query

	// If type filters are provided, wrap in a conjunction with a disjunction of
	// term queries on the type field.
	if len(types) > 0 {
		typeQueries := make([]bleveQuery.Query, 0, len(types))
		for _, t := range types {
			tq := bleve.NewTermQuery(t)
			tq.SetField("type")
			typeQueries = append(typeQueries, tq)
		}
		typeDisjunction := bleve.NewDisjunctionQuery(typeQueries...)
		typeDisjunction.SetMin(1)

		conjunction := bleve.NewConjunctionQuery(disjunction, typeDisjunction)
		searchQuery = conjunction
	} else {
		searchQuery = disjunction
	}

	req := bleve.NewSearchRequestOptions(searchQuery, limit, offset, false)
	req.Fields = []string{"type", "title", "subtitle", "description", "thumb"}
	req.Highlight = bleve.NewHighlightWithStyle("html")
	req.Highlight.AddField("title")
	req.Highlight.AddField("subtitle")
	req.Highlight.AddField("description")

	// Add type facet.
	typeFacet := bleve.NewFacetRequest("type", 10)
	req.AddFacet("type", typeFacet)

	res, err := se.index.Search(req)
	if err != nil {
		return nil, fmt.Errorf("search query failed: %w", err)
	}

	results := make([]SearchResult, 0, len(res.Hits))
	for _, hit := range res.Hits {
		sr := SearchResult{
			ID:    hit.ID,
			Score: hit.Score,
		}

		// Extract stored fields.
		if v, ok := hit.Fields["type"].(string); ok {
			sr.Type = v
		}
		if v, ok := hit.Fields["title"].(string); ok {
			sr.Title = v
		}
		if v, ok := hit.Fields["subtitle"].(string); ok {
			sr.Subtitle = v
		}
		if v, ok := hit.Fields["thumb"].(string); ok {
			sr.Thumb = v
		}

		// Use the best highlighted fragment as the snippet.
		if fragments, ok := hit.Fragments["description"]; ok && len(fragments) > 0 {
			sr.Snippet = fragments[0]
		} else if fragments, ok := hit.Fragments["title"]; ok && len(fragments) > 0 {
			sr.Snippet = fragments[0]
		}

		results = append(results, sr)
	}

	// Build facets map.
	facets := make(map[string][]FacetCount)
	if typeFacetResult, ok := res.Facets["type"]; ok {
		counts := make([]FacetCount, 0, len(typeFacetResult.Terms.Terms()))
		for _, term := range typeFacetResult.Terms.Terms() {
			counts = append(counts, FacetCount{
				Term:  term.Term,
				Count: term.Count,
			})
		}
		facets["type"] = counts
	}

	return &SearchResults{
		Query:   query,
		Total:   int(res.Total),
		Took:    res.Took,
		Results: results,
		Facets:  facets,
	}, nil
}

// ---------- Reindexing ----------

// RebuildIndex drops the current index contents and reindexes everything from
// the database. This is a blocking operation that may take a while on large
// databases.
func (se *SearchEngine) RebuildIndex() error {
	start := time.Now()
	logger.Info("search: starting full reindex")

	// We use a batch to amortise index write overhead.
	batch := se.index.NewBatch()
	count := 0
	const batchSize = 500

	flushBatch := func() error {
		if batch.Size() == 0 {
			return nil
		}
		if err := se.index.Batch(batch); err != nil {
			return fmt.Errorf("search: batch index failed: %w", err)
		}
		batch.Reset()
		return nil
	}

	// --- DVR Files ---
	var files []models.DVRFile
	if err := se.db.Where("deleted = ?", false).FindInBatches(&files, batchSize, func(tx *gorm.DB, batchNum int) error {
		for i := range files {
			f := &files[i]
			descParts := []string{}
			if f.Description != "" {
				descParts = append(descParts, f.Description)
			}
			if f.Summary != "" {
				descParts = append(descParts, f.Summary)
			}
			if f.Genres != "" {
				descParts = append(descParts, f.Genres)
			}
			if f.ChannelName != "" {
				descParts = append(descParts, f.ChannelName)
			}
			if f.Category != "" {
				descParts = append(descParts, f.Category)
			}

			doc := indexDocument{
				Type:        DocTypeFile,
				Title:       f.Title,
				Subtitle:    f.Subtitle,
				Description: strings.Join(descParts, " "),
				Thumb:       f.Thumb,
			}
			if err := batch.Index(docID(DocTypeFile, f.ID), doc); err != nil {
				logger.Errorf("search: failed to batch index DVR file %d: %v", f.ID, err)
			}
			count++
		}
		return flushBatch()
	}).Error; err != nil {
		logger.Errorf("search: error reindexing DVR files: %v", err)
	}

	// --- DVR Groups ---
	var groups []models.DVRGroup
	if err := se.db.FindInBatches(&groups, batchSize, func(tx *gorm.DB, batchNum int) error {
		for i := range groups {
			g := &groups[i]
			descParts := []string{}
			if g.Description != "" {
				descParts = append(descParts, g.Description)
			}
			if g.Categories != "" {
				descParts = append(descParts, g.Categories)
			}
			if g.Genres != "" {
				descParts = append(descParts, g.Genres)
			}
			if g.Cast != "" {
				descParts = append(descParts, g.Cast)
			}

			doc := indexDocument{
				Type:        DocTypeGroup,
				Title:       g.Title,
				Description: strings.Join(descParts, " "),
				Thumb:       g.Thumb,
			}
			if err := batch.Index(docID(DocTypeGroup, g.ID), doc); err != nil {
				logger.Errorf("search: failed to batch index DVR group %d: %v", g.ID, err)
			}
			count++
		}
		return flushBatch()
	}).Error; err != nil {
		logger.Errorf("search: error reindexing DVR groups: %v", err)
	}

	// --- Media Items ---
	var items []models.MediaItem
	if err := se.db.Preload("Genres").Preload("Cast").FindInBatches(&items, batchSize, func(tx *gorm.DB, batchNum int) error {
		for i := range items {
			item := &items[i]
			descParts := []string{}
			if item.Summary != "" {
				descParts = append(descParts, item.Summary)
			}
			for _, g := range item.Genres {
				descParts = append(descParts, g.Tag)
			}
			for _, c := range item.Cast {
				if c.Tag != "" {
					descParts = append(descParts, c.Tag)
				}
				if c.Role != "" {
					descParts = append(descParts, c.Role)
				}
			}

			subtitle := item.Tagline
			if subtitle == "" {
				subtitle = item.OriginalTitle
			}

			doc := indexDocument{
				Type:        DocTypeMedia,
				Title:       item.Title,
				Subtitle:    subtitle,
				Description: strings.Join(descParts, " "),
				Thumb:       item.Thumb,
			}
			if err := batch.Index(docID(DocTypeMedia, item.ID), doc); err != nil {
				logger.Errorf("search: failed to batch index media item %d: %v", item.ID, err)
			}
			count++
		}
		return flushBatch()
	}).Error; err != nil {
		logger.Errorf("search: error reindexing media items: %v", err)
	}

	// --- Channels ---
	var channels []models.Channel
	if err := se.db.Where("enabled = ?", true).FindInBatches(&channels, batchSize, func(tx *gorm.DB, batchNum int) error {
		for i := range channels {
			ch := &channels[i]
			descParts := []string{}
			if ch.Group != "" {
				descParts = append(descParts, ch.Group)
			}
			if ch.SourceName != "" {
				descParts = append(descParts, ch.SourceName)
			}

			doc := indexDocument{
				Type:        DocTypeChannel,
				Title:       ch.Name,
				Description: strings.Join(descParts, " "),
				Thumb:       ch.Logo,
			}
			if err := batch.Index(docID(DocTypeChannel, ch.ID), doc); err != nil {
				logger.Errorf("search: failed to batch index channel %d: %v", ch.ID, err)
			}
			count++
		}
		return flushBatch()
	}).Error; err != nil {
		logger.Errorf("search: error reindexing channels: %v", err)
	}

	// --- Programs (only future programs to keep index lean) ---
	now := time.Now()
	var programs []models.Program
	if err := se.db.Where("\"end\" > ?", now).FindInBatches(&programs, batchSize, func(tx *gorm.DB, batchNum int) error {
		for i := range programs {
			p := &programs[i]
			descParts := []string{}
			if p.Description != "" {
				descParts = append(descParts, p.Description)
			}
			if p.Category != "" {
				descParts = append(descParts, p.Category)
			}
			if p.Teams != "" {
				descParts = append(descParts, p.Teams)
			}
			if p.League != "" {
				descParts = append(descParts, p.League)
			}

			doc := indexDocument{
				Type:        DocTypeProgram,
				Title:       p.Title,
				Subtitle:    p.Subtitle,
				Description: strings.Join(descParts, " "),
				Thumb:       p.Icon,
			}
			if err := batch.Index(docID(DocTypeProgram, p.ID), doc); err != nil {
				logger.Errorf("search: failed to batch index program %d: %v", p.ID, err)
			}
			count++
		}
		return flushBatch()
	}).Error; err != nil {
		logger.Errorf("search: error reindexing programs: %v", err)
	}

	// Flush any remaining documents.
	if err := flushBatch(); err != nil {
		logger.Errorf("search: final batch flush failed: %v", err)
	}

	elapsed := time.Since(start)
	logger.Infof("search: reindex complete - %d documents indexed in %s", count, elapsed)

	return nil
}

// ---------- Statistics ----------

// IndexStats returns basic index statistics.
func (se *SearchEngine) IndexStats() map[string]interface{} {
	docCount, _ := se.index.DocCount()

	stats := map[string]interface{}{
		"docCount": docCount,
	}

	// Count documents per type by running zero-result facet queries.
	allQuery := bleve.NewMatchAllQuery()
	req := bleve.NewSearchRequestOptions(allQuery, 0, 0, false)
	typeFacet := bleve.NewFacetRequest("type", 10)
	req.AddFacet("type", typeFacet)

	res, err := se.index.Search(req)
	if err == nil {
		if facetResult, ok := res.Facets["type"]; ok {
			typeCounts := make(map[string]int)
			for _, term := range facetResult.Terms.Terms() {
				typeCounts[term.Term] = term.Count
			}
			stats["typeCounts"] = typeCounts
		}
	}

	return stats
}
