//
//  ChangePasswordView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }
    
    private var passwordStrength: PasswordStrength {
        getPasswordStrength(newPassword)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Change Password")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your current password and choose a new secure password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Password Fields
                    VStack(spacing: 16) {
                        // Current Password
                        PasswordField(
                            title: "Current Password",
                            text: $currentPassword,
                            showPassword: $showCurrentPassword,
                            placeholder: "Enter current password"
                        )
                        
                        // New Password
                        PasswordField(
                            title: "New Password",
                            text: $newPassword,
                            showPassword: $showNewPassword,
                            placeholder: "Enter new password"
                        )
                        
                        // Password Strength Indicator
                        if !newPassword.isEmpty {
                            PasswordStrengthView(strength: passwordStrength)
                        }
                        
                        // Confirm Password
                        PasswordField(
                            title: "Confirm New Password",
                            text: $confirmPassword,
                            showPassword: $showConfirmPassword,
                            placeholder: "Confirm new password"
                        )
                        
                        // Password Match Indicator
                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(newPassword == confirmPassword ? .green : .red)
                                
                                Text(newPassword == confirmPassword ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(newPassword == confirmPassword ? .green : .red)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Password Requirements
                    PasswordRequirementsView(password: newPassword)
                    
                    // Change Password Button
                    Button(action: changePassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            
                            Text(isLoading ? "Changing Password..." : "Change Password")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func changePassword() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                // Use Supabase Auth to update password
                try await supabaseService.updatePassword(newPassword: newPassword)
                
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Your password has been changed successfully."
                    showingAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to change password: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct PasswordField: View {
    let title: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(strength.text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strength.color)
                
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < strength.level ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
        }
    }
}

struct PasswordRequirementsView: View {
    let password: String
    
    private var requirements: [(String, Bool)] {
        [
            ("At least 8 characters", password.count >= 8),
            ("Contains uppercase letter", password.contains(where: { $0.isUppercase })),
            ("Contains lowercase letter", password.contains(where: { $0.isLowercase })),
            ("Contains number", password.contains(where: { $0.isNumber })),
            ("Contains special character", password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(requirements, id: \.0) { requirement, isMet in
                    HStack(spacing: 8) {
                        Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(isMet ? .green : .gray)
                        
                        Text(requirement)
                            .font(.caption)
                            .foregroundColor(isMet ? .primary : .secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

enum PasswordStrength {
    case weak
    case fair
    case good
    case strong
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return .green
        }
    }
}

private func getPasswordStrength(_ password: String) -> PasswordStrength {
    var score = 0
    
    if password.count >= 8 { score += 1 }
    if password.contains(where: { $0.isUppercase }) { score += 1 }
    if password.contains(where: { $0.isLowercase }) { score += 1 }
    if password.contains(where: { $0.isNumber }) { score += 1 }
    let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if password.contains(where: { ch in specialCharacters.contains(ch) }) { score += 1 }
    
    switch score {
    case 0...1: return .weak
    case 2...3: return .fair
    case 4: return .good
    case 5: return .strong
    default: return .weak
    }
}

#Preview {
    ChangePasswordView()
}