#!/bin/bash
# 민감한 파일 수정 차단 훅 (PreToolUse - Edit|Write)
#
# 차단 대상:
#   - 환경변수: .env, .env.local, .env.production 등
#   - 시크릿: secrets.yaml, secrets.json, credentials.json
#   - 인증서/키: .pem, .key, .p12, .pfx, .jks, .keystore
#   - Claude 설정: settings.local.json (개인 설정 보호)
#
# 사용법: PreToolUse 훅에서 Edit|Write matcher로 등록
# 종료 코드: 0=허용, 2=차단

INPUT=$(cat)

FILE_PATH=$(python3 -c "
import sys, json
data = json.loads(sys.argv[1])
print(data.get('tool_input', {}).get('file_path', ''))
" "$INPUT" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")
FILENAME_LOWER=$(echo "$FILENAME" | tr '[:upper:]' '[:lower:]')

# ── 정확한 파일명 매칭 ──
SENSITIVE_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.staging"
  ".env.development"
  "secrets.yaml"
  "secrets.yml"
  "secrets.json"
  "credentials.json"
  "service-account.json"
  "settings.local.json"
)

for pattern in "${SENSITIVE_FILES[@]}"; do
  if [ "$FILENAME_LOWER" = "$pattern" ]; then
    echo "BLOCK: 민감한 파일 수정 감지: $FILENAME"
    echo "파일 경로: $FILE_PATH"
    echo "이 파일을 수정하려면 훅을 일시적으로 비활성화하세요."
    exit 2
  fi
done

# ── 확장자 매칭 ──
SENSITIVE_EXTENSIONS=(
  ".pem"
  ".key"
  ".p12"
  ".pfx"
  ".jks"
  ".keystore"
)

for ext in "${SENSITIVE_EXTENSIONS[@]}"; do
  if [[ "$FILENAME_LOWER" == *"$ext" ]]; then
    echo "BLOCK: 인증서/키 파일 수정 감지: $FILENAME"
    echo "파일 경로: $FILE_PATH"
    exit 2
  fi
done

# ── 경로 패턴 매칭 ──
FILE_PATH_LOWER=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')
if echo "$FILE_PATH_LOWER" | grep -qE "(^|/)\.ssh/|/private[_-]?keys?/"; then
  echo "BLOCK: SSH/개인키 디렉토리 파일 수정 감지"
  echo "파일 경로: $FILE_PATH"
  exit 2
fi

exit 0
