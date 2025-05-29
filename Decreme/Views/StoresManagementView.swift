import SwiftUI

public struct StoresManagementView: View {
    @State private var stores: [Client] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddStore = false
    
    public init() {} // Add public initializer
    
    public var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if stores.isEmpty {
                Text("No stores found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(stores) { store in
                    NavigationLink(destination: StoreDetailView(store: store)) {
                        StoreRow(store: store)
                    }
                }
            }
        }
        .navigationTitle("Manage Stores")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddStore = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddStore) {
            NavigationView {
                StoreFormView(mode: .create)
            }
        }
        .task {
            await loadStores()
        }
        .refreshable {
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

struct StoreRow: View {
    let store: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.name)
                .font(.headline)
            Text(store.city)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(store.phone)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StoreDetailView: View {
    let store: Client
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var isEditing = false
    @State private var error: Error?
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: store.name)
                LabeledContent("Contact", value: store.contact)
                LabeledContent("Phone", value: store.phone)
                LabeledContent("Email", value: store.email)
                LabeledContent("Address", value: store.address)
                LabeledContent("City", value: store.city)
                if let deliveryFee = store.deliveryFee {
                    LabeledContent("Delivery Fee", value: formatPrice(deliveryFee))
                }
                LabeledContent("Type", value: store.type ?? "N/A")
            }
        }
        .navigationTitle("Store Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                StoreFormView(mode: .edit(store))
            }
        }
        .alert("Delete Store", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await SupabaseService.shared.deleteStore(id: store.id)
                        dismiss()
                    } catch {
                        self.error = error
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this store? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
}

struct StoreFormView: View {
    enum Mode {
        case create
        case edit(Client)
    }
    
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var contact = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var city = ""
    @State private var deliveryFee: Decimal = 0
    @State private var location = ""
    @State private var type = "business"
    @State private var error: Error?
    @State private var isSaving = false
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let store) = mode {
            _name = State(initialValue: store.name)
            _contact = State(initialValue: store.contact)
            _phone = State(initialValue: store.phone)
            _email = State(initialValue: store.email)
            _address = State(initialValue: store.address)
            _city = State(initialValue: store.city)
            _deliveryFee = State(initialValue: store.deliveryFee ?? 0)
            _location = State(initialValue: store.location)
            _type = State(initialValue: store.type ?? "business")
        }
    }
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Name", text: $name)
                TextField("Contact Person", text: $contact)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
            }
            
            Section("Location") {
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("Location", text: $location)
                TextField("Delivery Fee", value: $deliveryFee, format: .currency(code: "IDR"))
                    .keyboardType(.decimalPad)
            }
            
            Section("Type") {
                Picker("Type", selection: $type) {
                    Text("Business").tag("business")
                    Text("Personal").tag("personal")
                }
            }
        }
        .navigationTitle(mode == .create ? "New Store" : "Edit Store")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(mode == .create ? "Create" : "Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(isSaving || name.isEmpty || contact.isEmpty || phone.isEmpty)
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let store = Client(
                id: mode == .create ? UUID() : (mode == .edit(let s) ? s.id : UUID()),
                createdAt: Date(),
                name: name,
                contact: contact,
                phone: phone,
                email: email,
                address: address,
                city: city,
                deliveryFee: deliveryFee,
                location: location,
                logo: nil,
                type: type
            )
            
            if case .create = mode {
                _ = try await SupabaseService.shared.createStore(store)
            } else {
                _ = try await SupabaseService.shared.updateStore(store)
            }
            
            dismiss()
        } catch {
            self.error = error
        }
    }
} 