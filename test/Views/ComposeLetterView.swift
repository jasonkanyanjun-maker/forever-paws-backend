//
//  ComposeLetterView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct ComposeLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedPet: Pet?
    
    @State private var letterContent: String = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with pet info
                if let pet = selectedPet {
                    petHeader(pet: pet)
                }
                
                // Letter composition area
                letterComposer
            }
            .navigationTitle("Write Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendLetter()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .fontWeight(.semibold)
                    .disabled(letterContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .alert("Letter Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("sent") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func petHeader(pet: Pet) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Pet photo
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    if let photoURL = pet.photoURL {
                        CachedAsyncImage(url: photoURL) { image in
                             image
                                 .resizable()
                                 .aspectRatio(contentMode: .fill)
                                 .frame(width: 60, height: 60)
                                 .clipShape(Circle())
                         } placeholder: {
                             Circle()
                                 .fill(Color.gray.opacity(0.3))
                                 .frame(width: 60, height: 60)
                                 .overlay(
                                     Image(systemName: "pawprint.fill")
                                         .foregroundColor(.gray)
                                 )
                         }
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Writing to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(pet.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var letterComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Share your thoughts and memories")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Write a heartfelt letter to your beloved pet. Share your feelings, memories, or anything you'd like to say.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $letterContent)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                if letterContent.isEmpty {
                    Text("Dear \(selectedPet?.name ?? "my beloved pet"),\n\nI wanted to write you this letter to tell you...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Character count
            HStack {
                Spacer()
                Text("\(letterContent.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
    
    private func sendLetter() {
        guard let pet = selectedPet else {
            alertMessage = "Please select a pet first"
            showingAlert = true
            return
        }
        
        let trimmedContent = letterContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            alertMessage = "Please write your letter content"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // Create and save the letter
        let letter = Letter(
            petId: pet.id,
            content: trimmedContent
        )
        
        // 设置当前用户ID以确保数据隔离
        if let currentUserId = SupabaseService.shared.currentUser?.id.uuidString {
            letter.userId = currentUserId
        }
        
        modelContext.insert(letter)
        
        do {
            try modelContext.save()
            alertMessage = "Your letter has been sent to \(pet.name) 💕"
            showingAlert = true
            isLoading = false
        } catch {
            alertMessage = "Failed to send letter. Please try again."
            showingAlert = true
            isLoading = false
        }
    }
}

#Preview {
    ComposeLetterView(selectedPet: nil)
}