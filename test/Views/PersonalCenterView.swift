//
//  PersonalCenterView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import Combine

struct PersonalCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @Query private var orders: [Order]
    
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var petPhotoService = PetPhotoService()
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var showingProfileEdit = false
    @State private var showingMyPets = false
    @State private var showingPaymentHistory = false
    @State private var showingSettings = false
    @State private var showingSupport = false
    @State private var showingPrivacyPolicy = false
    @State private var showingLogoutAlert = false
    @State private var showingPhotoManagement = false
    
    // Avatar photo upload states
    @State private var showingImagePicker = false
    @State private var showingPhotoCrop = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingAvatar = false
    
    // 用户数据状态
    @State private var userEmail: String = ""
    @State private var userDisplayName: String = "Pet Lover"
    @State private var userAvatarURL: URL? = nil
    @State private var subscriptionStatus: ViewSubscriptionStatus = .free
    @State private var joinDate: Date = Date()
    
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
                        // 用户信息卡片
                        userInfoCard
                        
                        // 我的宠物快速访问
                        myPetsSection
                        
                        // 功能菜单
                        functionsMenu
                        
                        // 设置和支持
                        settingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Personal Center")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
        .sheet(isPresented: $showingMyPets) {
            if let firstPet = pets.first {
                PetPhotoManagementView(pet: firstPet)
            } else {
                Text("No pets available")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingPaymentHistory) {
            PaymentHistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            EnhancedSettingsView()
        }
        .sheet(isPresented: $showingSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingPhotoManagement) {
            if let firstPet = pets.first {
                PetPhotoManagementView(pet: firstPet)
            } else {
                Text("No pets available")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onAppear {
                    print("🔧 [PersonalCenterView] ImagePicker appeared")
                    // Reset selectedImage to ensure clean state
                    selectedImage = nil
                }
                .onDisappear {
                    print("🔧 [PersonalCenterView] ImagePicker disappeared, selectedImage: \(selectedImage != nil)")
                    // Add a small delay to ensure image is properly set before showing crop view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if selectedImage != nil {
                            showingPhotoCrop = true
                        }
                    }
                }
        }
        .sheet(isPresented: $showingPhotoCrop) {
            if let image = selectedImage {
                PhotoCropView(
                    image: image
                ) { croppedImage, cropData in
                    showingPhotoCrop = false
                    selectedImage = nil
                    
                    Task {
                        isUploadingAvatar = true
                        print("📤 Starting avatar upload process...")
                        
                        // Convert CropData to AvatarCropData
                        let avatarCropData = AvatarCropData(
                            x: cropData.x,
                            y: cropData.y,
                            width: cropData.width,
                            height: cropData.height,
                            scale: cropData.scale
                        )
                        
                        // Convert UIImage to Data
                        guard let imageData = croppedImage.jpegData(compressionQuality: 0.8) else {
                            print("❌ Failed to convert image to JPEG data")
                            isUploadingAvatar = false
                            return
                        }
                        
                        print("📤 Image data size: \(imageData.count) bytes")
                        
                        let success = await userProfileService.updateAvatar(imageData: imageData, cropData: avatarCropData)
                        isUploadingAvatar = false
                        
                        if success {
                            print("✅ Avatar upload completed successfully")
                            
                            // Force refresh the user profile to show new avatar
                            await userProfileService.getOrCreateUserProfile()
                            
                            // Clear image cache for old avatar URL to force reload
                            if let oldAvatarUrl = userProfileService.currentProfile?.avatarUrl,
                               let oldUrl = URL(string: oldAvatarUrl) {
                                print("🗑️ Clearing old avatar cache: \(oldAvatarUrl)")
                                ImageCacheManager.shared.clearImageCache(for: oldUrl)
                            }
                            
                            // Force UI refresh
                            await MainActor.run {
                                print("🔄 Triggering UI refresh after avatar upload")
                                userProfileService.objectWillChange.send()
                            }
                        } else {
                            print("❌ Avatar upload failed")
                        }
                    }
                }
            }
        }

        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                print("🔧 [PersonalCenterView] Logout button tapped in alert")
                Task {
                    do {
                        print("🔧 [PersonalCenterView] Calling supabaseService.signOut()")
                        try await supabaseService.signOut()
                        print("✅ [PersonalCenterView] Sign out successful")
                        
                        // 确保在主线程上强制刷新视图状态
                        await MainActor.run {
                            // 强制刷新视图状态
                            userProfileService.objectWillChange.send()
                        }
                    } catch {
                        print("❌ [PersonalCenterView] Logout error: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            Task {
                await loadUserData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataNeedsRefresh"))) { _ in
            Task {
                await loadUserData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserAvatarUpdated"))) { notification in
            Task {
                // Clear cache for the new avatar URL to force fresh load
                if let avatarUrl = notification.userInfo?["avatarUrl"] as? String,
                   !avatarUrl.isEmpty,
                   let url = URL(string: avatarUrl) {
                    ImageCacheManager.shared.clearImageCache(for: url)
                }
                
                await loadUserData()
                await MainActor.run {
                    userProfileService.objectWillChange.send()
                }
            }
        }
    }
    
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像和基本信息
            HStack(spacing: 16) {
                Button(action: { showingImagePicker = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        if let userProfile = userProfileService.currentProfile,
                           let avatarUrl = userProfile.avatarUrl,
                           !avatarUrl.isEmpty,
                           let url = URL(string: avatarUrl) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 76, height: 76)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 76, height: 76)
                            }
                            .onAppear {
                                print("📤 Loading avatar from URL: \(avatarUrl)")
                            }
                            .onDisappear {
                                print("📤 Avatar view disappeared")
                            }
                            .id("\(avatarUrl)_\(Date().timeIntervalSince1970)") // Force refresh with timestamp
                        } else {
                            let displayName = userProfileService.currentProfile?.name ?? userDisplayName
                            Text(String(displayName.prefix(1)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .onAppear {
                                    print("📤 Showing default avatar for: \(displayName)")
                                }
                        }
                        
                        // 编辑指示器
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 24, height: 24)
                            )
                            .offset(x: 28, y: 28)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(userProfileService.currentProfile?.name ?? userDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(userEmail.isEmpty ? supabaseService.currentUser?.email ?? "user@example.com" : userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: subscriptionStatus.icon)
                            .font(.caption)
                            .foregroundColor(subscriptionStatus.color)
                        
                        Text(subscriptionStatus.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(subscriptionStatus.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(subscriptionStatus.color.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            
            // 统计信息
            HStack(spacing: 0) {
                StatItem(
                    title: "Pets",
                    value: "\(pets.count)",
                    icon: "pawprint.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Orders",
                    value: "\(orders.count)",
                    icon: "bag.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Days",
                    value: "\(daysSinceJoined)",
                    icon: "calendar"
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var myPetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Pets")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingMyPets = true }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
            if pets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pawprint")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No pets added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingMyPets = true }) {
                        Text("Add Your First Pet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pets.prefix(5)) { pet in
                            PersonalCenterPetCard(pet: pet)
                        }
                        
                        if pets.count > 5 {
                            Button(action: { showingMyPets = true }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                    
                                    Text("More")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, height: 100)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var functionsMenu: some View {
        VStack(spacing: 16) {
            Text("Functions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                MenuRow(
                    icon: "bag.fill",
                    title: "Payment History",
                    subtitle: "View your purchase records",
                    color: .green
                ) {
                    showingPaymentHistory = true
                }
                
                MenuRow(
                    icon: "photo.fill",
                    title: "Photo Management",
                    subtitle: "Manage your pet photos",
                    color: .cyan
                ) {
                    showingPhotoManagement = true
                }
                

                
                MenuRow(
                    icon: "heart.fill",
                    title: "Favorites",
                    subtitle: "Your liked products and videos",
                    color: .red
                ) {
                    // TODO: Show favorites
                }
                
                MenuRow(
                    icon: "square.and.arrow.up",
                    title: "Share App",
                    subtitle: "Invite friends to Forever Paws",
                    color: .blue
                ) {
                    // TODO: Share app
                }
                
                MenuRow(
                    icon: "star.fill",
                    title: "Rate Us",
                    subtitle: "Leave a review on App Store",
                    color: .orange
                ) {
                    // TODO: Rate app
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            Text("Settings & Support")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                MenuRow(
                    icon: "gearshape.fill",
                    title: "Settings",
                    subtitle: "App preferences and privacy",
                    color: .gray
                ) {
                    showingSettings = true
                }
                
                MenuRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact us",
                    color: .purple
                ) {
                    showingSupport = true
                }
                
                MenuRow(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy",
                    color: .indigo
                ) {
                    showingPrivacyPolicy = true
                }
                
                MenuRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    color: .red
                ) {
                    showingLogoutAlert = true
                }
            }
        }
    }
    
    private var daysSinceJoined: Int {
        Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
    }
    
    private func loadUserData() async {
        // Load user profile from Supabase
        await userProfileService.getOrCreateUserProfile()
        
        // Update local state with user data
        if let profile = userProfileService.currentProfile {
            await MainActor.run {
                userDisplayName = profile.name ?? "Pet Lover"
                userEmail = supabaseService.currentUser?.email ?? ""
                
                // Set subscription status based on profile data
                if let subscriptionType = profile.preferences["subscription"] {
                    subscriptionStatus = ViewSubscriptionStatus(rawValue: subscriptionType) ?? .free
                }
                
                // Set join date from profile creation
                joinDate = profile.createdAt
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PersonalCenterPetCard: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                if let photoURL = pet.photoURL {
                    CachedAsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onAppear {
                        print("📤 Loading pet photo from URL: \(photoURL)")
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                        
                        Text("Replace with\nyour pet's photo")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            
            Text(pet.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

struct PetManagementCard: View {
    let pet: Pet
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 宠物头像
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                    
                    if let photoURL = pet.photoURL {
                        CachedAsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onAppear {
                            print("📤 Loading pet management photo from URL: \(photoURL)")
                        }
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 宠物信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(pet.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 宠物类型标签
                        Text(pet.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    
                    if let breed = pet.breed, !breed.isEmpty {
                        Text(breed)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let age = pet.age, !age.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(age)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if pet.isMemorialized {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                            Text("In Memory")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }
                    }
                }
                
                Spacer()
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
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
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 用户资料数据模型 (View-specific)
struct ViewUserProfile {
    let id: String
    let email: String
    var displayName: String
    var avatarURL: URL?
    var subscriptionStatus: ViewSubscriptionStatus
    let joinDate: Date
}

enum ViewSubscriptionStatus: String, CaseIterable {
    case free = "free"
    case premium = "premium"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .lifetime: return "Lifetime"
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "person"
        case .premium: return "crown.fill"
        case .lifetime: return "infinity"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .premium: return .orange
        case .lifetime: return .purple
        }
    }
}



struct MyPetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var showingAddPet = false
    @State private var selectedPet: Pet?
    @State private var showingEditPet = false
    @State private var showingDeleteAlert = false
    @State private var petToDelete: Pet?
    
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
                
                if pets.isEmpty {
                    // 空状态
                    VStack(spacing: 24) {
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("No Pets Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Add your first pet to get started with Forever Paws")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: { showingAddPet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("Add Your First Pet")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    // 宠物列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(pets) { pet in
                                PetManagementCard(
                                    pet: pet,
                                    onEdit: {
                                        selectedPet = pet
                                        showingEditPet = true
                                    },
                                    onDelete: {
                                        petToDelete = pet
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("My Pets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPet) {
            AddPetView()
        }
        .sheet(isPresented: $showingEditPet) {
            if let pet = selectedPet {
                EditPetView(pet: pet)
            }
        }
        .alert("Delete Pet", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let pet = petToDelete {
                    deletePet(pet)
                }
            }
        } message: {
            if let pet = petToDelete {
                Text("Are you sure you want to delete \(pet.name)? This action cannot be undone.")
            }
        }
    }
    
    private func deletePet(_ pet: Pet) {
        modelContext.delete(pet)
        try? modelContext.save()
        petToDelete = nil
    }
}

struct PaymentHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Payment history feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Payment History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct EnhancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    

    @State private var showingAccountManagement = false
    @State private var showingPrivacyPolicy = false
    @State private var showingNotificationSettings = false
    @State private var showingSecuritySettings = false
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    
    // Notification settings
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true
    @State private var supportNotificationsEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Section
                    SettingsSection(title: "Account") {
                        SettingsRow(
                            icon: "person.circle.fill",
                            title: "Account Management",
                            subtitle: "Manage your account settings",
                            color: .blue
                        ) {
                            showingAccountManagement = true
                        }
                        

                        
                        SettingsRow(
                            icon: "shield.fill",
                            title: "Security & Privacy",
                            subtitle: "Password and security settings",
                            color: .orange
                        ) {
                            showingSecuritySettings = true
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        SettingsToggleRow(
                            icon: "bell.fill",
                            title: "Push Notifications",
                            subtitle: "Receive push notifications",
                            color: .purple,
                            isOn: $pushNotificationsEnabled
                        )
                        
                        SettingsToggleRow(
                            icon: "envelope.fill",
                            title: "Email Notifications",
                            subtitle: "Receive email updates",
                            color: .blue,
                            isOn: $emailNotificationsEnabled
                        )
                        
                        SettingsToggleRow(
                            icon: "questionmark.circle.fill",
                            title: "Support Updates",
                            subtitle: "Get notified about support tickets",
                            color: .indigo,
                            isOn: $supportNotificationsEnabled
                        )
                        

                    }
                    
                    // Data & Privacy Section
                    SettingsSection(title: "Data & Privacy") {
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Privacy Policy",
                            subtitle: "Read our privacy policy",
                            color: .indigo
                        ) {
                            showingPrivacyPolicy = true
                        }
                        
                        SettingsRow(
                            icon: "externaldrive.fill",
                            title: "Data Management",
                            subtitle: "Export or delete your data",
                            color: .gray
                        ) {
                            showingDataManagement = true
                        }
                    }
                    
                    // Support Section
                    SettingsSection(title: "Support") {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About Forever Paws",
                            subtitle: "App version and information",
                            color: .cyan
                        ) {
                            showingAbout = true
                        }
                        
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "Get help and contact us",
                            color: .purple
                        ) {
                            // This will be handled by parent view
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }

        .sheet(isPresented: $showingAccountManagement) {
            AccountManagementView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingSecuritySettings) {
            SecuritySettingsView()
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct SettingsSection<Content: View>: View {
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

struct PersonalSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
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
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Support feature coming soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PersonalCenterView()
        .modelContainer(for: [Pet.self, Order.self], inMemory: true)
}