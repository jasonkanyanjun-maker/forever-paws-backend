import Foundation
import SwiftUI
import Combine

// MARK: - Photo Management Models
// Note: Using PetPhoto and CropData from Models/PetPhoto.swift

// MARK: - Photo Management Service
class PhotoManagementService: ObservableObject {
    private let supabase = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var petPhotos: [PetPhoto] = []
    
    // MARK: - Fetch Pet Photos
    func fetchPetPhotos(for petId: UUID) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let data = try await supabase.client
                .from("pet_photos")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            let photos = try JSONDecoder().decode([PetPhoto].self, from: data)
            
            await MainActor.run {
                self.petPhotos = photos.sorted { $0.uploadedAt > $1.uploadedAt }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load photos: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Upload Photo
    func uploadPhoto(for petId: UUID, imageData: Data, cropData: CropData? = nil) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Upload image to backend API
            guard let uploadedURL = await uploadImageToBackend(imageData, petId: petId) else {
                await MainActor.run {
                    self.errorMessage = "Failed to upload image to server"
                    self.isLoading = false
                }
                return false
            }
            
            var photoData: [String: Any] = [
                "pet_id": petId.uuidString,
                "photo_url": uploadedURL,
                "is_primary": petPhotos.isEmpty, // First photo becomes primary
                "uploaded_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Add crop data if available
            if let cropData = cropData {
                if let cropDataJson = try? JSONEncoder().encode(cropData) {
                    let cropString: String = String(data: cropDataJson, encoding: .utf8) ?? "{}"
                    photoData["crop_data"] = cropString as Any
                }
            }
            
            let _ = try await supabase.client
                .from("pet_photos")
                .insert(photoData)
                .execute()
            
            // Refresh photos after upload to show the new photo immediately
            await fetchPetPhotos(for: petId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadImageToBackend(_ imageData: Data, petId: UUID) async -> String? {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/upload/photo") else {
            print("❌ Invalid upload URL")
            return nil
        }
        
        print("📤 Uploading photo to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header
        if let token = supabase.currentAccessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add photo file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add type field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append("pet".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add pet_id field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"pet_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(petId.uuidString.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Upload failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            
            // Parse response to get the uploaded URL
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["data"] as? [String: Any],
               let uploadedURL = responseData["url"] as? String {
                return uploadedURL
            }
            
        } catch {
            print("Upload error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Delete Photo
    func deletePhoto(_ photoId: UUID, petId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            _ = try await supabase.client
                .from("pet_photos")
                .delete()
                .eq("id", value: photoId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Refresh photos after deletion
            await fetchPetPhotos(for: petId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete photo: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Set Primary Photo
    func setPrimaryPhoto(_ photoId: UUID, petId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // First, set all photos for this pet as non-primary
            _ = try await supabase.client
                .from("pet_photos")
                .update(["is_primary": false])
                .eq("pet_id", value: petId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Then set the selected photo as primary
            _ = try await supabase.client
                .from("pet_photos")
                .update(["is_primary": true])
                .eq("id", value: photoId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Refresh photos after update
            await fetchPetPhotos(for: petId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to set primary photo: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Update Crop Data
    func updateCropData(for photoId: UUID, cropData: CropData, petId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cropDataJson = try JSONEncoder().encode(cropData)
            let cropDataString: String = String(data: cropDataJson, encoding: .utf8) ?? "{}"
            
            _ = try await supabase.client
                .from("pet_photos")
                .update(["crop_data": cropDataString as Any])
                .eq("id", value: photoId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Refresh photos after update
            await fetchPetPhotos(for: petId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update crop data: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
}