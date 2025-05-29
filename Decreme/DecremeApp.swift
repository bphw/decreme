//
//  DecremeApp.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

@main
struct DecremeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
