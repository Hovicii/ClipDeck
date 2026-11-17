# ClipDeck

A tiny macOS menu-bar app that collects selected text / clipboard snippets into one
Markdown inbox (e.g. inside an Obsidian vault), so you never lose a to-do scattered across
Slack, Jira, meeting notes, and email. **Collection only — no LLM, no network.**

## How you use it
- **Select text → right-click → Services → "ClipDeck에 담기"** (doesn't touch your clipboard), or
- **Copy (⌘C) → press ⌘⌃C** to capture the current clipboard.

Each capture is appended to `Inbox.md` with the **source app** and a **daily header**:
```
## 2026-11-18 (화)

### 09:10 · Slack
Please share the stock-reconciliation report draft by Friday

### 09:42 · Chrome
Please review PR PROJ-1423
```

Then, when you want, **📋 menu → "정리용으로 복사"** copies everything plus an organize
prompt to your clipboard — paste it into your AI assistant once to turn it into a clean
`- [ ] task 📅 date #source` list for Obsidian. The app itself never calls an LLM.

### Small niceties
- Auto source tag (Slack / Chrome / …) and daily date headers
- Duplicate guard (double-capture of the same text is ignored)
- **Undo last capture** from the menu
- Archive the inbox to a dated file with one click

## Requirements
- macOS 13 or later (universal: Apple Silicon + Intel)
- No special permissions needed (Services & the ⌘⌃C hotkey work without Accessibility/Screen Recording)

## Install with Homebrew (recommended — no Gatekeeper block)
```bash
brew tap hovicii/tap
brew trust hovicii/tap
brew install --cask --no-quarantine hovicii/tap/clipdeck
```
`--no-quarantine` installs the unsigned app without the "cannot verify malware" warning.
Update: `brew upgrade --cask clipdeck` · Uninstall: `brew uninstall --cask clipdeck`

## Build from source
```bash
git clone https://github.com/Hovicii/ClipDeck.git
cd ClipDeck
./build.sh
cp -R build/ClipDeck.app /Applications/
open /Applications/ClipDeck.app
```

## First-time setup
1. 📋 menu → **"저장 위치 지정…"** → pick `Inbox.md` inside your Obsidian vault (otherwise it defaults to `~/ClipDeck/Inbox.md`).
2. If the right-click Service doesn't appear, enable it once in **System Settings → Keyboard → Keyboard Shortcuts → Services → Text → "ClipDeck에 담기"** (you can assign a shortcut there too). A logout/login makes it show up reliably.

## License
Personal utility. Use and modify freely.

---

# ClipDeck (한국어)

선택한 텍스트나 클립보드 조각을 **하나의 마크다운 인박스**(예: Obsidian 볼트의 `Inbox.md`)에
모아주는 작은 macOS 메뉴바 앱. Slack·Jira·회의록·이메일에 흩어진 할일을 놓치지 않게.
**수집만 — LLM 호출 없음, 네트워크 없음.**

## 쓰는 법
- **텍스트 선택 → 우클릭 → 서비스 → "ClipDeck에 담기"** (클립보드 안 건드림), 또는
- **복사(⌘C) → ⌘⌃C** 로 현재 클립보드 담기.

담을 때마다 **출처 앱**과 **날짜 헤더**가 자동으로 붙어 `Inbox.md`에 쌓입니다(위 예시 참고).

그다음 원할 때 **📋 메뉴 → "정리용으로 복사"** = 담긴 전체 + 정리 프롬프트가 클립보드에 올라감
→ AI에 한 번 붙여넣으면 `- [ ] 할일 📅 날짜 #출처` 형태로 정리. 앱 자체는 LLM을 부르지 않음.

### 작은 편의
- 출처 자동 태그, 날짜 헤더
- 연타·중복 방지
- **마지막 담기 취소**(메뉴)
- 인박스 아카이브(날짜 파일로)

## 요구 사양
- macOS 13 이상 (유니버설: Apple Silicon + Intel)
- 특별 권한 불필요 (서비스·⌘⌃C 모두 손쉬운 사용/화면기록 권한 없이 작동)

## Homebrew로 설치 (권장 — Gatekeeper 차단 없음)
```bash
brew tap hovicii/tap
brew trust hovicii/tap
brew install --cask --no-quarantine hovicii/tap/clipdeck
```
`--no-quarantine` 덕분에 "악성 코드가 없음을 확인할 수 없습니다" 경고 없이 설치됩니다.
업데이트: `brew upgrade --cask clipdeck` · 삭제: `brew uninstall --cask clipdeck`

## 소스에서 빌드
```bash
git clone https://github.com/Hovicii/ClipDeck.git
cd ClipDeck
./build.sh
cp -R build/ClipDeck.app /Applications/
open /Applications/ClipDeck.app
```

## 최초 설정
1. 📋 메뉴 → **"저장 위치 지정…"** → Obsidian 볼트 안 `Inbox.md` 지정 (안 하면 기본 `~/ClipDeck/Inbox.md`).
2. 우클릭 서비스가 안 보이면 **시스템 설정 → 키보드 → 키보드 단축키 → 서비스 → 텍스트 → "ClipDeck에 담기"** 체크(단축키도 지정 가능). 로그아웃/로그인하면 확실히 나타남.

## 라이선스
개인 유틸리티. 자유롭게 사용·수정하세요.
