package api

import (
	"strings"
	"testing"
)

func TestRewriteM3U8ForProxyPreservesAuthToken(t *testing.T) {
	content := strings.Join([]string{
		"#EXTM3U",
		`#EXT-X-KEY:METHOD=AES-128,URI="/keys/key.bin"`,
		"#EXTINF:4.0,",
		"segment00001.ts",
		"https://cdn.example.com/segment00002.ts",
	}, "\n")

	rewritten := rewriteM3U8ForProxy(
		content,
		"https://provider.example.com/root",
		"https://openflix.example.com/livetv/xtream/proxy",
		"test-token",
	)

	if !strings.Contains(rewritten, "X-Plex-Token=test-token") {
		t.Fatalf("expected rewritten playlist to include auth token, got:\n%s", rewritten)
	}
	if !strings.Contains(rewritten, "url=https%3A%2F%2Fprovider.example.com%2Froot%2Fsegment00001.ts") {
		t.Fatalf("expected relative segment URL to be rewritten, got:\n%s", rewritten)
	}
	if !strings.Contains(rewritten, "url=https%3A%2F%2Fprovider.example.com%2Froot%2Fkeys%2Fkey.bin") {
		t.Fatalf("expected URI attribute to be rewritten, got:\n%s", rewritten)
	}
}
