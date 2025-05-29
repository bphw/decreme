//
//  LoginView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo or App Title
                Text("Decreme")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await login()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationBarHidden(true)
        }
    }
    
    private func login() async {
        do {
            try await viewModel.login(email: email, password: password)
        } catch {
            showingAlert = true
        }
    }
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isAuthenticated = false
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.signIn(email: email, password: password)
            if !session.accessToken.isEmpty {
                isAuthenticated = true
                // Notify the app that authentication state has changed
                NotificationCenter.default.post(name: .authStateDidChange, object: nil)
            } else {
                throw NSError(
                    domain: "", 
                    code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Authentication failed"]
                )
            }
        } catch {
            // If any error occurs, store it and re-throw
            self.error = error
            throw error
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
