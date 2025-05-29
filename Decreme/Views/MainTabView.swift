//
//  MainTabView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var cartManager = CartManager()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                CatalogView()
                    .navigationTitle("Catalog")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Catalog", systemImage: "list.bullet")
            }
            
            NavigationStack {
                CartView()
                    .navigationTitle("Cart")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Cart", systemImage: "cart")
            }
            .badge(cartManager.totalItems)
            
            NavigationStack {
                OrdersView()
                    .navigationTitle("Orders")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Orders", systemImage: "clock")
            }
            
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(cartManager)
        .environmentObject(authViewModel)
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(CartManager())
            .environmentObject(AuthViewModel())
    }
}
#endif
