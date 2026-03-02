# claude-project-init

Claude Code 프로젝트를 위한 초기 세팅 플러그인. 새 프로젝트를 시작할 때 `.mcp.json`, hooks, skills, agents, `CLAUDE.md` 등을 자동으로 생성합니다.

## 왜 필요한가?

Claude Code는 프로젝트별로 다양한 설정 파일을 사용합니다:

| 파일 | 역할 |
|------|------|
| `CLAUDE.md` | Claude의 프로젝트 메모리 — 매 세션마다 자동 로드 |
| `.mcp.json` | MCP 서버 설정 (Notion, GitHub 등) |
| `.claude/settings.local.json` | 훅, 권한, MCP 활성화 설정 |
| `.claude/hooks/` | 위험 명령어 차단, 민감 파일 보호 등 |
| `.claude/skills/` | 반복 워크플로우 자동화 (세션 시작 등) |
| `.claude/agents/` | 특화 에이전트 정의 (Notion 기록 등) |

매번 수동으로 만드는 건 비효율적이고 빠뜨리기 쉽습니다. 이 플러그인이 검증된 패턴으로 한 번에 세팅해줍니다.

## 설치

원하는 위치에 클론합니다:

```bash
git clone https://github.com/Project-yth/claude-project-init.git
```

## 사용법

```bash
# 경로를 인자로 지정
bash /path/to/claude-project-init/init.sh /path/to/my-project

# 또는 인자 없이 실행하면 경로를 물어봅니다
bash /path/to/claude-project-init/init.sh
```

### 대화형 입력

```
[1/4] 프로젝트 경로 (기본값: /home/user/projects/my-project):
[1/4] 프로젝트 경로: /home/user/projects/my-project
[2/4] 프로젝트명 (기본값: my-project):
[3/4] Notion 작업 DB 사용? (y/N): y
[4/4] GitHub repo (예: org/my-project): org/my-project
설정 확인:
  프로젝트명:  my-project
  경로:        /home/user/projects/my-project
  Notion DB:   y
  Git repo:    org/my-project
  날짜:        2026-03-02

진행할까요? (Y/n):
```

> Notion DB 연결(data_source_id)은 init.sh에서 하지 않습니다. Claude Code 세션에서 Notion MCP로 자동 검색/연결합니다.

## 생성되는 파일

```
my-project/
├── CLAUDE.md                          # 프로젝트 메모리
├── .mcp.json                          # Notion MCP 서버
├── .claude/
│   ├── settings.local.json            # 훅 + 권한 + SessionStart 컨텍스트 주입
│   ├── hooks/
│   │   ├── guard-dangerous-cmd.sh     # 위험 명령어 차단
│   │   └── protect-sensitive-files.sh # 민감 파일 보호
│   ├── skills/
│   │   └── session-start/
│   │       └── SKILL.md               # /session-start 스킬
│   └── agents/
│       └── notion.md                  # Notion 에이전트 (선택)
└── .gitignore                         # settings.local.json 등 제외
```

## 각 구성요소 설명

### CLAUDE.md

Claude Code가 매 세션 시작 시 자동으로 읽는 프로젝트 메모리 파일입니다. 프로젝트 개요, 기술 스택, 세션 절차, 진행 상황 등을 기록합니다. 초기화 후 직접 내용을 채워야 합니다.

**팁**: 300줄 이하로 유지하세요. Claude는 약 150-200개의 지시를 안정적으로 따릅니다.

### Hooks

#### guard-dangerous-cmd.sh (PreToolUse → Bash)

Bash 명령어 실행 전에 위험한 패턴을 검사합니다:
- `rm -rf /`, `rm -rf ~` — 파일시스템 파괴
- `git push --force`, `git reset --hard` — Git 위험 조작
- `DROP DATABASE`, `TRUNCATE TABLE` — DB 파괴
- `kubectl delete namespace` — K8s 위험 조작

감지 시 exit code 2를 반환하여 실행을 차단합니다.

#### protect-sensitive-files.sh (PreToolUse → Edit|Write)

파일 수정 전에 민감한 파일인지 검사합니다:
- `.env`, `.env.local` 등 환경변수 파일
- `secrets.yaml`, `credentials.json` 등 시크릿
- `.pem`, `.key` 등 인증서/키 파일
- `settings.local.json` — 개인 설정 보호
- `.ssh/` 디렉토리 하위 파일

### SessionStart 훅

세션 시작 시 자동으로 프로젝트명, 경로, Git 브랜치, 변경 파일 목록을 Claude 컨텍스트에 주입합니다. 별도 조작 없이 Claude가 현재 상태를 파악할 수 있습니다.

### Skills

#### /session-start

세션 시작 워크플로우를 자동화합니다:
1. 텔레그램 봇 세션 등록 (선택적)
2. `git pull`로 코드 동기화
3. CLAUDE.md 기반 현황 보고
4. 오늘 작업 확인

### Agents

#### notion (선택)

Notion 작업 DB에 기록하고 조회하는 경량 에이전트입니다. Haiku 모델을 사용해 비용을 절약합니다. 초기화 시 Notion DB를 사용한다고 선택하면 생성됩니다.

### .mcp.json

[Notion MCP 서버](https://www.notion.so/help/notion-mcp)를 설정합니다. Claude Code에서 직접 Notion 페이지를 검색, 조회, 생성, 수정할 수 있습니다.

## 초기화 후 할 일

1. **CLAUDE.md 작성** — 프로젝트 개요, 기술 스택, 코딩 컨벤션 채우기
2. **Claude Code 실행** — 프로젝트 디렉토리에서 `claude` 실행
3. **/session-start** — 스킬이 인식되는지 확인
4. **에이전트 추가** (필요시) — `.claude/agents/`에 프로젝트별 에이전트 정의

## 커스터마이징

### 플레이스홀더

템플릿 파일들은 다음 플레이스홀더를 사용합니다:

| 플레이스홀더 | 치환값 |
|-------------|--------|
| `{{PROJECT_PATH}}` | 프로젝트 절대경로 |
| `{{PROJECT_NAME}}` | 프로젝트명 |
| `{{GIT_REPO}}` | GitHub 저장소 (org/repo) |
| `{{DATE}}` | 초기화 실행 날짜 |
| `{{HOME}}` | 사용자 홈 디렉토리 |

### 템플릿 수정

`templates/` 폴더의 파일을 직접 수정하면 이후 초기화에 반영됩니다. 자신의 워크플로우에 맞게 자유롭게 수정하세요.

## 참고

- [Claude Code Docs — Settings](https://code.claude.com/docs/en/settings)
- [Claude Code Docs — Hooks](https://code.claude.com/docs/en/hooks)
- [Claude Code Docs — Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Docs — Subagents](https://code.claude.com/docs/en/sub-agents)
- [Writing a Good CLAUDE.md — HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)

## License

MIT
