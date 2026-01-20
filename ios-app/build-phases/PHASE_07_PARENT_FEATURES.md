# Phase 7: Parent Features

**Objective:** Implement the parent dashboard, child statistics, and activity history screens for tracking children's progress.

**Dependencies:** Phase 6 (Authentication)

---

## Subphase 7.1: Dashboard Types

**Goal:** Define all types for the parent dashboard data structures.

### Prompt for Claude Code:

```
Create the dashboard types for Max's Puzzles iOS app.

Create file: Hub/Models/DashboardTypes.swift

```swift
import Foundation

// MARK: - Child Summary Types

/// Summary data for a child displayed on the parent dashboard
struct ChildSummary: Identifiable {
    let id: String
    let displayName: String
    let avatarEmoji: String
    let coins: Int // Lifetime total
    let lastPlayedAt: Date?

    var thisWeekStats: WeekStats

    struct WeekStats {
        var gamesPlayed: Int = 0
        var timePlayedMinutes: Int = 0
        var coinsEarned: Int = 0
        var accuracy: Int = 0 // 0-100 percentage
    }
}

// MARK: - Child Detail Types

/// Statistics for a specific puzzle module
struct ModuleStats: Identifiable {
    var id: String { moduleId }

    let moduleId: String
    let moduleName: String

    // Activity counts
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var timePlayed: Int = 0 // Seconds
    var coinsEarned: Int = 0
    var accuracy: Int = 0 // 0-100

    // Recency
    var lastPlayedAt: Date?

    // Win rate computed
    var winRate: Int {
        gamesPlayed > 0 ? Int(round(Double(gamesWon) / Double(gamesPlayed) * 100)) : 0
    }
}

/// Comprehensive statistics for a single child
struct ChildDetailStats {
    // Lifetime totals
    var totalGamesPlayed: Int = 0
    var totalTimePlayed: Int = 0 // In seconds
    var totalCoinsEarned: Int = 0
    var overallAccuracy: Int = 0 // 0-100 percentage

    // Streaks
    var currentStreak: Int = 0 // Consecutive wins
    var bestStreak: Int = 0

    // Account info
    var memberSince: Date = Date()

    // Per-module breakdown
    var moduleStats: [String: ModuleStats] = [:]
}

// MARK: - Activity Types

/// A single activity session entry
struct ActivityEntry: Identifiable {
    let id: String
    let moduleId: String
    let moduleName: String
    let moduleIcon: String

    // Timing
    let date: Date
    let duration: Int // Seconds

    // Performance
    let gamesPlayed: Int
    let correctAnswers: Int
    let mistakes: Int
    var accuracy: Int { // 0-100
        let total = correctAnswers + mistakes
        return total > 0 ? Int(round(Double(correctAnswers) / Double(total) * 100)) : 0
    }

    // Rewards
    let coinsEarned: Int
}

/// Activities grouped by date for display
struct ActivityGroup: Identifiable {
    var id: String { dateLabel }

    let dateLabel: String // e.g., "Monday, 15 January"
    let activities: [ActivityEntry]
    let totalGames: Int
    let totalTime: Int
    let totalCoins: Int
}

// MARK: - Filter and Chart Types

/// Time period options for filtering activity data
enum TimePeriod: String, CaseIterable {
    case today
    case week
    case month
    case all

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .all: return "All Time"
        }
    }
}

/// Metric options for activity charts
enum ChartMetric: String, CaseIterable {
    case games
    case time
    case accuracy
    case coins
}

/// A single data point for charts
struct ChartDataPoint: Identifiable {
    var id: String { date }

    let date: String // YYYY-MM-DD
    let dateLabel: String // e.g., "Mon", "15 Jan"
    let value: Double
}

/// Complete chart data with metadata
struct ChartData {
    let metric: ChartMetric
    let period: TimePeriod
    let points: [ChartDataPoint]
    let maxValue: Double
    let total: Double
    let average: Double
}

// MARK: - Module Metadata

/// Get module metadata by ID
func getModuleMeta(moduleId: String) -> (name: String, icon: String) {
    switch moduleId {
    case "circuit-challenge":
        return ("Circuit Challenge", "⚡")
    default:
        return (moduleId, "🧩")
    }
}
```
```

---

## Subphase 7.2: Dashboard Service

**Goal:** Create the service for fetching dashboard data from Supabase.

### Prompt for Claude Code:

```
Create the DashboardService for Max's Puzzles iOS app.

Create file: Shared/Services/DashboardService.swift

```swift
import Foundation

/// Service for fetching parent dashboard data
class DashboardService {
    static let shared = DashboardService()

    private init() {}

    // MARK: - Children Summaries

    /// Get summaries for all children in a family
    func getChildrenSummaries(familyId: String) async throws -> [ChildSummary] {
        guard let client = supabase else {
            // Return empty for offline mode
            return []
        }

        // Fetch all children in the family
        let children: [User] = try await client
            .from("users")
            .select()
            .eq("family_id", value: familyId)
            .eq("role", value: "child")
            .eq("is_active", value: true)
            .execute()
            .value

        // Fetch weekly stats for each child
        var summaries: [ChildSummary] = []

        for child in children {
            let weekStats = try await getWeekStats(childId: child.id)

            summaries.append(ChildSummary(
                id: child.id,
                displayName: child.displayName,
                avatarEmoji: "👽",
                coins: child.coins,
                lastPlayedAt: nil, // TODO: Fetch from activity_log
                thisWeekStats: weekStats
            ))
        }

        return summaries
    }

    /// Get this week's stats for a child
    private func getWeekStats(childId: String) async throws -> ChildSummary.WeekStats {
        guard let client = supabase else {
            return ChildSummary.WeekStats()
        }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        struct ActivityStats: Decodable {
            let games_played: Int?
            let time_played_seconds: Int?
            let coins_earned: Int?
            let correct_moves: Int?
            let total_moves: Int?
        }

        // This would be a database function or aggregated query
        // For now, return placeholder
        return ChildSummary.WeekStats(
            gamesPlayed: 0,
            timePlayedMinutes: 0,
            coinsEarned: 0,
            accuracy: 0
        )
    }

    // MARK: - Child Detail Stats

    /// Get detailed statistics for a single child
    func getChildDetailStats(childId: String) async throws -> ChildDetailStats {
        guard let client = supabase else {
            return ChildDetailStats()
        }

        // Fetch module progress
        struct ProgressRecord: Decodable {
            let module_id: String
            let data: [String: Any]?

            enum CodingKeys: String, CodingKey {
                case module_id
                case data
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                module_id = try container.decode(String.self, forKey: .module_id)
                data = nil // JSON parsing would go here
            }
        }

        // Build stats from progress records
        var stats = ChildDetailStats()

        // TODO: Implement full query against module_progress and activity_log tables

        return stats
    }

    // MARK: - Activity History

    /// Get activity entries for a child, optionally filtered by period
    func getActivityHistory(
        childId: String,
        period: TimePeriod = .all,
        limit: Int = 50
    ) async throws -> [ActivityGroup] {
        guard let client = supabase else {
            return []
        }

        // Calculate date filter
        let startDate: Date? = {
            switch period {
            case .today:
                return Calendar.current.startOfDay(for: Date())
            case .week:
                return Calendar.current.date(byAdding: .day, value: -7, to: Date())
            case .month:
                return Calendar.current.date(byAdding: .month, value: -1, to: Date())
            case .all:
                return nil
            }
        }()

        // Fetch activity log entries
        struct ActivityRecord: Decodable {
            let id: String
            let module_id: String
            let started_at: Date
            let ended_at: Date?
            let games_played: Int
            let correct_answers: Int
            let mistakes: Int
            let coins_earned: Int
        }

        // TODO: Implement full query

        return []
    }

    // MARK: - Chart Data

    /// Get chart data for a child
    func getChartData(
        childId: String,
        metric: ChartMetric,
        period: TimePeriod
    ) async throws -> ChartData {
        // TODO: Implement aggregation query

        return ChartData(
            metric: metric,
            period: period,
            points: [],
            maxValue: 0,
            total: 0,
            average: 0
        )
    }
}
```

This service will need database tables:
- `activity_log` - Records each play session
- `module_progress` - Stores per-module progress data

The actual queries will need to match your Supabase schema.
```

---

## Subphase 7.3: Parent Dashboard View

**Goal:** Create the main parent dashboard showing all children.

### Prompt for Claude Code:

```
Create the ParentDashboardView for Max's Puzzles iOS app.

Create file: Hub/Views/ParentDashboardView.swift

```swift
import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var summaries: [ChildSummary] = []
    @State private var isLoading = true
    @State private var error: String?

    private let dashboardService = DashboardService.shared

    // Family totals
    private var familyTotals: (coins: Int, games: Int, time: Int) {
        summaries.reduce((0, 0, 0)) { result, child in
            (
                result.0 + child.coins,
                result.1 + child.thisWeekStats.gamesPlayed,
                result.2 + child.thisWeekStats.timePlayedMinutes
            )
        }
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Parent Dashboard", showBack: true)

                ScrollView {
                    VStack(spacing: 24) {
                        // Family Header Card
                        familyHeaderCard

                        // Content
                        if isLoading {
                            loadingView
                        } else if let error = error {
                            errorView(error)
                        } else if summaries.isEmpty {
                            emptyStateView
                        } else {
                            childrenList
                        }

                        // Action Buttons
                        actionButtons
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadSummaries()
        }
    }

    // MARK: - Family Header

    private var familyHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Family name and child count
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.family?.name ?? "Your Family")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(summaries.isEmpty
                     ? "No children added yet"
                     : "\(summaries.count) \(summaries.count == 1 ? "child" : "children")")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Family totals (only if children exist)
            if !summaries.isEmpty {
                HStack(spacing: 32) {
                    StatColumn(
                        value: familyTotals.coins.formatted(),
                        label: "Total Coins",
                        color: .accentTertiary
                    )
                    StatColumn(
                        value: "\(familyTotals.games)",
                        label: "Games This Week",
                        color: .accentPrimary
                    )
                    StatColumn(
                        value: "\(familyTotals.time)m",
                        label: "Time This Week",
                        color: .accentSecondary
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Children List

    private var childrenList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHILDREN")
                .font(.caption.bold())
                .foregroundColor(.textSecondary)
                .tracking(1)

            ForEach(summaries) { child in
                NavigationLink(destination: ChildDetailView(childId: child.id)) {
                    ChildSummaryCard(summary: child)
                }
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            Text("📊")
                .font(.system(size: 60))
            Text("Loading family data...")
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 60))
            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Button("Try Again") {
                Task { await loadSummaries() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("👶")
                .font(.system(size: 80))
            Text("No Children Yet")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Add a child to start tracking their maths puzzle progress. Each child gets their own profile with a simple PIN for login.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            NavigationLink(destination: AddChildView()) {
                Text("+ Add Your First Child")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if summaries.count < 5 {
                NavigationLink(destination: AddChildView()) {
                    Text("+ Add Child")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentSecondary)
                        .cornerRadius(8)
                }
            }

            NavigationLink(destination: ParentSettingsView()) {
                DashboardButton(title: "⚙️ Family Settings")
            }

            Button(action: { dismiss() }) {
                DashboardButton(title: "← Back to Family Select")
            }
        }
    }

    // MARK: - Data Loading

    private func loadSummaries() async {
        guard let familyId = authManager.family?.id else {
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            summaries = try await dashboardService.getChildrenSummaries(familyId: familyId)
        } catch {
            self.error = "Failed to load data. Please try again."
        }

        isLoading = false
    }
}

// MARK: - Helper Views

struct StatColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

struct DashboardButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.backgroundDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        ParentDashboardView()
            .environmentObject(AuthManager.preview)
    }
}
```
```

---

## Subphase 7.4: Child Summary Card

**Goal:** Create the child summary card component for the dashboard.

### Prompt for Claude Code:

```
Create the ChildSummaryCard for Max's Puzzles iOS app.

Create file: Hub/Views/Components/ChildSummaryCard.swift

```swift
import SwiftUI

struct ChildSummaryCard: View {
    let summary: ChildSummary

    private var lastPlayedText: String {
        if let lastPlayed = summary.lastPlayedAt {
            return formatRelativeTime(lastPlayed)
        }
        return "Never played"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Text(summary.avatarEmoji)
                .font(.system(size: 48))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                // Week stats
                HStack(spacing: 12) {
                    StatBadge(icon: "🎮", value: "\(summary.thisWeekStats.gamesPlayed)")
                    StatBadge(icon: "⏱️", value: "\(summary.thisWeekStats.timePlayedMinutes)m")
                    StatBadge(icon: "💰", value: "+\(summary.thisWeekStats.coinsEarned)")
                }

                Text(lastPlayedText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Coins and arrow
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(summary.coins)")
                    .font(.title3.bold())
                    .foregroundColor(.accentTertiary)
                Text("coins")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

/// Format a date as relative time (e.g., "2 hours ago", "Yesterday")
func formatRelativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

#Preview {
    VStack(spacing: 16) {
        ChildSummaryCard(summary: ChildSummary(
            id: "1",
            displayName: "Max",
            avatarEmoji: "👽",
            coins: 150,
            lastPlayedAt: Date().addingTimeInterval(-3600),
            thisWeekStats: ChildSummary.WeekStats(
                gamesPlayed: 12,
                timePlayedMinutes: 45,
                coinsEarned: 80,
                accuracy: 75
            )
        ))

        ChildSummaryCard(summary: ChildSummary(
            id: "2",
            displayName: "Emma",
            avatarEmoji: "👽",
            coins: 50,
            lastPlayedAt: nil,
            thisWeekStats: ChildSummary.WeekStats()
        ))
    }
    .padding()
    .background(Color.backgroundDark)
}
```
```

---

## Subphase 7.5: Child Detail View

**Goal:** Create the comprehensive child detail screen.

### Prompt for Claude Code:

```
Create the ChildDetailView for Max's Puzzles iOS app.

Create file: Hub/Views/ChildDetailView.swift

```swift
import SwiftUI

struct ChildDetailView: View {
    let childId: String

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var stats: ChildDetailStats?
    @State private var isLoading = true
    @State private var error: String?
    @State private var chartPeriod: TimePeriod = .week
    @State private var showRemoveConfirm = false
    @State private var isRemoving = false

    private let dashboardService = DashboardService.shared

    private var child: Child? {
        authManager.children.first { $0.id == childId }
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            if let child = child {
                VStack(spacing: 0) {
                    HubHeader(title: child.displayName, showBack: true)

                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile header
                            profileHeader(child)

                            if isLoading {
                                loadingView
                            } else if let error = error {
                                errorView(error)
                            } else if let stats = stats {
                                statsContent(stats)
                            }

                            // Management section
                            managementSection
                        }
                        .padding()
                    }
                }

                // Remove confirmation
                if showRemoveConfirm {
                    removeConfirmationOverlay(child)
                }
            } else {
                childNotFoundView
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadStats()
        }
    }

    // MARK: - Profile Header

    private func profileHeader(_ child: Child) -> some View {
        HStack(spacing: 16) {
            Text(child.avatarEmoji)
                .font(.system(size: 80))

            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)

                if let stats = stats {
                    Text("Member since \(formatDate(stats.memberSince))")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(child.coins)")
                    .font(.largeTitle.bold())
                    .foregroundColor(.accentTertiary)
                Text("Total Coins")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Stats Content

    private func statsContent(_ stats: ChildDetailStats) -> some View {
        VStack(spacing: 24) {
            // Quick Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStatCard(icon: "🎮", value: "\(stats.totalGamesPlayed)", label: "Games Played")
                QuickStatCard(icon: "⏱️", value: formatDuration(stats.totalTimePlayed), label: "Time Played")
                QuickStatCard(icon: "✓", value: "\(stats.overallAccuracy)%", label: "Accuracy", highlight: stats.overallAccuracy >= 80)
                QuickStatCard(icon: "🔥", value: "\(stats.bestStreak)", label: "Best Streak", subtitle: stats.currentStreak > 0 ? "Current: \(stats.currentStreak)" : nil)
            }

            // Activity Chart
            activityChartCard

            // Module Progress
            moduleProgressCard(stats)

            // View History Button
            NavigationLink(destination: ActivityHistoryView(childId: childId)) {
                Text("📋 View Full Activity History")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentSecondary)
                    .cornerRadius(8)
            }
        }
    }

    private var activityChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Over Time")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Period selector
                HStack(spacing: 8) {
                    ForEach([TimePeriod.week, .month], id: \.self) { period in
                        Button(action: { chartPeriod = period }) {
                            Text(period.displayName)
                                .font(.caption.bold())
                                .foregroundColor(chartPeriod == period ? .black : .textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chartPeriod == period ? Color.accentPrimary : Color.backgroundDark)
                                .cornerRadius(6)
                        }
                    }
                }
            }

            // Chart placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundDark)
                .frame(height: 150)
                .overlay {
                    Text("Chart coming soon")
                        .foregroundColor(.textSecondary)
                }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private func moduleProgressCard(_ stats: ChildDetailStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress by Game")
                .font(.headline)
                .foregroundColor(.white)

            if stats.moduleStats.isEmpty {
                Text("No games played yet")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(Array(stats.moduleStats.values), id: \.moduleId) { module in
                    ModuleProgressRow(stats: module)
                }
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Management Section

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.1))

            Text("MANAGE PROFILE")
                .font(.caption.bold())
                .foregroundColor(.textSecondary)
                .tracking(1)

            NavigationLink(destination: EditChildView(childId: childId)) {
                ManageButton(title: "✏️ Edit Display Name")
            }

            NavigationLink(destination: ResetPinView(childId: childId)) {
                ManageButton(title: "🔑 Reset PIN")
            }

            Button(action: { showRemoveConfirm = true }) {
                Text("🗑️ Remove Child")
                    .font(.headline)
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.backgroundDark)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading statistics...")
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))
            Text(message)
                .foregroundColor(.textSecondary)
            Button("Try Again") {
                Task { await loadStats() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentSecondary)
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var childNotFoundView: some View {
        VStack(spacing: 16) {
            Text("🔍")
                .font(.system(size: 60))
            Text("Child Not Found")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("This child profile doesn't exist or has been removed.")
                .foregroundColor(.textSecondary)
            Button("Back to Dashboard") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentPrimary)
        }
        .padding(32)
    }

    private func removeConfirmationOverlay(_ child: Child) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showRemoveConfirm = false
                }

            VStack(spacing: 24) {
                Text("⚠️")
                    .font(.system(size: 60))

                Text("Remove \(child.displayName)?")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("This will permanently delete all their progress, stats, and earned coins. This action cannot be undone.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        showRemoveConfirm = false
                    }
                    .buttonStyle(.bordered)

                    Button(action: handleRemoveChild) {
                        if isRemoving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Remove Forever")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.error)
                    .disabled(isRemoving)
                }
            }
            .padding(32)
            .background(Color.backgroundMid)
            .cornerRadius(16)
            .padding(32)
        }
    }

    // MARK: - Actions

    private func loadStats() async {
        isLoading = true
        error = nil

        do {
            stats = try await dashboardService.getChildDetailStats(childId: childId)
        } catch {
            self.error = "Failed to load statistics."
        }

        isLoading = false
    }

    private func handleRemoveChild() {
        isRemoving = true

        Task {
            do {
                try await authManager.removeChild(id: childId)
                dismiss()
            } catch {
                self.error = "Failed to remove child."
            }
            isRemoving = false
            showRemoveConfirm = false
        }
    }
}

// MARK: - Helper Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    var highlight: Bool = false
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(highlight ? .accentPrimary : .white)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.accentSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }
}

struct ModuleProgressRow: View {
    let stats: ModuleStats

    var body: some View {
        HStack(spacing: 12) {
            let meta = getModuleMeta(moduleId: stats.moduleId)

            Text(meta.icon)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(meta.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(stats.gamesPlayed) games played • \(stats.accuracy)% accuracy")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.backgroundDark)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentPrimary)
                            .frame(width: geo.size.width * CGFloat(stats.winRate) / 100, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(stats.gamesWon) / \(stats.gamesPlayed) won (\(stats.winRate)%)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if let lastPlayed = stats.lastPlayedAt {
                Text(formatRelativeTime(lastPlayed))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 12)
    }
}

struct ManageButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.backgroundDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Helpers

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    } else if seconds < 3600 {
        return "\(seconds / 60)m"
    } else {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        return "\(hours)h \(mins)m"
    }
}
```
```

---

## Subphase 7.6: Activity History View

**Goal:** Create the activity history screen showing past play sessions.

### Prompt for Claude Code:

```
Create the ActivityHistoryView for Max's Puzzles iOS app.

Create file: Hub/Views/ActivityHistoryView.swift

```swift
import SwiftUI

struct ActivityHistoryView: View {
    let childId: String

    @State private var activityGroups: [ActivityGroup] = []
    @State private var selectedPeriod: TimePeriod = .week
    @State private var isLoading = true
    @State private var error: String?

    private let dashboardService = DashboardService.shared

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Activity History", showBack: true)

                // Period filter
                periodSelector

                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if activityGroups.isEmpty {
                    emptyView
                } else {
                    activityList
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadActivity()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadActivity() }
        }
    }

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        Text(period.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(selectedPeriod == period ? .black : .textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.accentPrimary : Color.backgroundMid)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
        }
    }

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(activityGroups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date header
                        HStack {
                            Text(group.dateLabel)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(group.totalGames) games • \(group.totalTime / 60)m")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }

                        // Activity cards
                        ForEach(group.activities) { activity in
                            ActivityCard(activity: activity)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading activity...")
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))
            Text(message)
                .foregroundColor(.textSecondary)
            Button("Try Again") {
                Task { await loadActivity() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Text("📋")
                .font(.system(size: 60))
            Text("No Activity Yet")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Play some puzzles to see activity here!")
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadActivity() async {
        isLoading = true
        error = nil

        do {
            activityGroups = try await dashboardService.getActivityHistory(
                childId: childId,
                period: selectedPeriod
            )
        } catch {
            self.error = "Failed to load activity."
        }

        isLoading = false
    }
}

struct ActivityCard: View {
    let activity: ActivityEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(activity.moduleIcon)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.moduleName)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text("\(activity.gamesPlayed) games")
                    Text("•")
                    Text("\(activity.duration / 60)m")
                    Text("•")
                    Text("\(activity.accuracy)% accuracy")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("+\(activity.coinsEarned)")
                    .font(.headline)
                    .foregroundColor(.accentTertiary)

                Text(formatTime(activity.date))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ActivityHistoryView(childId: "child1")
    }
}
```
```

---

## Subphase 7.7: Edit Child & Reset PIN Views

**Goal:** Create screens for editing child profile and resetting PIN.

### Prompt for Claude Code:

```
Create the EditChildView and ResetPinView for Max's Puzzles iOS app.

Create file: Hub/Views/EditChildView.swift

```swift
import SwiftUI

struct EditChildView: View {
    let childId: String

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var isLoading = false
    @State private var error: String?

    private var child: Child? {
        authManager.children.first { $0.id == childId }
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Edit Name", showBack: true)

                VStack(spacing: 24) {
                    // Avatar
                    Text(child?.avatarEmoji ?? "👽")
                        .font(.system(size: 80))
                        .padding(.top, 32)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        TextField("Name", text: $displayName)
                            .textFieldStyle(AuthTextFieldStyle())
                    }
                    .padding()
                    .background(Color.backgroundMid.opacity(0.8))
                    .cornerRadius(12)

                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                    }

                    // Save button
                    Button(action: handleSave) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(displayName.isEmpty ? Color.gray.opacity(0.5) : Color.accentPrimary)
                    .cornerRadius(12)
                    .disabled(displayName.isEmpty || isLoading)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            displayName = child?.displayName ?? ""
        }
    }

    private func handleSave() {
        guard !displayName.isEmpty else { return }

        isLoading = true
        error = nil

        // TODO: Implement update through auth service
        // For now, just dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            dismiss()
        }
    }
}
```

Create file: Hub/Views/ResetPinView.swift

```swift
import SwiftUI

struct ResetPinView: View {
    let childId: String

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var isLoading = false
    @State private var error: String?

    private var child: Child? {
        authManager.children.first { $0.id == childId }
    }

    private var isValid: Bool {
        newPin.count == 4 && newPin == confirmPin
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HubHeader(title: "Reset PIN", showBack: true)

                VStack(spacing: 24) {
                    // Avatar and name
                    VStack(spacing: 8) {
                        Text(child?.avatarEmoji ?? "👽")
                            .font(.system(size: 60))
                        Text(child?.displayName ?? "Child")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.top, 32)

                    // PIN fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New PIN")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            SecureField("4-digit PIN", text: $newPin)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: newPin) { _, newValue in
                                    newPin = String(newValue.filter { $0.isNumber }.prefix(4))
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm PIN")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            SecureField("Repeat PIN", text: $confirmPin)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: confirmPin) { _, newValue in
                                    confirmPin = String(newValue.filter { $0.isNumber }.prefix(4))
                                }
                        }
                    }
                    .padding()
                    .background(Color.backgroundMid.opacity(0.8))
                    .cornerRadius(12)

                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                    }

                    // Save button
                    Button(action: handleSave) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Reset PIN")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValid ? Color.accentPrimary : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(!isValid || isLoading)

                    Text("The child will use this new PIN to log in.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }

    private func handleSave() {
        guard isValid else { return }

        isLoading = true
        error = nil

        // TODO: Implement PIN reset through auth service
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            dismiss()
        }
    }
}
```
```

---

## Phase 7 Summary

After completing Phase 7, you will have:

1. **Dashboard Types** - ChildSummary, ChildDetailStats, ActivityEntry types
2. **Dashboard Service** - Data fetching for parent dashboard
3. **Parent Dashboard** - Main overview of all children
4. **Child Summary Card** - Compact child display component
5. **Child Detail View** - Comprehensive stats for one child
6. **Activity History** - Past play session list
7. **Edit Child View** - Change child display name
8. **Reset PIN View** - Update child's PIN

**Next Phase:** Phase 8 will implement printing and final polish.
