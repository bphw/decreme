import SwiftUI

struct CakeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var variant: String = ""
    @State private var cakeTypes: String = ""
    @State private var price: String = ""
    @State private var images: String = ""
    @State private var isAvailable: Bool = true
    @State private var isLoading = false
    @State private var error: Error?
    
    let cake: Cake?
    let onSave: (Cake) async throws -> Void
    
    init(cake: Cake? = nil, onSave: @escaping (Cake) async throws -> Void) {
        self.cake = cake
        self.onSave = onSave
        _name = State(initialValue: cake?.name ?? "")
        _variant = State(initialValue: cake?.variant ?? "")
        _cakeTypes = State(initialValue: cake?.cakeTypes ?? "")
        _price = State(initialValue: cake?.price.description ?? "")
        _images = State(initialValue: cake?.images ?? "")
        _isAvailable = State(initialValue: cake?.isAvailable ?? true)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Variant", text: $variant)
                TextField("Cake Types", text: $cakeTypes)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
                TextField("Image URL", text: $images)
                Toggle("Available", isOn: $isAvailable)
            }
        }
        .navigationTitle(cake == nil ? "Add Cake" : "Edit Cake")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await saveCake()
                    }
                }
                .disabled(name.isEmpty || variant.isEmpty || price.isEmpty || cakeTypes.isEmpty)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func saveCake() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let priceDecimal = Decimal(string: price) ?? 0
            let cakeData: [String: Any] = [
                "id": cake?.id ?? 0,
                "created_at": ISO8601DateFormatter().string(from: cake?.createdAt ?? Date()),
                "name": name,
                "cake_types": cakeTypes,
                "price": priceDecimal.description,
                "variant": variant,
                "images": images.isEmpty ? NSNull() as Any : images as Any,
                "available": isAvailable
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: cakeData)
            let newCake = try JSONDecoder().decode(Cake.self, from: jsonData)
            try await onSave(newCake)
            dismiss()
        } catch {
            self.error = error
            print("Error saving cake: \(error)")  // For debugging
        }
    }
} 
