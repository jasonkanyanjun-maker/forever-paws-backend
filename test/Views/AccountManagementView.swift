//
//  AccountManagementView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var userProfileService = UserProfileService()
    
    @State private var showingDeleteAccountAlert = false
    @State private var showingChangeEmailSheet = false
    @State private var showingChangePasswordSheet = false
    @State private var showingExportDataSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Information Section
                    AccountSection(title: "Account Information") {
                        AccountInfoRow(
                            icon: "envelope.fill",
                            title: "Email Address",
                            value: supabaseService.currentUser?.email ?? "Not available",
                            color: .blue
                        ) {
                            showingChangeEmailSheet = true
                        }
                        
                        AccountInfoRow(
                            icon: "person.fill",
                            title: "Display Name",
                            value: userProfileService.currentProfile?.name ?? supabaseService.currentUser?.displayName ?? "Not set",
                            color: .green
                        ) {
                            // Navigate to profile edit
                        }
                        
                        AccountInfoRow(
                            icon: "calendar.fill",
                            title: "Member Since",
                            value: formatDate(supabaseService.currentUser?.createdAt),
                            color: .orange,
                            showChevron: false
                        ) {
                            // No action
                        }
                    }
                    
                    // Security Section
                    AccountSection(title: "Security") {
                        AccountInfoRow(
                            icon: "key.fill",
                            title: "Change Password",
                            value: "Update your password",
                            color: .purple
                        ) {
                            showingChangePasswordSheet = true
                        }
                        
                        AccountInfoRow(
                            icon: "shield.checkered",
                            title: "Two-Factor Authentication",
                            value: "Not enabled",
                            color: .red
                        ) {
                            // TODO: Implement 2FA
                        }
                    }
                    
                    // Data Management Section
                    AccountSection(title: "Data Management") {
                        AccountInfoRow(
                            icon: "square.and.arrow.up.fill",
                            title: "Export Data",
                            value: "Download your data",
                            color: .cyan
                        ) {
                            showingExportDataSheet = true
                        }
                        
                        AccountInfoRow(
                            icon: "trash.fill",
                            title: "Delete Account",
                            value: "Permanently delete your account",
                            color: .red
                        ) {
                            showingDeleteAccountAlert = true
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Account Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingChangeEmailSheet) {
            ChangeEmailView()
        }
        .sheet(isPresented: $showingChangePasswordSheet) {
            AccountChangePasswordView()
        }
        .sheet(isPresented: $showingExportDataSheet) {
            AccountExportDataView()
        }
        .onAppear {
            Task {
                await userProfileService.getOrCreateUserProfile()
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct AccountSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                content
            }
        }
    }
}

struct AccountInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var showChevron: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!showChevron)
    }
}

// Placeholder views for sheets
struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Change Email feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AccountChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Change Password feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AccountExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export Data feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AccountManagementView()
}