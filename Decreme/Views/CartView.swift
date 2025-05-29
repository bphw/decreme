//
//  CartView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var clients: [Client] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingPaymentSheet = false
    @State private var isProcessingOrder = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var buyerName: String = ""
    @State private var buyerPhone: String = ""
    @State private var isPersonalBuyer: Bool = false
    @State private var notes: String = ""
    @State private var selectedStore: Client?
    @State private var showStoreSelector = false
    
    var body: some View {
        NavigationView {
            List {
                CartItemsList()
                    .environmentObject(cartManager)
                NotesSection(notes: $notes)
                BuyerInfoSection(
                    clients: clients,
                    isLoading: isLoading,
                    buyerName: $buyerName,
                    buyerPhone: $buyerPhone,
                    isPersonalBuyer: $isPersonalBuyer,
                    cartManager: cartManager
                )
                OrderSummarySection()
                    .environmentObject(cartManager)
                CheckoutButton(
                    isEnabled: isCheckoutEnabled,
                    onPlaceOrder: placeOrder
                )
            }
            .navigationTitle("Cart")
            .sheet(isPresented: $showingPaymentSheet) {
                if let selectedClient = cartManager.selectedClient {
                    PaymentSheetView(
                        total: cartManager.total,
                        subtotal: cartManager.subtotal,
                        deliveryFee: cartManager.deliveryFee,
                        ppn: cartManager.ppn,
                        client: selectedClient,
                        items: cartManager.items,
                        buyerName: buyerName,
                        buyerPhone: buyerPhone,
                        notes: notes,
                        onPaymentComplete: { paymentMethod in
                            Task {
                                await onProcessOrder(paymentMethod)
                            }
                        },
                        onClearCart: {
                            DispatchQueue.main.async {
                                cartManager.clearCart()
                            }
                        }
                    )
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadStores()
            }
        }
    }
    
    private func onProcessOrder(_ paymentMethod: String) async {
        isProcessingOrder = true
        defer {
            DispatchQueue.main.async {
                isProcessingOrder = false
            }
        }
        
        do {
            print("Start create order on Supabase...")
            guard let client = cartManager.selectedClient else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No store selected"])
            }
            
            // Generate order number
            let orderNumber = "ORD-\(Date().timeIntervalSince1970.rounded())"
            
            // Create the order
            let newOrder = try await SupabaseService.shared.createOrder(
                orderNumber: orderNumber,
                clientId: client.id,
                items: cartManager.items,
                deliveryFee: cartManager.deliveryFee,
                ppn: cartManager.ppn,
                totalAmount: cartManager.total,
                buyerName: isPersonalBuyer ? buyerName : client.name,
                buyerPhone: isPersonalBuyer ? buyerPhone : client.phone,
                notes: notes
            )
            
            print("Created order with ID: \(newOrder.id)")
            
            // Ensure UI updates happen on main thread
            await MainActor.run {
                cartManager.clearCart()
                showingPaymentSheet = false
            }
            
        } catch {
            print("Error creating order: \(error)")
            // Ensure UI updates happen on main thread
            await MainActor.run {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private var isCheckoutEnabled: Bool {
        if isPersonalBuyer {
            return !buyerName.isEmpty && !buyerPhone.isEmpty
        } else {
            return cartManager.selectedClient != nil && 
                   !(cartManager.selectedClient?.isPersonal ?? true)
        }
    }
    
    private func placeOrder() {
        // For personal buyers, only check name and phone
        if isPersonalBuyer {
            if buyerName.isEmpty || buyerPhone.isEmpty {
                alertMessage = "Please enter buyer name and phone number"
                showAlert = true
                return
            }
            // Create a personal client with ID 3 for the payment sheet
            let personalClient = Client(
                id: 3, // Use ID 3 for personal buyers
                createdAt: Date(),
                name: buyerName,
                contact: buyerName,
                phone: buyerPhone,
                email: "",
                address: "",
                city: "",
                deliveryFee: 0,
                location: "",
                logo: nil,
                type: "personal"
            )
            cartManager.selectedClient = personalClient
        } else {
            // For non-personal buyers, check store selection
            if cartManager.selectedClient == nil {
                alertMessage = "Please select a store first"
                showAlert = true
                return
            }
        }
        
        showingPaymentSheet = true
    }
    
    private func loadStores() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            clients = try await SupabaseService.shared.fetchClients()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct StoreSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStore: Client?
    @State private var stores: [Client] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(stores) { store in
                    Button(action: {
                        selectedStore = store
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(store.name)
                                Text(store.city)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedStore?.id == store.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Store")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task {
            await loadStores()
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func loadStores() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            stores = try await SupabaseService.shared.fetchClients()
        } catch {
            self.error = error
        }
    }
}

// Break out the main content into a separate view
struct CartContentView: View {
    @EnvironmentObject var cartManager: CartManager
    let clients: [Client]
    let isLoading: Bool
    @Binding var showingPaymentSheet: Bool
    @Binding var isProcessingOrder: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @Binding var buyerName: String
    @Binding var buyerPhone: String
    @Binding var isPersonalBuyer: Bool
    @Binding var notes: String
    let onLoadStores: () async -> Void
    let onPlaceOrder: () -> Void
    let onProcessOrder: (String) async -> Void
    
    private var isCheckoutEnabled: Bool {
        if isPersonalBuyer {
            return !buyerName.isEmpty && !buyerPhone.isEmpty
        } else {
            return cartManager.selectedClient != nil && 
                   !(cartManager.selectedClient?.isPersonal ?? true)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CartItemsList()
                    .environmentObject(cartManager)
                NotesSection(notes: $notes)
                BuyerInfoSection(
                    clients: clients,
                    isLoading: isLoading,
                    buyerName: $buyerName,
                    buyerPhone: $buyerPhone,
                    isPersonalBuyer: $isPersonalBuyer,
                    cartManager: cartManager
                )
                OrderSummarySection()
                    .environmentObject(cartManager)
                CheckoutButton(
                    isEnabled: isCheckoutEnabled,
                    onPlaceOrder: onPlaceOrder
                )
            }
            .padding()
        }
        .disabled(isProcessingOrder)
        .overlay(Group {
            if isProcessingOrder {
                ProgressView()
            }
        })
        .task {
            await onLoadStores()
        }
    }
}

// Break out the cart items list into a separate view
struct CartItemsList: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ForEach(cartManager.items) { item in
            CartItemRow(item: item)
                .environmentObject(cartManager)
        }
    }
}

// Break out the notes section into a separate view
struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes (Optional)")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Break out the checkout button into a separate view
struct CheckoutButton: View {
    let isEnabled: Bool
    let onPlaceOrder: () -> Void
    
    var body: some View {
        Button(action: onPlaceOrder) {
            Text("Proceed to Payment")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}

struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        HStack {
            // Cake image
            if let imageURL = URL(string: item.cake.images ?? "") {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
            }
            
            // Cake details
            VStack(alignment: .leading) {
                Text(item.cake.name)
                    .font(.headline)
                Text(formatPrice(item.cake.price))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quantity stepper
            Stepper(
                value: Binding(
                    get: { item.quantity },
                    set: { cartManager.updateQuantity(for: item.cake, quantity: $0) }
                ),
                in: 0...99
            ) {
                Text("\(item.quantity)")
                    .frame(minWidth: 40)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OrderSummarySection: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order Summary")
                .font(.headline)
            
            Group {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(formatPrice(cartManager.subtotal))
                }
                
                HStack {
                    Text("Delivery Fee")
                    Spacer()
                    Text(formatPrice(cartManager.deliveryFee))
                }
                
                HStack {
                    Text("PPN (10%)")
                    Spacer()
                    Text(formatPrice(cartManager.ppn))
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatPrice(cartManager.total))
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your cart is empty")
                .font(.headline)
            
            Text("Add some delicious cakes to get started!")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Cart")
    }
}

struct BuyerInfoSection: View {
    let clients: [Client]
    let isLoading: Bool
    @Binding var buyerName: String
    @Binding var buyerPhone: String
    @Binding var isPersonalBuyer: Bool
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Personal Buyer Toggle
            Toggle("Personal Buyer", isOn: $isPersonalBuyer)
                .onChange(of: isPersonalBuyer) { newValue in
                    if !newValue {
                        buyerName = ""
                        buyerPhone = ""
                    }
                    cartManager.selectedClient = nil
                }
            
            // Personal Buyer Fields
            if isPersonalBuyer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Buyer Information")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    TextField("Buyer Name", text: $buyerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)
                    
                    TextField("Phone Number", text: $buyerPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            
            // Store Selection - show when not personal buyer
            if !isPersonalBuyer {
                Text("Select Store")
                    .font(.headline)
                    .padding(.top, 8)
                
                Menu {
                    ForEach(clients.filter { $0.id != 3 }) { client in
                        Button(action: {
                            print("Selected store: \(client.name)") // Debug print
                            cartManager.selectedClient = client
                        }) {
                            HStack {
                                Text(client.name)
                                Spacer()
                                if cartManager.selectedClient?.id == client.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let selectedStore = cartManager.selectedClient {
                            Text(selectedStore.name)
                                .foregroundColor(.primary)
                        } else {
                            Text("Select a store")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Selected store details
                if let selectedStore = cartManager.selectedClient {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedStore.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedStore.phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
} 
