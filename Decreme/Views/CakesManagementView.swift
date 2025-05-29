import SwiftUI

public struct CakesManagementView: View {
    @State private var cakes: [Cake] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddCake = false
    
    public init() {} // Add public initializer
    
    public var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if cakes.isEmpty {
                Text("No cakes found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(cakes) { cake in
                    NavigationLink(destination: CakeDetailView(cake: cake)) {
                        CakeRow(cake: cake)
                    }
                }
            }
        }
        .navigationTitle("Manage Cakes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddCake = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCake) {
            NavigationView {
                CakeFormView(mode: .create)
            }
        }
        .task {
            await loadCakes()
        }
        .refreshable {
            await loadCakes()
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func loadCakes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            cakes = try await SupabaseService.shared.fetchCakes()
        } catch {
            self.error = error
        }
    }
}

struct CakeRow: View {
    let cake: Cake
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cake.name)
                .font(.headline)
            Text(cake.variant)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(formatPrice(cake.price))
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct CakeDetailView: View {
    let cake: Cake
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var isEditing = false
    @State private var error: Error?
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: cake.name)
                LabeledContent("Variant", value: cake.variant)
                LabeledContent("Price", value: formatPrice(cake.price))
                LabeledContent("Type", value: cake.cakeTypes)
                LabeledContent("Available", value: cake.isAvailable ?? false ? "Yes" : "No")
            }
        }
        .navigationTitle("Cake Details")
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
                CakeFormView(mode: .edit(cake))
            }
        }
        .alert("Delete Cake", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await SupabaseService.shared.deleteCake(id: cake.id)
                        dismiss()
                    } catch {
                        self.error = error
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this cake? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
}

struct CakeFormView: View {
    enum Mode {
        case create
        case edit(Cake)
    }
    
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var variant = ""
    @State private var price: Decimal = 0
    @State private var cakeTypes = ""
    @State private var isAvailable = true
    @State private var error: Error?
    @State private var isSaving = false
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let cake) = mode {
            _name = State(initialValue: cake.name)
            _variant = State(initialValue: cake.variant)
            _price = State(initialValue: cake.price)
            _cakeTypes = State(initialValue: cake.cakeTypes)
            _isAvailable = State(initialValue: cake.isAvailable ?? true)
        }
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Variant", text: $variant)
                TextField("Price", value: $price, format: .currency(code: "IDR"))
                    .keyboardType(.decimalPad)
                TextField("Type", text: $cakeTypes)
                Toggle("Available", isOn: $isAvailable)
            }
        }
        .navigationTitle(mode == .create ? "New Cake" : "Edit Cake")
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
                .disabled(isSaving || name.isEmpty || variant.isEmpty || price <= 0)
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
            let cake = Cake(
                id: mode == .create ? 0 : (mode == .edit(let c) ? c.id : 0),
                createdAt: Date(),
                name: name,
                cakeTypes: cakeTypes,
                price: price,
                variant: variant,
                images: nil,
                isAvailable: isAvailable
            )
            
            if case .create = mode {
                _ = try await SupabaseService.shared.createCake(cake)
            } else {
                _ = try await SupabaseService.shared.updateCake(cake)
            }
            
            dismiss()
        } catch {
            self.error = error
        }
    }
} 