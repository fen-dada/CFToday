import SwiftUI
import WidgetKit

struct ContestsView: View {

    @State private var contests: [CFContest] = []
    @State private var isLoading = false

    // MARK: - Load

    private func loadContests() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await CodeforcesAPI.fetchContests()
            let now = Date().timeIntervalSince1970

            let filtered = all
                .filter { $0.phase == "CODING" || $0.phase == "BEFORE" }
                .sorted { a, b in
                    ContestFormatting.distanceToNow(contest: a, now: now)
                    < ContestFormatting.distanceToNow(contest: b, now: now)
                }

            contests = filtered

            // ✅ 给小组件写入“下一场比赛”（Running 优先，否则 Upcoming）
            if let next = filtered.first {
                let widgetContest = WidgetContest(
                    id: next.id,
                    name: next.name,
                    startTime: next.startTimeSeconds.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                    phase: next.phase
                )

                SharedContestStore.save(widgetContest)

                // ✅ 通知 widget 立刻刷新（避免等 30 分钟）
                WidgetCenter.shared.reloadTimelines(ofKind: "CFTodayWidget")
            }

        } catch {
            print("Failed to load contests:", error)
        }
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(contests) { c in
                            ContestCard(contest: c)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 16) // ✅ 关键：左右留白
                }
            }
            .navigationTitle("Contests")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadContests()
            }
        }
    }
}

// MARK: - Small UI Components

private struct StatusBadge: View {
    let phase: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }

    private var text: String {
        switch phase {
        case "CODING": return "Running"
        case "BEFORE": return "Upcoming"
        default: return ""
        }
    }

    private var color: Color {
        switch phase {
        case "CODING": return .red
        case "BEFORE": return .blue
        default: return .gray
        }
    }
}

private struct ContestCard: View {
    let contest: CFContest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                Text(contest.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                StatusBadge(phase: contest.phase)
            }

            HStack(spacing: 12) {
                Label(ContestFormatting.timeText(for: contest), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(ContestFormatting.durationText(for: contest), systemImage: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial) // ✅ iOS 毛玻璃质感
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator.opacity(0.25))
        )
    }
}

#Preview {
    ContestsView()
}
