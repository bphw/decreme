//
//  SettingsView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var showLogoutAlert = false
    
    // Get app version from bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    // Get build number from bundle
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // Use compile date instead of build date
    private var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            List {
                // Management Section
                Section("Management") {
                    NavigationLink {
                        CakesManagementView()
                    } label: {
                        Label("Manage Cakes", systemImage: "birthday.cake")
                    }
                    
                    NavigationLink {
                        StoresManagementView()
                    } label: {
                        Label("Manage Stores", systemImage: "building.2")
                    }
                    
                    NavigationLink {
                        SystemSettingsView()
                    } label: {
                        Label("System Settings", systemImage: "gear")
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: { showLogoutAlert = true }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
                
                // App Info Section
                Section {
                    LabeledContent("Version", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("Build Date", value: buildDate)
                } header: {
                    Text("About")
                } footer: {
                    Text("© 2024 Decreme. All rights reserved.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    Task {
                        try? await SupabaseService.shared.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

// MARK: - Management Views
struct CakesManagementView: View {
    @State private var cakes: [Cake] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddCake = false
    @State private var selectedCake: Cake?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(cakes) { cake in
                    CakeRow(cake: cake) {
                        selectedCake = cake
                    }
                }
                .onDelete(perform: deleteCakes)
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
                CakeFormView { cake in
                    try await SupabaseService.shared.createCake(cake)
                    await loadCakes()
                }
            }
        }
        .sheet(item: $selectedCake) { cake in
            NavigationView {
                CakeFormView(cake: cake) { updatedCake in
                    try await SupabaseService.shared.updateCake(updatedCake)
                    await loadCakes()
                }
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
    
    private func deleteCakes(at offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    try await SupabaseService.shared.deleteCake(id: cakes[index].id)
                }
                await loadCakes()
            } catch {
                self.error = error
            }
        }
    }
}

struct StoresManagementView: View {
    @State private var stores: [Client] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddStore = false
    @State private var selectedStore: Client?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(stores) { store in
                    StoreRow(store: store) {
                        selectedStore = store
                    }
                }
                .onDelete(perform: deleteStores)
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
                StoreFormView { store in
                    try await SupabaseService.shared.createClient(store)
                    await loadStores()
                }
            }
        }
        .sheet(item: $selectedStore) { store in
            NavigationView {
                StoreFormView(store: store) { updatedStore in
                    try await SupabaseService.shared.updateClient(updatedStore)
                    await loadStores()
                }
            }
        }
        .task {
            await loadStores()
        }
        .refreshable {
            await loadStores()
        }
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
    
    private func deleteStores(at offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    try await SupabaseService.shared.deleteClient(id: stores[index].id)
                }
                await loadStores()
            } catch {
                self.error = error
            }
        }
    }
}

struct SystemSettingsView: View {
    @State private var settings: [Setting] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showAddSetting = false
    @State private var selectedSetting: Setting?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(settings, id: \.id) { setting in
                    SettingRow(setting: setting) {
                        selectedSetting = setting
                    }
                }
                .onDelete(perform: deleteSettings)
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
                SettingFormView { setting in
                    try await SupabaseService.shared.createSetting(setting)
                    await loadSettings()
                }
            }
        }
        .sheet(item: $selectedSetting) { setting in
            NavigationView {
                SettingFormView(setting: setting) { updatedSetting in
                    try await SupabaseService.shared.updateSetting(updatedSetting)
                    await loadSettings()
                }
            }
        }
        .task {
            await loadSettings()
        }
        .refreshable {
            await loadSettings()
        }
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
    
    private func deleteSettings(at offsets: IndexSet) {
        Task {
            do {
                for index in offsets {
                    try await SupabaseService.shared.deleteSetting(id: settings[index].id)
                }
                await loadSettings()
            } catch {
                self.error = error
            }
        }
    }
}
