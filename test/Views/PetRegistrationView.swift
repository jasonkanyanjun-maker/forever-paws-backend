//
//  PetRegistrationView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import PhotosUI

struct PetRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isCompleted: Bool
    
    @State private var petName = ""
    @State private var petType = PetType.dog
    @State private var petBreed = ""
    @State private var petAge = ""
    @State private var petDescription = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var petImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "pawprint.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            VStack(spacing: 8) {
                                Text("Tell us about your pet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("This information helps us create personalized content for your beloved companion")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Pet photo selection
                        VStack(spacing: 12) {
                            Text("Pet Photo")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 200)
                                    
                                    if let petImage = petImage {
                                        Image(uiImage: petImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.secondary)
                                            
                                            Text("Tap to add photo")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Pet information form
                        VStack(spacing: 20) {
                            // Pet name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pet Name *")
                                    .font(.headline)
                                
                                TextField("Enter your pet's name", text: $petName)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Pet type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pet Type *")
                                    .font(.headline)
                                
                                Picker("Pet Type", selection: $petType) {
                                    ForEach(PetType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Pet breed
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Breed")
                                    .font(.headline)
                                
                                TextField("Enter breed (optional)", text: $petBreed)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Pet age
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.headline)
                                
                                TextField("Enter age (optional)", text: $petAge)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Pet description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                
                                TextField("Tell us about your pet's personality (optional)", text: $petDescription, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                        }
                        
                        // Continue button
                        Button(action: savePetAndContinue) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Continue to App")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                petName.isEmpty ?
                                AnyView(Color.gray) :
                                AnyView(LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            )
                            .cornerRadius(12)
                        }
                        .disabled(petName.isEmpty || isLoading)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Pet Registration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                petImage = image
                            }
                        }
                    }
                }
            }
        }
        .alert("Alert", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func savePetAndContinue() {
        guard !petName.isEmpty else {
            showAlert("Please enter your pet's name")
            return
        }

        isLoading = true

        Task {
            // Save pet photo if available
            var photoURL: URL?
            if petImage != nil {
                // In a real app, you would upload this to your storage service
                // For now, we'll save it locally or use a placeholder
                photoURL = URL(string: "local://pet_photo_\(UUID().uuidString)")
            }

            // Create new pet
            let newPet = Pet(
                name: petName,
                type: petType,
                breed: petBreed.isEmpty ? nil : petBreed,
                age: petAge.isEmpty ? nil : petAge,
                petDescription: petDescription.isEmpty ? nil : petDescription,
                photoURL: photoURL
            )

            // Save to SwiftData on main actor
            await MainActor.run {
                modelContext.insert(newPet)
                do {
                    try modelContext.save()
                    isCompleted = true
                } catch {
                    showAlert("Failed to save pet information: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

#Preview {
    PetRegistrationView(isCompleted: .constant(false))
        .modelContainer(for: [Pet.self], inMemory: true)
}