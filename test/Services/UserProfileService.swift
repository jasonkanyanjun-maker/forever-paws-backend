import Foundation
import SwiftUI
import Combine

// MARK: - User Profile Models
// Note: Using UserProfile from Models/UserProfile.swift

struct UserPreferences: Codable {
    let notificationPreferences: NotificationPreferences
    let privacySettings: PrivacySettings
    let theme: String
    
    init() {
        self.notificationPreferences = NotificationPreferences()
        self.privacySettings = PrivacySettings()
        self.theme = "system"
    }
    
    init(notificationPreferences: NotificationPreferences, privacySettings: PrivacySettings, theme: String) {
        self.notificationPreferences = notificationPreferences
        self.privacySettings = privacySettings
        self.theme = theme
    }
}

struct NotificationPreferences: Codable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let supportEnabled: Bool
    let petUpdatesEnabled: Bool
    let videoReadyEnabled: Bool
    let promotionalEnabled: Bool
    
    init() {
        self.pushEnabled = true
        self.emailEnabled = true
        self.supportEnabled = true
        self.petUpdatesEnabled = true
        self.videoReadyEnabled = true
        self.promotionalEnabled = false
    }
    
    init(pushEnabled: Bool, emailEnabled: Bool, supportEnabled: Bool, petUpdatesEnabled: Bool, videoReadyEnabled: Bool, promotionalEnabled: Bool) {
        self.pushEnabled = pushEnabled
        self.emailEnabled = emailEnabled
        self.supportEnabled = supportEnabled
        self.petUpdatesEnabled = petUpdatesEnabled
        self.videoReadyEnabled = videoReadyEnabled
        self.promotionalEnabled = promotionalEnabled
    }
}

struct PrivacySettings: Codable {
    let dataCollectionEnabled: Bool
    let analyticsEnabled: Bool
    let crashReportingEnabled: Bool
    let personalizedAdsEnabled: Bool
    let locationTrackingEnabled: Bool
    let photoAnalysisEnabled: Bool
    
    init() {
        self.dataCollectionEnabled = true
        self.analyticsEnabled = true
        self.crashReportingEnabled = true
        self.personalizedAdsEnabled = false
        self.locationTrackingEnabled = false
        self.photoAnalysisEnabled = true
    }
    
    init(dataCollectionEnabled: Bool, analyticsEnabled: Bool, crashReportingEnabled: Bool, personalizedAdsEnabled: Bool, locationTrackingEnabled: Bool, photoAnalysisEnabled: Bool) {
        self.dataCollectionEnabled = dataCollectionEnabled
        self.analyticsEnabled = analyticsEnabled
        self.crashReportingEnabled = crashReportingEnabled
        self.personalizedAdsEnabled = personalizedAdsEnabled
        self.locationTrackingEnabled = locationTrackingEnabled
        self.photoAnalysisEnabled = photoAnalysisEnabled
    }
}

// MARK: - Avatar Crop Data
struct AvatarCropData: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let scale: Double
    
    init(x: Double, y: Double, width: Double, height: Double, scale: Double = 1.0) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.scale = scale
    }
}

// MARK: - User Profile Service
class UserProfileService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentProfile: UserProfile?
    
    private let supabase = SupabaseService.shared
    private let apiConfig = APIConfig.shared
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(for userId: UUID) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        print("🔄 Fetching user profile for user: \(userId.uuidString)")
        
        do {
            let data = try await supabase.client
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            let profiles = try JSONDecoder().decode([UserProfile].self, from: data)
            
            await MainActor.run {
                self.currentProfile = profiles.first
                self.isLoading = false
            }
            
            if let profile = profiles.first {
                print("✅ User profile fetched successfully")
                print("📋 Profile name: \(profile.name ?? "No name")")
                print("📋 Profile avatar URL: \(profile.avatarUrl ?? "No avatar URL")")
            } else {
                print("⚠️ No user profile found for user: \(userId.uuidString)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ Failed to fetch user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create User Profile
    func createUserProfile(userId: UUID, name: String?, avatarUrl: String? = nil) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let preferences = UserPreferences()
            let preferencesData = try JSONEncoder().encode(preferences)
            
            let profileData: [String: Any] = [
                "user_id": userId.uuidString,
                "name": name ?? "",
                "avatar_url": avatarUrl ?? NSNull(),
                "hobbies": [],
                "preferences": preferencesData.base64EncodedString()
            ]
            
            let _ = try await supabase.client
                .from("user_profiles")
                .insert(profileData)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Fetch the created profile
            await fetchUserProfile(for: userId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(
        userId: UUID,
        name: String? = nil,
        avatarUrl: String? = nil,
        hobbies: [String]? = nil,
        preferences: UserPreferences? = nil
    ) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        print("🔄 Updating user profile for user: \(userId.uuidString)")
        if let avatarUrl = avatarUrl {
            print("🔄 New avatar URL: \(avatarUrl)")
        }
        
        do {
            var updateData: [String: Any] = [:]
            
            if let name = name {
                updateData["name"] = name
                print("🔄 Updating name: \(name)")
            }
            
            if let avatarUrl = avatarUrl {
                updateData["avatar_url"] = avatarUrl
                print("🔄 Updating avatar_url: \(avatarUrl)")
            }
            
            if let hobbies = hobbies {
                updateData["hobbies"] = hobbies
                print("🔄 Updating hobbies: \(hobbies)")
            }
            
            if let preferences = preferences {
                let preferencesData = try JSONEncoder().encode(preferences)
                updateData["preferences"] = preferencesData
                print("🔄 Updating preferences")
            }
            
            updateData["updated_at"] = ISO8601DateFormatter().string(from: Date())
            
            print("🔄 Executing database update...")
            _ = try await supabase.client
                .from("user_profiles")
                .update(updateData)
                .eq("user_id", value: userId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            print("✅ Database update completed successfully")
            
            // Refresh profile after update to show changes immediately
            print("🔄 Refreshing profile after update...")
            await fetchUserProfile(for: userId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ User profile update completed successfully")
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ User profile update failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Update Avatar with Crop Support
    func updateAvatar(userId: UUID, imageData: Data, cropData: AvatarCropData? = nil) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        print("🔄 Starting avatar update process for user: \(userId.uuidString)")
        
        // Upload image to backend API
        guard let uploadedURL = await uploadImageToBackend(imageData, userId: userId, cropData: cropData) else {
            await MainActor.run {
                self.errorMessage = "Failed to upload avatar to server"
                self.isLoading = false
            }
            print("❌ Avatar upload failed")
            return false
        }

        print("✅ Avatar uploaded, URL: \(uploadedURL)")

        // Update profile with new avatar URL
        print("🔄 Updating user profile with new avatar URL...")
        let success = await updateUserProfile(userId: userId, avatarUrl: uploadedURL)

        if success {
            print("✅ User profile updated successfully")

            // Clear old avatar from cache before fetching new profile
            if let oldAvatarUrl = currentProfile?.avatarUrl,
               let oldUrl = URL(string: oldAvatarUrl) {
                print("🗑️ Clearing old avatar cache: \(oldAvatarUrl)")
                ImageCacheManager.shared.clearImageCache(for: oldUrl)
            }

            // Immediately refresh the profile to show the new avatar
            print("🔄 Refreshing user profile...")
            await fetchUserProfile(for: userId)

            // Clear new avatar from cache to force fresh load
            if let newAvatarUrl = currentProfile?.avatarUrl,
               let newUrl = URL(string: newAvatarUrl) {
                print("🗑️ Clearing new avatar cache to force refresh: \(newAvatarUrl)")
                ImageCacheManager.shared.clearImageCache(for: newUrl)
            }

            // Notify UI to refresh avatar display
            print("📢 Sending avatar update notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("UserAvatarUpdated"),
                object: nil,
                userInfo: ["userId": userId, "avatarUrl": currentProfile?.avatarUrl ?? ""]
            )

            // Force UI refresh
            await MainActor.run {
                print("🔄 Triggering UI refresh")
                self.objectWillChange.send()
            }

            print("✅ Avatar update process completed successfully")
        } else {
            print("❌ Failed to update user profile with new avatar URL")
        }

        await MainActor.run {
            self.isLoading = false
        }

        return success
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadImageToBackend(_ imageData: Data, userId: UUID, cropData: AvatarCropData? = nil) async -> String? {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/upload/avatar") else {
            print("❌ Invalid upload URL")
            return nil
        }
        
        print("📤 Uploading avatar to: \(url.absoluteString)")
        print("📤 Image data size: \(imageData.count) bytes")
        print("📤 User ID: \(userId.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header
        if let token = supabase.currentAccessToken {
            print("📤 Using auth token: \(String(token.prefix(20)))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("❌ No auth token available")
            return nil
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add avatar file (note: field name is 'avatar' for the avatar endpoint)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add crop data if available
        if let cropData = cropData {
            if let cropDataJson = try? JSONEncoder().encode(cropData),
               let cropDataString = String(data: cropDataJson, encoding: .utf8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"crop_data\"\r\n\r\n".data(using: .utf8)!)
                body.append(cropDataString.data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📤 Request body size: \(body.count) bytes")
        
        do {
            print("📤 Sending upload request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📤 Upload response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📤 Upload response data: \(responseString)")
                        
                        // Parse JSON response
                        if let jsonData = responseString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let success = json["success"] as? Bool,
                           success,
                           let responseData = json["data"] as? [String: Any],
                           let avatarUrl = responseData["url"] as? String {
                            print("✅ Avatar uploaded successfully: \(avatarUrl)")
                            return avatarUrl
                        } else {
                            print("❌ Failed to parse upload response")
                        }
                    }
                } else {
                    print("❌ Upload failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ Upload request failed: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Update Avatar (convenience method)
    func updateAvatar(imageData: Data, cropData: AvatarCropData? = nil) async -> Bool {
        guard let currentUser = SupabaseService.shared.currentUser else { return false }
        return await updateAvatar(userId: currentUser.id, imageData: imageData, cropData: cropData)
    }
    
    // MARK: - Update Notification Preferences
    func updateNotificationPreferences(userId: UUID, notifications: NotificationPreferences) async -> Bool {
        // For now, create new preferences with default values
        // TODO: Parse existing preferences from profile.preferences [String: String]
        let updatedPreferences = UserPreferences(
            notificationPreferences: notifications,
            privacySettings: PrivacySettings(),
            theme: "light"
        )
        
        return await updateUserProfile(userId: userId, preferences: updatedPreferences)
    }
    
    // MARK: - Update Privacy Preferences
    func updatePrivacySettings(userId: UUID, privacy: PrivacySettings) async -> Bool {
        // For now, create new preferences with default values
        // TODO: Parse existing preferences from profile.preferences [String: String]
        let updatedPreferences = UserPreferences(
            notificationPreferences: NotificationPreferences(),
            privacySettings: privacy,
            theme: "light"
        )
        
        return await updateUserProfile(userId: userId, preferences: updatedPreferences)
    }
    
    // MARK: - Delete User Profile
    func deleteUserProfile(userId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            _ = try await supabase.client
                .from("user_profiles")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            await MainActor.run {
                self.currentProfile = nil
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Get or Create User Profile
    func getOrCreateUserProfile() async {
        guard let currentUser = SupabaseService.shared.currentUser else { return }
        
        await fetchUserProfile(for: currentUser.id)
        
        if currentProfile == nil {
            let success = await createUserProfile(userId: currentUser.id, name: currentUser.email)
            if success {
                await fetchUserProfile(for: currentUser.id)
            }
        }
    }
    
    // MARK: - Update Notification Preferences (convenience method)
    func updateNotificationPreferences(_ notifications: NotificationPreferences) async -> Bool {
        guard let currentUser = SupabaseService.shared.currentUser else { return false }
        return await updateNotificationPreferences(userId: currentUser.id, notifications: notifications)
    }
    
    // MARK: - Update Privacy Settings (convenience method)
    func updatePrivacySettings(_ privacy: PrivacySettings) async -> Bool {
        guard let currentUser = SupabaseService.shared.currentUser else { return false }
        return await updatePrivacySettings(userId: currentUser.id, privacy: privacy)
    }
    
    // MARK: - Delete User Account
    func deleteUserAccount() async -> Bool {
        guard let currentUser = SupabaseService.shared.currentUser else { return false }
        return await deleteUserProfile(userId: currentUser.id)
    }
}