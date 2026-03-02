#!/bin/bash
# claude-project-init: Claude Code 프로젝트 초기 세팅 플러그인
# 사용법: bash init.sh [프로젝트경로]

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Claude Code 프로젝트 초기화 플러그인   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ──────────────────────────────────────────
# 1. 프로젝트 경로
# ──────────────────────────────────────────
if [ -n "${1:-}" ]; then
  PROJECT_PATH="$(cd "$1" && pwd)"
else
  # 인자 없으면 직접 입력받기 (pwd 자동 감지 안함 — 플러그인 디렉토리에서 실행할 수 있으므로)
  read -rp "$(echo -e "${BLUE}[1/5]${NC} 프로젝트 경로를 입력하세요: ")" INPUT_PATH
  if [ -z "$INPUT_PATH" ]; then
    echo -e "${RED}오류: 프로젝트 경로를 입력해야 합니다.${NC}"
    exit 1
  fi
  # ~ 확장 처리
  INPUT_PATH="${INPUT_PATH/#\~/$HOME}"
  PROJECT_PATH="$(cd "$INPUT_PATH" && pwd)"
fi

echo -e "${BLUE}[1/5]${NC} 프로젝트 경로: ${GREEN}$PROJECT_PATH${NC}"

if [ ! -d "$PROJECT_PATH" ]; then
  echo -e "${RED}오류: 디렉토리가 존재하지 않습니다: $PROJECT_PATH${NC}"
  exit 1
fi

# 플러그인 자체 디렉토리에 설치하려는 건 아닌지 확인
if [ "$PROJECT_PATH" = "$SCRIPT_DIR" ]; then
  echo -e "${RED}오류: 플러그인 자체 디렉토리에는 초기화할 수 없습니다.${NC}"
  echo -e "${YELLOW}대상 프로젝트 경로를 인자로 지정하세요: bash init.sh /path/to/project${NC}"
  exit 1
fi

# ──────────────────────────────────────────
# 2. 프로젝트명
# ──────────────────────────────────────────
DEFAULT_NAME="$(basename "$PROJECT_PATH")"
read -rp "$(echo -e "${BLUE}[2/5]${NC} 프로젝트명 (기본값: ${GREEN}$DEFAULT_NAME${NC}): ")" PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"

# ──────────────────────────────────────────
# 3. Notion DB 설정
# ──────────────────────────────────────────
read -rp "$(echo -e "${BLUE}[3/5]${NC} Notion 작업 DB 사용? (y/N): ")" USE_NOTION
USE_NOTION="${USE_NOTION,,}" # lowercase

NOTION_DATA_SOURCE_ID=""
if [[ "$USE_NOTION" == "y" || "$USE_NOTION" == "yes" ]]; then
  read -rp "$(echo -e "      Notion data_source_id: ")" NOTION_DATA_SOURCE_ID
  if [ -z "$NOTION_DATA_SOURCE_ID" ]; then
    echo -e "${YELLOW}경고: data_source_id가 비어있어 Notion 에이전트를 건너뜁니다.${NC}"
    USE_NOTION="n"
  fi
fi

# ──────────────────────────────────────────
# 4. Git repo 설정
# ──────────────────────────────────────────
read -rp "$(echo -e "${BLUE}[4/5]${NC} GitHub repo (예: org/my-project, 빈값=건너뜀): ")" GIT_REPO

# ──────────────────────────────────────────
# 5. 날짜
# ──────────────────────────────────────────
DATE="$(date +%Y-%m-%d)"

echo ""
echo -e "${BLUE}[5/5]${NC} 설정 확인:"
echo -e "  프로젝트명:  ${GREEN}$PROJECT_NAME${NC}"
echo -e "  경로:        ${GREEN}$PROJECT_PATH${NC}"
echo -e "  Notion DB:   ${GREEN}${USE_NOTION}${NC} ${NOTION_DATA_SOURCE_ID:+(${NOTION_DATA_SOURCE_ID})}"
echo -e "  Git repo:    ${GREEN}${GIT_REPO:-없음}${NC}"
echo -e "  날짜:        ${GREEN}$DATE${NC}"
echo ""
read -rp "$(echo -e "진행할까요? (Y/n): ")" CONFIRM
CONFIRM="${CONFIRM,,}"
if [[ "$CONFIRM" == "n" || "$CONFIRM" == "no" ]]; then
  echo -e "${YELLOW}취소되었습니다.${NC}"
  exit 0
fi

# ──────────────────────────────────────────
# 플레이스홀더 치환 함수
# ──────────────────────────────────────────
substitute() {
  local content="$1"
  content="${content//\{\{PROJECT_PATH\}\}/$PROJECT_PATH}"
  content="${content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
  content="${content//\{\{NOTION_DATA_SOURCE_ID\}\}/$NOTION_DATA_SOURCE_ID}"
  content="${content//\{\{GIT_REPO\}\}/$GIT_REPO}"
  content="${content//\{\{DATE\}\}/$DATE}"
  content="${content//\{\{HOME\}\}/$HOME}"
  echo "$content"
}

# 파일 복사 + 치환 함수
copy_template() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    echo -e "${YELLOW}  이미 존재: $(basename "$dest")${NC}"
    read -rp "  덮어쓸까요? (y/N): " overwrite
    overwrite="${overwrite,,}"
    if [[ "$overwrite" != "y" && "$overwrite" != "yes" ]]; then
      echo -e "  → 건너뜀"
      return
    fi
  fi

  mkdir -p "$(dirname "$dest")"
  local content
  content="$(cat "$src")"
  content="$(substitute "$content")"
  echo "$content" > "$dest"
  echo -e "${GREEN}  ✓ 생성: ${dest#$PROJECT_PATH/}${NC}"
}

echo ""
echo -e "${CYAN}파일 생성 중...${NC}"

# ──────────────────────────────────────────
# .mcp.json
# ──────────────────────────────────────────
copy_template "$TEMPLATE_DIR/mcp.json" "$PROJECT_PATH/.mcp.json"

# ──────────────────────────────────────────
# .claude/ 디렉토리
# ──────────────────────────────────────────
mkdir -p "$PROJECT_PATH/.claude"/{hooks,skills/session-start,agents}

# settings.local.json
copy_template "$TEMPLATE_DIR/settings.local.json" "$PROJECT_PATH/.claude/settings.local.json"

# hooks
copy_template "$TEMPLATE_DIR/hooks/guard-dangerous-cmd.sh" "$PROJECT_PATH/.claude/hooks/guard-dangerous-cmd.sh"
chmod +x "$PROJECT_PATH/.claude/hooks/guard-dangerous-cmd.sh"

copy_template "$TEMPLATE_DIR/hooks/protect-sensitive-files.sh" "$PROJECT_PATH/.claude/hooks/protect-sensitive-files.sh"
chmod +x "$PROJECT_PATH/.claude/hooks/protect-sensitive-files.sh"

# skills
copy_template "$TEMPLATE_DIR/skills/session-start/SKILL.md" "$PROJECT_PATH/.claude/skills/session-start/SKILL.md"

# agents (Notion은 조건부)
if [[ "$USE_NOTION" == "y" || "$USE_NOTION" == "yes" ]]; then
  copy_template "$TEMPLATE_DIR/agents/notion.md" "$PROJECT_PATH/.claude/agents/notion.md"
fi

# ──────────────────────────────────────────
# CLAUDE.md
# ──────────────────────────────────────────
copy_template "$TEMPLATE_DIR/CLAUDE.md" "$PROJECT_PATH/CLAUDE.md"

# Notion 미사용 시 CLAUDE.md에서 Notion 관련 내용 제거 (해당 없음 - 현재 템플릿엔 Notion 섹션 없음)

# ──────────────────────────────────────────
# .gitignore 업데이트
# ──────────────────────────────────────────
GITIGNORE_ENTRIES=(
  ".claude/settings.local.json"
  ".claude/agent-memory-local/"
)

if [ -f "$PROJECT_PATH/.gitignore" ]; then
  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if ! grep -qF "$entry" "$PROJECT_PATH/.gitignore"; then
      echo "$entry" >> "$PROJECT_PATH/.gitignore"
      echo -e "${GREEN}  ✓ .gitignore에 추가: $entry${NC}"
    fi
  done
else
  printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > "$PROJECT_PATH/.gitignore"
  echo -e "${GREEN}  ✓ 생성: .gitignore${NC}"
fi

# ──────────────────────────────────────────
# 완료
# ──────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            초기화 완료!                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "생성된 파일:"
echo -e "  ${GREEN}.mcp.json${NC}                          — MCP 서버 설정"
echo -e "  ${GREEN}.claude/settings.local.json${NC}        — 훅 + 권한 설정"
echo -e "  ${GREEN}.claude/hooks/guard-dangerous-cmd.sh${NC}    — 위험 명령어 차단"
echo -e "  ${GREEN}.claude/hooks/protect-sensitive-files.sh${NC} — 민감 파일 보호"
echo -e "  ${GREEN}.claude/skills/session-start/SKILL.md${NC}   — 세션 시작 스킬"
if [[ "$USE_NOTION" == "y" || "$USE_NOTION" == "yes" ]]; then
  echo -e "  ${GREEN}.claude/agents/notion.md${NC}             — Notion 에이전트"
fi
echo -e "  ${GREEN}CLAUDE.md${NC}                             — 프로젝트 메모리"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. CLAUDE.md를 열어 프로젝트 개요와 기술 스택을 채우세요"
echo -e "  2. Claude Code를 실행하고 /session-start로 시작하세요"
echo -e "  3. 필요에 따라 .claude/agents/에 커스텀 에이전트를 추가하세요"
