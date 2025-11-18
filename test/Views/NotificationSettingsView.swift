import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userProfileService = UserProfileService()
    
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true
    @State private var supportNotificationsEnabled = true

    @State private var petUpdatesEnabled = true
    @State private var videoReadyEnabled = true
    @State private var promotionalEnabled = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NotificationToggleRow(
                        icon: "bell.fill",
                        title: "Push Notifications",
                        subtitle: "Receive push notifications on your device",
                        color: .blue,
                        isOn: $pushNotificationsEnabled
                    )
                    
                    NotificationToggleRow(
                        icon: "envelope.fill",
                        title: "Email Notifications",
                        subtitle: "Receive notifications via email",
                        color: .green,
                        isOn: $emailNotificationsEnabled
                    )
                } header: {
                    Text("General Notifications")
                } footer: {
                    Text("Control how you receive notifications from Forever Paws")
                }
                
                Section {
                    NotificationToggleRow(
                        icon: "pawprint.fill",
                        title: "Pet Updates",
                        subtitle: "Notifications about your pets",
                        color: .orange,
                        isOn: $petUpdatesEnabled
                    )
                    
                    NotificationToggleRow(
                        icon: "video.fill",
                        title: "Video Ready",
                        subtitle: "When your AI videos are ready",
                        color: .purple,
                        isOn: $videoReadyEnabled
                    )
                    

                    
                    NotificationToggleRow(
                        icon: "questionmark.circle.fill",
                        title: "Support Updates",
                        subtitle: "Support ticket responses and updates",
                        color: .indigo,
                        isOn: $supportNotificationsEnabled
                    )
                } header: {
                    Text("Content Notifications")
                }
                
                Section {
                    NotificationToggleRow(
                        icon: "tag.fill",
                        title: "Promotional Offers",
                        subtitle: "Special offers and promotions",
                        color: .pink,
                        isOn: $promotionalEnabled
                    )
                } header: {
                    Text("Marketing")
                } footer: {
                    Text("Receive information about new features and special offers")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveNotificationSettings()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Notification Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadNotificationSettings()
            }
        }
    }
    
    private func loadNotificationSettings() async {
        await userProfileService.getOrCreateUserProfile()
        
        if userProfileService.currentProfile != nil {
            await MainActor.run {
                // Parse notification preferences from profile.preferences
                // For now, use default values since we need to implement proper parsing
                let notifications = NotificationPreferences()
                pushNotificationsEnabled = notifications.pushEnabled
                emailNotificationsEnabled = notifications.emailEnabled
                supportNotificationsEnabled = notifications.supportEnabled

                petUpdatesEnabled = notifications.petUpdatesEnabled
                videoReadyEnabled = notifications.videoReadyEnabled
                promotionalEnabled = notifications.promotionalEnabled
            }
        }
    }
    
    private func saveNotificationSettings() async {
        isLoading = true
        
        let notificationPrefs = NotificationPreferences(
            pushEnabled: pushNotificationsEnabled,
            emailEnabled: emailNotificationsEnabled,
            supportEnabled: supportNotificationsEnabled,
            petUpdatesEnabled: petUpdatesEnabled,
            videoReadyEnabled: videoReadyEnabled,
            promotionalEnabled: promotionalEnabled
        )
        
        let success = await userProfileService.updateNotificationPreferences(notificationPrefs)
        
        await MainActor.run {
            isLoading = false
            if success {
                alertMessage = "Notification settings saved successfully!"
                dismiss()
            } else {
                alertMessage = "Failed to save notification settings. Please try again."
                showingAlert = true
            }
        }
    }
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
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
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationSettingsView()
}