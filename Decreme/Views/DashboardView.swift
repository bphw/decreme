//
//  DashboardView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct DashboardView: View {
    @State private var dailySales: [DailySales] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                    } else if let error = error {
                        ErrorView(error: error)
                    } else {
                        salesSummary
                        salesChart
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
        .task {
            await loadDailySales()
        }
    }
    
    private var salesSummary: some View {
        VStack(spacing: 16) {
            SummaryCard(
                title: "Total Sales",
                value: String(format: "$%.2f", NSDecimalNumber(decimal: totalSales).doubleValue),
                icon: "dollarsign.circle.fill"
            )
            
            SummaryCard(
                title: "Total Orders",
                value: "\(totalOrders)",
                icon: "bag.circle.fill"
            )
        }
    }
    
    private var salesChart: some View {
        // Implement your chart view here
        Text("Sales Chart")
    }
    
    private var totalSales: Decimal {
        dailySales.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var totalOrders: Int {
        dailySales.reduce(0) { $0 + $1.orderCount }
    }
    
    private func loadDailySales() async {
        isLoading = true
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            dailySales = try await SupabaseService.shared.fetchDailySales(startDate: startDate, endDate: endDate)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
