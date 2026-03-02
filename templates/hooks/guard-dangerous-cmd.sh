#!/bin/bash
# 위험한 명령어 실행 차단 훅 (PreToolUse - Bash)
#
# 감지 대상:
#   - 파일시스템 파괴: rm -rf /, rm -rf ~, > /dev/sda, mkfs, dd if=
#   - Git 위험 조작: push --force, reset --hard, clean -fd, branch -D main
#   - DB 파괴: DROP DATABASE, DROP TABLE, TRUNCATE TABLE
#   - K8s 위험: kubectl delete namespace
#   - 포크 폭탄 등
#
# 사용법: PreToolUse 훅에서 Bash matcher로 등록
# 종료 코드: 0=허용, 2=차단

INPUT=$(cat)

CMD=$(python3 -c "
import sys, json
data = json.loads(sys.argv[1])
print(data.get('tool_input', {}).get('command', ''))
" "$INPUT" 2>/dev/null)

if [ -z "$CMD" ]; then
  exit 0
fi

CMD_LOWER=$(echo "$CMD" | tr '[:upper:]' '[:lower:]')

# ── 파일시스템 파괴 ──
FILESYSTEM_PATTERNS=(
  "rm -rf /"
  "rm -rf /*"
  "rm -rf ~"
  'rm -rf $home'
  'rm -rf "$home'
  "> /dev/sda"
  "mkfs."
  "dd if="
  ":(){:|:&};:"
)

for pattern in "${FILESYSTEM_PATTERNS[@]}"; do
  if echo "$CMD_LOWER" | grep -qF "$pattern"; then
    echo "BLOCK: 파일시스템 파괴 명령어 감지: $pattern"
    echo "명령어: $CMD"
    exit 2
  fi
done

# ── Git 위험 조작 ──
GIT_PATTERNS=(
  "git push --force"
  "git push -f "
  "git reset --hard"
  "git clean -fd"
  "git clean -f "
  "git checkout -- ."
  "git restore ."
)

for pattern in "${GIT_PATTERNS[@]}"; do
  if echo "$CMD_LOWER" | grep -qF "$pattern"; then
    echo "BLOCK: 위험한 Git 명령어 감지: $pattern"
    echo "명령어: $CMD"
    exit 2
  fi
done

# main/master 브랜치 강제 푸시 추가 검사
if echo "$CMD_LOWER" | grep -qE "git push.*(--force|-f).*(main|master)"; then
  echo "BLOCK: main/master 브랜치에 force push는 금지됩니다"
  echo "명령어: $CMD"
  exit 2
fi

# ── DB 파괴 ──
DB_PATTERNS=(
  "drop database"
  "drop table"
  "truncate table"
)

for pattern in "${DB_PATTERNS[@]}"; do
  if echo "$CMD_LOWER" | grep -qF "$pattern"; then
    echo "BLOCK: DB 파괴 명령어 감지: $pattern"
    echo "명령어: $CMD"
    exit 2
  fi
done

# ── K8s 위험 ──
K8S_PATTERNS=(
  "kubectl delete namespace"
  "kubectl delete ns "
)

for pattern in "${K8S_PATTERNS[@]}"; do
  if echo "$CMD_LOWER" | grep -qF "$pattern"; then
    echo "BLOCK: K8s 위험 명령어 감지: $pattern"
    echo "명령어: $CMD"
    exit 2
  fi
done

exit 0
