---
name: session-start
description: 세션 시작 시 텔레그램 봇 등록, git 동기화, 현황 보고를 수행합니다
user_invocable: true
---

# 세션 시작 절차

아래 단계를 순서대로 실행하세요:

## 1. 텔레그램 봇 세션 등록

```bash
/home/yth1133/workdir/telegram-bot/register-session.sh
```

등록 실패해도 세션은 계속 진행합니다. (텔레그램 봇이 없는 환경일 수 있음)

## 2. Git 동기화

```bash
git -C {{PROJECT_PATH}} pull origin main
git -C {{PROJECT_PATH}} status --porcelain
```

- 충돌이 있으면 사용자에게 알려주세요
- 변경사항이 있으면 간략히 보고하세요
- remote가 설정되지 않았으면 건너뛰세요

## 3. 현황 보고

`{{PROJECT_PATH}}/CLAUDE.md` 파일을 읽고:

1. **진행 상황** 섹션의 현재 상태를 보고
2. **향후 작업** 목록을 보여주기
3. 사용자에게 확인: "오늘 어떤 작업을 진행할까요?"
