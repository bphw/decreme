//
//  SettingFormView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 14/05/25.
//

import SwiftUI

struct SettingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var settingValue: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    
    let setting: Setting?
    let onSave: (Setting) async throws -> Void
    
    init(setting: Setting? = nil, onSave: @escaping (Setting) async throws -> Void) {
        self.setting = setting
        self.onSave = onSave
        
        // Initialize state with existing setting values if editing
        if let setting = setting {
            _name = State(initialValue: setting.name)
            _settingValue = State(initialValue: setting.settingValue)
        }
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Value", text: $settingValue)
            }
        }
        .navigationTitle(setting == nil ? "New Setting" : "Edit Setting")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(name.isEmpty || settingValue.isEmpty || isLoading)
            }
        }
        .disabled(isLoading)
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error?.localizedDescription ?? "Unknown error")
        })
    }
    
    private func save() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let newSetting = Setting(
                    id: setting?.id ?? 0,  // Use existing ID when editing, 0 for new settings
                    name: name,
                    settingValue: settingValue
                )
                try await onSave(newSetting)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
