//
//  VideoHistoryView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct VideoHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var videos: [VideoGeneration]
    @Query private var pets: [Pet]
    
    @State private var searchText = ""
    @State private var selectedFilter = FilterType.all
    @State private var selectedLayoutMode = LayoutMode.grid
    @State private var showingDeleteAlert = false
    @State private var videoToDelete: VideoGeneration?
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case processing = "Processing"
        case failed = "Failed"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .completed: return "checkmark.circle"
            case .processing: return "clock"
            case .failed: return "xmark.circle"
            }
        }
    }
    
    enum LayoutMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var filteredVideos: [VideoGeneration] {
        let filtered = videos.filter { video in
            if selectedFilter != .all {
                switch selectedFilter {
                case .completed:
                    return video.status == .completed
                case .processing:
                    return video.status == .processing
                case .failed:
                    return video.status == .failed
                default:
                    break
                }
            }
            return true
        }
        
        if searchText.isEmpty {
            return filtered.sorted { $0.createdAt > $1.createdAt }
        } else {
            return filtered.filter { video in
                (video.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                pets.first(where: { $0.id == video.petId })?.name.localizedCaseInsensitiveContains(searchText) ?? false
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Forever Paws 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.91, green: 0.47, blue: 0.98).opacity(0.1),
                        Color(red: 0.96, green: 0.45, blue: 0.71).opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    titleSection
                    searchAndFilterSection
                    layoutToggleSection
                    
                    if filteredVideos.isEmpty {
                        emptyStateView
                    } else {
                        if selectedLayoutMode == .grid {
                            videoGridView
                        } else {
                            videoListView
                        }
                    }
                }
            }
        }
        .alert("Delete Video", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let video = videoToDelete {
                    deleteVideo(video)
                }
            }
        } message: {
            Text("Are you sure you want to delete this video? This action cannot be undone.")
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Holographic Videos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(videos.count) videos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Add new video action
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.91, green: 0.47, blue: 0.98),
                                    Color(red: 0.96, green: 0.45, blue: 0.71)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            Text("Manage your pet memorial holographic videos")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search videos or pets...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
            )
            
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Layout Toggle Section
    
    private var layoutToggleSection: some View {
        HStack {
            Text("Layout")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(LayoutMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLayoutMode = mode
                        }
                    }) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedLayoutMode == mode ? .white : .secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedLayoutMode == mode ? 
                                          LinearGradient(
                                            colors: [
                                                Color(red: 0.91, green: 0.47, blue: 0.98),
                                                Color(red: 0.96, green: 0.45, blue: 0.71)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          ) : 
                                          LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Video Grid View
    
    private var videoGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(filteredVideos, id: \.id) { video in
                    VideoGridCard(video: video, pets: pets) {
                        videoToDelete = video
                        showingDeleteAlert = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Video List View
    
    private var videoListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredVideos, id: \.id) { video in
                    VideoListCard(video: video, pets: pets) {
                        videoToDelete = video
                        showingDeleteAlert = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Delete Video Function
    
    private func deleteVideo(_ video: VideoGeneration) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            modelContext.delete(video)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Empty state icon
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray.opacity(0.6), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No Videos Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create your first holographic memorial video for your beloved pet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Create button
            Button(action: {
                // Navigate to video creation
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("Create Video")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.47, blue: 0.98),
                            Color(red: 0.96, green: 0.45, blue: 0.71)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    VideoHistoryView()
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? 
                          LinearGradient(
                            colors: [
                                Color(red: 0.91, green: 0.47, blue: 0.98),
                                Color(red: 0.96, green: 0.45, blue: 0.71)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VideoGridCard: View {
    let video: VideoGeneration
    let pets: [Pet]
    let onDelete: () -> Void
    
    private var pet: Pet? {
        pets.first { $0.id == video.petId }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.47, blue: 0.98).opacity(0.1),
                            Color(red: 0.96, green: 0.45, blue: 0.71).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.91, green: 0.47, blue: 0.98),
                                        Color(red: 0.96, green: 0.45, blue: 0.71)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        if let pet = pet {
                            Text(pet.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                )
                .overlay(
                    // Status indicator
                    HStack {
                        Spacer()
                        VStack {
                            StatusBadge(status: video.status)
                            Spacer()
                        }
                    }
                    .padding(8)
                )
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title ?? "Untitled Video")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(video.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons
            HStack(spacing: 8) {
                if video.status == .completed {
                    Button(action: {
                        // Download action
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
    }
}

struct VideoListCard: View {
    let video: VideoGeneration
    let pets: [Pet]
    let onDelete: () -> Void
    
    private var pet: Pet? {
        pets.first { $0.id == video.petId }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.47, blue: 0.98).opacity(0.1),
                            Color(red: 0.96, green: 0.45, blue: 0.71).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.91, green: 0.47, blue: 0.98),
                                    Color(red: 0.96, green: 0.45, blue: 0.71)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Video info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title ?? "Untitled Video")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let pet = pet {
                    Text("Pet: \(pet.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    StatusBadge(status: video.status)
                    
                    Spacer()
                    
                    Text(video.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action menu
            Menu {
                if video.status == .completed {
                    Button(action: {
                        // Download action
                    }) {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    
                    Button(action: {
                        // Share action
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
    }
}

struct StatusBadge: View {
    let status: GenerationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(status.textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.backgroundColor)
        )
    }
}

// MARK: - Extensions

extension GenerationStatus {
    var statusColor: Color {
        switch self {
        case .pending: return .orange
        case .uploading: return .cyan
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var textColor: Color {
        switch self {
        case .pending: return .orange
        case .uploading: return .cyan
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pending: return .orange.opacity(0.1)
        case .uploading: return .cyan.opacity(0.1)
        case .processing: return .blue.opacity(0.1)
        case .completed: return .green.opacity(0.1)
        case .failed: return .red.opacity(0.1)
        }
    }
}