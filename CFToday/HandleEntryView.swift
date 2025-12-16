//
//  HandleEntryView.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation
import SwiftUI

struct HandleEntryView: View {
    @Environment(\.dismiss) private var dismiss

    // 外部传入：保存 handle 的回调
    let onSaved: (String) -> Void

    @State private var handle: String = ""
    @State private var isChecking = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your Codeforces handle")
                        .font(.title3.bold())

                    Text("We’ll verify it exists on Codeforces. You can change it later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("e.g. tourist", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                if let errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await verifyAndSave() }
                } label: {
                    if isChecking {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isChecking || handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @MainActor
    private func verifyAndSave() async {
        errorText = nil
        isChecking = true
        defer { isChecking = false }

        do {
            // 验证存在即可
            _ = try await CodeforcesAPI.fetchUser(handle: handle)
            let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
            onSaved(trimmed)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
