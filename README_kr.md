# csync

[English](README.md) · **한국어**

각 프로젝트 안에 Claude 를 위한 **지속적이고 버전 관리되는 작업 공간**을 만들어 주는
Claude Code 스킬. 원한다면 그 작업 공간과 Claude 의 글로벌 설정을 여러 머신에 걸쳐
동기화한다.

사용자 소유의 private git 저장소 하나에 두 가지가 들어간다:

1. **Claude 의 글로벌 상태** — `~/.claude/CLAUDE.md` 와 Claude 가 기록하는 프로젝트별
   메모리 디렉토리
2. **각 프로젝트 안의 작업 공간 디렉토리** (기본 `.csync/`) — 계획, 결정, 함정, 조사
   결과. 작업에는 속하지만 프로젝트 repo 에는 속하지 않는 것들

설치하고 `/csync` 를 치면 나머지는 안내를 따라가면 된다.

## 목차

- [두 가지 사용법](#두-가지-사용법)
- [사전 요구사항](#사전-요구사항) — [Windows](#windows)
- [설치](#설치)
- [무엇이 어디에 놓이는가](#무엇이-어디에-놓이는가)
- [CLAUDE.md 파일들, 어느 것이 어느 것인지](#claudemd-파일들-어느-것이-어느-것인지)
- [메모리 디렉토리](#메모리-디렉토리)
- [작업 공간](#작업-공간)
- [일상 사용](#일상-사용)
- [두 번째 머신 추가](#두-번째-머신-추가)
- [로컬 전용에서 원격으로](#로컬-전용에서-원격으로)
- [무엇이 push 되는가](#무엇이-push-되는가)
- [업데이트와 제거](#업데이트와-제거)
- [뭔가 잘못돼 보일 때](#뭔가-잘못돼-보일-때)
- [어떻게 구성되어 있나](#어떻게-구성되어-있나)

## 두 가지 사용법

**머신 한 대, 원격 없음.** 세션이 바뀔 때마다 Claude 가 맥락을 잃는 것을 멈추고 싶은
경우다 — 다음 한 걸음이 명시된 살아 있는 계획, 뒤집으면 안 되는 결정의 짧은 목록,
이미 밟아 본 함정의 기록. csync 는 사용자 디스크에 bare git 저장소를 만들어 원격
역할을 시키므로, 아무것도 머신을 떠나지 않고 계정도 필요 없으면서 전체 히스토리와
동일한 워크플로를 얻는다. **문서 규율이 핵심이고 동기화는 선택이다.**

**머신 두 대 이상.** 위의 모든 것에 더해, 글로벌 `CLAUDE.md`·프로젝트별 메모리·모든
프로젝트 작업 공간이 세션 시작 시 fast-forward 되고 작업을 마칠 때 push 된다.

로컬 전용으로 시작해서 나중에 원격을 붙여도 된다 — `/csync remote <url>` 이 그
이전을 처리한다.

## 사전 요구사항

| | | |
|---|---|---|
| **Claude Code** | 스킬을 지원하는 버전 | 스킬은 `~/.claude/skills/` 에 놓인다 |
| **git** | 2.x | 로컬 전용 모드의 `git init --bare` 를 포함한 모든 동작에 필요 |
| **bash** | 3.2 이상 | macOS 기본이 3.2 이고, 스크립트는 그 하한에 맞춰 작성했다 |
| **OS** | macOS 또는 Linux | 현재로서는 Windows 미지원 — [Windows](#windows) 참조 |
| **python3 또는 jq** | 선택 | 설치·제거 시 `~/.claude/settings.json` 편집에만 쓴다. 둘 다 없으면 붙여 넣을 JSON 을 출력한다 |

다중 머신 설정에는 추가로 필요하다:

- **사용자 소유의 git 저장소, 그리고 private 여야 한다.** 비어 있어도 된다 — csync 가
  뼈대를 만든다. [무엇이 push 되는가](#무엇이-push-되는가) 참조
- **그 저장소에 대한 인증이 동작할 것.** 시작 전에 셸에서 `git ls-remote <url>` 이
  성공해야 한다. csync 가 이것부터 확인하고 실패하면 중단한다

선택: 저장소의 `bin/` 에 CLI 래퍼를 둘 계획이라면 `~/.local/bin` 을 `PATH` 에 넣는다.

### Windows

현재는 미지원이지만, 막히는 지점이 좁아서 밝혀 둘 가치가 있다 — **심볼릭 링크에
의존하는 것은 설치 단계뿐이다.** `install.sh` 와 `uninstall.sh` 가 링크를 만들고
검사하며, 일상적으로 도는 `pull`·`push`·`sync` 에는 **심볼릭 링크 코드가 전혀 없고**
git 을 호출하는 것이 전부다. 머신 하나를 연결해 두면 그 뒤는 이미 이식성이 있다.

**WSL 이 가장 저항이 적은 길이다** — csync 쪽을 고칠 것이 없다. 단 조건이 하나 붙는다:
**Claude Code 자체가 WSL 안에서 돌아야** 의미가 있다. Windows 쪽 Claude Code 는
`%USERPROFILE%\.claude` 를 읽는데, 그것은 WSL 설치가 연결하는 `~/.claude` 가 아니므로
둘은 만나지 않는다. 동작할 것으로 보지만 검증하지는 않았다. `install.sh --dry-run` 은
아무것도 건드리지 않고 계획 전체를 출력하므로 확인 비용은 낮다.

**Git Bash 는 두 가지가 확인되지 않았다.** Windows 10 이상은 개발자 모드에서 권한 없이
심볼릭 링크를 만들 수 있고 Git for Windows 에도 `core.symlinks` 설정이 있다. 다만
그 환경의 `ln -s` 가 MSYS 의 복사 대체가 아니라 실제 링크를 만드는지, 그리고 Windows
에서 Claude Code 가 SessionStart hook 을 어떤 셸로 실행하는지 — 둘 다 모른다.
스크립트가 부르는 나머지 명령(`git`, `readlink`, `sed`, `grep`, `find`, `dirname`)은
Git Bash 가 제공하는 범위 안에 있고, `python3` 와 `jq` 는 어느 쪽이든 선택이다.

둘 중 어느 환경이든 시도해 본 결과를 알려주면 반영한다. 특히 WSL 은 한 사람만 해 보면
위의 "검증하지 않았다" 를 지울 수 있다.

**포팅 자체가 필요하다면 fork 하는 편이 낫다.** pull request 보다 이쪽이 정직한 정리다 —
변경이 Windows 전용이고, 여기에는 그것을 계속 살려 둘 Windows 사용자가 없다. 손댈 면은
좁고 이미 특정되어 있다: `install.sh` 와 `uninstall.sh` 의 심볼릭 링크 생성·검사, 그리고
`~/.claude` 를 전제하는 지점들. fork 를 `~/.claude/skills/csync` 로 clone 하면 그 뒤는
전부 그쪽을 따른다. `/csync update` 도 마찬가지다 — 그 위치의 clone 에서
`git pull --ff-only` 를 할 뿐이기 때문이다. 이후 수정을 받아 오고 싶으면 이 저장소를
두 번째 remote 로 추가한다. MIT 이므로 따로 허락을 구할 것은 없다.

```bash
git clone https://github.com/you/csync.git ~/.claude/skills/csync
git -C ~/.claude/skills/csync remote add upstream https://github.com/redzefyr/csync.git
```

## 설치

시작하기 전에 **빈 private git 저장소**를 하나 만들어 둔다. csync 가 뼈대를 만들어
주므로 안은 비어 있어도 되지만, setup 이 URL 을 묻기 때문에 저장소 자체는 있어야 한다.
머신 한 대에서만 쓸 거라면 이 준비는 건너뛰어도 된다 — setup 에서 **로컬 전용**을
고르면 자기 디스크의 bare 저장소가 원격 역할을 하고, 아무것도 머신을 떠나지 않으며
어디에도 계정이 필요 없다.

```bash
git clone https://github.com/redzefyr/csync.git ~/.claude/skills/csync
```

이 경로는 임의가 아니다. Claude Code 는 `~/.claude/skills` 아래에서만 스킬을 찾고,
`/csync` 를 명령으로 만드는 것은 그 링크 하나뿐이다. 나머지는 이 경로에 의존하지
않으므로 — 스크립트는 전부 포인터를 통해 해석한다 — clone 은 저장소를 모아두는 곳
어디에 둬도 되고, 거기서 링크만 걸려 있으면 된다. 첫 설치에서는 링크를 직접 만든다.
아직 그 일을 시킬 `/csync` 가 없기 때문이다:

```bash
git clone https://github.com/redzefyr/csync.git ~/dev/csync
ln -s ~/dev/csync ~/.claude/skills/csync
```

그 뒤로는 `install.sh` 가 이 링크를 관리한다 — clone 이 옮겨지면 다시 걸고, 제거할
때 함께 지운다.

그다음 Claude Code 에서:

```
/csync
```

아직 아무것도 설정되지 않았다면 `setup` 이 실행된다. 두 가지를 묻고 — sync 저장소를
어디에 둘지(기본 `~/.csync`), 원격이 있는지 — **바꾸기 전에 무엇을 바꿀지 정확히
보여준다.**

설치 스크립트의 첫 실행은 dry run 이다. 출력되는 계획에서 `ADOPT` 는 사용자의 실제
파일이 git 저장소로 **이동**한다는 뜻이고, `BACKUP` 은 실제 파일이 `.bak` 으로
**이름이 바뀐다**는 뜻이다. 승인하기 전에는 아무 일도 일어나지 않는다.

setup 이 끝나면 프로젝트를 연결한다:

```bash
cd ~/dev/my-project
/csync init
```

## 무엇이 어디에 놓이는가

```
~/.claude/
├── skills/csync/              이 스킬 (이 저장소의 clone, 또는 그 clone 으로의 링크)
├── csync-tool   -> ~/.claude/skills/csync      포인터, 머신 로컬
├── csync-repo   -> ~/.csync                    포인터, 머신 로컬
├── csync-projects                              연결된 프로젝트 레지스트리
├── CLAUDE.md    -> ~/.csync/global/CLAUDE.md   심볼릭 링크
├── settings.json                               SessionStart hook 하나가 추가된다
└── projects/<key>/memory -> ~/.csync/global/memory/<key>   심볼릭 링크

~/.csync/                      sync 저장소, `main` 브랜치
├── csync.conf                 모든 머신이 공유하는 설정
├── global/CLAUDE.md           ~/.claude/CLAUDE.md 의 실체
├── global/memory/<project>/   프로젝트별 메모리 디렉토리의 실체
└── bin/                       CLI 래퍼, ~/.local/bin 으로 링크된다

~/.csync.git/                  로컬 전용 모드: 원격 역할을 하는 bare 저장소

~/dev/my-project/.csync/       작업 공간, `prj/my-project` 브랜치
├── CLAUDE.md
├── GRAPH.md
├── plans/  notes/  docs/
```

심볼릭 링크 두 개 — `csync-tool` 과 `csync-repo` — 가 머신 로컬 설정의 전부다. 둘 중
어느 clone 을 옮기든 `install.sh` 를 다시 돌리면 hook 경로까지 포함해 전부 다시
연결된다.

`~/.claude/settings.json` 자체는 **동기화하지 않는다.** 머신 로컬 권한과 경로가 섞여
있고, csync 는 여기에 자신의 hook 만 추가한다.

## CLAUDE.md 파일들, 어느 것이 어느 것인지

최대 세 개가 생기고, 서로 대체할 수 없다.

| 파일 | 적용 범위 | 누구를 위한 것인가 | csync 동기화 |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | 이 머신의 모든 세션 | **사용자** — 상시 적용되는 개인 선호 | **예**, `global/CLAUDE.md` 로의 심볼릭 링크 |
| `<project>/CLAUDE.md` | 그 프로젝트 | **팀** — 프로젝트 repo 에 체크인된다 | 아니오. 프로젝트의 것이다 |
| `<project>/.csync/CLAUDE.md` | 그 프로젝트 | **Claude** — 이 작업 공간에서 일하는 방법 | **예**, `prj/<name>` 브랜치에 |

**`~/.claude/CLAUDE.md` — 사용자의 규칙.** Claude 가 어떻게 말하기를 원하는지, 무엇을
하기 전에 물어야 하는지, 커밋 메시지를 어떻게 쓰기를 원하는지. 머신을 따라 이동한다.
csync 가 자기 규칙 한 줄을 넣는 곳이기도 하다(아래 참조).

**`<project>/CLAUDE.md` — 프로젝트의 규칙.** 빌드 명령, 관례, 팀원도 의존하는 아키텍처.
csync 는 여기를 의도적으로 건드리지 않는다 — 프로젝트가 버전 관리하고, 프로젝트가
리뷰하며, csync 를 쓰지 않는 사람들과 공유되는 파일이다.

**`<project>/.csync/CLAUDE.md` — 작업 공간 자신의 규칙.** 프로젝트 한 줄 설명, 계획과
노트의 위치, 그리고 이 프로젝트에 대해 머신마다 다른 사항(예: 어떤 language server 가
설치되어 있는지). `/csync init` 이 템플릿에서 만든다.

알아 둘 함정 하나: **`.csync/CLAUDE.md` 는 세션 시작 시 자동으로 로드되지 않는다.**
Claude Code 가 알지 못하는 디렉토리 안을 들여다볼 이유가 없기 때문이다. 이것을
확실히 읽히게 만드는 것은 `setup` 이 글로벌 `CLAUDE.md` 에 추가하겠다고 제안하는
짧은 규칙이다:

> 프로젝트 루트에 `.csync/` 디렉토리가 있으면, 본격적인 작업을 시작하기 전에
> `.csync/CLAUDE.md` 와 `.csync/GRAPH.md` 를 읽고 그 지침을 따른다.

이 규칙을 거절하면 `init` 은 여전히 작업 공간을 만들지만 **어떤 세션도 그것을 열지
않는다.** 전문은 [`templates/repo/global-rules.md`](templates/repo/global-rules.md) 에
있다.

## 메모리 디렉토리

Claude Code 는 프로젝트별 메모리 — 사용자와 프로젝트, 내려진 결정에 대해 스스로
기록하는 짧은 파일들 — 를 `~/.claude/projects/` 아래에 둔다. 프로젝트마다 디렉토리
하나를 갖고, 이름은 프로젝트의 절대 경로에서 `/` 와 `.` 를 `-` 로 바꾼 것이다:

```
~/dev/acme-api   ->   ~/.claude/projects/-Users-ann-dev-acme-api/memory/
```

그 안에는 색인 하나와 사실 하나당 파일 하나가 있다:

```
memory/
├── MEMORY.md                     색인, 메모리 하나당 한 줄
├── deploy-needs-jdk21.md
└── review-before-force-push.md
```

각 파일은 어떤 종류의 메모리인지(`user`, `feedback`, `project`, `reference`)와 관련성
판단에 쓰이는 한 줄 설명을 frontmatter 로 갖는다. 매 세션 로드되는 것은 `MEMORY.md`
이고, 개별 파일은 필요할 때 끌어온다.

csync 는 그 `memory` 디렉토리를 sync 저장소로 향하는 심볼릭 링크로 교체한다:

```
~/.claude/projects/-Users-ann-dev-acme-api/memory  ->  ~/.csync/global/memory/dev-acme-api/
```

저장소 쪽 이름을 보라 — `-Users-ann-dev-acme-api` 가 아니라 **홈 디렉토리 기준으로
키를 만든 `dev-acme-api`** 다. 로컬 이름에는 사용자명이 박혀 있어서, 계정 이름이 다른
두 머신에서 같은 프로젝트가 서로 다른 디렉토리로 해석된다. `$HOME` 기준으로 키를
만들면 **두 머신의 사용자명이 달라도 되고**, 프로젝트가 홈 *아래* 같은 경로에 있기만
하면 된다.

홈 밖의 프로젝트는 전체 변환 키를 그대로 쓰므로, 그런 경우에는 두 머신의 절대 경로가
같아야 한다.

메모리 디렉토리 하나하나가 개별 심볼릭 링크이기 때문에, **두 번째 머신에서 프로젝트를
연결하면 설치 스크립트를 다시 돌려야 한다** — 그 개별 링크를 만드는 것이 `install.sh`
다. `/csync init` 이 이를 알리고 실행하지만, 건너뛰면 Claude 는 동기화되지 않는 로컬
디렉토리에 메모리를 쓰고 머신을 바꿀 때 그것은 사라진다.

## 작업 공간

`/csync init` 이 프로젝트 안에 만드는 구조:

```
.csync/
├── CLAUDE.md          이 작업 공간에서 일하는 방법
├── GRAPH.md           진입점: 살아 있는 파이프라인, 다음 한 걸음, 백로그, 닫힌 작업
├── plans/             파이프라인 하나 = 파일 하나, YYYYMMDD-YYYYMMDD-<slug>.md
├── notes/
│   ├── decisions.md   뒤집으면 안 되는 것과 그 이유
│   └── traps.md       밟기 쉬운 것
└── docs/
    ├── design/        live — 설계만, 코드가 바뀌면 함께 개정한다
    └── archive/       그날의 판단, 쓰인 그대로 둔다
```

이 형태 자체가 핵심이다. 각 디렉토리는 **수명이 다르다**: 계획은 닫히면 삭제되고,
노트는 영구적이지만 의도적으로 상한이 있으며, 설계 문서는 영구적이되 개정되고,
archive 는 영구적이되 개정되지 않는다. 섞어 두면 무엇을 판단하든 전부 읽어야 하고,
그 상태가 오래되면 아무도 아무것도 읽지 않게 된다. 수명이 경로에 적혀 있으므로
외우지 않아도 된다.

`GRAPH.md` 는 세션이 가장 먼저 읽는 파일이다. 어떤 파이프라인이 살아 있고, 각각의
다음 한 걸음이 무엇이며, 닫힌 것들이 어디로 갔는지를 말한다.

규칙 — 한 세션이 다른 파이프라인의 우선순위를 대신 정하지 않으면서 발견 사항을
넘기는 방법을 포함해 — 은
[`references/workspace.md`](references/workspace.md) 에 있다. Claude 가 필요할 때
읽으므로 사용자가 읽을 필요는 없다.

`.csync/` 는 **글로벌** git excludes 파일에 등록되므로, 프로젝트 repo 에서 untracked
로 뜨지 않고 프로젝트 `.gitignore` 가 이를 언급할 필요도 없다.

## 일상 사용

| 명령 | 하는 일 |
|---|---|
| `/csync` | 상태에 따라 분기: 미설치면 `setup`, 미연결 프로젝트면 `init`, 그 외에는 `sync` |
| `/csync init [name]` | 현재 프로젝트 연결 — `prj/<name>` 브랜치에 `.csync/` 생성 |
| `/csync sync` | 전체 pull 후 커밋·push |
| `/csync list` | 열려 있는 파이프라인을 표로 — 상태와 대기 중인 findings |
| `/csync open [slug]` | 이 세션이 그 파이프라인을 맡는다 — findings 를 접어 넣고 세션 제목을 바꾼다 |
| `/csync status` | sync 저장소와 이 세션의 작업 공간들에 대한 git status |
| `/csync config [key] [value]` | `csync.conf` 을 읽거나 바꿈 — 작업 공간 디렉토리명, 자동 제목 |
| `/csync pull` / `push` | 한 방향만 |
| `/csync cleanup` | 새 세션이 신뢰할 수 있도록 이 프로젝트의 작업 공간을 정리 |
| `/csync remote [url]` | 로컬 전용 설정에 실제 원격을 붙인다 |
| `/csync update` | 스킬 자신을 갱신하고 무엇이 바뀌었는지 알린다 |
| `/csync uninstall` | 이 머신의 연결을 해제하고 실제 파일을 남긴다 |

실제로는 이 중 어느 것도 직접 칠 일이 드물다. 세션이 열릴 때 SessionStart hook 이
전부 fast-forward 하고, Claude 가 노트를 쓴 뒤나 작업을 마무리할 때 알아서 `sync` 를
돌린 다음 **한 줄로만 보고한다** — 배관 작업이기 때문이다.

`cleanup` 은 예외다. 문서를 삭제하고 판단을 내리므로 **이름을 지목해 요청할 때만**
실행된다.

`list` 는 반대쪽 예외다. 요청하지 않아도 나타나지만, **그 프로젝트에서 아직
파이프라인을 열지 않은 세션이 `sync` 를 돌릴 때만** 그렇다. 세션 초입이나 무관한
작업을 마친 뒤의 sync 는 무엇이 기다리는지 알려주며 끝나고, 이미 한 파이프라인에
들어가 있는 세션은 건드리지 않는다는 뜻이다. 각 행이 plan 하나다 — 상태 줄과, 다른
세션이 넘겨 둔 findings 가 몇 건인지. **상태는 그 일을 한 세션이 적은 문장을 그대로
인용한다** — csync 는 한 줄로 자를 뿐 고쳐 쓰지 않는다. 일하지 않은 사람이 고쳐 쓴
상태도 읽는 쪽에는 똑같이 사실로 보이기 때문이다.

## 두 번째 머신 추가

```bash
git clone https://github.com/redzefyr/csync.git ~/.claude/skills/csync
```

그다음 Claude Code 에서 이 순서로:

1. `/csync` → **existing repo** 를 고르고 같은 원격 URL 을 준다
2. 연결할 프로젝트마다 `/csync init`
3. **설치 스크립트를 한 번 더 실행** — `~/.claude/skills/csync/scripts/install.sh`

3번이 사람들이 건너뛰는 단계다. 방금 연결한 프로젝트들의 개별 메모리 심볼릭 링크를
만드는 것이 이 단계다.

## 로컬 전용에서 원격으로

빈 **private** 저장소를 만든 뒤:

```
/csync remote git@github.com:you/your-sync-repo.git
```

로컬 bare 저장소를 통째로(모든 브랜치, `main` 과 모든 `prj/*`) 새 원격으로 mirror 하고
각 clone 의 원격을 다시 가리킨다. 먼저 확인을 구한다 — 사용자의 글로벌 지침과 메모리가
머신을 떠나는 순간이기 때문이다.

## 무엇이 push 되는가

`global/` 아래의 모든 것이 원격으로 그대로 올라간다:

- **`global/CLAUDE.md`** — Claude 에게 주는 상시 지침
- **`global/memory/**`** — Claude 가 각 프로젝트에 대해 기록한 모든 것: 결정, 환경
  세부사항, 기억하라고 말한 것들
- **모든 `prj/<name>` 브랜치** — 프로젝트별 계획·노트·조사 결과

메모리와 작업 공간 노트에는 작업의 내부 세부사항이 일상적으로 담긴다.
**저장소를 private 로 유지한다.** 첫 push 전에 — `setup` 중에, 그리고 나중에 로컬 전용
설정을 `/csync remote` 로 승격할 때 다시 — csync 는 사용자의 말을 믿는 대신 **원격의
공개 여부를 직접 확인한다.** 가능하면 `gh` 를, 아니면 익명 fetch 를 쓴다. public 으로
읽히는 저장소는 push 를 중단시키고, 판정할 수 없는 저장소는 private 가 아니라
**판정 불가**로 보고한다.

나중에 저장소를 private 로 바꾸는 것은 **이미 가져가졌거나 색인된 내용을 회수하지
못한다.** 검사가 전송 전에 이루어지는 이유다.

동기화하지 않는 것: `~/.claude/settings.json`(머신 로컬 권한과 경로), 세션 트랜스크립트,
그 밖에 csync 가 놓지 않은 `~/.claude` 아래의 모든 것.

## 업데이트와 제거

```
/csync update
```

도구 repo 를 pull 하고, **무엇이 바뀌었는지 알려준다.** 이전 리비전과 새 리비전 사이의
diff 에서 읽어, 바뀐 파일 목록이 아니라 앞으로 세션이 무엇을 다르게 하는지로 옮겨 말한다.
받아올 것이 없었다면 그 한 줄로 끝난다.

pull 만으로는 적용되지 않는 것도 함께 짚는다. `SKILL.md` 나 `references/` 의 변경은
**다음** 세션부터 적용된다 — 현재 세션은 시작 시점에 옛 사본을 로드했다. `scripts/` 가
바뀌었다면 `install.sh` 를 다시 실행해야 한다. SessionStart hook 이 스크립트 경로를
기록해 두기 때문이다. `templates/` 갱신은 그 이후 만들어지는 작업 공간에만 적용되며,
이미 있는 작업 공간을 다시 쓰지 않는다.

직접 챙길 필요는 없다. SessionStart hook 이 스킬 자신의 clone 도 확인한다 — 다만 그쪽은
**알리기만 한다.** 내 사본이 깨끗하게 뒤처져 있으면 세션이 열릴 때 몇 커밋이 밀려 있는지
한 줄이 뜬다. 몰래 merge 하지는 않는다. 이미 진행 중인 작업 아래에서 규칙이 바뀌고,
그 clone 이 편집 중인 것일 수도 있기 때문이다. 로컬 커밋이 있거나 네트워크가 끊겼을 때는
이 줄이 뜨지 않으므로, **줄이 없다고 최신이라는 보장은 아니다.**

```
/csync uninstall
```

사용자 자신의 내용을 담은 심볼릭 링크 — 글로벌 `CLAUDE.md` 와 각 메모리 디렉토리 — 는
가리키던 것의 실제 사본으로 교체하므로 이후 아무것도 사라지지 않는다. 배선에 지나지
않는 링크는 그대로 제거한다: 포인터·레지스트리·hook·`bin/` 래퍼·스킬 링크. **sync
저장소와 프로젝트 작업 공간, 그리고 스킬 자신의 clone 은 그대로 둔다** — 그것을 지우는
것은 사용자의 판단이다. `--dry-run` 을 먼저 실행한다. 스킬은 그렇게 한다.

## 뭔가 잘못돼 보일 때

**"글로벌 CLAUDE.md 와 메모리가 사라졌다."** clone 이 옮겨져 심볼릭 링크가 끊어진
것이다. `install.sh` 를 다시 실행하면 두 포인터와 스킬 링크, hook 경로를 다시 쓴다.

**`/csync` 가 명령으로 잡히지 않는다.** `~/.claude/skills/csync` 에서 스킬을 찾지
못한 것이다. clone 이 다른 곳에 있다면 셸에서 그 clone 의 `scripts/install.sh` 를
실행하고 — 링크를 만드는 것이 그 스크립트다 — 세션을 새로 시작한다. 스킬은 세션
시작 시점에 로드된다.

**프로젝트에서 `.csync/` 가 untracked 로 뜬다.** 글로벌 git excludes 파일에서 항목이
빠진 것이다. 설치 스크립트를 다시 실행하면 되돌아온다.

**`DIVERGED sync repo — local 3 / remote 5`.** 두 머신이 공통 조상 이후 각자 진행한
것이다. 스크립트는 그 위에 커밋하지 않고 멈춘다 — 갈라진 히스토리 위에 커밋하면 실행할
때마다 한 커밋씩 더 깊어지기 때문이다. Claude 에게 해결을 요청한다. 절차는
[`references/divergence.md`](references/divergence.md) 에 있다. 그동안 잃는 것은 없다 —
커밋하지 않은 작업은 작업 트리에 그대로 있다.

**세션 시작 pull 이 더 이상 돌지 않는다.** `~/.claude/settings.json` 에서 hook 항목이
사라진 것이다. 설치 스크립트를 다시 실행한다.

## 어떻게 구성되어 있나

- **`main`** 은 글로벌 설정을, **`prj/<name>`** 은 프로젝트 하나의 작업 공간을 orphan
  히스토리로 담는다 — 공유하는 파일도, 공통 조상도 없다. 의도한 설계다: 작업 공간
  clone 은 자기 브랜치만 가져온다. git 도구들이 이를 오독할 것을 예상해야 한다(GitHub
  는 의미 없는 ahead/behind 숫자를 보여주고, IDE 는 병합을 제안한다). **브랜치끼리
  merge 나 rebase 를 하지 않으며, 모든 것이 fast-forward 전용이다.**
- **pull 은 레지스트리 전체, push 는 `$PWD` 한정.** 알려진 모든 clone 을 fast-forward
  하는 것은 안전하지만 — 커밋하지 않은 작업을 건드릴 수 없다 — 다른 프로젝트를 대신해
  커밋하는 것은 다른 창에서 아직 진행 중인 세션의 미완성 작업을 쉽게 커밋해 버린다.
- **분기(divergence)는 "오프라인"이 아니라 그 자체로 보고된다.** 둘은 정반대의 대응을
  요구한다. 닿지 않는 원격은 다음 실행에서 저절로 낫지만, 갈라진 히스토리는 sync 가 그
  위에 커밋할 때마다 나빠진다.
- **작업 공간 디렉토리 이름은 머신 로컬 설정이 아니라 저장소 안(`csync.conf`)에 있다.**
  각 프로젝트 안의 실제 디렉토리 이름이므로, 두 머신이 서로 다르게 알면 아무 관계 없는
  두 디렉토리가 생긴다.

## 라이선스

MIT — [LICENSE](LICENSE) 참조.
