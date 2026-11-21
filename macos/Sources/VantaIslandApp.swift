import SwiftUI
import AppKit
import Combine

@main
struct VantaIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let view = IslandView { [weak self] expanded in self?.resizePanel(expanded: expanded) }
        let hosting = NSHostingView(rootView: view)
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 236, height: 54),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.contentView = hosting
        p.isFloatingPanel = true
        p.level = .statusBar
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.hidesOnDeactivate = false
        p.isMovableByWindowBackground = true
        panel = p
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "V"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Vanta Island", action: #selector(showIsland), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Vanta Island", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
        positionPanel(expanded: false)
        p.orderFrontRegardless()
    }
    @objc private func showIsland() { panel?.orderFrontRegardless() }
    @objc private func quitApp() { NSApp.terminate(nil) }
    private func resizePanel(expanded: Bool) {
        guard let p = panel else { return }
        p.setContentSize(NSSize(width: expanded ? 430 : 236, height: expanded ? 172 : 54))
        positionPanel(expanded: expanded)
    }
    private func positionPanel(expanded: Bool) {
        guard let p = panel, let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let width: CGFloat = expanded ? 430 : 236
        let height: CGFloat = expanded ? 172 : 54
        p.setFrame(NSRect(x: frame.midX - width/2, y: frame.maxY - height - 7, width: width, height: height), display: true)
    }
}

struct IslandView: View {
    var onExpandChanged: (Bool) -> Void
    @State private var expanded = false
    @State private var track = "Nothing playing"
    @State private var artist = "Connect Spotify or Apple Music"
    @State private var battery = BatteryReader.status()
    @State private var volume = 50.0
    @State private var selectedTheme = "Violet"
    @State private var showWallpapers = false
    private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                Circle().fill(Color(red: 0.68, green: 0.56, blue: 1)).frame(width: 7, height: 7)
                    .shadow(color: .purple.opacity(0.9), radius: 5)
                Text(expanded ? "VANTA ISLAND" : "Vanta Island")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(expanded ? 1.6 : 0.2)
                Spacer(minLength: 4)
                if expanded {
                    Text(Date.now, style: .time).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                    Button { showWallpapers.toggle() } label: { Image(systemName: "circle.lefthalf.filled") }
                        .buttonStyle(.plain).help("Wallpaper themes")
                    Button { expanded = false; onExpandChanged(false) } label: { Image(systemName: "chevron.up") }
                        .buttonStyle(.plain).help("Collapse")
                } else {
                    Image(systemName: "waveform").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
                }
            }
            if expanded {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 11).fill(LinearGradient(colors: themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48).overlay(Image(systemName: "music.note").font(.system(size: 19, weight: .medium)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                        Text(artist).font(.system(size: 10)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Button { spotify("previous track") } label: { Image(systemName: "backward.end.fill") }
                    Button { spotify("playpause") } label: { Image(systemName: "playpause.fill") }
                    Button { spotify("next track") } label: { Image(systemName: "forward.end.fill") }
                }.buttonStyle(.plain)
                Divider().overlay(.white.opacity(0.1))
                HStack(spacing: 10) {
                    Image(systemName: battery.contains("Charging") ? "battery.100percent.bolt" : "battery.75")
                    Text(battery).font(.system(size: 10)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: "speaker.wave.2")
                    Slider(value: $volume, in: 0...100, onEditingChanged: { editing in if !editing { setVolume(volume) } })
                        .frame(width: 95).tint(Color(red: 0.68, green: 0.56, blue: 1))
                }
                if showWallpapers {
                    HStack(spacing: 7) {
                        ForEach(["Violet", "Ocean", "Sunset", "Midnight"], id: \.self) { theme in
                            Button(theme) { selectedTheme = theme }
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(selectedTheme == theme ? Color.purple.opacity(0.35) : Color.white.opacity(0.08), in: Capsule())
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 17).padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: expanded ? 25 : 28).fill(.black.gradient))
        .overlay(RoundedRectangle(cornerRadius: expanded ? 25 : 28).stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: themeColors.first.opacity(0.22), radius: 18, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 26))
        .onTapGesture(count: 1) {
            if !expanded { expanded = true; onExpandChanged(true) }
        }
        .onReceive(timer) { _ in battery = BatteryReader.status() }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: expanded)
        .preferredColorScheme(.dark)
    }

    private var themeColors: [Color] {
        switch selectedTheme {
        case "Ocean": return [Color.cyan, Color.blue, Color.black]
        case "Sunset": return [Color.orange, Color.pink, Color.purple]
        case "Midnight": return [Color.gray, Color.indigo, Color.black]
        default: return [Color.purple, Color(red: 0.25, green: 0.18, blue: 0.5), Color.black]
        }
    }
    private func spotify(_ command: String) {
        let script = "if application \"Spotify\" is running then tell application \"Spotify\" to (command)"
        runAppleScript(script)
        if command == "next track" { track = "Spotify · Next track" }
        else if command == "previous track" { track = "Spotify · Previous track" }
        else { track = "Spotify playback toggled" }
        artist = "Spotify desktop app"
    }
    private func setVolume(_ value: Double) {
        runAppleScript("set volume output volume \(Int(value))")
    }
    private func runAppleScript(_ source: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        try? process.run()
    }
}

enum BatteryReader {
    static func status() -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g", "batt"]
        let pipe = Pipe(); p.standardOutput = pipe
        do {
            try p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)
            let percent = output.range(of: #"\\d+%"#, options: .regularExpression).map { String(output[$0]) } ?? "?"
            let state = output.contains("AC Power") ? "Charging" : "On battery"
            return "\(percent) · \(state)"
        } catch { return "Battery status unavailable" }
    }
}
