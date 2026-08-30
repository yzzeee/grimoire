#!/usr/bin/env bash
# SessionStart 훅: 어느 폴더에서 세션을 열든 관련 kb 컨텍스트를 주입한다.
# 1) jump 매핑이 있으면 큐레이션된 프로젝트 컨텍스트(grimoire-context).
# 2) 없으면 폴더명을 키워드로 kb frontmatter(tags/title)를 자동 매칭.
# 매칭이 없으면 아무것도 출력하지 않아 노이즈를 만들지 않는다.
set -euo pipefail

# 경로는 이 스크립트 위치에서 끌어온다. 하드코딩하면 다른 머신에서 조용히 안 돈다.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG="${GRIMOIRE_CONFIG:-$HERE/kb.config.json}"
CTX="${GRIMOIRE_CONTEXT_BIN:-$HERE/bin/grimoire-context}"
KB="${GRIMOIRE_KB:-$HOME/kb}"
CWD="${1:-$PWD}"

[ -x "$CTX" ] || exit 0
[ -d "$KB" ] || exit 0

# 1) jump 매핑 기반 (큐레이션)
if OUT="$("$CTX" "$CFG" "$CWD" 2>/dev/null)" && [ -n "$OUT" ]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# 2) fallback: 폴더명 키워드로 kb 자동 매칭 (frontmatter tags/title 만, 본문 제외해 노이즈 억제)
KW="$(basename "$CWD" | tr '[:upper:]' '[:lower:]')"
# 너무 짧거나 일반적인 이름은 스킵 (go, bin, src 등 오탐 방지)
case "$KW" in
  ""|go|bin|src|tmp|lib|etc|home|docs|test|tests|work|dev) exit 0 ;;
esac
[ "${#KW}" -lt 4 ] && exit 0

HITS="$(grep -rliE "^(title|tags):.*${KW}" \
  "$KB/runbooks" "$KB/analysis" "$KB/troubleshooting" "$KB/guides" "$KB/reference" "$KB/scenarios" "$KB/study" \
  2>/dev/null | head -4 || true)"
[ -z "$HITS" ] && exit 0

echo "## kb 컨텍스트 (폴더명 '${KW}' 자동 매칭)"
echo "관련 kb 문서 후보. 필요하면 \`/kb\` 또는 grimoire \`read_note\`로 확인:"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  title="$(grep -m1 '^title:' "$f" 2>/dev/null | sed "s/^title:[[:space:]]*//; s/^['\"]//; s/['\"]$//")"
  rel="${f#"$KB"/}"
  echo "- \`${rel}\` — ${title}"
done <<< "$HITS"
