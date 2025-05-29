import SwiftUI

public struct SystemSettingsView: View {
    @State private var settings: [Setting] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddSetting = false
    
    public init() {} // Add public initializer
    
    public var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if settings.isEmpty {
                Text("No settings found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(settings, id: \.id) { setting in
                    NavigationLink(destination: SettingDetailView(setting: setting)) {
                        SettingRow(setting: setting)
                    }
                }
            }
        }
        .navigationTitle("System Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSetting = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSetting) {
            NavigationView {
                SettingFormView(mode: .create)
            }
        }
        .task {
            await loadSettings()
        }
        .refreshable {
            await loadSettings()
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func loadSettings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            settings = try await SupabaseService.shared.fetchSettings()
        } catch {
            self.error = error
        }
    }
}

struct SettingRow: View {
    let setting: Setting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(setting.name)
                .font(.headline)
            Text(setting.settingValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SettingDetailView: View {
    let setting: Setting
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var isEditing = false
    @State private var error: Error?
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: setting.name)
                LabeledContent("Value", value: setting.settingValue)
            }
        }
        .navigationTitle("Setting Details")
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
                SettingFormView(mode: .edit(setting))
            }
        }
        .alert("Delete Setting", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await SupabaseService.shared.deleteSetting(id: setting.id)
                        dismiss()
                    } catch {
                        self.error = error
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this setting? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
}

struct SettingFormView: View {
    enum Mode {
        case create
        case edit(Setting)
    }
    
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""
    @State private var error: Error?
    @State private var isSaving = false
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let setting) = mode {
            _name = State(initialValue: setting.name)
            _value = State(initialValue: setting.settingValue)
        }
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Value", text: $value)
            }
        }
        .navigationTitle(mode == .create ? "New Setting" : "Edit Setting")
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
                .disabled(isSaving || name.isEmpty || value.isEmpty)
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
            let setting = Setting(
                id: mode == .create ? 0 : (mode == .edit(let s) ? s.id : 0),
                name: name,
                settingValue: value
            )
            
            if case .create = mode {
                _ = try await SupabaseService.shared.createSetting(setting)
            } else {
                _ = try await SupabaseService.shared.updateSetting(setting)
            }
            
            dismiss()
        } catch {
            self.error = error
        }
    }
} 