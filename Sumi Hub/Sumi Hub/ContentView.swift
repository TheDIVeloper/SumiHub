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

struct Quote: Identifiable, Codable {
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
    var theme: AppTheme = .light
    var calendarIntegration: Bool = false
    var silenceNotifications: Bool = true
    var trackAppUsage: Bool = true
    var blockDistractions: Bool = false
    var blockedApps: [String] = ["Safari", "Mail", "Messages"]
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
    case highContrast = "High Contrast"
    
    var colors: ThemeColors {
        switch self {
        case .light:
            return ThemeColors(
                background: Color(red: 0.97, green: 0.95, blue: 0.91),
                sidebar: Color(red: 0.94, green: 0.91, blue: 0.87),
                card: Color(red: 0.96, green: 0.92, blue: 0.85),
                textPrimary: Color(red: 0.18, green: 0.17, blue: 0.20),
                textSecondary: Color(red: 0.45, green: 0.42, blue: 0.47),
                accent: Color(red: 0.52, green: 0.60, blue: 0.50),
                seal: Color(red: 0.78, green: 0.30, blue: 0.25),
                divider: Color(red: 0.88, green: 0.85, blue: 0.80),
                warm: Color(red: 0.96, green: 0.92, blue: 0.85),
                buttonBackground: Color(red: 0.25, green: 0.24, blue: 0.27),
                buttonText: Color(red: 0.98, green: 0.97, blue: 0.95)
            )
        case .dark:
            return ThemeColors(
                background: Color(red: 0.12, green: 0.11, blue: 0.14),
                sidebar: Color(red: 0.15, green: 0.14, blue: 0.17),
                card: Color(red: 0.18, green: 0.17, blue: 0.20),
                textPrimary: Color(red: 0.95, green: 0.94, blue: 0.92),
                textSecondary: Color(red: 0.75, green: 0.72, blue: 0.70),
                accent: Color(red: 0.52, green: 0.60, blue: 0.50),
                seal: Color(red: 0.85, green: 0.40, blue: 0.35),
                divider: Color(red: 0.25, green: 0.24, blue: 0.27),
                warm: Color(red: 0.22, green: 0.20, blue: 0.18),
                buttonBackground: Color(red: 0.52, green: 0.60, blue: 0.50),
                buttonText: Color(red: 0.98, green: 0.97, blue: 0.95)
            )
        case .sepia:
            return ThemeColors(
                background: Color(red: 0.94, green: 0.90, blue: 0.82),
                sidebar: Color(red: 0.91, green: 0.86, blue: 0.76),
                card: Color(red: 0.96, green: 0.92, blue: 0.85),
                textPrimary: Color(red: 0.35, green: 0.28, blue: 0.22),
                textSecondary: Color(red: 0.55, green: 0.48, blue: 0.42),
                accent: Color(red: 0.48, green: 0.52, blue: 0.42),
                seal: Color(red: 0.68, green: 0.35, blue: 0.28),
                divider: Color(red: 0.85, green: 0.80, blue: 0.72),
                warm: Color(red: 0.96, green: 0.90, blue: 0.80),
                buttonBackground: Color(red: 0.45, green: 0.38, blue: 0.32),
                buttonText: Color(red: 0.98, green: 0.96, blue: 0.92)
            )
        case .highContrast:
            return ThemeColors(
                background: Color.white,
                sidebar: Color(red: 0.95, green: 0.95, blue: 0.95),
                card: Color(red: 0.98, green: 0.98, blue: 0.98),
                textPrimary: Color.black,
                textSecondary: Color(red: 0.40, green: 0.40, blue: 0.40),
                accent: Color(red: 0.00, green: 0.50, blue: 0.00),
                seal: Color(red: 0.80, green: 0.00, blue: 0.00),
                divider: Color(red: 0.80, green: 0.80, blue: 0.80),
                warm: Color(red: 0.98, green: 0.95, blue: 0.90),
                buttonBackground: Color.black,
                buttonText: Color.white
            )
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
    func strokeOpacity(hovering: Bool = false) -> Double { hovering ? 0.14 : 0.07 }
    func dividerOpacity() -> Double { 0.06 }

    // Zen corner languages: calm cards, tighter controls, smallest chips.
    func radiusCard() -> CGFloat { 12 }
    func radiusControl() -> CGFloat { 7 }
    func radiusChip() -> CGFloat { 6 }
    func radiusSidebar() -> CGFloat { 10 }

    // Breathable 8-pt spacing rhythm — the anti-clutter lever.
    func spaceXS() -> CGFloat { 6 }
    func spaceS() -> CGFloat { 10 }
    func spaceM() -> CGFloat { 16 }
    func spaceL() -> CGFloat { 24 }
    func spaceXL() -> CGFloat { 40 }

    // Keep the window airy but not empty.
    func contentInset() -> CGFloat { 28 }
    func contentInsetCompact() -> CGFloat { 20 }

    // Soft ambient presence — shadow, not weight.
    func shadowColorOpacity() -> Double { 0.10 }
    func shadowRadius() -> CGFloat { 10 }
    func shadowOffsetY() -> CGFloat { 2 }

    // Type scale (tuned, rounded numerals for the zen/data set).
    func typeHero() -> CGFloat { 30 }
    func typeTitle() -> CGFloat { 20 }
    func typeSection() -> CGFloat { 15 }
    func typeBody() -> CGFloat { 13 }
    func typeSmall() -> CGFloat { 11 }
    func typeCaption() -> CGFloat { 9 }
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
        return Float(Int64(h2 ^ (h2 >> 31))) / Float(Int64.max)
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
                  let ablPointer = audioBufferList.pointee.mBuffers.mData else {
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
                        self.nextCrackle = Float.random(in: 0.02...0.9)
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
        
        return WeeklyReview(
            weekStart: weekStart,
            totalMinutes: totalMinutes,
            sessionsCompleted: sessionsCompleted,
            goalsCompleted: goalsCompleted,
            topApps: topApps,
            moodAverage: moodAverage,
            achievements: achievements,
            insights: insights
        )
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
    @Published var currentTheme: AppTheme = .light
    
    let appUsageTracker = AppUsageTracker()
    let calendarManager = CalendarManager()
    let notificationManager = NotificationManager()
    let distractionBlocker = DistractionBlocker()
    let audioPlayerManager = AudioPlayerManager()
    
    var theme: ThemeColors {
        currentTheme.colors
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
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleToggle), name: .toggleTimer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReset), name: .resetTimer, object: nil)
    }
    
    @objc func handleToggle() { toggle() }
    @objc func handleReset() { reset() }
    
    private var timer: Timer?
    private var quoteTimer: Timer?
    private var appUsageTracker: AppUsageTracker?
    
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
        let total = 25 * 60
        return Double(total - timeRemaining) / Double(total)
    }
    
    var statusText: String {
        mode == .flow ? "Flowing Quietly" : "Breathe In · Study · Breathe Out"
    }
    
    func toggle() {
        if isRunning { pause() } else { start() }
    }
    
    func start() {
        isRunning = true
        appsUsed = []
        appUsageTracker = AppUsageTracker()
        generateBreakSuggestion()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        startQuoteRotation()
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        quoteTimer?.invalidate()
        appUsageTracker?.stopTracking()
        if let tracker = appUsageTracker {
            appsUsed = Array(tracker.appUsage.keys)
        }
    }
    
    func reset() {
        pause()
        timeRemaining = 25 * 60
        totalTime = 0
        appsUsed = []
        focusGoals = []
    }
    
    func startQuickTimer(minutes: Int) {
        reset()
        mode = .pomodoro
        timeRemaining = minutes * 60
        start()
    }
    
    private func tick() {
        if mode == .pomodoro {
            if timeRemaining > 0 { timeRemaining -= 1 }
            else { pause() }
        } else {
            totalTime += 1
        }
    }
    
    private func startQuoteRotation() {
        quoteTimer?.invalidate()
        rotateQuote()
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.rotateQuote()
        }
    }
    
    func rotateQuote() {
        let allQuotes = VaultManager().defaultQuotes
        currentQuote = allQuotes.randomElement()
    }
    
    func generateBreakSuggestion() {
        let suggestions = [
            "Take a 5-minute walk outside",
            "Do some stretching exercises",
            "Practice deep breathing for 2 minutes",
            "Drink a glass of water",
            "Look at something 20 feet away for 20 seconds",
            "Do 10 push-ups or squats",
            "Meditate for 3 minutes",
            "Write down three things you're grateful for"
        ]
        breakSuggestion = suggestions.randomElement() ?? "Take a short break"
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
    static var paper: Color { AppTheme.light.colors.background }
    static var paperDark: Color { AppTheme.light.colors.sidebar }
    static var ink: Color { AppTheme.light.colors.textPrimary }
    static var inkLight: Color { AppTheme.light.colors.textSecondary }
    static var moss: Color { AppTheme.light.colors.accent }
    static var seal: Color { AppTheme.light.colors.seal }
    static var divider: Color { AppTheme.light.colors.divider }
    static var warm: Color { AppTheme.light.colors.warm }
    static var buttonBackground: Color { AppTheme.light.colors.buttonBackground }
    static var buttonText: Color { AppTheme.light.colors.buttonText }
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
                        .font(.system(size: 13, weight: selection == option.0 ? .medium : .regular))
                        .foregroundColor(selection == option.0 ? vault.theme.textPrimary : vault.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == option.0 ? vault.theme.warm : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(vault.theme.sidebar)
        .cornerRadius(8)
    }
}

// MARK: - Main Content
struct ContentView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("zenMode") private var zenMode = false
    @AppStorage("currentSection") private var currentSection: AppSection = .study
    @State private var selectedDestination: Destination = .focus
    @State private var showingMoodCheckIn = false
    @State private var showingMenuBarInfo = false
    @EnvironmentObject var vault: VaultManager
    @EnvironmentObject var timerManager: TimerManager
    
    init() {
        NotificationCenter.default.addObserver(forName: .toggleZen, object: nil, queue: .main) { _ in
            let current = UserDefaults.standard.bool(forKey: "zenMode")
            UserDefaults.standard.set(!current, forKey: "zenMode")
        }
    }
    
    enum AppSection: String, CaseIterable {
        case study = "Study"
        case powerUser = "Power User"
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
    
    var studyDestinations: [Destination] { [.focus, .stats, .notes, .schedule, .habits, .settings] }
    var powerUserDestinations: [Destination] { [.weeklyReview, .stats, .settings] }
    
    var currentDestinations: [Destination] {
        switch currentSection {
        case .study: return studyDestinations
        case .powerUser: return powerUserDestinations
        }
    }
    
    var body: some View {
        Group {
            if !hasCompletedSetup {
                OnboardingView(hasCompletedSetup: $hasCompletedSetup, vault: vault)
            } else {
                MainAppView(
                    currentSection: $currentSection,
                    selectedDestination: $selectedDestination,
                    vault: vault,
                    timerManager: timerManager,
                    zenMode: $zenMode,
                    showingMoodCheckIn: $showingMoodCheckIn,
                    showingMenuBarInfo: $showingMenuBarInfo,
                    currentDestinations: currentDestinations
                )
                .environmentObject(vault)
                .environmentObject(timerManager)
            }
        }
        .frame(minWidth: 1000, minHeight: 650)
        .background(vault.theme.background)
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
    @Binding var currentSection: ContentView.AppSection
    @Binding var selectedDestination: ContentView.Destination
    @ObservedObject var vault: VaultManager
    @ObservedObject var timerManager: TimerManager
    @Binding var zenMode: Bool
    @Binding var showingMoodCheckIn: Bool
    @Binding var showingMenuBarInfo: Bool
    let currentDestinations: [ContentView.Destination]
    @State private var showingQuickTimer = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            if !zenMode {
                SidebarView(
                    currentSection: $currentSection,
                    selectedDestination: $selectedDestination,
                    showingQuickTimer: $showingQuickTimer,
                    showingMenuBarInfo: $showingMenuBarInfo,
                    currentDestinations: currentDestinations
                )
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
                .transition(.move(edge: .leading))
            }
        } detail: {
            ZStack {
                vault.theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        if showingMenuBarInfo {
                            Text("Menu Bar Active")
                                .font(.system(size: 11))
                                .foregroundColor(vault.theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(vault.theme.warm)
                                .cornerRadius(4)
                        }
                        
                        Button(action: { withAnimation(.easeInOut) { zenMode.toggle() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: zenMode ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                                Text(zenMode ? "Zen" : "Normal")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(vault.theme.sidebar)
                            .cornerRadius(6)
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
        .navigationTitle(currentSection == .study ? "Sumi — Focus" : "Sumi — Power User")
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Picker("Section", selection: $currentSection) {
                    Text("Study").tag(ContentView.AppSection.study)
                    Text("Power User").tag(ContentView.AppSection.powerUser)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
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
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var currentSection: ContentView.AppSection
    @Binding var selectedDestination: ContentView.Destination
    @Binding var showingQuickTimer: Bool
    @Binding var showingMenuBarInfo: Bool
    let currentDestinations: [ContentView.Destination]
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Section", selection: $currentSection) {
                Text("Study").tag(ContentView.AppSection.study)
                Text("Power User").tag(ContentView.AppSection.powerUser)
            }
            .pickerStyle(.segmented)
            .padding(12)
            
            Divider().background(vault.theme.divider)
            
            HStack(spacing: 10) {
                EnsoLogo()
                Text("墨")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(vault.theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider().background(vault.theme.divider)
            
            VStack(spacing: 2) {
                ForEach(currentDestinations) { destination in
                    SidebarItem(
                        icon: destination.icon,
                        title: destination.rawValue,
                        isSelected: selectedDestination == destination,
                        action: { selectedDestination = destination }
                    )
                }
            }
            .padding(.vertical, 12)
            
            Spacer()
            
            Divider().background(vault.theme.divider)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.system(size: 11))
                        .foregroundColor(vault.theme.textSecondary)
                    Spacer()
                    Text("\(todayMinutes)m")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(vault.theme.divider)
                            .frame(height: 2)
                        Rectangle()
                            .fill(vault.theme.accent)
                            .frame(width: geo.size.width * todayProgress, height: 2)
                    }
                }
                .frame(height: 2)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(vault.getStreak() > 0 ? vault.theme.seal : vault.theme.divider)
                        .frame(width: 5, height: 5)
                    Text("\(vault.getStreak())")
                        .font(.system(size: 10))
                        .foregroundColor(vault.theme.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Button(action: { showingQuickTimer = true }) {
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    Text("Quick Timer")
                        .font(.system(size: 13))
                    Spacer()
                }
                .foregroundColor(vault.theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(vault.theme.sidebar)
        }
        .background(vault.theme.sidebar)
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
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
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

// MARK: - Focus Room with Goals
struct FocusRoomView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var vault: VaultManager
    @State private var showingAddGoal = false
    @State private var newGoalTitle = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                HStack(alignment: .top, spacing: 60) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(todayMinutes)")
                                .font(.system(size: 48, weight: .light, design: .serif))
                                .foregroundColor(vault.theme.textPrimary)
                            Text("min")
                                .font(.system(size: 14))
                                .foregroundColor(vault.theme.textSecondary)
                        }
                        Text("of \(vault.settings.dailyGoal) min")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(vault.getStreak())")
                                .font(.system(size: 48, weight: .light, design: .serif))
                                .foregroundColor(vault.theme.seal)
                            Text("days")
                                .font(.system(size: 14))
                                .foregroundColor(vault.theme.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                TimerDisplayView()
                    .frame(maxWidth: 500)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Focus Goals")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vault.theme.textPrimary)
                        Spacer()
                        Button(action: { showingAddGoal = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(vault.theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if timerManager.focusGoals.isEmpty {
                        Text("No goals set. Click + to add one.")
                            .font(.system(size: 12))
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(timerManager.focusGoals) { goal in
                            HStack {
                                Button(action: { timerManager.toggleGoal(goal) }) {
                                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(goal.isCompleted ? vault.theme.accent : vault.theme.divider)
                                }
                                .buttonStyle(.plain)
                                
                                Text(goal.title)
                                    .strikethrough(goal.isCompleted)
                                    .foregroundColor(goal.isCompleted ? vault.theme.textSecondary : vault.theme.textPrimary)
                                
                                Spacer()
                                
                                Button(action: { timerManager.removeGoal(goal) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(vault.theme.seal.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 60)
                
                if vault.settings.showQuotes, let quote = timerManager.currentQuote {
                    VStack(spacing: 8) {
                        Text("—")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(vault.theme.divider)
                        Text("\"\(quote.text)\"")
                            .font(.system(size: 14, design: .serif))
                            .italic()
                            .foregroundColor(vault.theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Text("— \(quote.author)")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary.opacity(0.6))
                    }
                    .padding(.horizontal, 60)
                    .animation(.easeInOut(duration: 0.5), value: quote.id)
                }
                
                if !timerManager.isRunning && timerManager.breakSuggestion.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smart Break Suggestion")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text(timerManager.breakSuggestion)
                            .font(.system(size: 13))
                            .foregroundColor(vault.theme.textPrimary)
                            .padding(12)
                            .background(vault.theme.warm)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 60)
                }
                
                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(title: $newGoalTitle, timerManager: timerManager)
        }
    }
    
    var todayMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        return vault.dailyStats[key]?.totalMinutes ?? 0
    }
}

struct AddGoalSheet: View {
    @Binding var title: String
    @ObservedObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Focus Goal")
                .font(.system(size: 18, weight: .light, design: .serif))
            
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
        VStack(spacing: 32) {
            ZenSegmentedPicker(
                selection: $timerManager.mode,
                options: [(.pomodoro, "Pomodoro"), (.flow, "Flow")]
            )
            .frame(width: 260)
            
            ZStack {
                Circle()
                    .stroke(vault.theme.divider, lineWidth: 1)
                    .frame(width: 300, height: 300)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(vault.theme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)
                
                VStack(spacing: 16) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 72, weight: .light, design: .serif))
                        .monospacedDigit()
                        .foregroundColor(vault.theme.textPrimary)
                    
                    Text(timerManager.statusText)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(vault.theme.textSecondary)
                }
            }
            
            AmbienceSelector()
            
            HStack(spacing: 20) {
                Button(action: { timerManager.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: timerManager.isRunning ? "pause" : "play.fill")
                            .font(.system(size: 12))
                        Text(timerManager.isRunning ? "Pause" : "Begin")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(vault.theme.buttonText)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(vault.theme.buttonBackground)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: { timerManager.reset() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Reset")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(vault.theme.textPrimary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(vault.theme.sidebar)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(48)
        .background(vault.theme.card)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(vault.theme.divider, lineWidth: 1))
    }
}

// MARK: - Ambience Selector with Audio
struct AmbienceSelector: View {
    @EnvironmentObject var vault: VaultManager
    let ambiances = ["None", "Rain", "Fireplace", "White Noise", "Deep Focus"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Ambience")
                .font(.system(size: 11))
                .foregroundColor(vault.theme.textSecondary)
            
            HStack(spacing: 8) {
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
                            .font(.system(size: 11))
                            .foregroundColor(vault.settings.ambience == amb.lowercased() ? vault.theme.buttonText : vault.theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(vault.settings.ambience == amb.lowercased() ? vault.theme.buttonBackground : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if vault.settings.ambience != "none" {
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(vault.theme.textSecondary)
                    Slider(value: $vault.settings.ambienceVolume, in: 0...1)
                        .tint(vault.theme.accent)
                        .frame(width: 120)
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
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(vault.theme.textPrimary)
            
            HStack(spacing: 12) {
                ForEach([15, 25, 45, 60], id: \.self) { mins in
                    Button { selectedMinutes = mins } label: {
                        Text("\(mins)")
                            .font(.system(size: 14, weight: selectedMinutes == mins ? .medium : .regular))
                            .foregroundColor(selectedMinutes == mins ? vault.theme.textPrimary : vault.theme.textSecondary)
                            .frame(width: 60, height: 40)
                            .background(selectedMinutes == mins ? vault.theme.warm : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("minutes")
                .font(.system(size: 11))
                .foregroundColor(vault.theme.textSecondary)
            
            Spacer()
            
            Button("Begin") {
                timerManager.startQuickTimer(minutes: selectedMinutes)
                dismiss()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(vault.theme.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(vault.theme.buttonBackground)
            .cornerRadius(6)
            
            Button("Cancel") { dismiss() }
                .font(.system(size: 12))
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
                .font(.system(size: 18, weight: .light, design: .serif))
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
                                .font(.system(size: 10))
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
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(vault.theme.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(vault.theme.buttonBackground)
            .cornerRadius(6)
        }
        .padding(32)
        .background(vault.theme.background)
    }
}

// MARK: - Stats Room
struct StatsRoomView: View {
    @State private var selectedPeriod: StatsPeriod = .week
    @EnvironmentObject var vault: VaultManager
    
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
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    
                    HStack(spacing: 0) {
                        ForEach(Array(StatsPeriod.allCases.enumerated()), id: \.offset) { index, period in
                            Button { selectedPeriod = period } label: {
                                Text(period.rawValue)
                                    .font(.system(size: 12, weight: selectedPeriod == period ? .medium : .regular))
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
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text("\(totalHours)h \(totalMinutes)m")
                            .font(.system(size: 36, weight: .light, design: .serif))
                            .foregroundColor(vault.theme.textPrimary)
                        Text("This \(selectedPeriod.rawValue.lowercased())")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Milestone")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        Text(milestone.title)
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundColor(vault.theme.textPrimary)
                        Text("\(Int(vault.getTotalHours()))h of 1000h")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 60)
                
                if !vault.appUsageTracker.appUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Apps This Week")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                        
                        ForEach(vault.appUsageTracker.getTopApps(limit: 5), id: \.0) { app, minutes in
                            HStack {
                                Text(app)
                                    .font(.system(size: 12))
                                    .foregroundColor(vault.theme.textPrimary)
                                Spacer()
                                Text("\(minutes / 60)h \(minutes % 60)m")
                                    .font(.system(size: 12))
                                    .foregroundColor(vault.theme.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(vault.theme.card)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("This Week")
                        .font(.system(size: 11))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    HStack(alignment: .bottom, spacing: 24) {
                        ForEach(0..<7) { day in WeeklyBar(day: day) }
                    }
                    .frame(height: 140)
                }
                .padding(.horizontal, 60)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("The Year")
                        .font(.system(size: 11))
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
                
                Spacer(minLength: 60)
            }
        }
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
                .font(.system(size: 10))
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
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    Button(action: { showingAddHabit = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 11))
                            Text("Add Habit").font(.system(size: 12))
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(vault.theme.textPrimary)
                Text("Streak: \(habit.streak) days")
                    .font(.system(size: 11))
                    .foregroundColor(vault.theme.textSecondary)
            }
            
            Spacer()
            
            Button(action: { vault.toggleHabitCompletion(habit) }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompletedToday ? vault.theme.accent : vault.theme.divider)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(vault.theme.card)
        .cornerRadius(8)
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
                .font(.system(size: 18, weight: .light, design: .serif))
            
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
                        .font(.system(size: 32, weight: .light, design: .serif))
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
                        HStack(spacing: 40) {
                            StatCard(title: "Total Time", value: "\(review.totalMinutes / 60)h \(review.totalMinutes % 60)m")
                            StatCard(title: "Sessions", value: "\(review.sessionsCompleted)")
                            StatCard(title: "Goals Completed", value: "\(review.goalsCompleted)")
                            StatCard(title: "Avg Mood", value: String(format: "%.1f/5", review.moodAverage))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Apps")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.topApps, id: \.0) { app, minutes in
                                HStack {
                                    Text(app)
                                        .font(.system(size: 12))
                                        .foregroundColor(vault.theme.textPrimary)
                                    Spacer()
                                    Text("\(minutes / 60)h \(minutes % 60)m")
                                        .font(.system(size: 12))
                                        .foregroundColor(vault.theme.textSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Achievements")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.achievements, id: \.self) { achievement in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(vault.theme.seal)
                                    Text(achievement)
                                        .font(.system(size: 12))
                                        .foregroundColor(vault.theme.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vault.theme.textPrimary)
                            ForEach(review.insights, id: \.self) { insight in
                                Text(insight)
                                    .font(.system(size: 12))
                                    .foregroundColor(vault.theme.textPrimary)
                            }
                        }
                        .padding(16)
                        .background(vault.theme.card)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 60)
                } else {
                    Text("Click \"Generate Review\" to see your weekly summary.")
                        .foregroundColor(vault.theme.textSecondary)
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
                .font(.system(size: 11))
                .foregroundColor(vault.theme.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundColor(vault.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(vault.theme.card)
        .cornerRadius(8)
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
                        .font(.system(size: 11))
                        .foregroundColor(vault.theme.textSecondary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
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
                        Image(systemName: "plus").font(.system(size: 11))
                        Text("New Note").font(.system(size: 12))
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
                NoteEditorView(note: note, showPreview: $showPreview)
            } else {
                VStack(spacing: 20) {
                    EnsoLogo()
                        .scaleEffect(2)
                    Text("Select a note")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(vault.theme.textSecondary)
                    Text("or create a new one")
                        .font(.system(size: 12))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.6))
                    Button("New Note") { showingNewNote = true }
                        .font(.system(size: 12))
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
                .font(.system(size: 13, weight: isSelected ? .medium : .regular, design: .serif))
                .foregroundColor(vault.theme.textPrimary)
                .lineLimit(1)
            
            Text(note.content.prefix(50))
                .font(.system(size: 11))
                .foregroundColor(vault.theme.textSecondary)
                .lineLimit(2)
            
            Text(note.date, style: .date)
                .font(.system(size: 10))
                .foregroundColor(vault.theme.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(isSelected ? vault.theme.warm : Color.clear)
    }
}

struct NoteEditorView: View {
    @State var note: Note
    @Binding var showPreview: Bool
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Title", text: $note.title)
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .textFieldStyle(.plain)
                    .foregroundColor(vault.theme.textPrimary)
                    .onChange(of: note.title) { _, _ in saveNote() }
                
                Spacer()
                
                HStack(spacing: 4) {
                    FormatButton(icon: "bold", action: { insertFormat("**", "**") })
                    FormatButton(icon: "italic", action: { insertFormat("_", "_") })
                    FormatButton(icon: "strikethrough", action: { insertFormat("~~", "~~") })
                    Divider().frame(height: 16)
                    FormatButton(icon: "number", action: { insertFormat("### ", "") })
                    FormatButton(icon: "quote.opening", action: { insertFormat("> ", "") })
                    Divider().frame(height: 16)
                    Button(action: { showPreview.toggle() }) {
                        Image(systemName: showPreview ? "text.alignleft" : "eye")
                            .font(.system(size: 11))
                            .foregroundColor(vault.theme.textSecondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { deleteNote() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(vault.theme.seal)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                Text("Saved \(timeAgo)")
                    .font(.system(size: 10))
                    .foregroundColor(vault.theme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            
            Divider().background(vault.theme.divider)
            
            if showPreview {
                ScrollView {
                    Text(note.content)
                        .font(.system(size: 14))
                        .foregroundColor(vault.theme.textPrimary)
                        .textSelection(.enabled)
                        .padding(32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(vault.theme.background)
                }
            } else {
                TextEditor(text: $note.content)
                    .font(.system(size: 14))
                    .foregroundColor(vault.theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(32)
                    .background(ZStack {
                        vault.theme.background
                        GridPatternView()
                    })
                    .onChange(of: note.content) { _, _ in saveNote() }
            }
        }
        .background(vault.theme.background)
    }
    
    func insertFormat(_ prefix: String, _ suffix: String) {
        note.content += prefix + "text" + suffix + "\n"
        saveNote()
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
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void
    @EnvironmentObject var vault: VaultManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(vault.theme.textSecondary)
                .padding(6)
        }
        .buttonStyle(.plain)
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
                .font(.system(size: 22, weight: .light, design: .serif))
                .textFieldStyle(.plain)
                .foregroundColor(vault.theme.textPrimary)
            
            TextEditor(text: $content)
                .font(.system(size: 14))
                .foregroundColor(vault.theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 320)
                .padding(16)
                .background(vault.theme.card)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(vault.theme.divider, lineWidth: 1))
            
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundColor(vault.theme.textSecondary)
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save") {
                    let note = Note(id: UUID(), title: title, content: content, date: Date())
                    vault.notes.append(note)
                    vault.saveAllData()
                    dismiss()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(vault.theme.buttonText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(vault.theme.buttonBackground)
                .cornerRadius(6)
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
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                    Spacer()
                    Button(action: { showingAddEvent = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 11))
                            Text("Add Event").font(.system(size: 12))
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
                .font(.system(size: 14, weight: isToday ? .medium : .regular, design: .serif))
                .foregroundColor(isToday ? vault.theme.seal : vault.theme.textPrimary)
                .frame(width: 100, alignment: .leading)
                .padding(.vertical, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                if events.isEmpty {
                    Text("Open")
                        .font(.system(size: 12))
                        .foregroundColor(vault.theme.textSecondary.opacity(0.5))
                        .padding(.vertical, 20)
                } else {
                    ForEach(events) { event in
                        HStack(spacing: 16) {
                            Text(event.startTime)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(vault.theme.textSecondary)
                                .frame(width: 50, alignment: .leading)
                            Text(event.title)
                                .font(.system(size: 13))
                                .foregroundColor(vault.theme.textPrimary)
                            Text("– \(event.endTime)")
                                .font(.system(size: 11))
                                .foregroundColor(vault.theme.textSecondary)
                            
                            Spacer()
                            
                            Button(action: { deleteEvent(event) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
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
                .font(.system(size: 20, weight: .light, design: .serif))
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
                    Text("Starts").font(.system(size: 10)).foregroundColor(vault.theme.textSecondary)
                    TextField("09:00", text: $startTime)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ends").font(.system(size: 10)).foregroundColor(vault.theme.textSecondary)
                    TextField("10:00", text: $endTime)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 12))
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(vault.theme.buttonText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(vault.theme.buttonBackground)
                .cornerRadius(6)
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
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundColor(vault.theme.textPrimary)
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Appearance")
                        .font(.system(size: 14, weight: .medium))
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
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Timer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    SettingRow(title: "Daily Goal", value: $vault.settings.dailyGoal, range: 30...300, step: 10, unit: "min")
                    SettingRow(title: "Study Duration", value: $vault.settings.studyMinutes, range: 15...90, step: 5, unit: "min")
                    SettingRow(title: "Break Duration", value: $vault.settings.breakMinutes, range: 5...30, step: 5, unit: "min")
                    Toggle("Show Quotes During Timer", isOn: $vault.settings.showQuotes)
                        .tint(vault.theme.accent)
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Integrations")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    Toggle("Calendar Integration", isOn: $vault.settings.calendarIntegration)
                        .tint(vault.theme.accent)
                    Toggle("Silence Notifications During Focus", isOn: $vault.settings.silenceNotifications)
                        .tint(vault.theme.accent)
                    Toggle("Track App Usage", isOn: $vault.settings.trackAppUsage)
                        .tint(vault.theme.accent)
                    Toggle("Block Distractions", isOn: $vault.settings.blockDistractions)
                        .tint(vault.theme.accent)
                }
                .padding(24)
                .background(vault.theme.card)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Vault & Data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(vault.theme.textPrimary)
                    
                    HStack {
                        Text(vault.vaultURL?.path ?? "No vault selected")
                            .font(.system(size: 12))
                            .foregroundColor(vault.theme.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Choose Folder") {
                            _ = vault.chooseVaultFolder()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Tip: Choose an iCloud Drive folder for automatic sync across devices")
                        .font(.system(size: 10))
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
                .cornerRadius(8)
                
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
                .font(.system(size: 13))
                .foregroundColor(vault.theme.textPrimary)
            Spacer()
            Text("\(value) \(unit)")
                .font(.system(size: 13, weight: .medium, design: .serif))
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
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                    Text("A Quiet Space For Focused Study")
                        .font(.system(size: 13))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    Spacer()
                    
                    Button("Choose Vault Location") {
                        if vault.chooseVaultFolder() != nil { currentStep = 1 }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(vault.theme.buttonText)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(vault.theme.buttonBackground)
                    .cornerRadius(6)
                }
                .padding(60)
            } else {
                VStack(spacing: 24) {
                    Text("You're All Set")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundColor(vault.theme.textPrimary)
                    Text("Your vault is ready")
                        .font(.system(size: 13))
                        .foregroundColor(vault.theme.textSecondary)
                    
                    Spacer()
                    
                    Button("Begin") { hasCompletedSetup = true }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(vault.theme.buttonText)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(vault.theme.buttonBackground)
                        .cornerRadius(6)
                }
                .padding(60)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(vault.theme.background)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
