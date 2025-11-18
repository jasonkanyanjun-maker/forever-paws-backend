//
//  EditPetView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct EditPetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var supabaseService = SupabaseService.shared
    
    let pet: Pet
    
    @State private var name: String = ""
    @State private var selectedType: PetType = .dog
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var petDescription: String = ""
    @State private var birthDate: Date = Date()
    @State private var isMemorialized: Bool = false
    @State private var memorialDate: Date = Date()
    
    @State private var showingImagePicker = false
    @State private var showingPhotoCrop = false
    @State private var selectedImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var photoURL: URL?
    
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color.orange.opacity(0.05),
                        Color.pink.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 照片选择区域
                        photoSelectionSection
                        
                        // 基本信息
                        basicInfoSection
                        
                        // 详细信息
                        detailsSection
                        
                        // 纪念信息
                        memorialSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Pet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePet()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            loadPetData()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        showingPhotoCrop = true
                    }
                }
        }
        .sheet(isPresented: $showingPhotoCrop) {
            if let image = selectedImage {
                PhotoCropView(
                    image: image
                ) { croppedImg, cropData in
                    showingPhotoCrop = false
                    selectedImage = nil
                    croppedImage = croppedImg
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Updating Pet...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private var photoSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Pet Photo")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { showingImagePicker = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    
                    if let croppedImage = croppedImage {
                        Image(uiImage: croppedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else if let photoURL = pet.photoURL {
                        CachedAsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Tap to add photo")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            Text("Basic Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // 姓名
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter pet's name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 类型
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Picker("Pet Type", selection: $selectedType) {
                        ForEach(PetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 品种
                VStack(alignment: .leading, spacing: 8) {
                    Text("Breed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter breed (optional)", text: $breed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            Text("Details")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // 年龄
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("e.g., 3 years old", text: $age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 生日
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                // 描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Tell us about your pet...", text: $petDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    private var memorialSection: some View {
        VStack(spacing: 16) {
            Text("Memorial Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                Toggle("This is a memorial pet", isOn: $isMemorialized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isMemorialized {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Memorial Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        DatePicker("Memorial Date", selection: $memorialDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    private func loadPetData() {
        name = pet.name
        selectedType = pet.type
        breed = pet.breed ?? ""
        age = pet.age ?? ""
        petDescription = pet.petDescription ?? ""
        birthDate = pet.birthDate ?? Date()
        isMemorialized = pet.isMemorialized
        memorialDate = pet.memorialDate ?? Date()
        photoURL = pet.photoURL
    }
    
    private func savePet() {
        guard !name.isEmpty else {
            alertMessage = "Please enter a name for your pet."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // 更新宠物信息
                pet.name = name
                pet.type = selectedType
                pet.breed = breed.isEmpty ? nil : breed
                pet.age = age.isEmpty ? nil : age
                pet.petDescription = petDescription.isEmpty ? nil : petDescription
                pet.birthDate = birthDate
                pet.memorialDate = isMemorialized ? memorialDate : nil
                
                // 保存到本地数据库
                try modelContext.save()
                
                // 同步到服务器
                await syncPetToServer(pet: pet)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to update pet: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func syncPetToServer(pet: Pet) async {
        guard let _ = supabaseService.currentUser,
              let token = KeychainService.shared.loadAccessToken() ?? supabaseService.currentAccessToken else {
            print("❌ [EditPetView] No authenticated user or token for pet sync")
            return
        }
        
        do {
            let url = URL(string: "\(APIConfig.shared.baseURL)/api/pets/\(pet.id.uuidString)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 准备宠物数据，只包含后端允许的字段
            var petData: [String: Any] = [
                "name": pet.name,
                "type": pet.type.rawValue
            ]
            
            // 只有非空值才添加到请求中
            if let breed = pet.breed, !breed.isEmpty {
                petData["breed"] = breed
            }
            
            if let description = pet.petDescription, !description.isEmpty {
                petData["description"] = description
            }
            
            if let age = pet.age, !age.isEmpty {
                // 尝试转换为数字，如果失败则发送字符串
                if let ageNumber = Int(age) {
                    petData["age"] = ageNumber
                } else {
                    petData["age"] = age
                }
            }
            
            // 添加日期字段（如果存在）
            if let birthDate = pet.birthDate {
                petData["birth_date"] = ISO8601DateFormatter().string(from: birthDate)
            }
            
            if let memorialDate = pet.memorialDate {
                petData["memorial_date"] = ISO8601DateFormatter().string(from: memorialDate)
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: petData)
            
            print("🔄 [EditPetView] Syncing pet update to server: \(pet.name)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("✅ [EditPetView] Pet update synced to server successfully")
                } else {
                    print("❌ [EditPetView] Failed to sync pet update to server - Status: \(httpResponse.statusCode)")
                    if let responseData = String(data: data, encoding: .utf8) {
                        print("❌ [EditPetView] Error response: \(responseData)")
                    }
                }
            }
            
        } catch {
            print("❌ [EditPetView] Error syncing pet update to server: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    let samplePet = Pet(
        name: "Buddy",
        type: .dog,
        breed: "Golden Retriever",
        age: "3 years old",
        petDescription: "A friendly and energetic dog"
    )
    
    return EditPetView(pet: samplePet)
        .modelContainer(container)
}