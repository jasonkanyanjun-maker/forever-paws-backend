//
//  LetterWritingView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct LetterWritingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pets: [Pet]
    @Query private var letters: [Letter]
    
    @State private var selectedPet: Pet?
    @State private var letterContent = ""
    @State private var showingCompose = false
    @State private var showingAddPet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isGeneratingReply = false
    @State private var petReply = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let service = SupabaseService.shared
    
    // 隐藏键盘的辅助方法
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Write a Letter to Your Pet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Express your love and memories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pet Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Pet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if pets.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "pawprint.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No pets registered yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Add Pet") {
                                        showingAddPet = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(pets) { pet in
                                        PetSelectionCard(
                                            pet: pet,
                                            isSelected: selectedPet?.id == pet.id
                                        ) {
                                            selectedPet = pet
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Letter Content
                        if selectedPet != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Letter Content")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // 键盘收起按钮
                                    if isTextEditorFocused {
                                        Button("Done") {
                                            isTextEditorFocused = false
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                TextEditor(text: $letterContent)
                                    .frame(minHeight: 200)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .focused($isTextEditorFocused)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                isTextEditorFocused = false
                                                hideKeyboard()
                                            }
                                            .foregroundColor(.blue)
                                        }
                                    }
                                
                                if letterContent.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Writing Tips:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("• Share your favorite memories together")
                                            Text("• Express your feelings and emotions")
                                            Text("• Talk about what you miss most")
                                            Text("• Share your hopes and wishes")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        
                        // Pet Reply Section
                        if !petReply.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.pink)
                                    Text("Reply from \(selectedPet?.name ?? "Your Pet")")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text(petReply)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(16)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Action Buttons
                        if selectedPet != nil {
                            VStack(spacing: 12) {
                                Button(action: sendLetterAndGetReply) {
                                    HStack {
                                        if isGeneratingReply {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                        }
                                        Text(isGeneratingReply ? "Getting Reply..." : "Send Letter & Get Reply")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(letterContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingReply)
                                
                                Button(action: saveLetter) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save Letter")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(letterContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                
                                Button(action: shareContent) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share Letter")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(letterContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Letters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPet) {
                AddPetView()
            }
            .alert("Letter Status", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onTapGesture {
                // 点击空白区域收起键盘
                isTextEditorFocused = false
                hideKeyboard()
            }
    }
    
    private func sendLetterAndGetReply() {
        guard let pet = selectedPet else { return }
        
        let trimmedContent = letterContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // 收起键盘
        isTextEditorFocused = false
        isGeneratingReply = true
        
        Task {
            do {
                let createdId = try await service.createServerLetter(petId: pet.id, content: trimmedContent)
                let reply = try await service.requestAIReply(letterId: createdId)
                
                await MainActor.run {
                    petReply = reply
                    
                    // Save the letter with the reply
                    let letter = Letter(
                        petId: pet.id,
                        content: trimmedContent,
                        reply: reply,
                        createdAt: Date()
                    )
                    
                    // 设置当前用户ID以确保数据隔离
                    if let currentUserId = SupabaseService.shared.currentUser?.id.uuidString {
                        letter.userId = currentUserId
                    }
                    
                    modelContext.insert(letter)
                    
                    do {
                        try modelContext.save()
                        alertMessage = "Letter sent and reply received from \(pet.name)! 💕"
                        showingAlert = true
                        letterContent = ""
                    } catch {
                        print("❌ Failed to save letter: \(error)")
                        alertMessage = "Failed to save letter: \(error.localizedDescription)"
                        showingAlert = true
                    }
                    
                    isGeneratingReply = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to get reply: \(error)")
                    alertMessage = "Failed to get reply: \(error.localizedDescription)"
                    showingAlert = true
                    isGeneratingReply = false
                }
            }
        }
    }
    
    private func saveLetter() {
        guard let pet = selectedPet else { 
            print("❌ No pet selected")
            alertMessage = "Please select a pet first"
            showingAlert = true
            return 
        }
        
        let trimmedContent = letterContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            print("❌ Letter content is empty")
            alertMessage = "Please write some content before saving"
            showingAlert = true
            return
        }
        
        // 收起键盘
        isTextEditorFocused = false
        hideKeyboard()
        
        print("✅ Saving letter for pet: \(pet.name)")
        
        let letter = Letter(
            petId: pet.id,
            content: trimmedContent,
            createdAt: Date()
        )
        
        // 设置当前用户ID以确保数据隔离
        if let currentUserId = SupabaseService.shared.currentUser?.id.uuidString {
            letter.userId = currentUserId
        }
        
        modelContext.insert(letter)
        
        do {
            try modelContext.save()
            print("✅ Letter saved successfully")
            alertMessage = "Letter saved successfully! 💌"
            showingAlert = true
            letterContent = ""
        } catch {
            print("❌ Failed to save letter: \(error)")
            alertMessage = "Failed to save letter: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareContent() {
        guard let pet = selectedPet else { 
            print("❌ No pet selected for sharing")
            alertMessage = "Please select a pet first"
            showingAlert = true
            return 
        }
        
        let trimmedContent = letterContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            print("❌ Letter content is empty for sharing")
            alertMessage = "Please write some content before sharing"
            showingAlert = true
            return
        }
        
        // 收起键盘
        isTextEditorFocused = false
        hideKeyboard()
        
        print("✅ Sharing letter for pet: \(pet.name)")
        
        let shareText = """
        Letter to \(pet.name):
        
        \(trimmedContent)
        
        Written with love ❤️
        Created with Forever Paws 🐾
        """
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: [shareText],
                applicationActivities: nil
            )
            
            // 设置iPad的popover与呈现窗口（避免使用已弃用的 API）
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    let screen = windowScene.screen
                    let midX = screen.bounds.midX
                    let midY = screen.bounds.midY
                    popover.sourceRect = CGRect(x: midX, y: midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                rootViewController.present(activityVC, animated: true) {
                    print("✅ Share sheet presented successfully")
                }
            } else {
                print("❌ Failed to present share sheet - no root view controller found")
                self.alertMessage = "Failed to open share sheet"
                self.showingAlert = true
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
                        PetSelectorCard(
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
    
    private var composeButton: some View {
        Button(action: { showingCompose = true }) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                
                Text("Write a Letter")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(selectedPet == nil)
    }
    
    private var letterHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Letter History")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !filteredLetters.isEmpty {
                    Text("\(filteredLetters.count) letters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if filteredLetters.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No letters yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start writing your first letter to \(selectedPet?.name ?? "your pet")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredLetters) { letter in
                        LetterCard(letter: letter)
                    }
                }
            }
        }
    }
    
    private var filteredLetters: [Letter] {
        guard let selectedPet = selectedPet else { return [] }
        return letters.filter { $0.petId == selectedPet.id }
            .sorted { $0.sentAt > $1.sentAt }
    }
}

struct PetSelectorCard: View {
    let pet: Pet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? 
                                    LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing) :
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
                            .foregroundColor(isSelected ? .orange : .secondary)
                    }
                }
                
                Text(pet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .orange : .primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 80)
    }
}

struct LetterCard: View {
    let letter: Letter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text("Letter to \(letter.pet?.name ?? "Pet")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(letter.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(letter.previewText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                
                Button("Read Full Letter") {
                    // TODO: Show full letter view
                }
                .font(.caption)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LetterWritingView()
        .modelContainer(for: [Pet.self, Letter.self], inMemory: true)
}

// Create PetSelectionCard component
struct PetSelectionCard: View {
    let pet: Pet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color(.systemGray6))
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? 
                                    LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 2
                                )
                        )
                    
                    VStack(spacing: 8) {
                        if let photoURL = pet.photoURL {
                            CachedAsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(isSelected ? .orange : .secondary)
                                )
                        }
                        
                        Text(pet.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .foregroundColor(isSelected ? .orange : .primary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
