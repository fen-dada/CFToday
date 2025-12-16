//
//  ContestFormatting.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation

enum ContestFormatting {

    /// 距离现在的秒数（用于排序）
    /// - Running: 0
    /// - Upcoming: start - now
    /// - Others: +∞
    static func distanceToNow(contest: CFContest, now: TimeInterval) -> TimeInterval {
        switch contest.phase {
        case "CODING":
            return 0
        case "BEFORE":
            if let start = contest.startTimeSeconds {
                return TimeInterval(start) - now
            } else {
                return .infinity
            }
        default:
            return .infinity
        }
    }

    /// 显示开始时间 / 状态（你可以后面再改成 “Starts in …”）
    static func timeText(for contest: CFContest) -> String {
        switch contest.phase {
        case "CODING":
            return "Running"
        case "BEFORE":
            if let start = contest.startTimeSeconds {
                let date = Date(timeIntervalSince1970: TimeInterval(start))
                return "Starts \(date.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Upcoming"
            }
        default:
            return "Finished"
        }
    }

    /// 比赛持续时间
    static func durationText(for contest: CFContest) -> String {
        let hours = contest.durationSeconds / 3600
        let minutes = (contest.durationSeconds % 3600) / 60
        if minutes == 0 {
            return "\(hours)h"
        } else if hours == 0 {
            return "\(minutes)m"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}
