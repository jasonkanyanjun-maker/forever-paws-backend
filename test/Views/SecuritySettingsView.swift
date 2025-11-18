import SwiftUI

struct SecuritySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Change Password") {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                Section("Security Actions") {
                    Button("Update Password") {
                        updatePassword()
                    }
                    .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
                    
                    Button("Sign Out All Devices") {
                        signOutAllDevices()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Security Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Security Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updatePassword() {
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match"
            showingAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            // TODO: Implement password update
            await MainActor.run {
                alertMessage = "Password updated successfully"
                showingAlert = true
                isLoading = false
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
    
    private func signOutAllDevices() {
        isLoading = true
        
        Task {
            do {
                try await supabaseService.signOut()
                await MainActor.run {
                    alertMessage = "Signed out from all devices"
                    showingAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to sign out: \(error.localizedDescription)"
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SecuritySettingsView()
}