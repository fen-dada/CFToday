//
//  CFTodayWidget.swift
//  CFTodayWidget
//
//  Created by Fendada on 2025/12/16.
//

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Timeline Entry

struct ContestEntry: TimelineEntry {
    let date: Date
    let contest: WidgetContest?
}


// MARK: - Provider

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> ContestEntry {
        ContestEntry(
            date: Date(),
            contest: WidgetContest(
                id: 0,
                name: "Codeforces Round #999",
                startTime: Date().addingTimeInterval(3600),
                phase: "BEFORE"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ContestEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContestEntry>) -> Void) {
        Task {
            let cached = SharedContestStore.load()
            let contest: WidgetContest?

            if let cached {
                contest = cached
            } else {
                contest = await fetchNextContest()
            }

            let entry = ContestEntry(date: Date(), contest: contest)


            // Refresh every 30 minutes
            let nextRefresh = Date().addingTimeInterval(30 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    // MARK: Fetch Next Contest

    private func fetchNextContest() async -> WidgetContest? {
        let url = URL(string: "https://codeforces.com/api/contest.list")!

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(CFContestResponse.self, from: data)
            guard decoded.status == "OK" else { return nil }

            let filtered = decoded.result
                .filter { $0.phase == "CODING" || $0.phase == "BEFORE" }
                .sorted { (a, b) in
                    let ta = a.startTimeSeconds ?? Int.max
                    let tb = b.startTimeSeconds ?? Int.max
                    return ta < tb
                }

            guard let c = filtered.first else { return nil }

            return WidgetContest(
                id: c.id,
                name: c.name,
                startTime: c.startTimeSeconds.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                phase: c.phase
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Widget Root View

struct CFTodayWidgetEntryView: View {
    let entry: ContestEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidget(entry: entry)
            case .systemMedium:
                MediumWidget(entry: entry)
            case .systemLarge:
                LargeWidget(entry: entry)

            case .accessoryInline:
                LockInline(entry: entry)
            case .accessoryCircular:
                LockCircular(entry: entry)
            case .accessoryRectangular:
                LockRectangular(entry: entry)

            default:
                MediumWidget(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

}

// MARK: - Widget

struct CFTodayWidget: Widget {
    private let kind = "CFTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CFTodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Codeforces Next Contest")
        .description("Shows the next Codeforces contest and countdown.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryInline, .accessoryCircular, .accessoryRectangular
        ])
    }
}

// MARK: - Shared UI Components

private struct MiniPill: View {
    enum Kind { case upcoming, running }

    let text: String
    let kind: Kind

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(foreground)
            .background(Capsule().fill(background))
    }

    private var foreground: Color {
        switch kind {
        case .upcoming: return .blue
        case .running: return .red
        }
    }

    private var background: Color {
        switch kind {
        case .upcoming: return .blue.opacity(0.16)
        case .running: return .red.opacity(0.16)
        }
    }
}

private struct StatusPill: View {
    let phase: String

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.16)))
    }

    private var text: String {
        switch phase {
        case "CODING": return "RUNNING"
        case "BEFORE": return "UPCOMING"
        default: return "—"
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

// MARK: - Small

private struct SmallWidget: View {
    let entry: ContestEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if let c = entry.contest {
                Text(c.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Spacer(minLength: 0)

                if let start = c.startTime {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                            Text(start.formatted(.relative(
                                presentation: .numeric,
                                unitsStyle: .abbreviated
                            )))
                        }

                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                            Text(start.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
            } else {
                Text("No upcoming contests")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 2)
        .padding(.vertical, 12)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Next Contest")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Medium

private struct MediumWidget: View {
    let entry: ContestEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let c = entry.contest {
                Text(c.name)
                    .font(.headline)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    MiniPill(
                        text: c.phase == "CODING" ? "RUNNING" : "UPCOMING",
                        kind: c.phase == "CODING" ? .running : .upcoming
                    )

                    Spacer(minLength: 0)

                    if let start = c.startTime {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(start.formatted(.relative(
                                    presentation: .numeric,
                                    unitsStyle: .abbreviated
                                )))
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    }
                }
            } else {
                Text("No upcoming contests")
                    .font(.headline)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 2)
        .padding(.vertical, 12)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Next Contest")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Large

private struct LargeWidget: View {
    let entry: ContestEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header

            if let c = entry.contest {
                Text(c.name)
                    .font(.title3.bold())
                    .lineLimit(4)

                HStack(spacing: 10) {
                    StatusPill(phase: c.phase)

                    if c.phase == "BEFORE", let start = c.startTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(start, style: .relative)
                        }
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    } else {
                        Label("Running", systemImage: "bolt.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let start = c.startTime {
                    HStack {
                        Label(start.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                Spacer(minLength: 0)

                if c.phase == "BEFORE", let start = c.startTime {
                    CountdownBar(start: start)
                }
            } else {
                Text("No upcoming contests")
                    .font(.headline)
                Spacer()
            }
        }
        .padding(8)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Next Contest")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

private struct LockInline: View {
    let entry: ContestEntry

    var body: some View {
        if let c = entry.contest {
            if c.phase == "CODING" {
                Label("CF: Running", systemImage: "trophy.fill")
            } else if let start = c.startTime {
                Label("CF \(start, style: .relative)", systemImage: "trophy.fill")
            } else {
                Label("CF: Upcoming", systemImage: "trophy.fill")
            }
        } else {
            Label("CF: No contest", systemImage: "trophy.fill")
        }
    }
}

private struct LockCircular: View {
    let entry: ContestEntry

    var body: some View {
        if let c = entry.contest, let start = c.startTime, c.phase == "BEFORE" {
            // 用系统相对时间，锁屏会自动刷新显示
            Text(start, style: .relative)
                .font(.caption2.monospacedDigit())
                .minimumScaleFactor(0.6)
        } else if let c = entry.contest, c.phase == "CODING" {
            Image(systemName: "bolt.fill")
        } else {
            Image(systemName: "trophy.fill")
        }
    }
}

private struct LockRectangular: View {
    let entry: ContestEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                Text("Codeforces")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let c = entry.contest {
                Text(c.name)
                    .font(.headline)
                    .lineLimit(1)

                if c.phase == "CODING" {
                    Text("Running now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let start = c.startTime {
                    Text(start, style: .relative)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("No upcoming contests")
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }
}


// MARK: - Countdown Bar (Large only)

private struct CountdownBar: View {
    let start: Date

    var body: some View {
        let total: TimeInterval = 24 * 3600
        let remaining = max(0, start.timeIntervalSinceNow)
        let progress = 1 - min(1, remaining / total)

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Countdown")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(start, style: .relative)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let width = geo.size.width

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(.tertiarySystemFill))

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: width * progress)
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator.opacity(0.2))
        )
    }
}
