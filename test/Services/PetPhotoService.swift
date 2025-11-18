import Foundation
import Combine

class PetPhotoService: ObservableObject {
    private let supabase = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Pet Photo Management
    
    func fetchPetPhotos(for petId: UUID) async -> [PetPhoto] {
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
            
            let response = try JSONDecoder().decode([PetPhoto].self, from: data)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return response
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return []
        }
    }
    
    func getPrimaryPhoto(for petId: UUID) async -> PetPhoto? {
        do {
            let data = try await supabase.client
                .from("pet_photos")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .eq("is_primary", value: true)
                .execute(accessToken: supabase.currentAccessToken)
            
            let response = try JSONDecoder().decode([PetPhoto].self, from: data)
            
            return response.first
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return nil
        }
    }
    
    func uploadPetPhoto(_ imageData: Data, for petId: UUID, fileName: String, cropData: CropData? = nil, isPrimary: Bool = false) async -> PetPhoto? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Upload image to backend API
            guard let uploadedURL = await uploadImageToBackend(imageData, petId: petId, fileName: fileName) else {
                await MainActor.run {
                    self.errorMessage = "Failed to upload image to server"
                    self.isLoading = false
                }
                return nil
            }
            
            print("✅ Pet photo uploaded successfully: \(uploadedURL)")
            
            // If this is set as primary, unset other primary photos
            if isPrimary {
                _ = try await supabase.client
                    .from("pet_photos")
                    .update(["is_primary": false])
                    .eq("pet_id", value: petId.uuidString)
                    .execute(accessToken: supabase.currentAccessToken)
            }
            
            // Create pet photo record
            let newPhoto = PetPhoto(
                petId: petId,
                photoUrl: uploadedURL,
                cropData: cropData,
                isPrimary: isPrimary
            )
            
            var photoData: [String: Any] = [
                "pet_id": newPhoto.petId.uuidString,
                "photo_url": newPhoto.photoUrl,
                "is_primary": newPhoto.isPrimary,
                "uploaded_at": ISO8601DateFormatter().string(from: newPhoto.uploadedAt)
            ]
            
            // Add crop data if available
            if let cropData = cropData {
                if let cropDataJson = try? JSONEncoder().encode(cropData) {
                    photoData["crop_data"] = String(data: cropDataJson, encoding: .utf8)
                }
            }
            
            let data = try await supabase.client
                .from("pet_photos")
                .insert(photoData)
                .execute(accessToken: supabase.currentAccessToken)
            
            let response = try JSONDecoder().decode([PetPhoto].self, from: data)
            
            // If this is a primary photo, update the Pet model's photoURL
            if isPrimary, let uploadedPhoto = response.first {
                await updatePetPhotoURL(petId: petId, photoURL: uploadedPhoto.photoUrl)
            }
            
            // Always notify UI to refresh after photo upload
            NotificationCenter.default.post(
                name: NSNotification.Name("PetPhotoUpdated"),
                object: nil,
                userInfo: ["petId": petId]
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return response.first
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return nil
        }
    }
    
    // Update Pet model's photoURL when a primary photo is set
    private func updatePetPhotoURL(petId: UUID, photoURL: String) async {
        // This will be handled by the calling view's model context
        // We'll notify through a notification
        NotificationCenter.default.post(
            name: NSNotification.Name("PetPhotoUpdated"),
            object: nil,
            userInfo: ["petId": petId, "photoURL": photoURL]
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadImageToBackend(_ imageData: Data, petId: UUID, fileName: String) async -> String? {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/upload/photo") else {
            print("❌ Invalid upload URL")
            return nil
        }
        
        print("📤 Uploading pet photo to: \(url.absoluteString)")
        
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
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                return nil
            }
            
            print("📡 Upload response status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Upload response body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Upload failed with status: \(httpResponse.statusCode)")
                return nil
            }
            
            // Parse response to get the uploaded URL
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["data"] as? [String: Any],
               let uploadedURL = responseData["url"] as? String {
                print("✅ Parsed upload URL: \(uploadedURL)")
                print("🔍 Full response data: \(responseData)")
                return uploadedURL
            } else {
                print("❌ Failed to parse upload response")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(responseString)")
                }
            }
            
        } catch {
            print("❌ Upload error: \(error)")
        }
        
        return nil
    }
    
    func setPrimaryPhoto(_ photoId: UUID, for petId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Unset all primary photos for this pet
            _ = try await supabase.client
                .from("pet_photos")
                .update(["is_primary": false])
                .eq("pet_id", value: petId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            // Set the selected photo as primary
            _ = try await supabase.client
                .from("pet_photos")
                .update(["is_primary": true])
                .eq("id", value: photoId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    func updateCropData(for photoId: UUID, cropData: CropData) async -> Bool {
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
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    func deletePetPhoto(_ photoId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Delete from database
            _ = try await supabase.client
                .from("pet_photos")
                .delete()
                .eq("id", value: photoId.uuidString)
                .execute(accessToken: supabase.currentAccessToken)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}