//
//  ContentView.swift
//  test
//
//  Created by junlish on 10/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var currentUser: UserProfile?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if !supabaseService.isAuthenticated {
                AuthenticationView(isAuthenticated: $supabaseService.isAuthenticated, currentUser: $currentUser)
            } else {
                ForeverPawsMainView()
            }
        }
        .onAppear {
            checkAutoLoginOnAppear()
            // 设置DataSyncService的ModelContext
            DataSyncService.shared.setModelContext(modelContext)
            print("✅ DataSyncService ModelContext initialized")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataNeedsRefresh"))) { _ in
            // 当用户数据需要刷新时，重新检查认证状态
            Task {
                await supabaseService.checkAutoLogin()
            }
        }
    }
    
    // MARK: - 应用启动时检查自动登录
    private func checkAutoLoginOnAppear() {
        Task {
            await supabaseService.checkAutoLogin()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VideoGeneration.self, inMemory: true)
}