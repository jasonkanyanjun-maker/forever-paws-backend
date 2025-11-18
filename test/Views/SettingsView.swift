import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var supabaseService = SupabaseService.shared

    @State private var showingAccountSettings = false
    @State private var showingSecuritySettings = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    @State private var showingHelpSupport = false
    @State private var showingDeveloperSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Profile Section
                Section {
                    if let user = supabaseService.currentUser {
                        HStack(spacing: 12) {
                            CachedAsyncImage(url: URL(string: userProfileService.currentProfile?.avatarUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(user.email?.prefix(1).uppercased() ?? "U")
                                            .font(.title2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userProfileService.currentProfile?.name ?? user.email ?? "User")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingAccountSettings = true
                        }
                    }
                }
                
                // Sharing Section
                Section("Sharing") {
                    SettingsRow(
                        icon: "square.and.arrow.up.fill",
                        title: "Share App",
                        subtitle: "Invite friends to Forever Paws",
                        color: .green
                    ) {
                        shareApp()
                    }
                }
                
                // Account & Security Section
                Section("Account & Security") {
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: "Account Settings",
                        subtitle: "Manage your account information",
                        color: .orange
                    ) {
                        showingAccountSettings = true
                    }
                    
                    SettingsRow(
                        icon: "lock.fill",
                        title: "Security",
                        subtitle: "Password and security settings",
                        color: .red
                    ) {
                        showingSecuritySettings = true
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: "Manage notification preferences",
                        color: .purple
                    ) {
                        showingNotificationSettings = true
                    }
                    
                    SettingsRow(
                        icon: "hand.raised.fill",
                        title: "Privacy",
                        subtitle: "Privacy and data settings",
                        color: .indigo
                    ) {
                        showingPrivacySettings = true
                    }
                    
                    SettingsRow(
                        icon: "externaldrive.fill",
                        title: "Data Management",
                        subtitle: "Export or delete your data",
                        color: .teal
                    ) {
                        showingDataManagement = true
                    }
                }
                
                // Support Section
                Section("Support") {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support",
                        subtitle: "Get help and contact support",
                        color: .cyan
                    ) {
                        showingHelpSupport = true
                    }
                    
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About Forever Paws",
                        subtitle: "App version and information",
                        color: .gray
                    ) {
                        showingAbout = true
                    }
                    
                    #if DEBUG
                    SettingsRow(
                        icon: "wrench.and.screwdriver.fill",
                        title: "开发者设置",
                        subtitle: "API 配置和网络测试",
                        color: .orange
                    ) {
                        showingDeveloperSettings = true
                    }
                    #endif
                }
                
                // Sign Out Section
                Section {
                    Button {
                        signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await userProfileService.getOrCreateUserProfile()
            }
        }

        .sheet(isPresented: $showingAccountSettings) {
            AccountSettingsView()
        }
        .sheet(isPresented: $showingSecuritySettings) {
            SecuritySettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingDeveloperSettings) {
            DeveloperSettingsView()
        }
    }
    
    private func shareApp() {
        let shareText = "Check out Forever Paws - a beautiful app to cherish memories of your beloved pets! 🐾"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func signOut() {
        print("🔧 [SettingsView] Sign out button tapped")
        Task {
            do {
                print("🔧 [SettingsView] Calling supabaseService.signOut()")
                try await supabaseService.signOut()
                print("✅ [SettingsView] Sign out successful")
                
                // 确保在主线程上更新UI状态
                await MainActor.run {
                    // 强制刷新视图状态
                    userProfileService.objectWillChange.send()
                }
            } catch {
                print("❌ [SettingsView] Sign out error: \(error)")
                await MainActor.run {
                    // Show error alert if needed
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}