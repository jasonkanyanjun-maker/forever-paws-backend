//
//  DashboardView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @Query private var recentVideos: [VideoGeneration]
    @Query private var recentLetters: [Letter]
    @Query private var products: [Product]
    
    @State private var showingProfile = false
    @StateObject private var petPhotoService = PetPhotoService()
    @State private var primaryPetPhoto: PetPhoto?
    @ObservedObject private var cartService = CartService.shared
    
    // Photo upload states
    @State private var showingImagePicker = false
    @State private var showingPhotoCrop = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var showingAddPet = false
    
    // Hot products states
    @State private var showingCart = false
    @State private var showingAddToCartAlert = false
    @State private var addToCartMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "E879F9").opacity(0.05),
                        Color(hex: "F472B6").opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 英雄区域
                        heroSection
                        
                        // 功能网格
                        featuresGrid
                        
                        // 我的宠物快速访问
                        myPetsSection
                        
                        // 最近活动
                        recentActivitySection
                        
                        // 热卖商品展示区域
                        hotProductsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCart = true }) {
                        ZStack {
                            Image(systemName: "cart.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if cartService.getTotalItemCount() > 0 {
                                Text("\(cartService.getTotalItemCount())")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            PersonalCenterView()
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
                ) { croppedImage, cropData in
                    showingPhotoCrop = false
                    selectedImage = nil
                    
                    // Handle the cropped image and save it for the first pet
                    if let firstPet = pets.first {
                        Task {
                            // Convert UIImage to Data
                            guard let imageData = croppedImage.jpegData(compressionQuality: 0.8) else {
                                return
                            }
                            
                            // Upload photo using PetPhotoService
                            let uploadedPhoto = await petPhotoService.uploadPetPhoto(
                                imageData,
                                for: firstPet.id,
                                fileName: "pet_photo_\(Date().timeIntervalSince1970).jpg",
                                cropData: cropData,
                                isPrimary: true
                            )
                            
                            if let uploadedPhoto = uploadedPhoto {
                                // Update the pet's photoURL in the local model
                                firstPet.photoURL = URL(string: uploadedPhoto.photoUrl)
                                try? modelContext.save()
                                
                                // Update the primary photo state immediately
                                await MainActor.run {
                                    primaryPetPhoto = uploadedPhoto
                                }
                                
                                // Also reload to ensure consistency
                                await loadPrimaryPetPhoto()
                            }
                        }
                    }
                }
            }
        }

        .task {
            await loadPrimaryPetPhoto()
        }
        .onChange(of: pets) { _, _ in
            Task {
                await loadPrimaryPetPhoto()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PetPhotoUpdated"))) { notification in
            // When a pet photo is updated, refresh the primary photo
            Task {
                await loadPrimaryPetPhoto()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataNeedsRefresh"))) { _ in
            Task {
                await loadPrimaryPetPhoto()
            }
        }
        .sheet(isPresented: $showingAddPet) {
            AddPetView()
        }
        .sheet(isPresented: $showingCart) {
            CartView(cartService: cartService)
        }
        .alert("Shopping Cart", isPresented: $showingAddToCartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addToCartMessage)
        }
        .onAppear {
            print("🔄 DashboardView onAppear - Setting up CartService")
            cartService.setModelContext(modelContext)
            print("✅ CartService ModelContext set in DashboardView")
            loadSampleProducts()
        }
    }
    
    private func loadSampleProducts() {
        // 如果没有产品数据，创建一些示例产品
        if products.isEmpty {
            let sampleProducts = [
                Product(
                    name: "定制宠物相框",
                    description: "精美的定制相框，永远珍藏您与爱宠的美好回忆",
                    price: 89.99,
                    category: .frames,
                    imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=elegant%20custom%20pet%20photo%20frame%20wooden%20memorial&image_size=square"),
                    customizationOptions: try? JSONEncoder().encode(["尺寸": "标准", "材质": "实木"])
                ),
                Product(
                    name: "宠物纪念项链",
                    description: "刻有宠物名字的精美项链，让爱永远陪伴在身边",
                    price: 129.99,
                    category: .jewelry,
                    imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=elegant%20pet%20memorial%20necklace%20silver%20pendant%20heart%20shaped&image_size=square"),
                    customizationOptions: try? JSONEncoder().encode(["材质": "925银", "刻字": "可定制"])
                ),
                Product(
                    name: "宠物纪念石",
                    description: "天然石材制作的纪念石，可刻字定制，适合花园摆放",
                    price: 199.99,
                    category: .stones,
                    imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=natural%20stone%20pet%20memorial%20garden%20marker%20engraved&image_size=square"),
                    customizationOptions: try? JSONEncoder().encode(["石材": "花岗岩", "刻字": "可定制"])
                ),
                Product(
                    name: "定制宠物抱枕",
                    description: "印有宠物照片的舒适抱枕，让温暖的回忆触手可及",
                    price: 69.99,
                    category: .textiles,
                    imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=custom%20pet%20photo%20pillow%20soft%20fabric%20memorial%20cushion&image_size=square"),
                    customizationOptions: try? JSONEncoder().encode(["尺寸": "40x40cm", "材质": "棉质"])
                ),
                Product(
                    name: "宠物纪念蜡烛",
                    description: "香薰纪念蜡烛，点燃时想起与爱宠的美好时光",
                    price: 39.99,
                    category: .candles,
                    imageURL: URL(string: "https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=memorial%20pet%20candle%20elegant%20glass%20jar%20warm%20light&image_size=square"),
                    customizationOptions: try? JSONEncoder().encode(["香味": "薰衣草", "燃烧时间": "50小时"])
                )
            ]
            
            for product in sampleProducts {
                modelContext.insert(product)
            }
            
            try? modelContext.save()
        }
    }
    
    private func loadPrimaryPetPhoto() async {
        guard let firstPet = pets.first else {
            await MainActor.run {
                primaryPetPhoto = nil
            }
            return
        }
        
        let photo = await petPhotoService.getPrimaryPhoto(for: firstPet.id)
        await MainActor.run {
            primaryPetPhoto = photo
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // 主要宠物照片或占位符
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "E879F9").opacity(0.1), Color(hex: "F472B6").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                if let primaryPhoto = primaryPetPhoto {
                    CachedAsyncImage(url: URL(string: primaryPhoto.photoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(20)
                    } placeholder: {
                        ProgressView("Loading...")
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                    }
                    .onAppear {
                        print("📤 Loading primary photo from URL: \(primaryPhoto.photoUrl)")
                    }
                } else if let firstPet = pets.first, let photoURL = firstPet.photoURL {
                    CachedAsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Add your pet's photo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .onTapGesture {
                if pets.isEmpty {
                    showingAddPet = true
                } else {
                    showingImagePicker = true
                }
            }
            .contentShape(Rectangle()) // 确保整个区域都可以点击
            
            // 欢迎文本
            VStack(spacing: 8) {
                Text("Welcome to Forever Paws")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create lasting memories of your beloved companions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                FeatureCard(
                    icon: "envelope.fill",
                    title: "Write Letter",
                    color: Color.orange,
                    destination: AnyView(LetterWritingView())
                )
                
                FeatureCard(
                    icon: "checkmark.square.fill",
                    title: "Memorial Shop",
                    color: Color.pink,
                    destination: AnyView(MemorialProductsView())
                )
                
                FeatureCard(
                    icon: "archivebox.fill",
                    title: "Memory Storage",
                    color: Color.purple,
                    destination: AnyView(MemoryStorageView())
                )
                
                FeatureCard(
                    icon: "square.and.arrow.up.fill",
                    title: "Share Space",
                    color: Color.cyan,
                    destination: AnyView(SharingCenterView())
                )
                
                FeatureCard(
                    icon: "wand.and.stars.inverse",
                    title: "Holographic",
                    color: Color.blue,
                    destination: AnyView(HolographicProjectionView())
                )
                
                FeatureCard(
                    icon: "person.fill",
                    title: "My Profile",
                    color: Color.purple,
                    destination: AnyView(PersonalCenterView())
                )
            }
        }
    }
    
    private var myPetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Pets")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: MyPetsView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
            if pets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "pawprint")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Forever Paws!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Start by adding your beloved pet to create lasting memories together")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    NavigationLink(destination: AddPetView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            
                            Text("Add Your First Pet")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "E879F9").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    VStack(spacing: 12) {
                        Text("What you can do:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "E879F9"))
                                
                                Text("Upload Photos")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "F472B6"))
                                
                                Text("Write Letters")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text("Create Videos")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "E879F9").opacity(0.05),
                                    Color(hex: "F472B6").opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "E879F9").opacity(0.2),
                                            Color(hex: "F472B6").opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pets.prefix(5)) { pet in
                            PetCard(pet: pet)
                        }
                        
                        // Add More 按钮
                        NavigationLink(destination: AddPetView()) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "E879F9").opacity(0.1), Color(hex: "F472B6").opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    style: StrokeStyle(lineWidth: 2, dash: [5])
                                                )
                                        )
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                Text("Add More")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineLimit(1)
                            }
                            .frame(width: 80)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var hotProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Custom Keepsake")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: MemorialProductsView()) {
                    Text("View More")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
            if products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bag")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No products available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(products.prefix(5)) { product in
                            HotProductCard(
                                product: product,
                                cartService: cartService
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to activity view
                }
                .font(.subheadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            VStack(spacing: 12) {
                if recentLetters.isEmpty && recentVideos.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        
                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(recentLetters.prefix(3)) { letter in
                        ActivityCard(
                            icon: "envelope.fill",
                            title: "Letter from your pet",
                            subtitle: letter.previewText,
                            time: letter.formattedDate,
                            color: Color.orange
                        )
                    }
                    
                    ForEach(recentVideos.prefix(2)) { video in
                        ActivityCard(
                            icon: "wand.and.stars.inverse",
                            title: "Holographic video created",
                            subtitle: video.title ?? "Untitled video",
                            time: DateFormatter.shortDateTime.string(from: video.createdAt),
                            color: Color.blue
                        )
                    }
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PetCard: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                
                if let photoURL = pet.photoURL {
                    CachedAsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .onAppear {
                        print("📤 Loading dashboard pet photo from URL: \(photoURL)")
                    }

                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
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

struct ActivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

#Preview {
    DashboardView()
        .modelContainer(for: [Pet.self, VideoGeneration.self, Letter.self], inMemory: true)
}