//
//  CodeforcesAPI.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation

// MARK: - API Response Wrapper

struct CFContestResponse: Codable {
    let status: String
    let result: [CFContest]
}

// MARK: - DTO

struct CFContest: Codable, Identifiable {
    let id: Int
    let name: String
    let startTimeSeconds: Int?
    let durationSeconds: Int
    let phase: String
}

// MARK: - API Client (minimal)

enum CodeforcesAPI {
    static func fetchContests() async throws -> [CFContest] {
        let url = URL(string: "https://codeforces.com/api/contest.list")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(CFContestResponse.self, from: data)

        guard decoded.status == "OK" else {
            throw NSError(domain: "CodeforcesAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Codeforces API returned status=\(decoded.status)"
            ])
        }

        return decoded.result
    }
}

// MARK: - User DTO

struct CFUserResponse: Codable {
    let status: String
    let comment: String?
    let result: [CFUser]
}

struct CFUser: Codable {
    let handle: String
    let email: String?
    let vkId: String?
    let openId: String?

    let firstName: String?
    let lastName: String?
    let country: String?
    let city: String?
    let organization: String?

    let contribution: Int?
    let rank: String?
    let rating: Int?
    let maxRank: String?
    let maxRating: Int?

    let lastOnlineTimeSeconds: Int?
    let registrationTimeSeconds: Int?

    let friendOfCount: Int?

    let avatar: String?
    let titlePhoto: String?
}

// MARK: - User API

extension CodeforcesAPI {
    static func fetchUser(handle: String) async throws -> CFUser {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "CodeforcesAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Handle is empty"])
        }

        // 注意：handles 用分号分隔，这里只查一个
        let url = URL(string: "https://codeforces.com/api/user.info?handles=\(trimmed)")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(CFUserResponse.self, from: data)

        guard decoded.status == "OK", let user = decoded.result.first else {
            throw NSError(
                domain: "CodeforcesAPI",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: decoded.comment ?? "User not found"]
            )
        }
        return user
    }
}

// MARK: - Rating DTO

struct CFRatingResponse: Codable {
    let status: String
    let comment: String?
    let result: [CFRatingChange]
}

struct CFRatingChange: Codable, Identifiable {
    let contestId: Int
    let contestName: String
    let handle: String
    let rank: Int
    let ratingUpdateTimeSeconds: Int
    let oldRating: Int
    let newRating: Int

    var id: Int { contestId } // 用 contestId 当唯一 id
}

extension CodeforcesAPI {
    static func fetchRatingHistory(handle: String) async throws -> [CFRatingChange] {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "CodeforcesAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "Handle is empty"])
        }

        let url = URL(string: "https://codeforces.com/api/user.rating?handle=\(trimmed)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(CFRatingResponse.self, from: data)

        guard decoded.status == "OK" else {
            throw NSError(domain: "CodeforcesAPI", code: -11, userInfo: [
                NSLocalizedDescriptionKey: decoded.comment ?? "Failed to load rating history"
            ])
        }
        return decoded.result
    }
}
