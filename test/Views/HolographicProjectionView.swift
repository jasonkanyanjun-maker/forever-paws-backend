//
//  HolographicProjectionView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct HolographicProjectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @Query private var videos: [VideoGeneration]
    
    @State private var selectedPet: Pet?
    @State private var showingVideoGeneration = false
    @State private var showingAddPet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if pets.isEmpty {
                    // 空状态
                    VStack(spacing: 24) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        VStack(spacing: 12) {
                            Text("No Pets Added")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Add a pet first to create holographic projections")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: { showingAddPet = true }) {
                            Text("Add Your First Pet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 宠物选择器
                            petSelector
                            
                            // 创建全息投影按钮
                            createProjectionButton
                            
                            // 全息投影历史
                            projectionHistory
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Holographic Projection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPet = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
        }
        .sheet(isPresented: $showingVideoGeneration) {
            VideoGenerationView()
        }
        .sheet(isPresented: $showingAddPet) {
            AddPetView()
        }
        .onAppear {
            if selectedPet == nil {
                selectedPet = pets.first
            }
        }
    }
    
    private var petSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Pet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pets) { pet in
                        HolographicPetCard(
                            pet: pet,
                            isSelected: selectedPet?.id == pet.id
                        ) {
                            selectedPet = pet
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var createProjectionButton: some View {
        Button(action: { showingVideoGeneration = true }) {
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text("Create Holographic Projection")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Transform your pet's photo into a magical 3D video")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(selectedPet == nil)
    }
    
    private var projectionHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Projection History")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !filteredVideos.isEmpty {
                    Text("\(filteredVideos.count) projections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if filteredVideos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "video.badge.waveform")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No projections yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first holographic projection of \(selectedPet?.name ?? "your pet")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(filteredVideos) { video in
                        HolographicVideoCard(video: video)
                    }
                }
            }
        }
    }
    
    private var filteredVideos: [VideoGeneration] {
        guard let selectedPet = selectedPet else { return [] }
        return videos.filter { $0.petId == selectedPet.id }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

struct HolographicPetCard: View {
    let pet: Pet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? 
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 2
                                )
                        )
                    
                    if let photoURL = pet.photoURL {
                        CachedAsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .blue : .secondary)
                    }
                    
                    if isSelected {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                            )
                            .offset(x: 20, y: -20)
                    }
                }
                
                Text(pet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 80)
    }
}

struct HolographicVideoCard: View {
    let video: VideoGeneration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let thumbnailURL = video.thumbnailURL {
                    CachedAsyncImage(url: thumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let originalImageURL = video.originalImageURL {
                    CachedAsyncImage(url: originalImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                
                // 播放按钮覆盖层
                if video.status == .completed {
                    Button(action: {
                        // TODO: Play video
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 40, height: 40)
                            )
                    }
                }
                
                // 状态指示器
                VStack {
                    HStack {
                        Spacer()
                        
                        Text(video.status.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(video.status.color).opacity(0.8))
                            )
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title ?? "Holographic Projection")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(DateFormatter.shortDate.string(from: video.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

#Preview {
    HolographicProjectionView()
        .modelContainer(for: [Pet.self, VideoGeneration.self], inMemory: true)
}