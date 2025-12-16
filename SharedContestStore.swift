//
//  SharedContestStore.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation
import WidgetKit

struct WidgetContest: Identifiable, Codable {
    let id: Int
    let name: String
    let startTime: Date?
    let phase: String
}

enum SharedContestStore {
    static let appGroupID = "group.com.fendada.cftoday"
    static let contestKey = "next_contest"

    static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ contest: WidgetContest) {
        let data = try? JSONEncoder().encode(contest)
        suite?.set(data, forKey: contestKey)
    }

    static func load() -> WidgetContest? {
        guard
            let data = suite?.data(forKey: contestKey),
            let contest = try? JSONDecoder().decode(WidgetContest.self, from: data)
        else {
            return nil
        }
        return contest
    }
}
