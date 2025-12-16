//
//  UsersView.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation
import SwiftUI

struct UsersView: View {
    @AppStorage("cfHandle") private var cfHandle: String = ""

    @State private var user: CFUser?
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var ratingChanges: [CFRatingChange] = []


    @State private var showEditHandle = false

    var body: some View {
        NavigationStack {
            Group {
                if cfHandle.isEmpty {
                    // 理论上 RootTabs 会弹窗，这里兜底
                    VStack(spacing: 12) {
                        Text("No handle set")
                            .font(.title3.bold())
                        Text("Please enter your Codeforces handle to continue.")
                            .foregroundStyle(.secondary)
                        Button("Set Handle") { showEditHandle = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(16)

                } else if isLoading {
                    ProgressView()

                } else if let user {
                    
                    List {
                        if !ratingChanges.isEmpty {
                            Section {
                                RatingChartView(changes: ratingChanges)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                        }
                        profileSection(user)
                        ratingSection(user)
                        metaSection(user)
                        linksSection(user)
                    }
                    .listStyle(.insetGrouped)

                } else {
                    VStack(spacing: 12) {
                        Text("Failed to load user")
                            .font(.title3.bold())
                        if let errorText {
                            Text(errorText).foregroundStyle(.secondary)
                        }
                        Button("Retry") { Task { await loadUser() } }
                            .buttonStyle(.borderedProminent)
                        Button("Change Handle") { showEditHandle = true }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("User")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditHandle = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .disabled(cfHandle.isEmpty)
                }
            }
            .task {
                // 页面首次出现加载
                if user == nil, !cfHandle.isEmpty {
                    await loadUser()
                }
            }
            .sheet(isPresented: $showEditHandle) {
                HandleEntryView { newHandle in
                    cfHandle = newHandle
                    user = nil
                    Task { await loadUser() }
                }
            }
        }
    }

    @MainActor
    private func loadUser() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await CodeforcesAPI.fetchUser(handle: cfHandle)
            ratingChanges = try await CodeforcesAPI.fetchRatingHistory(handle: cfHandle)
        } catch {
            user = nil
            ratingChanges = []
            errorText = error.localizedDescription
        }
    }

    // MARK: - Sections

    private func profileSection(_ u: CFUser) -> some View {
        Section("Profile") {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: u.avatar ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(.secondary.opacity(0.2))
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(u.handle)
                        .font(.headline)

                    Text(displayName(u))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let org = u.organization, !org.isEmpty {
                row("Organization", org)
            }

            let loc = locationText(u)
            if !loc.isEmpty {
                row("Location", loc)
            }
        }
    }

    private func ratingSection(_ u: CFUser) -> some View {
        Section("Rating") {
            row("Rank", u.rank ?? "—")
            row("Rating", u.rating.map(String.init) ?? "—")
            row("Max Rank", u.maxRank ?? "—")
            row("Max Rating", u.maxRating.map(String.init) ?? "—")
            row("Contribution", u.contribution.map(String.init) ?? "—")
            row("Friends", u.friendOfCount.map(String.init) ?? "—")
        }
    }

    private func metaSection(_ u: CFUser) -> some View {
        Section("Meta") {
            row("Registered", u.registrationTimeSeconds.map(formatEpoch) ?? "—")
            row("Last Online", u.lastOnlineTimeSeconds.map(formatEpoch) ?? "—")
        }
    }

    private func linksSection(_ u: CFUser) -> some View {
        Section("Links") {
            Link("Open Codeforces Profile", destination: URL(string: "https://codeforces.com/profile/\(u.handle)")!)
        }
    }

    // MARK: - Helpers

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func displayName(_ u: CFUser) -> String {
        let full = [u.firstName, u.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return full.isEmpty ? "—" : full
    }

    private func locationText(_ u: CFUser) -> String {
        let parts = [u.city, u.country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    private func formatEpoch(_ seconds: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
#Preview {
    UsersView()
}
