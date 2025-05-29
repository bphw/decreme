//
//  CatalogView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct CatalogView: View {
    @State private var cakes: [Cake] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    ErrorView(error: error)
                } else {
                    cakesList
                }
            }
        }
        .task {
            await loadCakes()
        }
    }
    
    private var cakesList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(cakes) { cake in
                    CakeCard(cake: cake)
                }
            }
            .navigationTitle("Catalog")
            .padding()
        }
    }
    
    private func loadCakes() async {
        isLoading = true
        do {
            cakes = try await SupabaseService.shared.fetchCakes()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

struct CakeCard: View {
    let cake: Cake
    @EnvironmentObject var cartManager: CartManager
    @State private var showingAddedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if let imageURL = URL(string: cake.images ?? "") {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
                .clipped()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(height: 150)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cake.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(cake.variant)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(cake.cakeTypes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formatPrice(cake.price))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: addToCart) {
                    HStack {
                        Text("Add to Cart")
                        if showingAddedFeedback {
                            Image(systemName: "checkmark")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(cake.isAvailable ?? true ? Color.blue : Color.gray)
                    .cornerRadius(8)
                }
//                .disabled(!(cake.isAvailable ?? true))
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .opacity(cake.isAvailable ?? true ? 1.0 : 0.5)
    }
    
    private func addToCart() {
        withAnimation {
            showingAddedFeedback = true
            cartManager.addToCart(CartItem(
                id: cake.id,
                cake: cake,
                quantity: 1
            ))
        }
        
        // Hide the feedback after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showingAddedFeedback = false
            }
        }
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
