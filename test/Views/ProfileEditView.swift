import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var petPhotoService = PetPhotoService()
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var name: String = ""
    @State private var hobbies: String = ""
    @State private var preferences: UserPreferences = UserPreferences()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    
    // Preference categories
    private let preferenceCategories = [
        "Communication Style": ["Formal", "Casual", "Playful", "Caring"],
        "Pet Care Focus": ["Health", "Training", "Play", "Nutrition"],
        "Response Tone": ["Encouraging", "Informative", "Emotional", "Practical"]
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    profilePhotoSection
                } header: {
                    Text("Profile Photo")
                }
                
                Section {
                    TextField("Your Name", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("Basic Information")
                }
                
                Section {
                    TextField("Enter your hobbies (comma separated)", text: $hobbies, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Hobbies & Interests")
                } footer: {
                    Text("Tell us about your interests to help personalize your pet's responses")
                }
                
                Section {
                    preferencesSection
                } header: {
                    Text("AI Response Preferences")
                } footer: {
                    Text("These preferences help customize how your pet communicates with you")
                }
                
                Section {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("Notification Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingPrivacySettings = true }) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.green)
                            Text("Privacy Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Additional Settings")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(userProfileService.isLoading || isUploading)
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadSelectedPhoto(newValue)
                }
            }
            .alert("Profile Update", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadUserProfile()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
        }
    }
    
    private var profilePhotoSection: some View {
        HStack {
            Button(action: { showingImagePicker = true }) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 76, height: 76)
                            .clipShape(Circle())
                    } else if let avatarUrl = userProfileService.currentProfile?.avatarUrl,
                              let url = URL(string: avatarUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    
                    if isUploading {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile Photo")
                    .font(.headline)
                
                Text("Tap to change your profile picture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var preferencesSection: some View {
        ForEach(Array(preferenceCategories.keys.sorted()), id: \.self) { category in
            VStack(alignment: .leading, spacing: 8) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let options = preferenceCategories[category] ?? []
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            // For now, just show the option as selected
                            // TODO: Implement proper preference handling
                        }) {
                            Text(option)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.2))
                                )
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func loadUserProfile() async {
        guard let currentUser = SupabaseService.shared.currentUser else { return }
        await userProfileService.fetchUserProfile(for: currentUser.id)
        
        if let profile = userProfileService.currentProfile {
            await MainActor.run {
                name = profile.name ?? ""
                hobbies = profile.hobbies.joined(separator: ", ")
                // Convert [String: String] to UserPreferences if needed
                // For now, use default preferences
                preferences = UserPreferences()
            }
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    avatarImage = image
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to load selected image"
                showingAlert = true
            }
        }
    }
    
    private func saveProfile() async {
        isUploading = true
        
        // Upload avatar if selected
        if let avatarImage = avatarImage,
           let currentUser = SupabaseService.shared.currentUser {
            let imageData = avatarImage.jpegData(compressionQuality: 0.8)!
            _ = await userProfileService.updateAvatar(userId: currentUser.id, imageData: imageData)
        }
        
        // Parse hobbies
        let hobbiesArray = hobbies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Update profile
        guard let currentUser = SupabaseService.shared.currentUser else { return }
        let success = await userProfileService.updateUserProfile(
            userId: currentUser.id,
            name: name.isEmpty ? nil : name,
            hobbies: hobbiesArray,
            preferences: preferences
        )
        
        await MainActor.run {
            isUploading = false
            if success {
                alertMessage = "Profile updated successfully!"
                dismiss()
            } else {
                alertMessage = "Failed to update profile. Please try again."
                showingAlert = true
            }
        }
    }
}

#Preview {
    ProfileEditView()
}