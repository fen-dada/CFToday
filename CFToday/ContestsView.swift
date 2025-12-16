import SwiftUI

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

            // 只保留 Running/Upcoming，按距离现在升序
            contests = all
                .filter { $0.phase == "CODING" || $0.phase == "BEFORE" }
                .sorted { a, b in
                    ContestFormatting.distanceToNow(contest: a, now: now)
                    < ContestFormatting.distanceToNow(contest: b, now: now)
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
