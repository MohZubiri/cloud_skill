#!/usr/bin/env bash
# يثبّت مهارة /delegate ووكلاءها الأربعة (scout, planner, builder, verifier) في ~/.claude
# للمستخدم الحالي. آمن لإعادة التشغيل: أي ملف موجود ومختلف يُحفظ منه نسخة .bak أولاً.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

copy() { # copy <relative-src> <absolute-dest>
  local src="$KIT/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    cp -p "$dst" "$dst.bak-$STAMP"
    echo "  (نسخة احتياطية) $dst.bak-$STAMP"
  fi
  cp -p "$src" "$dst"
  echo "  ✓ $dst"
}

echo "التثبيت في: $DEST"
copy skills/delegate/SKILL.md             "$DEST/skills/delegate/SKILL.md"
copy skills/delegate/templates/spec.md    "$DEST/skills/delegate/templates/spec.md"
copy skills/delegate/scripts/codex-run.sh "$DEST/skills/delegate/scripts/codex-run.sh"
chmod +x "$DEST/skills/delegate/scripts/codex-run.sh"
for agent in builder planner scout verifier; do
  copy "agents/$agent.md" "$DEST/agents/$agent.md"
done

echo
echo "فحص المتطلبات:"
if command -v claude >/dev/null 2>&1; then
  echo "  ✓ claude: $(claude --version 2>/dev/null | head -1)"
else
  echo "  • أمر claude ليس على PATH — طبيعي إن كنت تستعمل Claude Code من إضافة VS Code؛ وإلا ثبّت Claude Code أولاً"
fi
# command -v لا يكفي: قد يكون على PATH غلاف يشير إلى ثنائي غير مثبّت، فنتحقق أن --version يعمل فعلاً.
if codex_ver="$(timeout 15 codex --version 2>/dev/null | head -1)" && [ -n "$codex_ver" ]; then
  echo "  ✓ codex: $codex_ver"
  (timeout 15 codex login status 2>&1 || true) | sed 's/^/    /'
else
  echo "  ✗ codex غير جاهز — نفّذ:  npm install -g @openai/codex  ثم  codex login"
fi
command -v git >/dev/null 2>&1 && echo "  ✓ git" || echo "  ✗ git غير موجود"

echo
echo "تم. افتح Claude Code داخل أي مشروع واكتب /delegate لرؤية المهارة."
