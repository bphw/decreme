import SwiftUI

struct StoreFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var contact: String = ""
    @State private var logo: String = ""
    @State private var email: String = ""
    @State private var city: String = ""
    @State private var deliveryFee: String = ""
    @State private var location: String = ""
    @State private var type: String = "personal"
    @State private var isLoading = false
    @State private var error: Error?
    
    let store: Client?
    let onSave: (Client) async throws -> Void
    
    init(store: Client? = nil, onSave: @escaping (Client) async throws -> Void) {
        self.store = store
        self.onSave = onSave
        _name = State(initialValue: store?.name ?? "")
        _address = State(initialValue: store?.address ?? "")
        _phone = State(initialValue: store?.phone ?? "")
        _contact = State(initialValue: store?.contact ?? "")
        _logo = State(initialValue: store?.logo ?? "")
        _email = State(initialValue: store?.email ?? "")
        _city = State(initialValue: store?.city ?? "")
        _deliveryFee = State(initialValue: store?.deliveryFee?.description ?? "0")
        _location = State(initialValue: store?.location ?? "")
        _type = State(initialValue: store?.type ?? "personal")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                TextField("Name", text: $name)
                TextField("Contact Person", text: $contact)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
            }
            
            Section(header: Text("Location")) {
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("Location", text: $location)
            }
            
            Section(header: Text("Additional Details")) {
                TextField("Delivery Fee", text: $deliveryFee)
                    .keyboardType(.decimalPad)
                TextField("Logo URL", text: $logo)
                Picker("Type", selection: $type) {
                    Text("Personal").tag("personal")
                    Text("Business").tag("business")
                }
            }
        }
        .navigationTitle(store == nil ? "Add Store" : "Edit Store")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await saveStore()
                    }
                }
                .disabled(name.isEmpty || address.isEmpty || phone.isEmpty)
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
    
    private func saveStore() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeData: [String: Any] = [
                "id": store?.id ?? 0,
                "created_at": ISO8601DateFormatter().string(from: store?.createdAt ?? Date()),
                "name": name,
                "contact": contact,
                "phone": phone,
                "email": email,
                "address": address,
                "city": city,
                "delivery_fee": deliveryFee.isEmpty ? 0 : Double(deliveryFee) ?? 0,
                "location": location,
                "logo": logo.isEmpty ? NSNull() as Any : logo as Any,
                "type": type
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: storeData)
            let newStore = try JSONDecoder().decode(Client.self, from: jsonData)
            try await onSave(newStore)
            dismiss()
        } catch {
            self.error = error
            print("Error saving store: \(error)") // For debugging
        }
    }
} 