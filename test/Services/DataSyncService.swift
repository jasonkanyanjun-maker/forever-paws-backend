//
//  DataSyncService.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class DataSyncService: ObservableObject {
    static let shared = DataSyncService()
    private let supabaseService = SupabaseService.shared
    var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - 同步用户的所有数据
    func syncUserData() async {
        guard let currentUser = supabaseService.currentUser,
              let context = modelContext else {
            print("❌ [DataSyncService] No authenticated user or model context")
            return
        }
        
        print("🔄 [DataSyncService] Starting data sync for user: \(currentUser.email ?? "unknown")")
        
        // 同步宠物数据
        await syncPets(for: currentUser.id.uuidString, context: context)
        
        // 同步视频数据
        await syncVideos(for: currentUser.id.uuidString, context: context)
        
        // 同步信件数据
        await syncLetters(for: currentUser.id.uuidString, context: context)
        
        print("✅ [DataSyncService] Data sync completed")
        
        // 发送数据同步完成通知
        NotificationCenter.default.post(name: NSNotification.Name("DataSyncCompleted"), object: nil)
    }
    
    // MARK: - 同步宠物数据
    private func syncPets(for userId: String, context: ModelContext) async {
        do {
            // 获取本地宠物数据
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate<Pet> { pet in
                    pet.userId == userId
                }
            )
            let localPets = try context.fetch(descriptor)
            
            // 从服务器获取宠物数据
            let serverPets = await fetchPetsFromServer(userId: userId)
            
            // 合并数据
            await mergePetData(localPets: localPets, serverPets: serverPets, context: context)
            
            print("✅ [DataSyncService] Pet data synced: \(localPets.count) local, \(serverPets.count) server")
            
        } catch {
            print("❌ [DataSyncService] Failed to sync pets: \(error)")
        }
    }
    
    // MARK: - 同步视频数据
    private func syncVideos(for userId: String, context: ModelContext) async {
        do {
            // 获取本地视频数据
            let descriptor = FetchDescriptor<VideoGeneration>(
                predicate: #Predicate<VideoGeneration> { video in
                    video.userId == userId
                }
            )
            let localVideos = try context.fetch(descriptor)
            
            // 从服务器获取视频数据
            let serverVideos = await fetchVideosFromServer(userId: userId)
            
            // 合并数据
            await mergeVideoData(localVideos: localVideos, serverVideos: serverVideos, context: context)
            
            print("✅ [DataSyncService] Video data synced: \(localVideos.count) local, \(serverVideos.count) server")
            
        } catch {
            print("❌ [DataSyncService] Failed to sync videos: \(error)")
        }
    }
    
    // MARK: - 同步信件数据
    private func syncLetters(for userId: String, context: ModelContext) async {
        do {
            // 获取本地信件数据
            let descriptor = FetchDescriptor<Letter>(
                predicate: #Predicate<Letter> { letter in
                    letter.userId == userId
                }
            )
            let localLetters = try context.fetch(descriptor)
            
            // 从服务器获取信件数据
            let serverLetters = await fetchLettersFromServer(userId: userId)
            
            // 合并数据
            await mergeLetterData(localLetters: localLetters, serverLetters: serverLetters, context: context)
            
            print("✅ [DataSyncService] Letter data synced: \(localLetters.count) local, \(serverLetters.count) server")
            
        } catch {
            print("❌ [DataSyncService] Failed to sync letters: \(error)")
        }
    }
    
    // MARK: - 从服务器获取宠物数据
    private func fetchPetsFromServer(userId: String) async -> [ServerPet] {
        // 优先从Keychain获取token，确保获取最新的token
        guard let token = KeychainService.shared.loadAccessToken() ?? supabaseService.currentAccessToken else {
            print("❌ [DataSyncService] No access token for pets fetch")
            return []
        }
        
        do {
            let url = URL(string: "\(APIConfig.shared.baseURL)/api/pets")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("🔧 [DataSyncService] Fetching pets from: \(url)")
            print("🔧 [DataSyncService] Using token: \(token.prefix(20))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [DataSyncService] Invalid response type for pets fetch")
                return []
            }
            
            print("🔧 [DataSyncService] Pets fetch response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let serverResponse = try JSONDecoder().decode(ServerPetsResponse.self, from: data)
                print("✅ [DataSyncService] Successfully fetched \(serverResponse.data.count) pets from server")
                return serverResponse.data
            } else {
                print("❌ [DataSyncService] Failed to fetch pets from server - Status: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("❌ [DataSyncService] Error response: \(responseData)")
                }
                return []
            }
            
        } catch {
            print("❌ [DataSyncService] Error fetching pets from server: \(error)")
            return []
        }
    }
    
    // MARK: - 从服务器获取视频数据
    private func fetchVideosFromServer(userId: String) async -> [ServerVideo] {
        // 优先从Keychain获取token，确保获取最新的token
        guard let token = KeychainService.shared.loadAccessToken() ?? supabaseService.currentAccessToken else {
            print("❌ [DataSyncService] No access token for videos fetch")
            return []
        }
        
        do {
            let url = URL(string: "\(APIConfig.shared.baseURL)/api/videos")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("🔧 [DataSyncService] Fetching videos from: \(url)")
            print("🔧 [DataSyncService] Using token: \(token.prefix(20))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [DataSyncService] Invalid response type for videos fetch")
                return []
            }
            
            print("🔧 [DataSyncService] Videos fetch response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let serverResponse = try JSONDecoder().decode(ServerVideosResponse.self, from: data)
                print("✅ [DataSyncService] Successfully fetched \(serverResponse.data.count) videos from server")
                return serverResponse.data
            } else {
                print("❌ [DataSyncService] Failed to fetch videos from server - Status: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("❌ [DataSyncService] Error response: \(responseData)")
                }
                return []
            }
            
        } catch {
            print("❌ [DataSyncService] Error fetching videos from server: \(error)")
            // 提供更详细的错误信息
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    print("❌ [DataSyncService] Network not available")
                case .timedOut:
                    print("❌ [DataSyncService] Request timed out")
                case .cannotConnectToHost:
                    print("❌ [DataSyncService] Cannot connect to server")
                case .networkConnectionLost:
                    print("❌ [DataSyncService] Network connection lost")
                default:
                    print("❌ [DataSyncService] Network error: \(urlError.localizedDescription)")
                }
            }
            return []
        }
    }
    
    // MARK: - 从服务器获取信件数据
    private func fetchLettersFromServer(userId: String) async -> [ServerLetter] {
        // 优先从Keychain获取token，确保获取最新的token
        guard let token = KeychainService.shared.loadAccessToken() ?? supabaseService.currentAccessToken else {
            print("❌ [DataSyncService] No access token for letters fetch")
            return []
        }
        
        do {
            let url = URL(string: "\(APIConfig.shared.baseURL)/api/letters")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("🔧 [DataSyncService] Fetching letters from: \(url)")
            print("🔧 [DataSyncService] Using token: \(token.prefix(20))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [DataSyncService] Invalid response type for letters fetch")
                return []
            }
            
            print("🔧 [DataSyncService] Letters fetch response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let serverResponse = try JSONDecoder().decode(ServerLettersResponse.self, from: data)
                print("✅ [DataSyncService] Successfully fetched \(serverResponse.data.count) letters from server")
                return serverResponse.data
            } else {
                print("❌ [DataSyncService] Failed to fetch letters from server - Status: \(httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("❌ [DataSyncService] Error response: \(responseData)")
                }
                return []
            }
            
        } catch {
            print("❌ [DataSyncService] Error fetching letters from server: \(error)")
            // 提供更详细的错误信息
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    print("❌ [DataSyncService] Network not available")
                case .timedOut:
                    print("❌ [DataSyncService] Request timed out")
                case .cannotConnectToHost:
                    print("❌ [DataSyncService] Cannot connect to server")
                case .networkConnectionLost:
                    print("❌ [DataSyncService] Network connection lost")
                default:
                    print("❌ [DataSyncService] Network error: \(urlError.localizedDescription)")
                }
            }
            return []
        }
    }
    
    // MARK: - 合并宠物数据
    private func mergePetData(localPets: [Pet], serverPets: [ServerPet], context: ModelContext) async {
        await MainActor.run {
            // 创建服务器宠物ID集合
            let serverPetIds = Set(serverPets.map { $0.id })
            
            // 删除本地存在但服务器不存在的宠物
            for localPet in localPets {
                if !serverPetIds.contains(localPet.id.uuidString) {
                    context.delete(localPet)
                }
            }
            
            // 创建本地宠物ID集合（如需调试可启用）
            // let localPetIds = Set(localPets.map { $0.id.uuidString })
            
            // 添加或更新服务器的宠物数据
            for serverPet in serverPets {
                if let existingPet = localPets.first(where: { $0.id.uuidString == serverPet.id }) {
                    // 更新现有宠物
                    existingPet.name = serverPet.name
                    existingPet.type = PetType(rawValue: serverPet.type) ?? .other
                    existingPet.breed = serverPet.breed
                    existingPet.age = serverPet.age
                    existingPet.petDescription = serverPet.description
                    if let photoUrl = serverPet.photos?.first {
                        existingPet.photoURL = URL(string: photoUrl)
                    }
                    
                    // 处理日期字段
                    if let birthDateString = serverPet.date_of_birth {
                        existingPet.birthDate = ISO8601DateFormatter().date(from: birthDateString)
                    }
                    
                    if let memorialDateString = serverPet.date_of_passing {
                        existingPet.memorialDate = ISO8601DateFormatter().date(from: memorialDateString)
                    }
                } else {
                    // 创建新宠物
                    let newPet = Pet(
                        name: serverPet.name,
                        type: PetType(rawValue: serverPet.type) ?? .other,
                        breed: serverPet.breed,
                        age: serverPet.age,
                        petDescription: serverPet.description,
                        photoURL: serverPet.photos?.first.flatMap { URL(string: $0) }
                    )
                    newPet.id = UUID(uuidString: serverPet.id) ?? UUID()
                    newPet.userId = serverPet.user_id
                    
                    // 处理日期字段
                    if let birthDateString = serverPet.date_of_birth {
                        newPet.birthDate = ISO8601DateFormatter().date(from: birthDateString)
                    }
                    
                    if let memorialDateString = serverPet.date_of_passing {
                        newPet.memorialDate = ISO8601DateFormatter().date(from: memorialDateString)
                    }
                    
                    context.insert(newPet)
                }
            }
            
            // 保存更改
            do {
                try context.save()
            } catch {
                print("❌ [DataSyncService] Failed to save pet data: \(error)")
            }
        }
    }
    
    // MARK: - 合并视频数据
    private func mergeVideoData(localVideos: [VideoGeneration], serverVideos: [ServerVideo], context: ModelContext) async {
        await MainActor.run {
            // 创建服务器视频ID集合
            let serverVideoIds = Set(serverVideos.map { $0.id })
            
            // 删除本地存在但服务器不存在的视频
            for localVideo in localVideos {
                if !serverVideoIds.contains(localVideo.id.uuidString) {
                    context.delete(localVideo)
                }
            }
            
            // 创建本地视频ID集合（如需调试可启用）
            // let localVideoIds = Set(localVideos.map { $0.id.uuidString })
            
            // 添加或更新服务器的视频数据
            for serverVideo in serverVideos {
                if let existingVideo = localVideos.first(where: { $0.id.uuidString == serverVideo.id }) {
                    // 更新现有视频
                    existingVideo.status = GenerationStatus(rawValue: serverVideo.status) ?? .pending
                    if let videoUrl = serverVideo.video_url {
                        existingVideo.generatedVideoURL = URL(string: videoUrl)
                    }
                } else {
                    // 创建新视频
                    let newVideo = VideoGeneration(
                        originalImageURL: nil,
                        petId: UUID(uuidString: serverVideo.pet_id ?? "") ?? UUID(),
                        title: nil,
                        userId: serverVideo.user_id
                    )
                    newVideo.status = GenerationStatus(rawValue: serverVideo.status) ?? .pending
                    newVideo.generatedVideoURL = serverVideo.video_url.flatMap { URL(string: $0) }
                    newVideo.id = UUID(uuidString: serverVideo.id) ?? UUID()
                    context.insert(newVideo)
                }
            }
            
            // 保存更改
            do {
                try context.save()
            } catch {
                print("❌ [DataSyncService] Failed to save video data: \(error)")
            }
        }
    }
    
    // MARK: - 合并信件数据
    private func mergeLetterData(localLetters: [Letter], serverLetters: [ServerLetter], context: ModelContext) async {
        await MainActor.run {
            // 创建服务器信件ID集合
            let serverLetterIds = Set(serverLetters.map { $0.id })
            
            // 删除本地存在但服务器不存在的信件
            for localLetter in localLetters {
                if !serverLetterIds.contains(localLetter.id.uuidString) {
                    context.delete(localLetter)
                }
            }
            
            // 创建本地信件ID集合
            let _ = Set(localLetters.map { $0.id.uuidString })
            
            // 添加或更新服务器的信件数据
            for serverLetter in serverLetters {
                if let existingLetter = localLetters.first(where: { $0.id.uuidString == serverLetter.id }) {
                    // 更新现有信件
                    existingLetter.content = serverLetter.content
                } else {
                    // 创建新信件
                    let newLetter = Letter(
                        petId: UUID(uuidString: serverLetter.pet_id ?? "") ?? UUID(),
                        content: serverLetter.content
                    )
                    newLetter.id = UUID(uuidString: serverLetter.id) ?? UUID()
                    newLetter.userId = serverLetter.user_id
                    context.insert(newLetter)
                }
            }
            
            // 保存更改
            do {
                try context.save()
            } catch {
                print("❌ [DataSyncService] Failed to save letter data: \(error)")
            }
        }
    }
}

// MARK: - 服务器数据模型
struct ServerPetsResponse: Codable {
    let data: [ServerPet]
}

struct ServerPet: Codable {
    let id: String
    let user_id: String
    let name: String
    let type: String
    let breed: String?
    let description: String?
    let photos: [String]?
    let age: String?
    let date_of_birth: String?
    let date_of_passing: String?
    let is_memorial: Bool?
    let created_at: String
    let updated_at: String?
}

struct ServerVideosResponse: Codable {
    let data: [ServerVideo]
}

struct ServerVideo: Codable {
    let id: String
    let user_id: String
    let pet_id: String?
    let video_url: String?
    let status: String
    let created_at: String
    let updated_at: String?
}

struct ServerLettersResponse: Codable {
    let data: [ServerLetter]
}

struct ServerLetter: Codable {
    let id: String
    let user_id: String
    let pet_id: String?
    let content: String
    let created_at: String
    let updated_at: String?
}