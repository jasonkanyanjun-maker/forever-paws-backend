import Foundation

struct PetPhoto: Codable, Identifiable {
    let id: UUID
    let petId: UUID
    let photoUrl: String
    var cropData: CropData?
    var isPrimary: Bool
    let uploadedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case photoUrl = "photo_url"
        case cropData = "crop_data"
        case isPrimary = "is_primary"
        case uploadedAt = "uploaded_at"
    }
    
    init(id: UUID = UUID(), petId: UUID, photoUrl: String, cropData: CropData? = nil, isPrimary: Bool = false, uploadedAt: Date = Date()) {
        self.id = id
        self.petId = petId
        self.photoUrl = photoUrl
        self.cropData = cropData
        self.isPrimary = isPrimary
        self.uploadedAt = uploadedAt
    }
}

struct CropData: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let scale: Double
    
    init(x: Double, y: Double, width: Double, height: Double, scale: Double = 1.0) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.scale = scale
    }
}