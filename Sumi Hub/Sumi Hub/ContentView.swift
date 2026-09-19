import SwiftUI
import UniformTypeIdentifiers
import Combine
import AppKit
import UserNotifications
import WidgetKit
import AVFoundation

// MARK: - Models
struct StudySession: Identifiable, Codable, Hashable {
    let id: UUID
    var subject: String
    var duration: Int
    var date: Date
    var type: String
    var mood: Int?
    var appsUsed: [String] = []
    var goals: [FocusGoal] = []
    var awayMinutes: Int? = nil
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: StudySession, rhs: StudySession) -> Bool { lhs.id == rhs.id }
}

struct FocusGoal: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var category: String
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String = "General") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
    }
}

struct DailyStats: Codable {
    var date: String
    var totalMinutes: Int
    var mood: Int
    var sessions: [StudySession]
    var topApps: [String: Int] = [:]
    var completedGoals: Int = 0
}

struct Habit: Identifiable, Codable {
    let id: UUID
    var title: String
    var streak: Int
    var completedDates: [String]
    var category: String
    
    init(id: UUID = UUID(), title: String, streak: Int = 0, completedDates: [String] = [], category: String = "General") {
        self.id = id
        self.title = title
        self.streak = streak
        self.completedDates = completedDates
        self.category = category
    }
}

struct Quote: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var author: String
}

struct AppSettings: Codable {
    var dailyGoal: Int = 120
    var studyMinutes: Int = 50
    var breakMinutes: Int = 10
    var longBreakMinutes: Int = 30
    var roundsBeforeLongBreak: Int = 4
    var windDownHour: Int = 22
    var ambience: String = "none"
    var ambienceVolume: Double = 0.5
    var showQuotes: Bool = true
    var theme: AppTheme = .sumi
    var calendarIntegration: Bool = false
    var silenceNotifications: Bool = true
    var trackAppUsage: Bool = true
    var blockDistractions: Bool = false
    var blockedApps: [String] = ["Safari", "Mail", "Messages"]
    var autoContinuePomodoro: Bool = false
    var breatheGapSeconds: Int = 30
    var streakMercy: Bool = true
    var interruptionAware: Bool = true
}

enum AppTheme: String, Codable, CaseIterable {
    case dark = "Dark"
    case sumi = "Sumi"
    
    // Old Light/Sepia/H. Contrast saved values fold to Sumi instead of failing
    // the whole settings file decode (ADR-004).
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = AppTheme(rawValue: value) ?? .sumi
    }
    
    var colors: ThemeColors {
        switch self {
        case .dark:
            return ThemeColors(
                background: Color(red: 0.118, green: 0.118, blue: 0.180),
                sidebar: Color(red: 0.094, green: 0.094, blue: 0.145),
                card: Color(red: 0.192, green: 0.196, blue: 0.267),
                textPrimary: Color(red: 0.776, green: 0.816, blue: 0.961),
                textSecondary: Color(red: 0.702, green: 0.737, blue: 0.875),
                accent: Color(red: 0.533, green: 0.373, blue: 0.306),
                seal: Color(red: 0.839, green: 0.506, blue: 0.490),
                divider: Color(red: 0.263, green: 0.275, blue: 0.353),
                warm: Color(red: 0.247, green: 0.187, blue: 0.236),
                buttonBackground: Color(red: 0.533, green: 0.373, blue: 0.306),
                buttonText: Color(red: 0.933, green: 0.902, blue: 0.867)
            )
        case .sumi:
            // Web app look (app/index.html): moss + rust on warm ink, serif
            // display type, halo ring. Palette lifted verbatim from the site CSS.
            var colors = ThemeColors(
                background: Color(red: 0.086, green: 0.090, blue: 0.078),
                sidebar: Color(red: 0.063, green: 0.067, blue: 0.063),
                card: Color(red: 0.118, green: 0.122, blue: 0.102),
                textPrimary: Color(red: 0.906, green: 0.886, blue: 0.831),
                textSecondary: Color(red: 0.561, green: 0.541, blue: 0.471),
                accent: SumiSeason.current.accent,
                seal: Color(red: 0.831, green: 0.412, blue: 0.290),
                divider: Color(red: 0.200, green: 0.204, blue: 0.169),
                warm: Color(red: 0.129, green: 0.110, blue: 0.090),
                buttonBackground: Color(red: 0.906, green: 0.886, blue: 0.831),
                buttonText: Color(red: 0.086, green: 0.090, blue: 0.078)
            )
            colors.serifDisplay = true
            return colors
        }
    }
}

struct ThemeColors {
    let background: Color
    let sidebar: Color
    let card: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let seal: Color
    let divider: Color
    let warm: Color
    let buttonBackground: Color
    let buttonText: Color
    // Sumi-only flourish (ADR-004): display type becomes Shippori Mincho. Dark
    // and any future theme keep Atkinson everywhere.
    var serifDisplay: Bool = false
    
    var paper: Color { background }
    var paperDark: Color { sidebar }
    var ink: Color { textPrimary }
    var inkLight: Color { textSecondary }
    var moss: Color { accent }
}

// MARK: - Design System (zen-native chrome)
// Single source of truth for radii, spacing and soft-shadow so every card and
// control reads as one quiet system. Additive + dependency-free: uses ONLY the
// standard SwiftUI primitives that already built clean, so this can never break
// the rest of the file.
struct DesignSystem {
    // Hairline strokes built from theme ink at low opacity (never heavy boxes).
    static func strokeOpacity(hovering: Bool = false) -> Double { hovering ? 0.14 : 0.07 }
    static func dividerOpacity() -> Double { 0.06 }

    // Zen corner languages: calm cards, tighter controls, smallest chips.
    static func radiusCard() -> CGFloat { 8 }
    static func radiusControl() -> CGFloat { 7 }
    static func radiusChip() -> CGFloat { 6 }
    static func radiusSidebar() -> CGFloat { 10 }

    // Breathable 8-pt spacing rhythm — the anti-clutter lever.
    static func spaceXS() -> CGFloat { 6 }
    static func spaceS() -> CGFloat { 10 }
    static func spaceM() -> CGFloat { 16 }
    static func spaceL() -> CGFloat { 24 }
    static func spaceXL() -> CGFloat { 40 }

    // Keep the window airy but not empty.
    static func contentInset() -> CGFloat { 28 }
    static func contentInsetCompact() -> CGFloat { 20 }

    // Soft ambient presence — shadow, not weight.
    static func shadowColorOpacity() -> Double { 0.10 }
    static func shadowRadius() -> CGFloat { 10 }
    static func shadowOffsetY() -> CGFloat { 2 }

    // Type scale (Atkinson Hyperlegible Next — the vault's own typeface).
    static func typeDisplay() -> CGFloat { 64 }
    static func typeHero() -> CGFloat { 30 }
    static func typeTitle() -> CGFloat { 22 }
    static func typeSection() -> CGFloat { 15 }
    static func typeBody() -> CGFloat { 13 }
    static func typeSmall() -> CGFloat { 12 }
    static func typeCaption() -> CGFloat { 11 }

    // Typeface — Atkinson Hyperlegible Next, installed system-wide (same font
    // the Obsidian vault uses). PostScript-name per weight; unknown weights
    // fall back to Regular rather than trapping.
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .ultraLight, .thin:
            name = "AtkinsonHyperlegibleNext-ExtraLight"
        case .light:
            name = "AtkinsonHyperlegibleNext-Light"
        case .medium:
            name = "AtkinsonHyperlegibleNext-Medium"
        case .semibold:
            name = "AtkinsonHyperlegibleNext-SemiBold"
        case .bold:
            name = "AtkinsonHyperlegibleNext-Bold"
        case .heavy, .black:
            name = "AtkinsonHyperlegibleNext-ExtraBold"
        default:
            name = "AtkinsonHyperlegibleNext-Regular"
        }
        return Font.custom(name, size: size)
    }

    // Display type — Shippori Mincho (bundled, OFL) when the theme opts into
    // serif display (Sumi, ADR-004), else Atkinson for everything. Only the
    // closest Mincho cut exists per request; unknown weights fold up, never
    // try to load a missing PostScript name.
    static func displayFont(serif: Bool, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard serif else { return font(size, weight: weight) }
        let name: String
        switch weight {
        case .ultraLight, .thin, .light, .regular:
            name = "ShipporiMincho-Medium"
        case .medium:
            name = "ShipporiMincho-Medium"
        case .semibold:
            name = "ShipporiMincho-SemiBold"
        case .bold, .heavy, .black:
            name = "ShipporiMincho-Bold"
        default:
            name = "ShipporiMincho-Medium"
        }
        return Font.custom(name, size: size)
    }
}

// MARK: - Materials Kit (minimal surfaces)
// Shared primitives so rooms stop hand-rolling background/cornerRadius/shadow.
// One caller: every card/panel goes through surface(theme:) — card fill +
// hairline stroke + soft shadow + radius from the tokens below, so depth reads as
// one system instead of ad-hoc boxes.

struct PanelSurface: ViewModifier {
    let theme: ThemeColors
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.spaceM())
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.radiusCard())
                    .fill(theme.card)
            )
    }
}

extension View {
    /// Minimal layered card: card fill + hairline stroke + soft shadow.
    func surface(_ theme: ThemeColors) -> some View {
        modifier(PanelSurface(theme: theme))
    }
}

struct PillButtonStyle: ButtonStyle {
    let theme: ThemeColors
    let prominent: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.font(DesignSystem.typeBody(), weight: .medium))
            .foregroundColor(prominent ? theme.buttonText : theme.textPrimary)
            .padding(.horizontal, DesignSystem.spaceL())
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.radiusControl())
                    .fill(prominent ? theme.buttonBackground : theme.sidebar)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}


struct Note: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var content: String
    var date: Date
    var isMarkdown: Bool = true
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Note, rhs: Note) -> Bool { lhs.id == rhs.id }
}

struct ScheduleEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var dayOfWeek: Int
    var startTime: String
    var endTime: String
}

// MARK: - Audio Player for Ambience
// Fully synthesized stereo ambience — AVAudioSourceNode generates PCM on demand at
// 44.1kHz. No bundled audio files needed. Public API mirrors the original class:
//   playAmbience(named:volume:), stop(), setVolume(_:)
class AudioPlayerManager: ObservableObject {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var currentGain: Float = 0.7
    private var engineRunning = false
    private var currentAmbienceKey: String = "none"
    
    private let format: AVAudioFormat = {
        AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    }()
    
    // Synthesizer state (mutated only inside the render closure; UI never touches these).
    private var noiseSeed: UInt64 = 0x9E3779B97F4A7C15
    private var rainLP: Float = 0
    private var fireRumble: Float = 0
    private var fireRumble2: Float = 0
    private var crackleTimer: Float = 0.05
    private var nextCrackle: Float = 0.05
    private var focusEarthLP: Float = 0
    private var focusWavePhase: Float = 0
    private var fallbackLP: Float = 0
    
    private func nextNoise() -> Float {
        noiseSeed &+= 0x9E3779B97F4A7C15
        let z = noiseSeed
        let h = ((z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9)
        let h2 = ((h ^ (h >> 27)) &* 0x94D049BB133111EB)
        return Float(Int64(bitPattern: h2 ^ (h2 >> 31))) / Float(Int64.max)
    }
    
    func playAmbience(named fileName: String, volume: Float) {
        currentGain = volume
        let key = fileName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard key != "none", key != "" else {
            stop()
            return
        }
        currentAmbienceKey = key
        startAmbience(key)
    }
    
    private func startAmbience(_ key: String) {
        engine.stop()
        engine.reset()
        
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self,
                  audioBufferList.pointee.mBuffers.mData != nil else {
                return noErr
            }
            
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let left = abl[0].mData?.assumingMemoryBound(to: Float.self)
            let right = abl[1].mData?.assumingMemoryBound(to: Float.self)
            let gain = self.currentGain
            let frameCountInt = Int(frameCount)
            
            switch key {
            case "rain":
                for frame in 0..<frameCountInt {
                    let n = self.nextNoise()
                    self.rainLP += 0.015 * (n - self.rainLP)
                    let droplet: Float = self.nextNoise().magnitude > 0.999 ? 0.6 : 0.0
                    let s = (self.rainLP * Float(0.5) + droplet) * Float(0.35)
                    left?[frame] = s * gain
                    right?[frame] = s * gain
                }
            case "fireplace":
                for frame in 0..<frameCountInt {
                    let n = self.nextNoise()
                    self.fireRumble += 0.02 * n
                    self.fireRumble *= 0.999
                    self.fireRumble2 += 0.03 * n
                    self.fireRumble2 *= 0.9995
                    self.crackleTimer -= 1.0 / 44100.0
                    var pop: Float = 0
                    if self.crackleTimer <= 0 {
                        self.nextCrackle = 0.02 + 0.88 * abs(self.nextNoise())
                        self.crackleTimer = self.nextCrackle
                        pop = self.nextNoise().magnitude > 0.96 ? 0.7 : 0.0
                    }
                    let s = (self.fireRumble * 0.7 + self.fireRumble2 * 0.2 + pop * 0.5) * 0.16
                    left?[frame] = s * gain
                    right?[frame] = s * gain
                }
            case "deep focus":
                for frame in 0..<frameCountInt {
                    let t = Float(frame) / 44100.0
                    let n = self.nextNoise()
                    self.focusEarthLP += 0.025 * (n - self.focusEarthLP)
                    let wave = sin(2 * .pi * 92 * t) * 0.4 + sin(2 * .pi * 110 * t) * 0.2
                    let s = (self.focusEarthLP * 0.55 + wave * 0.35) * 0.22
                    left?[frame] = s * gain
                    right?[frame] = s * gain
                }
            default:
                // Fallback: soft filtered noise bed so ambience is never silent.
                for frame in 0..<frameCountInt {
                    let n = self.nextNoise()
                    self.fallbackLP += 0.02 * (n - self.fallbackLP)
                    let s = self.fallbackLP * 0.4
                    left?[frame] = s * gain
                    right?[frame] = s * gain
                }
            }
            return noErr
        }
        
        guard let node = sourceNode else { return }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.prepare()
        
        do {
            try engine.start()
            engineRunning = true
        } catch {
            print("Error starting ambience engine: \(error)")
        }
    }
    
    func stop() {
        engine.stop()
        engineRunning = false
        sourceNode = nil
        currentAmbienceKey = "none"
    }
    
    func setVolume(_ volume: Float) {
        currentGain = volume
    }
}
// MARK: - App Usage Tracker
class AppUsageTracker: ObservableObject {
    @Published var currentApp: String = ""
    @Published var appUsage: [String: Int] = [:]
    private var timer: Timer?
    private var lastApp: String = ""
    
    init() {
        startTracking()
    }
    
    func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateCurrentApp()
        }
    }
    
    private func updateCurrentApp() {
        if let app = NSWorkspace.shared.frontmostApplication?.localizedName {
            currentApp = app
            if app != lastApp {
                appUsage[app, default: 0] += 5
                lastApp = app
            }
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
    }
    
    func getTopApps(limit: Int = 5) -> [(String, Int)] {
        appUsage.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
}

// MARK: - Distraction Blocker
class DistractionBlocker: ObservableObject {
    @Published var isBlocking: Bool = false
    private var blockedApps: [String] = []
    
    func startBlocking(apps: [String]) {
        blockedApps = apps
        isBlocking = true
    }
    
    func stopBlocking() {
        isBlocking = false
        blockedApps = []
    }
}

// MARK: - Calendar Manager
class CalendarManager: ObservableObject {
    @Published var upcomingEvents: [CalendarEvent] = []
    
    struct CalendarEvent: Identifiable {
        let id = UUID()
        var title: String
        var startDate: Date
        var endDate: Date
    }
    
    func fetchUpcomingEvents() {
        upcomingEvents = []
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleNotification(title: String, subtitle: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func silenceNotifications(_ silence: Bool) {}
}

// MARK: - Weekly Review Generator
struct WeeklyReview {
    let weekStart: Date
    let totalMinutes: Int
    let sessionsCompleted: Int
    let goalsCompleted: Int
    let topApps: [(String, Int)]
    let moodAverage: Double
    let achievements: [String]
    let insights: [String]
    let letter: String
    
    static func generate(from sessions: [StudySession], stats: [String: DailyStats]) -> WeeklyReview {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: Date())
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        let sessionsCompleted = sessions.count
        let goalsCompleted = sessions.reduce(0) { $0 + $1.goals.filter { $0.isCompleted }.count }
        
        var appUsage: [String: Int] = [:]
        sessions.forEach { session in
            session.appsUsed.forEach { app in
                appUsage[app, default: 0] += session.duration
            }
        }
        let topApps = appUsage.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        
        let moods = sessions.compactMap { $0.mood }
        let moodAverage = moods.isEmpty ? 3.0 : Double(moods.reduce(0, +)) / Double(moods.count)
        
        var achievements: [String] = []
        if totalMinutes > 300 { achievements.append("Completed 5+ hours of focused work") }
        if sessionsCompleted >= 10 { achievements.append("Completed 10+ sessions") }
        if goalsCompleted >= 5 { achievements.append("Achieved 5+ goals") }
        
        var insights: [String] = []
        if let topApp = topApps.first {
            insights.append("Most productive app: \(topApp.0) (\(topApp.1 / 60)h)")
        }
        insights.append("Average mood: \(String(format: "%.1f", moodAverage))/5")
        
        let letter = Self.composeLetter(
            totalMinutes: totalMinutes,
            sessionsCompleted: sessionsCompleted,
            goalsCompleted: goalsCompleted,
            topApps: topApps,
            moodAverage: moodAverage
        )
        
        return WeeklyReview(
            weekStart: weekStart,
            totalMinutes: totalMinutes,
            sessionsCompleted: sessionsCompleted,
            goalsCompleted: goalsCompleted,
            topApps: topApps,
            moodAverage: moodAverage,
            achievements: achievements,
            insights: insights,
            letter: letter
        )
    }
    
    // A short, honest letter from the practice to its reader.
    static func composeLetter(totalMinutes: Int, sessionsCompleted: Int, goalsCompleted: Int, topApps: [(String, Int)], moodAverage: Double) -> String {
        let moodWord: String
        switch moodAverage {
        case 4.5...: moodWord = "light"
        case 3.5..<4.5: moodWord = "steady"
        case 2.5..<3.5: moodWord = "weathered"
        default: moodWord = "heavy"
        }
        let appLine = topApps.first.map { "You gave your best hours to \($0.0)." } ?? "The hours went somewhere quiet."
        let pace = sessionsCompleted >= 7 ? "You returned often" : (sessionsCompleted >= 4 ? "You came back a few times" : "You visited rarely")
        let goalLine = goalsCompleted > 0 ? "\(goalsCompleted) goals were closed." : "No goals closed this week."
        
        return """
        This week you practised.
        \(totalMinutes) minutes in \(sessionsCompleted) sittings, with a \(moodWord) mood through it. \(pace). \(appLine) \(goalLine)
        The seal does not judge the streak. It notices the returning.
        """
    }
}

// MARK: - Vault Manager
class VaultManager: ObservableObject {
    @Published var vaultURL: URL?
    @Published var sessions: [StudySession] = []
    @Published var notes: [Note] = []
    @Published var quotes: [Quote] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var dailyStats: [String: DailyStats] = [:]
    @Published var schedule: [ScheduleEvent] = []
    @Published var habits: [Habit] = []
    @Published var todayMood: Int = 3
    @Published var currentTheme: AppTheme = .sumi
    
    let appUsageTracker = AppUsageTracker()
    let calendarManager = CalendarManager()
    let notificationManager = NotificationManager()
    let distractionBlocker = DistractionBlocker()
    let audioPlayerManager = AudioPlayerManager()
    
    var theme: ThemeColors {
        currentTheme.colors
    }
    
    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleSessionCompleted(_:)),
            name: .sessionCompleted, object: nil
        )
    }

    @objc private func handleSessionCompleted(_ notification: Notification) {
        if let session = notification.object as? StudySession {
            addSession(session)
        }
    }

    func chooseVaultFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder for your Sumi vault (iCloud Drive folders sync automatically)"
        if panel.runModal() == .OK, let url = panel.url {
            vaultURL = url
            loadAllData()
            return url
        }
        return nil
    }
    
    func loadAllData() {
        guard let url = vaultURL else { return }
        sessions = loadJSON("sessions.json", from: url) ?? []
        notes = loadJSON("notes.json", from: url) ?? []
        quotes = loadJSON("quotes.json", from: url) ?? defaultQuotes
        settings = loadJSON("settings.json", from: url) ?? AppSettings()
        dailyStats = loadJSON("stats.json", from: url) ?? [:]
        schedule = loadJSON("schedule.json", from: url) ?? []
        habits = loadJSON("habits.json", from: url) ?? []
        
        currentTheme = settings.theme
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        todayMood = dailyStats[key]?.mood ?? 3
    }
    
    func saveAllData() {
        guard let url = vaultURL else { return }
        saveJSON(sessions, to: url, filename: "sessions.json")
        saveJSON(notes, to: url, filename: "notes.json")
        saveJSON(quotes, to: url, filename: "quotes.json")
        saveJSON(settings, to: url, filename: "settings.json")
        saveJSON(dailyStats, to: url, filename: "stats.json")
        saveJSON(schedule, to: url, filename: "schedule.json")
        saveJSON(habits, to: url, filename: "habits.json")
    }
    
    func addSession(_ session: StudySession) {
        sessions.append(session)
        updateDailyStats(for: session)
        saveAllData()
        
        if #available(macOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func deleteSession(_ session: StudySession) {
        sessions.removeAll { $0.id == session.id }
        saveAllData()
    }
    
    private func updateDailyStats(for session: StudySession) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: session.date)
        if var stats = dailyStats[dateKey] {
            stats.totalMinutes += session.duration
            stats.sessions.append(session)
            if let mood = session.mood { stats.mood = mood }
            stats.completedGoals += session.goals.filter { $0.isCompleted }.count
            dailyStats[dateKey] = stats
        } else {
            dailyStats[dateKey] = DailyStats(date: dateKey, totalMinutes: session.duration, mood: session.mood ?? 3, sessions: [session])
        }
    }
    
    func recomputeDailyStats() {
        var rebuilt: [String: DailyStats] = [:]
        for session in sessions { updateDailyStatsInto(&rebuilt, session) }
        dailyStats = rebuilt
    }
    
    private func updateDailyStatsInto(_ into: inout [String: DailyStats], _ session: StudySession) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: session.date)
        if var stats = into[dateKey] {
            stats.totalMinutes += session.duration
            stats.sessions.append(session)
            if let mood = session.mood { stats.mood = mood }
            stats.completedGoals += session.goals.filter { $0.isCompleted }.count
            into[dateKey] = stats
        } else {
            into[dateKey] = DailyStats(date: dateKey, totalMinutes: session.duration, mood: session.mood ?? 3, sessions: [session])
        }
    }
    
    func setTodayMood(_ mood: Int) {
        todayMood = mood
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        if var stats = dailyStats[key] {
            stats.mood = mood
            dailyStats[key] = stats
        } else {
            dailyStats[key] = DailyStats(date: key, totalMinutes: 0, mood: mood, sessions: [])
        }
        saveAllData()
    }
    
    func toggleHabitCompletion(_ habit: Habit) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            if updatedHabit.completedDates.contains(today) {
                updatedHabit.completedDates.removeAll { $0 == today }
                updatedHabit.streak = max(0, updatedHabit.streak - 1)
            } else {
                updatedHabit.completedDates.append(today)
                updatedHabit.streak += 1
            }
            habits[index] = updatedHabit
            saveAllData()
        }
    }
    
    func getStreak() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var streak = 0
        var date = Date()
        while true {
            let key = formatter.string(from: date)
            if let stats = dailyStats[key], stats.totalMinutes > 0 {
                streak += 1
                if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date) { date = prevDate } else { break }
            } else { break }
        }
        return streak
    }
    
    // Streak mercy (ADR-005, C4): every 7 consecutive focus days earns one freeze;
    // a missed day consumes a freeze and the count keeps counting. The strict
    // streak is also exposed for stats.
    func effectiveStreak() -> Int {
        guard settings.streakMercy else { return getStreak() }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var streak = 0
        var freezes = 0
        var date = Date()
        while true {
            let key = formatter.string(from: date)
            if let stats = dailyStats[key], stats.totalMinutes > 0 {
                streak += 1
                if streak % 7 == 0 { freezes += 1 }
            } else if freezes > 0 {
                freezes -= 1
                streak += 1
            } else { break }
            guard let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prevDate
        }
        return streak
    }
    
    // Days where the daily goal was met (planned vs actual, C3).
    func daysAtGoal() -> Int {
        dailyStats.values.filter { $0.totalMinutes >= settings.dailyGoal }.count
    }
    
    func addNote(title: String, content: String) {
        let note = Note(id: UUID(), title: title, content: content, date: Date())
        notes.insert(note, at: 0)
        saveAllData()
    }
    
    func getTotalHours() -> Double { return Double(sessions.reduce(0) { $0 + $1.duration }) / 60.0 }
    
    func getMilestone() -> (title: String, progress: Double) {
        let hours = getTotalHours()
        let milestones: [(Double, String)] = [(10, "First Steps"), (50, "Deep Roots"), (100, "Steady Growth"), (500, "Old Growth"), (1000, "Ten Thousand Hours")]
        for (target, name) in milestones {
            if hours < target {
                let prev = milestones.first(where: { $0.0 < hours })?.0 ?? 0
                let progress = (hours - prev) / (target - prev)
                return (name, progress)
            }
        }
        return ("Master", 1.0)
    }
    
    func exportToObsidian() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.folder]
        
        if panel.runModal() == .OK, let url = panel.url {
            for note in notes {
                let content = "# \(note.title)\n\n\(note.content)\n\nCreated: \(note.date.formatted())"
                let fileURL = url.appendingPathComponent("\(note.title).md")
                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }
    
    func exportToNotion() {
        print("Export to Notion - API integration needed")
    }
    
    func exportCSV() -> URL? {
        guard vaultURL != nil else { return nil }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "sumi_export_\(Date().timeIntervalSince1970).csv"
        
        if panel.runModal() == .OK, let saveURL = panel.url {
            var csv = "Date,Subject,Duration (min),Type,Mood,Apps Used,Goals\n"
            for session in sessions {
                let dateStr = session.date.formatted(date: .abbreviated, time: .shortened)
                let apps = session.appsUsed.joined(separator: ";")
                let goals = session.goals.filter { $0.isCompleted }.map { $0.title }.joined(separator: ";")
                csv += "\(dateStr),\(session.subject),\(session.duration),\(session.type),\(session.mood ?? 0),\(apps),\(goals)\n"
            }
            try? csv.write(to: saveURL, atomically: true, encoding: .utf8)
            return saveURL
        }
        return nil
    }
    
    func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        
        if panel.runModal() == .OK, let url = panel.url {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
            let lines = content.components(separatedBy: "\n").dropFirst()
            
            for line in lines {
                let parts = line.components(separatedBy: ",")
                guard parts.count >= 4 else { continue }
                
                let session = StudySession(
                    id: UUID(),
                    subject: parts[1],
                    duration: Int(parts[2]) ?? 0,
                    date: Date(),
                    type: parts[3],
                    mood: parts.count > 4 ? Int(parts[4]) : nil,
                    appsUsed: parts.count > 5 ? parts[5].components(separatedBy: ";") : [],
                    goals: []
                )
                sessions.append(session)
            }
            saveAllData()
        }
    }
    
    func changeTheme(_ newTheme: AppTheme) {
        currentTheme = newTheme
        settings.theme = newTheme
        saveAllData()
    }
    
    private func loadJSON<T: Decodable>(_ filename: String, from url: URL) -> T? {
        let fileURL = url.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func saveJSON<T: Encodable>(_ data: T, to url: URL, filename: String) {
        let fileURL = url.appendingPathComponent(filename)
        if let jsonData = try? JSONEncoder().encode(data) { try? jsonData.write(to: fileURL) }
    }
    
    var defaultQuotes: [Quote] {
        [
            Quote(id: UUID(), text: "The ink remembers every stroke.", author: "Sumi"),
            Quote(id: UUID(), text: "Calm attention compounds in silence.", author: "Sumi"),
            Quote(id: UUID(), text: "Rest is part of the path.", author: "Sumi"),
            Quote(id: UUID(), text: "Focus is the new superpower.", author: "Cal Newport"),
            Quote(id: UUID(), text: "The mind is everything. What you think you become.", author: "Buddha"),
            Quote(id: UUID(), text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci"),
            Quote(id: UUID(), text: "Do one thing every day that scares you.", author: "Eleanor Roosevelt"),
            Quote(id: UUID(), text: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        ]
    }
    
    var moodLabels: [String] { ["Heavy", "Low", "Steady", "Clear", "Bright"] }
}

// MARK: - Timer Manager
class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var timeRemaining: Int = 25 * 60
    @Published var mode: TimerMode = .pomodoro
    @Published var totalTime: Int = 0
    @Published var subject: String = "Focus"
    @Published var currentQuote: Quote?
    @Published var appsUsed: [String] = []
    @Published var focusGoals: [FocusGoal] = []
    @Published var breakSuggestion: String = ""
    @Published var sessionLength: Int = 25 * 60
    @Published var awaySeconds: Int = 0
    @Published var awayApp: String?
    @Published var isBreathing = false
    @Published var breatheRemaining = 0
    var quotePool: [Quote] = []
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleToggle), name: .toggleTimer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReset), name: .resetTimer, object: nil)
    }
    
    @objc func handleToggle() { toggle() }
    @objc func handleReset() { reset() }
    
    private var timer: Timer?
    private var quoteTimer: Timer?
    private var breatheTimer: Timer?
    private var appUsageTracker: AppUsageTracker?
    private var workspaceObserver: NSObjectProtocol?
    
    enum TimerMode {
        case pomodoro, flow
    }
    
    var formattedTime: String {
        if mode == .flow {
            let hours = totalTime / 3600
            let minutes = (totalTime % 3600) / 60
            let seconds = totalTime % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        if mode == .flow { return 0 }
        let total = sessionLength
        return Double(total - timeRemaining) / Double(total)
    }
    
    var statusText: String {
        mode == .flow ? "Flowing Quietly" : "Breathe In · Study · Breathe Out"
    }
    
    func syncSessionLength(minutes: Int) {
        sessionLength = minutes * 60
        if !isRunning, mode == .pomodoro, timeRemaining == 25 * 60 {
            timeRemaining = sessionLength
        }
    }
    
    func toggle() {
        if isBreathing {
            cancelBreathing()
            start()
            return
        }
        if isRunning {
            pause(recordIncomplete: mode == .flow)
        } else {
            start()
        }
    }
    
    func start() {
        cancelBreathing()
        isRunning = true
        appsUsed = []
        awaySeconds = 0
        awayApp = nil
        appUsageTracker = AppUsageTracker()
        generateBreakSuggestion()
        startAwayTracking()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        startQuoteRotation()
    }
    
    func pause(recordIncomplete: Bool = false) {
        isRunning = false
        timer?.invalidate()
        quoteTimer?.invalidate()
        stopAwayTracking()
        appUsageTracker?.stopTracking()
        if let tracker = appUsageTracker {
            appsUsed = Array(tracker.appUsage.keys)
        }
        if recordIncomplete, mode == .flow, totalTime >= 300 {
            recordSession(duration: totalTime)
            resetCounters(for: .flow)
        }
    }
    
    func reset() {
        pause()
        timeRemaining = sessionLength
        totalTime = 0
        appsUsed = []
        focusGoals = []
        awaySeconds = 0
        awayApp = nil
    }
    
    func startQuickTimer(minutes: Int) {
        reset()
        mode = .pomodoro
        sessionLength = minutes * 60
        timeRemaining = minutes * 60
        start()
    }
    
    private func tick() {
        if mode == .pomodoro {
            if timeRemaining > 0 { timeRemaining -= 1 }
            else { completePomodoro() }
        } else {
            totalTime += 1
        }
    }
    
    // A completed pomodoro: stop, log the session, then breathe before the next.
    private func completePomodoro() {
        let duration = sessionLength
        pause()
        recordSession(duration: duration)
        if settingsAutoContinue {
            startBreathingGap()
        }
    }
    
    private var settingsAutoContinue: Bool {
        UserDefaults.standard.bool(forKey: "autoContinuePomodoro")
    }
    
    private func startBreathingGap() {
        isBreathing = true
        breatheRemaining = UserDefaults.standard.integer(forKey: "breatheGapSeconds") > 0
            ? UserDefaults.standard.integer(forKey: "breatheGapSeconds")
            : 30
        breatheTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.breatheRemaining -= 1
            if self.breatheRemaining <= 0 {
                self.breatheRemaining = 0
                self.cancelBreathing()
                self.start()
            }
        }
    }
    
    private func cancelBreathing() {
        isBreathing = false
        breatheRemaining = 0
        breatheTimer?.invalidate()
        breatheTimer = nil
    }
    
    private func resetCounters(for mode: TimerMode) {
        if mode == .flow { totalTime = 0 }
    }
    
    // A completed (or meaningfully progressed) session is logged to the vault.
    private func recordSession(duration: Int) {
        guard duration >= 60 else { return }
        let minutes = duration / 60
        let session = StudySession(
            id: UUID(),
            subject: subject,
            duration: minutes,
            date: Date(),
            type: mode == .pomodoro ? "pomodoro" : "flow",
            mood: nil,
            appsUsed: appsUsed,
            goals: focusGoals,
            awayMinutes: awaySeconds > 0 ? awaySeconds / 60 : nil
        )
        NotificationCenter.default.post(name: .sessionCompleted, object: session)
    }
    
    // C1 — notice when the user switches to a non-Sumi app mid-focus. Uses only
    // the "active app changed" notification (no screen content, no permission).
    private func startAwayTracking() {
        awaySeconds = 0
        awayApp = nil
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let self, self.isRunning else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let name = app.localizedName,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier,
                  name != "Finder"
            else { return }
            self.awayApp = name
        }
        awayTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.isRunning else { return }
            if let app = self.awayApp, self.isAppFrontmost(appName: app) {
                self.awaySeconds += 1
            }
        }
    }
    
    private func isAppFrontmost(appName: String) -> Bool {
        NSWorkspace.shared.frontmostApplication?.localizedName == appName
    }
    
    private func stopAwayTracking() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObserver = nil
        awayTrackingTimer?.invalidate()
        awayTrackingTimer = nil
        awayApp = nil
    }
    
    private var awayTrackingTimer: Timer?
    
    private func startQuoteRotation() {
        quoteTimer?.invalidate()
        rotateQuote()
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 18, repeats: true) { [weak self] _ in
            self?.rotateQuote()
        }
    }
    
    func rotateQuote() {
        let pool = quotePool.isEmpty ? VaultManager().defaultQuotes : quotePool
        currentQuote = pool.randomElement()
    }
    
    func generateBreakSuggestion() {
        let base = [
            "Take a 5-minute walk outside",
            "Do some stretching exercises",
            "Practice deep breathing for 2 minutes",
            "Drink a glass of water",
            "Look at something 20 feet away for 20 seconds",
            "Do 10 push-ups or squats",
            "Meditate for 3 minutes",
            "Write down three things you're grateful for"
        ]
        breakSuggestion = base.randomElement() ?? "Take a short break"
    }
    
    func addGoal(_ goal: FocusGoal) {
        focusGoals.append(goal)
    }
    
    func toggleGoal(_ goal: FocusGoal) {
        if let index = focusGoals.firstIndex(where: { $0.id == goal.id }) {
            focusGoals[index].isCompleted.toggle()
        }
    }
    
    func removeGoal(_ goal: FocusGoal) {
        focusGoals.removeAll { $0.id == goal.id }
    }
}

// MARK: - Global Hotkey Manager
class GlobalHotkeyManager: ObservableObject {
    private var eventMonitor: Any?
    
    func startMonitoring(action: @escaping (NSEvent) -> Void) {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            action(event)
        }
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - Enso Logo
struct EnsoLogo: View {
    var body: some View {
        Path { path in
            path.addArc(center: CGPoint(x: 12, y: 12), radius: 10, startAngle: .degrees(45), endAngle: .degrees(375), clockwise: false)
        }
        .stroke(Zen.seal, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(width: 24, height: 24)
    }
}

// MARK: - Grid Pattern
struct GridPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let gridSize: CGFloat = 28
            Path { path in
                for x in stride(from: 0, through: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for y in stride(from: 0, through: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Zen.divider.opacity(0.4), lineWidth: 0.5)
        }
    }
}

// MARK: - Zen Theme
struct Zen {
    static var paper: Color { AppTheme.sumi.colors.background }
    static var paperDark: Color { AppTheme.sumi.colors.sidebar }
    static var ink: Color { AppTheme.sumi.colors.textPrimary }
    static var inkLight: Color { AppTheme.sumi.colors.textSecondary }
    static var moss: Color { AppTheme.sumi.colors.accent }
    static var seal: Color { AppTheme.sumi.colors.seal }
    static var divider: Color { AppTheme.sumi.colors.divider }
    static var warm: Color { AppTheme.sumi.colors.warm }
    static var buttonBackground: Color { AppTheme.sumi.colors.buttonBackground }
    static var buttonText: Color { AppTheme.sumi.colors.buttonText }
}

// Seasonal accent rotation — the Sumi web app shifts its accent + washes by
// season (dec/oct→day-of-month rules from the site: Dec-Feb winter, Mar-May
// spring, Jun-Aug summer, Sep-Nov autumn). Dark-palette values verbatim.
enum SumiSeason {
    case winter, spring, summer, autumn
    
    static var current: SumiSeason {
        let m = Calendar.current.component(.month, from: Date())
        switch m {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        default: return .autumn
        }
    }
    
    var accent: Color {
        switch self {
        case .winter: return Color(red: 0.576, green: 0.639, blue: 0.694)
        case .spring: return Color(red: 0.612, green: 0.671, blue: 0.525)
        case .summer: return Color(red: 0.592, green: 0.663, blue: 0.549)
        case .autumn: return Color(red: 0.753, green: 0.553, blue: 0.353)
        }
    }
    
    var washAccent: Color {
        switch self {
        case .winter: return Color(red: 0.576, green: 0.639, blue: 0.694)
        case .spring: return Color(red: 0.612, green: 0.671, blue: 0.525)
        case .summer: return Color(red: 0.592, green: 0.663, blue: 0.549)
        case .autumn: return Color(red: 0.753, green: 0.553, blue: 0.353)
        }
    }
    
    var washRust: Color {
        switch self {
        case .winter: return Color(red: 0.576, green: 0.639, blue: 0.694)
        case .spring: return Color(red: 0.839, green: 0.627, blue: 0.667)
        case .summer: return Color(red: 0.831, green: 0.667, blue: 0.353)
        case .autumn: return Color(red: 0.831, green: 0.471, blue: 0.275)
        }
    }
}

// Slow-drifting radial washes behind the content — the web app's animated
// multi-plate radial-gradient backdrop. Sumi-only.
struct DriftWashView: View {
    let theme: ThemeColors
    @State private var drifting = false
    
    var body: some View {
        GeometryReader { g in
            let s = SumiSeason.current
            ZStack {
                RadialGradient(
                    colors: [s.washAccent.opacity(0.10), .clear],
                    center: .init(x: 0.22, y: 0.24),
                    startRadius: 0, endRadius: g.size.width * 0.75
                )
                RadialGradient(
                    colors: [s.washRust.opacity(0.08), .clear],
                    center: .init(x: 0.82, y: 0.78),
                    startRadius: 0, endRadius: g.size.width * 0.7
                )
                RadialGradient(
                    colors: [s.washAccent.opacity(0.07), .clear],
                    center: .init(x: 0.74, y: 0.14),
                    startRadius: 0, endRadius: g.size.width * 0.6
                )
            }
            .scaleEffect(drifting ? 1.06 : 1.0)
            .offset(x: drifting ? -12 : 10, y: drifting ? 10 : -8)
            .animation(
                .easeInOut(duration: 45).repeatForever(autoreverses: true),
                value: drifting
            )
            .onAppear { drifting = true }
            .allowsHitTesting(false)
        }
    }
}

// Fine film-grain overlay (fractal-noise style at ~4.5% opacity), the web
// app's fixed noise layer. Sumi-only.
struct GrainView: View {
    let theme: ThemeColors
    
    var body: some View {
        Canvas { context, size in
            var rng = SeedRandom(seed: 0x13579BDF)
            for _ in 0..<6000 {
                let x = rng.next() * size.width
                let y = rng.next() * size.height
                let light = rng.next() < 0.5
                let alpha = 0.10 + rng.next() * 0.12
                let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                context.fill(
                    Path(rect),
                    with: .color(.white.opacity(light ? alpha * 0.5 : alpha * 0.35))
                )
            }
        }
        .blendMode(.plusLighter)
        .opacity(0.5)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct SeedRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state &+= 0xA0761D6478BD642F
        let mix = (state ^ (state >> 29)) &* 0xBF58476D1CE4E5B9
        return Double((mix & 0x00FFFFFFFFFFFFFF) >> 10) / Double(0x10000000000000)
    }
}

// MARK: - Custom Segmented Picker
struct ZenSegmentedPicker: View {
    @Binding var selection: TimerManager.TimerMode
    let options: [(TimerManager.TimerMode, String)]
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = option.0
                    }
                } label: {
                    Text(option.1)
                        .font(DesignSystem.font(DesignSystem.typeBody(), weight: selection == option.0 ? .medium : .regular))
                        .foregroundColor(selection == option.0 ? vault.theme.textPrimary : vault.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.radiusChip())
                                .fill(selection == option.0 ? vault.theme.card : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.spaceXS())
        .background(vault.theme.sidebar)
        .cornerRadius(DesignSystem.radiusControl())
    }
}

// MARK: - Main Content
struct ContentView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("zenMode") private var zenMode = false
    @State private var selectedDestination: Destination = .focus
    @State private var showingMoodCheckIn = false
    @State private var showingMenuBarInfo = false
    @EnvironmentObject var vault: VaultManager
    @EnvironmentObject var timerManager: TimerManager
    
    init() {
        NotificationCenter.default.addObserver(forName: .toggleZen, object: nil, queue: .main) { _ in
            let current = UserDefaults.standard.bool(forKey: "zenMode")
            withAnimation(.easeInOut) {
                UserDefaults.standard.set(!current, forKey: "zenMode")
            }
        }
    }
    
    enum Destination: String, CaseIterable, Identifiable {
        case focus = "Focus"
        case stats = "Stats"
        case notes = "Notes"
        case schedule = "Schedule"
        case habits = "Habits"
        case weeklyReview = "Weekly Review"
        case settings = "Settings"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .focus: return "play.circle"
            case .stats: return "chart.bar.xaxis"
            case .notes: return "note.text"
            case .schedule: return "calendar"
            case .habits: return "checkmark.circle"
            case .weeklyReview: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }
    }
    
    var studyDestinations: [Destination] { [.focus, .stats, .notes, .schedule, .habits, .weeklyReview, .settings] }
    
    var body: some View {
        Group {
            if !hasCompletedSetup {
                OnboardingView(hasCompletedSetup: $hasCompletedSetup, vault: vault)
            } else {
                MainAppView(
                    selectedDestination: $selectedDestination,
                    vault: vault,
                    timerManager: timerManager,
                    zenMode: $zenMode,
                    showingMoodCheckIn: $showingMoodCheckIn,
                    showingMenuBarInfo: $showingMenuBarInfo,
                    currentDestinations: studyDestinations
                )
                .environmentObject(vault)
                .environmentObject(timerManager)
            }
        }
        .frame(minWidth: 1000, minHeight: 650)
        .background(vault.theme.background)
        .tint(vault.theme.accent)
        .onAppear {
            if hasCompletedSetup && vault.dailyStats.isEmpty == false {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let key = formatter.string(from: Date())
                if vault.dailyStats[key] == nil {
                    showingMoodCheckIn = true
                }
            }
        }
    }
}

struct MainAppView: View {
    @Binding var selectedDestination: ContentView.Destination
    @ObservedObject var vault: VaultManager
    @ObservedObject var timerManager: TimerManager
    @Binding var zenMode: Bool
    @Binding var showingMoodCheckIn: Bool
    @Binding var showingMenuBarInfo: Bool
    let currentDestinations: [ContentView.Destination]
    @State private var showingQuickTimer = false

    // Zen = the sidebar column collapses entirely (.detailOnly), not just its text.
    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { zenMode ? .detailOnly : .doubleColumn },
            set: { _ in }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            SidebarView(
                selectedDestination: $selectedDestination,
                showingQuickTimer: $showingQuickTimer,
                showingMenuBarInfo: $showingMenuBarInfo,
                currentDestinations: currentDestinations
            )
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
            .transition(.move(edge: .leading))
        } detail: {
            ZStack {
                vault.theme.background.ignoresSafeArea()
                
                if vault.theme.serifDisplay {
                    DriftWashView(theme: vault.theme).ignoresSafeArea()
                    GrainView(theme: vault.theme)
                }
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        if showingMenuBarInfo {
                            Text("Menu Bar Active")
                                .font(DesignSystem.font(11))
                                .foregroundColor(vault.theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(vault.theme.warm)
                                .cornerRadius(DesignSystem.radiusChip())
                        }
                        
                        Button(action: { withAnimation(.easeInOut) { zenMode.toggle() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: zenMode ? "eye.slash" : "eye")
                                    .font(DesignSystem.font(12))
                                Text(zenMode ? "Zen" : "Normal")
                                    .font(DesignSystem.font(12))
                            }
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(vault.theme.sidebar)
                            .cornerRadius(DesignSystem.radiusChip())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    
                    switch selectedDestination {
                    case .focus: FocusRoomView()
                    case .stats: StatsRoomView()
                    case .notes: NotesRoomView()
                    case .schedule: ScheduleRoomView()
                    case .habits: HabitsRoomView()
                    case .weeklyReview: WeeklyReviewView()
                    case .settings: SettingsRoomView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedDestination)
            .animation(.easeInOut(duration: 0.3), value: zenMode)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Sumi")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { withAnimation(.easeInOut) { zenMode.toggle() } }) {
                    Label(zenMode ? "Zen On" : "Zen Off", systemImage: zenMode ? "moon.stars.fill" : "moon")
                }
                .help("Toggle Zen Mode")
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingQuickTimer = true }) {
                    Label("Quick Timer", systemImage: "timer")
                }
                .help("Start a quick focus timer")
            }
        }
        .toolbarBackground(vault.theme.background, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .sheet(isPresented: $showingQuickTimer) {
            QuickTimerSheet()
                .frame(width: 400, height: 320)
        }
        .sheet(isPresented: $showingMoodCheckIn) {
            MoodCheckInSheet()
                .frame(width: 400, height: 300)
        }
        .onAppear {
            timerManager.quotePool = vault.quotes
        }
        .onChange(of: vault.quotes) { _, newQuotes in
            timerManager.quotePool = newQuotes
        }
    }
}

struct SidebarView: View {
    @Binding var selectedDestination: ContentView.Destination
    @Binding var showingQuickTimer: Bool
    @Binding var showingMenuBarInfo: Bool
    let currentDestinations: [ContentView.Destination]
    @EnvironmentObject var vault: VaultManager

    var body: some View {
        List(selection: $selectedDestination) {
            Section {
                ForEach(currentDestinations) { destination in
                    Label(destination.rawValue, systemImage: destination.icon)
                        .font(DesignSystem.font(DesignSystem.typeSmall()))
                        .tag(destination)
                }
            } header: {
                Text("VIEWS")
                    .font(DesignSystem.font(DesignSystem.typeCaption()))
                    .foregroundColor(vault.theme.textSecondary)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider().background(vault.theme.divider)
                HStack(spacing: DesignSystem.spaceS()) {
                    Text("\(todayMinutes)m today")
                        .font(DesignSystem.font(DesignSystem.typeCaption()))
                        .foregroundColor(vault.theme.textSecondary)
                    Spacer()
                    Button(action: { showingQuickTimer = true }) {
                        Label("Quick Timer", systemImage: "timer")
                            .font(DesignSystem.font(DesignSystem.typeSmall()))
                            .foregroundColor(vault.theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.spaceM())
                .padding(.vertical, DesignSystem.spaceS())
            }
            .background(vault.theme.sidebar)
        }
    }

    var todayMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        return vault.dailyStats[key]?.totalMinutes ?? 0
    }

    var todayProgress: Double {
        min(Double(todayMinutes) / Double(vault.settings.dailyGoal), 1.0)
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(DesignSystem.font(14))
                    .frame(width: 20)
                Text(title)
                    .font(DesignSystem.font(13, weight: isSelected ? .medium : .regular))
                Spacer()
            }
            .foregroundColor(isSelected ? vault.theme.textPrimary : vault.theme.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? vault.theme.warm : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Focus Hero Portrait (minimal surface)
// The single warm surface in the Focus room: today's minutes as a system-sans
// stat, white card, hairline stroke, soft shadow. Pure display, zero state.
struct FocusHeroTile: View {
    @EnvironmentObject var vault: VaultManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: DesignSystem.spaceM()) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today".uppercased())
                        .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                        .kerning(0.6)
                        .foregroundColor(vault.theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.spaceXS()) {
                        Text("\(todayMinutes)")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: DesignSystem.typeHero(), weight: .medium))
                            .monospacedDigit()
                            .foregroundColor(vault.theme.textPrimary)
                        Text("min")
                            .font(DesignSystem.font(DesignSystem.typeBody()))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    Text("of \(vault.settings.dailyGoal) min goal")
                        .font(DesignSystem.font(DesignSystem.typeSmall()))
                        .foregroundColor(vault.theme.textSecondary)
                }

                Spacer(minLength: DesignSystem.spaceM())

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Streak".uppercased())
                        .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                        .kerning(0.6)
                        .foregroundColor(vault.theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.spaceXS()) {
                        Text("\(vault.effectiveStreak())")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: DesignSystem.typeTitle(), weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(vault.theme.accent)
                        Text("days")
                            .font(DesignSystem.font(DesignSystem.typeCaption()))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                }
            }

            BranchView(streak: vault.effectiveStreak(), theme: vault.theme)

            MoodDotsRow(theme: vault.theme)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(vault.theme)
    }

    var todayMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        return vault.dailyStats[key]?.totalMinutes ?? 0
    }
}

// Branch-and-bloom streak flourish (Sumi web app): an ink branch that grows a
// rust blossom for each day of the streak, with a dashed bud for the next.
struct BranchView: View {
    let streak: Int
    let theme: ThemeColors

    // Web app BRANCH_PTS — one blossom site per streak day, head to tail.
    private static let points: [CGPoint] = [
        CGPoint(x: 16, y: 66), CGPoint(x: 36, y: 58), CGPoint(x: 56, y: 52),
        CGPoint(x: 76, y: 45), CGPoint(x: 96, y: 40), CGPoint(x: 116, y: 35),
        CGPoint(x: 136, y: 32), CGPoint(x: 156, y: 28), CGPoint(x: 176, y: 26),
        CGPoint(x: 196, y: 23), CGPoint(x: 214, y: 20), CGPoint(x: 228, y: 16)
    ]

    var body: some View {
        let blossoms = min(streak, BranchView.points.count)
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                BranchPath()
                    .stroke(theme.textSecondary.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 240, height: 76)
                    .fixedSize()

                ForEach(0..<blossoms, id: \.self) { i in
                    let p = BranchView.points[i]
                    if i == blossoms - 1 && blossoms >= 7 {
                        Circle()
                            .stroke(theme.seal.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                            .position(x: p.x + 3, y: p.y + 3)
                    }
                    Circle()
                        .fill(theme.seal)
                        .frame(width: 14, height: 14)
                        .position(x: p.x + 3, y: p.y + 3)
                }

                if blossoms < BranchView.points.count {
                    let p = BranchView.points[blossoms]
                    Circle()
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 14, height: 14)
                        .position(x: p.x + 3, y: p.y + 3)
                }
            }
            .frame(width: 240, height: 76, alignment: .topLeading)
            .padding(.top, 2)

            Text(blossomCaption)
                .font(DesignSystem.font(10))
                .foregroundColor(theme.textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blossomCaption: String {
        if streak <= 0 { return "A bare branch — today begins the bloom." }
        if streak >= BranchView.points.count { return "Full bloom — your streak is flourishing." }
        return "One blossom for each day of your streak."
    }
}

// The web app's mood line: five dots, sized by brightness, plus the mood word.
struct MoodDotsRow: View {
    let theme: ThemeColors
    @EnvironmentObject var vault: VaultManager

    var body: some View {
        let key: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        let mood = vault.dailyStats[key]?.mood
        let moodLabel = mood.flatMap { v in vault.moodLabels.indices.contains(v) ? vault.moodLabels[v] : nil } ?? "—"

        HStack(spacing: 8) {
            Text("Mood".uppercased())
                .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                .kerning(0.6)
                .foregroundColor(theme.textSecondary)

            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < (mood.map { $0 + 1 } ?? 0) ? theme.seal : theme.divider.opacity(0.8))
                    .frame(width: 5 + CGFloat(i) * 1.8, height: 5 + CGFloat(i) * 1.8)
            }

            Text(moodLabel)
                .font(DesignSystem.displayFont(serif: theme.serifDisplay, size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .font(DesignSystem.font(DesignSystem.typeCaption()))
    }
}

struct BranchPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: 74))
        path.addCurve(to: CGPoint(x: 116, y: 36),
                      control1: CGPoint(x: 50, y: 62),
                      control2: CGPoint(x: 80, y: 50))
        path.addCurve(to: CGPoint(x: 234, y: 12),
                      control1: CGPoint(x: 150, y: 26),
                      control2: CGPoint(x: 190, y: 20))
        return path
    }
}

// MARK: - Focus Room with Goals
struct FocusRoomView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var vault: VaultManager
    @State private var showingAddGoal = false
    @State private var newGoalTitle = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FocusHeroTile()

                TimerDisplayView()

                VStack(alignment: .leading, spacing: DesignSystem.spaceS()) {
                    HStack(spacing: DesignSystem.spaceS()) {
                        Text("Focus Goals")
                            .font(DesignSystem.font(DesignSystem.typeSection(), weight: .medium))
                            .foregroundColor(vault.theme.textPrimary)
                        Spacer()
                        Button(action: { showingAddGoal = true }) {
                            Image(systemName: "plus")
                                .font(DesignSystem.font(DesignSystem.typeBody(), weight: .semibold))
                                .foregroundColor(vault.theme.textSecondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Add focus goal")
                    }

                    if timerManager.focusGoals.isEmpty {
                        Text("No goals set. Click + to add one.")
                            .font(DesignSystem.font(DesignSystem.typeSmall()))
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(timerManager.focusGoals) { goal in
                            HStack(spacing: DesignSystem.spaceS()) {
                                Button { timerManager.toggleGoal(goal) } label: {
                                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(DesignSystem.font(DesignSystem.typeBody()))
                                        .foregroundColor(goal.isCompleted ? vault.theme.accent : vault.theme.divider)
                                        .frame(width: 24, height: 24)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help(goal.isCompleted ? "Mark as not done" : "Mark as done")

                                Text(goal.title)
                                    .font(DesignSystem.font(DesignSystem.typeBody()))
                                    .strikethrough(goal.isCompleted)
                                    .foregroundColor(goal.isCompleted ? vault.theme.textSecondary : vault.theme.textPrimary)

                                Spacer()

                                Button { timerManager.removeGoal(goal) } label: {
                                    Image(systemName: "xmark")
                                        .font(DesignSystem.font(DesignSystem.typeSmall()))
                                        .foregroundColor(vault.theme.textSecondary.opacity(0.6))
                                        .frame(width: 24, height: 24)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help("Remove goal")
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .surface(vault.theme)

                if vault.settings.showQuotes, let quote = timerManager.currentQuote {
                    VStack(spacing: 6) {
                        Text("\"\(quote.text)\"")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: DesignSystem.typeSection(), weight: .regular))
                            .italic(!vault.theme.serifDisplay)
                            .foregroundColor(vault.theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Text(quote.author.uppercased())
                            .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                            .kerning(0.6)
                            .foregroundColor(vault.theme.textSecondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignSystem.spaceS())
                    .animation(.easeInOut(duration: 0.5), value: quote.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        timerManager.rotateQuote()
                    }
                    .help("Click for another")
                }

                if !timerManager.isRunning && timerManager.breakSuggestion.isEmpty == false {
                    VStack(alignment: .leading, spacing: DesignSystem.spaceXS()) {
                        Text("Smart Break Suggestion".uppercased())
                            .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                            .kerning(0.6)
                            .foregroundColor(vault.theme.textSecondary)
                        Text(timerManager.breakSuggestion)
                            .font(DesignSystem.font(DesignSystem.typeBody()))
                            .foregroundColor(vault.theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.spaceM())
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.radiusControl())
                            .fill(vault.theme.warm)
                    )
                }

                Spacer(minLength: 40)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(title: $newGoalTitle, timerManager: timerManager)
        }
    }
}

struct AddGoalSheet: View {
    @Binding var title: String
    @ObservedObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Focus Goal")
                .font(DesignSystem.font(DesignSystem.typeTitle(), weight: .semibold))
                .foregroundColor(vault.theme.textPrimary)
            
            TextField("Goal title", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
            
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                Spacer()
                Button("Add") {
                    if !title.isEmpty {
                        timerManager.addGoal(FocusGoal(title: title))
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct TimerDisplayView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var vault: VaultManager

    var body: some View {
        VStack(spacing: 28) {
            ZenSegmentedPicker(
                selection: $timerManager.mode,
                options: [(.pomodoro, "Pomodoro"), (.flow, "Flow")]
            )
            .frame(width: 240)

            ZStack {
                Circle()
                    .stroke(vault.theme.divider, lineWidth: 1)
                    .frame(width: 280, height: 280)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(vault.theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)

                VStack(spacing: 10) {
                    if timerManager.isBreathing {
                        Text("Breathe. Then on.")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 22, weight: .medium))
                            .foregroundColor(vault.theme.textPrimary)
                        Text("Posture reset · auto-continue in \(timerManager.breatheRemaining)s")
                            .font(DesignSystem.font(DesignSystem.typeSmall()))
                            .foregroundColor(vault.theme.textSecondary)
                    } else {
                        Text(timerManager.formattedTime)
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: DesignSystem.typeDisplay(), weight: .medium))
                            .monospacedDigit()
                            .foregroundColor(vault.theme.textPrimary)

                        Text(timerManager.statusText)
                            .font(DesignSystem.font(DesignSystem.typeSmall()))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                }
            }

            if vault.settings.interruptionAware, timerManager.isRunning, let away = timerManager.awayApp, timerManager.awaySeconds > 3 {
                HStack(spacing: 6) {
                    Image(systemName: "leaf")
                        .font(DesignSystem.font(DesignSystem.typeCaption()))
                        .foregroundColor(vault.theme.accent)
                    Text("notice: \(away) for \(timerManager.awaySeconds / 60)m \(timerManager.awaySeconds % 60)s")
                        .font(DesignSystem.font(DesignSystem.typeCaption()))
                        .foregroundColor(vault.theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(vault.theme.card.opacity(0.6))
                .clipShape(Capsule())
            }

            AmbienceSelector()

            HStack(spacing: 12) {
                Button { timerManager.toggle() } label: {
                    if timerManager.isBreathing {
                        Label("Skip", systemImage: "forward.fill")
                    } else {
                        Label(timerManager.isRunning ? "Pause" : "Begin",
                              systemImage: timerManager.isRunning ? "pause.fill" : "play.fill")
                    }
                }
                .buttonStyle(PillButtonStyle(theme: vault.theme, prominent: true))

                Button { timerManager.reset() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PillButtonStyle(theme: vault.theme, prominent: false))
            }
        }
        .padding(32)
        .surface(vault.theme)
        .onAppear {
            timerManager.syncSessionLength(minutes: vault.settings.studyMinutes)
        }
    }
}

// MARK: - Ambience Selector with Audio
struct AmbienceSelector: View {
    @EnvironmentObject var vault: VaultManager
    let ambiances = ["None", "Rain", "Fireplace", "White Noise", "Deep Focus"]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Ambience".uppercased())
                .font(DesignSystem.font(DesignSystem.typeCaption(), weight: .medium))
                .kerning(0.6)
                .foregroundColor(vault.theme.textSecondary)
            
            HStack(spacing: 4) {
                ForEach(ambiances, id: \.self) { amb in
                    Button {
                        vault.settings.ambience = amb.lowercased()
                        vault.audioPlayerManager.playAmbience(
                            named: amb.lowercased(),
                            volume: Float(vault.settings.ambienceVolume)
                        )
                        vault.saveAllData()
                    } label: {
                        Text(amb)
                            .font(DesignSystem.font(DesignSystem.typeSmall(), weight: vault.settings.ambience == amb.lowercased() ? .medium : .regular))
                            .foregroundColor(vault.settings.ambience == amb.lowercased() ? vault.theme.buttonText : vault.theme.textSecondary)
                            .padding(.horizontal, DesignSystem.spaceS())
                            .frame(height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.radiusChip())
                                    .fill(vault.settings.ambience == amb.lowercased() ? vault.theme.buttonBackground : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.radiusControl())
                    .fill(vault.theme.sidebar)
            )
            
            if vault.settings.ambience != "none" {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(DesignSystem.font(DesignSystem.typeCaption()))
                        .foregroundColor(vault.theme.textSecondary)
                    Slider(value: $vault.settings.ambienceVolume, in: 0...1)
                        .tint(vault.theme.accent)
                        .frame(width: 140)
                        .onChange(of: vault.settings.ambienceVolume) { _, newValue in
                            vault.audioPlayerManager.setVolume(Float(newValue))
                        }
                }
            }
        }
    }
}

struct QuickTimerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var vault: VaultManager
    @State private var selectedMinutes = 25
    
    var body: some View {
        VStack(spacing: 28) {
            Text("Quick Timer")
                .font(DesignSystem.font(20, weight: .light))
                .foregroundColor(vault.theme.textPrimary)
            
            HStack(spacing: 12) {
                ForEach([15, 25, 45, 60], id: \.self) { mins in
                    Button { selectedMinutes = mins } label: {
                        Text("\(mins)")
                            .font(DesignSystem.font(14, weight: selectedMinutes == mins ? .medium : .regular))
                            .foregroundColor(selectedMinutes == mins ? vault.theme.textPrimary : vault.theme.textSecondary)
                            .frame(width: 60, height: 40)
                            .background(selectedMinutes == mins ? vault.theme.warm : Color.clear)
                            .cornerRadius(DesignSystem.radiusChip())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("minutes")
                .font(DesignSystem.font(11))
                .foregroundColor(vault.theme.textSecondary)
            
            Spacer()
            
            Button("Begin") {
                timerManager.startQuickTimer(minutes: selectedMinutes)
                dismiss()
            }
            .font(DesignSystem.font(13, weight: .medium))
            .foregroundColor(vault.theme.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(vault.theme.buttonBackground)
            .cornerRadius(DesignSystem.radiusChip())
            
            Button("Cancel") { dismiss() }
                .font(DesignSystem.font(12))
                .foregroundColor(vault.theme.textSecondary)
        }
        .padding(32)
        .background(vault.theme.background)
    }
}

// MARK: - Mood Check-In
struct MoodCheckInSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vault: VaultManager
    @State private var selectedMood = 3
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How Do You Arrive Today?")
                .font(DesignSystem.font(18, weight: .light))
                .foregroundColor(vault.theme.textPrimary)
            
            HStack(spacing: 16) {
                ForEach(0..<5) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(mood == selectedMood ? vault.theme.seal : vault.theme.divider)
                                .frame(width: 32, height: 32)
                            Text(vault.moodLabels[mood])
                                .font(DesignSystem.font(10))
                                .foregroundColor(mood == selectedMood ? vault.theme.textPrimary : vault.theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                vault.setTodayMood(selectedMood)
                dismiss()
            }
            .font(DesignSystem.font(12, weight: .medium))
            .foregroundColor(vault.theme.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(vault.theme.buttonBackground)
            .cornerRadius(DesignSystem.radiusChip())
        }
        .padding(32)
        .background(vault.theme.background)
    }
}

// MARK: - Stats Room
struct StatsRoomView: View {
    @EnvironmentObject var vault: VaultManager
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var sessionToRename: StudySession?
    @State private var renameText = ""
    let focusTags = ["Focus", "Code", "Deep Work", "Revision", "Creative"]
    
    enum StatsPeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your Practice")
                        .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 32, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    
                    HStack(spacing: 0) {
                        ForEach(Array(StatsPeriod.allCases.enumerated()), id: \.offset) { index, period in
                            Button { selectedPeriod = period } label: {
                                Text(period.rawValue)
                                    .font(DesignSystem.font(12, weight: selectedPeriod == period ? .medium : .regular))
                                    .foregroundColor(selectedPeriod == period ? vault.theme.textPrimary : vault.theme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedPeriod == period ? vault.theme.warm : Color.clear)
                            }
                            .buttonStyle(.plain)
                            
                            if index < StatsPeriod.allCases.count - 1 {
                                Rectangle().fill(vault.theme.divider).frame(width: 1, height: 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                HStack(alignment: .top, spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Time")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text("\(totalHours)h \(totalMinutes)m")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 36, weight: .light))
                            .foregroundColor(vault.theme.textPrimary)
                        Text("This \(selectedPeriod.rawValue.lowercased())")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Milestone")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text(milestone.title)
                            .font(DesignSystem.font(20, weight: .medium))
                            .foregroundColor(vault.theme.textPrimary)
                        Text("\(Int(vault.getTotalHours()))h of 1000h")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Days at Goal")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text("\(vault.daysAtGoal())")
                            .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 36, weight: .light))
                            .foregroundColor(vault.theme.accent)
                        Text("target \(vault.settings.dailyGoal) min/day")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 60)
                
                if !vault.appUsageTracker.appUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Apps This Week")
                            .font(DesignSystem.font(11))
                            .foregroundColor(vault.theme.textSecondary)
                        
                        ForEach(vault.appUsageTracker.getTopApps(limit: 5), id: \.0) { app, minutes in
                            HStack {
                                Text(app)
                                    .font(DesignSystem.font(12))
                                    .foregroundColor(vault.theme.textPrimary)
                                Spacer()
                                Text("\(minutes / 60)h \(minutes % 60)m")
                                    .font(DesignSystem.font(12))
                                    .foregroundColor(vault.theme.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(vault.theme.card)
                    .cornerRadius(DesignSystem.radiusCard())
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("This Week")
                        .font(DesignSystem.font(11))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    HStack(alignment: .bottom, spacing: 24) {
                        ForEach(0..<7) { day in WeeklyBar(day: day) }
                    }
                    .frame(height: 140)
                    .overlay(alignment: .bottom) {
                        let goalPx = min(CGFloat(vault.settings.dailyGoal) / 120.0, 1.0) * 120
                        Rectangle()
                            .fill(vault.theme.accent.opacity(0.4))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .offset(y: -min(goalPx, 120))
                    }

                    Text("thin rule = daily goal (\(vault.settings.dailyGoal) min)")
                        .font(DesignSystem.font(10))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 60)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("The Year")
                        .font(DesignSystem.font(11))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 52), spacing: 3) {
                        ForEach(0..<365) { day in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(dayColor(day))
                                .frame(height: 10)
                        }
                    }
                }
                .padding(.horizontal, 60)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Sessions")
                        .font(DesignSystem.font(11))
                        .foregroundColor(vault.theme.textSecondary)

                    if vault.sessions.isEmpty {
                        Text("No sessions yet. Complete a pomodoro or import a CSV and they will line up here.")
                            .font(DesignSystem.font(12))
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(vault.sessions.prefix(25)) { session in
                            HStack(spacing: 12) {
                                Text(session.subject)
                                    .font(DesignSystem.font(12))
                                    .foregroundColor(vault.theme.textPrimary)
                                    .lineLimit(1)
                                if let away = session.awayMinutes, away > 0 {
                                    Text("strayed \(away)m")
                                        .font(DesignSystem.font(10))
                                        .foregroundColor(vault.theme.accent)
                                }
                                Spacer()
                                Text("\(session.duration)m")
                                    .font(DesignSystem.font(12, weight: .medium))
                                    .foregroundColor(vault.theme.textPrimary)
                                    .monospacedDigit()
                                Text(sessionDate(session.date))
                                    .font(DesignSystem.font(11))
                                    .foregroundColor(vault.theme.textSecondary)
                            }
                            .padding(.vertical, 6)
                            .contextMenu {
                                Button("Rename…") {
                                    sessionToRename = session
                                    renameText = session.subject
                                }
                                Divider()
                                ForEach(focusTags, id: \.self) { tag in
                                    Button("Tag \"\(tag)\"") {
                                        renameSession(session, to: tag)
                                    }
                                }
                                Divider()
                                Button("Delete Entry", role: .destructive) {
                                    if let idx = vault.sessions.firstIndex(where: { $0.id == session.id }) {
                                        vault.sessions.remove(at: idx)
                                        vault.saveAllData()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 60)

                Spacer(minLength: 60)
            }
        }
        .alert("Rename Session", isPresented: Binding(
            get: { sessionToRename != nil },
            set: { if !$0 { sessionToRename = nil } }
        )) {
            TextField("Subject", text: $renameText)
            Button("Rename") {
                if let session = sessionToRename {
                    renameSession(session, to: renameText)
                }
                sessionToRename = nil
            }
            Button("Cancel", role: .cancel) { sessionToRename = nil }
        }
    }

    func renameSession(_ session: StudySession, to subject: String) {
        guard !subject.isEmpty,
              let idx = vault.sessions.firstIndex(where: { $0.id == session.id }) else { return }
        vault.sessions[idx].subject = subject
        vault.recomputeDailyStats()
        vault.saveAllData()
    }

    func sessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    var totalHours: Int { Int(vault.getTotalHours()) }
    var totalMinutes: Int { Int((vault.getTotalHours() - Double(totalHours)) * 60) }
    var milestone: (title: String, progress: Double) { vault.getMilestone() }
    
    func dayColor(_ day: Int) -> Color {
        let date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        let minutes = vault.dailyStats[key]?.totalMinutes ?? 0
        let opacity = min(Double(minutes) / 120, 1.0)
        return vault.theme.accent.opacity(max(opacity, 0.08))
    }
}

struct WeeklyBar: View {
    let day: Int
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(vault.theme.accent.opacity(barOpacity))
                .frame(width: 24, height: max(barHeight, 2))
            Text(dayName)
                .font(DesignSystem.font(10))
                .foregroundColor(vault.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    var barHeight: CGFloat {
        let minutes = getDayMinutes()
        return min(CGFloat(minutes) / 120 * 120, 120)
    }
    
    var barOpacity: Double { min(Double(getDayMinutes()) / 120, 1.0) }
    
    func getDayMinutes() -> Int {
        let date = Calendar.current.date(byAdding: .day, value: -(6 - day), to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return vault.dailyStats[key]?.totalMinutes ?? 0
    }
    
    var dayName: String {
        let date = Calendar.current.date(byAdding: .day, value: -(6 - day), to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Habits Room
struct HabitsRoomView: View {
    @EnvironmentObject var vault: VaultManager
    @State private var showingAddHabit = false
    @State private var newHabitTitle = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text("Habit Tracker")
                        .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 32, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    Button(action: { showingAddHabit = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(DesignSystem.font(11))
                            Text("Add Habit").font(DesignSystem.font(12))
                        }
                        .foregroundColor(vault.theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(vault.theme.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ForEach(vault.habits) { habit in
                        HabitRow(habit: habit, vault: vault)
                    }
                }
                .padding(.horizontal, 60)
                
                if vault.habits.isEmpty {
                    Text("No habits tracked yet. Add one to get started.")
                        .foregroundColor(vault.theme.textSecondary)
                        .padding(.horizontal, 60)
                        .padding(.top, 40)
                }
                
                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitSheet(title: $newHabitTitle, vault: vault)
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @ObservedObject var vault: VaultManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(DesignSystem.font(14, weight: .medium))
                    .foregroundColor(vault.theme.textPrimary)
                Text("Streak: \(habit.streak) days")
                    .font(DesignSystem.font(11))
                    .foregroundColor(vault.theme.textSecondary)
            }
            
            Spacer()
            
            Button(action: { vault.toggleHabitCompletion(habit) }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(DesignSystem.font(24))
                    .foregroundColor(isCompletedToday ? vault.theme.accent : vault.theme.divider)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(vault.theme.card)
        .cornerRadius(DesignSystem.radiusCard())
    }
    
    var isCompletedToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return habit.completedDates.contains(today)
    }
}

struct AddHabitSheet: View {
    @Binding var title: String
    @ObservedObject var vault: VaultManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Habit")
                .font(DesignSystem.font(18, weight: .light))
            
            TextField("Habit name", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
            
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                Spacer()
                Button("Add") {
                    if !title.isEmpty {
                        vault.habits.append(Habit(title: title))
                        vault.saveAllData()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Weekly Review View
struct WeeklyReviewView: View {
    @EnvironmentObject var vault: VaultManager
    @State private var currentReview: WeeklyReview?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text("Weekly Review")
                        .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 32, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    Button("Generate Review") {
                        currentReview = WeeklyReview.generate(from: vault.sessions, stats: vault.dailyStats)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                if let review = currentReview {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("The Week, In a Letter")
                                    .font(DesignSystem.font(12, weight: .medium))
                                    .foregroundColor(vault.theme.textSecondary)
                                    .kerning(0.6)
                                Spacer()
                                Button {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateStyle = .medium
                                    vault.addNote(
                                        title: "Weekly Review — \(dateFormatter.string(from: review.weekStart))",
                                        content: review.letter
                                    )
                                } label: {
                                    Label("Save to Notes", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(PillButtonStyle(theme: vault.theme, prominent: false))
                            }
                            Text(review.letter)
                                .font(DesignSystem.displayFont(serif: true, size: 19, weight: .regular))
                                .italic()
                                .foregroundColor(vault.theme.textPrimary)
                                .lineSpacing(6)
                        }
                        .padding(20)
                        .background(vault.theme.card)
                        .cornerRadius(DesignSystem.radiusCard())
                        
                        HStack(spacing: 40) {
                            StatCard(title: "Total Time", value: "\(review.totalMinutes / 60)h \(review.totalMinutes % 60)m")
                            StatCard(title: "Sessions", value: "\(review.sessionsCompleted)")
                            StatCard(title: "Goals Completed", value: "\(review.goalsCompleted)")
                            StatCard(title: "Avg Mood", value: String(format: "%.1f/5", review.moodAverage))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Apps")
                                .font(DesignSystem.font(14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.topApps, id: \.0) { app, minutes in
                                HStack {
                                    Text(app)
                                        .font(DesignSystem.font(12))
                                        .foregroundColor(vault.theme.textPrimary)
                                    Spacer()
                                    Text("\(minutes / 60)h \(minutes % 60)m")
                                        .font(DesignSystem.font(12))
                                        .foregroundColor(vault.theme.textSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(DesignSystem.radiusCard())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Achievements")
                                .font(DesignSystem.font(14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.achievements, id: \.self) { achievement in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(DesignSystem.font(12))
                                        .foregroundColor(vault.theme.seal)
                                    Text(achievement)
                                        .font(DesignSystem.font(12))
                                        .foregroundColor(vault.theme.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(DesignSystem.radiusCard())
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(DesignSystem.font(14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.insights, id: \.self) { insight in
                                Text(insight)
                                    .font(DesignSystem.font(12))
                                    .foregroundColor(vault.theme.textPrimary)
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(DesignSystem.radiusCard())
                    }
                    .padding(.horizontal, 60)
                } else {
                    Text("Click \"Generate Review\" to see your weekly summary.")
                        .foregroundColor(vault.theme.textSecondary)
                        .padding(.horizontal, 60)
                        .padding(.top, 40)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignSystem.font(11))
                .foregroundColor(vault.theme.textSecondary)
            Text(value)
                .font(DesignSystem.font(24, weight: .medium))
                .foregroundColor(vault.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(vault.theme.card)
        .cornerRadius(DesignSystem.radiusCard())
    }
}

// MARK: - Notes Room
struct NotesRoomView: View {
    @EnvironmentObject var vault: VaultManager
    @State private var selectedNote: Note?
    @State private var showingNewNote = false
    @State private var searchText = ""
    @State private var showPreview = false
    
    var filteredNotes: [Note] {
        if searchText.isEmpty { return vault.notes.sorted(by: { $0.date > $1.date }) }
        return vault.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
        .sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(DesignSystem.font(11))
                        .foregroundColor(vault.theme.textSecondary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.font(12))
                        .foregroundColor(vault.theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(vault.theme.card)
                
                Divider().background(vault.theme.divider)
                
                List(selection: $selectedNote) {
                    ForEach(filteredNotes) { note in
                        NoteListItem(note: note, isSelected: note.id == selectedNote?.id)
                    }
                    .onDelete { indices in
                        indices.forEach { index in
                            let note = filteredNotes[index]
                            if selectedNote?.id == note.id { selectedNote = nil }
                            vault.notes.removeAll { $0.id == note.id }
                            vault.saveAllData()
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(vault.theme.paper)
                
                Divider().background(vault.theme.divider)
                
                Button(action: { showingNewNote = true }) {
                    HStack {
                        Image(systemName: "plus").font(DesignSystem.font(11))
                        Text("New Note").font(DesignSystem.font(12))
                        Spacer()
                    }
                    .foregroundColor(vault.theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 260)
            .background(vault.theme.paper)
            
            if let note = selectedNote {
                NoteEditorView(note: note, showPreview: $showPreview) {
                    selectedNote = nil
                }
                .id(note.id)
            } else {
                VStack(spacing: 20) {
                    EnsoLogo()
                        .scaleEffect(2)
                    Text("Select a note")
                        .font(DesignSystem.font(14))
                        .foregroundColor(vault.theme.textSecondary)
                    Text("or create a new one")
                        .font(DesignSystem.font(12))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.6))
                    Button("New Note") { showingNewNote = true }
                        .font(DesignSystem.font(12))
                        .foregroundColor(vault.theme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(vault.theme.divider, lineWidth: 1))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(vault.theme.background)
            }
        }
        .sheet(isPresented: $showingNewNote) { NewNoteSheet() }
    }
}

struct NoteListItem: View {
    let note: Note
    let isSelected: Bool
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(DesignSystem.font(13, weight: isSelected ? .medium : .regular))
                .foregroundColor(vault.theme.textPrimary)
                .lineLimit(1)
            
            Text(note.content.prefix(50))
                .font(DesignSystem.font(11))
                .foregroundColor(vault.theme.textSecondary)
                .lineLimit(2)
            
            Text(note.date, style: .date)
                .font(DesignSystem.font(10))
                .foregroundColor(vault.theme.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(isSelected ? vault.theme.warm : Color.clear)
        .contextMenu {
            Button("Delete Note", role: .destructive) {
                vault.notes.removeAll { $0.id == note.id }
                vault.saveAllData()
            }
        }
    }
}

// Shared editor controller: keeps a weak handle on the live NSTextView so the
// toolbar can format at the current selection / caret instead of appending.
final class EditorController: ObservableObject {
    weak var textView: NSTextView?

    func apply(_ op: NoteFormat) {
        guard let tv = textView else { return }
        let text = tv.string
        var sel = tv.selectedRange()
        let lower = min(sel.location, text.count)
        if lower > text.count { return }

        switch op {
        case .bold, .italic, .strikethrough, .inlineCode:
            wrapSelection(tv, text: text, sel: &sel) { content in
                switch op {
                case .bold: return ("**" + content + "**")
                case .italic: return ("_" + content + "_")
                case .strikethrough: return ("~~" + content + "~~")
                default: return ("`" + content + "`")
                }
            }

        case .heading1, .heading2:
            blockPrefix(tv, text: text, sel: &sel, marker: op == .heading1 ? "# " : "## ")

        case .bullet:
            blockPrefix(tv, text: text, sel: &sel, marker: "- ")

        case .numbered:
            blockPrefix(tv, text: text, sel: &sel, marker: "1. ")

        case .quote:
            blockPrefix(tv, text: text, sel: &sel, marker: "> ")

        case .checkbox:
            blockPrefix(tv, text: text, sel: &sel, marker: "- [ ] ")

        case .codeBlock:
            wrapSelection(tv, text: text, sel: &sel) { content in
                "```\n" + content + "\n```"
            }

        case .link:
            if sel.length > 0 {
                let prefix = "["
                let middle = (text as NSString).substring(with: sel)
                let url = "](url)"
                let inserted = prefix + middle + url
                tv.insertText(inserted, replacementRange: sel)
                let newLoc = sel.location + prefix.utf16.count + middle.utf16.count + 2
                tv.setSelectedRange(NSRange(location: newLoc, length: 3))
            } else {
                tv.insertText("[](url)", replacementRange: sel)
                tv.setSelectedRange(NSRange(location: sel.location + 1, length: 0))
                let urlLoc = sel.location + 2
                tv.setSelectedRange(NSRange(location: urlLoc, length: 3))
            }

        case .horizontalRule:
            tv.insertText("\n---\n", replacementRange: sel)
        }
    }

    private func wrapSelection(
        _ tv: NSTextView, text: String, sel: inout NSRange,
        transform: (String) -> String
    ) {
        if sel.length > 0 {
            tv.insertText(transform((text as NSString).substring(with: sel)), replacementRange: sel)
        } else {
            let placeholder = "text"
            tv.insertText(transform(placeholder), replacementRange: sel)
            let idx = sel.location + (placeholder as NSString).length / 2
            tv.setSelectedRange(NSRange(location: idx, length: placeholder.count))
        }
    }

    private func blockPrefix(_ tv: NSTextView, text: String, sel: inout NSRange, marker: String) {
        let ns = text as NSString
        var start = sel.location
        if sel.length > 0 { start = sel.location }
        guard start <= ns.length else { return }
        var lineStart = start
        while lineStart > 0 {
            let idx = lineStart - 1
            if idx < ns.length, ns.character(at: idx) == 0x0A { break }
            lineStart -= 1
        }
        tv.insertText(marker, replacementRange: NSRange(location: lineStart, length: 0))
        tv.setSelectedRange(NSRange(location: start + marker.utf16.count, length: sel.length))
    }
}

enum NoteFormat {
    case bold, italic, strikethrough, inlineCode
    case heading1, heading2, bullet, numbered, quote, checkbox
    case codeBlock, link, horizontalRule
}

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    let controller: EditorController
    let textColor: NSColor
    let selectionColor: NSColor
    
    init(text: Binding<String>, controller: EditorController, textColor: NSColor, selectionColor: NSColor) {
        self._text = text
        self.controller = controller
        self.textColor = textColor
        self.selectionColor = selectionColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let tv = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = NSFont.systemFont(ofSize: 14)
        tv.textColor = textColor
        tv.insertionPointColor = textColor
        tv.selectedTextAttributes = [
            .backgroundColor: selectionColor,
            .foregroundColor: textColor
        ]
        tv.drawsBackground = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.textContainerInset = NSSize(width: 8, height: 8)
        tv.string = text
        controller.textView = tv
        scrollView.drawsBackground = false
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        if tv.string != text {
            let selected = tv.selectedRange()
            tv.string = text
            tv.setSelectedRange(NSRange(location: min(selected.location, (text as NSString).length), length: 0))
        }
        tv.textColor = textColor
        tv.insertionPointColor = textColor
        tv.selectedTextAttributes = [
            .backgroundColor: selectionColor,
            .foregroundColor: textColor
        ]
        controller.textView = tv
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: MarkdownEditorView
        init(_ parent: MarkdownEditorView) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let value = tv.string
            if value != parent.text {
                parent.text = value
            }
        }
    }
}

// MARK: - Note Editor (Obsidian-style markdown formatting + live preview)
struct NoteEditorView: View {
    @State var note: Note
    @Binding var showPreview: Bool
    var onDeleted: () -> Void = {}
    @EnvironmentObject var vault: VaultManager
    @StateObject private var editor = EditorController()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Title", text: $note.title)
                    .font(DesignSystem.font(22, weight: .light))
                    .textFieldStyle(.plain)
                    .foregroundColor(vault.theme.textPrimary)
                    .onChange(of: note.title) { _, _ in saveNote() }

                Spacer()

                Button(action: { showPreview.toggle() }) {
                    Image(systemName: showPreview ? "square.and.pencil" : "eye")
                        .font(DesignSystem.font(12))
                        .foregroundColor(showPreview ? vault.theme.accent : vault.theme.textSecondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .help(showPreview ? "Back to editor" : "Preview rendered markdown")

                Button(action: deleteNote) {
                    Image(systemName: "trash")
                        .font(DesignSystem.font(12))
                        .foregroundColor(vault.theme.seal)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .help("Delete note")

                Text("Saved \(timeAgo)")
                    .font(DesignSystem.font(10))
                    .foregroundColor(vault.theme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    FormatButton(icon: "textformat.size", action: { editor.apply(.heading1) }, help: "Heading 1", shortcut: .command, key: "1")
                    FormatButton(icon: "textformat.size.2", action: { editor.apply(.heading2) }, help: "Heading 2", shortcut: .command, key: "2")
                    Divider().frame(height: 16)
                    FormatButton(icon: "bold", action: { editor.apply(.bold) }, help: "Bold", shortcut: .command, key: "b")
                    FormatButton(icon: "italic", action: { editor.apply(.italic) }, help: "Italic", shortcut: .command, key: "i")
                    FormatButton(icon: "strikethrough", action: { editor.apply(.strikethrough) }, help: "Strikethrough")
                    FormatButton(icon: "chevron.left.forwardslash.chevron.right", action: { editor.apply(.inlineCode) }, help: "Inline code", shortcut: .command, key: "e")
                    FormatButton(icon: "quote.opening", action: { editor.apply(.quote) }, help: "Quote")
                    Divider().frame(height: 16)
                    FormatButton(icon: "list.bullet", action: { editor.apply(.bullet) }, help: "Bullet list")
                    FormatButton(icon: "list.number", action: { editor.apply(.numbered) }, help: "Numbered list")
                    FormatButton(icon: "checklist", action: { editor.apply(.checkbox) }, help: "Checkbox")
                    Divider().frame(height: 16)
                    FormatButton(icon: "chevron.left.forwardslash.chevron.right.square", action: { editor.apply(.codeBlock) }, help: "Code block")
                    FormatButton(icon: "link", action: { editor.apply(.link) }, help: "Link", shortcut: .command, key: "k")
                    FormatButton(icon: "minus", action: { editor.apply(.horizontalRule) }, help: "Horizontal rule")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 6)
            }

            Divider().background(vault.theme.divider)

            if showPreview {
                ScrollView {
                    MarkdownPreview(content: note.content)
                        .padding(32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(vault.theme.background)
                }
            } else {
                MarkdownEditorView(
                    text: $note.content,
                    controller: editor,
                    textColor: NSColor(vault.theme.textPrimary),
                    selectionColor: NSColor(vault.theme.accent.opacity(0.35))
                )
                .padding(24)
                .background(ZStack {
                    vault.theme.background
                    GridPatternView()
                })
                .onChange(of: note.content) { _, _ in saveNote() }
            }
        }
        .background(vault.theme.background)
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: note.date, relativeTo: Date())
    }

    func saveNote() {
        note.date = Date()
        if let index = vault.notes.firstIndex(where: { $0.id == note.id }) {
            vault.notes[index] = note
            vault.saveAllData()
        }
    }

    func deleteNote() {
        vault.notes.removeAll { $0.id == note.id }
        vault.saveAllData()
        onDeleted()
    }
}

// Renders note markdown (headings, bold, italic, code, lists, quotes, links).
struct MarkdownPreview: View {
    let content: String

    var body: some View {
        let rendered = try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        )
        Group {
            if let rendered {
                Text(rendered)
                    .font(DesignSystem.font(14))
                    .foregroundColor(.white.opacity(0.86))
                    .textSelection(.enabled)
            } else {
                Text(content)
                    .font(DesignSystem.font(14))
                    .foregroundColor(.white.opacity(0.86))
                    .textSelection(.enabled)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void
    var help: String = ""
    var shortcut: EventModifiers? = nil
    var key: KeyEquivalent = "."
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(DesignSystem.font(11))
                .foregroundColor(vault.theme.textSecondary)
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .modifier(ShortcutModifier(shortcut: shortcut, key: key))
    }
}

struct ShortcutModifier: ViewModifier {
    let shortcut: EventModifiers?
    let key: KeyEquivalent
    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(key, modifiers: shortcut)
        } else {
            content
        }
    }
}

struct NewNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vault: VaultManager
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack(spacing: 24) {
            TextField("Title", text: $title)
                .font(DesignSystem.font(22, weight: .light))
                .textFieldStyle(.plain)
                .foregroundColor(vault.theme.textPrimary)
            
            TextEditor(text: $content)
                .font(DesignSystem.font(14))
                .foregroundColor(vault.theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 320)
                .padding(16)
                .background(vault.theme.card)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(vault.theme.divider, lineWidth: 1))
            
            HStack {
                Button("Cancel") { dismiss() }
                    .font(DesignSystem.font(12))
                    .foregroundColor(vault.theme.textSecondary)
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save") {
                    let note = Note(id: UUID(), title: title, content: content, date: Date())
                    vault.notes.append(note)
                    vault.saveAllData()
                    dismiss()
                }
                .font(DesignSystem.font(12, weight: .medium))
                .foregroundColor(vault.theme.buttonText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(vault.theme.buttonBackground)
                .cornerRadius(DesignSystem.radiusChip())
            }
        }
        .padding(32)
        .frame(width: 600)
        .background(vault.theme.background)
    }
}

// MARK: - Schedule Room
struct ScheduleRoomView: View {
    @EnvironmentObject var vault: VaultManager
    @State private var showingAddEvent = false
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text("Weekly Rhythm")
                        .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 32, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    Button(action: { showingAddEvent = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(DesignSystem.font(11))
                            Text("Add Event").font(DesignSystem.font(12))
                        }
                        .foregroundColor(vault.theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(vault.theme.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        ScheduleDayRow(day: day, dayIndex: index)
                        if index < days.count - 1 { Divider().background(vault.theme.divider) }
                    }
                }
                .padding(.horizontal, 60)
                
                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showingAddEvent) { AddEventSheet() }
    }
}

struct ScheduleDayRow: View {
    let day: String
    let dayIndex: Int
    @EnvironmentObject var vault: VaultManager
    
    var isToday: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday == 1 && dayIndex == 6) || (weekday - 1 == dayIndex)
    }
    
    var events: [ScheduleEvent] {
        vault.schedule.filter { $0.dayOfWeek == dayIndex }.sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            Text(day)
                .font(DesignSystem.font(14, weight: isToday ? .medium : .regular))
                .foregroundColor(isToday ? vault.theme.seal : vault.theme.textPrimary)
                .frame(width: 100, alignment: .leading)
                .padding(.vertical, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                if events.isEmpty {
                    Text("Open")
                        .font(DesignSystem.font(12))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.5))
                        .padding(.vertical, 20)
                } else {
                    ForEach(events) { event in
                        HStack(spacing: 16) {
                            Text(event.startTime)
                                .font(DesignSystem.font(11, weight: .medium))
                                .foregroundColor(vault.theme.textSecondary)
                                .frame(width: 50, alignment: .leading)
                            Text(event.title)
                                .font(DesignSystem.font(13))
                                .foregroundColor(vault.theme.textPrimary)
                            Text("– \(event.endTime)")
                                .font(DesignSystem.font(11))
                                .foregroundColor(vault.theme.textSecondary)
                            
                            Spacer()
                            
                            Button(action: { deleteEvent(event) }) {
                                Image(systemName: "trash")
                                    .font(DesignSystem.font(10))
                                    .foregroundColor(vault.theme.seal.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(isToday ? vault.theme.warm.opacity(0.5) : Color.clear)
    }
    
    func deleteEvent(_ event: ScheduleEvent) {
        vault.schedule.removeAll { $0.id == event.id }
        vault.saveAllData()
    }
}

struct AddEventSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vault: VaultManager
    @State private var title = ""
    @State private var day = 0
    @State private var startTime = "09:00"
    @State private var endTime = "10:00"
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add Event")
                .font(DesignSystem.font(20, weight: .light))
                .foregroundColor(vault.theme.textPrimary)
            
            TextField("What", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
            
            Picker("Day", selection: $day) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, dayName in
                    Text(dayName).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 20)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starts").font(DesignSystem.font(10)).foregroundColor(vault.theme.textSecondary)
                    TextField("09:00", text: $startTime)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ends").font(DesignSystem.font(10)).foregroundColor(vault.theme.textSecondary)
                    TextField("10:00", text: $endTime)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack {
                Button("Cancel") { dismiss() }
                    .font(DesignSystem.font(12))
                    .foregroundColor(vault.theme.textSecondary)
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save") {
                    let event = ScheduleEvent(
                        id: UUID(),
                        title: title,
                        dayOfWeek: day,
                        startTime: startTime,
                        endTime: endTime
                    )
                    vault.schedule.append(event)
                    vault.saveAllData()
                    dismiss()
                }
                .font(DesignSystem.font(12, weight: .medium))
                .foregroundColor(vault.theme.buttonText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(vault.theme.buttonBackground)
                .cornerRadius(DesignSystem.radiusChip())
            }
            .padding(.horizontal, 20)
        }
        .padding(32)
        .frame(width: 400, height: 420)
        .background(vault.theme.background)
    }
}

// MARK: - Settings Room
struct SettingsRoomView: View {
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Settings")
                    .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 32, weight: .light))
                    .foregroundColor(vault.theme.textPrimary)
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Appearance")
                        .font(DesignSystem.font(14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    Picker("Theme", selection: $vault.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .tint(vault.theme.accent)
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(DesignSystem.radiusCard())
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Timer")
                        .font(DesignSystem.font(14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    SettingRow(title: "Daily Goal", value: $vault.settings.dailyGoal, range: 30...300, step: 10, unit: "min")
                    SettingRow(title: "Study Duration", value: $vault.settings.studyMinutes, range: 15...90, step: 5, unit: "min")
                    SettingRow(title: "Break Duration", value: $vault.settings.breakMinutes, range: 5...30, step: 5, unit: "min")
                    Toggle("Show Quotes During Timer", isOn: $vault.settings.showQuotes)
                        .tint(vault.theme.accent)
                    Toggle("Auto-Continue After Pomodoro (breathe gap)", isOn: $vault.settings.autoContinuePomodoro)
                        .tint(vault.theme.accent)
                    SettingRow(title: "Breathe Gap", value: $vault.settings.breatheGapSeconds, range: 15...90, step: 5, unit: "s")
                    Toggle("Notice When You Stray (interruption-aware)", isOn: $vault.settings.interruptionAware)
                        .tint(vault.theme.accent)
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(DesignSystem.radiusCard())
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Integrations")
                        .font(DesignSystem.font(14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    Toggle("Calendar Integration", isOn: $vault.settings.calendarIntegration)
                        .tint(vault.theme.accent)
                    Toggle("Silence Notifications During Focus", isOn: $vault.settings.silenceNotifications)
                        .tint(vault.theme.accent)
                    Toggle("Track App Usage", isOn: $vault.settings.trackAppUsage)
                        .tint(vault.theme.accent)
                    Toggle("Block Distractions", isOn: $vault.settings.blockDistractions)
                        .tint(vault.theme.accent)
                    Toggle("Streak Mercy (forgive a missed day)", isOn: $vault.settings.streakMercy)
                        .tint(vault.theme.accent)
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(DesignSystem.radiusCard())
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Vault & Data")
                        .font(DesignSystem.font(14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    HStack {
                        Text(vault.vaultURL?.path ?? "No vault selected")
                            .font(DesignSystem.font(12))
                            .foregroundColor(vault.theme.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Choose Folder") {
                            _ = vault.chooseVaultFolder()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Tip: Choose an iCloud Drive folder for automatic sync across devices")
                        .font(DesignSystem.font(10))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.6))
                    
                    HStack(spacing: 12) {
                        Button("Export CSV") {
                            _ = vault.exportCSV()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Import CSV") {
                            vault.importCSV()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Export to Obsidian") {
                            vault.exportToObsidian()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Export to Notion") {
                            vault.exportToNotion()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(DesignSystem.radiusCard())
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 60)
        }
    }
}

struct SettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.font(13))
                .foregroundColor(vault.theme.textPrimary)
            Spacer()
            Text("\(value) \(unit)")
                .font(DesignSystem.font(13, weight: .medium))
                .foregroundColor(vault.theme.textPrimary)
                .frame(width: 80, alignment: .trailing)
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
                .tint(vault.theme.accent)
                .frame(width: 200)
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @Binding var hasCompletedSetup: Bool
    @ObservedObject var vault: VaultManager
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 40) {
            if currentStep == 0 {
                VStack(spacing: 24) {
                    EnsoLogo()
                        .scaleEffect(3)
                    Text("Sumi")
                        .font(DesignSystem.font(24, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Text("A Quiet Space For Focused Study")
                        .font(DesignSystem.font(13))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    Spacer()
                    
                    Button("Choose Vault Location") {
                        if vault.chooseVaultFolder() != nil { currentStep = 1 }
                    }
                    .font(DesignSystem.font(12, weight: .medium))
                    .foregroundColor(vault.theme.buttonText)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(vault.theme.buttonBackground)
                    .cornerRadius(DesignSystem.radiusChip())
                }
                .padding(60)
            } else {
                VStack(spacing: 24) {
                    Text("You're All Set")
                        .font(DesignSystem.displayFont(serif: vault.theme.serifDisplay, size: 28, weight: .light))
                        .foregroundColor(vault.theme.textPrimary)
                    Text("Your vault is ready")
                        .font(DesignSystem.font(13))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    Spacer()
                    
                    Button("Begin") { hasCompletedSetup = true }
                        .font(DesignSystem.font(12, weight: .medium))
                        .foregroundColor(vault.theme.buttonText)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(vault.theme.buttonBackground)
                        .cornerRadius(DesignSystem.radiusChip())
                }
                .padding(60)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(vault.theme.background)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
