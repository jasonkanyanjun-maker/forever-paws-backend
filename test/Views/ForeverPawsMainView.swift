//
//  ForeverPawsMainView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct ForeverPawsMainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingAuth = false
    @State private var isAuthenticated = false
    @State private var currentUser: UserProfile?
    
    var body: some View {
        Group {
            if isAuthenticated {
                TabView(selection: $selectedTab) {
                    // Main Dashboard
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    // Letter Writing
                    LetterWritingView()
                        .tabItem {
                            Image(systemName: "envelope.fill")
                            Text("Letters")
                        }
                        .tag(1)
                    
                    // Holographic Projection (formerly Video Generation)
                    HolographicProjectionView()
                        .tabItem {
                            Image(systemName: "video.fill")
                            Text("3D Videos")
                        }
                        .tag(2)
                    
                    // Memory Storage
                    MemoryStorageView()
                        .tabItem {
                            Image(systemName: "archivebox.fill")
                            Text("Memories")
                        }
                        .tag(3)
                    
                    // Memorial Products
                    MemorialProductsView()
                        .tabItem {
                            Image(systemName: "gift.fill")
                            Text("Memorial")
                        }
                        .tag(4)
                    
                    // Personal Center
                    PersonalCenterView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(5)
                    
                    // Settings
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(6)
                }
                .tint(
                    LinearGradient(
                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            } else {
                AuthenticationView(isAuthenticated: $isAuthenticated, currentUser: $currentUser)
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        // 检查 Supabase 认证状态
        isAuthenticated = SupabaseService.shared.isAuthenticated
        
        // 如果已认证，触发数据同步
        if isAuthenticated {
            Task {
                await DataSyncService.shared.syncUserData()
            }
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ForeverPawsMainView()
        .modelContainer(for: [VideoGeneration.self, Pet.self, Letter.self, Subscription.self, Product.self, Order.self], inMemory: true)
}