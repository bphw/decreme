//
//  AuthViewModel.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation
import Combine
import Supabase

// Make sure NotificationExtensions.swift is in your project's target
extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up observer for auth state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChange),
            name: .authStateDidChange,
            object: nil
        )
        
        // Check initial auth state
        checkAuthStatus()
    }
    
    @objc private func handleAuthStateChange() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        Task {
            do {
                let session = try await SupabaseService.shared.getSession()
                isAuthenticated = session != nil
            } catch {
                isAuthenticated = false
                print("Auth check error: \(error)")
            }
        }
    }
    
    func signOut() async {
        do {
            try await SupabaseService.shared.signOut()
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
