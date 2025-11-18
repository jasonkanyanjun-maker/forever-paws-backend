//
//  MemoryDetailView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import AVKit

struct MemoryDetailView: View {
    let memoryItem: MemoryItem
    @Environment(\.dismiss) private var dismiss
    @Query private var pets: [Pet]
    
    private var pet: Pet? {
        pets.first(where: { $0.id == memoryItem.petId })
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    headerSection
                    
                    // Content section
                    if memoryItem.type == .letter {
                        letterContentSection
                    } else {
                        videoContentSection
                    }
                    
                    // Pet information section
                    if let pet = pet {
                        petInfoSection(pet: pet)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Memory Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Type indicator
            HStack {
                Image(systemName: memoryItem.type == .letter ? "envelope.fill" : "video.fill")
                    .font(.title)
                    .foregroundColor(memoryItem.type == .letter ? .orange : .blue)
                    .frame(width: 60, height: 60)
                    .background((memoryItem.type == .letter ? Color.orange : Color.blue).opacity(0.1))
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(memoryItem.type == .letter ? "Letter" : "Video")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(memoryItem.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDate(memoryItem.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var letterContentSection: some View {
        VStack(spacing: 20) {
            // Original letter content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "envelope.open.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("Your Letter")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                if let content = memoryItem.content {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            // Pet reply (if available)
            if let reply = memoryItem.reply {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundColor(.pink)
                        
                        Text("Reply from \(pet?.name ?? "Your Pet")")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(reply)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var videoContentSection: some View {
        VStack(spacing: 20) {
            if let video = memoryItem.video {
                // Video status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("Video Information")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Status:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack {
                                Circle()
                                    .fill(statusColor(for: video.status))
                                    .frame(width: 8, height: 8)
                                
                                Text(video.status.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if video.status == .processing {
                            HStack {
                                Text("Progress:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(video.progress * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            
                            ProgressView(value: video.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                        
                        if let completedAt = video.completedAt {
                            HStack {
                                Text("Completed:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatDate(completedAt))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Video player (if completed)
                if video.status == .completed, let videoURL = video.generatedVideoURL {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            
                            Text("Generated Video")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 300)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Original image (if available)
                if let imageURL = video.originalImageURL {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title3)
                                .foregroundColor(.purple)
                            
                            Text("Original Image")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                                .frame(height: 200)
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private func petInfoSection(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.title3)
                    .foregroundColor(.brown)
                
                Text("Pet Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Pet photo
                if let photoURL = pet.photoURL {
                    CachedAsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                    )
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.brown)
                        .frame(width: 80, height: 80)
                        .background(Color.brown.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Pet details
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(pet.type.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brown.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func statusColor(for status: GenerationStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .uploading:
            return .blue
        case .processing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    let sampleMemory = MemoryItem(
        id: UUID(),
        type: .letter,
        title: "Letter to Buddy",
        content: "Dear Buddy, I miss you so much. You were the best companion I could ever ask for.",
        reply: "Woof! I miss you too, human. I'm always watching over you from rainbow bridge.",
        date: Date(),
        petId: UUID()
    )
    
    MemoryDetailView(memoryItem: sampleMemory)
        .modelContainer(for: [Pet.self, Letter.self, VideoGeneration.self], inMemory: true)
}