//
//  MemoryStorageView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import AVKit

struct MemoryStorageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var letters: [Letter]
    @Query private var videos: [VideoGeneration]
    @Query private var pets: [Pet]
    
    @State private var searchText = ""
    @State private var selectedFilter = MemoryFilter.all
    @State private var selectedMemoryItem: MemoryItem?
    @State private var showingDetail = false
    
    // Computed property to combine and sort memories
    private var allMemories: [MemoryItem] {
        var memories: [MemoryItem] = []
        
        // Add letters
        for letter in letters {
            memories.append(MemoryItem(
                id: letter.id,
                type: .letter,
                title: "Letter to \(pets.first(where: { $0.id == letter.petId })?.name ?? "Pet")",
                content: letter.content,
                reply: letter.reply,
                date: letter.createdAt,
                petId: letter.petId,
                letter: letter
            ))
        }
        
        // Add videos
        for video in videos {
            memories.append(MemoryItem(
                id: video.id,
                type: .video,
                title: video.title ?? "AI Generated Video",
                content: nil,
                reply: nil,
                date: video.createdAt,
                petId: video.petId,
                video: video
            ))
        }
        
        // Filter and sort
        let filtered = memories.filter { memory in
            let matchesSearch = searchText.isEmpty || 
                memory.title.localizedCaseInsensitiveContains(searchText) ||
                (memory.content?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesFilter = selectedFilter == .all || 
                (selectedFilter == .letters && memory.type == .letter) ||
                (selectedFilter == .videos && memory.type == .video)
            
            return matchesSearch && matchesFilter
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemPurple).opacity(0.03),
                        Color(.systemPink).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                    
                    // Search and filter section
                    searchAndFilterSection
                    
                    // Memory list
                    if allMemories.isEmpty {
                        emptyStateView
                    } else {
                        memoryListView
                    }
                }
            }
            .navigationTitle("Memory Storage")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingDetail) {
            if let selectedItem = selectedMemoryItem {
                MemoryDetailView(memoryItem: selectedItem)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and description
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Memory Storage")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Your precious memories with beloved pets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Statistics
            HStack(spacing: 20) {
                StatCard(
                    icon: "envelope.fill",
                    title: "Letters",
                    count: letters.count,
                    color: .orange
                )
                
                StatCard(
                    icon: "video.fill",
                    title: "Videos",
                    count: videos.filter { $0.status == .completed }.count,
                    color: .blue
                )
                
                StatCard(
                    icon: "heart.fill",
                    title: "Total",
                    count: allMemories.count,
                    color: .pink
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search memories...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Filter buttons
            HStack(spacing: 12) {
                ForEach(MemoryFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var memoryListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(allMemories) { memory in
                    MemoryCard(
                        memory: memory,
                        pet: pets.first(where: { $0.id == memory.petId })
                    ) {
                        selectedMemoryItem = memory
                        showingDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Memories Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start creating memories by writing letters or generating videos for your pets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                NavigationLink(destination: LetterWritingView()) {
                    Label("Write Letter", systemImage: "envelope.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                
                NavigationLink(destination: VideoGenerationView()) {
                    Label("Create Video", systemImage: "video.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MemoryCard: View {
    let memory: MemoryItem
    let pet: Pet?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon and type indicator
                VStack(spacing: 4) {
                    Image(systemName: memory.type == .letter ? "envelope.fill" : "video.fill")
                        .font(.title2)
                        .foregroundColor(memory.type == .letter ? .orange : .blue)
                        .frame(width: 40, height: 40)
                        .background((memory.type == .letter ? Color.orange : Color.blue).opacity(0.1))
                        .cornerRadius(10)
                    
                    Text(memory.type == .letter ? "Letter" : "Video")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(memory.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatDate(memory.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let petName = pet?.name {
                        HStack {
                            Image(systemName: "pawprint.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(petName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let content = memory.content {
                        Text(content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if memory.type == .video, let video = memory.video {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(video.status == .completed ? .green : .orange)
                            
                            Text(video.status.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct MemoryItem: Identifiable {
    let id: UUID
    let type: MemoryType
    let title: String
    let content: String?
    let reply: String?
    let date: Date
    let petId: UUID?
    let letter: Letter?
    let video: VideoGeneration?
    
    init(id: UUID, type: MemoryType, title: String, content: String?, reply: String?, date: Date, petId: UUID?, letter: Letter? = nil, video: VideoGeneration? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.reply = reply
        self.date = date
        self.petId = petId
        self.letter = letter
        self.video = video
    }
}

enum MemoryType {
    case letter
    case video
}

enum MemoryFilter: CaseIterable {
    case all
    case letters
    case videos
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .letters:
            return "Letters"
        case .videos:
            return "Videos"
        }
    }
}

// FilterButton is defined in Components/FilterButton.swift

#Preview {
    MemoryStorageView()
        .modelContainer(for: [Pet.self, Letter.self, VideoGeneration.self], inMemory: true)
}