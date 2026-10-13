package writer

import "testing"

// buildFilename 의 naming 규칙별 결과. date-prefix 가 switch 에 없어
// default(kebab) 로 빠져 날짜가 붙지 않던 일이 있었다(2026-10-14).
func TestBuildFilename(t *testing.T) {
	cases := []struct {
		naming string
		want   string
	}{
		{"kebab", "my-note.md"},
		{"", "my-note.md"},
		{"mixed", "my-note.md"},
		{"date-compact", "20261014-my-note.md"},
		{"date-prefix", "2026-10-14-my-note.md"},
		{"date-done", "2026-10-14-my-note-done.md"},
	}
	for _, c := range cases {
		got := buildFilename(c.naming, "my-note", "2026-10-14")
		if got != c.want {
			t.Errorf("buildFilename(%q) = %q, want %q", c.naming, got, c.want)
		}
	}
}
