//
//  RatingChartView.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import SwiftUI
import Charts

struct RatingChartView: View {
    let changes: [CFRatingChange]

    @State private var selected: CFRatingChange?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating")
                .font(.title3.bold())

            Chart(changes) { c in
                LineMark(
                    x: .value("Time", Date(timeIntervalSince1970: TimeInterval(c.ratingUpdateTimeSeconds))),
                    y: .value("Rating", c.newRating)
                )

                PointMark(
                    x: .value("Time", Date(timeIntervalSince1970: TimeInterval(c.ratingUpdateTimeSeconds))),
                    y: .value("Rating", c.newRating)
                )
                .symbolSize(20)
            }
            .frame(height: 220)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let xPos = value.location.x - origin.x
                                    if let date: Date = proxy.value(atX: xPos) {
                                        selected = nearest(to: date)
                                    }
                                }
                        )
                }
            }
            .chartBackground { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.separator.opacity(0.25))
            )

            if let s = selected {
                selectedCard(s)
            } else if let last = changes.last {
                selectedCard(last)
            }
        }
        .padding(.vertical, 8)
    }

    private func nearest(to date: Date) -> CFRatingChange? {
        guard !changes.isEmpty else { return nil }
        let t = date.timeIntervalSince1970
        return changes.min(by: { abs(TimeInterval($0.ratingUpdateTimeSeconds) - t) < abs(TimeInterval($1.ratingUpdateTimeSeconds) - t) })
    }

    private func selectedCard(_ c: CFRatingChange) -> some View {
        let delta = c.newRating - c.oldRating
        let sign = delta >= 0 ? "+" : ""
        let when = Date(timeIntervalSince1970: TimeInterval(c.ratingUpdateTimeSeconds))
            .formatted(date: .abbreviated, time: .omitted)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(c.contestName)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text("\(c.newRating)")
                    .font(.headline)
                    .monospacedDigit()
            }

            HStack(spacing: 12) {
                Label("\(c.oldRating) → \(c.newRating)", systemImage: "arrow.right")
                    .foregroundStyle(.secondary)

                Text("\(sign)\(delta)")
                    .font(.subheadline.bold())
                    .foregroundStyle(delta >= 0 ? .green : .red)
                    .monospacedDigit()
            }
            .font(.subheadline)

            HStack {
                Text("Rank \(c.rank)")
                Spacer()
                Text(when)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.separator.opacity(0.25))
        )
    }
}
