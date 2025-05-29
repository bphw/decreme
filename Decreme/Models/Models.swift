//
//  Models.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation
import SwiftUI

struct Cake: Codable, Identifiable {
    let id: Int
    let createdAt: Date
    let name: String
    let cakeTypes: String
    let price: Decimal
    let variant: String
    let images: String?
    let isAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case cakeTypes = "cake_types"
        case price
        case variant
        case images
        case isAvailable = "available"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // Handle ISO8601 date string with multiple format attempts
        let dateString = try container.decode(String.self, forKey: .createdAt)
        
        let iso8601Full = ISO8601DateFormatter()
        iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let iso8601NoFraction = ISO8601DateFormatter()
        iso8601NoFraction.formatOptions = [.withInternetDateTime]
        
        let backupFormatter = DateFormatter()
        backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = iso8601Full.date(from: dateString) {
            createdAt = date
        } else if let date = iso8601NoFraction.date(from: dateString) {
            createdAt = date
        } else if let date = backupFormatter.date(from: dateString) {
            createdAt = date
        } else {
            print("Failed to parse date: \(dateString)")
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match any expected format")
        }
        
        name = try container.decode(String.self, forKey: .name)
        cakeTypes = try container.decode(String.self, forKey: .cakeTypes)
        price = try container.decode(Decimal.self, forKey: .price)
        variant = try container.decode(String.self, forKey: .variant)
        images = try container.decodeIfPresent(String.self, forKey: .images)
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
    }
}

struct Store: Codable, Identifiable {
    let id: UUID
    let name: String
    let address: String
    let email: String
    let phone: String
}

struct Order: Codable, Identifiable {
    let id: Int
    let createdAt: Date
    let createdBy: String?
    let orderNumber: String
    let deliveryFee: Decimal
    let ppn: Decimal
    let status: String
    let clientId: Int
    let totalAmount: Decimal
    let buyerName: String?
    let buyerPhone: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case createdBy = "created_by"
        case orderNumber = "order_number"
        case deliveryFee = "delivery_fee"
        case ppn
        case status
        case clientId = "client_id"
        case totalAmount = "total_amount"
        case buyerName = "buyer_name"
        case buyerPhone = "buyer_phone"
        case notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // Handle ISO8601 date string with multiple format attempts
        let dateString = try container.decode(String.self, forKey: .createdAt)
        
        let iso8601Full = ISO8601DateFormatter()
        iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let iso8601NoFraction = ISO8601DateFormatter()
        iso8601NoFraction.formatOptions = [.withInternetDateTime]
        
        let backupFormatter = DateFormatter()
        backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = iso8601Full.date(from: dateString) {
            createdAt = date
        } else if let date = iso8601NoFraction.date(from: dateString) {
            createdAt = date
        } else if let date = backupFormatter.date(from: dateString) {
            createdAt = date
        } else {
            print("Failed to parse date: \(dateString)")
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match any expected format")
        }
        
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)
        clientId = try container.decode(Int.self, forKey: .clientId)
        deliveryFee = try container.decode(Decimal.self, forKey: .deliveryFee)
        ppn = try container.decode(Decimal.self, forKey: .ppn)
        status = try container.decode(String.self, forKey: .status)
        totalAmount = try container.decode(Decimal.self, forKey: .totalAmount)
        buyerName = try container.decodeIfPresent(String.self, forKey: .buyerName)
        buyerPhone = try container.decodeIfPresent(String.self, forKey: .buyerPhone)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

struct OrderItem: Codable, Identifiable {
    let id: Int
    let orderId: Int
    let cakeId: Int
    let quantity: Int
    let price: Decimal
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case cakeId = "cake_id"
        case quantity
        case price
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"
    case paid = "paid"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .paid: return "Paid"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        case .paid: return .green
        }
    }
}

struct DailySales: Codable {
    let date: Date
    let amount: Decimal
    let orderCount: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case amount
        case orderCount = "order_count"
    }
}

struct Client: Codable, Identifiable, Hashable {
    let id: Int
    let createdAt: Date
    let name: String
    let contact: String
    let phone: String
    let email: String
    let address: String
    let city: String
    let deliveryFee: Decimal?
    let location: String
    let logo: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case contact
        case phone
        case email
        case address
        case city
        case deliveryFee = "delivery_fee"
        case location
        case logo
        case type
    }
    
    var isPersonal: Bool {
        return type == "personal"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(createdAt)
        hasher.combine(name)
        hasher.combine(contact)
        hasher.combine(phone)
        hasher.combine(email)
        hasher.combine(address)
        hasher.combine(city)
        hasher.combine(deliveryFee?.description ?? "0")
        hasher.combine(location)
        hasher.combine(logo)
        hasher.combine(type)
    }
    
    static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id &&
        lhs.createdAt == rhs.createdAt &&
        lhs.name == rhs.name &&
        lhs.contact == rhs.contact &&
        lhs.phone == rhs.phone &&
        lhs.email == rhs.email &&
        lhs.address == rhs.address &&
        lhs.city == rhs.city &&
        lhs.deliveryFee == rhs.deliveryFee &&
        lhs.location == rhs.location &&
        lhs.logo == rhs.logo &&
        lhs.type == rhs.type
    }
}

struct Setting: Codable, Identifiable {
    let id: Int
    let name: String
    let settingValue: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case settingValue = "setting_value"
    }
}
