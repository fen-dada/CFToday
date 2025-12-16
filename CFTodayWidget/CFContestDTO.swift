//
//  CFContestDTO.swift
//  CFTodayWidgetExtension
//
//  Created by Fendada on 2025/12/16.
//

import Foundation

struct CFContestResponse: Codable {
    let status: String
    let result: [CFContest]
}

struct CFContest: Codable {
    let id: Int
    let name: String
    let startTimeSeconds: Int?
    let phase: String
}
