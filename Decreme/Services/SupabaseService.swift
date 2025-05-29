//
//  SupabaseService.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation
import Supabase

@MainActor
class SupabaseService {
    static let shared = SupabaseService()
    private let client: SupabaseClient
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {
        // Initialize with your actual Supabase credentials
        client = SupabaseClient(
            supabaseURL: URL(string: "https://phroccglswebelbqalpy.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBocm9jY2dsc3dlYmVsYnFhbHB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE4NDQ1MzMsImV4cCI6MjA0NzQyMDUzM30.5WNyVkLDXAL4Jo0Mh2uBc1p8TOely3wT7VUE9itxn64"
        )
    }
    
    // Add this method to access the session
    func getSession() async throws -> Session? {
        return try await client.auth.session
    }
    
    // Authentication
    func signIn(email: String, password: String) async throws -> Session {
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in successful: \(response)")
            return response
        } catch {
            print("Sign in error: \(error)")
            throw error
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // Cakes
    func fetchCakes() async throws -> [Cake] {
        do {
            let response: [Cake] = try await client
                .database
                .from("cakes")
                .select()
                .execute()
                .value
            print("Fetched cakes: \(response)") // For debugging
            return response
        } catch {
            print("Error fetching cakes: \(error)") // For debugging
            throw error
        }
    }
    
    // Stores
    func fetchClients() async throws -> [Client] {
        do {
            let response: [Client] = try await client
                .database
                .from("clients")
                .select()
                .execute()
                .value
            print("Fetched clients: \(response)") // For debugging
            return response
        } catch {
            print("Error fetching clients: \(error)") // For debugging
            throw error
        }
    }
    
    // Orders
    func fetchOrders() async throws -> [Order] {
        do {
            let response: [Order] = try await client
                .database
                .from("orders")
                .select()
                .order("created_at", ascending: false)  // Most recent first
                .execute()
                .value
            print("Fetched orders: \(response)") // For debugging
            return response
        } catch {
            print("Error fetching orders: \(error)") // For debugging
            throw error
        }
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        let response: [Order] = try await client
            .database
            .from("orders")
            .insert(order)
            .execute()
            .value
        return response[0]
    }
    
    // Daily Sales
    func fetchDailySales(startDate: Date, endDate: Date) async throws -> [DailySales] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let response: [DailySales] = try await client
            .database
            .from("orders")
            .select()
            .gte("created_at", value: startDateString)
            .lte("created_at", value: endDateString)
            .execute()
            .value
        return response
    }
    
    func createOrder(
        orderNumber: String,
        clientId: Int,
        items: [CartItem],
        deliveryFee: Decimal,
        ppn: Decimal,
        totalAmount: Decimal,
        buyerName: String,
        buyerPhone: String,
        notes: String
    ) async throws -> Order {
        // Get current user ID from auth session
        let session = try await getSession()
        guard let session = session else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let userId = session.user.id.uuidString  // Keep this for future use
        
        struct OrderInput: Encodable {
            let orderNumber: String
            let clientId: Int
            let deliveryFee: Decimal
            let ppn: Decimal
            let status: String
            let totalAmount: Decimal
            let buyerName: String
            let buyerPhone: String
            let notes: String
            let createdBy: String  // Unhide this
            
            enum CodingKeys: String, CodingKey {
                case orderNumber = "order_number"
                case clientId = "client_id"
                case deliveryFee = "delivery_fee"
                case ppn
                case status
                case totalAmount = "total_amount"
                case buyerName = "buyer_name"
                case buyerPhone = "buyer_phone"
                case notes
                case createdBy = "created_by"  // Unhide this
            }
        }
        
        let orderInput = OrderInput(
            orderNumber: orderNumber,
            clientId: clientId,
            deliveryFee: deliveryFee,
            ppn: ppn,
            status: "pending",
            totalAmount: totalAmount,
            buyerName: buyerName,
            buyerPhone: buyerPhone,
            notes: notes.isEmpty ? "" : notes,
            createdBy: userId  // Unhide this
        )
        
        print("Creating order with input:", orderInput)
        
        do {
            let jsonData = try JSONEncoder().encode(orderInput)
            print("Sending to Supabase - Request JSON:", String(data: jsonData, encoding: .utf8) ?? "Unable to encode request")
            
            // First, create the order
            _ = try await client.database
                .from("orders")
                .insert(orderInput)
                .execute()
            
            // Then fetch the created order
            let response = try await client.database
                .from("orders")
                .select()
                .eq("order_number", value: orderNumber)
                .single()
                .execute()
            
            print("Fetch Response Data:", String(data: response.data, encoding: .utf8) ?? "No data")
            
            let order = try JSONDecoder().decode(Order.self, from: response.data)
            print("Successfully decoded order:", order)
            
            // Create order items
            for item in items {
                print("Creating order item for cake:", item.cake.id)
                try await _ = createOrderItem(
                    orderId: order.id,
                    cakeId: item.cake.id,
                    quantity: item.quantity,
                    price: item.price
                )
            }
            
            return order
        } catch let decodingError as DecodingError {
            print("Decoding error:", decodingError)
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted:", context)
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found:", context)
            case .typeMismatch(let type, let context):
                print("Type '\(type)' mismatch:", context)
            case .valueNotFound(let type, let context):
                print("Value of type '\(type)' not found:", context)
            @unknown default:
                print("Unknown decoding error:", decodingError)
            }
            throw decodingError
        } catch {
            print("Other error:", error)
            print("Error type:", type(of: error))
            if let supabaseError = error as? PostgrestError {
                print("Supabase error details:", supabaseError)
            }
            throw error
        }
    }
    
    func fetchOrderItems(orderId: Int) async throws -> [OrderItem] {
        let response = try await client.database
            .from("order_items")
            .select()
            .eq("order_id", value: orderId)
            .execute()
        
        return try JSONDecoder().decode([OrderItem].self, from: response.data)
    }
    
    func fetchOrders(clientId: Int) async throws -> [Order] {
        let response = try await client.database
            .from("orders")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Order].self, from: response.data)
    }
    
    // Fetch store settings
    func fetchStoreLogo() async throws -> String? {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .eq("name", value: "store_logo")
            .execute()
            .value
        
        return response.first?.settingValue
    }

    // Fetch bank account number
    func fetchBankAccount() async throws -> String? {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .eq("name", value: "invoice_bank_account_number")
            .execute()
            .value
        
        return response.first?.settingValue
    }

    // Fetch bank account holder
    func fetchBankName() async throws -> String? {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .eq("name", value: "invoice_bank_account_holder")
            .execute()
            .value
        
        return response.first?.settingValue
    }

    // Fetch bank icon
    func fetchBankIcon() async throws -> String? {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .eq("name", value: "invoice_bank_logo")
            .execute()
            .value
        
        return response.first?.settingValue
    }

    // Fetch bank for invoice
    func fetchBankInvoice() async throws -> String? {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .eq("name", value: "invoice_bank")
            .execute()
            .value
        
        return response.first?.settingValue
    }
    
    func createOrderItem(orderId: Int, cakeId: Int, quantity: Int, price: Decimal) async throws -> OrderItem {
        struct OrderItemInput: Encodable {
            let orderId: Int
            let cakeId: Int
            let quantity: Int
            let price: Decimal
            
            enum CodingKeys: String, CodingKey {
                case orderId = "order_id"
                case cakeId = "cake_id"
                case quantity
                case price
            }
        }
        
        let orderItemInput = OrderItemInput(
            orderId: orderId,
            cakeId: cakeId,
            quantity: quantity,
            price: price
        )
        
        print("Creating order item with input:", orderItemInput)
        
        // First insert the order item
        _ = try await client.database
            .from("order_items")
            .insert(orderItemInput)
            .execute()
        
        // Then fetch the created order item
        let response = try await client.database
            .from("order_items")
            .select()
            .eq("order_id", value: orderId)
            .eq("cake_id", value: cakeId)
            .single()
            .execute()
        
        print("Order item response data:", String(data: response.data, encoding: .utf8) ?? "No data")
        
        return try JSONDecoder().decode(OrderItem.self, from: response.data)
    }
    
    func updateOrderStatus(orderId: Int, status: String) async throws {
        // First verify we have an active session
        guard let session = try await getSession() else {
            throw NSError(domain: "", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated session found"])
        }
        
        print("Sending status update to Supabase - Order ID: \(orderId), Status: \(status)")
        print("User ID: \(session.user.id)")
        
        do {
            // Try with minimal payload and debug the update operation
            let updatePayload = ["status": status]
            
            print("Attempting update with payload:", updatePayload)
            
            // First perform the update with debug information
            let updateResponse = try await client.database
                .from("orders")
                .update(updatePayload)
                .eq("id", value: orderId)
                .execute()
            
            print("Update Response Status:", updateResponse.status)
            print("Update Response Data:", String(data: updateResponse.data, encoding: .utf8) ?? "No data")
            
            // Check if the update response indicates success
            guard updateResponse.status == 200 || updateResponse.status == 204 else {
                throw NSError(domain: "", code: -1, 
                             userInfo: [NSLocalizedDescriptionKey: "Update failed with status: \(updateResponse.status)"])
            }
            
            // Add a small delay to ensure database consistency
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Then fetch the updated record
            let fetchResponse = try await client.database
                .from("orders")
                .select()
                .eq("id", value: orderId)
                .single()
                .execute()
            
            print("Fetch Response Status:", fetchResponse.status)
            print("Fetch Response Data:", String(data: fetchResponse.data, encoding: .utf8) ?? "No data")
            
            let updatedOrder = try JSONDecoder().decode(Order.self, from: fetchResponse.data)
            print("Successfully decoded order:", updatedOrder)
            
            // Verify the update
            guard updatedOrder.status.lowercased() == status.lowercased() else {
                print("WARNING: Update operation did not modify the database.")
                print("Current user permissions:", session.user.role ?? "unknown")
                print("Expected status:", status.uppercased())
                print("Actual status:", updatedOrder.status)
                throw NSError(domain: "", code: -1, 
                             userInfo: [NSLocalizedDescriptionKey: "Status update failed: expected '\(status)' but got '\(updatedOrder.status)'. This might be a permissions issue."])
            }
            
            print("Order status successfully updated to:", updatedOrder.status)
            
        } catch let error as PostgrestError {
            print("Supabase error details:", error)
            print("Error code:", error.code ?? "unknown")
            print("Error message:", error.message)
            throw error
        } catch {
            print("Other error:", error)
            print("Error type:", type(of: error))
            throw error
        }
    }
    
    func fetchOrder(id: Int) async throws -> Order? {
        print("Fetching order from Supabase - ID: \(id)")
        
        let response = try await client.database
            .from("orders")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        print("Supabase fetch response data:", String(data: response.data, encoding: .utf8) ?? "No data")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = Self.iso8601Formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, 
                debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return try decoder.decode(Order.self, from: response.data)
    }
    
    func fetchCake(id: Int) async throws -> Cake {
        let response = try await client.database
            .from("cakes")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        return try JSONDecoder().decode(Cake.self, from: response.data)
    }
    
    // Add these methods to SupabaseService class
    func fetchSettings() async throws -> [Setting] {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .select()
            .execute()
            .value
        
        return response
    }

    // Add CRUD operations for each type
    func createCake(_ cake: Cake) async throws -> Cake {
        let response: [Cake] = try await client
            .database
            .from("cakes")
            .insert(cake)
            .execute()
            .value
        return response[0]
    }

    func updateCake(_ cake: Cake) async throws -> Cake {
        let response: [Cake] = try await client
            .database
            .from("cakes")
            .update(cake)
            .eq("id", value: cake.id)
            .execute()
            .value
        return response[0]
    }

    func deleteCake(id: Int) async throws {
        _ = try await client
            .database
            .from("cakes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // Store CRUD operations
    func createStore(_ store: Client) async throws -> Client {
        let response: [Client] = try await client
            .database
            .from("clients")
            .insert(store)
            .execute()
            .value
        return response[0]
    }

    func updateStore(_ store: Client) async throws -> Client {
        let response: [Client] = try await client
            .database
            .from("clients")
            .update(store)
            .eq("id", value: store.id)
            .execute()
            .value
        return response[0]
    }

    func deleteStore(id: UUID) async throws {
        _ = try await client
            .database
            .from("clients")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // Setting CRUD operations
    func createSetting(_ setting: Setting) async throws -> Setting {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .insert(setting)
            .execute()
            .value
        return response[0]
    }

    func updateSetting(_ setting: Setting) async throws -> Setting {
        let response: [Setting] = try await client
            .database
            .from("settings")
            .update(setting)
            .eq("id", value: setting.id)
            .execute()
            .value
        return response[0]
    }

    func deleteSetting(id: Int) async throws {
        _ = try await client
            .database
            .from("settings")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // Add this function to your SupabaseService class
    func deleteClient(id: Int) async throws {
        _ = try await client
            .database
            .from("clients")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // Also add these functions if they don't exist
    func createClient(_ store: Client) async throws -> Client {
        let response: [Client] = try await client
            .database
            .from("clients")
            .insert(store)
            .execute()
            .value
        return response[0]
    }

    func updateClient(_ store: Client) async throws -> Client {
        let response: [Client] = try await client
            .database
            .from("clients")
            .update(store)
            .eq("id", value: store.id)
            .execute()
            .value
        return response[0]
    }

}
