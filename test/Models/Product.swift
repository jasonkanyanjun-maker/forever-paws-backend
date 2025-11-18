//
//  Product.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class Product {
    var id: UUID
    var name: String
    var productDescription: String?
    var price: Double
    var category: ProductCategory
    var imageURL: URL?
    var customizationOptions: Data? // JSON data for customization options
    var createdAt: Date
    
    init(name: String, description: String? = nil, price: Double, category: ProductCategory, imageURL: URL? = nil, customizationOptions: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.productDescription = description
        self.price = price
        self.category = category
        self.imageURL = imageURL
        self.customizationOptions = customizationOptions
        self.createdAt = Date()
    }
    
    var formattedPrice: String {
        return String(format: "¥%.2f", price)
    }
    
    var hasCustomization: Bool {
        return customizationOptions != nil
    }
}

enum ProductCategory: String, CaseIterable, Codable {
    case all = "all"
    case frames = "frames"
    case stones = "stones"
    case jewelry = "jewelry"
    case textiles = "textiles"
    case candles = "candles"
    case digital = "digital"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .frames:
            return "Memorial Frames"
        case .stones:
            return "Memorial Stones"
        case .jewelry:
            return "Memorial Jewelry"
        case .textiles:
            return "Memorial Textiles"
        case .candles:
            return "Memorial Candles"
        case .digital:
            return "Digital Memorials"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .frames:
            return "photo"
        case .stones:
            return "building.columns"
        case .jewelry:
            return "heart.circle"
        case .textiles:
            return "tshirt"
        case .candles:
            return "flame"
        case .digital:
            return "ipad"
        }
    }
}