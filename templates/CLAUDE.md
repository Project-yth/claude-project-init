# {{PROJECT_NAME}}

## 프로젝트 개요

> TODO: 프로젝트 설명을 작성하세요.

- **생성일**: {{DATE}}
- **경로**: `{{PROJECT_PATH}}`
- **Git**: `{{GIT_REPO}}`

## 기술 스택

> TODO: 사용하는 기술 스택을 정리하세요.

## 세션 시작 절차

1. `/session-start` 스킬 실행
   - 텔레그램 봇 세션 등록
   - `git pull origin main`으로 코드 동기화
   - 진행 상황 보고 및 오늘 작업 확인

## 세션 종료 절차

1. CLAUDE.md "진행 상황" 섹션 업데이트
2. 변경사항 커밋 & 푸시
3. (세션 해제는 전역 훅이 자동 처리)

## Bash 명령어 규칙

- **git**: `git -C {{PROJECT_PATH}} <command>`
- **uv**: `uv --directory {{PROJECT_PATH}} <command>`
- **docker**: `docker build -f {{PROJECT_PATH}}/Dockerfile {{PROJECT_PATH}}/`

## 코딩 컨벤션

> TODO: 프로젝트에 맞는 컨벤션을 정리하세요.
> 예시:
> - 변수/함수명: snake_case
> - 주석/문서: 한국어
> - 코드: 영어

## 진행 상황

> 현재 진행 중인 작업을 기록하세요.

## 향후 작업

> 계획된 작업을 나열하세요.
