import SwiftUI
import UIKit

struct PhotoCropEditView: View {
    let photo: PetPhoto
    let onCropComplete: (CropData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var imageSize = CGSize.zero
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading photo...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let image = image {
                    GeometryReader { geometry in
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            VStack {
                                // Crop area
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .gesture(
                                            SimultaneousGesture(
                                                MagnificationGesture()
                                                    .onChanged { value in
                                                        scale = max(1.0, min(3.0, value))
                                                    },
                                                DragGesture()
                                                    .onChanged { value in
                                                        offset = CGSize(
                                                            width: lastOffset.width + value.translation.width,
                                                            height: lastOffset.height + value.translation.height
                                                        )
                                                    }
                                                    .onEnded { _ in
                                                        lastOffset = offset
                                                    }
                                            )
                                        )
                                        .onAppear {
                                            imageSize = calculateImageSize(in: geometry.size)
                                            
                                            // Apply existing crop data if available
                                            if let cropData = photo.cropData {
                                                scale = cropData.scale
                                                offset = CGSize(
                                                    width: -cropData.x * imageSize.width,
                                                    height: -cropData.y * imageSize.height
                                                )
                                                lastOffset = offset
                                            }
                                        }
                                    
                                    // Crop overlay
                                    CropOverlay()
                                }
                                .frame(height: geometry.size.width)
                                .clipped()
                                
                                Spacer()
                                
                                // Controls
                                VStack(spacing: 20) {
                                    Text("Pinch to zoom, drag to move")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack(spacing: 20) {
                                        Button("Reset") {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                scale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                        .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button("Save Crop") {
                                            saveCrop()
                                        }
                                        .foregroundColor(.orange)
                                        .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 40)
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load photo")
                            .font(.headline)
                        
                        Button("Retry") {
                            Task {
                                await loadImage()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Edit Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func calculateImageSize(in containerSize: CGSize) -> CGSize {
        guard let image = image else { return .zero }
        
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = containerSize.width / containerSize.height
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container
            let width = containerSize.width
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller than container
            let height = containerSize.height
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func loadImage() async {
        await MainActor.run {
            isLoading = true
        }
        
        guard let url = URL(string: photo.photoUrl) else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await MainActor.run {
                    image = loadedImage
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func saveCrop() {
        let cropSize = imageSize.width // Square crop
        let cropRect = CGRect(
            x: (imageSize.width - cropSize) / 2 - offset.width / scale,
            y: (imageSize.height - cropSize) / 2 - offset.height / scale,
            width: cropSize / scale,
            height: cropSize / scale
        )
        
        // Normalize crop rect to image coordinates
        let normalizedRect = CGRect(
            x: max(0, cropRect.origin.x / imageSize.width),
            y: max(0, cropRect.origin.y / imageSize.height),
            width: min(1, cropRect.width / imageSize.width),
            height: min(1, cropRect.height / imageSize.height)
        )
        
        let cropData = CropData(
            x: normalizedRect.origin.x,
            y: normalizedRect.origin.y,
            width: normalizedRect.width,
            height: normalizedRect.height,
            scale: scale
        )
        
        onCropComplete(cropData)
        dismiss()
    }
}

#Preview {
    PhotoCropEditView(
        photo: PetPhoto(
            petId: UUID(),
            photoUrl: "https://example.com/photo.jpg"
        ),
        onCropComplete: { _ in }
    )
}