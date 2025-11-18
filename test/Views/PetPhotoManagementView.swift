import SwiftUI
import PhotosUI

struct PetPhotoManagementView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss
    @StateObject private var petPhotoService = PetPhotoService()
    
    @State private var petPhotos: [PetPhoto] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingCropView = false
    @State private var selectedImageForCrop: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedPhotoForCrop: PetPhoto?
    @State private var showingCropEditor = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Add Photo Button
                    addPhotoButton
                    
                    // Photos Grid
                    if !petPhotos.isEmpty {
                        photosGrid
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("\(pet.name)'s Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadSelectedPhoto(newValue)
                }
            }
            .sheet(isPresented: $showingCropView) {
                if let image = selectedImageForCrop {
                    PhotoCropView(
                        image: image,
                        onCropComplete: { croppedImage, cropData in
                            Task {
                                await uploadPhoto(croppedImage, cropData: cropData)
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCropEditor) {
                if let photo = selectedPhotoForCrop {
                    PhotoCropEditView(
                        photo: photo,
                        onCropComplete: { cropData in
                            Task {
                                await updatePhotoCrop(photo, cropData: cropData)
                            }
                        }
                    )
                }
            }
            .alert("Photo Management", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadPetPhotos()
            }
        }
    }
    
    private var addPhotoButton: some View {
        Button(action: { showingImagePicker = true }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Add New Photo")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Upload a new photo of \(pet.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var photosGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(petPhotos) { photo in
                PetPhotoCard(
                    photo: photo,
                    onSetPrimary: {
                        Task {
                            await setPrimaryPhoto(photo)
                        }
                    },
                    onDelete: {
                        Task {
                            await deletePhoto(photo)
                        }
                    },
                    onCrop: {
                        selectedPhotoForCrop = photo
                        showingCropEditor = true
                    }
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Photos Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add photos of \(pet.name) to create a beautiful gallery and set a primary photo for the main display.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    private func loadPetPhotos() async {
        petPhotos = await petPhotoService.fetchPetPhotos(for: pet.id)
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImageForCrop = image
                    showingCropView = true
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to load selected image"
                showingAlert = true
            }
        }
    }
    
    private func uploadPhoto(_ image: UIImage, cropData: CropData?) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            await MainActor.run {
                alertMessage = "Failed to process image"
                showingAlert = true
            }
            return
        }
        
        let isPrimary = petPhotos.isEmpty // First photo becomes primary
        let fileName = "pet_photo_\(Date().timeIntervalSince1970).jpg"
        
        if let newPhoto = await petPhotoService.uploadPetPhoto(
            imageData,
            for: pet.id,
            fileName: fileName,
            cropData: cropData,
            isPrimary: isPrimary
        ) {
            await MainActor.run {
                petPhotos.insert(newPhoto, at: 0)
                alertMessage = "Photo uploaded successfully!"
                showingAlert = true
            }
        } else {
            await MainActor.run {
                alertMessage = petPhotoService.errorMessage ?? "Failed to upload photo"
                showingAlert = true
            }
        }
    }
    
    private func setPrimaryPhoto(_ photo: PetPhoto) async {
        let success = await petPhotoService.setPrimaryPhoto(photo.id, for: pet.id)
        
        if success {
            await MainActor.run {
                // Update local state
                for i in petPhotos.indices {
                    petPhotos[i].isPrimary = (petPhotos[i].id == photo.id)
                }
                alertMessage = "Primary photo updated!"
                showingAlert = true
            }
        } else {
            await MainActor.run {
                alertMessage = petPhotoService.errorMessage ?? "Failed to set primary photo"
                showingAlert = true
            }
        }
    }
    
    private func deletePhoto(_ photo: PetPhoto) async {
        let success = await petPhotoService.deletePetPhoto(photo.id)
        
        if success {
            await MainActor.run {
                petPhotos.removeAll { $0.id == photo.id }
                alertMessage = "Photo deleted successfully!"
                showingAlert = true
            }
        } else {
            await MainActor.run {
                alertMessage = petPhotoService.errorMessage ?? "Failed to delete photo"
                showingAlert = true
            }
        }
    }
    
    private func updatePhotoCrop(_ photo: PetPhoto, cropData: CropData) async {
        let success = await petPhotoService.updateCropData(for: photo.id, cropData: cropData)
        
        if success {
            await MainActor.run {
                // Update local state
                if let index = petPhotos.firstIndex(where: { $0.id == photo.id }) {
                    petPhotos[index].cropData = cropData
                }
                alertMessage = "Crop updated successfully!"
                showingAlert = true
            }
        } else {
            await MainActor.run {
                alertMessage = petPhotoService.errorMessage ?? "Failed to update crop"
                showingAlert = true
            }
        }
    }
}

struct PetPhotoCard: View {
    let photo: PetPhoto
    let onSetPrimary: () -> Void
    let onDelete: () -> Void
    let onCrop: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        ZStack {
            CachedAsyncImage(url: URL(string: photo.photoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(height: 180)
            .clipped()
            .cornerRadius(12)
            
            // Primary badge
            if photo.isPrimary {
                VStack {
                    HStack {
                        Spacer()
                        Text("PRIMARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            .padding(8)
                    }
                    Spacer()
                }
            }
            
            // Action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingActionSheet = true }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 32, height: 32)
                            )
                    }
                    .padding(8)
                }
            }
        }
        .confirmationDialog("Photo Actions", isPresented: $showingActionSheet, titleVisibility: .visible) {
            if !photo.isPrimary {
                Button("Set as Primary") {
                    onSetPrimary()
                }
            }
            
            Button("Edit Crop") {
                onCrop()
            }
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview {
    PetPhotoManagementView(pet: Pet(name: "Buddy", type: .dog))
}