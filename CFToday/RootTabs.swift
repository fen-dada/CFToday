//
//  RootTabs.swift
//  CFToday
//
//  Created by Fendada on 2025/12/16.
//

import Foundation
import SwiftUI

struct RootTabs: View {
    @AppStorage("cfHandle") private var cfHandle: String = ""
    @State private var showHandleSheet = false

    var body: some View {
        TabView {
            ContestsView()
                .tabItem { Label("Contests", systemImage: "trophy") }

            UsersView()
                .tabItem { Label("User", systemImage: "person") }
        }
        .onAppear {
            // 第一次进入 App：如果没设置 handle，就弹窗
            if cfHandle.isEmpty {
                showHandleSheet = true
            }
        }
        .sheet(isPresented: $showHandleSheet) {
            HandleEntryView { newHandle in
                cfHandle = newHandle
                showHandleSheet = false
            }
            .interactiveDismissDisabled(true) // 强制用户先设置（你想允许跳过就删掉）
        }
    }
}

