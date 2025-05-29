//
//  CartManager.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation

@MainActor
class CartManager: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var selectedClient: Client?
    @Published var isLoading = false
    
    var subtotal: Decimal {
        items.reduce(0) { $0 + ($1.price * Decimal($1.quantity)) }
    }
    
    var deliveryFee: Decimal {
        selectedClient?.deliveryFee ?? Decimal(0)
    }
    
    var ppn: Decimal {
        subtotal * Decimal(0.10) // 10% tax
    }
    
    var total: Decimal {
        subtotal + deliveryFee + ppn
    }
    
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    func addToCart(_ item: CartItem) {
        if let index = items.firstIndex(where: { $0.cake.id == item.cake.id }) {
            items[index].quantity += item.quantity
        } else {
            items.append(item)
        }
    }
    
    func updateQuantity(for cake: Cake, quantity: Int) {
        if quantity <= 0 {
            items.removeAll { $0.cake.id == cake.id }
        } else if let index = items.firstIndex(where: { $0.cake.id == cake.id }) {
            items[index].quantity = quantity
        }
    }
    
    func clearCart() {
        items.removeAll()
        selectedClient = nil
    }
}

struct CartItem: Identifiable {
    let id: Int
    let cake: Cake
    var quantity: Int
    
    var price: Decimal {
        cake.price
    }
} 
