import SwiftUI
import PhotosUI

struct NewSupportTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supportService = SupportTicketService()
    
    @State private var selectedCategory: SupportTicket.TicketCategory = .general
    @State private var subject = ""
    @State private var description = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentImages: [UIImage] = []
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Create Support Ticket")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Tell us about your issue and we'll help you resolve it")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(SupportTicket.TicketCategory.allCases, id: \.self) { category in
                                    CategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        
                        // Subject
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Brief description of your issue", text: $subject)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                    .frame(minHeight: 120)
                                
                                TextEditor(text: $description)
                                    .padding(8)
                                    .font(.system(size: 16))
                                    .scrollContentBackground(.hidden)
                                
                                if description.isEmpty {
                                    Text("Please provide detailed information about your issue...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        
                        // Attachments
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 3,
                                matching: .images
                            ) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Add Photos")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Up to 3 images")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            if !attachmentImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(attachmentImages.enumerated()), id: \.offset) { index, image in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                Button(action: {
                                                    attachmentImages.remove(at: index)
                                                    selectedPhotos.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("New Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitTicket()
                    }
                    .disabled(subject.isEmpty || description.isEmpty || supportService.isLoading)
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                await loadSelectedPhotos(newItems)
            }
        }
        .alert("Support Ticket", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        attachmentImages.removeAll()
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    attachmentImages.append(image)
                }
            }
        }
    }
    
    private func submitTicket() {
        guard !subject.isEmpty && !description.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showingAlert = true
            return
        }
        
        guard let userId = SupabaseService.shared.currentUser?.id else {
            alertMessage = "Please log in to submit a support ticket."
            showingAlert = true
            return
        }
        
        // Convert images to Data
        let attachmentData = attachmentImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        let request = NewTicketRequest(
            category: selectedCategory.rawValue,
            subject: subject,
            description: description,
            attachments: attachmentData
        )
        
        Task {
            let success = await supportService.createTicket(userId: userId, request: request)
            
            await MainActor.run {
                if success {
                    alertMessage = "Your support ticket has been submitted successfully. We'll get back to you soon!"
                } else {
                    alertMessage = supportService.errorMessage ?? "Failed to submit ticket. Please try again."
                }
                showingAlert = true
            }
        }
    }
}

struct CategoryCard: View {
    let category: SupportTicket.TicketCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? 
                LinearGradient(
                    colors: [category.color, category.color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewSupportTicketView()
}