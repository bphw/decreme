import Foundation

class CartManager {
    static let shared = CartManager()
    
    private init() {}
    
    // Clear all items from cart
    func clearCart() {
        // Add your cart clearing logic here
        // For example, if you're using UserDefaults:
        UserDefaults.standard.removeObject(forKey: "cartItems")
        UserDefaults.standard.synchronize()
    }
} 