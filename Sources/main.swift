import Cocoa
import Carbon.HIToolbox
import ServiceManagement

// ClipDeck — 클립보드를 수동 단축키로 모아 Obsidian Inbox.md에 쌓는 메뉴바 앱.
// 수집만 담당(LLM 호출 없음). "정리용으로 복사"로 정리 프롬프트까지 한 번에.

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    let defaults = UserDefaults.standard

    // MARK: 저장 위치
    var inboxURL: URL {
        if let p = defaults.string(forKey: "inboxPath"), !p.isEmpty {
            return URL(fileURLWithPath: (p as NSString).expandingTildeInPath)
        }
        let dir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("ClipDeck")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Inbox.md")
    }

    // MARK: 오늘 담긴 개수
    private func todayKey() -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df.string(from: Date())
    }
    var todayCount: Int {
        get { defaults.string(forKey: "countDate") == todayKey() ? defaults.integer(forKey: "count") : 0 }
        set { defaults.set(todayKey(), forKey: "countDate"); defaults.set(newValue, forKey: "count") }
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateTitle()
        if let b = statusItem.button {
            b.target = self
            b.action = #selector(statusClicked)
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        registerHotKey()
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    // MARK: 서비스 — 선택 후 우클릭 → 서비스 → "ClipDeck에 담기"
    @objc func captureToClipDeck(_ pboard: NSPasteboard, userData: String?,
                                 error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        capture(pboard.string(forType: .string) ?? "")
    }

    private func updateTitle() {
        statusItem.button?.title = todayCount > 0 ? "📋 \(todayCount)" : "📋"
    }
    private func flash(_ s: String) {
        statusItem.button?.title = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.updateTitle() }
    }

    // MARK: 클릭 — 좌클릭=메뉴, 우클릭=지금 담기
    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            captureClipboard()
        } else {
            statusItem.menu = buildMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        }
    }

    // MARK: 전역 단축키 ⌘⌃C
    private func registerHotKey() {
        let hotID = EventHotKeyID(signature: OSType(0x434C4950) /*CLIP*/, id: 1)
        var ref: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_C), UInt32(cmdKey | controlKey),
                            hotID, GetApplicationEventTarget(), 0, &ref)
        hotKeyRef = ref
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            let me = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async { me.captureClipboard() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    // MARK: 담기
    @objc func captureClipboard() {
        capture(NSPasteboard.general.string(forType: .string) ?? "")
    }

    // 모든 담기 경로의 공통 처리(중복 방지 포함)
    func capture(_ raw: String) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { flash("⚠️"); return }
        if s == defaults.string(forKey: "lastText") { flash("⏸"); return }  // 연타·중복 방지
        appendToInbox(s)
        defaults.set(s, forKey: "lastText")
        todayCount += 1
        flash("✅")
    }

    // 출처 앱 이름(Slack, Chrome 등). 못 찾으면 "메모".
    private func sourceName() -> String {
        if let n = NSWorkspace.shared.frontmostApplication?.localizedName, n != "ClipDeck" { return n }
        return "메모"
    }

    private func appendToInbox(_ text: String) {
        let url = inboxURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        var out = ""
        // 하루 바뀌면 날짜 헤더 1회
        let dayKey = todayKey()
        if defaults.string(forKey: "lastDayHeader") != dayKey {
            let hf = DateFormatter(); hf.locale = Locale(identifier: "ko_KR"); hf.dateFormat = "yyyy-MM-dd (E)"
            out += "\n## \(hf.string(from: Date()))\n"
            defaults.set(dayKey, forKey: "lastDayHeader")
        }
        let tf = DateFormatter(); tf.dateFormat = "HH:mm"
        out += "\n### \(tf.string(from: Date())) · \(sourceName())\n\(text)\n"
        let data = Data(out.utf8)
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile(); h.write(data); try? h.close()
        } else {
            try? (Data("# ClipDeck Inbox\n".utf8) + data).write(to: url)
        }
        defaults.set(data.count, forKey: "lastAppendLen")  // 마지막 담기 취소용
    }

    // MARK: 마지막 담기 취소
    @objc func undoLast() {
        let len = defaults.integer(forKey: "lastAppendLen")
        guard len > 0, let data = try? Data(contentsOf: inboxURL), data.count >= len else { flash("⚠️"); return }
        try? data.subdata(in: 0..<(data.count - len)).write(to: inboxURL)
        defaults.set(0, forKey: "lastAppendLen")
        defaults.set("", forKey: "lastText")
        if todayCount > 0 { todayCount -= 1 }
        flash("↩️")
    }

    // MARK: 정리용으로 복사 (정리 프롬프트 + 담긴 전체 → 클립보드)
    @objc func copyForOrganize() {
        guard let content = try? String(contentsOf: inboxURL, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            flash("⚠️"); return
        }
        let prompt = """
        아래 붙여넣은 내용을 다음으로 정리해줘:
        1. ## 액션 아이템 — 한 줄씩: `- [ ] <할일> 📅 <날짜 있으면 YYYY-MM-DD> #<출처>` (코딩 작업이면 #dev 추가)
        2. ## 맥락/결정 — 최대 5개 불릿, 남길 가치 있는 사실만
        3. ## 요약 — 3줄 이내
        없는 할일이나 날짜를 지어내지 말 것. 마크다운만 출력.

        ---
        \(content)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        flash("📄")
    }

    @objc func openInbox() { NSWorkspace.shared.open(inboxURL) }

    // MARK: 아카이브(비우기)
    @objc func archiveInbox() {
        guard let content = try? String(contentsOf: inboxURL, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { flash("⚠️"); return }
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "Inbox를 비울까요?"
        a.informativeText = "현재 담긴 내용을 Archive 폴더로 옮기고 Inbox.md를 비웁니다."
        a.addButton(withTitle: "비우기")
        a.addButton(withTitle: "취소")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        let dir = inboxURL.deletingLastPathComponent().appendingPathComponent("Archive")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd_HHmm"
        let dst = dir.appendingPathComponent("Inbox-\(df.string(from: Date())).md")
        try? content.write(to: dst, atomically: true, encoding: .utf8)
        try? "# ClipDeck Inbox\n".write(to: inboxURL, atomically: true, encoding: .utf8)
        flash("🗂")
    }

    // MARK: 저장 위치 지정
    @objc func setInboxPath() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSSavePanel()
        panel.message = "Obsidian 볼트 안에 Inbox.md 위치를 지정하세요"
        panel.nameFieldStringValue = "Inbox.md"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            defaults.set(url.path, forKey: "inboxPath")
            flash("✅")
        }
    }

    // MARK: 로그인 항목
    @objc func toggleLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
                else { try SMAppService.mainApp.register() }
            } catch { NSSound.beep() }
        }
    }

    @objc func quit() { NSApp.terminate(nil) }

    // MARK: 메뉴
    private func buildMenu() -> NSMenu {
        let m = NSMenu()
        let cap = NSMenuItem(title: "지금 클립보드 담기", action: #selector(captureClipboard), keyEquivalent: "c")
        cap.keyEquivalentModifierMask = [.command, .control]
        cap.target = self
        m.addItem(cap)
        let svc = NSMenuItem(title: "또는: 텍스트 선택 → 우클릭 → 서비스 → ClipDeck에 담기", action: nil, keyEquivalent: "")
        svc.isEnabled = false
        m.addItem(svc)
        m.addItem(.separator())

        var countTitle = "오늘 담긴 항목: \(todayCount)개"
        if todayCount > 0, let last = defaults.string(forKey: "lastText"), !last.isEmpty {
            let preview = String(last.prefix(18)).replacingOccurrences(of: "\n", with: " ")
            countTitle += " · 마지막: \(preview)…"
        }
        let count = NSMenuItem(title: countTitle, action: nil, keyEquivalent: "")
        count.isEnabled = false
        m.addItem(count)

        add(m, "↩︎ 마지막 담기 취소", #selector(undoLast))
        add(m, "담긴 항목 보기 (Inbox.md)", #selector(openInbox))
        add(m, "📄 정리용으로 복사", #selector(copyForOrganize))
        add(m, "Inbox 비우기(아카이브)…", #selector(archiveInbox))
        m.addItem(.separator())

        let path = defaults.string(forKey: "inboxPath") ?? "미지정(기본: ~/ClipDeck/Inbox.md)"
        let pinfo = NSMenuItem(title: "저장: \((path as NSString).abbreviatingWithTildeInPath)", action: nil, keyEquivalent: "")
        pinfo.isEnabled = false
        m.addItem(pinfo)
        add(m, "저장 위치 지정…", #selector(setInboxPath))

        if #available(macOS 13.0, *) {
            let on = SMAppService.mainApp.status == .enabled
            let li = NSMenuItem(title: "로그인 시 자동 실행", action: #selector(toggleLogin), keyEquivalent: "")
            li.target = self; li.state = on ? .on : .off
            m.addItem(li)
        }
        m.addItem(.separator())
        add(m, "종료", #selector(quit))
        return m
    }
    private func add(_ m: NSMenu, _ title: String, _ sel: Selector) {
        let i = NSMenuItem(title: title, action: sel, keyEquivalent: ""); i.target = self; m.addItem(i)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
