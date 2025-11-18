//
//  ImagePicker.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        print("🔧 [ImagePicker] Creating PHPickerViewController")
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        print("✅ [ImagePicker] PHPickerViewController created successfully")
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("🔧 [ImagePicker] Picker finished with \(results.count) results")
        
        // Always dismiss the picker first
        parent.presentationMode.wrappedValue.dismiss()
        
        guard let provider = results.first?.itemProvider else { 
            print("❌ [ImagePicker] No item provider found")
            return 
        }
        
        print("✅ [ImagePicker] Item provider found, loading image...")
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [ImagePicker] Error loading image: \(error)")
                    } else if let uiImage = image as? UIImage {
                        print("✅ [ImagePicker] Image loaded successfully")
                        self.parent.selectedImage = uiImage
                    } else {
                        print("❌ [ImagePicker] Failed to cast image to UIImage")
                    }
                }
            }
        } else {
            print("❌ [ImagePicker] Cannot load UIImage from provider")
        }
    }
    }
}

struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var showingPhotoCrop: Bool
    
    var body: some View {
        VStack {
            // This view is used as a bridge between SwiftUI and UIKit
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        showingPhotoCrop = true
                    }
                }
        }
    }
}

// MARK: - Photo Selection and Crop Workflow
struct PhotoSelectionWorkflow: View {
    @Binding var finalImage: UIImage?
    @Binding var cropData: AvatarCropData?
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotoCrop = false
    
    let onComplete: (UIImage, AvatarCropData) -> Void
    
    var body: some View {
        VStack {
            // Trigger photo selection
            Button("Select Photo") {
                showingImagePicker = true
            }
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
                ) { croppedImage, newCropData in
                    finalImage = croppedImage
                    // Convert CropData to AvatarCropData
                    let avatarCropData = AvatarCropData(
                        x: newCropData.x,
                        y: newCropData.y,
                        width: newCropData.width,
                        height: newCropData.height,
                        scale: newCropData.scale
                    )
                    cropData = avatarCropData
                    onComplete(croppedImage, avatarCropData)
                    showingPhotoCrop = false
                }
            }
        }
    }
}