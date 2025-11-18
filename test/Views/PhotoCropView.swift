import SwiftUI
import UIKit

struct PhotoCropView: View {
    let image: UIImage
    let onCropComplete: (UIImage, CropData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var imageSize = CGSize.zero
    
    var body: some View {
        NavigationView {
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
                                .contentShape(Rectangle())
                                .allowsHitTesting(true)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let newScale = lastScale * value
                                                scale = max(1.0, min(5.0, newScale))
                                            }
                                            .onEnded { value in
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    let newScale = lastScale * value
                                                    scale = max(1.0, min(5.0, newScale))
                                                    lastScale = scale
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                let newOffset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                                
                                                // Apply bounds checking to prevent dragging too far
                                                let maxOffset = max(0, (imageSize.width * scale - imageSize.width) / 2)
                                                let maxOffsetHeight = max(0, (imageSize.height * scale - imageSize.height) / 2)
                                                
                                                offset = CGSize(
                                                    width: max(-maxOffset, min(maxOffset, newOffset.width)),
                                                    height: max(-maxOffsetHeight, min(maxOffsetHeight, newOffset.height))
                                                )
                                            }
                                            .onEnded { _ in
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    lastOffset = offset
                                                }
                                            }
                                    )
                                )
                                .onAppear {
                                    imageSize = calculateImageSize(in: geometry.size)
                                }
                            
                            // Crop overlay
                            CropOverlay()
                                .allowsHitTesting(false)
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
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                                .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("Crop") {
                                    cropImage()
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
            .navigationTitle("Crop Photo")
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
    }
    
    private func calculateImageSize(in containerSize: CGSize) -> CGSize {
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
    
    private func cropImage() {
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
        
        // Create cropped image
        let cropRectInImageCoords = CGRect(
            x: normalizedRect.origin.x * image.size.width,
            y: normalizedRect.origin.y * image.size.height,
            width: normalizedRect.width * image.size.width,
            height: normalizedRect.height * image.size.height
        )
        
        if let cgImage = image.cgImage?.cropping(to: cropRectInImageCoords) {
            let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            
            let cropData = CropData(
                x: normalizedRect.origin.x,
                y: normalizedRect.origin.y,
                width: normalizedRect.width,
                height: normalizedRect.height,
                scale: scale
            )
            
            onCropComplete(croppedImage, cropData)
            dismiss()
        }
    }
}

struct CropOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let cropSize = min(geometry.size.width, geometry.size.height) * 0.8
            let cropRect = CGRect(
                x: (geometry.size.width - cropSize) / 2,
                y: (geometry.size.height - cropSize) / 2,
                width: cropSize,
                height: cropSize
            )
            
            ZStack {
                // Dark overlay
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: cropSize, height: cropSize)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Crop frame
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Corner indicators
                ForEach(0..<4) { index in
                    let corner = corners[index]
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 3)
                        .position(
                            x: cropRect.minX + (corner.x * cropSize),
                            y: cropRect.minY + (corner.y * cropSize)
                        )
                        .rotationEffect(.degrees(corner.rotation))
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3, height: 20)
                        .position(
                            x: cropRect.minX + (corner.x * cropSize),
                            y: cropRect.minY + (corner.y * cropSize)
                        )
                        .rotationEffect(.degrees(corner.rotation + 90))
                }
            }
        }
    }
    
    private let corners = [
        (x: 0.0, y: 0.0, rotation: 0.0),   // Top-left
        (x: 1.0, y: 0.0, rotation: 90.0),  // Top-right
        (x: 1.0, y: 1.0, rotation: 180.0), // Bottom-right
        (x: 0.0, y: 1.0, rotation: 270.0)  // Bottom-left
    ]
}

#Preview {
    PhotoCropView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onCropComplete: { _, _ in }
    )
}