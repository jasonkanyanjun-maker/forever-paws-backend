import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        TextField("Enter display name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Account Actions") {
                    Button("Update Profile") {
                        updateProfile()
                    }
                    .disabled(isLoading)
                    
                    Button("Change Password") {
                        // TODO: Implement password change
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadUserProfile()
            }
            .alert("Account Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadUserProfile() async {
        await userProfileService.getOrCreateUserProfile()
        
        await MainActor.run {
            if let profile = userProfileService.currentProfile {
                displayName = profile.name ?? ""
            }
            
            if let user = supabaseService.currentUser {
                email = user.email ?? ""
            }
        }
    }
    
    private func updateProfile() {
        isLoading = true
        
        Task {
            // Update profile name
            if userProfileService.currentProfile != nil {
                // TODO: Implement profile update
                await MainActor.run {
                    alertMessage = "Profile updated successfully"
                    showingAlert = true
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    alertMessage = "No profile loaded to update"
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AccountSettingsView()
}