package instant

import "testing"

func TestBuildCachedStreamURLIncludesToken(t *testing.T) {
	got := buildCachedStreamURL("tvguide-123", "abc123")
	want := "/api/instant/stream/tvguide-123?X-Plex-Token=abc123"
	if got != want {
		t.Fatalf("unexpected stream url: got %q want %q", got, want)
	}
}

func TestBuildCachedStreamURLWithoutToken(t *testing.T) {
	got := buildCachedStreamURL("hdhr-8BB2D956-25", "")
	want := "/api/instant/stream/hdhr-8BB2D956-25"
	if got != want {
		t.Fatalf("unexpected stream url without token: got %q want %q", got, want)
	}
}
