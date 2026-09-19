import SwiftUI
import AppKit
import UserNotifications
import CoreText

@main
struct SumiHubApp: App {
    // Moved here so MenuBarExtra can access them
    @StateObject private var vault = VaultManager()
    @StateObject private var timerManager = TimerManager()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        registerBundledFonts()
    }
    
    // Shippori Mincho (OFL 1.1) ships inside the bundle (Sumi Hub/Fonts) and is
    // registered process-wide at launch so Font.custom("ShipporiMincho-…") works.
    private func registerBundledFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vault)
                .environmentObject(timerManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Timer") {
                Button("Start/Pause") {
                    NotificationCenter.default.post(name: .toggleTimer, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button("Reset") {
                    NotificationCenter.default.post(name: .resetTimer, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Toggle Zen Mode") {
                    NotificationCenter.default.post(name: .toggleZen, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(vault)
        }
        
        // Menu Bar Extra
        MenuBarExtra("Sumi", systemImage: "timer", content: {
            MenuBarView()
                .environmentObject(vault)
                .environmentObject(timerManager)
        })
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate for Global Hotkeys
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: GlobalHotkeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager = GlobalHotkeyManager()
        hotkeyManager?.startMonitoring { event in
            // Space to start/pause timer (if not in a text field)
            if event.keyCode == 49 && event.modifierFlags.contains(.command) {
                NotificationCenter.default.post(name: .toggleTimer, object: nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.stopMonitoring()
    }
}

// MARK: - Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var vault: VaultManager
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(timerManager.formattedTime)
                    .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 24, weight: .light))
                    .foregroundColor(vault.theme.textPrimary) // Fixed white text
                Spacer()
                Button(action: { timerManager.toggle() }) {
                    Image(systemName: timerManager.isRunning ? "pause.circle" : "play.circle")
                        .font(.system(size: 20))
                        .foregroundColor(vault.theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            Text("Today: \(todayMinutes)m / \(vault.settings.dailyGoal)m")
                .font(.system(size: 12))
                .foregroundColor(vault.theme.textSecondary)
            
            Button("Open Sumi") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .foregroundColor(vault.theme.textPrimary)
        }
        .padding(16)
        .frame(width: 250)
        .background(vault.theme.background)
        .tint(vault.theme.accent)
    }
    
    var todayMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        return vault.dailyStats[key]?.totalMinutes ?? 0
    }
}

struct SettingsView: View {
    @AppStorage("dailyGoal") private var dailyGoal = 120
    @AppStorage("studyMinutes") private var studyMinutes = 50
    @AppStorage("breakMinutes") private var breakMinutes = 10
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        Form {
            Section("Timer") {
                Stepper("Daily Goal: \(dailyGoal) minutes", value: $dailyGoal, in: 30...300, step: 10)
                Stepper("Study Duration: \(studyMinutes) minutes", value: $studyMinutes, in: 15...90, step: 5)
                Stepper("Break Duration: \(breakMinutes) minutes", value: $breakMinutes, in: 5...30, step: 5)
            }
        }
        .padding(40)
        .frame(width: 500, height: 300)
        .tint(vault.theme.accent)
    }
}

extension Notification.Name {
    static let toggleTimer = Notification.Name("toggleTimer")
    static let resetTimer = Notification.Name("resetTimer")
    static let toggleZen = Notification.Name("toggleZen")
    static let sessionCompleted = Notification.Name("sessionCompleted")
}
